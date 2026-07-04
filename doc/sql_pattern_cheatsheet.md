# SQL Pattern Cheatsheet — Data & AI F&B Platform

> Đây là các **mẫu cú pháp** (pattern), không phải lời giải đầy đủ cho bài toán cụ thể của bạn. Mục tiêu là giúp bạn nhớ cú pháp đúng để tự ráp logic nghiệp vụ, đúng tinh thần "active mentoring" — không copy-paste nguyên khối.

---

## 1. Data Quality Check (Bước 6)

**Kiểm tra NULL ở khóa chính:**
```sql
SELECT *
FROM raw.orders
WHERE order_id IS NULL;
```

**Kiểm tra khóa ngoại không hợp lệ (orphan record):**
```sql
SELECT o.*
FROM raw.orders o
LEFT JOIN raw.branches b ON o.branch_id = b.branch_id
WHERE b.branch_id IS NULL;
```

**Kiểm tra giá trị âm không hợp lệ:**
```sql
SELECT *
FROM raw.order_items
WHERE CAST(unit_price AS NUMERIC) < 0
   OR CAST(quantity AS NUMERIC) <= 0;
```

**Ghi log lỗi vào audit (pattern chung):**
```sql
INSERT INTO audit.data_quality_errors (batch_id, source_table, row_identifier, error_type, error_detail, detected_at)
SELECT
    :batch_id,
    'raw.orders',
    order_id,
    'NEGATIVE_AMOUNT',
    'total_amount < 0',
    now()
FROM raw.orders
WHERE CAST(total_amount AS NUMERIC) < 0;
```

---

## 2. Deduplication (Bước 7 — Staging)

**Loại bỏ trùng lặp, giữ bản ghi mới nhất:**
```sql
WITH ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY order_id
               ORDER BY loaded_at DESC
           ) AS rn
    FROM raw.orders
)
SELECT *
FROM ranked
WHERE rn = 1;
```

> Lưu ý: `PARTITION BY` chọn cột định danh nghiệp vụ (natural key), `ORDER BY` chọn cột quyết định "bản ghi nào là mới nhất/đúng nhất".

---

## 3. Chuẩn hóa text (Bước 7)

```sql
SELECT
    TRIM(LOWER(order_channel)) AS order_channel_raw,
    CASE
        WHEN TRIM(LOWER(order_channel)) IN ('delivery', 'deliv', 'giao hang') THEN 'delivery'
        WHEN TRIM(LOWER(order_channel)) IN ('dine-in', 'dinein', 'tai quan') THEN 'dine_in'
        WHEN TRIM(LOWER(order_channel)) IN ('takeaway', 'mang di') THEN 'takeaway'
        ELSE 'unknown'
    END AS order_channel_std
FROM raw.orders;
```

---

## 4. Ép kiểu an toàn (tránh crash pipeline vì 1 dòng lỗi)

```sql
SELECT
    order_id,
    -- ép kiểu an toàn: nếu lỗi format thì trả NULL thay vì crash
    CASE WHEN order_time ~ '^\d{4}-\d{2}-\d{2}'
         THEN order_time::TIMESTAMP
         ELSE NULL
    END AS order_time_parsed
FROM raw.orders;
```

---

## 5. Tránh Fan-out khi tính tổng (Bước 9 — cực kỳ quan trọng)

**SAI — gây nhân đôi doanh thu:**
```sql
-- orders (grain: hóa đơn) JOIN order_items (grain: dòng món) rồi SUM total_amount
-- → total_amount sẽ bị lặp lại theo số dòng món trong hóa đơn
SELECT o.order_id, SUM(o.total_amount)  -- ❌ SAI
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id;
```

**ĐÚNG — tính riêng từng grain, JOIN sau khi đã aggregate:**
```sql
WITH order_level AS (
    SELECT order_id, total_amount
    FROM warehouse.fact_sales
),
item_level AS (
    SELECT order_id, SUM(line_total) AS sum_items
    FROM warehouse.fact_order_items
    GROUP BY order_id
)
SELECT ol.order_id, ol.total_amount, il.sum_items
FROM order_level ol
JOIN item_level il ON ol.order_id = il.order_id;
```

---

## 6. Upsert (Insert hoặc Update nếu đã tồn tại) — dùng khi chạy lại pipeline

```sql
INSERT INTO warehouse.dim_product (product_id, product_name, category, price)
VALUES (:product_id, :product_name, :category, :price)
ON CONFLICT (product_id)
DO UPDATE SET
    product_name = EXCLUDED.product_name,
    category = EXCLUDED.category,
    price = EXCLUDED.price;
```

---

## 7. Slowly Changing Dimension — Type 2 (theo dõi lịch sử thay đổi)

Dùng khi cần biết giá sản phẩm/lương nhân viên **tại từng thời điểm trong quá khứ**, không chỉ giá trị hiện tại.

```sql
CREATE TABLE warehouse.dim_product_scd2 (
    product_sk SERIAL PRIMARY KEY,      -- surrogate key
    product_id VARCHAR NOT NULL,        -- natural key
    product_name VARCHAR,
    price NUMERIC,
    valid_from DATE NOT NULL,
    valid_to DATE,                      -- NULL nếu đang là bản ghi hiện hành
    is_current BOOLEAN DEFAULT TRUE
);

-- Khi giá thay đổi: đóng bản ghi cũ + mở bản ghi mới
UPDATE warehouse.dim_product_scd2
SET valid_to = CURRENT_DATE - 1, is_current = FALSE
WHERE product_id = :product_id AND is_current = TRUE;

INSERT INTO warehouse.dim_product_scd2 (product_id, product_name, price, valid_from, is_current)
VALUES (:product_id, :product_name, :new_price, CURRENT_DATE, TRUE);
```

**Khi JOIN fact với SCD2, phải join theo khoảng thời gian, không theo product_id đơn thuần:**
```sql
SELECT f.*, d.product_name, d.price
FROM warehouse.fact_sales f
JOIN warehouse.dim_product_scd2 d
  ON f.product_id = d.product_id
 AND f.order_date BETWEEN d.valid_from AND COALESCE(d.valid_to, '9999-12-31');
```

---

## 8. Pre-aggregation cho Data Mart (Bước 10)

```sql
CREATE TABLE mart.mart_daily_sales AS
SELECT
    d.branch_id,
    d.order_date,
    COUNT(DISTINCT d.order_id) AS total_orders,
    SUM(d.total_amount) AS net_sales,
    SUM(d.total_amount) / NULLIF(COUNT(DISTINCT d.order_id), 0) AS aov
FROM warehouse.fact_sales d
GROUP BY d.branch_id, d.order_date;
```

**Food Cost % (ví dụ công thức):**
```sql
-- food_cost_pct = giá vốn nguyên liệu tiêu thụ / doanh thu
SELECT
    branch_id,
    order_date,
    SUM(ingredient_cost) / NULLIF(SUM(net_sales), 0) * 100 AS food_cost_pct
FROM ...
GROUP BY branch_id, order_date;
```

---

## 9. Insight Engine — phát hiện bất thường (Bước 12)

**So sánh doanh thu hôm nay với trung bình 7 ngày trước (rolling average):**
```sql
WITH daily AS (
    SELECT branch_id, order_date, net_sales
    FROM mart.mart_daily_sales
),
with_avg AS (
    SELECT *,
           AVG(net_sales) OVER (
               PARTITION BY branch_id
               ORDER BY order_date
               ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
           ) AS avg_last_7d
    FROM daily
)
SELECT *,
       (net_sales - avg_last_7d) / NULLIF(avg_last_7d, 0) * 100 AS pct_change
FROM with_avg
WHERE (net_sales - avg_last_7d) / NULLIF(avg_last_7d, 0) < -0.15;  -- giảm > 15%
```

---

## 10. dim_date — tạo bảng ngày đầy đủ thuộc tính

```sql
CREATE TABLE warehouse.dim_date AS
SELECT
    d::DATE AS date_key,
    EXTRACT(YEAR FROM d) AS year,
    EXTRACT(MONTH FROM d) AS month,
    EXTRACT(DAY FROM d) AS day,
    TO_CHAR(d, 'Day') AS day_name,
    EXTRACT(ISODOW FROM d) IN (6,7) AS is_weekend,
    EXTRACT(QUARTER FROM d) AS quarter
FROM generate_series('2025-01-01'::DATE, '2026-12-31'::DATE, '1 day') AS d;
```

---

## 11. Audit — ghi log mỗi lần chạy pipeline

```sql
INSERT INTO audit.pipeline_runs (batch_id, pipeline_step, started_at, status)
VALUES (:batch_id, 'staging_orders', now(), 'RUNNING');

-- ... chạy transform ...

UPDATE audit.pipeline_runs
SET finished_at = now(), status = 'SUCCESS', row_count = :row_count
WHERE batch_id = :batch_id AND pipeline_step = 'staging_orders';
```

---

## Ghi chú chung
- Luôn dùng `NULLIF(x, 0)` khi chia để tránh lỗi chia cho 0.
- Luôn test pattern trên 1 chi nhánh/1 ngày nhỏ trước khi chạy full toàn bộ dữ liệu 6 tháng × 15 chi nhánh.
- Khi viết CTE nhiều tầng, đặt tên rõ ràng theo grain (`order_level`, `item_level`...) để chính bạn không bị nhầm khi debug.

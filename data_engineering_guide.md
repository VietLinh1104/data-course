# Lộ Trình Xây Dựng Hệ Thống Dữ Liệu & AI F&B (Data & AI Platform Guide)

Tài liệu này kết hợp giữa **hướng dẫn thực hành từng bước** và **đối chiếu lý thuyết kinh điển** của ngành Data Engineering, giúp bạn hiểu rõ bản chất (Tại sao phải làm như vậy?) của từng công việc khi xây dựng hệ thống dữ liệu F&B chuỗi 15 chi nhánh.

---

## MỤC LỤC
1. [Xác Định Mục Tiêu Hệ Thống](#1-xác-định-mục-tiêu-hệ-thống)
2. [Chuẩn Bị Dữ Liệu Nguồn](#2-chuẩn-bị-dữ-liệu-nguồn)
3. [Tạo Cơ Sở Dữ Liệu & Schema](#3-tạo-cơ-sở-dữ-liệu--schema)
4. [Quy Trình Data Ingestion (EL trong ELT)](#4-quy-trình-data-ingestion-el-trong-elt)
5. [Raw Layer (Bronze Layer)](#5-raw-layer-bronze-layer)
6. [Kiểm Tra Chất Lượng Dữ Liệu (Data Quality Check)](#6-kiểm-tra-chất-lượng-dữ-liệu-data-quality-check)
7. [Biến Đổi Dữ Liệu Raw → Staging (T trong ELT)](#7-biến-đổi-dữ-liệu-raw--staging-t-trong-elt)
8. [Thiết Kế Data Warehouse (Kimball Star Schema)](#8-thiết-kế-data-warehouse-kimball-star-schema)
9. [Xác Định Grain Cho Fact Table](#9-xác-định-grain-cho-fact-table)
10. [Tạo Data Mart (Gold Layer / Business Layer)](#10-tạo-data-mart-gold-layer--business-layer)
11. [Dashboard & Business Intelligence (BI)](#11-dashboard--business-intelligence-bi)
12. [Insight Engine (Phát Hiện Bất Thường)](#12-insight-engine-phát-hiện-bất-thường)
13. [Dự Báo (Forecast Engine)](#13-dự-báo-forecast-engine)
14. [AI Daily Report (Tự Động Tổng Hợp Báo Cáo)](#14-ai-daily-report-tự-động-tổng-hợp-báo-cáo)
15. [AI Agent Hỏi Đáp Ngôn Ngữ Tự Nhiên](#15-ai-agent-hỏi-đáp-ngôn-ngữ-tự-nhiên)
16. [Orchestration (Tự Động Hóa Toàn Bộ Pipeline)](#16-orchestration-tự-động-hóa-toàn-bộ-pipeline)
17. [Monitoring & Audit](#17-monitoring--audit)
18. [API Service Phục Vụ Dashboard & AI Agent](#18-api-service-phục-vụ-dashboard--ai-agent)
19. [Cấu Trúc Thư Mục Dự Án](#19-cấu-trúc-thư-mục-dự-án)
20. [Thứ Tự Triển Khai Thực Tế](#20-thứ-tự-triển-khai-thực-tế)

---

## 1. Xác Định Mục Tiêu Hệ Thống

Mục tiêu chính là xây dựng **Data & AI Layer** cho doanh nghiệp F&B nhằm tổng hợp dữ liệu từ các nguồn khác nhau (POS, ERP/Kho, HRM, CRM) để giải quyết các câu hỏi kinh doanh cốt lõi:
*   **POS (Doanh thu & Sản phẩm)**: Chi nhánh nào doanh thu tốt/xấu? Món nào bán chạy? Món nào bán nhiều nhưng lợi nhuận (margin) thấp?
*   **ERP/Kho (Inventory & Supply Chain)**: Nguyên liệu nào sắp hết? Tỷ lệ hao hụt (waste rate) là bao nhiêu?
*   **HRM (Nhân sự)**: Chi phí nhân sự (labor cost %) có cao không? Doanh thu trên mỗi giờ công là bao nhiêu?
*   **CRM/Marketing**: Các chiến dịch và voucher khuyến mãi có hiệu quả không (ROI)? Khách hàng có quay lại không?
*   **Dự báo & Vận hành**: Ngày mai nên chuẩn bị bao nhiêu nguyên liệu? Doanh thu dự báo thế nào? Có bất thường gì trong vận hành hôm nay không?

> [!NOTE]
> **ĐỐI CHIẾU LÝ THUYẾT: Mối quan hệ giữa Business Requirements và Data Architecture**
> Trong lý thuyết kỹ nghệ dữ liệu, mọi kiến trúc dữ liệu đều phải bắt đầu từ **yêu cầu nghiệp vụ (Business Requirements)** chứ không phải công nghệ. Nếu thiết kế hệ thống mà không biết rõ các câu hỏi kinh doanh cần trả lời, bạn sẽ rơi vào cái bẫy "Over-engineering" (thiết kế quá phức tạp nhưng không dùng được). Bản chất của Data Engineer là chuyển dịch câu hỏi kinh doanh thành cấu trúc dữ liệu tối ưu cho việc truy vấn.

---

## 2. Chuẩn Bị Dữ Liệu Nguồn

Dữ liệu thô giả lập 6 tháng của chuỗi F&B 15 chi nhánh bao gồm 16 file CSV được tổ chức thành các nhóm nghiệp vụ chính:
*   **Nhóm POS (Bán hàng)**: `orders.csv`, `order_items.csv`, `payments.csv`, `products.csv`, `branches.csv`.
*   **Nhóm ERP / Kho**: `ingredients.csv`, `recipes.csv`, `purchase_orders.csv`, `inventory_daily.csv`, `suppliers.csv`.
*   **Nhóm HRM**: `employees.csv`, `employee_shifts.csv`.
*   **Nhóm CRM / Marketing**: `customers.csv`, `campaigns.csv`, `vouchers.csv`.

> [!NOTE]
> **ĐỐI CHIẾU LÝ THUYẾT: Dữ liệu nguồn từ các hệ thống OLTP**
> Các file CSV trên đại diện cho các bản xuất (dump) từ cơ sở dữ liệu **OLTP (Online Transaction Processing)**. 
> *   **Hệ thống OLTP**: Thiết kế cho mục đích giao dịch nhanh, ghi dữ liệu liên tục, cấu trúc chuẩn hóa cao (3NF) để tránh dư thừa và đảm bảo tính toàn vẹn (ACID).
> *   **Hệ thống OLAP (Online Analytical Processing)**: Nơi chúng ta hướng tới (Data Warehouse), được thiết kế tối ưu cho các truy vấn đọc, phân tích và tổng hợp dữ liệu quy mô lớn. 
> Nhiệm vụ của bạn là chuyển dữ liệu từ dạng tối ưu cho *ghi* (OLTP) sang dạng tối ưu cho *đọc/phân tích* (OLAP).

---

## 3. Tạo Cơ Sở Dữ Liệu & Schema

Trong cơ sở dữ liệu PostgreSQL `dwh_fb`, chúng ta tạo ra 5 schema độc lập: `raw`, `staging`, `warehouse`, `mart`, và `audit`.

> [!NOTE]
> **ĐỐI CHIẾU LÝ THUYẾT: Kiến trúc phân lớp (Medallion Architecture)**
> Đây là việc triển khai mô hình **Medallion Architecture** (đồng, bạc, vàng) nổi tiếng trong hồ dữ liệu:
> 1.  **Bronze (Raw)**: Dữ liệu gốc nguyên bản. Lưu vết lịch sử và là điểm tựa để chạy lại (replay) pipeline khi có lỗi công thức.
> 2.  **Silver (Staging/Warehouse)**: Dữ liệu đã làm sạch (`staging`) và cấu trúc hóa dưới dạng Fact/Dim (`warehouse`). Đây là nguồn dữ liệu chuẩn hóa, tích hợp đầy đủ.
> 3.  **Gold (Mart)**: Dữ liệu tổng hợp sâu cho nghiệp vụ cụ thể. Tối ưu hóa tối đa cho hiệu năng truy vấn của báo cáo và AI.
> **Ý nghĩa bản chất**: Tách biệt trách nhiệm (Separation of Concerns). Nếu logic tính toán KPI thay đổi, bạn chỉ cần sửa ở tầng Gold (Mart) mà không cần nạp lại dữ liệu từ tệp CSV gốc.

---

## 4. Quy Trình Data Ingestion (EL trong ELT)

Giai đoạn Ingestion thực hiện đọc dữ liệu thô từ file CSV và ghi trực tiếp vào schema `raw` trong PostgreSQL.
*   **Yêu cầu**: Python đọc CSV -> Validate cột -> Load Postgres. Thêm 3 cột metadata: `batch_id`, `source_file_name`, `loaded_at`.

> [!NOTE]
> **ĐỐI CHIẾU LÝ THUYẾT: Sự chuyển dịch từ ETL sang ELT**
> *   **ETL (Extract-Transform-Load)**: Xử lý dữ liệu ở bộ nhớ đệm trước khi nạp vào kho. Thường dùng khi máy chủ lưu trữ dữ liệu rất đắt đỏ hoặc yếu về năng lực tính toán.
> *   **ELT (Extract-Load-Transform)**: Nạp thô trước, biến đổi sau. Tận dụng trực tiếp năng lực tính toán cực mạnh của các cơ sở dữ liệu hiện đại bằng ngôn ngữ SQL SQL-native.
> **Ý nghĩa của 3 cột Metadata**: Trong hệ thống dữ liệu lớn, việc mất mát dữ liệu hoặc sai lệch số liệu rất dễ xảy ra. Ba cột này tạo ra **khả năng truy vết nguồn gốc (Data Lineage)**. Nhìn vào một dòng dữ liệu lỗi ở cuối pipeline, ta biết ngay nó được nạp lúc nào, từ file cụ thể nào và trong đợt chạy (batch) nào để dễ cô lập lỗi.

> [!TIP]
> **Nâng cấp hiện đại (2025/2026) - Local Lakehouse với DuckDB & Parquet**:
> Thay vì ghi thẳng dữ liệu thô vào PostgreSQL, xu hướng hiện nay là chuyển đổi các tệp CSV thô thành định dạng **Parquet** (nén tốt, lưu trữ cột, đọc cực nhanh) và lưu trữ trong thư mục `data/lakehouse/` (Bronze Layer). 
> Sau đó, sử dụng **DuckDB** (cơ sở dữ liệu nhúng siêu nhanh cho analytics) để truy vấn trực tiếp trên các file Parquet này mà không cần khởi chạy một database server cồng kềnh.

---

## 5. Raw Layer (Bronze Layer)

*   **Nguyên tắc**: Giữ dữ liệu gốc ở kiểu dữ liệu đơn giản nhất (`VARCHAR`/`TEXT`), không ép kiểu phức tạp, không biến đổi.

> [!NOTE]
> **ĐỐI CHIẾU LÝ THUYẾT: Nguyên lý Tính bất biến (Immutability) và Data Replayability**
> *   **Immutability**: Dữ liệu ở tầng Raw phải là bất biến. Một khi đã ghi vào là không bao giờ sửa đổi.
> *   **Replayability (Khả năng chạy lại)**: Nếu trong quá trình tính toán công thức ở Staging/Warehouse bạn phát hiện ra lỗi logic, bạn chỉ việc xóa các bảng Staging/Warehouse đi và chạy lại từ Raw. Nếu không giữ tầng Raw nguyên bản, bạn sẽ phải thực hiện lại quy trình Ingest tốn kém thời gian từ các file vật lý bên ngoài.

---

## 6. Kiểm Tra Chất Lượng Dữ Liệu (Data Quality Check)

Quét dữ liệu thô ở Raw trước khi cho phép biến đổi sang Staging. 
*   **Ví dụ quy tắc**: Kiểm tra Null khóa chính, khóa ngoại phải hợp lệ, giá trị số tiền không được âm.

> [!NOTE]
> **ĐỐI CHIẾU LÝ THUYẾT: Nguyên lý "Garbage In, Garbage Out" (GIGO)**
> Nếu dữ liệu đầu vào là "rác" (lỗi, rỗng, sai định dạng) thì mọi báo cáo, dự báo AI ở đầu ra cũng chỉ là "rác". 
> Việc kiểm soát chất lượng dữ liệu ở cổng vào (Data Quality Gate) giúp phát hiện sớm các sự cố dữ liệu (Data Drift/Schema Drift) từ hệ thống nguồn trước khi chúng làm hỏng số liệu trên báo cáo của Ban giám đốc. Ghi log dữ liệu lỗi vào `audit.data_quality_errors` đóng vai trò như một cơ chế **cách ly và chẩn đoán**.

---

## 7. Biến Đổi Dữ Liệu Raw → Staging (T trong ELT)

*   **Công việc**: Ép kiểu chuẩn (`TIMESTAMP`, `NUMERIC`), loại bỏ trùng lặp, xử lý NULL, lọc các dòng đã bị đánh dấu lỗi ở bước DQ.

> [!NOTE]
> **ĐỐI CHIẾU LÝ THUYẾT: Chuẩn hóa dữ liệu (Data Standardization)**
> Đây chính là bước xử lý **sự không nhất quán của dữ liệu** (Data Inconsistency) - một lỗi kinh điển khi tổng hợp dữ liệu từ nhiều nguồn khác nhau. Ví dụ: Kênh bán hàng hệ thống này ghi là `Delivery`, hệ thống kia ghi là `deliv`. Việc chuẩn hóa text đưa tất cả về một định dạng thống nhất giúp cho các phép gom nhóm (`GROUP BY`) trong SQL sau này tính toán chính xác số liệu tổng.

> [!TIP]
> **Nâng cấp hiện đại (2025/2026) - Sử dụng dbt (Data Build Tool)**:
> Thay vì viết các hàm Python/SQL thủ công để chạy các file SQL tạo và nạp bảng, các kỹ sư dữ liệu hiện nay đều sử dụng **dbt-postgres**. dbt cho phép định nghĩa các bảng `staging` và `warehouse` dưới dạng các file `.sql` dạng `SELECT`, tự động quản lý sơ đồ phụ thuộc dữ liệu (Data Lineage) và hỗ trợ lập trình SQL linh động.

---

## 8. Thiết Kế Data Warehouse (Kimball Star Schema)

Dữ liệu staging sẽ được chuyển hóa thành cấu trúc Star Schema trong schema `warehouse`.

### 8.1. Các bảng chiều (Dimension Tables - DIM)
Bảng chứa ngữ cảnh: `dim_date`, `dim_branch`, `dim_product`, `dim_customer`, `dim_employee`, `dim_ingredient`, `dim_supplier`, `dim_campaign`, `dim_voucher`.

### 8.2. Các bảng sự kiện (Fact Tables - FACT)
Bảng chứa chỉ số: `fact_sales`, `fact_order_items`, `fact_payments`, `fact_inventory_daily`, `fact_purchase_orders`, `fact_employee_shifts`.

> [!NOTE]
> **ĐỐI CHIẾU LÝ THUYẾT: Kimball Dimensional Modeling (Mô hình hóa chiều)**
> Đây là lý thuyết kinh điển của Ralph Kimball về kho dữ liệu.
> *   **Tại sao lại tách Fact và Dim?** 
>     Trong hệ thống OLTP, để tránh dư thừa dữ liệu, người ta tách ra làm hàng chục bảng liên kết chéo. Nhưng khi phân tích, việc JOIN quá nhiều bảng sẽ làm truy vấn cực kỳ chậm. 
>     Kimball giải quyết bằng cách chia thế giới dữ liệu thành 2 thực thể:
>     1.  **Chỉ số đo lường (Fact)**: Chứa các con số biến động liên tục (tiền, số lượng).
>     2.  **Ngữ cảnh mô tả (Dim)**: Chứa thông tin cố định hoặc ít thay đổi giúp trả lời câu hỏi Ai, Cái gì, Ở đâu, Khi nào.
> *   **Star Schema vs Snowflake Schema**:
>     *   *Snowflake*: Chuẩn hóa các bảng Dim (ví dụ: `dim_product` join với `dim_category`). Tốn nhiều join hơn.
>     *   *Star Schema*: Giải chuẩn hóa (Denormalized) các bảng Dim (đưa tên danh mục trực tiếp vào bảng sản phẩm). Giảm thiểu phép join, giúp tối ưu hóa bộ nhớ đệm và tốc độ đọc của cơ sở dữ liệu OLAP.

---

## 9. Xác Định Grain Cho Fact Table

*   Xác định rõ ý nghĩa của một dòng trong bảng Fact: `fact_sales` là 1 hóa đơn, `fact_order_items` là 1 món trong hóa đơn, `fact_inventory_daily` là tồn kho của 1 nguyên liệu/chi nhánh/ngày.

> [!NOTE]
> **ĐỐI CHIẾU LÝ THUYẾT: Tránh lỗi tính trùng lặp (Fan-Out Effect & Double Counting)**
> Kimball chỉ ra rằng: **"Mọi phép tính toán trên bảng Fact sẽ sai lầm nếu bạn không xác định rõ hạt nhân chi tiết (Grain) của nó trước khi thiết kế"**.
> *   *Ví dụ lỗi*: Nếu bạn join bảng `orders` (grain là hóa đơn) với bảng `order_items` (grain là món trong hóa đơn) rồi tính tổng tiền của bảng `orders`, số tiền hóa đơn sẽ bị nhân lên theo số lượng món ăn trong hóa đơn đó (Fan-out). 
> Việc tách biệt `fact_sales` và `fact_order_items` với grain được định nghĩa hiển ngôn là chìa khóa để đảm bảo tính chính xác của dữ liệu.

---

## 10. Tạo Data Mart (Gold Layer / Business Layer)

*   Tạo các bảng/view tổng hợp sẵn KPIs nghiệp vụ: `mart_daily_sales`, `mart_branch_performance`, `mart_product_performance`, v.v.

> [!NOTE]
> **ĐỐI CHIẾU LÝ THUYẾT: Bản chất của Data Mart và Phép tính toán trước (Pre-aggregation)**
> Khi dữ liệu trong kho dữ liệu lên tới hàng triệu hay hàng tỷ dòng, việc để Dashboard hoặc AI Agent quét qua toàn bộ bảng Fact thô mỗi lần truy cập sẽ làm treo hệ thống và tốn tài nguyên.
> **Bản chất lý thuyết**: Data Mart thực hiện phép **tổng hợp trước (Pre-aggregation)** dữ liệu theo thời gian (ví dụ: theo ngày) hoặc theo thực thể nghiệp vụ (chi nhánh, sản phẩm). Nhờ đó, BI tool chỉ cần đọc vài nghìn dòng dữ liệu đã được tính sẵn thay vì hàng triệu dòng Fact, giúp tốc độ tải báo cáo giảm từ vài phút xuống dưới 1 giây.

---

## 11. Dashboard & Business Intelligence (BI)

*   Trực quan hóa dữ liệu qua các biểu đồ (Overview, Sales, Product, Inventory, Labor).

> [!NOTE]
> **ĐỐI CHIẾU LÝ THUYẾT: Từ Dữ liệu đến Thông tin (Data-to-Information)**
> Dữ liệu thô trong DWH rất khó để con người hấp thụ trực tiếp. Dashboard là công cụ dịch chuyển dữ liệu thô thành **Thông tin (Information)** có thể hiểu được bằng thị giác. Lý thuyết trực quan hóa nhấn mạnh việc thiết kế Dashboard theo nguyên tắc: **"Tổng quan trước, lọc và đào sâu sau" (Overview first, zoom and filter, then details-on-demand)**.

---

## 12. Insight Engine (Phát Hiện Bất Thường)

*   Thiết lập các rule quét dữ liệu mart tự động phát hiện doanh thu giảm >15%, food cost >35%, labor cost >25%, tồn kho dưới 2 ngày.

> [!NOTE]
> **ĐỐI CHIẾU LÝ THUYẾT: Phân tích chẩn đoán (Diagnostic Analytics) và Quản lý theo ngoại lệ (Management by Exception)**
> *   *Diagnostic Analytics*: Không chỉ cho biết chuyện gì đã xảy ra (Descriptive), hệ thống cần chỉ ra *tại sao* nó xảy ra hoặc có gì bất thường.
> *   *Management by Exception*: Người quản lý bận rộn không thể xem hết mọi chi tiết Dashboard mỗi ngày. Insight Engine giúp họ chỉ tập trung vào các trường hợp "ngoại lệ" (các lỗi vận hành, chi phí vượt ngưỡng) để đưa ra quyết định can thiệp kịp thời.

---

## 13. Dự Báo (Forecast Engine)

*   Dự báo doanh thu, nguyên liệu chuẩn bị và nhân sự ngày mai dùng thuật toán chuỗi thời gian (Prophet, XGBoost).

> [!NOTE]
> **ĐỐI CHIẾU LÝ THUYẾT: Phân tích dự đoán (Predictive Analytics)**
> DWH truyền thống nhìn về quá khứ. Việc tích hợp Forecast Engine dịch chuyển hệ thống sang **Phân tích dự đoán (Predictive)**. 
> Về mặt toán học, dữ liệu chuỗi thời gian của F&B luôn bao gồm 3 thành phần bản chất: **Xu hướng (Trend)** (quán đang đi lên hay đi xuống), **Tính chu kỳ (Seasonality)** (cuối tuần đông khách hơn ngày thường, mùa hè bán nhiều trà trái cây hơn), và **Nhiễu (Noise)**. Các thuật toán như Prophet hay XGBoost tách biệt các thành phần này để đưa ra dự báo sát thực tế nhất.

---

## 14. AI Daily Report (Tự Động Tổng Hợp Báo Cáo)

*   Sử dụng Python tổng hợp KPI ngày hôm trước và dùng LLM viết báo cáo tóm tắt bằng tiếng Việt gửi qua Slack/Telegram.

> [!NOTE]
> **ĐỐI CHIẾU LÝ THUYẾT: Tự động hóa tri thức (Knowledge Automation)**
> Bước này ứng dụng Generative AI để tự động hóa việc đọc số liệu và viết báo cáo. LLM đóng vai trò là một "nhà phân tích ảo", chuyển đổi dữ liệu số khô khan thành **Tri thức dạng văn bản (Narrative Insight)**, giúp người dùng tiếp cận thông tin kinh doanh nhanh nhất mà không cần kỹ năng đọc biểu đồ phức tạp.

---

## 15. AI Agent Hỏi Đáp Ngôn Ngữ Tự Nhiên

*   Cung cấp giao diện chat hỏi đáp số liệu kinh doanh. **Bắt buộc** dùng Tool Calling (FastAPI API) để Agent lấy số liệu, tuyệt đối không cho Agent viết SQL tự do chạy trên db raw.

> [!NOTE]
> **ĐỐI CHIẾU LÝ THUYẾT: Kiến trúc Semantic Layer cho Generative AI**
> Tại sao việc cho LLM tự viết SQL (Text-to-SQL) chạy trực tiếp lên database là sai lầm nguy hiểm?
> 1.  *Lỗi ảo giác (Hallucination)*: LLM có thể join sai bảng, dùng sai tên cột hoặc tự chế ra công thức tính toán không đúng với nghiệp vụ của công ty.
> 2.  *Rủi ro bảo mật (SQL Injection / Data Leak)*: Người dùng có thể lừa LLM thực thi các câu lệnh nguy hại như xóa bảng hoặc truy cập dữ liệu lương nhân sự bảo mật.
> **Giải pháp bản chất**: Thiết lập lớp API đóng vai trò là **Semantic Layer**. AI Agent chỉ được phép tương tác thông qua các hàm (Tools) được lập trình sẵn. Agent chỉ quyết định *khi nào cần gọi hàm nào với tham số nào* (ví dụ: gọi hàm doanh thu với tham số ngày hôm qua). Logic SQL thực tế vẫn do Kỹ sư dữ liệu kiểm soát hoàn toàn ở API.

> [!TIP]
> **Nâng cấp hiện đại (2025/2026) - Lớp ngữ nghĩa thống nhất (Unified Semantic Layer)**:
> Thiết lập các công cụ như Cube hoặc dbt Semantic Layer làm Single Source of Truth cho cả AI Agent và Dashboard, đảm bảo sự đồng bộ số liệu tuyệt đối.

---

## 16. Orchestration (Tự Động Hóa Toàn Bộ Pipeline)

*   Tự động hóa luồng chạy: Ingest -> Quality Checks -> Staging -> Warehouse -> Mart -> Insights -> Forecast -> AI Report.

> [!NOTE]
> **ĐỐI CHIẾU LÝ THUYẾT: Đồ thị có hướng không chu trình (DAG - Directed Acyclic Graph)**
> Trong khoa học máy tính, một pipeline dữ liệu được biểu diễn dưới dạng một **DAG**.
> *   *Có hướng (Directed)*: Dữ liệu di chuyển theo một chiều duy nhất (từ Raw sang Mart).
> *   *Không chu trình (Acyclic)*: Không có vòng lặp vô hạn (bảng A không thể phụ thuộc vào bảng B khi bảng B lại phụ thuộc vào bảng A).
> Điều phối (Orchestration) quản lý thứ tự thực thi của các nút trong DAG, đảm bảo bước sau chỉ chạy khi bước trước đã hoàn thành thành công và tự động xử lý khi một nút bị lỗi.

---

## 17. Monitoring & Audit

*   Nhật ký giám sát: `audit.pipeline_runs`, `audit.load_batches`, `audit.data_quality_errors`.

> [!NOTE]
> **ĐỐI CHIẾU LÝ THUYẾT: Khả năng quan sát dữ liệu (Data Observability)**
> Data Observability là lý thuyết đảm bảo hệ thống dữ liệu hoạt động tin cậy. 
> Nó dựa trên các chỉ số **SLA (Service Level Agreement)** (ví dụ: DWH phải sẵn sàng trước 7h sáng mỗi ngày) và các thông số giám sát. Bằng cách ghi nhận vết thời gian và số dòng ở mỗi tầng chạy, bạn có thể nhanh chóng phát hiện ra sự cố nghẽn cổ chai (performance bottleneck) hoặc sụt giảm đột biến lượng dữ liệu nạp.

---

## 18. API Service Phục Vụ Dashboard & AI Agent

*   Xây dựng API Backend (FastAPI) để cung cấp dữ liệu mart an toàn ra ngoài.

> [!NOTE]
> **ĐỐI CHIẾU LÝ THUYẾT: Nguyên lý Đóng gói (Encapsulation) và Phân rã dịch vụ**
> Thay vì cho phép các ứng dụng bên ngoài (Dashboard React, AI Agent Python) kết nối trực tiếp đến Cơ sở dữ liệu DWH (gây quá tải kết nối và lộ thông tin bảo mật), ta đóng gói toàn bộ logic truy vấn dữ liệu phía sau một lớp API bảo mật. API kiểm soát quyền truy cập, cache dữ liệu để tăng tốc độ phản hồi và cung cấp một giao diện kết nối tiêu chuẩn, dễ bảo trì.

---

## 19. Cấu Trúc Thư Mục Dự Án

*   Tổ chức mã nguồn khoa học (`data/`, `database/ddl/`, `pipelines/`, `analytics-api/`, `dashboard/`, `ai-agent/`, `notebooks/`).

> [!NOTE]
> **ĐỐI CHIẾU LÝ THUYẾT: Kỹ nghệ phần mềm cho dữ liệu (Software Engineering for Data)**
> Data Engineering không chỉ là viết SQL và script chạy thử. Đó là việc áp dụng các nguyên tắc kỹ nghệ phần mềm vào dữ liệu: quản lý mã nguồn bằng Git, tách biệt cấu trúc thư mục theo mô hình hướng dịch vụ (Microservices/Modular Monolith), đảm bảo code dễ đọc, dễ kiểm thử và có thể deploy tự động qua CI/CD.

---

## 20. Thứ Tự Triển Khai Thực Tế

*   Thứ tự làm: Database -> Ingestion -> DQ -> Staging -> Warehouse -> Mart -> BI -> Insights -> Forecast -> AI Integration -> Orchestration.

> [!NOTE]
> **ĐỐI CHIẾU LÝ THUYẾT: Quy trình phát triển hướng dữ liệu (Data-Driven Development)**
> Trong kỹ nghệ dữ liệu, bạn bắt buộc phải đi theo mô hình **Bottom-Up (Từ dưới lên)** khi xây dựng nền tảng. Bạn không thể làm Dashboard hay AI Agent nếu không có dữ liệu Mart sạch; bạn không có Mart nếu không có cấu trúc Warehouse chuẩn; và bạn không có Warehouse nếu không nạp dữ liệu thô vào Raw. 
> Việc tuân thủ trình tự này giúp bạn xây dựng móng vững chắc cho hệ thống, giảm thiểu tối đa việc phải quay lại sửa đổi kiến trúc ở các bước sau.

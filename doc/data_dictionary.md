# Data Dictionary — Nguồn Dữ Liệu F&B (16 File CSV)

> **Cách dùng**: Đây là khung mẫu (template). Với mỗi bảng, hãy mở file CSV thật tương ứng, điền chính xác tên cột, kiểu dữ liệu quan sát được, và ghi chú nghiệp vụ. Các dòng đánh dấu `(?)` là suy đoán hợp lý dựa trên tên file — cần bạn xác nhận/sửa lại theo dữ liệu thật.

---

## Quy ước ký hiệu
- **PK** = Primary Key (khóa chính)
- **FK** = Foreign Key (khóa ngoại) → trỏ tới bảng nào
- **Kiểu gợi ý** = kiểu dữ liệu nên ép về ở tầng Staging (không phải kiểu thô ở Raw)

---

## NHÓM POS (Bán hàng)

### 1. `branches.csv`
| Cột | Kiểu gợi ý | PK/FK | Ghi chú |
|---|---|---|---|
| branch_id | INT/VARCHAR | PK | |
| branch_name | VARCHAR | | |
| address | VARCHAR | | |
| city / region | VARCHAR | | dùng cho phân tích theo khu vực |
| opened_date | DATE | | phục vụ tính tuổi chi nhánh |
| status | VARCHAR | | active/closed/renovating (?) |

### 2. `products.csv`
| Cột | Kiểu gợi ý | PK/FK | Ghi chú |
|---|---|---|---|
| product_id | INT/VARCHAR | PK | |
| product_name | VARCHAR | | |
| category | VARCHAR | | đồ uống/đồ ăn/combo (?) |
| price | NUMERIC | | giá bán niêm yết — **kiểm tra: giá có thay đổi theo thời gian không → cần SCD** |
| cost_price | NUMERIC | | giá vốn nếu có, phục vụ tính margin |
| is_active | BOOLEAN | | món còn bán hay đã ngừng |

### 3. `orders.csv`
| Cột | Kiểu gợi ý | PK/FK | Ghi chú |
|---|---|---|---|
| order_id | VARCHAR | PK | **Grain: 1 dòng = 1 hóa đơn** |
| branch_id | INT | FK → branches | |
| customer_id | VARCHAR | FK → customers | có thể NULL nếu khách vãng lai |
| employee_id | VARCHAR | FK → employees | nhân viên lập hóa đơn (?) |
| order_time | TIMESTAMP | | dùng tách ra `dim_date` + giờ trong ngày |
| order_channel | VARCHAR | | Dine-in/Delivery/Takeaway — **cần chuẩn hóa text (Delivery vs deliv)** |
| total_amount | NUMERIC | | ⚠️ kiểm tra không âm |
| voucher_id | VARCHAR | FK → vouchers | có thể NULL |
| order_status | VARCHAR | | completed/cancelled/refunded (?) |

### 4. `order_items.csv`
| Cột | Kiểu gợi ý | PK/FK | Ghi chú |
|---|---|---|---|
| order_id | VARCHAR | FK → orders | **Grain: 1 dòng nguồn = 1 món trong hóa đơn**; ⚠️ không JOIN trực tiếp lên `orders` rồi SUM → gây fan-out |
| product_id | INT | FK → products | |
| quantity | INT | | > 0 |
| unit_price | NUMERIC | | giá tại thời điểm bán (có thể khác `products.price` do khuyến mãi) |
| line_total | NUMERIC | | = quantity × unit_price (kiểm tra khớp) |

> File nguồn hiện không có `order_item_id` và `(order_id, product_id)` không duy nhất.
> Cần bổ sung `source_row_number` khi ingestion hoặc sinh khóa kỹ thuật ở Staging.

### 5. `payments.csv`
| Cột | Kiểu gợi ý | PK/FK | Ghi chú |
|---|---|---|---|
| payment_id | VARCHAR | PK | **Grain: 1 dòng = 1 giao dịch thanh toán** (1 order có thể có nhiều payment nếu tách hóa đơn) |
| order_id | VARCHAR | FK → orders | |
| payment_method | VARCHAR | | cash/card/e-wallet — chuẩn hóa text |
| amount | NUMERIC | | |
| paid_at | TIMESTAMP | | |

---

## NHÓM ERP / KHO

### 6. `ingredients.csv`
| Cột | Kiểu gợi ý | PK/FK | Ghi chú |
|---|---|---|---|
| ingredient_id | VARCHAR | PK | |
| ingredient_name | VARCHAR | | |
| unit | VARCHAR | | kg/lít/gói — quan trọng khi tính hao hụt |
| category | VARCHAR | | nguyên liệu tươi/khô/đông lạnh (?) |

### 7. `recipes.csv`
| Cột | Kiểu gợi ý | PK/FK | Ghi chú |
|---|---|---|---|
| recipe_id | VARCHAR | PK | |
| product_id | INT | FK → products | công thức thuộc món nào |
| ingredient_id | VARCHAR | FK → ingredients | |
| quantity_required | NUMERIC | | định lượng nguyên liệu/1 món — dùng để tính food cost |

### 8. `suppliers.csv`
| Cột | Kiểu gợi ý | PK/FK | Ghi chú |
|---|---|---|---|
| supplier_id | VARCHAR | PK | |
| supplier_name | VARCHAR | | |
| contact_info | VARCHAR | | |
| lead_time_days | INT | | thời gian giao hàng trung bình (?) |

### 9. `purchase_orders.csv`
| Cột | Kiểu gợi ý | PK/FK | Ghi chú |
|---|---|---|---|
| po_id | VARCHAR | PK | **Grain: 1 dòng = 1 đơn nhập hàng (hoặc 1 dòng nguyên liệu trong đơn — cần xác nhận)** |
| supplier_id | VARCHAR | FK → suppliers | |
| branch_id | INT | FK → branches | |
| ingredient_id | VARCHAR | FK → ingredients | |
| quantity | NUMERIC | | |
| unit_cost | NUMERIC | | |
| order_date | DATE | | |
| received_date | DATE | | có thể NULL nếu chưa nhận hàng |

### 10. `inventory_daily.csv`
| Cột | Kiểu gợi ý | PK/FK | Ghi chú |
|---|---|---|---|
| branch_id | INT | FK → branches | **Grain: 1 dòng = tồn kho của 1 nguyên liệu / 1 chi nhánh / 1 ngày** |
| ingredient_id | VARCHAR | FK → ingredients | |
| snapshot_date | DATE | | |
| beginning_stock | NUMERIC | | |
| received_qty | NUMERIC | | |
| used_qty | NUMERIC | | |
| waste_qty | NUMERIC | | dùng tính waste rate = waste_qty / (beginning + received) |
| ending_stock | NUMERIC | | Công thức nguồn: `GREATEST(0, beginning + received - used - waste)` |

---

## NHÓM HRM

### 11. `employees.csv`
| Cột | Kiểu gợi ý | PK/FK | Ghi chú |
|---|---|---|---|
| employee_id | VARCHAR | PK | |
| full_name | VARCHAR | | |
| branch_id | INT | FK → branches | chi nhánh làm việc chính |
| position | VARCHAR | | thu ngân/pha chế/quản lý (?) |
| hourly_wage | NUMERIC | | ⚠️ dữ liệu nhạy cảm — cần masking khi expose qua API |
| hire_date | DATE | | |
| status | VARCHAR | | active/resigned (?) |

### 12. `employee_shifts.csv`
| Cột | Kiểu gợi ý | PK/FK | Ghi chú |
|---|---|---|---|
| shift_id | VARCHAR | PK | **Grain: 1 dòng = 1 ca làm việc của 1 nhân viên** |
| employee_id | VARCHAR | FK → employees | |
| branch_id | INT | FK → branches | |
| shift_date | DATE | | |
| check_in | TIMESTAMP | | |
| check_out | TIMESTAMP | | |
| hours_worked | NUMERIC | | tính từ check_in/check_out hoặc có sẵn cột |

---

## NHÓM CRM / MARKETING

### 13. `customers.csv`
| Cột | Kiểu gợi ý | PK/FK | Ghi chú |
|---|---|---|---|
| customer_id | VARCHAR | PK | |
| full_name | VARCHAR | | |
| phone / email | VARCHAR | | ⚠️ PII — cân nhắc ẩn/hash khi phân tích |
| registered_date | DATE | | |
| membership_tier | VARCHAR | | (?) |

### 14. `campaigns.csv`
| Cột | Kiểu gợi ý | PK/FK | Ghi chú |
|---|---|---|---|
| campaign_id | VARCHAR | PK | |
| campaign_name | VARCHAR | | |
| start_date / end_date | DATE | | |
| budget | NUMERIC | | dùng tính ROI = (doanh thu tăng thêm − budget) / budget |
| channel | VARCHAR | | Facebook/Zalo/SMS (?) |

### 15. `vouchers.csv`
| Cột | Kiểu gợi ý | PK/FK | Ghi chú |
|---|---|---|---|
| voucher_id | VARCHAR | PK | |
| campaign_id | VARCHAR | FK → campaigns | |
| discount_type | VARCHAR | | percent/fixed_amount |
| discount_value | NUMERIC | | |
| valid_from / valid_to | DATE | | |
| usage_limit | INT | | (?) |

---

## Ma Trận Quan Hệ Giữa Các Bảng (tổng quan)

```
branches ──┬── orders ── order_items ── products ── recipes ── ingredients
           │       │                                              │
           ├── employee_shifts ── employees               inventory_daily
           │
           └── purchase_orders ── suppliers

orders ── payments
orders ── customers
orders ── vouchers ── campaigns
```

## Việc cần làm tiếp
1. Đối chiếu bảng trên với file CSV thật, sửa lại tên cột và kiểu dữ liệu chính xác.
2. Đánh dấu rõ cột nào có thể NULL, cột nào là PII (thông tin cá nhân) cần bảo vệ.
3. Xác nhận lại **grain** thật sự của `purchase_orders` và `payments` — đây là 2 bảng dễ nhầm nhất.
4. Bổ sung cột nào chưa được liệt kê nếu file thật có nhiều hơn.

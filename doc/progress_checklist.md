# Checklist Tiến Độ — Data & AI Platform F&B (20 Bước)

> Cập nhật trạng thái mỗi khi kết thúc phiên làm việc, để lần sau tiếp tục đúng chỗ đang dừng. Trạng thái: `⬜ Chưa làm` / `🟡 Đang làm` / `✅ Hoàn thành`.

| # | Bước | Trạng thái | Ghi chú / Vướng mắc |
|---|---|---|---|
| 1 | Xác định mục tiêu hệ thống | ⬜ | |
| 2 | Chuẩn bị dữ liệu nguồn (16 CSV) | ⬜ | |
| 3 | Tạo database & schema (raw/staging/warehouse/mart/audit) | ⬜ | |
| 4 | Data Ingestion (EL) | ✅ Hoàn thành | 16/16 nguồn đã ingestion thành công, có metadata và audit log. |
| 5 | Raw Layer (Bronze) | ✅ Hoàn thành | Đã xác nhận raw giữ dữ liệu thô và đủ metadata. |
| 6 | Data Quality Check | ✅ Hoàn thành | DQ Gate theo batch đã PASSED; còn cảnh báo tồn kho cần theo dõi. |
| 7 | Transform Raw → Staging | ✅ Hoàn thành | 16 bảng typed, DQ gate, idempotent load và đối chiếu row count. |
| 8 | Thiết kế Data Warehouse (Star Schema) | ⬜ | |
| 9 | Xác định Grain cho Fact Table | ⬜ | |
| 10 | Tạo Data Mart (Gold) | ⬜ | |
| 11 | Dashboard & BI | ⬜ | |
| 12 | Insight Engine | ⬜ | |
| 13 | Forecast Engine | ⬜ | |
| 14 | AI Daily Report | ⬜ | |
| 15 | AI Agent hỏi đáp | ⬜ | |
| 16 | Orchestration | ⬜ | |
| 17 | Monitoring & Audit | ⬜ | |
| 18 | API Service | ⬜ | |
| 19 | Cấu trúc thư mục dự án | ⬜ | |
| 20 | Triển khai theo thứ tự thực tế | ⬜ | |

---

## Nhật ký phiên làm việc (Working Log)

> Mỗi lần làm việc, thêm 1 dòng mới bên dưới để giữ ngữ cảnh cho phiên sau.

| Ngày | Bước đang làm | Việc đã làm | Việc cần làm tiếp theo |
|---|---|---|---|
| 2026-07-05 | Bước 6 | Hoàn thiện DQ Gate gồm key, validity, FK, business rule và reconciliation. | Xử lý cảnh báo tồn kho rồi bắt đầu Raw → Staging. |
| 2026-07-05 | Bước 7 | Nạp 724.424 dòng vào 16 bảng staging; chuẩn hóa kiểu/text và kiểm thử chạy lại. | Thiết kế Star Schema và xác định grain Fact. |

---

## Rủi ro / Nợ kỹ thuật cần quay lại xử lý

> Ghi lại những chỗ bạn tạm bỏ qua để làm nhanh (technical debt), tránh quên mất.

- [ ] Ví dụ: `purchase_orders` grain chưa xác nhận rõ (1 đơn hay 1 dòng nguyên liệu?)
- [ ] Ví dụ: `dim_product` chưa áp dụng SCD Type 2 cho lịch sử giá
- [ ] `order_items.csv` không có `order_item_id`; `(order_id, product_id)` không duy nhất nên chưa thể định danh tuyệt đối từng dòng nguồn.
- [ ] Điều tra cảnh báo `STOCK_USAGE_EXCEEDS_AVAILABLE` trước khi thiết kế logic tồn kho ở Staging.
- [ ] ...

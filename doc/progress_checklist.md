# Checklist Tiến Độ — Data & AI Platform F&B (20 Bước)

> Cập nhật trạng thái mỗi khi kết thúc phiên làm việc, để lần sau tiếp tục đúng chỗ đang dừng. Trạng thái: `⬜ Chưa làm` / `🟡 Đang làm` / `✅ Hoàn thành`.

| # | Bước | Trạng thái | Ghi chú / Vướng mắc |
|---|---|---|---|
| 1 | Xác định mục tiêu hệ thống | ⬜ | |
| 2 | Chuẩn bị dữ liệu nguồn (16 CSV) | ⬜ | |
| 3 | Tạo database & schema (raw/staging/warehouse/mart/audit) | ⬜ | |
| 4 | Data Ingestion (EL) | ⬜ | |
| 5 | Raw Layer (Bronze) | ⬜ | |
| 6 | Data Quality Check | ⬜ | |
| 7 | Transform Raw → Staging | ⬜ | |
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
| | | | |

---

## Rủi ro / Nợ kỹ thuật cần quay lại xử lý

> Ghi lại những chỗ bạn tạm bỏ qua để làm nhanh (technical debt), tránh quên mất.

- [ ] Ví dụ: `purchase_orders` grain chưa xác nhận rõ (1 đơn hay 1 dòng nguyên liệu?)
- [ ] Ví dụ: `dim_product` chưa áp dụng SCD Type 2 cho lịch sử giá
- [ ] ...

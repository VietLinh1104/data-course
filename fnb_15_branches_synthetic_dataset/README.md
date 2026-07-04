# F&B Synthetic Dataset - 15 Branches

Bộ dữ liệu giả lập cho chuỗi F&B 15 chi nhánh, dùng để demo Data Warehouse, Dashboard, Forecast và AI Agent.

## Thời gian
- Từ: 2025-12-01
- Đến: 2026-05-31
- Số tháng: khoảng 6 tháng

## Quy mô
- 15 chi nhánh
- 50 món/sản phẩm
- 80 nguyên liệu/vật tư
- 100,000 hóa đơn POS
- 229,014 dòng order item
- 30,000 khách hàng
- 218,400 dòng tồn kho ngày
- 35,100 dòng ca làm nhân viên
- 11,231 phiếu nhập nguyên liệu

## Gợi ý fact/dim
- fact_sales: orders + order_items + payments
- fact_inventory: inventory_daily + purchase_orders
- fact_labor: employee_shifts
- dim_branch: branches
- dim_product: products
- dim_ingredient: ingredients
- dim_customer: customers
- dim_employee: employees
- dim_campaign: campaigns + vouchers

## Bài toán demo
1. Doanh thu theo ngày/chi nhánh/kênh/món
2. AOV, số bill, top món bán chạy
3. Food cost theo recipe + giá nhập
4. Tồn kho và cảnh báo sắp hết hàng
5. Waste/hao hụt nguyên liệu
6. Labor cost %, doanh thu/giờ công
7. Hiệu quả campaign/voucher
8. Khách quay lại, phân khúc khách hàng
9. Forecast doanh thu/nguyên liệu/ngày mai
10. AI Agent hỏi đáp dữ liệu bằng tiếng Việt

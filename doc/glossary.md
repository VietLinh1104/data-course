# Bảng Thuật Ngữ — Data Engineering (Anh - Việt)

| Thuật ngữ | Giải thích ngắn |
|---|---|
| **OLTP** (Online Transaction Processing) | Hệ thống tối ưu cho ghi/giao dịch nhanh, chuẩn hóa cao (3NF). Ví dụ: hệ thống POS gốc. |
| **OLAP** (Online Analytical Processing) | Hệ thống tối ưu cho đọc/phân tích số liệu lớn. Ví dụ: Data Warehouse. |
| **ETL / ELT** | Extract-Transform-Load vs Extract-Load-Transform. ELT nạp thô trước, biến đổi sau bằng SQL ngay trong kho dữ liệu. |
| **Medallion Architecture** | Kiến trúc phân lớp Bronze (Raw) → Silver (Staging/Warehouse) → Gold (Mart). |
| **Data Lineage** | Khả năng truy vết một dòng dữ liệu về nguồn gốc (file nào, batch nào, lúc nào được nạp). |
| **Immutability** | Dữ liệu tầng Raw không bao giờ bị sửa đổi sau khi ghi — đảm bảo có thể replay pipeline. |
| **Replayability** | Khả năng chạy lại toàn bộ pipeline từ đầu (từ Raw) khi phát hiện lỗi logic ở tầng sau. |
| **GIGO** (Garbage In, Garbage Out) | Dữ liệu đầu vào lỗi → mọi kết quả phân tích/dự báo phía sau cũng sai. |
| **Data Drift / Schema Drift** | Hiện tượng cấu trúc hoặc phân phối dữ liệu nguồn thay đổi bất ngờ theo thời gian. |
| **Dimensional Modeling (Kimball)** | Phương pháp mô hình hóa kho dữ liệu bằng Fact (chỉ số) và Dimension (ngữ cảnh mô tả). |
| **Fact Table** | Bảng chứa các số đo định lượng, biến động liên tục (doanh thu, số lượng...). |
| **Dimension Table** | Bảng chứa thông tin mô tả, ít thay đổi (ai, cái gì, ở đâu, khi nào). |
| **Grain** | Định nghĩa rõ "1 dòng trong bảng Fact tương ứng với cái gì" — phải xác định trước khi thiết kế. |
| **Fan-out Effect** | Lỗi nhân đôi số liệu khi JOIN 2 bảng có grain khác nhau rồi SUM sai cách. |
| **Star Schema** | Mô hình giải chuẩn hóa (denormalized) các bảng Dim, giảm số lượng JOIN. |
| **Snowflake Schema** | Mô hình chuẩn hóa các bảng Dim thành nhiều bảng con, tốn nhiều JOIN hơn Star Schema. |
| **Surrogate Key** | Khóa nhân tạo (thường là số tự tăng), độc lập với khóa nghiệp vụ, dùng trong Dimension. |
| **Natural Key / Business Key** | Khóa định danh gốc theo nghiệp vụ (ví dụ mã sản phẩm từ hệ thống nguồn). |
| **SCD** (Slowly Changing Dimension) | Kỹ thuật quản lý thay đổi giá trị của Dimension theo thời gian. Type 1 = ghi đè; Type 2 = giữ lịch sử bằng valid_from/valid_to. |
| **Pre-aggregation** | Tính toán tổng hợp trước ở tầng Mart để BI/AI truy vấn nhanh, không phải quét lại Fact thô mỗi lần. |
| **Data Mart** | Tập hợp bảng/view đã tổng hợp sẵn KPI phục vụ một nhóm nghiệp vụ cụ thể. |
| **Idempotency** | Tính chất: chạy lại cùng một bước nhiều lần vẫn cho ra kết quả giống hệt, không tạo dữ liệu trùng. |
| **Backfill** | Nạp/tính toán lại dữ liệu cho các ngày trong quá khứ (ví dụ khi mới thêm 1 cột KPI mới). |
| **Data Observability** | Khả năng giám sát "sức khỏe" của hệ thống dữ liệu: độ trễ, khối lượng, chất lượng, lineage. |
| **SLA** (Service Level Agreement) | Cam kết về thời gian/độ tin cậy, ví dụ: "DWH phải sẵn sàng trước 7h sáng". |
| **DAG** (Directed Acyclic Graph) | Đồ thị có hướng không chu trình — mô hình biểu diễn thứ tự phụ thuộc giữa các bước trong pipeline. |
| **Orchestration** | Việc điều phối tự động thứ tự và điều kiện chạy các bước trong pipeline (ví dụ: Airflow, Dagster). |
| **Descriptive / Diagnostic / Predictive Analytics** | 3 cấp độ phân tích: Mô tả (chuyện gì xảy ra) → Chẩn đoán (tại sao xảy ra) → Dự đoán (điều gì sẽ xảy ra). |
| **Management by Exception** | Nguyên tắc quản lý: chỉ tập trung vào các trường hợp bất thường/vượt ngưỡng thay vì xem toàn bộ dữ liệu. |
| **Seasonality / Trend / Noise** | 3 thành phần của chuỗi thời gian: tính chu kỳ, xu hướng, và nhiễu ngẫu nhiên. |
| **Semantic Layer** | Lớp trung gian (thường là API) chuẩn hóa cách truy vấn dữ liệu, dùng chung cho Dashboard và AI Agent. |
| **Text-to-SQL** | Kỹ thuật để LLM tự sinh câu lệnh SQL từ ngôn ngữ tự nhiên — rủi ro cao nếu chạy trực tiếp trên DB sản xuất. |
| **Tool Calling** | Cơ chế AI Agent gọi các hàm/API đã được lập trình sẵn thay vì tự viết SQL tùy tiện. |
| **PII** (Personally Identifiable Information) | Thông tin định danh cá nhân (SĐT, email, lương...) — cần bảo vệ/masking khi expose ra ngoài. |
| **Row-Level Security (RLS)** | Cơ chế giới hạn quyền xem dữ liệu theo từng dòng, dựa trên vai trò người dùng. |
| **Materialized View** | View được lưu trữ vật lý kết quả tính toán, cần refresh định kỳ, giúp truy vấn nhanh hơn View thường. |
| **Lakehouse** | Kiến trúc kết hợp tính linh hoạt của Data Lake (lưu file thô) và khả năng truy vấn có cấu trúc của Data Warehouse. |
| **Parquet** | Định dạng file lưu trữ dạng cột (columnar), nén tốt, đọc nhanh cho khối lượng lớn — thường dùng thay CSV ở tầng Bronze hiện đại. |
| **DuckDB** | Cơ sở dữ liệu phân tích nhúng (embedded), không cần server, truy vấn trực tiếp trên file Parquet/CSV. |
| **dbt** (Data Build Tool) | Công cụ quản lý các bước transform bằng SQL model, tự động quản lý lineage và cho phép viết test. |

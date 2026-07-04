# Raw to Staging

`scripts/run_staging.py` chạy các file SQL trong thư mục này theo thứ tự tên file.
Job chỉ nhận batch có trạng thái DQ mới nhất là `DQ_PASSED`.

Mỗi lần chạy lại, job xóa dữ liệu staging của đúng batch rồi nạp lại trong cùng
một transaction. Trước khi commit, job đối chiếu row count từng bảng raw–staging.
Nếu lệch dòng, toàn bộ transaction bị rollback. Dữ liệu raw không bị thay đổi.

```bash
source .venv/bin/activate
python scripts/run_staging.py
```

Hoặc chỉ định batch:

```bash
python scripts/run_staging.py --batch-id <UUID>
```

# Raw Data Quality Gate

Các file SQL trong thư mục này được `scripts/run_dq.py` chạy theo thứ tự tên file.
Mỗi file ghi lỗi trực tiếp vào `audit.data_quality_errors` cho một `batch_id`.

## Nhóm rule

- `01_key_checks.sql`: khóa thiếu và khóa trùng.
- `02_validity.sql`: kiểu dữ liệu và miền giá trị.
- `03_referential.sql`: khóa ngoại không tồn tại.
- `04_business_rules.sql`: quy tắc nghiệp vụ và công thức.
- `05_reconciliation.sql`: đối soát orders, order items và payments.

## Chạy

```bash
source .venv/bin/activate
python scripts/run_dq.py
```

Chạy một batch cụ thể:

```bash
python scripts/run_dq.py --batch-id <UUID>
```

Exit code:

- `0`: DQ Gate đạt (`DQ_PASSED`).
- `1`: có lỗi severity `ERROR` (`DQ_FAILED`).
- `2`: runner hoặc SQL gặp lỗi kỹ thuật (`FAILED`).

Runner xóa và tạo lại riêng kết quả `pipeline_step = 'DQ_RAW'` của batch nên có
thể chạy lại mà không nhân đôi lỗi. Log ingestion của batch vẫn được giữ nguyên.

import os
import uuid
import logging
from pathlib import Path
from datetime import datetime
from typing import Optional

import pandas as pd
# pyrefly: ignore [missing-import]
from dotenv import load_dotenv
# pyrefly: ignore [missing-import]
from sqlalchemy import create_engine, text


load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
RAW_DATA_DIR = Path(os.getenv("RAW_DATA_DIR", "data/raw_files"))

engine = create_engine(DATABASE_URL)

CHUNK_SIZE = 1000

CSV_TO_TABLE = {
    # "branches.csv": "branches",
    # "campaigns.csv": "campaigns",
    # "customers.csv": "customers",
    # "data_dictionary.csv": "data_dictionary",
    # "employee_shifts.csv": "employee_shifts",
    # "employees.csv": "employees",
    # "ingredients.csv": "ingredients",
    # "inventory_daily.csv": "inventory_daily",
    # "order_items.csv": "order_items",
    "orders.csv": "orders",
    "payments.csv": "payments",
    "products.csv": "products",
    "purchase_orders.csv": "purchase_orders",
    "recipes.csv": "recipes",
    "suppliers.csv": "suppliers",
    "vouchers.csv": "vouchers",
}


def setup_logger():
    log_dir = Path("logs")
    log_dir.mkdir(exist_ok=True)

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)s | %(message)s",
        handlers=[
            logging.FileHandler(log_dir / "ingest_raw.log", encoding="utf-8"),
            logging.StreamHandler(),
        ],
    )


def create_ingestion_log(batch_id: str, csv_name: str, table_name: str, status: str):
    with engine.begin() as conn:
        result = conn.execute(
            text("""
                INSERT INTO metadata.ingestion_logs (
                    batch_id,
                    source_file_name,
                    target_schema,
                    target_table,
                    status,
                    started_at,
                    updated_at
                )
                VALUES (
                    :batch_id,
                    :source_file_name,
                    'raw',
                    :target_table,
                    :status,
                    NOW(),
                    NOW()
                )
                RETURNING id;
            """),
            {
                "batch_id": batch_id,
                "source_file_name": csv_name,
                "target_table": table_name,
                "status": status,
            }
        )

        return result.scalar_one()

def update_ingestion_log(
    log_id: int,
    status: str,
    rows_total: int = 0,
    rows_inserted: int = 0,
    error_message: Optional[str] = None,
    ended: bool = False,
):
    ended_sql = "ended_at = NOW()," if ended else ""

    with engine.begin() as conn:
        conn.execute(
            text(f"""
                UPDATE metadata.ingestion_logs
                SET
                    status = :status,
                    rows_total = :rows_total,
                    rows_inserted = :rows_inserted,
                    error_message = :error_message,
                    {ended_sql}
                    updated_at = NOW()
                WHERE id = :log_id;
            """),
            {
                "log_id": log_id,
                "status": status,
                "rows_total": rows_total,
                "rows_inserted": rows_inserted,
                "error_message": error_message,
            }
        )


def load_csv_to_raw(csv_file: Path, table_name: str, batch_id: str):
    log_id = create_ingestion_log(
        batch_id=batch_id,
        csv_name=csv_file.name,
        table_name=table_name,
        status="STARTED",
    )

    rows_total = 0
    rows_inserted = 0

    try:
        logging.info(f"Loading {csv_file.name} -> raw.{table_name}")

        df = pd.read_csv(csv_file, dtype=str)

        # Xử lý cột rác nếu CSV bị thừa
        df = df.drop(columns=["f"], errors="ignore")

        # Thêm metadata bắt buộc cho raw layer
        df["batch_id"] = batch_id
        df["source_file_name"] = csv_file.name
        df["loaded_at"] = datetime.now()

        rows_total = len(df)

        update_ingestion_log(
            log_id=log_id,
            status="RUNNING",
            rows_total=rows_total,
            rows_inserted=0,
        )

        for start in range(0, rows_total, CHUNK_SIZE):
            end = start + CHUNK_SIZE
            chunk_df = df.iloc[start:end]

            with engine.begin() as conn:
                chunk_df.to_sql(
                    name=table_name,
                    con=conn,
                    schema="raw",
                    if_exists="append",
                    index=False,
                    method="multi",
                )

            rows_inserted += len(chunk_df)

            update_ingestion_log(
                log_id=log_id,
                status="RUNNING",
                rows_total=rows_total,
                rows_inserted=rows_inserted,
            )

            logging.info(
                f"{csv_file.name}: inserted {rows_inserted}/{rows_total} rows"
            )

        update_ingestion_log(
            log_id=log_id,
            status="SUCCESS",
            rows_total=rows_total,
            rows_inserted=rows_inserted,
            ended=True,
        )

        logging.info(f"Done: {csv_file.name}, rows={rows_inserted}")

    except Exception as e:
        error_message = str(e)[:5000]

        update_ingestion_log(
            log_id=log_id,
            status="FAILED",
            rows_total=rows_total,
            rows_inserted=rows_inserted,
            error_message=error_message,
            ended=True,
        )

        logging.exception(
            f"Failed: {csv_file.name} -> raw.{table_name}, inserted={rows_inserted}/{rows_total}"
        )

        raise


def main():
    setup_logger()
    batch_id = str(uuid.uuid4())

    success_count = 0
    failed_count = 0
    skipped_count = 0

    logging.info(f"Start ingestion batch_id={batch_id}")

    for csv_name, table_name in CSV_TO_TABLE.items():
        csv_file = RAW_DATA_DIR / csv_name

        if not csv_file.exists():
            skipped_count += 1

            log_id = create_ingestion_log(
                batch_id=batch_id,
                csv_name=csv_name,
                table_name=table_name,
                status="SKIPPED",
            )

            update_ingestion_log(
                log_id=log_id,
                status="SKIPPED",
                error_message=f"File not found: {csv_file}",
                ended=True,
            )

            logging.warning(f"Skip: file not found {csv_file}")
            continue

        try:
            load_csv_to_raw(csv_file, table_name, batch_id)
            success_count += 1

        except Exception:
            failed_count += 1

            # Không dừng toàn bộ batch.
            # File lỗi sẽ được ghi log, script tiếp tục chạy file sau.
            continue

    logging.info(
        f"Finished raw ingestion | batch_id={batch_id} | success={success_count} | failed={failed_count} | skipped={skipped_count}"
    )


if __name__ == "__main__":
    main()
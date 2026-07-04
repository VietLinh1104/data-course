import os
import uuid
import logging
from pathlib import Path
from datetime import datetime

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

from src.logger.logger import setup_logger
from src.audit.pipeline_runs import (
    create_data_quality_errors,
    create_pipeline_run_log,
    update_pipeline_run_log,
)


load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
RAW_DATA_DIR = Path(os.getenv("RAW_DATA_DIR", "data/raw_files"))

engine = create_engine(DATABASE_URL)

CHUNK_SIZE = 1000

CSV_TO_TABLE = {
    "branches.csv": "branches",
    "campaigns.csv": "campaigns",
    "customers.csv": "customers",
    "data_dictionary.csv": "data_dictionary",
    "employee_shifts.csv": "employee_shifts",
    "employees.csv": "employees",
    "ingredients.csv": "ingredients",
    "inventory_daily.csv": "inventory_daily",
    "order_items.csv": "order_items",
    "orders.csv": "orders",
    "payments.csv": "payments",
    "products.csv": "products",
    "purchase_orders.csv": "purchase_orders",
    "recipes.csv": "recipes",
    "suppliers.csv": "suppliers",
    "vouchers.csv": "vouchers",
}

def load_csv_to_raw(csv_file: Path, table_name: str, batch_id: str):
    run_id = create_pipeline_run_log(
        batch_id=batch_id,
        pipeline_step="INGESTION_RAW",
        status="STARTED",
        row_count=0,
        error_message=None,
    )

    rows_total = 0
    rows_inserted = 0
    row_identifier = None

    try:
        logging.info(f"Loading {csv_file.name} -> raw.{table_name}")

        df = pd.read_csv(csv_file, dtype=str)

        # Ghi nhận cột ngoài schema trước khi loại bỏ để ingestion tiếp tục.
        unexpected_columns = [column for column in ["f"] if column in df.columns]
        for column in unexpected_columns:
            non_null_rows = int(df[column].notna().sum())
            create_data_quality_errors(
                batch_id=batch_id,
                source_table=table_name,
                row_identifier=None,
                pipeline_step="INGESTION_RAW",
                error_type="UNEXPECTED_COLUMN",
                error_detail=(
                    f"Removed unexpected column '{column}' from {csv_file.name}; "
                    f"non_null_rows={non_null_rows}"
                ),
            )

        df = df.drop(columns=unexpected_columns)

        # Thêm metadata bắt buộc cho raw layer
        df["batch_id"] = batch_id
        df["source_file_name"] = csv_file.name
        df["loaded_at"] = datetime.now()

        rows_total = len(df)

        update_pipeline_run_log(
            run_id=run_id,
            status="RUNNING",
            row_count=rows_total,
        )

        for start in range(0, rows_total, CHUNK_SIZE):
            end = start + CHUNK_SIZE
            chunk_df = df.iloc[start:end]
            row_identifier = (
                f"csv_rows={start + 2}-{min(end, rows_total) + 1}"
            )

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

            update_pipeline_run_log(
                run_id=run_id,
                status="RUNNING",
                row_count=rows_total,
            )

            logging.info(
                f"{csv_file.name}: inserted {rows_inserted}/{rows_total} rows"
            )

        update_pipeline_run_log(
            run_id=run_id,
            status="SUCCESS",
            row_count=rows_total,
            ended=True,
        )

        logging.info(f"Done: {csv_file.name}, rows={rows_inserted}")

    except Exception as e:
        error_message = str(e)[:5000]

        update_pipeline_run_log(
            run_id=run_id,
            status="FAILED",
            row_count=rows_inserted,
            error_message=error_message,
            ended=True,
        )

        create_data_quality_errors(
            batch_id=batch_id,
            source_table=table_name,
            row_identifier=row_identifier,
            pipeline_step="INGESTION_RAW",
            error_type="PROCESSING_ERROR",
            error_detail=error_message,
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

            run_id = create_pipeline_run_log(
                batch_id=batch_id,
                pipeline_step="INGESTION_RAW",
                status="SKIPPED",
                row_count=0,
                error_message=f"File not found: {csv_file}",
            )

            update_pipeline_run_log(
                run_id=run_id,
                status="SKIPPED",
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

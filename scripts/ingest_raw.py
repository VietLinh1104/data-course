import logging
import os
import sys
import uuid
from datetime import datetime
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.engine import Engine

from src.logger.logger import setup_logger
from src.audit.pipeline_runs import (
    create_data_quality_errors,
    create_pipeline_run_log,
    update_pipeline_run_log,
)


PROJECT_ROOT = Path(__file__).resolve().parents[1]
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

def build_engine() -> Engine:
    load_dotenv(PROJECT_ROOT / ".env")
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        raise RuntimeError("DATABASE_URL is not configured")
    return create_engine(database_url, pool_pre_ping=True)


def get_raw_data_dir() -> Path:
    configured_path = Path(os.getenv("RAW_DATA_DIR", "data/raw_files"))
    if configured_path.is_absolute():
        return configured_path
    return PROJECT_ROOT / configured_path


def load_csv_to_raw(
    engine: Engine,
    csv_file: Path,
    table_name: str,
    batch_id: str,
) -> int:
    run_id = create_pipeline_run_log(
        engine=engine,
        batch_id=batch_id,
        pipeline_step="INGESTION_RAW",
        status="STARTED",
        row_count=0,
        error_message=None,
    )

    rows_processed = 0
    row_identifier = None
    unexpected_column_counts: dict[str, int] = {}

    try:
        logging.info("Loading %s -> raw.%s", csv_file.name, table_name)
        loaded_at = datetime.now()
        chunks = pd.read_csv(csv_file, dtype=str, chunksize=CHUNK_SIZE)

        # Một file là một transaction: chunk sau lỗi thì không để raw bị nạp dở.
        with engine.begin() as conn:
            for chunk_df in chunks:
                start = rows_processed
                rows_processed += len(chunk_df)
                row_identifier = f"csv_rows={start + 2}-{rows_processed + 1}"

                # Ghi nhận cột ngoài schema trước khi loại bỏ.
                unexpected_columns = [
                    column for column in ["f"] if column in chunk_df.columns
                ]
                for column in unexpected_columns:
                    unexpected_column_counts[column] = (
                        unexpected_column_counts.get(column, 0)
                        + int(chunk_df[column].notna().sum())
                    )

                chunk_df = chunk_df.drop(columns=unexpected_columns)
                chunk_df["batch_id"] = batch_id
                chunk_df["source_file_name"] = csv_file.name
                chunk_df["loaded_at"] = loaded_at

                chunk_df.to_sql(
                    name=table_name,
                    con=conn,
                    schema="raw",
                    if_exists="append",
                    index=False,
                    method="multi",
                )

                update_pipeline_run_log(
                    engine=engine,
                    run_id=run_id,
                    status="RUNNING",
                    row_count=rows_processed,
                )
                logging.info(
                    "%s: processed %s rows", csv_file.name, rows_processed
                )

        for column, non_null_rows in unexpected_column_counts.items():
            create_data_quality_errors(
                engine=engine,
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

        update_pipeline_run_log(
            engine=engine,
            run_id=run_id,
            status="SUCCESS",
            row_count=rows_processed,
            ended=True,
        )
        logging.info("Done: %s, rows=%s", csv_file.name, rows_processed)
        return rows_processed

    except Exception as exc:
        error_message = str(exc)[:5000]

        update_pipeline_run_log(
            engine=engine,
            run_id=run_id,
            status="FAILED",
            # Transaction cấp file đã rollback nên không có dòng nào được commit.
            row_count=0,
            error_message=error_message,
            ended=True,
        )

        create_data_quality_errors(
            engine=engine,
            batch_id=batch_id,
            source_table=table_name,
            row_identifier=row_identifier,
            pipeline_step="INGESTION_RAW",
            error_type="PROCESSING_ERROR",
            error_detail=error_message,
        )

        logging.exception(
            "Failed: %s -> raw.%s, transaction rolled back after %s rows",
            csv_file.name,
            table_name,
            rows_processed,
        )
        raise


def main() -> int:
    setup_logger()
    engine = build_engine()
    raw_data_dir = get_raw_data_dir()
    batch_id = str(uuid.uuid4())

    success_count = 0
    failed_count = 0
    skipped_count = 0

    logging.info("Start ingestion batch_id=%s", batch_id)

    try:
        for csv_name, table_name in CSV_TO_TABLE.items():
            csv_file = raw_data_dir / csv_name

            if not csv_file.exists():
                skipped_count += 1
                run_id = create_pipeline_run_log(
                    engine=engine,
                    batch_id=batch_id,
                    pipeline_step="INGESTION_RAW",
                    status="SKIPPED",
                    row_count=0,
                    error_message=f"File not found: {csv_file}",
                )
                update_pipeline_run_log(
                    engine=engine,
                    run_id=run_id,
                    status="SKIPPED",
                    ended=True,
                )
                logging.warning("Skip: file not found %s", csv_file)
                continue

            try:
                load_csv_to_raw(engine, csv_file, table_name, batch_id)
                success_count += 1
            except Exception:
                failed_count += 1
                # Ghi lỗi theo file rồi tiếp tục để có báo cáo đầy đủ cho batch.
                continue
    finally:
        engine.dispose()

    logging.info(
        "Finished raw ingestion | batch_id=%s | success=%s | failed=%s | skipped=%s",
        batch_id,
        success_count,
        failed_count,
        skipped_count,
    )
    return 1 if failed_count or skipped_count else 0


if __name__ == "__main__":
    sys.exit(main())

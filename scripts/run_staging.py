import argparse
import logging
import os
import sys
import uuid
from pathlib import Path
from typing import Optional

from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Connection, Engine

from src.logger.logger import setup_logger


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DDL_FILE = PROJECT_ROOT / "database" / "ddl" / "01_staging.sql"
LOAD_DIR = PROJECT_ROOT / "database" / "staging"
PIPELINE_STEP = "RAW_TO_STAGING"
DQ_PIPELINE_STEP = "DQ_RAW"

TABLE_MAPPINGS = (
    ("branches", "stg_branches"),
    ("campaigns", "stg_campaigns"),
    ("customers", "stg_customers"),
    ("data_dictionary", "stg_data_dictionary"),
    ("employee_shifts", "stg_employee_shifts"),
    ("employees", "stg_employees"),
    ("ingredients", "stg_ingredients"),
    ("inventory_daily", "stg_inventory_daily"),
    ("order_items", "stg_order_items"),
    ("orders", "stg_orders"),
    ("payments", "stg_payments"),
    ("products", "stg_products"),
    ("purchase_orders", "stg_purchase_orders"),
    ("recipes", "stg_recipes"),
    ("suppliers", "stg_suppliers"),
    ("vouchers", "stg_vouchers"),
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Load a DQ-passed raw batch to staging")
    parser.add_argument(
        "--batch-id",
        help="Ingestion batch UUID. Defaults to the latest DQ-passed batch.",
    )
    return parser.parse_args()


def build_engine() -> Engine:
    load_dotenv(PROJECT_ROOT / ".env")
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        raise RuntimeError("DATABASE_URL is not configured")
    return create_engine(database_url, pool_pre_ping=True)


def validate_batch_id(batch_id: str) -> str:
    try:
        return str(uuid.UUID(batch_id))
    except ValueError as exc:
        raise ValueError(f"Invalid batch UUID: {batch_id}") from exc


def apply_staging_ddl(engine: Engine) -> None:
    ddl = DDL_FILE.read_text(encoding="utf-8")
    with engine.begin() as conn:
        conn.exec_driver_sql(ddl)


def find_latest_dq_passed_batch(conn: Connection) -> Optional[str]:
    return conn.execute(
        text(
            """
            WITH latest_dq_run AS (
                SELECT DISTINCT ON (batch_id)
                       batch_id, status, finished_at, run_id
                FROM audit.pipeline_runs
                WHERE pipeline_step = :dq_pipeline_step
                ORDER BY batch_id, run_id DESC
            )
            SELECT batch_id::TEXT
            FROM latest_dq_run
            WHERE status = 'DQ_PASSED'
            ORDER BY finished_at DESC NULLS LAST, run_id DESC
            LIMIT 1
            """
        ),
        {"dq_pipeline_step": DQ_PIPELINE_STEP},
    ).scalar_one_or_none()


def assert_dq_passed(conn: Connection, batch_id: str) -> None:
    latest_status = conn.execute(
        text(
            """
            SELECT status
            FROM audit.pipeline_runs
            WHERE batch_id = CAST(:batch_id AS UUID)
              AND pipeline_step = :dq_pipeline_step
            ORDER BY run_id DESC
            LIMIT 1
            """
        ),
        {"batch_id": batch_id, "dq_pipeline_step": DQ_PIPELINE_STEP},
    ).scalar_one_or_none()

    if latest_status != "DQ_PASSED":
        raise RuntimeError(
            f"Batch {batch_id} is not eligible for staging; "
            f"latest DQ status={latest_status or 'NOT_FOUND'}"
        )


def create_run(engine: Engine, batch_id: str) -> int:
    with engine.begin() as conn:
        return conn.execute(
            text(
                """
                INSERT INTO audit.pipeline_runs (
                    batch_id, pipeline_step, started_at, status, row_count
                )
                VALUES (CAST(:batch_id AS UUID), :pipeline_step, NOW(), 'RUNNING', 0)
                RETURNING run_id
                """
            ),
            {"batch_id": batch_id, "pipeline_step": PIPELINE_STEP},
        ).scalar_one()


def finish_run(
    engine: Engine,
    run_id: int,
    status: str,
    row_count: int,
    error_message: Optional[str] = None,
) -> None:
    with engine.begin() as conn:
        conn.execute(
            text(
                """
                UPDATE audit.pipeline_runs
                SET status = :status,
                    row_count = :row_count,
                    error_message = :error_message,
                    finished_at = NOW()
                WHERE run_id = :run_id
                """
            ),
            {
                "run_id": run_id,
                "status": status,
                "row_count": row_count,
                "error_message": error_message,
            },
        )


def load_staging(engine: Engine, batch_id: str) -> int:
    load_files = sorted(LOAD_DIR.glob("*.sql"))
    if not load_files:
        raise RuntimeError(f"No staging SQL files found in {LOAD_DIR}")

    total_rows = 0
    with engine.begin() as conn:
        # Chặn hai job cùng ghi một batch; lock tự nhả khi transaction kết thúc.
        conn.execute(text("SELECT pg_advisory_xact_lock(hashtext(:batch_id))"), {"batch_id": batch_id})

        for _, staging_table in TABLE_MAPPINGS:
            conn.execute(
                text(
                    f"DELETE FROM staging.{staging_table} "
                    "WHERE batch_id = CAST(:batch_id AS UUID)"
                ),
                {"batch_id": batch_id},
            )

        for load_file in load_files:
            result = conn.execute(
                text(load_file.read_text(encoding="utf-8")),
                {"batch_id": batch_id},
            )
            inserted = max(result.rowcount or 0, 0)
            total_rows += inserted
            logging.info("Staging load %s: rows=%s", load_file.name, inserted)

        for raw_table, staging_table in TABLE_MAPPINGS:
            raw_count = conn.execute(
                text(f"SELECT COUNT(*) FROM raw.{raw_table} WHERE batch_id = :batch_id"),
                {"batch_id": batch_id},
            ).scalar_one()
            staging_count = conn.execute(
                text(
                    f"SELECT COUNT(*) FROM staging.{staging_table} "
                    "WHERE batch_id = CAST(:batch_id AS UUID)"
                ),
                {"batch_id": batch_id},
            ).scalar_one()
            if raw_count != staging_count:
                raise RuntimeError(
                    f"Row count mismatch raw.{raw_table}={raw_count}, "
                    f"staging.{staging_table}={staging_count}"
                )

    return total_rows


def main() -> int:
    setup_logger()
    args = parse_args()
    engine = build_engine()
    run_id = None

    try:
        apply_staging_ddl(engine)

        with engine.connect() as conn:
            batch_id = args.batch_id or find_latest_dq_passed_batch(conn)

        if not batch_id:
            raise RuntimeError(
                "No DQ-passed batch found; run scripts/run_dq.py first "
                "or pass --batch-id explicitly"
            )

        batch_id = validate_batch_id(batch_id)
        with engine.connect() as conn:
            assert_dq_passed(conn, batch_id)

        run_id = create_run(engine, batch_id)
        logging.info("Start raw-to-staging batch_id=%s run_id=%s", batch_id, run_id)

        total_rows = load_staging(engine, batch_id)
        finish_run(engine, run_id, "SUCCESS", total_rows)
        logging.info(
            "Finished raw-to-staging batch_id=%s status=SUCCESS rows=%s",
            batch_id,
            total_rows,
        )
        return 0

    except Exception as exc:
        logging.exception("Raw-to-staging execution failed")
        if run_id is not None:
            finish_run(engine, run_id, "FAILED", 0, str(exc)[:5000])
        return 2
    finally:
        engine.dispose()


if __name__ == "__main__":
    sys.exit(main())

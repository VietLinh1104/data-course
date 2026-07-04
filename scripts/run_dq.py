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
DDL_FILE = PROJECT_ROOT / "database" / "ddl" / "02_dq.sql"
DQ_DIR = PROJECT_ROOT / "database" / "dq"
PIPELINE_STEP = "DQ_RAW"
EXPECTED_SOURCE_COUNT = 16
EXPECTED_RAW_TABLES = (
    "branches",
    "campaigns",
    "customers",
    "data_dictionary",
    "employee_shifts",
    "employees",
    "ingredients",
    "inventory_daily",
    "order_items",
    "orders",
    "payments",
    "products",
    "purchase_orders",
    "recipes",
    "suppliers",
    "vouchers",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run raw-layer data quality gate")
    parser.add_argument(
        "--batch-id",
        help="Ingestion batch UUID. Defaults to the latest complete ingestion batch.",
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


def find_latest_complete_batch(conn: Connection) -> Optional[str]:
    batch_sources = " UNION ALL ".join(
        f"""
        SELECT batch_id, MAX(loaded_at) AS latest_loaded_at,
               '{table_name}' AS source_table
        FROM raw.{table_name}
        GROUP BY batch_id
        """
        for table_name in EXPECTED_RAW_TABLES
    )

    result = conn.execute(
        text(
            f"""
            SELECT batch_id
            FROM ({batch_sources}) AS raw_batches
            GROUP BY batch_id
            HAVING COUNT(DISTINCT source_table) = :expected_source_count
            ORDER BY MAX(latest_loaded_at) DESC
            LIMIT 1
            """
        ),
        {"expected_source_count": EXPECTED_SOURCE_COUNT},
    )
    return result.scalar_one_or_none()


def apply_dq_ddl(engine: Engine) -> None:
    ddl = DDL_FILE.read_text(encoding="utf-8")
    with engine.begin() as conn:
        conn.exec_driver_sql(ddl)


def assert_batch_has_all_sources(conn: Connection, batch_id: str) -> None:
    missing_tables = []
    for table_name in EXPECTED_RAW_TABLES:
        has_rows = conn.execute(
            text(
                f"""
                SELECT EXISTS (
                    SELECT 1 FROM raw.{table_name}
                    WHERE batch_id = :batch_id
                )
                """
            ),
            {"batch_id": batch_id},
        ).scalar_one()
        if not has_rows:
            missing_tables.append(f"raw.{table_name}")

    if missing_tables:
        raise RuntimeError(
            "Batch is incomplete; no rows found in: " + ", ".join(missing_tables)
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


def run_rule_files(engine: Engine, batch_id: str) -> int:
    rule_files = sorted(DQ_DIR.glob("*.sql"))
    if not rule_files:
        raise RuntimeError(f"No DQ SQL files found in {DQ_DIR}")

    total_errors = 0
    with engine.begin() as conn:
        # Chỉ làm mới kết quả của DQ_RAW; giữ nguyên lỗi ingestion cùng batch.
        conn.execute(
            text(
                """
                DELETE FROM audit.data_quality_errors
                WHERE batch_id = CAST(:batch_id AS UUID)
                  AND pipeline_step = :pipeline_step
                """
            ),
            {"batch_id": batch_id, "pipeline_step": PIPELINE_STEP},
        )

        for rule_file in rule_files:
            sql = rule_file.read_text(encoding="utf-8")
            result = conn.execute(text(sql), {"batch_id": batch_id})
            inserted = max(result.rowcount or 0, 0)
            total_errors += inserted
            logging.info("DQ rule file %s: errors=%s", rule_file.name, inserted)

    return total_errors


def get_error_summary(engine: Engine, batch_id: str) -> list:
    with engine.connect() as conn:
        return list(
            conn.execute(
                text(
                    """
                    SELECT severity, error_type, COUNT(*) AS error_count
                    FROM audit.data_quality_errors
                    WHERE batch_id = CAST(:batch_id AS UUID)
                      AND pipeline_step = :pipeline_step
                    GROUP BY severity, error_type
                    ORDER BY severity, error_type
                    """
                ),
                {"batch_id": batch_id, "pipeline_step": PIPELINE_STEP},
            ).mappings()
        )


def main() -> int:
    setup_logger()
    args = parse_args()
    engine = build_engine()
    run_id = None

    try:
        apply_dq_ddl(engine)

        with engine.connect() as conn:
            batch_id = args.batch_id or find_latest_complete_batch(conn)

        if not batch_id:
            raise RuntimeError(
                "No complete ingestion batch found; pass --batch-id explicitly"
            )

        batch_id = validate_batch_id(batch_id)
        with engine.connect() as conn:
            assert_batch_has_all_sources(conn, batch_id)

        run_id = create_run(engine, batch_id)
        logging.info("Start DQ gate batch_id=%s run_id=%s", batch_id, run_id)

        total_errors = run_rule_files(engine, batch_id)
        summary = get_error_summary(engine, batch_id)
        critical_errors = sum(
            row["error_count"] for row in summary if row["severity"] == "ERROR"
        )

        for row in summary:
            logging.info(
                "DQ summary severity=%s type=%s count=%s",
                row["severity"],
                row["error_type"],
                row["error_count"],
            )

        status = "DQ_FAILED" if critical_errors else "DQ_PASSED"
        finish_run(engine, run_id, status, total_errors)
        logging.info(
            "Finished DQ gate batch_id=%s status=%s errors=%s",
            batch_id,
            status,
            total_errors,
        )
        return 1 if critical_errors else 0

    except Exception as exc:
        logging.exception("DQ gate execution failed")
        if run_id is not None:
            finish_run(engine, run_id, "FAILED", 0, str(exc)[:5000])
        return 2
    finally:
        engine.dispose()


if __name__ == "__main__":
    sys.exit(main())

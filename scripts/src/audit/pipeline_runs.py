import os
from dotenv import load_dotenv
from typing import Optional
from pathlib import Path
from sqlalchemy import create_engine, text
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(DATABASE_URL)


def create_pipeline_run_log(batch_id: str, pipeline_step: str, status: str, row_count: int, error_message: str):
    with engine.begin() as conn:
        result = conn.execute(
            text("""
                INSERT INTO audit.pipeline_runs (
                    batch_id,
                    pipeline_step,
                    started_at,
                    status,
                    row_count,
                    error_message
                )
                VALUES (
                    :batch_id,
                    :pipeline_step,
                    NOW(),
                    :status,
                    :row_count,
                    :error_message
                )
                RETURNING run_id;
            """),
            {
                "batch_id": batch_id,
                "pipeline_step": pipeline_step,
                "status": status,
                "row_count": row_count,
                "error_message": error_message
            }
        )

        return result.scalar_one()

def update_pipeline_run_log(
    run_id: int,
    status: str,
    row_count: int = 0,
    error_message: Optional[str] = None,
    ended: bool = False,
):
    with engine.begin() as conn:
        ended_sql = "finished_at = NOW()," if ended else ""

        conn.execute(
            text(f"""
                UPDATE audit.pipeline_runs
                SET
                    status = :status,
                    row_count = :row_count,
                    {ended_sql}
                    error_message = :error_message
                WHERE run_id = :run_id;
            """),
            {
                "run_id": run_id,
                "status": status,
                "row_count": row_count,
                "error_message": error_message,
            }
        )



def create_data_quality_errors(
    batch_id: str,
    source_table: str,
    row_identifier: str,
    pipeline_step: str,
    error_type: str,
    error_detail: str,
):
    with engine.begin() as conn:
        result = conn.execute(
            text("""
                INSERT INTO audit.data_quality_errors (
                    batch_id,
                    source_table,
                    row_identifier,
                    pipeline_step,
                    error_type,
                    error_detail,
                    detected_at
                )
                VALUES (
                    :batch_id,
                    :source_table,
                    :row_identifier,
                    :pipeline_step,
                    :error_type,
                    :error_detail,
                    NOW()
                )
                RETURNING error_id;
            """),
            {
                "batch_id": batch_id,
                "source_table": source_table,
                "row_identifier": row_identifier,
                "pipeline_step": pipeline_step,
                "error_type": error_type,
                "error_detail": error_detail,
            }
        )

        return result.scalar_one()
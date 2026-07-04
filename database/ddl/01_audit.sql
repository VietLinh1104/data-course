CREATE SCHEMA IF NOT EXISTS audit;

CREATE TABLE IF NOT EXISTS audit.pipeline_runs (
    run_id BIGSERIAL PRIMARY KEY,
    batch_id UUID NOT NULL,
    pipeline_step VARCHAR(50) NOT NULL,
    started_at TIMESTAMP DEFAULT NOW(),
    finished_at TIMESTAMP,
    status VARCHAR(20) NOT NULL,
    row_count INTEGER DEFAULT 0,
    error_message TEXT
);

CREATE TABLE IF NOT EXISTS audit.data_quality_errors (
    error_id BIGSERIAL PRIMARY KEY,
    batch_id UUID NOT NULL,
    source_table VARCHAR(50) NOT NULL,
    row_identifier VARCHAR(100),
    error_type VARCHAR(50) NOT NULL,
    severity VARCHAR(10) NOT NULL DEFAULT 'ERROR',
    error_detail TEXT,
    detected_at TIMESTAMP DEFAULT NOW(),
    pipeline_step VARCHAR(50) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_dq_errors_batch_step
    ON audit.data_quality_errors (batch_id, pipeline_step);

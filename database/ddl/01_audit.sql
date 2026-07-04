-- Tạo schema audit nếu chưa có, tạo bảng pipeline_runs với cột như đã gợi ý ở lượt trước (run_id, batch_id, pipeline_step, started_at, finished_at, status, row_count, error_message).

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
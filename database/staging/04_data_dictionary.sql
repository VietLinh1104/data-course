WITH ranked AS (
    SELECT r.*, ROW_NUMBER() OVER (PARTITION BY "table" ORDER BY loaded_at DESC) AS rn
    FROM raw.data_dictionary r WHERE batch_id = :batch_id
)
INSERT INTO staging.stg_data_dictionary (
    batch_id, source_table, expected_rows, description, source_file_name, loaded_at
)
SELECT batch_id::UUID, BTRIM("table"), rows::BIGINT, BTRIM(description),
       source_file_name, loaded_at
FROM ranked WHERE rn = 1;

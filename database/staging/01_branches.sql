WITH ranked AS (
    SELECT r.*, ROW_NUMBER() OVER (PARTITION BY branch_id ORDER BY loaded_at DESC) AS rn
    FROM raw.branches r WHERE batch_id = :batch_id
)
INSERT INTO staging.stg_branches (
    batch_id, branch_id, branch_name, city, district_type, store_type,
    sales_multiplier, source_file_name, loaded_at
)
SELECT batch_id::UUID, BTRIM(branch_id), BTRIM(branch_name), BTRIM(city),
       LOWER(BTRIM(district_type)), LOWER(BTRIM(store_type)), sales_multiplier::NUMERIC,
       source_file_name, loaded_at
FROM ranked WHERE rn = 1;

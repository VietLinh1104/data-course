WITH ranked AS (
    SELECT r.*, ROW_NUMBER() OVER (PARTITION BY supplier_id ORDER BY loaded_at DESC) AS rn
    FROM raw.suppliers r WHERE batch_id = :batch_id
)
INSERT INTO staging.stg_suppliers (
    batch_id, supplier_id, supplier_name, category, city, source_file_name, loaded_at
)
SELECT batch_id::UUID, BTRIM(supplier_id), BTRIM(supplier_name),
       LOWER(BTRIM(category)), BTRIM(city), source_file_name, loaded_at
FROM ranked WHERE rn = 1;

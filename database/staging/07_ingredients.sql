WITH ranked AS (
    SELECT r.*, ROW_NUMBER() OVER (PARTITION BY ingredient_id ORDER BY loaded_at DESC) AS rn
    FROM raw.ingredients r WHERE batch_id = :batch_id
)
INSERT INTO staging.stg_ingredients (
    batch_id, ingredient_id, ingredient_name, unit, base_unit_cost,
    is_perishable, storage_type, source_file_name, loaded_at
)
SELECT batch_id::UUID, BTRIM(ingredient_id), BTRIM(ingredient_name), LOWER(BTRIM(unit)),
       base_unit_cost::NUMERIC, BTRIM(is_perishable) = '1', LOWER(BTRIM(storage_type)),
       source_file_name, loaded_at
FROM ranked WHERE rn = 1;

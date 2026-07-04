WITH ranked AS (
    SELECT r.*, ROW_NUMBER() OVER (
        PARTITION BY product_id, ingredient_id ORDER BY loaded_at DESC
    ) AS rn
    FROM raw.recipes r WHERE batch_id = :batch_id
)
INSERT INTO staging.stg_recipes (
    batch_id, product_id, ingredient_id, quantity_per_unit,
    source_file_name, loaded_at
)
SELECT batch_id::UUID, BTRIM(product_id), BTRIM(ingredient_id),
       quantity_per_unit::NUMERIC, source_file_name, loaded_at
FROM ranked WHERE rn = 1;

WITH ranked AS (
    SELECT r.*, ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY loaded_at DESC) AS rn
    FROM raw.products r WHERE batch_id = :batch_id
)
INSERT INTO staging.stg_products (
    batch_id, product_id, product_name, category, selling_price, is_active,
    popularity_weight, source_file_name, loaded_at
)
SELECT batch_id::UUID, BTRIM(product_id), BTRIM(product_name), LOWER(BTRIM(category)),
       selling_price::NUMERIC, BTRIM(is_active) = '1', popularity_weight::NUMERIC,
       source_file_name, loaded_at
FROM ranked WHERE rn = 1;

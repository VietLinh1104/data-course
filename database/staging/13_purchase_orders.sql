WITH ranked AS (
    SELECT r.*, ROW_NUMBER() OVER (PARTITION BY purchase_order_id ORDER BY loaded_at DESC) AS rn
    FROM raw.purchase_orders r WHERE batch_id = :batch_id
)
INSERT INTO staging.stg_purchase_orders (
    batch_id, purchase_order_id, purchase_date, branch_id, ingredient_id,
    supplier_id, quantity, unit_cost, total_cost, source_file_name, loaded_at
)
SELECT batch_id::UUID, BTRIM(purchase_order_id), purchase_date::DATE, BTRIM(branch_id),
       BTRIM(ingredient_id), BTRIM(supplier_id), quantity::NUMERIC,
       unit_cost::NUMERIC, total_cost::NUMERIC, source_file_name, loaded_at
FROM ranked WHERE rn = 1;

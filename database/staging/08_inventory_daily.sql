WITH ranked AS (
    SELECT r.*, ROW_NUMBER() OVER (
        PARTITION BY date, branch_id, ingredient_id ORDER BY loaded_at DESC
    ) AS rn
    FROM raw.inventory_daily r WHERE batch_id = :batch_id
)
INSERT INTO staging.stg_inventory_daily (
    batch_id, inventory_date, branch_id, ingredient_id, opening_stock, stock_in,
    stock_out_usage, waste, closing_stock, is_stockout, unmet_demand,
    source_file_name, loaded_at
)
SELECT batch_id::UUID, date::DATE, BTRIM(branch_id), BTRIM(ingredient_id),
       opening_stock::NUMERIC, stock_in::NUMERIC, stock_out_usage::NUMERIC,
       waste::NUMERIC, closing_stock::NUMERIC,
       stock_out_usage::NUMERIC + waste::NUMERIC > opening_stock::NUMERIC + stock_in::NUMERIC,
       GREATEST(0, stock_out_usage::NUMERIC + waste::NUMERIC - opening_stock::NUMERIC - stock_in::NUMERIC),
       source_file_name, loaded_at
FROM ranked WHERE rn = 1;

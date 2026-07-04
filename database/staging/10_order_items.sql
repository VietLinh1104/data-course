INSERT INTO staging.stg_order_items (
    batch_id, order_id, product_id, quantity, unit_price, line_amount,
    source_file_name, loaded_at
)
SELECT batch_id::UUID, BTRIM(order_id), BTRIM(product_id), quantity::NUMERIC,
       unit_price::NUMERIC, line_amount::NUMERIC, source_file_name, loaded_at
FROM raw.order_items
WHERE batch_id = :batch_id;

WITH ranked AS (
    SELECT r.*, ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY loaded_at DESC) AS rn
    FROM raw.orders r WHERE batch_id = :batch_id
)
INSERT INTO staging.stg_orders (
    batch_id, order_id, branch_id, customer_id, order_datetime, channel,
    gross_amount, discount_amount, net_amount, cashier_employee_id, status,
    source_file_name, loaded_at
)
SELECT batch_id::UUID, BTRIM(order_id), BTRIM(branch_id), NULLIF(BTRIM(customer_id), ''),
       order_datetime::TIMESTAMP,
       CASE LOWER(BTRIM(channel))
           WHEN 'delivery' THEN 'delivery'
           WHEN 'dine-in' THEN 'dine_in'
           WHEN 'take-away' THEN 'takeaway'
           ELSE LOWER(BTRIM(channel))
       END,
       gross_amount::NUMERIC, discount_amount::NUMERIC, net_amount::NUMERIC,
       BTRIM(cashier_employee_id), LOWER(BTRIM(status)), source_file_name, loaded_at
FROM ranked WHERE rn = 1;

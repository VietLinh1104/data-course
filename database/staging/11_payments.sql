WITH ranked AS (
    SELECT r.*, ROW_NUMBER() OVER (PARTITION BY payment_id ORDER BY loaded_at DESC) AS rn
    FROM raw.payments r WHERE batch_id = :batch_id
)
INSERT INTO staging.stg_payments (
    batch_id, payment_id, order_id, payment_method, amount, paid_at,
    source_file_name, loaded_at
)
SELECT batch_id::UUID, BTRIM(payment_id), BTRIM(order_id),
       LOWER(BTRIM(payment_method)), amount::NUMERIC, paid_at::TIMESTAMP,
       source_file_name, loaded_at
FROM ranked WHERE rn = 1;

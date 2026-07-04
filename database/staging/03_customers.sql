WITH ranked AS (
    SELECT r.*, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY loaded_at DESC) AS rn
    FROM raw.customers r WHERE batch_id = :batch_id
)
INSERT INTO staging.stg_customers (
    batch_id, customer_id, customer_name, segment, signup_date, city,
    source_file_name, loaded_at
)
SELECT batch_id::UUID, BTRIM(customer_id), BTRIM(customer_name), LOWER(BTRIM(segment)),
       signup_date::DATE, BTRIM(city), source_file_name, loaded_at
FROM ranked WHERE rn = 1;

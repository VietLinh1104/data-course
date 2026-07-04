WITH ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY order_id
               ORDER BY loaded_at DESC
           ) AS rn
    FROM raw.orders
)
SELECT *
FROM ranked
WHERE rn = 1;



WITH item_totals AS MATERIALIZED (
    SELECT order_id,
           BOOL_AND(audit.is_valid_numeric(line_amount)) AS all_amounts_valid,
           SUM(CASE WHEN audit.is_valid_numeric(line_amount) THEN line_amount::NUMERIC ELSE 0 END) AS item_amount
    FROM raw.order_items
    WHERE batch_id = :batch_id
    GROUP BY order_id
),
payment_totals AS MATERIALIZED (
    SELECT order_id,
           BOOL_AND(audit.is_valid_numeric(amount)) AS all_amounts_valid,
           SUM(CASE WHEN audit.is_valid_numeric(amount) THEN amount::NUMERIC ELSE 0 END) AS payment_amount
    FROM raw.payments
    WHERE batch_id = :batch_id
    GROUP BY order_id
),
reconciled_orders AS MATERIALIZED (
    SELECT
        o.order_id,
        o.status,
        o.gross_amount,
        o.net_amount,
        i.order_id AS item_order_id,
        i.all_amounts_valid AS item_amounts_valid,
        i.item_amount,
        p.order_id AS payment_order_id,
        p.all_amounts_valid AS payment_amounts_valid,
        p.payment_amount
    FROM raw.orders o
    LEFT JOIN item_totals i ON i.order_id = o.order_id
    LEFT JOIN payment_totals p ON p.order_id = o.order_id
    WHERE o.batch_id = :batch_id
),
dq_errors AS (
    SELECT
        'raw.orders' AS source_table,
        r.order_id AS row_identifier,
        check_result.error_type,
        'ERROR' AS severity,
        check_result.error_detail
    FROM reconciled_orders r
    CROSS JOIN LATERAL (
        VALUES
            (
                r.item_order_id IS NULL,
                'MISSING_ORDER_ITEMS',
                'order has no matching rows in raw.order_items'
            ),
            (
                r.item_order_id IS NOT NULL
                AND COALESCE(r.item_amounts_valid, FALSE)
                AND CASE WHEN audit.is_valid_numeric(r.gross_amount)
                         THEN ABS(r.gross_amount::NUMERIC - r.item_amount) > 0.01
                         ELSE FALSE END,
                'ORDER_ITEM_TOTAL_MISMATCH',
                'gross_amount=' || r.gross_amount || ', item_amount=' || r.item_amount
            ),
            (
                LOWER(BTRIM(r.status)) = 'completed' AND r.payment_order_id IS NULL,
                'MISSING_PAYMENT',
                'completed order has no matching rows in raw.payments'
            ),
            (
                LOWER(BTRIM(r.status)) = 'completed'
                AND r.payment_order_id IS NOT NULL
                AND COALESCE(r.payment_amounts_valid, FALSE)
                AND CASE WHEN audit.is_valid_numeric(r.net_amount)
                         THEN ABS(r.net_amount::NUMERIC - r.payment_amount) > 0.01
                         ELSE FALSE END,
                'PAYMENT_TOTAL_MISMATCH',
                'net_amount=' || r.net_amount || ', payment_amount=' || r.payment_amount
            )
    ) AS check_result(is_error, error_type, error_detail)
    WHERE check_result.is_error
)
INSERT INTO audit.data_quality_errors (
    batch_id, source_table, row_identifier, pipeline_step,
    error_type, severity, error_detail, detected_at
)
SELECT CAST(:batch_id AS UUID), source_table, LEFT(row_identifier, 100), 'DQ_RAW',
       error_type, severity, error_detail, NOW()
FROM dq_errors;

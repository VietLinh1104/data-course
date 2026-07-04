WITH ranked AS (
    SELECT r.*, ROW_NUMBER() OVER (PARTITION BY voucher_id ORDER BY loaded_at DESC) AS rn
    FROM raw.vouchers r WHERE batch_id = :batch_id
)
INSERT INTO staging.stg_vouchers (
    batch_id, voucher_id, campaign_id, voucher_code, discount_type,
    discount_value, budget_limit, min_order_value, source_file_name, loaded_at
)
SELECT batch_id::UUID, BTRIM(voucher_id), BTRIM(campaign_id), BTRIM(voucher_code),
       LOWER(BTRIM(discount_type)), discount_value::NUMERIC, budget_limit::NUMERIC,
       min_order_value::NUMERIC, source_file_name, loaded_at
FROM ranked WHERE rn = 1;

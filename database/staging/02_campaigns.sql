WITH ranked AS (
    SELECT r.*, ROW_NUMBER() OVER (PARTITION BY campaign_id ORDER BY loaded_at DESC) AS rn
    FROM raw.campaigns r WHERE batch_id = :batch_id
)
INSERT INTO staging.stg_campaigns (
    batch_id, campaign_id, campaign_name, start_date, end_date, scope,
    objective, source_file_name, loaded_at
)
SELECT batch_id::UUID, BTRIM(campaign_id), BTRIM(campaign_name), start_date::DATE,
       end_date::DATE, LOWER(BTRIM(scope)), LOWER(BTRIM(objective)),
       source_file_name, loaded_at
FROM ranked WHERE rn = 1;

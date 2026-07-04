WITH ranked AS (
    SELECT r.*, ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY loaded_at DESC) AS rn
    FROM raw.employees r WHERE batch_id = :batch_id
)
INSERT INTO staging.stg_employees (
    batch_id, employee_id, branch_id, employee_name, role, hourly_rate,
    employment_type, hire_date, source_file_name, loaded_at
)
SELECT batch_id::UUID, BTRIM(employee_id), BTRIM(branch_id), BTRIM(employee_name),
       LOWER(BTRIM(role)), hourly_rate::NUMERIC, LOWER(BTRIM(employment_type)),
       hire_date::DATE, source_file_name, loaded_at
FROM ranked WHERE rn = 1;

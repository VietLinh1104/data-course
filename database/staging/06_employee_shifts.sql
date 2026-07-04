WITH ranked AS (
    SELECT r.*, ROW_NUMBER() OVER (PARTITION BY shift_id ORDER BY loaded_at DESC) AS rn
    FROM raw.employee_shifts r WHERE batch_id = :batch_id
)
INSERT INTO staging.stg_employee_shifts (
    batch_id, shift_id, shift_date, branch_id, employee_id, shift_name,
    start_time, end_time, working_hours, salary_cost, attendance_status,
    source_file_name, loaded_at
)
SELECT batch_id::UUID, BTRIM(shift_id), date::DATE, BTRIM(branch_id),
       BTRIM(employee_id), LOWER(BTRIM(shift_name)), start_time::TIME, end_time::TIME,
       working_hours::NUMERIC, salary_cost::NUMERIC, LOWER(BTRIM(attendance_status)),
       source_file_name, loaded_at
FROM ranked WHERE rn = 1;

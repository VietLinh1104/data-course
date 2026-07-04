WITH dq_errors AS (
    -- Numeric format checks. LATERAL giúp kiểm tra nhiều cột mà không lặp query.
    SELECT 'raw.branches' AS source_table, branch_id AS row_identifier,
           'INVALID_NUMERIC' AS error_type, 'ERROR' AS severity,
           column_name || ' is not numeric: ' || COALESCE(column_value, '<null>') AS error_detail
    FROM raw.branches
    CROSS JOIN LATERAL (VALUES ('sales_multiplier', sales_multiplier)) AS value_to_check(column_name, column_value)
    WHERE batch_id = :batch_id AND NOT audit.is_valid_numeric(column_value)
    UNION ALL
    SELECT 'raw.employee_shifts', shift_id, 'INVALID_NUMERIC', 'ERROR',
           column_name || ' is not numeric: ' || COALESCE(column_value, '<null>')
    FROM raw.employee_shifts
    CROSS JOIN LATERAL (VALUES ('working_hours', working_hours), ('salary_cost', salary_cost)) AS value_to_check(column_name, column_value)
    WHERE batch_id = :batch_id AND NOT audit.is_valid_numeric(column_value)
    UNION ALL
    SELECT 'raw.employees', employee_id, 'INVALID_NUMERIC', 'ERROR',
           'hourly_rate is not numeric: ' || COALESCE(hourly_rate, '<null>')
    FROM raw.employees WHERE batch_id = :batch_id AND NOT audit.is_valid_numeric(hourly_rate)
    UNION ALL
    SELECT 'raw.ingredients', ingredient_id, 'INVALID_NUMERIC', 'ERROR',
           'base_unit_cost is not numeric: ' || COALESCE(base_unit_cost, '<null>')
    FROM raw.ingredients WHERE batch_id = :batch_id AND NOT audit.is_valid_numeric(base_unit_cost)
    UNION ALL
    SELECT 'raw.inventory_daily', CONCAT_WS('|', 'date=' || date, 'branch_id=' || branch_id, 'ingredient_id=' || ingredient_id),
           'INVALID_NUMERIC', 'ERROR', column_name || ' is not numeric: ' || COALESCE(column_value, '<null>')
    FROM raw.inventory_daily
    CROSS JOIN LATERAL (VALUES ('opening_stock', opening_stock), ('stock_in', stock_in),
        ('stock_out_usage', stock_out_usage), ('waste', waste), ('closing_stock', closing_stock)) AS value_to_check(column_name, column_value)
    WHERE batch_id = :batch_id AND NOT audit.is_valid_numeric(column_value)
    UNION ALL
    SELECT 'raw.order_items', CONCAT_WS('|', 'order_id=' || order_id, 'product_id=' || product_id),
           'INVALID_NUMERIC', 'ERROR', column_name || ' is not numeric: ' || COALESCE(column_value, '<null>')
    FROM raw.order_items
    CROSS JOIN LATERAL (VALUES ('quantity', quantity), ('unit_price', unit_price), ('line_amount', line_amount)) AS value_to_check(column_name, column_value)
    WHERE batch_id = :batch_id AND NOT audit.is_valid_numeric(column_value)
    UNION ALL
    SELECT 'raw.orders', order_id, 'INVALID_NUMERIC', 'ERROR',
           column_name || ' is not numeric: ' || COALESCE(column_value, '<null>')
    FROM raw.orders
    CROSS JOIN LATERAL (VALUES ('gross_amount', gross_amount), ('discount_amount', discount_amount), ('net_amount', net_amount)) AS value_to_check(column_name, column_value)
    WHERE batch_id = :batch_id AND NOT audit.is_valid_numeric(column_value)
    UNION ALL
    SELECT 'raw.payments', payment_id, 'INVALID_NUMERIC', 'ERROR',
           'amount is not numeric: ' || COALESCE(amount, '<null>')
    FROM raw.payments WHERE batch_id = :batch_id AND NOT audit.is_valid_numeric(amount)
    UNION ALL
    SELECT 'raw.products', product_id, 'INVALID_NUMERIC', 'ERROR',
           column_name || ' is not numeric: ' || COALESCE(column_value, '<null>')
    FROM raw.products
    CROSS JOIN LATERAL (VALUES ('selling_price', selling_price), ('popularity_weight', popularity_weight)) AS value_to_check(column_name, column_value)
    WHERE batch_id = :batch_id AND NOT audit.is_valid_numeric(column_value)
    UNION ALL
    SELECT 'raw.purchase_orders', purchase_order_id, 'INVALID_NUMERIC', 'ERROR',
           column_name || ' is not numeric: ' || COALESCE(column_value, '<null>')
    FROM raw.purchase_orders
    CROSS JOIN LATERAL (VALUES ('quantity', quantity), ('unit_cost', unit_cost), ('total_cost', total_cost)) AS value_to_check(column_name, column_value)
    WHERE batch_id = :batch_id AND NOT audit.is_valid_numeric(column_value)
    UNION ALL
    SELECT 'raw.recipes', CONCAT_WS('|', 'product_id=' || product_id, 'ingredient_id=' || ingredient_id),
           'INVALID_NUMERIC', 'ERROR', 'quantity_per_unit is not numeric: ' || COALESCE(quantity_per_unit, '<null>')
    FROM raw.recipes WHERE batch_id = :batch_id AND NOT audit.is_valid_numeric(quantity_per_unit)
    UNION ALL
    SELECT 'raw.vouchers', voucher_id, 'INVALID_NUMERIC', 'ERROR',
           column_name || ' is not numeric: ' || COALESCE(column_value, '<null>')
    FROM raw.vouchers
    CROSS JOIN LATERAL (VALUES ('discount_value', discount_value), ('budget_limit', budget_limit),
        ('min_order_value', min_order_value)) AS value_to_check(column_name, column_value)
    WHERE batch_id = :batch_id AND NOT audit.is_valid_numeric(column_value)

    UNION ALL

    -- Date/time format checks.
    SELECT 'raw.campaigns', campaign_id, 'INVALID_DATE', 'ERROR',
           column_name || ' is not a valid date: ' || COALESCE(column_value, '<null>')
    FROM raw.campaigns
    CROSS JOIN LATERAL (VALUES ('start_date', start_date), ('end_date', end_date)) AS value_to_check(column_name, column_value)
    WHERE batch_id = :batch_id AND NOT audit.is_valid_date(column_value)
    UNION ALL
    SELECT 'raw.customers', customer_id, 'INVALID_DATE', 'ERROR',
           'signup_date is not a valid date: ' || COALESCE(signup_date, '<null>')
    FROM raw.customers WHERE batch_id = :batch_id AND NOT audit.is_valid_date(signup_date)
    UNION ALL
    SELECT 'raw.employee_shifts', shift_id, 'INVALID_DATE', 'ERROR',
           'date is not a valid date: ' || COALESCE(date, '<null>')
    FROM raw.employee_shifts WHERE batch_id = :batch_id AND NOT audit.is_valid_date(date)
    UNION ALL
    SELECT 'raw.employee_shifts', shift_id, 'INVALID_TIME', 'ERROR',
           column_name || ' is not a valid time: ' || COALESCE(column_value, '<null>')
    FROM raw.employee_shifts
    CROSS JOIN LATERAL (VALUES ('start_time', start_time), ('end_time', end_time)) AS value_to_check(column_name, column_value)
    WHERE batch_id = :batch_id AND NOT audit.is_valid_time(column_value)
    UNION ALL
    SELECT 'raw.employees', employee_id, 'INVALID_DATE', 'ERROR',
           'hire_date is not a valid date: ' || COALESCE(hire_date, '<null>')
    FROM raw.employees WHERE batch_id = :batch_id AND NOT audit.is_valid_date(hire_date)
    UNION ALL
    SELECT 'raw.inventory_daily', CONCAT_WS('|', 'date=' || date, 'branch_id=' || branch_id, 'ingredient_id=' || ingredient_id),
           'INVALID_DATE', 'ERROR', 'date is not a valid date: ' || COALESCE(date, '<null>')
    FROM raw.inventory_daily WHERE batch_id = :batch_id AND NOT audit.is_valid_date(date)
    UNION ALL
    SELECT 'raw.orders', order_id, 'INVALID_TIMESTAMP', 'ERROR',
           'order_datetime is not a valid timestamp: ' || COALESCE(order_datetime, '<null>')
    FROM raw.orders WHERE batch_id = :batch_id AND NOT audit.is_valid_timestamp(order_datetime)
    UNION ALL
    SELECT 'raw.payments', payment_id, 'INVALID_TIMESTAMP', 'ERROR',
           'paid_at is not a valid timestamp: ' || COALESCE(paid_at, '<null>')
    FROM raw.payments WHERE batch_id = :batch_id AND NOT audit.is_valid_timestamp(paid_at)
    UNION ALL
    SELECT 'raw.purchase_orders', purchase_order_id, 'INVALID_DATE', 'ERROR',
           'purchase_date is not a valid date: ' || COALESCE(purchase_date, '<null>')
    FROM raw.purchase_orders WHERE batch_id = :batch_id AND NOT audit.is_valid_date(purchase_date)

    UNION ALL

    -- Controlled-domain checks.
    SELECT 'raw.employee_shifts', shift_id, 'INVALID_DOMAIN', 'ERROR',
           'attendance_status is invalid: ' || COALESCE(attendance_status, '<null>')
    FROM raw.employee_shifts
    WHERE batch_id = :batch_id AND COALESCE(BTRIM(LOWER(attendance_status)), '') NOT IN ('worked', 'late', 'absent')
    UNION ALL
    SELECT 'raw.employees', employee_id, 'INVALID_DOMAIN', 'ERROR',
           'employment_type is invalid: ' || COALESCE(employment_type, '<null>')
    FROM raw.employees
    WHERE batch_id = :batch_id AND COALESCE(BTRIM(LOWER(employment_type)), '') NOT IN ('full-time', 'part-time')
    UNION ALL
    SELECT 'raw.ingredients', ingredient_id, 'INVALID_DOMAIN', 'ERROR',
           'is_perishable must be 0 or 1: ' || COALESCE(is_perishable, '<null>')
    FROM raw.ingredients WHERE batch_id = :batch_id AND COALESCE(BTRIM(is_perishable), '') NOT IN ('0', '1')
    UNION ALL
    SELECT 'raw.orders', order_id, 'INVALID_DOMAIN', 'ERROR',
           'channel is invalid: ' || COALESCE(channel, '<null>')
    FROM raw.orders
    WHERE batch_id = :batch_id AND COALESCE(BTRIM(LOWER(channel)), '') NOT IN ('delivery', 'dine-in', 'take-away')
    UNION ALL
    SELECT 'raw.orders', order_id, 'INVALID_DOMAIN', 'ERROR',
           'status is invalid: ' || COALESCE(status, '<null>')
    FROM raw.orders
    WHERE batch_id = :batch_id AND COALESCE(BTRIM(LOWER(status)), '') NOT IN ('completed', 'cancelled', 'refunded')
    UNION ALL
    SELECT 'raw.payments', payment_id, 'INVALID_DOMAIN', 'ERROR',
           'payment_method is invalid: ' || COALESCE(payment_method, '<null>')
    FROM raw.payments
    WHERE batch_id = :batch_id AND COALESCE(BTRIM(LOWER(payment_method)), '') NOT IN ('cash', 'card', 'bank_transfer', 'e-wallet')
    UNION ALL
    SELECT 'raw.products', product_id, 'INVALID_DOMAIN', 'ERROR',
           'is_active must be 0 or 1: ' || COALESCE(is_active, '<null>')
    FROM raw.products WHERE batch_id = :batch_id AND COALESCE(BTRIM(is_active), '') NOT IN ('0', '1')
    UNION ALL
    SELECT 'raw.vouchers', voucher_id, 'INVALID_DOMAIN', 'ERROR',
           'discount_type is invalid: ' || COALESCE(discount_type, '<null>')
    FROM raw.vouchers
    WHERE batch_id = :batch_id AND COALESCE(BTRIM(LOWER(discount_type)), '') NOT IN ('percent', 'amount')
)
INSERT INTO audit.data_quality_errors (
    batch_id, source_table, row_identifier, pipeline_step,
    error_type, severity, error_detail, detected_at
)
SELECT CAST(:batch_id AS UUID), source_table, LEFT(row_identifier, 100), 'DQ_RAW',
       error_type, severity, error_detail, NOW()
FROM dq_errors;

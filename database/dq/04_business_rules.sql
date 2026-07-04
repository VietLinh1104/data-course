WITH dq_errors AS (
    SELECT 'raw.branches' AS source_table, branch_id AS row_identifier,
           'NON_POSITIVE_VALUE' AS error_type, 'ERROR' AS severity,
           'sales_multiplier must be greater than 0' AS error_detail
    FROM raw.branches
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_numeric(sales_multiplier) THEN sales_multiplier::NUMERIC <= 0 ELSE FALSE END
    UNION ALL
    SELECT 'raw.campaigns', campaign_id, 'INVALID_DATE_RANGE', 'ERROR', 'end_date is before start_date'
    FROM raw.campaigns
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_date(start_date) AND audit.is_valid_date(end_date)
               THEN end_date::DATE < start_date::DATE ELSE FALSE END
    UNION ALL
    SELECT 'raw.employee_shifts', shift_id, 'INVALID_TIME_RANGE', 'ERROR', 'end_time must be after start_time'
    FROM raw.employee_shifts
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_time(start_time) AND audit.is_valid_time(end_time)
               THEN end_time::TIME <= start_time::TIME ELSE FALSE END
    UNION ALL
    SELECT 'raw.employee_shifts', shift_id, 'NEGATIVE_VALUE', 'ERROR',
           column_name || ' must not be negative'
    FROM raw.employee_shifts
    CROSS JOIN LATERAL (VALUES ('working_hours', working_hours), ('salary_cost', salary_cost)) AS value_to_check(column_name, column_value)
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_numeric(column_value) THEN column_value::NUMERIC < 0 ELSE FALSE END
    UNION ALL
    SELECT 'raw.employees', employee_id, 'NEGATIVE_VALUE', 'ERROR', 'hourly_rate must not be negative'
    FROM raw.employees
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_numeric(hourly_rate) THEN hourly_rate::NUMERIC < 0 ELSE FALSE END
    UNION ALL
    SELECT 'raw.ingredients', ingredient_id, 'NEGATIVE_VALUE', 'ERROR', 'base_unit_cost must not be negative'
    FROM raw.ingredients
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_numeric(base_unit_cost) THEN base_unit_cost::NUMERIC < 0 ELSE FALSE END
    UNION ALL
    SELECT 'raw.inventory_daily', CONCAT_WS('|', 'date=' || date, 'branch_id=' || branch_id, 'ingredient_id=' || ingredient_id),
           'NEGATIVE_VALUE', 'ERROR', column_name || ' must not be negative'
    FROM raw.inventory_daily
    CROSS JOIN LATERAL (VALUES ('opening_stock', opening_stock), ('stock_in', stock_in),
        ('stock_out_usage', stock_out_usage), ('waste', waste), ('closing_stock', closing_stock)) AS value_to_check(column_name, column_value)
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_numeric(column_value) THEN column_value::NUMERIC < 0 ELSE FALSE END
    UNION ALL
    SELECT 'raw.inventory_daily', CONCAT_WS('|', 'date=' || date, 'branch_id=' || branch_id, 'ingredient_id=' || ingredient_id),
           'INVENTORY_BALANCE_MISMATCH', 'ERROR',
           'closing_stock != greatest(0, opening_stock + stock_in - stock_out_usage - waste)'
    FROM raw.inventory_daily
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_numeric(opening_stock) AND audit.is_valid_numeric(stock_in)
                    AND audit.is_valid_numeric(stock_out_usage) AND audit.is_valid_numeric(waste)
                    AND audit.is_valid_numeric(closing_stock)
               THEN ABS(closing_stock::NUMERIC - GREATEST(0,
                    opening_stock::NUMERIC + stock_in::NUMERIC - stock_out_usage::NUMERIC - waste::NUMERIC)) > 0.01
               ELSE FALSE END
    UNION ALL
    SELECT 'raw.inventory_daily', CONCAT_WS('|', 'date=' || date, 'branch_id=' || branch_id, 'ingredient_id=' || ingredient_id),
           'STOCK_USAGE_EXCEEDS_AVAILABLE', 'WARN',
           'stock_out_usage + waste exceeds opening_stock + stock_in'
    FROM raw.inventory_daily
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_numeric(opening_stock) AND audit.is_valid_numeric(stock_in)
                    AND audit.is_valid_numeric(stock_out_usage) AND audit.is_valid_numeric(waste)
               THEN stock_out_usage::NUMERIC + waste::NUMERIC > opening_stock::NUMERIC + stock_in::NUMERIC
               ELSE FALSE END
    UNION ALL
    SELECT 'raw.order_items', CONCAT_WS('|', 'order_id=' || order_id, 'product_id=' || product_id),
           'NON_POSITIVE_VALUE', 'ERROR', 'quantity must be greater than 0'
    FROM raw.order_items
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_numeric(quantity) THEN quantity::NUMERIC <= 0 ELSE FALSE END
    UNION ALL
    SELECT 'raw.order_items', CONCAT_WS('|', 'order_id=' || order_id, 'product_id=' || product_id),
           'NEGATIVE_VALUE', 'ERROR', column_name || ' must not be negative'
    FROM raw.order_items
    CROSS JOIN LATERAL (VALUES ('unit_price', unit_price), ('line_amount', line_amount)) AS value_to_check(column_name, column_value)
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_numeric(column_value) THEN column_value::NUMERIC < 0 ELSE FALSE END
    UNION ALL
    SELECT 'raw.order_items', CONCAT_WS('|', 'order_id=' || order_id, 'product_id=' || product_id),
           'LINE_AMOUNT_MISMATCH', 'ERROR', 'line_amount != quantity * unit_price'
    FROM raw.order_items
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_numeric(quantity) AND audit.is_valid_numeric(unit_price) AND audit.is_valid_numeric(line_amount)
               THEN ABS(line_amount::NUMERIC - quantity::NUMERIC * unit_price::NUMERIC) > 0.01 ELSE FALSE END
    UNION ALL
    SELECT 'raw.orders', order_id, 'NEGATIVE_VALUE', 'ERROR', column_name || ' must not be negative'
    FROM raw.orders
    CROSS JOIN LATERAL (VALUES ('gross_amount', gross_amount), ('discount_amount', discount_amount), ('net_amount', net_amount)) AS value_to_check(column_name, column_value)
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_numeric(column_value) THEN column_value::NUMERIC < 0 ELSE FALSE END
    UNION ALL
    SELECT 'raw.orders', order_id, 'ORDER_AMOUNT_MISMATCH', 'ERROR',
           'net_amount != gross_amount - discount_amount'
    FROM raw.orders
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_numeric(gross_amount) AND audit.is_valid_numeric(discount_amount) AND audit.is_valid_numeric(net_amount)
               THEN ABS(net_amount::NUMERIC - (gross_amount::NUMERIC - discount_amount::NUMERIC)) > 0.01 ELSE FALSE END
    UNION ALL
    SELECT 'raw.orders', order_id, 'INVALID_DISCOUNT', 'ERROR', 'discount_amount must not exceed gross_amount'
    FROM raw.orders
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_numeric(gross_amount) AND audit.is_valid_numeric(discount_amount)
               THEN discount_amount::NUMERIC > gross_amount::NUMERIC ELSE FALSE END
    UNION ALL
    SELECT 'raw.payments', payment_id, 'NEGATIVE_VALUE', 'ERROR', 'amount must not be negative'
    FROM raw.payments
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_numeric(amount) THEN amount::NUMERIC < 0 ELSE FALSE END
    UNION ALL
    SELECT 'raw.products', product_id, 'NEGATIVE_VALUE', 'ERROR', 'selling_price must not be negative'
    FROM raw.products
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_numeric(selling_price) THEN selling_price::NUMERIC < 0 ELSE FALSE END
    UNION ALL
    SELECT 'raw.products', product_id, 'NON_POSITIVE_VALUE', 'ERROR', 'popularity_weight must be greater than 0'
    FROM raw.products
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_numeric(popularity_weight) THEN popularity_weight::NUMERIC <= 0 ELSE FALSE END
    UNION ALL
    SELECT 'raw.purchase_orders', purchase_order_id, 'NON_POSITIVE_VALUE', 'ERROR', 'quantity must be greater than 0'
    FROM raw.purchase_orders
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_numeric(quantity) THEN quantity::NUMERIC <= 0 ELSE FALSE END
    UNION ALL
    SELECT 'raw.purchase_orders', purchase_order_id, 'NEGATIVE_VALUE', 'ERROR',
           column_name || ' must not be negative'
    FROM raw.purchase_orders
    CROSS JOIN LATERAL (VALUES ('unit_cost', unit_cost), ('total_cost', total_cost)) AS value_to_check(column_name, column_value)
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_numeric(column_value) THEN column_value::NUMERIC < 0 ELSE FALSE END
    UNION ALL
    SELECT 'raw.purchase_orders', purchase_order_id, 'TOTAL_COST_MISMATCH', 'ERROR',
           'total_cost != quantity * unit_cost'
    FROM raw.purchase_orders
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_numeric(quantity) AND audit.is_valid_numeric(unit_cost) AND audit.is_valid_numeric(total_cost)
               THEN ABS(total_cost::NUMERIC - quantity::NUMERIC * unit_cost::NUMERIC) > 0.01 ELSE FALSE END
    UNION ALL
    SELECT 'raw.recipes', CONCAT_WS('|', 'product_id=' || product_id, 'ingredient_id=' || ingredient_id),
           'NON_POSITIVE_VALUE', 'ERROR', 'quantity_per_unit must be greater than 0'
    FROM raw.recipes
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_numeric(quantity_per_unit) THEN quantity_per_unit::NUMERIC <= 0 ELSE FALSE END
    UNION ALL
    SELECT 'raw.vouchers', voucher_id, 'NEGATIVE_VALUE', 'ERROR', column_name || ' must not be negative'
    FROM raw.vouchers
    CROSS JOIN LATERAL (VALUES ('discount_value', discount_value), ('budget_limit', budget_limit),
        ('min_order_value', min_order_value)) AS value_to_check(column_name, column_value)
    WHERE batch_id = :batch_id
      AND CASE WHEN audit.is_valid_numeric(column_value) THEN column_value::NUMERIC < 0 ELSE FALSE END
    UNION ALL
    SELECT 'raw.vouchers', voucher_id, 'INVALID_DISCOUNT', 'ERROR',
           'percent discount_value must be between 0 and 1'
    FROM raw.vouchers
    WHERE batch_id = :batch_id AND LOWER(BTRIM(discount_type)) = 'percent'
      AND CASE WHEN audit.is_valid_numeric(discount_value)
               THEN discount_value::NUMERIC <= 0 OR discount_value::NUMERIC > 1 ELSE FALSE END
)
INSERT INTO audit.data_quality_errors (
    batch_id, source_table, row_identifier, pipeline_step,
    error_type, severity, error_detail, detected_at
)
SELECT CAST(:batch_id AS UUID), source_table, LEFT(row_identifier, 100), 'DQ_RAW',
       error_type, severity, error_detail, NOW()
FROM dq_errors;

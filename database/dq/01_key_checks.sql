WITH dq_errors AS (
    -- Completeness của natural key.
    SELECT 'raw.branches' AS source_table, COALESCE(NULLIF(BTRIM(branch_id), ''), '<missing>') AS row_identifier,
           'MISSING_KEY' AS error_type, 'ERROR' AS severity, 'branch_id is null or blank' AS error_detail
    FROM raw.branches WHERE batch_id = :batch_id AND NULLIF(BTRIM(branch_id), '') IS NULL
    UNION ALL
    SELECT 'raw.campaigns', COALESCE(NULLIF(BTRIM(campaign_id), ''), '<missing>'), 'MISSING_KEY', 'ERROR', 'campaign_id is null or blank'
    FROM raw.campaigns WHERE batch_id = :batch_id AND NULLIF(BTRIM(campaign_id), '') IS NULL
    UNION ALL
    SELECT 'raw.customers', COALESCE(NULLIF(BTRIM(customer_id), ''), '<missing>'), 'MISSING_KEY', 'ERROR', 'customer_id is null or blank'
    FROM raw.customers WHERE batch_id = :batch_id AND NULLIF(BTRIM(customer_id), '') IS NULL
    UNION ALL
    SELECT 'raw.employee_shifts', COALESCE(NULLIF(BTRIM(shift_id), ''), '<missing>'), 'MISSING_KEY', 'ERROR', 'shift_id is null or blank'
    FROM raw.employee_shifts WHERE batch_id = :batch_id AND NULLIF(BTRIM(shift_id), '') IS NULL
    UNION ALL
    SELECT 'raw.employees', COALESCE(NULLIF(BTRIM(employee_id), ''), '<missing>'), 'MISSING_KEY', 'ERROR', 'employee_id is null or blank'
    FROM raw.employees WHERE batch_id = :batch_id AND NULLIF(BTRIM(employee_id), '') IS NULL
    UNION ALL
    SELECT 'raw.ingredients', COALESCE(NULLIF(BTRIM(ingredient_id), ''), '<missing>'), 'MISSING_KEY', 'ERROR', 'ingredient_id is null or blank'
    FROM raw.ingredients WHERE batch_id = :batch_id AND NULLIF(BTRIM(ingredient_id), '') IS NULL
    UNION ALL
    SELECT 'raw.inventory_daily', CONCAT_WS('|', 'date=' || COALESCE(NULLIF(BTRIM(date), ''), '<missing>'),
           'branch_id=' || COALESCE(NULLIF(BTRIM(branch_id), ''), '<missing>'),
           'ingredient_id=' || COALESCE(NULLIF(BTRIM(ingredient_id), ''), '<missing>')),
           'MISSING_KEY', 'ERROR', 'inventory composite key contains null or blank'
    FROM raw.inventory_daily
    WHERE batch_id = :batch_id
      AND (NULLIF(BTRIM(date), '') IS NULL OR NULLIF(BTRIM(branch_id), '') IS NULL OR NULLIF(BTRIM(ingredient_id), '') IS NULL)
    UNION ALL
    SELECT 'raw.order_items', CONCAT_WS('|', 'order_id=' || COALESCE(NULLIF(BTRIM(order_id), ''), '<missing>'),
           'product_id=' || COALESCE(NULLIF(BTRIM(product_id), ''), '<missing>')),
           'MISSING_KEY', 'ERROR', 'order item composite key contains null or blank'
    FROM raw.order_items
    WHERE batch_id = :batch_id AND (NULLIF(BTRIM(order_id), '') IS NULL OR NULLIF(BTRIM(product_id), '') IS NULL)
    UNION ALL
    SELECT 'raw.orders', COALESCE(NULLIF(BTRIM(order_id), ''), '<missing>'), 'MISSING_KEY', 'ERROR', 'order_id is null or blank'
    FROM raw.orders WHERE batch_id = :batch_id AND NULLIF(BTRIM(order_id), '') IS NULL
    UNION ALL
    SELECT 'raw.payments', COALESCE(NULLIF(BTRIM(payment_id), ''), '<missing>'), 'MISSING_KEY', 'ERROR', 'payment_id is null or blank'
    FROM raw.payments WHERE batch_id = :batch_id AND NULLIF(BTRIM(payment_id), '') IS NULL
    UNION ALL
    SELECT 'raw.products', COALESCE(NULLIF(BTRIM(product_id), ''), '<missing>'), 'MISSING_KEY', 'ERROR', 'product_id is null or blank'
    FROM raw.products WHERE batch_id = :batch_id AND NULLIF(BTRIM(product_id), '') IS NULL
    UNION ALL
    SELECT 'raw.purchase_orders', COALESCE(NULLIF(BTRIM(purchase_order_id), ''), '<missing>'), 'MISSING_KEY', 'ERROR', 'purchase_order_id is null or blank'
    FROM raw.purchase_orders WHERE batch_id = :batch_id AND NULLIF(BTRIM(purchase_order_id), '') IS NULL
    UNION ALL
    SELECT 'raw.recipes', CONCAT_WS('|', 'product_id=' || COALESCE(NULLIF(BTRIM(product_id), ''), '<missing>'),
           'ingredient_id=' || COALESCE(NULLIF(BTRIM(ingredient_id), ''), '<missing>')),
           'MISSING_KEY', 'ERROR', 'recipe composite key contains null or blank'
    FROM raw.recipes
    WHERE batch_id = :batch_id AND (NULLIF(BTRIM(product_id), '') IS NULL OR NULLIF(BTRIM(ingredient_id), '') IS NULL)
    UNION ALL
    SELECT 'raw.suppliers', COALESCE(NULLIF(BTRIM(supplier_id), ''), '<missing>'), 'MISSING_KEY', 'ERROR', 'supplier_id is null or blank'
    FROM raw.suppliers WHERE batch_id = :batch_id AND NULLIF(BTRIM(supplier_id), '') IS NULL
    UNION ALL
    SELECT 'raw.vouchers', COALESCE(NULLIF(BTRIM(voucher_id), ''), '<missing>'), 'MISSING_KEY', 'ERROR', 'voucher_id is null or blank'
    FROM raw.vouchers WHERE batch_id = :batch_id AND NULLIF(BTRIM(voucher_id), '') IS NULL

    UNION ALL

    -- Completeness của các thuộc tính mô tả bắt buộc.
    SELECT 'raw.branches', branch_id, 'MISSING_REQUIRED_VALUE', 'ERROR',
           column_name || ' is null or blank'
    FROM raw.branches
    CROSS JOIN LATERAL (VALUES ('branch_name', branch_name), ('city', city)) AS required_value(column_name, column_value)
    WHERE batch_id = :batch_id AND NULLIF(BTRIM(column_value), '') IS NULL
    UNION ALL
    SELECT 'raw.campaigns', campaign_id, 'MISSING_REQUIRED_VALUE', 'ERROR', 'campaign_name is null or blank'
    FROM raw.campaigns WHERE batch_id = :batch_id AND NULLIF(BTRIM(campaign_name), '') IS NULL
    UNION ALL
    SELECT 'raw.customers', customer_id, 'MISSING_REQUIRED_VALUE', 'ERROR', 'customer_name is null or blank'
    FROM raw.customers WHERE batch_id = :batch_id AND NULLIF(BTRIM(customer_name), '') IS NULL
    UNION ALL
    SELECT 'raw.employees', employee_id, 'MISSING_REQUIRED_VALUE', 'ERROR',
           column_name || ' is null or blank'
    FROM raw.employees
    CROSS JOIN LATERAL (VALUES ('employee_name', employee_name), ('role', role)) AS required_value(column_name, column_value)
    WHERE batch_id = :batch_id AND NULLIF(BTRIM(column_value), '') IS NULL
    UNION ALL
    SELECT 'raw.ingredients', ingredient_id, 'MISSING_REQUIRED_VALUE', 'ERROR',
           column_name || ' is null or blank'
    FROM raw.ingredients
    CROSS JOIN LATERAL (VALUES ('ingredient_name', ingredient_name), ('unit', unit)) AS required_value(column_name, column_value)
    WHERE batch_id = :batch_id AND NULLIF(BTRIM(column_value), '') IS NULL
    UNION ALL
    SELECT 'raw.products', product_id, 'MISSING_REQUIRED_VALUE', 'ERROR',
           column_name || ' is null or blank'
    FROM raw.products
    CROSS JOIN LATERAL (VALUES ('product_name', product_name), ('category', category)) AS required_value(column_name, column_value)
    WHERE batch_id = :batch_id AND NULLIF(BTRIM(column_value), '') IS NULL
    UNION ALL
    SELECT 'raw.suppliers', supplier_id, 'MISSING_REQUIRED_VALUE', 'ERROR', 'supplier_name is null or blank'
    FROM raw.suppliers WHERE batch_id = :batch_id AND NULLIF(BTRIM(supplier_name), '') IS NULL
    UNION ALL
    SELECT 'raw.vouchers', voucher_id, 'MISSING_REQUIRED_VALUE', 'ERROR', 'voucher_code is null or blank'
    FROM raw.vouchers WHERE batch_id = :batch_id AND NULLIF(BTRIM(voucher_code), '') IS NULL

    UNION ALL

    -- Uniqueness trong cùng batch.
    SELECT 'raw.branches', branch_id, 'DUPLICATE_KEY', 'ERROR', 'branch_id duplicated ' || COUNT(*) || ' times'
    FROM raw.branches WHERE batch_id = :batch_id AND NULLIF(BTRIM(branch_id), '') IS NOT NULL GROUP BY branch_id HAVING COUNT(*) > 1
    UNION ALL
    SELECT 'raw.campaigns', campaign_id, 'DUPLICATE_KEY', 'ERROR', 'campaign_id duplicated ' || COUNT(*) || ' times'
    FROM raw.campaigns WHERE batch_id = :batch_id AND NULLIF(BTRIM(campaign_id), '') IS NOT NULL GROUP BY campaign_id HAVING COUNT(*) > 1
    UNION ALL
    SELECT 'raw.customers', customer_id, 'DUPLICATE_KEY', 'ERROR', 'customer_id duplicated ' || COUNT(*) || ' times'
    FROM raw.customers WHERE batch_id = :batch_id AND NULLIF(BTRIM(customer_id), '') IS NOT NULL GROUP BY customer_id HAVING COUNT(*) > 1
    UNION ALL
    SELECT 'raw.employee_shifts', shift_id, 'DUPLICATE_KEY', 'ERROR', 'shift_id duplicated ' || COUNT(*) || ' times'
    FROM raw.employee_shifts WHERE batch_id = :batch_id AND NULLIF(BTRIM(shift_id), '') IS NOT NULL GROUP BY shift_id HAVING COUNT(*) > 1
    UNION ALL
    SELECT 'raw.employees', employee_id, 'DUPLICATE_KEY', 'ERROR', 'employee_id duplicated ' || COUNT(*) || ' times'
    FROM raw.employees WHERE batch_id = :batch_id AND NULLIF(BTRIM(employee_id), '') IS NOT NULL GROUP BY employee_id HAVING COUNT(*) > 1
    UNION ALL
    SELECT 'raw.ingredients', ingredient_id, 'DUPLICATE_KEY', 'ERROR', 'ingredient_id duplicated ' || COUNT(*) || ' times'
    FROM raw.ingredients WHERE batch_id = :batch_id AND NULLIF(BTRIM(ingredient_id), '') IS NOT NULL GROUP BY ingredient_id HAVING COUNT(*) > 1
    UNION ALL
    SELECT 'raw.inventory_daily', CONCAT_WS('|', 'date=' || date, 'branch_id=' || branch_id, 'ingredient_id=' || ingredient_id),
           'DUPLICATE_KEY', 'ERROR', 'inventory composite key duplicated ' || COUNT(*) || ' times'
    FROM raw.inventory_daily WHERE batch_id = :batch_id
      AND NULLIF(BTRIM(date), '') IS NOT NULL AND NULLIF(BTRIM(branch_id), '') IS NOT NULL AND NULLIF(BTRIM(ingredient_id), '') IS NOT NULL
    GROUP BY date, branch_id, ingredient_id HAVING COUNT(*) > 1
    UNION ALL
    SELECT 'raw.orders', order_id, 'DUPLICATE_KEY', 'ERROR', 'order_id duplicated ' || COUNT(*) || ' times'
    FROM raw.orders WHERE batch_id = :batch_id AND NULLIF(BTRIM(order_id), '') IS NOT NULL GROUP BY order_id HAVING COUNT(*) > 1
    UNION ALL
    SELECT 'raw.payments', payment_id, 'DUPLICATE_KEY', 'ERROR', 'payment_id duplicated ' || COUNT(*) || ' times'
    FROM raw.payments WHERE batch_id = :batch_id AND NULLIF(BTRIM(payment_id), '') IS NOT NULL GROUP BY payment_id HAVING COUNT(*) > 1
    UNION ALL
    SELECT 'raw.products', product_id, 'DUPLICATE_KEY', 'ERROR', 'product_id duplicated ' || COUNT(*) || ' times'
    FROM raw.products WHERE batch_id = :batch_id AND NULLIF(BTRIM(product_id), '') IS NOT NULL GROUP BY product_id HAVING COUNT(*) > 1
    UNION ALL
    SELECT 'raw.purchase_orders', purchase_order_id, 'DUPLICATE_KEY', 'ERROR', 'purchase_order_id duplicated ' || COUNT(*) || ' times'
    FROM raw.purchase_orders WHERE batch_id = :batch_id AND NULLIF(BTRIM(purchase_order_id), '') IS NOT NULL GROUP BY purchase_order_id HAVING COUNT(*) > 1
    UNION ALL
    SELECT 'raw.recipes', CONCAT_WS('|', 'product_id=' || product_id, 'ingredient_id=' || ingredient_id),
           'DUPLICATE_KEY', 'ERROR', 'recipe composite key duplicated ' || COUNT(*) || ' times'
    FROM raw.recipes WHERE batch_id = :batch_id
      AND NULLIF(BTRIM(product_id), '') IS NOT NULL AND NULLIF(BTRIM(ingredient_id), '') IS NOT NULL
    GROUP BY product_id, ingredient_id HAVING COUNT(*) > 1
    UNION ALL
    SELECT 'raw.suppliers', supplier_id, 'DUPLICATE_KEY', 'ERROR', 'supplier_id duplicated ' || COUNT(*) || ' times'
    FROM raw.suppliers WHERE batch_id = :batch_id AND NULLIF(BTRIM(supplier_id), '') IS NOT NULL GROUP BY supplier_id HAVING COUNT(*) > 1
    UNION ALL
    SELECT 'raw.vouchers', voucher_id, 'DUPLICATE_KEY', 'ERROR', 'voucher_id duplicated ' || COUNT(*) || ' times'
    FROM raw.vouchers WHERE batch_id = :batch_id AND NULLIF(BTRIM(voucher_id), '') IS NOT NULL GROUP BY voucher_id HAVING COUNT(*) > 1
)
INSERT INTO audit.data_quality_errors (
    batch_id, source_table, row_identifier, pipeline_step,
    error_type, severity, error_detail, detected_at
)
SELECT CAST(:batch_id AS UUID), source_table, LEFT(row_identifier, 100), 'DQ_RAW',
       error_type, severity, error_detail, NOW()
FROM dq_errors;

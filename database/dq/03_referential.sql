WITH dq_errors AS (
    SELECT 'raw.employees' AS source_table, e.employee_id AS row_identifier,
           'ORPHAN_FOREIGN_KEY' AS error_type, 'ERROR' AS severity,
           'branch_id not found in raw.branches: ' || COALESCE(e.branch_id, '<null>') AS error_detail
    FROM raw.employees e
    WHERE e.batch_id = :batch_id
      AND NOT EXISTS (
          SELECT 1 FROM raw.branches b
          WHERE b.batch_id = :batch_id AND b.branch_id = e.branch_id
      )
    UNION ALL
    SELECT 'raw.employee_shifts', s.shift_id, 'ORPHAN_FOREIGN_KEY', 'ERROR',
           'branch_id not found in raw.branches: ' || COALESCE(s.branch_id, '<null>')
    FROM raw.employee_shifts s
    WHERE s.batch_id = :batch_id
      AND NOT EXISTS (SELECT 1 FROM raw.branches b WHERE b.batch_id = :batch_id AND b.branch_id = s.branch_id)
    UNION ALL
    SELECT 'raw.employee_shifts', s.shift_id, 'ORPHAN_FOREIGN_KEY', 'ERROR',
           'employee_id not found in raw.employees: ' || COALESCE(s.employee_id, '<null>')
    FROM raw.employee_shifts s
    WHERE s.batch_id = :batch_id
      AND NOT EXISTS (SELECT 1 FROM raw.employees e WHERE e.batch_id = :batch_id AND e.employee_id = s.employee_id)
    UNION ALL
    SELECT 'raw.inventory_daily', CONCAT_WS('|', 'date=' || i.date, 'branch_id=' || i.branch_id, 'ingredient_id=' || i.ingredient_id),
           'ORPHAN_FOREIGN_KEY', 'ERROR', 'branch_id not found in raw.branches: ' || COALESCE(i.branch_id, '<null>')
    FROM raw.inventory_daily i
    WHERE i.batch_id = :batch_id
      AND NOT EXISTS (SELECT 1 FROM raw.branches b WHERE b.batch_id = :batch_id AND b.branch_id = i.branch_id)
    UNION ALL
    SELECT 'raw.inventory_daily', CONCAT_WS('|', 'date=' || i.date, 'branch_id=' || i.branch_id, 'ingredient_id=' || i.ingredient_id),
           'ORPHAN_FOREIGN_KEY', 'ERROR', 'ingredient_id not found in raw.ingredients: ' || COALESCE(i.ingredient_id, '<null>')
    FROM raw.inventory_daily i
    WHERE i.batch_id = :batch_id
      AND NOT EXISTS (SELECT 1 FROM raw.ingredients g WHERE g.batch_id = :batch_id AND g.ingredient_id = i.ingredient_id)
    UNION ALL
    SELECT 'raw.orders', o.order_id, 'ORPHAN_FOREIGN_KEY', 'ERROR',
           'branch_id not found in raw.branches: ' || COALESCE(o.branch_id, '<null>')
    FROM raw.orders o
    WHERE o.batch_id = :batch_id
      AND NOT EXISTS (SELECT 1 FROM raw.branches b WHERE b.batch_id = :batch_id AND b.branch_id = o.branch_id)
    UNION ALL
    SELECT 'raw.orders', o.order_id, 'ORPHAN_FOREIGN_KEY', 'ERROR',
           'customer_id not found in raw.customers: ' || COALESCE(o.customer_id, '<null>')
    FROM raw.orders o
    WHERE o.batch_id = :batch_id
      AND NULLIF(BTRIM(o.customer_id), '') IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM raw.customers c WHERE c.batch_id = :batch_id AND c.customer_id = o.customer_id)
    UNION ALL
    SELECT 'raw.orders', o.order_id, 'ORPHAN_FOREIGN_KEY', 'ERROR',
           'cashier_employee_id not found in raw.employees: ' || COALESCE(o.cashier_employee_id, '<null>')
    FROM raw.orders o
    WHERE o.batch_id = :batch_id
      AND NOT EXISTS (SELECT 1 FROM raw.employees e WHERE e.batch_id = :batch_id AND e.employee_id = o.cashier_employee_id)
    UNION ALL
    SELECT 'raw.order_items', CONCAT_WS('|', 'order_id=' || i.order_id, 'product_id=' || i.product_id),
           'ORPHAN_FOREIGN_KEY', 'ERROR', 'order_id not found in raw.orders: ' || COALESCE(i.order_id, '<null>')
    FROM raw.order_items i
    WHERE i.batch_id = :batch_id
      AND NOT EXISTS (SELECT 1 FROM raw.orders o WHERE o.batch_id = :batch_id AND o.order_id = i.order_id)
    UNION ALL
    SELECT 'raw.order_items', CONCAT_WS('|', 'order_id=' || i.order_id, 'product_id=' || i.product_id),
           'ORPHAN_FOREIGN_KEY', 'ERROR', 'product_id not found in raw.products: ' || COALESCE(i.product_id, '<null>')
    FROM raw.order_items i
    WHERE i.batch_id = :batch_id
      AND NOT EXISTS (SELECT 1 FROM raw.products p WHERE p.batch_id = :batch_id AND p.product_id = i.product_id)
    UNION ALL
    SELECT 'raw.payments', p.payment_id, 'ORPHAN_FOREIGN_KEY', 'ERROR',
           'order_id not found in raw.orders: ' || COALESCE(p.order_id, '<null>')
    FROM raw.payments p
    WHERE p.batch_id = :batch_id
      AND NOT EXISTS (SELECT 1 FROM raw.orders o WHERE o.batch_id = :batch_id AND o.order_id = p.order_id)
    UNION ALL
    SELECT 'raw.purchase_orders', p.purchase_order_id, 'ORPHAN_FOREIGN_KEY', 'ERROR',
           'branch_id not found in raw.branches: ' || COALESCE(p.branch_id, '<null>')
    FROM raw.purchase_orders p
    WHERE p.batch_id = :batch_id
      AND NOT EXISTS (SELECT 1 FROM raw.branches b WHERE b.batch_id = :batch_id AND b.branch_id = p.branch_id)
    UNION ALL
    SELECT 'raw.purchase_orders', p.purchase_order_id, 'ORPHAN_FOREIGN_KEY', 'ERROR',
           'ingredient_id not found in raw.ingredients: ' || COALESCE(p.ingredient_id, '<null>')
    FROM raw.purchase_orders p
    WHERE p.batch_id = :batch_id
      AND NOT EXISTS (SELECT 1 FROM raw.ingredients i WHERE i.batch_id = :batch_id AND i.ingredient_id = p.ingredient_id)
    UNION ALL
    SELECT 'raw.purchase_orders', p.purchase_order_id, 'ORPHAN_FOREIGN_KEY', 'ERROR',
           'supplier_id not found in raw.suppliers: ' || COALESCE(p.supplier_id, '<null>')
    FROM raw.purchase_orders p
    WHERE p.batch_id = :batch_id
      AND NOT EXISTS (SELECT 1 FROM raw.suppliers s WHERE s.batch_id = :batch_id AND s.supplier_id = p.supplier_id)
    UNION ALL
    SELECT 'raw.recipes', CONCAT_WS('|', 'product_id=' || r.product_id, 'ingredient_id=' || r.ingredient_id),
           'ORPHAN_FOREIGN_KEY', 'ERROR', 'product_id not found in raw.products: ' || COALESCE(r.product_id, '<null>')
    FROM raw.recipes r
    WHERE r.batch_id = :batch_id
      AND NOT EXISTS (SELECT 1 FROM raw.products p WHERE p.batch_id = :batch_id AND p.product_id = r.product_id)
    UNION ALL
    SELECT 'raw.recipes', CONCAT_WS('|', 'product_id=' || r.product_id, 'ingredient_id=' || r.ingredient_id),
           'ORPHAN_FOREIGN_KEY', 'ERROR', 'ingredient_id not found in raw.ingredients: ' || COALESCE(r.ingredient_id, '<null>')
    FROM raw.recipes r
    WHERE r.batch_id = :batch_id
      AND NOT EXISTS (SELECT 1 FROM raw.ingredients i WHERE i.batch_id = :batch_id AND i.ingredient_id = r.ingredient_id)
    UNION ALL
    SELECT 'raw.vouchers', v.voucher_id, 'ORPHAN_FOREIGN_KEY', 'ERROR',
           'campaign_id not found in raw.campaigns: ' || COALESCE(v.campaign_id, '<null>')
    FROM raw.vouchers v
    WHERE v.batch_id = :batch_id
      AND NOT EXISTS (SELECT 1 FROM raw.campaigns c WHERE c.batch_id = :batch_id AND c.campaign_id = v.campaign_id)
)
INSERT INTO audit.data_quality_errors (
    batch_id, source_table, row_identifier, pipeline_step,
    error_type, severity, error_detail, detected_at
)
SELECT CAST(:batch_id AS UUID), source_table, LEFT(row_identifier, 100), 'DQ_RAW',
       error_type, severity, error_detail, NOW()
FROM dq_errors;

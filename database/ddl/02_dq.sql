-- Migration idempotent cho những database đã tạo audit.data_quality_errors.
ALTER TABLE audit.data_quality_errors
    ADD COLUMN IF NOT EXISTS severity VARCHAR(10) NOT NULL DEFAULT 'ERROR';

CREATE INDEX IF NOT EXISTS idx_dq_errors_batch_step
    ON audit.data_quality_errors (batch_id, pipeline_step);

-- DQ luôn lọc raw theo batch_id; các index này tránh quét toàn bộ lịch sử.
CREATE INDEX IF NOT EXISTS idx_raw_branches_batch ON raw.branches (batch_id);
CREATE INDEX IF NOT EXISTS idx_raw_campaigns_batch ON raw.campaigns (batch_id);
CREATE INDEX IF NOT EXISTS idx_raw_customers_batch ON raw.customers (batch_id);
CREATE INDEX IF NOT EXISTS idx_raw_data_dictionary_batch ON raw.data_dictionary (batch_id);
CREATE INDEX IF NOT EXISTS idx_raw_employee_shifts_batch ON raw.employee_shifts (batch_id);
CREATE INDEX IF NOT EXISTS idx_raw_employees_batch ON raw.employees (batch_id);
CREATE INDEX IF NOT EXISTS idx_raw_ingredients_batch ON raw.ingredients (batch_id);
CREATE INDEX IF NOT EXISTS idx_raw_inventory_daily_batch ON raw.inventory_daily (batch_id);
CREATE INDEX IF NOT EXISTS idx_raw_order_items_batch ON raw.order_items (batch_id);
CREATE INDEX IF NOT EXISTS idx_raw_orders_batch ON raw.orders (batch_id);
CREATE INDEX IF NOT EXISTS idx_raw_payments_batch ON raw.payments (batch_id);
CREATE INDEX IF NOT EXISTS idx_raw_products_batch ON raw.products (batch_id);
CREATE INDEX IF NOT EXISTS idx_raw_purchase_orders_batch ON raw.purchase_orders (batch_id);
CREATE INDEX IF NOT EXISTS idx_raw_recipes_batch ON raw.recipes (batch_id);
CREATE INDEX IF NOT EXISTS idx_raw_suppliers_batch ON raw.suppliers (batch_id);
CREATE INDEX IF NOT EXISTS idx_raw_vouchers_batch ON raw.vouchers (batch_id);

-- Các hàm ép kiểu an toàn dành cho raw layer đang lưu dữ liệu dạng TEXT.
CREATE OR REPLACE FUNCTION audit.is_valid_numeric(input_value TEXT)
RETURNS BOOLEAN
LANGUAGE SQL
IMMUTABLE
AS $$
    SELECT input_value IS NOT NULL
       AND BTRIM(input_value) ~ '^[+-]?(([0-9]+([.][0-9]+)?)|([.][0-9]+))$';
$$;

CREATE OR REPLACE FUNCTION audit.is_valid_date(input_value TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    IF input_value IS NULL OR BTRIM(input_value) = '' THEN
        RETURN FALSE;
    END IF;
    PERFORM BTRIM(input_value)::DATE;
    RETURN TRUE;
EXCEPTION WHEN OTHERS THEN
    RETURN FALSE;
END;
$$;

CREATE OR REPLACE FUNCTION audit.is_valid_timestamp(input_value TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    IF input_value IS NULL OR BTRIM(input_value) = '' THEN
        RETURN FALSE;
    END IF;
    PERFORM BTRIM(input_value)::TIMESTAMP;
    RETURN TRUE;
EXCEPTION WHEN OTHERS THEN
    RETURN FALSE;
END;
$$;

CREATE OR REPLACE FUNCTION audit.is_valid_time(input_value TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    IF input_value IS NULL OR BTRIM(input_value) = '' THEN
        RETURN FALSE;
    END IF;
    PERFORM BTRIM(input_value)::TIME;
    RETURN TRUE;
EXCEPTION WHEN OTHERS THEN
    RETURN FALSE;
END;
$$;

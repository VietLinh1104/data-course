CREATE SCHEMA IF NOT EXISTS staging;

-- Staging giữ dữ liệu đã chuẩn hóa theo từng batch để có thể replay và đối chiếu.
CREATE TABLE IF NOT EXISTS staging.stg_branches (
    batch_id UUID NOT NULL,
    branch_id VARCHAR(20) NOT NULL,
    branch_name VARCHAR(150) NOT NULL,
    city VARCHAR(100) NOT NULL,
    district_type VARCHAR(50),
    store_type VARCHAR(50),
    sales_multiplier NUMERIC(10, 4) NOT NULL,
    source_file_name TEXT NOT NULL,
    loaded_at TIMESTAMP NOT NULL,
    staged_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (batch_id, branch_id)
);

CREATE TABLE IF NOT EXISTS staging.stg_campaigns (
    batch_id UUID NOT NULL,
    campaign_id VARCHAR(20) NOT NULL,
    campaign_name VARCHAR(200) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    scope VARCHAR(50),
    objective VARCHAR(100),
    source_file_name TEXT NOT NULL,
    loaded_at TIMESTAMP NOT NULL,
    staged_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (batch_id, campaign_id)
);

CREATE TABLE IF NOT EXISTS staging.stg_customers (
    batch_id UUID NOT NULL,
    customer_id VARCHAR(30) NOT NULL,
    customer_name VARCHAR(200) NOT NULL,
    segment VARCHAR(50),
    signup_date DATE NOT NULL,
    city VARCHAR(100),
    source_file_name TEXT NOT NULL,
    loaded_at TIMESTAMP NOT NULL,
    staged_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (batch_id, customer_id)
);

CREATE TABLE IF NOT EXISTS staging.stg_data_dictionary (
    batch_id UUID NOT NULL,
    source_table VARCHAR(100) NOT NULL,
    expected_rows BIGINT NOT NULL,
    description TEXT,
    source_file_name TEXT NOT NULL,
    loaded_at TIMESTAMP NOT NULL,
    staged_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (batch_id, source_table)
);

CREATE TABLE IF NOT EXISTS staging.stg_employees (
    batch_id UUID NOT NULL,
    employee_id VARCHAR(30) NOT NULL,
    branch_id VARCHAR(20) NOT NULL,
    employee_name VARCHAR(200) NOT NULL,
    role VARCHAR(50) NOT NULL,
    hourly_rate NUMERIC(18, 2) NOT NULL,
    employment_type VARCHAR(30) NOT NULL,
    hire_date DATE NOT NULL,
    source_file_name TEXT NOT NULL,
    loaded_at TIMESTAMP NOT NULL,
    staged_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (batch_id, employee_id)
);

CREATE TABLE IF NOT EXISTS staging.stg_employee_shifts (
    batch_id UUID NOT NULL,
    shift_id VARCHAR(30) NOT NULL,
    shift_date DATE NOT NULL,
    branch_id VARCHAR(20) NOT NULL,
    employee_id VARCHAR(30) NOT NULL,
    shift_name VARCHAR(30) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    working_hours NUMERIC(8, 2) NOT NULL,
    salary_cost NUMERIC(18, 2) NOT NULL,
    attendance_status VARCHAR(30) NOT NULL,
    source_file_name TEXT NOT NULL,
    loaded_at TIMESTAMP NOT NULL,
    staged_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (batch_id, shift_id)
);

CREATE TABLE IF NOT EXISTS staging.stg_ingredients (
    batch_id UUID NOT NULL,
    ingredient_id VARCHAR(30) NOT NULL,
    ingredient_name VARCHAR(200) NOT NULL,
    unit VARCHAR(30) NOT NULL,
    base_unit_cost NUMERIC(18, 4) NOT NULL,
    is_perishable BOOLEAN NOT NULL,
    storage_type VARCHAR(30) NOT NULL,
    source_file_name TEXT NOT NULL,
    loaded_at TIMESTAMP NOT NULL,
    staged_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (batch_id, ingredient_id)
);

CREATE TABLE IF NOT EXISTS staging.stg_inventory_daily (
    batch_id UUID NOT NULL,
    inventory_date DATE NOT NULL,
    branch_id VARCHAR(20) NOT NULL,
    ingredient_id VARCHAR(30) NOT NULL,
    opening_stock NUMERIC(20, 4) NOT NULL,
    stock_in NUMERIC(20, 4) NOT NULL,
    stock_out_usage NUMERIC(20, 4) NOT NULL,
    waste NUMERIC(20, 4) NOT NULL,
    closing_stock NUMERIC(20, 4) NOT NULL,
    is_stockout BOOLEAN NOT NULL,
    unmet_demand NUMERIC(20, 4) NOT NULL,
    source_file_name TEXT NOT NULL,
    loaded_at TIMESTAMP NOT NULL,
    staged_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (batch_id, inventory_date, branch_id, ingredient_id)
);

CREATE TABLE IF NOT EXISTS staging.stg_orders (
    batch_id UUID NOT NULL,
    order_id VARCHAR(30) NOT NULL,
    branch_id VARCHAR(20) NOT NULL,
    customer_id VARCHAR(30),
    order_datetime TIMESTAMP NOT NULL,
    channel VARCHAR(30) NOT NULL,
    gross_amount NUMERIC(18, 2) NOT NULL,
    discount_amount NUMERIC(18, 2) NOT NULL,
    net_amount NUMERIC(18, 2) NOT NULL,
    cashier_employee_id VARCHAR(30) NOT NULL,
    status VARCHAR(30) NOT NULL,
    source_file_name TEXT NOT NULL,
    loaded_at TIMESTAMP NOT NULL,
    staged_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (batch_id, order_id)
);

-- Nguồn không có order_item_id và (order_id, product_id) không duy nhất.
CREATE TABLE IF NOT EXISTS staging.stg_order_items (
    order_item_sk BIGSERIAL PRIMARY KEY,
    batch_id UUID NOT NULL,
    order_id VARCHAR(30) NOT NULL,
    product_id VARCHAR(30) NOT NULL,
    quantity NUMERIC(12, 4) NOT NULL,
    unit_price NUMERIC(18, 2) NOT NULL,
    line_amount NUMERIC(18, 2) NOT NULL,
    source_file_name TEXT NOT NULL,
    loaded_at TIMESTAMP NOT NULL,
    staged_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stg_order_items_batch_order
    ON staging.stg_order_items (batch_id, order_id);

CREATE TABLE IF NOT EXISTS staging.stg_payments (
    batch_id UUID NOT NULL,
    payment_id VARCHAR(30) NOT NULL,
    order_id VARCHAR(30) NOT NULL,
    payment_method VARCHAR(30) NOT NULL,
    amount NUMERIC(18, 2) NOT NULL,
    paid_at TIMESTAMP NOT NULL,
    source_file_name TEXT NOT NULL,
    loaded_at TIMESTAMP NOT NULL,
    staged_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (batch_id, payment_id)
);

CREATE TABLE IF NOT EXISTS staging.stg_products (
    batch_id UUID NOT NULL,
    product_id VARCHAR(30) NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    category VARCHAR(100) NOT NULL,
    selling_price NUMERIC(18, 2) NOT NULL,
    is_active BOOLEAN NOT NULL,
    popularity_weight NUMERIC(12, 4) NOT NULL,
    source_file_name TEXT NOT NULL,
    loaded_at TIMESTAMP NOT NULL,
    staged_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (batch_id, product_id)
);

CREATE TABLE IF NOT EXISTS staging.stg_purchase_orders (
    batch_id UUID NOT NULL,
    purchase_order_id VARCHAR(30) NOT NULL,
    purchase_date DATE NOT NULL,
    branch_id VARCHAR(20) NOT NULL,
    ingredient_id VARCHAR(30) NOT NULL,
    supplier_id VARCHAR(30) NOT NULL,
    quantity NUMERIC(20, 4) NOT NULL,
    unit_cost NUMERIC(18, 4) NOT NULL,
    total_cost NUMERIC(20, 2) NOT NULL,
    source_file_name TEXT NOT NULL,
    loaded_at TIMESTAMP NOT NULL,
    staged_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (batch_id, purchase_order_id)
);

CREATE TABLE IF NOT EXISTS staging.stg_recipes (
    batch_id UUID NOT NULL,
    product_id VARCHAR(30) NOT NULL,
    ingredient_id VARCHAR(30) NOT NULL,
    quantity_per_unit NUMERIC(20, 4) NOT NULL,
    source_file_name TEXT NOT NULL,
    loaded_at TIMESTAMP NOT NULL,
    staged_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (batch_id, product_id, ingredient_id)
);

CREATE TABLE IF NOT EXISTS staging.stg_suppliers (
    batch_id UUID NOT NULL,
    supplier_id VARCHAR(30) NOT NULL,
    supplier_name VARCHAR(200) NOT NULL,
    category VARCHAR(100),
    city VARCHAR(100),
    source_file_name TEXT NOT NULL,
    loaded_at TIMESTAMP NOT NULL,
    staged_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (batch_id, supplier_id)
);

CREATE TABLE IF NOT EXISTS staging.stg_vouchers (
    batch_id UUID NOT NULL,
    voucher_id VARCHAR(30) NOT NULL,
    campaign_id VARCHAR(30) NOT NULL,
    voucher_code VARCHAR(100) NOT NULL,
    discount_type VARCHAR(30) NOT NULL,
    discount_value NUMERIC(18, 4) NOT NULL,
    budget_limit NUMERIC(18, 2) NOT NULL,
    min_order_value NUMERIC(18, 2) NOT NULL,
    source_file_name TEXT NOT NULL,
    loaded_at TIMESTAMP NOT NULL,
    staged_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (batch_id, voucher_id)
);

CREATE INDEX IF NOT EXISTS idx_stg_orders_batch_datetime
    ON staging.stg_orders (batch_id, order_datetime);

CREATE INDEX IF NOT EXISTS idx_stg_inventory_batch_date
    ON staging.stg_inventory_daily (batch_id, inventory_date);

CREATE INDEX IF NOT EXISTS idx_stg_shifts_batch_date
    ON staging.stg_employee_shifts (batch_id, shift_date);

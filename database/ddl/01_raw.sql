CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE IF NOT EXISTS raw.orders (
    -- Columns từ CSV (giữ nguyên kiểu TEXT)
    order_id              TEXT,
    branch_id             TEXT,
    customer_id           TEXT,
    order_datetime        TEXT,
    channel               TEXT,
    gross_amount          TEXT,
    discount_amount       TEXT,
    net_amount            TEXT,
    cashier_employee_id   TEXT,
    status                TEXT,
    -- 3 cột metadata bắt buộc
    batch_id              TEXT        NOT NULL,
    source_file_name      TEXT        NOT NULL,
    loaded_at             TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.branches (
    -- Columns từ CSV (giữ nguyên kiểu TEXT)
    branch_id               TEXT,
    branch_name             TEXT,
    city                    TEXT,
    district_type           TEXT,
    store_type              TEXT,
    sales_multiplier        TEXT,

    -- 3 cột metadata bắt buộc
    batch_id                TEXT        NOT NULL,
    source_file_name        TEXT        NOT NULL,
    loaded_at               TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE IF NOT EXISTS raw.campaigns (
    campaign_id        TEXT,
    campaign_name      TEXT,
    start_date         TEXT,
    end_date           TEXT,
    scope              TEXT,
    objective          TEXT,

    batch_id           TEXT        NOT NULL,
    source_file_name   TEXT        NOT NULL,
    loaded_at          TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.customers (
    customer_id            TEXT,
    customer_name          TEXT,
    segment                TEXT,
    signup_date            TEXT,
    city                   TEXT,
    batch_id               TEXT NOT NULL,
    source_file_name       TEXT NOT NULL,
    loaded_at              TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.employee_shifts (
    shift_id               TEXT,
    date                   TEXT,
    branch_id              TEXT,
    employee_id            TEXT,
    shift_name             TEXT,
    start_time             TEXT,
    end_time               TEXT,
    working_hours          TEXT,
    salary_cost            TEXT,
    attendance_status      TEXT,
    batch_id               TEXT NOT NULL,
    source_file_name       TEXT NOT NULL,
    loaded_at              TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.employees (
    employee_id            TEXT,
    branch_id              TEXT,
    employee_name          TEXT,
    role                   TEXT,
    hourly_rate            TEXT,
    employment_type        TEXT,
    hire_date              TEXT,
    batch_id               TEXT NOT NULL,
    source_file_name       TEXT NOT NULL,
    loaded_at              TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.ingredients (
    ingredient_id          TEXT,
    ingredient_name        TEXT,
    unit                   TEXT,
    base_unit_cost         TEXT,
    is_perishable          TEXT,
    storage_type           TEXT,
    batch_id               TEXT NOT NULL,
    source_file_name       TEXT NOT NULL,
    loaded_at              TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.inventory_daily (
    date                   TEXT,
    branch_id              TEXT,
    ingredient_id          TEXT,
    opening_stock          TEXT,
    stock_in               TEXT,
    stock_out_usage        TEXT,
    waste                  TEXT,
    closing_stock          TEXT,
    batch_id               TEXT NOT NULL,
    source_file_name       TEXT NOT NULL,
    loaded_at              TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.order_items (
    order_id               TEXT,
    product_id             TEXT,
    quantity               TEXT,
    unit_price             TEXT,
    line_amount            TEXT,
    batch_id               TEXT NOT NULL,
    source_file_name       TEXT NOT NULL,
    loaded_at              TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.payments (
    payment_id             TEXT,
    order_id               TEXT,
    payment_method         TEXT,
    amount                 TEXT,
    paid_at                TEXT,
    batch_id               TEXT NOT NULL,
    source_file_name       TEXT NOT NULL,
    loaded_at              TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.products (
    product_id             TEXT,
    product_name           TEXT,
    category               TEXT,
    selling_price          TEXT,
    is_active              TEXT,
    popularity_weight      TEXT,
    batch_id               TEXT NOT NULL,
    source_file_name       TEXT NOT NULL,
    loaded_at              TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.purchase_orders (
    purchase_order_id      TEXT,
    purchase_date          TEXT,
    branch_id              TEXT,
    ingredient_id          TEXT,
    supplier_id            TEXT,
    quantity               TEXT,
    unit_cost              TEXT,
    total_cost             TEXT,
    batch_id               TEXT NOT NULL,
    source_file_name       TEXT NOT NULL,
    loaded_at              TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.recipes (
    product_id             TEXT,
    ingredient_id          TEXT,
    quantity_per_unit      TEXT,
    batch_id               TEXT NOT NULL,
    source_file_name       TEXT NOT NULL,
    loaded_at              TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.suppliers (
    supplier_id            TEXT,
    supplier_name          TEXT,
    category               TEXT,
    city                   TEXT,
    batch_id               TEXT NOT NULL,
    source_file_name       TEXT NOT NULL,
    loaded_at              TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.vouchers (
    voucher_id             TEXT,
    campaign_id            TEXT,
    voucher_code           TEXT,
    discount_type          TEXT,
    discount_value         TEXT,
    budget_limit           TEXT,
    min_order_value        TEXT,
    batch_id               TEXT NOT NULL,
    source_file_name       TEXT NOT NULL,
    loaded_at              TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.customers (
    customer_id        TEXT,
    customer_name      TEXT,
    segment            TEXT,
    signup_date        TEXT,
    city               TEXT,

    batch_id           TEXT        NOT NULL,
    source_file_name   TEXT        NOT NULL,
    loaded_at          TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.data_dictionary (
    "table"            TEXT,
    rows               TEXT,
    description        TEXT,

    batch_id           TEXT        NOT NULL,
    source_file_name   TEXT        NOT NULL,
    loaded_at          TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.employee_shifts (
    shift_id           TEXT,
    date               TEXT,
    branch_id          TEXT,
    employee_id        TEXT,
    shift_name         TEXT,
    start_time         TEXT,
    end_time           TEXT,
    working_hours      TEXT,
    salary_cost        TEXT,
    attendance_status  TEXT,

    batch_id           TEXT        NOT NULL,
    source_file_name   TEXT        NOT NULL,
    loaded_at          TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.employees (
    employee_id        TEXT,
    branch_id          TEXT,
    employee_name      TEXT,
    role               TEXT,
    hourly_rate        TEXT,
    employment_type    TEXT,
    hire_date          TEXT,

    batch_id           TEXT        NOT NULL,
    source_file_name   TEXT        NOT NULL,
    loaded_at          TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.ingredients (
    ingredient_id      TEXT,
    ingredient_name    TEXT,
    unit               TEXT,
    base_unit_cost     TEXT,
    is_perishable      TEXT,
    storage_type       TEXT,

    batch_id           TEXT        NOT NULL,
    source_file_name   TEXT        NOT NULL,
    loaded_at          TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.inventory_daily (
    date               TEXT,
    branch_id          TEXT,
    ingredient_id      TEXT,
    opening_stock      TEXT,
    stock_in           TEXT,
    stock_out_usage    TEXT,
    waste              TEXT,
    closing_stock      TEXT,

    batch_id           TEXT        NOT NULL,
    source_file_name   TEXT        NOT NULL,
    loaded_at          TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.order_items (
    order_id           TEXT,
    product_id         TEXT,
    quantity           TEXT,
    unit_price         TEXT,
    line_amount        TEXT,

    batch_id           TEXT        NOT NULL,
    source_file_name   TEXT        NOT NULL,
    loaded_at          TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.payments (
    payment_id         TEXT,
    order_id           TEXT,
    payment_method     TEXT,
    amount             TEXT,
    paid_at            TEXT,

    batch_id           TEXT        NOT NULL,
    source_file_name   TEXT        NOT NULL,
    loaded_at          TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.products (
    product_id         TEXT,
    product_name       TEXT,
    category           TEXT,
    selling_price      TEXT,
    is_active          TEXT,
    popularity_weight  TEXT,

    batch_id           TEXT        NOT NULL,
    source_file_name   TEXT        NOT NULL,
    loaded_at          TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.purchase_orders (
    purchase_order_id  TEXT,
    purchase_date      TEXT,
    branch_id          TEXT,
    ingredient_id      TEXT,
    supplier_id        TEXT,
    quantity           TEXT,
    unit_cost          TEXT,
    total_cost         TEXT,

    batch_id           TEXT        NOT NULL,
    source_file_name   TEXT        NOT NULL,
    loaded_at          TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.recipes (
    product_id         TEXT,
    ingredient_id      TEXT,
    quantity_per_unit  TEXT,

    batch_id           TEXT        NOT NULL,
    source_file_name   TEXT        NOT NULL,
    loaded_at          TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.suppliers (
    supplier_id        TEXT,
    supplier_name      TEXT,
    category           TEXT,
    city               TEXT,

    batch_id           TEXT        NOT NULL,
    source_file_name   TEXT        NOT NULL,
    loaded_at          TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.vouchers (
    voucher_id         TEXT,
    campaign_id        TEXT,
    voucher_code       TEXT,
    discount_type      TEXT,
    discount_value     TEXT,
    budget_limit       TEXT,
    min_order_value    TEXT,

    batch_id           TEXT        NOT NULL,
    source_file_name   TEXT        NOT NULL,
    loaded_at          TIMESTAMP   NOT NULL DEFAULT NOW()
);
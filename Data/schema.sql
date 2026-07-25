-- =====================================================================
-- Logistics & Supply Chain Analytics Dataset — Schema
-- 8 tables, fully normalized, with primary/foreign key constraints.
-- Compatible with PostgreSQL (minor tweaks needed for MySQL/SQL Server).
-- =====================================================================

DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS shipments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS carriers CASCADE;
DROP TABLE IF EXISTS warehouses CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- ---------------------------------------------------------------------
-- 1. customers
-- ---------------------------------------------------------------------
CREATE TABLE customers (
    customer_id     INTEGER PRIMARY KEY,
    customer_name   VARCHAR(150) NOT NULL,
    customer_type   VARCHAR(20) NOT NULL CHECK (customer_type IN ('Retail','Wholesale','Corporate')),
    city            VARCHAR(80) NOT NULL,
    state           VARCHAR(80) NOT NULL,
    country         VARCHAR(50) NOT NULL DEFAULT 'India',
    signup_date     DATE NOT NULL
);

-- ---------------------------------------------------------------------
-- 2. products
-- ---------------------------------------------------------------------
CREATE TABLE products (
    product_id      INTEGER PRIMARY KEY,
    product_name    VARCHAR(150) NOT NULL,
    category        VARCHAR(60) NOT NULL,
    weight_kg       NUMERIC(8,3) NOT NULL,
    unit_price      NUMERIC(12,2) NOT NULL
);

-- ---------------------------------------------------------------------
-- 3. warehouses
-- ---------------------------------------------------------------------
CREATE TABLE warehouses (
    warehouse_id      INTEGER PRIMARY KEY,
    warehouse_name    VARCHAR(150) NOT NULL,
    city              VARCHAR(80) NOT NULL,
    state             VARCHAR(80) NOT NULL,
    storage_capacity  INTEGER NOT NULL
);

-- ---------------------------------------------------------------------
-- 4. carriers
-- ---------------------------------------------------------------------
CREATE TABLE carriers (
    carrier_id      INTEGER PRIMARY KEY,
    carrier_name    VARCHAR(150) NOT NULL,
    transport_mode  VARCHAR(20) NOT NULL CHECK (transport_mode IN ('Road','Rail','Air','Sea')),
    rating          NUMERIC(2,1) NOT NULL CHECK (rating BETWEEN 1.0 AND 5.0)
);

-- ---------------------------------------------------------------------
-- 5. orders
-- ---------------------------------------------------------------------
CREATE TABLE orders (
    order_id                INTEGER PRIMARY KEY,
    customer_id             INTEGER NOT NULL REFERENCES customers(customer_id),
    warehouse_id            INTEGER NOT NULL REFERENCES warehouses(warehouse_id),
    order_date              DATE NOT NULL,
    expected_delivery_date  DATE NOT NULL,
    actual_delivery_date    DATE,                       -- NULL for Cancelled / In Transit / Processing orders
    order_status            VARCHAR(20) NOT NULL CHECK (order_status IN
                                ('Delivered','Cancelled','Returned','In Transit','Processing')),
    total_amount            NUMERIC(14,2) NOT NULL
);

-- ---------------------------------------------------------------------
-- 6. order_items
-- ---------------------------------------------------------------------
CREATE TABLE order_items (
    order_item_id   INTEGER PRIMARY KEY,
    order_id        INTEGER NOT NULL REFERENCES orders(order_id),
    product_id      INTEGER NOT NULL REFERENCES products(product_id),
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(12,2) NOT NULL,
    discount        NUMERIC(4,2) NOT NULL DEFAULT 0      -- fraction, e.g. 0.10 = 10%
);

-- ---------------------------------------------------------------------
-- 7. shipments
-- ---------------------------------------------------------------------
CREATE TABLE shipments (
    shipment_id     INTEGER PRIMARY KEY,
    order_id        INTEGER NOT NULL REFERENCES orders(order_id),   -- 1 shipment per non-cancelled order
    carrier_id      INTEGER NOT NULL REFERENCES carriers(carrier_id),
    shipment_date   DATE NOT NULL,
    delivery_status VARCHAR(20) NOT NULL CHECK (delivery_status IN
                        ('Delivered','Returned','In Transit','Pending')),
    shipping_cost   NUMERIC(12,2) NOT NULL,
    distance_km     NUMERIC(10,1) NOT NULL,
    fuel_cost       NUMERIC(12,2) NOT NULL,
    delay_days      INTEGER NOT NULL DEFAULT 0            -- 0 = on-time or not yet resolved
);

-- ---------------------------------------------------------------------
-- 8. inventory
-- ---------------------------------------------------------------------
CREATE TABLE inventory (
    inventory_id    INTEGER PRIMARY KEY,
    warehouse_id    INTEGER NOT NULL REFERENCES warehouses(warehouse_id),
    product_id      INTEGER NOT NULL REFERENCES products(product_id),
    stock_quantity  INTEGER NOT NULL,
    reorder_level   INTEGER NOT NULL,
    last_updated    DATE NOT NULL,
    UNIQUE (warehouse_id, product_id)
);

-- ---------------------------------------------------------------------
-- Helpful indexes for analytics queries
-- ---------------------------------------------------------------------
CREATE INDEX idx_orders_customer      ON orders(customer_id);
CREATE INDEX idx_orders_warehouse     ON orders(warehouse_id);
CREATE INDEX idx_orders_date          ON orders(order_date);
CREATE INDEX idx_orders_status        ON orders(order_status);
CREATE INDEX idx_order_items_order    ON order_items(order_id);
CREATE INDEX idx_order_items_product  ON order_items(product_id);
CREATE INDEX idx_shipments_order      ON shipments(order_id);
CREATE INDEX idx_shipments_carrier    ON shipments(carrier_id);
CREATE INDEX idx_inventory_warehouse  ON inventory(warehouse_id);
CREATE INDEX idx_inventory_product    ON inventory(product_id);

-- =====================================================================
-- Entity relationships
-- =====================================================================
-- customers  (1) ──< orders (M)             via orders.customer_id
-- warehouses (1) ──< orders (M)             via orders.warehouse_id
-- orders     (1) ──< order_items (M)        via order_items.order_id
-- products   (1) ──< order_items (M)        via order_items.product_id
-- orders     (1) ──< shipments (0..1)       via shipments.order_id  (cancelled orders have none)
-- carriers   (1) ──< shipments (M)          via shipments.carrier_id
-- warehouses (1) ──< inventory (M)          via inventory.warehouse_id
-- products   (1) ──< inventory (M)          via inventory.product_id
-- =====================================================================

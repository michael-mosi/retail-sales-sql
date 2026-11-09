-- ---------------------------------------------------------------------
-- customers: one row per customer
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
    customer_id        INTEGER       PRIMARY KEY,
    customer_name      VARCHAR(100)  NOT NULL,
    gender             VARCHAR(10)   CHECK (gender IN ('Male', 'Female')),
    city               VARCHAR(50),
    registration_date  DATE,
    customer_segment   VARCHAR(20)   CHECK (customer_segment IN ('Retail', 'Corporate', 'VIP'))
);

-- ---------------------------------------------------------------------
-- orders: one row per order, each belonging to exactly one customer
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders (
    order_id          INTEGER        PRIMARY KEY,
    customer_id       INTEGER        NOT NULL
                                     REFERENCES customers (customer_id),
    order_date        DATE           NOT NULL,
    product_name      VARCHAR(100),
    product_category  VARCHAR(50)    CHECK (product_category IN
                                     ('Electronics', 'Accessories', 'Home Appliances',
                                      'Computing', 'Mobile Phones')),
    quantity          INTEGER        CHECK (quantity > 0),
    unit_price        NUMERIC(12,2)  CHECK (unit_price >= 0),   -- KSh, before discount
    cost_price        NUMERIC(12,2)  CHECK (cost_price >= 0),   -- KSh per unit
    discount          NUMERIC(5,2)   DEFAULT 0
                                     CHECK (discount BETWEEN 0 AND 100),  -- percentage
    payment_method    VARCHAR(30)    CHECK (payment_method IN
                                     ('M-Pesa', 'Cash', 'Card', 'Bank Transfer')),
    order_status      VARCHAR(20)    CHECK (order_status IN
                                     ('Completed', 'Pending', 'Cancelled'))
);

-- ---------------------------------------------------------------------
-- Indexes on the columns the analysis joins and filters on most.
-- (Primary keys are indexed automatically; foreign keys are not.)
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders (customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_order_date  ON orders (order_date);
CREATE INDEX IF NOT EXISTS idx_orders_status      ON orders (order_status);
CREATE INDEX IF NOT EXISTS idx_orders_category    ON orders (product_category);

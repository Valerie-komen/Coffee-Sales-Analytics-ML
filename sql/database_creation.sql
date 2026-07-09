-- ============================================================
-- Coffee Sales Analytics — Database Creation
-- Target: SQLite (tested). Standard ANSI SQL; portable to
-- PostgreSQL/MySQL with minor type changes (e.g. TEXT -> VARCHAR).
-- ============================================================

DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;

-- Dimension: products (48 SKUs = 4 coffee types x 3 roasts x 4 sizes,
-- minus a few combinations not sold)
CREATE TABLE products (
    product_id      TEXT PRIMARY KEY,
    coffee_type     TEXT NOT NULL,      -- Ara, Exc, Lib, Rob
    roast_type      TEXT NOT NULL,      -- L, M, D
    size_kg         REAL NOT NULL,
    unit_price      REAL NOT NULL,
    price_per_100g  REAL,
    profit          REAL
);

-- Dimension: customers (PII already stripped upstream — see
-- notebooks/01_data_cleaning.ipynb — only the fields needed for
-- segmentation/CLV analysis are kept)
CREATE TABLE customers (
    customer_id     TEXT PRIMARY KEY,
    country         TEXT NOT NULL,
    loyalty_card    TEXT NOT NULL       -- 'Yes' / 'No'
);

-- Fact: orders (one row per order line, i.e. one product within one order)
CREATE TABLE orders (
    order_id        TEXT NOT NULL,
    order_date      DATE NOT NULL,
    customer_id     TEXT NOT NULL,
    product_id      TEXT NOT NULL,
    quantity        INTEGER NOT NULL,
    country         TEXT NOT NULL,
    coffee_type     TEXT NOT NULL,
    coffee_name     TEXT NOT NULL,
    roast_type      TEXT NOT NULL,
    roast_name      TEXT NOT NULL,
    size_kg         REAL NOT NULL,
    unit_price      REAL NOT NULL,
    sales           REAL NOT NULL,
    loyalty_card    TEXT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id)  REFERENCES products(product_id)
);

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date     ON orders(order_date);
CREATE INDEX idx_orders_product  ON orders(product_id);

-- ------------------------------------------------------------
-- Import (SQLite CLI, run from the sql/ directory):
--   sqlite3 ../data/coffee_sales.db
--   .mode csv
--   .import --skip 1 ../data/products_clean.csv products_staging
--   .import --skip 1 ../data/customers_clean.csv customers_staging
--   .import --skip 1 ../data/cleaned_data.csv orders_staging
--   -- then INSERT INTO ... SELECT ... FROM *_staging casting types as needed
-- The project's own database is built programmatically with the
-- equivalent logic in python (pandas.DataFrame.to_sql) — see the
-- reproducibility section of the README for the exact script.
-- ------------------------------------------------------------

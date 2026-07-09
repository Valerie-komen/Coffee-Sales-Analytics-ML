-- ============================================================
-- Coffee Sales Analytics — Data Cleaning / Validation Queries
-- Run after database_creation.sql + data import.
-- These mirror the checks performed in notebooks/01_data_cleaning.ipynb,
-- expressed in SQL.
-- ============================================================

-- 1. Missing values in any required column
SELECT
    SUM(CASE WHEN order_id     IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN order_date   IS NULL THEN 1 ELSE 0 END) AS null_order_date,
    SUM(CASE WHEN customer_id  IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN product_id   IS NULL THEN 1 ELSE 0 END) AS null_product_id,
    SUM(CASE WHEN sales        IS NULL THEN 1 ELSE 0 END) AS null_sales
FROM orders;

-- 2. Exact duplicate rows
SELECT COUNT(*) AS exact_duplicate_rows
FROM (
    SELECT order_id, product_id, quantity, sales, COUNT(*) AS c
    FROM orders
    GROUP BY order_id, product_id, quantity, sales
    HAVING COUNT(*) > 1
);

-- 3. Repeated (order_id, product_id) pairs with differing quantity/sales
--    (data-quality note, not necessarily an error — see notebook 01)
SELECT order_id, product_id, COUNT(*) AS line_count,
       GROUP_CONCAT(quantity) AS quantities,
       GROUP_CONCAT(sales)    AS sales_values
FROM orders
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;

-- 4. Referential integrity: orders pointing to a customer/product that
--    doesn't exist in the dimension tables
SELECT o.order_id, o.customer_id
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT o.order_id, o.product_id
FROM orders o
LEFT JOIN products p ON o.product_id = p.product_id
WHERE p.product_id IS NULL;

-- 5. Sales reconciliation: sales should equal quantity * unit_price
SELECT order_id, product_id, quantity, unit_price, sales,
       ROUND(quantity * unit_price, 2) AS expected_sales
FROM orders
WHERE ABS(sales - ROUND(quantity * unit_price, 2)) > 0.01;

-- 6. Valid categorical domains (catches typos/casing drift)
SELECT DISTINCT country      FROM orders ORDER BY 1;
SELECT DISTINCT coffee_type  FROM orders ORDER BY 1;
SELECT DISTINCT roast_type   FROM orders ORDER BY 1;
SELECT DISTINCT loyalty_card FROM orders ORDER BY 1;

-- 7. Date range sanity check
SELECT MIN(order_date) AS first_order, MAX(order_date) AS last_order
FROM orders;

-- ============================================================
-- Coffee Sales Analytics — Business Analysis Queries
-- Run after database_creation.sql + data import.
-- Results referenced in report/Technical_Report.pdf (Section 5, EDA)
-- and notebooks/02_exploratory_analysis.ipynb.
-- ============================================================

-- 1. Revenue by coffee type
SELECT coffee_name AS coffee_type,
       ROUND(SUM(sales), 2) AS total_revenue,
       COUNT(*) AS line_items
FROM orders
GROUP BY coffee_name
ORDER BY total_revenue DESC;

-- 2. Revenue AND profit margin by coffee type (join to products for cost)
SELECT o.coffee_name AS coffee_type,
       ROUND(SUM(o.sales), 2) AS total_revenue,
       ROUND(SUM(p.profit * o.quantity), 2) AS total_profit,
       ROUND(100.0 * SUM(p.profit * o.quantity) / SUM(o.sales), 1) AS margin_pct
FROM orders o
JOIN products p 
       ON o.product_id = p.product_id
GROUP BY o.coffee_name
ORDER BY margin_pct DESC;

-- 3. Monthly sales trend
SELECT strftime('%Y-%m', order_date) AS year_month,
       ROUND(SUM(sales), 2) AS monthly_revenue
FROM orders
GROUP BY year_month
ORDER BY year_month;

-- 4. Revenue by country, with each country's share of total revenue
--    (window function: SUM(...) OVER () for the grand total)
SELECT country,
       ROUND(SUM(sales), 2) AS revenue,
       ROUND(100.0 * SUM(sales) / SUM(SUM(sales)) OVER (), 1) AS pct_of_total
FROM orders
GROUP BY country
ORDER BY revenue DESC;

-- 5. Top-5 customers by lifetime spend (ranking with window function)
SELECT customer_id,
       ROUND(SUM(sales), 2) AS lifetime_spend,
       RANK() OVER (ORDER BY SUM(sales) DESC) AS spend_rank
FROM orders
GROUP BY customer_id
ORDER BY spend_rank
LIMIT 5;

-- 6. Customer lifetime value (CLV) components: order count, avg order
--    value, total spend, first/last order date, tenure in days
SELECT o.customer_id,
       c.country,
       c.loyalty_card,
       COUNT(DISTINCT o.order_id) AS n_orders,
       ROUND(SUM(o.sales), 2) AS total_spend,
       ROUND(AVG(o.sales), 2) AS avg_line_value,
       MIN(o.order_date) AS first_order,
       MAX(o.order_date) AS last_order,
       JULIANDAY(MAX(o.order_date)) - JULIANDAY(MIN(o.order_date)) AS tenure_days
FROM orders o
JOIN customers c 
       ON o.customer_id = c.customer_id
GROUP BY o.customer_id, c.country, c.loyalty_card
ORDER BY total_spend DESC
LIMIT 10;

-- 7. Repeat-purchase rate (the class-imbalance finding driving the ML
--    section's scoping decision)
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN n_orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(100.0 * SUM(CASE WHEN n_orders > 1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS repeat_rate_pct
FROM (
    SELECT customer_id, COUNT(DISTINCT order_id) AS n_orders
    FROM orders
    GROUP BY customer_id
);

-- 8. Does loyalty membership correlate with average order value?
SELECT loyalty_card,
       COUNT(DISTINCT customer_id) AS n_customers,
       ROUND(AVG(sales), 2) AS avg_line_value,
       ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM orders
GROUP BY loyalty_card;

-- 9. Best-selling size tier by revenue share
SELECT size_kg,
       ROUND(SUM(sales), 2) AS revenue,
       ROUND(100.0 * SUM(sales) / SUM(SUM(sales)) OVER (), 1) AS pct_of_total
FROM orders
GROUP BY size_kg
ORDER BY revenue DESC;

-- 10. Running 12-month total revenue (window function: moving frame)
--     Useful for spotting the growth deceleration discussed in the report.
SELECT year_month,
       monthly_revenue,
       ROUND(SUM(monthly_revenue) OVER (
           ORDER BY year_month
           ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
       ), 2) AS trailing_12mo_revenue
FROM (
    SELECT strftime('%Y-%m', order_date) AS year_month,
           SUM(sales) AS monthly_revenue
    FROM orders
    GROUP BY year_month
)
ORDER BY year_month;

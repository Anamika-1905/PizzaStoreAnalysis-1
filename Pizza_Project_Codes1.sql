/* ============================================================
   🍕 PIZZA STORE ANALYTICS — PostgreSQL 18
   Author: Anamika Pandey
   Description: Key insights and KPIs for pizza sales
   ============================================================ */

1. =============Create Database Pizza_store;=============

2. =============CREATE TABLE order_details=============
(
    order_details_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    pizza_id VARCHAR(50) NOT NULL,
    quantity INT CHECK (quantity > 0)
);

3. =============CREATE TABLE pizza_types=============
(
    pizza_type_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    ingredients TEXT
);


4. =============CREATE TABLE Pizza=============
(
    pizza_id VARCHAR(50) PRIMARY KEY,
    pizza_type_id VARCHAR(50) NOT NULL,
    size VARCHAR(10) NOT NULL,
    price DECIMAL(6,2) Not Null

);

5. =============Data Upload=============

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    order_date DATE NOT NULL,
    order_time TIME NOT NULL
);

6. =============Data Upload=============

copy orders(order_id, order_date, order_time)
FROM 'D:/Mysql/Sql_Project/sqlprojectpizzasalesanalysis/orders.csv'
DELIMITER ','
CSV HEADER;

7. =============Data Upload=============

copy order_details
FROM 'D:/Mysql/Sql_Project/sqlprojectpizzasalesanalysis/order_details.csv'
DELIMITER ','
CSV HEADER;

8. =============Data Upload=============

COPY pizza_types
FROM 'D:/Mysql/Sql_Project/sqlprojectpizzasalesanalysis/pizza_types.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'WIN1252');

9. =============Data Upload=============
COPY pizza
FROM 'D:/Mysql/Sql_Project/sqlprojectpizzasalesanalysis/pizzas.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'WIN1252');

/* === 1. highest number of orders by the day. ====================== */

SELECT 
    pt.name AS pizza_type,
    ROUND(SUM(od.quantity * p.price), 2) AS total_revenue
FROM 
    order_details od
JOIN 
    pizza p ON od.pizza_id = p.pizza_id
JOIN 
    pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY 
    pt.name
ORDER BY 
    total_revenue DESC;

/* === 2. highest number of orders by the day. ====================== */

SELECT
  CASE
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 6  AND 11 THEN 'Morning'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 AND 17 THEN 'Afternoon'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 18 AND 22 THEN 'Evening'
    ELSE 'Night'
  END AS time_of_day,
  COUNT(*) AS total_orders
FROM orders
GROUP BY time_of_day
ORDER BY total_orders DESC
LIMIT 1;

/* === 3. Check column Name. ====================== */

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'orders'
ORDER BY ordinal_position;

/* === 4. Top-Selling Pizzas and sizes ====================== */
SELECT 
    pt.name AS pizza_name,
    p.size AS pizza_size,
    SUM(od.quantity) AS total_quantity_sold
FROM 
    order_details od
JOIN 
    pizza p ON od.pizza_id = p.pizza_id
JOIN 
    pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY 
    pt.name, p.size
ORDER BY 
    total_quantity_sold DESC
LIMIT 10;



/* === 5. SALES TRENDS OVER TIME (DAILY) ====================== */
CREATE OR REPLACE VIEW v_daily_sales AS
SELECT
  o.order_date,
  COUNT(DISTINCT o.order_id) AS orders_count,
  SUM(od.quantity * p.price) AS revenue
FROM orders o
JOIN order_details od ON od.order_id = o.order_id
JOIN pizza p ON p.pizza_id = od.pizza_id
GROUP BY o.order_date
ORDER BY o.order_date;


/* === 2. SALES TRENDS OVER TIME (MONTHLY) ==================== */
CREATE OR REPLACE VIEW v_monthly_sales AS
SELECT
  DATE_TRUNC('month', o.order_date)::date AS month,
  COUNT(DISTINCT o.order_id) AS orders_count,
  SUM(od.quantity * p.price) AS revenue
FROM orders o
JOIN order_details od ON od.order_id = o.order_id
JOIN pizza p ON p.pizza_id = od.pizza_id
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY month;


/* === 3. TOTAL NUMBER OF ORDERS PLACED ======================= */
CREATE OR REPLACE VIEW v_total_orders AS
SELECT COUNT(*) AS total_orders
FROM orders;


/* === 4. TOTAL REVENUE GENERATED ============================= */
CREATE OR REPLACE VIEW v_total_revenue AS
SELECT SUM(od.quantity * p.price) AS total_revenue
FROM order_details od
JOIN pizza p ON p.pizza_id = od.pizza_id;


/* === 5. HIGHEST-PRICED PIZZA ================================ */
CREATE OR REPLACE VIEW v_highest_priced_pizza AS
SELECT pt.name AS pizza_name, p.size, p.price
FROM pizza p
JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
ORDER BY p.price DESC
LIMIT 1;


/* === 6. MOST COMMONLY ORDERED PIZZA SIZE ==================== */
CREATE OR REPLACE VIEW v_most_common_size AS
SELECT p.size, SUM(od.quantity) AS total_qty
FROM order_details od
JOIN pizza p ON p.pizza_id = od.pizza_id
GROUP BY p.size
ORDER BY total_qty DESC
LIMIT 1;


/* === 7. TOP 5 PIZZA TYPES BY QUANTITY ======================= */
CREATE OR REPLACE VIEW v_top5_pizza_by_qty AS
SELECT pt.name AS pizza_type, SUM(od.quantity) AS total_qty
FROM order_details od
JOIN pizza p ON p.pizza_id = od.pizza_id
JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY pt.name
ORDER BY total_qty DESC
LIMIT 5;


/* === 8. TOTAL QUANTITY OF EACH PIZZA CATEGORY =============== */
CREATE OR REPLACE VIEW v_category_qty AS
SELECT pt.category, SUM(od.quantity) AS total_qty
FROM order_details od
JOIN pizza p ON p.pizza_id = od.pizza_id
JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY pt.category
ORDER BY total_qty DESC;


/* === 9. DISTRIBUTION OF ORDERS BY HOUR ====================== */
CREATE OR REPLACE VIEW v_orders_by_hour AS
SELECT EXTRACT(HOUR FROM order_time) AS hour_24,
       COUNT(*) AS orders_count
FROM orders
GROUP BY hour_24
ORDER BY hour_24;


/* === 10. CATEGORY-WISE PIZZA DISTRIBUTION =================== */
CREATE OR REPLACE VIEW v_category_distribution AS
SELECT pt.category, COUNT(*) AS num_items
FROM pizza p
JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY pt.category
ORDER BY num_items DESC;


/* === 11. DAILY AVERAGE PIZZAS ORDERED ======================= */
CREATE OR REPLACE VIEW v_avg_pizzas_per_day AS
WITH daily AS (
  SELECT o.order_date, SUM(od.quantity) AS qty
  FROM orders o
  JOIN order_details od ON od.order_id = o.order_id
  GROUP BY o.order_date
)
SELECT ROUND(AVG(qty), 2) AS avg_pizzas_per_day
FROM daily;


/* === 12. TOP 3 PIZZA TYPES BY REVENUE ======================= */
CREATE OR REPLACE VIEW v_top3_pizza_by_revenue AS
SELECT pt.name AS pizza_type,
       SUM(od.quantity * p.price) AS revenue
FROM order_details od
JOIN pizza p ON p.pizza_id = od.pizza_id
JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY pt.name
ORDER BY revenue DESC
LIMIT 3;


/* === 13. REVENUE % CONTRIBUTION OF EACH PIZZA TYPE ========== */
CREATE OR REPLACE VIEW v_pizza_revenue_share AS
WITH rev AS (
  SELECT pt.name AS pizza_type,
         SUM(od.quantity * p.price) AS revenue
  FROM order_details od
  JOIN pizza p ON p.pizza_id = od.pizza_id
  JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
  GROUP BY pt.name
),
tot AS (
  SELECT SUM(revenue) AS total_revenue FROM rev
)
SELECT r.pizza_type,
       r.revenue,
       ROUND(r.revenue / t.total_revenue * 100, 2) AS pct_of_total
FROM rev r CROSS JOIN tot t
ORDER BY pct_of_total DESC;


/* === 14. CUMULATIVE REVENUE OVER TIME ======================= */
CREATE MATERIALIZED VIEW mv_cumulative_revenue AS
WITH daily AS (
  SELECT o.order_date,
         SUM(od.quantity * p.price) AS revenue
  FROM orders o
  JOIN order_details od ON od.order_id = o.order_id
  JOIN pizza p ON p.pizza_id = od.pizza_id
  GROUP BY o.order_date
)
SELECT
  order_date,
  revenue,
  SUM(revenue) OVER (ORDER BY order_date) AS cumulative_revenue
FROM daily
ORDER BY order_date;


/* === 15. TOP 3 PIZZAS BY REVENUE IN EACH CATEGORY =========== */
CREATE OR REPLACE VIEW v_top3_pizza_by_category AS
WITH by_cat AS (
  SELECT
    pt.category,
    pt.name AS pizza_type,
    SUM(od.quantity * p.price) AS revenue
  FROM order_details od
  JOIN pizza p ON p.pizza_id = od.pizza_id
  JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
  GROUP BY pt.category, pt.name
),
ranked AS (
  SELECT *,
         DENSE_RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rnk
  FROM by_cat
)
SELECT category, pizza_type, revenue
FROM ranked
WHERE rnk <= 3
ORDER BY category, revenue DESC;

-- =============================================================
-- END OF FILE
-- To refresh materialized view: REFRESH MATERIALIZED VIEW mv_cumulative_revenue;
-- =============================================================

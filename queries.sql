-- =====================================================================
-- SECTION A  SQL fundamentals (Q1,Q10)
-- =====================================================================

-- Q1: Retrieve all customer records
SELECT *
FROM customers
ORDER BY customer_id;

-- Q2: Display customer names, cities, and segments
SELECT customer_name, city, customer_segment
FROM customers
ORDER BY customer_name;

-- Q3: Find customers living in Nairobi
SELECT *
FROM customers
WHERE city = 'Nairobi'
ORDER BY customer_name;

-- Q4: Find customers registered after January 1, 2025
--     ("after" = strictly later than 2025-01-01)
SELECT *
FROM customers
WHERE registration_date > DATE '2025-01-01'
ORDER BY registration_date;

-- Q5: Display all unique customer cities
SELECT DISTINCT city
FROM customers
ORDER BY city;

-- Q6: Retrieve the 10 most recent orders
--     (order_id breaks ties between orders on the same date)
SELECT *
FROM orders
ORDER BY order_date DESC, order_id DESC
LIMIT 10;

-- Q7: Find orders with unit prices above KSh 10,000
SELECT *
FROM orders
WHERE unit_price > 10000
ORDER BY unit_price DESC;

-- Q8: Find customers whose names start with A
SELECT *
FROM customers
WHERE customer_name LIKE 'A%'
ORDER BY customer_name;

-- Q9: Retrieve orders with quantities between 2 and 5 (inclusive)
SELECT *
FROM orders
WHERE quantity BETWEEN 2 AND 5
ORDER BY quantity, order_id;

-- Q10: Find orders paid through M-Pesa
SELECT *
FROM orders
WHERE payment_method = 'M-Pesa'
ORDER BY order_date;


-- =====================================================================
-- SECTION B  Aggregation and grouping (Q11,Q20)
-- =====================================================================

-- Q11: Count all customers
SELECT COUNT(*) AS total_customers
FROM customers;

-- Q12: Count all orders (every status | business rule 2)
SELECT COUNT(*) AS total_orders
FROM orders;

-- Q13: Calculate completed-order revenue
SELECT ROUND(SUM(quantity * unit_price * (1 - discount / 100)), 2) AS completed_revenue
FROM orders
WHERE order_status = 'Completed';

-- Q14: Calculate the average completed-order value
--      (mean revenue per Completed order)
SELECT ROUND(AVG(quantity * unit_price * (1 - discount / 100)), 2) AS avg_completed_order_value
FROM orders
WHERE order_status = 'Completed';

-- Q15: Find the highest and lowest product prices
--      (list unit_price, across all orders, before discount)
SELECT MAX(unit_price) AS highest_unit_price,
       MIN(unit_price) AS lowest_unit_price
FROM orders;

-- Q16: Calculate revenue by product category (Completed orders)
SELECT product_category,
       ROUND(SUM(quantity * unit_price * (1 - discount / 100)), 2) AS revenue
FROM orders
WHERE order_status = 'Completed'
GROUP BY product_category
ORDER BY revenue DESC;

-- Q17: Count customers by city
SELECT city,
       COUNT(DISTINCT customer_id) AS customers
FROM customers
GROUP BY city
ORDER BY customers DESC, city;

-- Q18: Calculate quantity sold by product
--      "Sold" = units on Completed orders (pending/cancelled units were not sold)
SELECT product_name,
       product_category,
       SUM(quantity) AS units_sold
FROM orders
WHERE order_status = 'Completed'
GROUP BY product_name, product_category
ORDER BY units_sold DESC, product_name;

-- Q19: Find categories generating more than KSh 100,000 in revenue
SELECT product_category,
       ROUND(SUM(quantity * unit_price * (1 - discount / 100)), 2) AS revenue
FROM orders
WHERE order_status = 'Completed'
GROUP BY product_category
HAVING SUM(quantity * unit_price * (1 - discount / 100)) > 100000
ORDER BY revenue DESC;

-- Q20: Calculate the percentage of cancelled orders (out of all orders)
SELECT COUNT(*) FILTER (WHERE order_status = 'Cancelled')               AS cancelled_orders,
       COUNT(*)                                                         AS total_orders,
       ROUND(100.0 * COUNT(*) FILTER (WHERE order_status = 'Cancelled')
             / NULLIF(COUNT(*), 0), 2)                                  AS cancelled_pct
FROM orders;


-- =====================================================================
-- SECTION C  Joins and customer analytics (Q21, Q28)
-- =====================================================================

-- Q21: Display orders with customer names and cities
SELECT o.order_id,
       o.order_date,
       c.customer_name,
       c.city,
       o.product_name,
       o.quantity,
       o.order_status
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
ORDER BY o.order_date, o.order_id;

-- Q22: Calculate total spending by customer
--      Spending = Completed-order revenue. Customers who placed orders but
--      have none Completed show 0 (FILTER + COALESCE keeps them in the list).
SELECT c.customer_id,
       c.customer_name,
       ROUND(COALESCE(SUM(o.quantity * o.unit_price * (1 - o.discount / 100))
                      FILTER (WHERE o.order_status = 'Completed'), 0), 2) AS total_spending
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spending DESC;

-- Q23: Identify customers who have never ordered (LEFT JOIN anti-join)
SELECT c.*
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;

-- Q24: Find the 10 highest-spending customers (Completed revenue)
SELECT c.customer_id,
       c.customer_name,
       c.city,
       c.customer_segment,
       ROUND(SUM(o.quantity * o.unit_price * (1 - o.discount / 100)), 2) AS total_spending
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, c.customer_name, c.city, c.customer_segment
ORDER BY total_spending DESC
LIMIT 10;

-- Q25: Calculate revenue by customer city (Completed revenue)
SELECT c.city,
       COUNT(DISTINCT c.customer_id)                                     AS paying_customers,
       ROUND(SUM(o.quantity * o.unit_price * (1 - o.discount / 100)), 2) AS revenue
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.city
ORDER BY revenue DESC;

-- Q26: Identify customers with more than five orders (all statuses)
SELECT c.customer_id,
       c.customer_name,
       COUNT(o.order_id) AS order_count
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(o.order_id) > 5
ORDER BY order_count DESC, c.customer_name;

-- Q27: Calculate average customer spending by segment
--      Definition: step 1 = each customer's total Completed revenue;
--      step 2 = average of those totals within each segment.
--      Only customers with at least one Completed order are averaged
--      (customers who never bought are excluded, not counted as 0).
WITH customer_totals AS (
    SELECT c.customer_id,
           c.customer_segment,
           SUM(o.quantity * o.unit_price * (1 - o.discount / 100)) AS total_spending
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id, c.customer_segment
)
SELECT customer_segment,
       COUNT(*)                        AS paying_customers,
       ROUND(AVG(total_spending), 2)   AS avg_spending_per_customer,
       ROUND(SUM(total_spending), 2)   AS segment_revenue
FROM customer_totals
GROUP BY customer_segment
ORDER BY avg_spending_per_customer DESC;

-- Q28: Identify the most popular category among VIP customers
--      "Popular" = most ORDERS placed (all statuses — it measures demand,
--      not money). Units and Completed revenue are shown alongside for
--      context; RANK() keeps ties.
WITH vip_categories AS (
    SELECT o.product_category,
           COUNT(*)                                                          AS orders,
           SUM(o.quantity)                                                   AS units,
           ROUND(SUM(o.quantity * o.unit_price * (1 - o.discount / 100))
                 FILTER (WHERE o.order_status = 'Completed'), 2)             AS completed_revenue
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE c.customer_segment = 'VIP'
    GROUP BY o.product_category
)
SELECT *
FROM (SELECT vc.*, RANK() OVER (ORDER BY orders DESC) AS popularity_rank
      FROM vip_categories vc) ranked
WHERE popularity_rank = 1;


-- =====================================================================
-- SECTION D  Subqueries and CTEs (Q29,Q34)
-- =====================================================================

-- Q29: Find customers spending above the average total spending
--      per purchasing customer (purchasing = has >= 1 Completed order)
WITH customer_spend AS (
    SELECT customer_id,
           SUM(quantity * unit_price * (1 - discount / 100)) AS total_spending
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY customer_id
)
SELECT c.customer_id,
       c.customer_name,
       c.customer_segment,
       ROUND(cs.total_spending, 2)                                 AS total_spending,
       ROUND((SELECT AVG(total_spending) FROM customer_spend), 2)  AS avg_per_purchasing_customer
FROM customer_spend cs
JOIN customers c ON c.customer_id = cs.customer_id
WHERE cs.total_spending > (SELECT AVG(total_spending) FROM customer_spend)
ORDER BY cs.total_spending DESC;

-- Q30: Find products priced above the overall average unit price
--      Each product's average unit_price vs. the average unit_price of
--      all order lines (subquery).
SELECT product_name,
       product_category,
       ROUND(AVG(unit_price), 2)                         AS avg_unit_price,
       (SELECT ROUND(AVG(unit_price), 2) FROM orders)    AS overall_avg_unit_price
FROM orders
GROUP BY product_name, product_category
HAVING AVG(unit_price) > (SELECT AVG(unit_price) FROM orders)
ORDER BY avg_unit_price DESC;

-- Q31: Use a CTE to identify the three highest-revenue months
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::DATE                AS month,
           SUM(quantity * unit_price * (1 - discount / 100))    AS revenue
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY 1
)
SELECT TO_CHAR(month, 'YYYY-MM') AS month,
       ROUND(revenue, 2)         AS revenue
FROM monthly
ORDER BY revenue DESC
LIMIT 3;

-- Q32: Find customers purchasing from at least three categories
--      "Purchasing" = Completed orders only.
SELECT c.customer_id,
       c.customer_name,
       COUNT(DISTINCT o.product_category)                              AS categories_bought,
       STRING_AGG(DISTINCT o.product_category, ', ')                   AS categories
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(DISTINCT o.product_category) >= 3
ORDER BY categories_bought DESC, c.customer_name;

-- Q33: Use a CTE to calculate category revenue, cost, profit, and profit margin
WITH category_totals AS (
    SELECT product_category,
           SUM(quantity * unit_price * (1 - discount / 100)) AS revenue,
           SUM(quantity * cost_price)                        AS cost
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY product_category
)
SELECT product_category,
       ROUND(revenue, 2)                                         AS revenue,
       ROUND(cost, 2)                                            AS cost,
       ROUND(revenue - cost, 2)                                  AS profit,
       ROUND((revenue - cost) / NULLIF(revenue, 0) * 100, 2)     AS profit_margin_pct
FROM category_totals
ORDER BY profit DESC;

-- Q34: Find customers whose latest completed order is more than 90 days
--      before the latest order date in the dataset ("today" = MAX(order_date))
WITH last_completed AS (
    SELECT customer_id,
           MAX(order_date) AS last_completed_order
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY customer_id
),
today AS (
    SELECT MAX(order_date) AS as_of FROM orders
)
SELECT c.customer_id,
       c.customer_name,
       c.customer_segment,
       c.city,
       lc.last_completed_order,
       t.as_of - lc.last_completed_order AS days_since_last_completed
FROM last_completed lc
JOIN customers c ON c.customer_id = lc.customer_id
CROSS JOIN today t
WHERE t.as_of - lc.last_completed_order > 90
ORDER BY days_since_last_completed DESC;


-- =====================================================================
-- SECTION E  Window functions (Q35,Q42)
-- =====================================================================

-- Q35: Rank customers by spending using RANK()
--      (Completed revenue; ties share a rank and leave a gap)
SELECT c.customer_id,
       c.customer_name,
       ROUND(SUM(o.quantity * o.unit_price * (1 - o.discount / 100)), 2)            AS total_spending,
       RANK() OVER (ORDER BY SUM(o.quantity * o.unit_price * (1 - o.discount / 100)) DESC) AS spending_rank
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, c.customer_name
ORDER BY spending_rank;

-- Q36: Number each customer's orders by recency using ROW_NUMBER()
--      (1 = most recent; order_id breaks same-day ties; all statuses)
SELECT o.customer_id,
       c.customer_name,
       o.order_id,
       o.order_date,
       o.order_status,
       ROW_NUMBER() OVER (PARTITION BY o.customer_id
                          ORDER BY o.order_date DESC, o.order_id DESC) AS recency_number
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
ORDER BY o.customer_id, recency_number;

-- Q37: Rank products within categories using DENSE_RANK()
--      (by Completed revenue within each category)
WITH product_revenue AS (
    SELECT product_category,
           product_name,
           SUM(quantity * unit_price * (1 - discount / 100)) AS revenue
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY product_category, product_name
)
SELECT product_category,
       product_name,
       ROUND(revenue, 2) AS revenue,
       DENSE_RANK() OVER (PARTITION BY product_category ORDER BY revenue DESC) AS rank_in_category
FROM product_revenue
ORDER BY product_category, rank_in_category;

-- Q38: Calculate cumulative monthly revenue
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::DATE             AS month,
           SUM(quantity * unit_price * (1 - discount / 100)) AS revenue
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY 1
)
SELECT TO_CHAR(month, 'YYYY-MM')                    AS month,
       ROUND(revenue, 2)                            AS revenue,
       ROUND(SUM(revenue) OVER (ORDER BY month), 2) AS cumulative_revenue
FROM monthly
ORDER BY month;

-- Q39: Compare monthly revenue using LAG()
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::DATE             AS month,
           SUM(quantity * unit_price * (1 - discount / 100)) AS revenue
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY 1
)
SELECT TO_CHAR(month, 'YYYY-MM')                              AS month,
       ROUND(revenue, 2)                                      AS revenue,
       ROUND(LAG(revenue) OVER (ORDER BY month), 2)           AS previous_month_revenue,
       ROUND(revenue - LAG(revenue) OVER (ORDER BY month), 2) AS change_vs_previous
FROM monthly
ORDER BY month;

-- Q40: Calculate month-over-month revenue growth (%)
--      First month has no previous month, so growth is NULL.
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::DATE             AS month,
           SUM(quantity * unit_price * (1 - discount / 100)) AS revenue
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY 1
),
with_prev AS (
    SELECT month, revenue,
           LAG(revenue) OVER (ORDER BY month) AS prev_revenue
    FROM monthly
)
SELECT TO_CHAR(month, 'YYYY-MM')                                        AS month,
       ROUND(revenue, 2)                                                AS revenue,
       ROUND(prev_revenue, 2)                                           AS previous_month_revenue,
       ROUND((revenue - prev_revenue) / NULLIF(prev_revenue, 0) * 100, 2) AS mom_growth_pct
FROM with_prev
ORDER BY month;

-- Q41: Divide customers into four spending groups using NTILE(4)
--      Group 1 = top 25% of purchasing customers by Completed revenue.
WITH customer_spend AS (
    SELECT c.customer_id,
           c.customer_name,
           SUM(o.quantity * o.unit_price * (1 - o.discount / 100)) AS total_spending
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id, c.customer_name
)
SELECT customer_id,
       customer_name,
       ROUND(total_spending, 2)                           AS total_spending,
       NTILE(4) OVER (ORDER BY total_spending DESC)       AS spending_quartile
FROM customer_spend
ORDER BY spending_quartile, total_spending DESC;

-- Q42: Calculate each category's share of total revenue using window functions
SELECT product_category,
       ROUND(SUM(quantity * unit_price * (1 - discount / 100)), 2)               AS revenue,
       ROUND(SUM(SUM(quantity * unit_price * (1 - discount / 100))) OVER (), 2)  AS total_revenue,
       ROUND(100 * SUM(quantity * unit_price * (1 - discount / 100))
             / SUM(SUM(quantity * unit_price * (1 - discount / 100))) OVER (), 2) AS revenue_share_pct
FROM orders
WHERE order_status = 'Completed'
GROUP BY product_category
ORDER BY revenue_share_pct DESC;


-- =====================================================================
-- SECTION F Advanced business intelligence (Q43,Q46)
-- =====================================================================

-- Q43: Create a monthly_sales_summary view (month, orders, revenue, cost, profit)
--      orders  = ALL orders placed in the month (rule 2)
--      revenue/cost/profit = Completed orders only (rule 1)
CREATE OR REPLACE VIEW monthly_sales_summary AS
SELECT DATE_TRUNC('month', order_date)::DATE AS month,
       COUNT(*)                              AS orders,
       COUNT(*) FILTER (WHERE order_status = 'Completed') AS completed_orders,
       ROUND(COALESCE(SUM(quantity * unit_price * (1 - discount / 100))
             FILTER (WHERE order_status = 'Completed'), 0), 2) AS revenue,
       ROUND(COALESCE(SUM(quantity * cost_price)
             FILTER (WHERE order_status = 'Completed'), 0), 2) AS cost,
       ROUND(COALESCE(SUM(quantity * unit_price * (1 - discount / 100) - quantity * cost_price)
             FILTER (WHERE order_status = 'Completed'), 0), 2) AS profit
FROM orders
GROUP BY 1;

SELECT TO_CHAR(month, 'YYYY-MM') AS month, orders, completed_orders, revenue, cost, profit
FROM monthly_sales_summary
ORDER BY month;

-- Q44: Function returning Completed-order revenue for a supplied customer ID.
--      COALESCE turns "no rows" into 0, so unknown IDs return 0, not NULL.
CREATE OR REPLACE FUNCTION get_customer_revenue(p_customer_id INTEGER)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_revenue NUMERIC;
BEGIN
    SELECT COALESCE(SUM(quantity * unit_price * (1 - discount / 100)), 0)
    INTO   v_revenue
    FROM   orders
    WHERE  customer_id  = p_customer_id
      AND  order_status = 'Completed';

    RETURN ROUND(v_revenue, 2);
END;
$$;

-- Working for an existing customer (the top spender) 
SELECT customer_id, get_customer_revenue(customer_id) AS revenue
FROM orders
WHERE order_status = 'Completed'
GROUP BY customer_id
ORDER BY revenue DESC
LIMIT 1;

-- and for an ID that does not exist (returns 0)
SELECT 999999 AS customer_id, get_customer_revenue(999999) AS revenue;

-- Q45: Segment customers into High, Medium and Low Value
--      Thresholds WHY: spending in retail is heavily skewed (a few large
--      laptop/TV buyers dominate), so fixed KSh cut-offs chosen in advance
--      would be arbitrary and would go stale as prices change. Instead the
--      bands are percentiles of THIS data, recomputed every run:
--        High   = top 20% of purchasing customers (>= 80th percentile)
--                 the classic 80/20 group that drives most revenue
--        Medium = 40th 80th percentile  steady buyers worth growing
--        Low    = bottom 40% (< 40th percentile)
--        No Purchase = registered but no Completed order (shown separately,
--                 so they do not drag the percentiles down)
--      The actual KSh cut-off values are returned in the output so managers
--      see the thresholds as round numbers they can act on.
WITH customer_spend AS (
    SELECT c.customer_id,
           c.customer_name,
           c.customer_segment,
           COALESCE(SUM(o.quantity * o.unit_price * (1 - o.discount / 100))
                    FILTER (WHERE o.order_status = 'Completed'), 0) AS total_spending
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.customer_name, c.customer_segment
),
thresholds AS (
    SELECT PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY total_spending) AS p80,
           PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY total_spending) AS p40
    FROM customer_spend
    WHERE total_spending > 0
),
banded AS (
    SELECT cs.*,
           CASE
               WHEN cs.total_spending = 0      THEN 'No Purchase'
               WHEN cs.total_spending >= t.p80 THEN 'High Value'
               WHEN cs.total_spending >= t.p40 THEN 'Medium Value'
               ELSE 'Low Value'
           END AS value_band,
           ROUND(t.p80::NUMERIC, 2) AS high_threshold,
           ROUND(t.p40::NUMERIC, 2) AS medium_threshold
    FROM customer_spend cs
    CROSS JOIN thresholds t
)
-- Detail: every customer with their band
SELECT customer_id, customer_name, customer_segment,
       ROUND(total_spending, 2) AS total_spending, value_band
FROM banded
ORDER BY total_spending DESC;

-- Q45 (summary): band sizes, revenue share and the KSh thresholds used
WITH customer_spend AS (
    SELECT c.customer_id,
           COALESCE(SUM(o.quantity * o.unit_price * (1 - o.discount / 100))
                    FILTER (WHERE o.order_status = 'Completed'), 0) AS total_spending
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.customer_id
    GROUP BY c.customer_id
),
thresholds AS (
    SELECT PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY total_spending) AS p80,
           PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY total_spending) AS p40
    FROM customer_spend
    WHERE total_spending > 0
),
banded AS (
    SELECT cs.total_spending,
           CASE
               WHEN cs.total_spending = 0      THEN 'No Purchase'
               WHEN cs.total_spending >= t.p80 THEN 'High Value'
               WHEN cs.total_spending >= t.p40 THEN 'Medium Value'
               ELSE 'Low Value'
           END AS value_band
    FROM customer_spend cs CROSS JOIN thresholds t
)
SELECT b.value_band,
       COUNT(*)                                                          AS customers,
       ROUND(SUM(b.total_spending), 2)                                   AS revenue,
       ROUND(100 * SUM(b.total_spending) / SUM(SUM(b.total_spending)) OVER (), 2) AS revenue_share_pct,
       ROUND(MIN(t.p80)::NUMERIC, 2)                                     AS high_threshold_ksh,
       ROUND(MIN(t.p40)::NUMERIC, 2)                                     AS medium_threshold_ksh
FROM banded b CROSS JOIN thresholds t
GROUP BY b.value_band
ORDER BY revenue DESC;

-- Q46: Management report top 5 customers, top 5 products,
--      most profitable category, lowest-revenue month.
--      One result set; "rank" orders rows inside each section.
--      (Completed orders only for all money figures.)
WITH completed AS (
    SELECT o.*,
           o.quantity * o.unit_price * (1 - o.discount / 100) AS revenue,
           o.quantity * o.cost_price                          AS cost
    FROM orders o
    WHERE o.order_status = 'Completed'
),
top_customers AS (
    SELECT '1. Top 5 customers (revenue)'::TEXT AS section,
           ROW_NUMBER() OVER (ORDER BY SUM(cp.revenue) DESC) AS rank,
           c.customer_name || ' (' || c.city || ', ' || c.customer_segment || ')' AS item,
           ROUND(SUM(cp.revenue), 2) AS value_ksh
    FROM completed cp JOIN customers c ON c.customer_id = cp.customer_id
    GROUP BY c.customer_id, c.customer_name, c.city, c.customer_segment
    ORDER BY rank LIMIT 5
),
top_products AS (
    SELECT '2. Top 5 products (revenue)'::TEXT,
           ROW_NUMBER() OVER (ORDER BY SUM(revenue) DESC),
           product_name || ' (' || product_category || ')',
           ROUND(SUM(revenue), 2)
    FROM completed
    GROUP BY product_name, product_category
    ORDER BY 2 LIMIT 5
),
top_category AS (
    SELECT '3. Most profitable category (profit)'::TEXT,
           1::BIGINT,
           product_category || ' — margin '
               || ROUND((SUM(revenue) - SUM(cost)) / NULLIF(SUM(revenue), 0) * 100, 1) || '%',
           ROUND(SUM(revenue) - SUM(cost), 2)
    FROM completed
    GROUP BY product_category
    ORDER BY SUM(revenue) - SUM(cost) DESC LIMIT 1
),
low_month AS (
    SELECT '4. Lowest-revenue month'::TEXT,
           1::BIGINT,
           TO_CHAR(month, 'YYYY-MM'),
           revenue
    FROM monthly_sales_summary
    ORDER BY revenue ASC LIMIT 1
)
SELECT * FROM top_customers
UNION ALL SELECT * FROM top_products
UNION ALL SELECT * FROM top_category
UNION ALL SELECT * FROM low_month
ORDER BY section, rank;

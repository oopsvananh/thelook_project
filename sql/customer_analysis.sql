USE thelook;
GO


-- Topic 2: Revenue Growth Strategy
-- Customer Analysis

/***
- Business Overview and Customer Profile use a broader order status definition
  (excluding only Cancelled/Returned) to reflect overall business activity.
- RFM Segmentation uses a narrower definition (Complete only), since this is
  the input for actionable decisions (targeting/marketing), which requires
  confirmed, fully completed transaction data.
***/


-- 0. Business Overview
-- Revenue, profit, AOV, Growth (Complete only)
SELECT 
    SUM(o2.sale_price) AS revenue,
    COUNT(DISTINCT o1.order_id) AS num_of_orders_completed,
    ROUND(
        SUM(o2.sale_price)/
        COUNT(DISTINCT o1.order_id), 2
    ) AS aov,
    SUM(o2.sale_price) - SUM(p.cost) AS profit,
    ROUND((SUM(o2.sale_price) - SUM(p.cost))*100.0/NULLIF(SUM(o2.sale_price),0), 2)  AS profit_margin
FROM orders o1 JOIN order_items o2 ON o1.order_id = o2.order_id
                JOIN products p ON o2.product_id = p.id
WHERE o1.status = 'Complete'
;


-- Growth 
WITH yearly AS (
    SELECT YEAR(o1.created_at) AS [year],
            SUM(o2.sale_price) AS revenue
    FROM orders o1 JOIN order_items o2 ON o1.order_id = o2.order_id
    WHERE o1.status = 'Complete'
    GROUP BY YEAR(o1.created_at)
)
SELECT [year],
    revenue,
    LAG(revenue, 1) OVER(ORDER BY [year]) AS prev_revenue,
    ROUND(
        (revenue*1.0/NULLIF(LAG(revenue, 1) OVER(ORDER BY [year]), 0)  - 1) * 100.0
        , 2
         ) AS growth_pct
FROM yearly
ORDER BY [year] ASC;

WITH monthly AS (
    SELECT YEAR(o1.created_at) AS [year],
            MONTH(o1.created_at) AS [month],
            SUM(o2.sale_price) AS revenue
    FROM orders o1 JOIN order_items o2 ON o1.order_id = o2.order_id
    WHERE o1.status = 'Complete'
    GROUP BY YEAR(o1.created_at), MONTH(o1.created_at)
)
SELECT [year],
    month,
    revenue,
    LAG(revenue, 1) OVER(ORDER BY [year], [month]) AS prev_revenue,
    ROUND(
        (revenue*1.0/NULLIF(LAG(revenue, 1) OVER(ORDER BY [year], [month]),0)  - 1) *100.0
        , 2
         ) AS growth_pct
FROM monthly
ORDER BY [year], [month] ASC;

-- Customers, Orders
SELECT COUNT(DISTINCT u.id) AS total_users, -- registered users
        COUNT(DISTINCT o.[user_id]) AS total_customers, -- users with at least 1 valid order -> customers
        COUNT(DISTINCT o.order_id) AS total_orders
FROM users u LEFT JOIN orders o ON u.id = o.[user_id] AND o.[status] NOT IN ('Cancelled', 'Returned');

SELECT status,
       COUNT(*) AS num_orders,
       ROUND(COUNT(*)*100.0/SUM(COUNT(*)) OVER(), 2) AS pct
FROM orders
GROUP BY status
ORDER BY num_orders DESC;

-- 1. Customer Profile 
-- Metrics: Number of Customers, %, Revenue, AOV, Orders, Revenue Share
-- Customer behaviour analysis should include Processing/Shipped orders, excluding only Cancelled/Returned
-- (Cancelled may reflect casual/accidental orders that don't represent real demand;
--  Returned means the money has already been refunded and is no longer company revenue).

-- 27.775% of users have at least 1 completed order
SELECT 
    COUNT(DISTINCT u.id) AS total_registered_users,
    COUNT(DISTINCT o.user_id) AS customers_active,
    COUNT(DISTINCT CASE WHEN o.[status]='Complete' THEN o.user_id END) AS customers_with_complete_order,
    COUNT(DISTINCT u.id) - COUNT(DISTINCT o.user_id) AS users_not_purchased,
    ROUND(COUNT(DISTINCT o.user_id) * 100.0 / COUNT(DISTINCT u.id), 2) AS conversion_rate_pct
FROM users u
LEFT JOIN orders o ON u.id = o.user_id AND o.status NOT IN ('Cancelled', 'Returned');
 



-- Customers as a share of registered users
-- a. Demographics
-- Gender
SELECT u.gender,
        COUNT(DISTINCT u.id) AS num_of_customers,
        ROUND(
            COUNT(DISTINCT u.id)*100.0/
            SUM(COUNT(DISTINCT u.id)) OVER()
            , 2
        ) AS pct_customers,
        SUM(oi.sale_price) AS revenue,
        ROUND(
            SUM(oi.sale_price)*100.0/
            SUM(SUM(oi.sale_price)) OVER()
            , 2
        ) AS revenue_share,
        COUNT(DISTINCT o.order_id) AS num_of_orders,
        ROUND(
            SUM(oi.sale_price)/
            NULLIF(COUNT(DISTINCT o.order_id),0)
            , 2
        ) AS aov,
        ROUND(
            SUM(oi.sale_price) * 1.0 /
            COUNT(DISTINCT u.id)
            ,2
        ) AS revenue_per_customer
FROM users u 
JOIN order_items oi ON u.id = oi.[user_id]
JOIN orders o ON oi.order_id = o.order_id
WHERE o.[status] NOT IN ('Cancelled', 'Returned')
GROUP BY u.gender;
-- Customer count is roughly 50-50; revenue skews slightly toward male due to higher AOV
-- Gender doesn't affect customer acquisition, but has a small effect on spending behaviour

-- Age

WITH users_group AS (
    SELECT *,
        CASE WHEN age < 18 THEN 'Teen' 
            WHEN age < 24 THEN 'Gen Z'
            WHEN age < 34 THEN 'Young Professionals'
            WHEN age < 44 THEN 'Mid-age Professionals'
            WHEN age < 54 THEN 'Mature Adults'
        ELSE 'Seniors' END AS age_group
    FROM users
) 
SELECT age_group,
        COUNT(DISTINCT u.id) AS num_of_customers,
        ROUND(
            COUNT(DISTINCT u.id)*100.0/
            SUM(COUNT(DISTINCT u.id)) OVER()
            , 2
        ) AS pct_customers,
        SUM(oi.sale_price) AS revenue,
        ROUND(
            SUM(oi.sale_price)*100.0/
            SUM(SUM(oi.sale_price)) OVER()
            , 2
        ) AS revenue_share,
        COUNT(DISTINCT o.order_id) AS num_of_orders,
        ROUND(
            SUM(oi.sale_price)/
            NULLIF(COUNT(DISTINCT o.order_id),0)
            , 2
        ) AS aov,
        ROUND(
            SUM(oi.sale_price) * 1.0 /
            COUNT(DISTINCT u.id)
            ,2
        ) AS revenue_per_customer
FROM users_group u 
JOIN order_items oi ON u.id = oi.[user_id]
JOIN orders o ON oi.order_id = o.order_id
WHERE o.[status] NOT IN ('Cancelled', 'Returned')
GROUP BY age_group
ORDER BY revenue DESC;
-- AOV and Revenue/Customer are fairly even across all age groups
-- Revenue differences mainly come from customer volume (more customers -> more revenue)
-- Age is not a factor that differentiates customer value


-- Country
SELECT u.country,
        COUNT(DISTINCT u.id) AS num_of_customers,
        ROUND(
            COUNT(DISTINCT u.id)*100.0/
            SUM(COUNT(DISTINCT u.id)) OVER()
            , 2
        ) AS pct_customers,
        SUM(oi.sale_price) AS revenue,
        ROUND(
            SUM(oi.sale_price)*100.0/
            SUM(SUM(oi.sale_price)) OVER()
            , 2
        ) AS revenue_share,
        COUNT(DISTINCT o.order_id) AS num_of_orders,
        ROUND(
            SUM(oi.sale_price)/
            NULLIF(COUNT(DISTINCT o.order_id),0)
            , 2
        ) AS aov,
        ROUND(
            SUM(oi.sale_price) * 1.0 /
            COUNT(DISTINCT u.id)
            ,2
        ) AS revenue_per_customer
FROM users u 
JOIN order_items oi ON u.id = oi.[user_id]
JOIN orders o ON oi.order_id = o.order_id
WHERE o.[status] NOT IN ('Cancelled', 'Returned')
GROUP BY u.country;
-- Customers are heavily concentrated in three markets: China, USA, Brazil
-- Large markets generate large revenue mainly due to customer volume
-- (larger markets create more revenue because they have more customers, not because customers there spend more)
-- Customer value (AOV, revenue per customer) is fairly even across the largest markets
-- A few smaller markets show slightly higher spending, but their small customer base limits total revenue contribution



-- b. Acquisition source
-- Traffic source
SELECT u.traffic_source,
        COUNT(DISTINCT u.id) AS num_of_customers,
        ROUND(
            COUNT(DISTINCT u.id)*100.0/
            SUM(COUNT(DISTINCT u.id)) OVER()
            , 2
        ) AS pct_customers,
        SUM(oi.sale_price) AS revenue,
        ROUND(
            SUM(oi.sale_price)*100.0/
            SUM(SUM(oi.sale_price)) OVER()
            , 2
        ) AS revenue_share,
        COUNT(DISTINCT o.order_id) AS num_of_orders,
        ROUND(
            SUM(oi.sale_price)/
            NULLIF(COUNT(DISTINCT o.order_id),0)
            , 2
        ) AS aov,
        ROUND(
            SUM(oi.sale_price) * 1.0 /
            COUNT(DISTINCT u.id)
            ,2
        ) AS revenue_per_customer
FROM users u 
JOIN order_items oi ON u.id = oi.[user_id]
JOIN orders o ON oi.order_id = o.order_id
WHERE o.[status] NOT IN ('Cancelled', 'Returned')
GROUP BY u.traffic_source;
/***
- Search is the most important acquisition channel
- Customer share and revenue share are fairly similar across traffic sources, showing that once users
  sign up and purchase, the value they generate is proportional to how they were acquired
- AOV is fairly even across channels
-> Traffic source affects customer acquisition more than it affects customer spending value
***/

-- 2. Customer Value - How is revenue/value distributed?
-- Overall
SELECT
    COUNT(DISTINCT u.id) AS num_of_customers,
    SUM(oi.sale_price) AS revenue,
    COUNT(DISTINCT o.order_id) AS num_of_orders,
    ROUND(
        SUM(oi.sale_price) * 1.0 /
        COUNT(DISTINCT o.order_id),
        2
    ) AS aov,
    ROUND(
        SUM(oi.sale_price) * 1.0 /
        COUNT(DISTINCT u.id),
        2
    ) AS revenue_per_customer,
    ROUND(
        COUNT(DISTINCT o.order_id) * 1.0 /
        COUNT(DISTINCT u.id),
        2
    ) AS orders_per_customer
FROM users u
JOIN orders o
    ON u.id = o.user_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Complete';

--- Revenue Pareto calculation
-- Each row is a customer with their revenue, ordered descending

WITH customer_revenue AS (
    SELECT 
        u.id, 
        SUM(oi.sale_price) AS revenue 
    FROM users u 
    JOIN orders o 
        ON u.id = o.[user_id] 
    JOIN order_items oi 
        ON o.order_id = oi.order_id 
    WHERE o.[status] = 'Complete' 
    GROUP BY u.id 
), 
customer_pareto AS ( 
    SELECT 
        id, 
        revenue, 
        SUM(revenue) OVER() AS total_revenue, 
        SUM(revenue) OVER(
            ORDER BY revenue DESC  
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cum_revenue, 
        ROW_NUMBER() OVER(
            ORDER BY revenue DESC
        ) AS customer_rank 
    FROM customer_revenue 
), 
pareto_result AS (
    SELECT 
        id, 
        revenue, 
        customer_rank,
        cum_revenue,
        ROUND(
            customer_rank * 100.0 / COUNT(*) OVER(), 
            2
        ) AS customer_share,
        ROUND(
            cum_revenue * 100.0 / total_revenue,  
            10
        ) AS cum_share
    FROM customer_pareto 
)
SELECT TOP 1
    customer_rank,
    customer_share,
    cum_share
FROM pareto_result
WHERE cum_share >= 80
ORDER BY customer_rank ASC;
--- 12,682 customers (45.66% of total customers) generate 80% of total revenue

-- Split customers into percentile buckets
WITH customer_revenue AS (
    SELECT u.id, SUM(oi.sale_price) AS revenue
    FROM users u
    JOIN orders o ON u.id = o.user_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Complete'
    GROUP BY u.id
),
ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (ORDER BY revenue DESC) AS rn,
        COUNT(*) OVER () AS total_customers
    FROM customer_revenue
),
bucketed AS (
    SELECT *,
        CEILING(rn * 20.0 / total_customers) AS bucket  -- 20 buckets, 5% each
    FROM ranked
)
SELECT 
    bucket,
    bucket * 5 AS customer_pct,     -- Top 5%, 10%, 15%, ...
    SUM(revenue) AS bucket_revenue,
    SUM(SUM(revenue)) OVER (ORDER BY bucket) AS cumulative_revenue,
    ROUND(
        SUM(SUM(revenue)) OVER (ORDER BY bucket) * 100.0 / SUM(SUM(revenue)) OVER (), 
        2
    ) AS cumulative_revenue_pct
FROM bucketed
GROUP BY bucket
ORDER BY bucket;

-- 3. Customer segmentation

-- Calculate raw R, F, M

WITH snapshot_date AS (
    SELECT DATEADD(day, 1, MAX(created_at)) AS snap_date -- last date in the data is 2024-05-10
    FROM orders 
),
calc_rfm AS (
    SELECT u.id AS customer_id,
            DATEDIFF(day, MAX(o.created_at), (SELECT snap_date FROM snapshot_date)) AS recency,
            COUNT(DISTINCT o.order_id) AS frequency,
            SUM(oi.sale_price) AS monetary
    FROM users u JOIN orders o ON u.id = o.[user_id]
                JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.[status] = 'Complete'
    GROUP BY u.id
)
SELECT * FROM calc_rfm;


WITH snapshot_date AS (
    SELECT DATEADD(day, 1, MAX(created_at)) AS snap_date
    FROM orders 
),
calc_rfm AS (
    SELECT u.id AS customer_id,
            COUNT(DISTINCT o.order_id) AS frequency
    FROM users u JOIN orders o ON u.id = o.[user_id]
                JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.[status] = 'Complete'
    GROUP BY u.id
)
SELECT frequency,
       COUNT(*) AS num_customers,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_customers
FROM calc_rfm
GROUP BY frequency
ORDER BY frequency;
-- Frequency only ranges from 1 to 4; the % of customers who purchase only once dominates at 88.09%
-- Only 11.91% of customers return for a 2nd purchase or more
-- -> Most customers are lost right after their first purchase
-- -> A significant retention problem

-- How much revenue does each frequency group generate?
WITH snapshot_date AS (
    SELECT DATEADD(day, 1, MAX(created_at)) AS snap_date FROM orders 
),
calc_rfm AS (
    SELECT u.id AS customer_id,
            COUNT(DISTINCT o.order_id) AS frequency,
            SUM(oi.sale_price) AS monetary
    FROM users u JOIN orders o ON u.id = o.[user_id]
                JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.[status] = 'Complete'
    GROUP BY u.id
)
SELECT 
    CASE WHEN frequency = 1 THEN '1' ELSE '2+' END AS freq_group,
    COUNT(*) AS num_customers,
    SUM(monetary) AS total_revenue,
    ROUND(SUM(monetary)*1.0/COUNT(*), 2) AS revenue_per_cust, 
    ROUND(SUM(monetary)*100.0/SUM(SUM(monetary)) OVER(), 2) AS pct_revenue
FROM calc_rfm
GROUP BY CASE WHEN frequency = 1 THEN '1' ELSE '2+' END;
-- Customers who purchase only once still contribute the majority of revenue simply because they are the majority of customers
-- Revenue per customer for the 2+ group is more than 2x higher than the 1-time group, despite only being 11.91% of customers
-- -> Acquisition remains the main revenue driver due to sheer volume
-- -> Investing in retention delivers significantly higher value per customer

SELECT AVG(num_of_item*1.0) AS avg_items_per_order
FROM orders
WHERE status = 'Complete';



-- Customer segments
SELECT * FROM customer_segments

-- Segment Performance
SELECT segment,
        COUNT(customer_id) AS num_of_customers,
        ROUND(
            COUNT(customer_id)*100.0/
            SUM(COUNT(customer_id)) OVER()
            , 2
        ) AS pct_customers, 
        SUM(monetary) AS total_revenue,
        ROUND(
            SUM(monetary)*100.0/
            SUM(SUM(monetary)) OVER()
            , 2
        ) AS pct_revenue,
        ROUND(AVG(monetary)*1.0, 2) AS avg_revenue_per_customer,
        ROUND(AVG(frequency)*1.0, 2) AS avg_orders_per_customer
FROM customer_segments
GROUP BY segment
;
-- Loyal Customers have high revenue/customer -> shows that loyal customers deliver high value despite being a small group
-- High-Value New (first-time buyers) also show high revenue/customer -> a promising segment.
--   Converting them into Loyal Customers would be valuable -> encourage a second purchase, etc.
-- Lost and Inactive customers make up a large share, contributing ~60% of total revenue -> dragging down overall performance.
--   Need a strategy to win back Inactive Customers... Lost customers have been gone too long to realistically target.

-- Basket 
SELECT 
    cs.segment,
    COUNT(DISTINCT o.order_id) AS num_orders,
    COUNT(oi.id) AS num_items,
    ROUND(SUM(oi.sale_price)*1.0/COUNT(DISTINCT o.order_id), 2) AS aov,
    ROUND(COUNT(oi.id)*1.0/COUNT(DISTINCT o.order_id), 2) AS items_per_order,
    ROUND(COUNT(DISTINCT o.order_id)*1.0/COUNT(DISTINCT cs.customer_id), 2) AS orders_per_customer
FROM customer_segments cs
JOIN orders o ON cs.customer_id = o.user_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Complete'
GROUP BY cs.segment;
-- Basket size is not what differentiates Loyal Customers from churned customers -- the difference lies in
-- purchase frequency, not order size (basket size is similar across segments)
-- Loyal Customers don't have the highest AOV; their value comes from a higher purchase frequency



-- Deep-dive - Focus on segments: High-Value New, Loyal Customers, and Inactive

-- Demographics, acquisition source, product preferences
-- a. Loyal customers
SELECT u.gender,
        COUNT(c.customer_id) AS num_of_customers,
        ROUND(
            COUNT(c.customer_id)*100.0/
            SUM(COUNT(c.customer_id)) OVER()
            , 2
        ) AS pct_customers
FROM customer_segments c JOIN users u ON c.customer_id = u.id
WHERE segment = 'Inactive Customers'
GROUP BY u.gender;

SELECT u.country,
        COUNT(c.customer_id) AS num_of_customers,
        ROUND(
            COUNT(c.customer_id)*100.0/
            SUM(COUNT(c.customer_id)) OVER()
            , 2
        ) AS pct_customers
FROM customer_segments c JOIN users u ON c.customer_id = u.id
WHERE segment = 'Inactive Customers'
GROUP BY u.country;


WITH customers_group AS (
    SELECT *,
        CASE WHEN age < 18 THEN 'Teen' 
            WHEN age < 24 THEN 'Gen Z'
            WHEN age < 34 THEN 'Young Professionals'
            WHEN age < 44 THEN 'Mid-age Professionals'
            WHEN age < 54 THEN 'Mature Adults'
        ELSE 'Seniors' END AS age_group
    FROM users
) 
SELECT age_group,
        COUNT(cs.customer_id) AS num_of_customers,
        ROUND(
            COUNT(cs.customer_id)*100.0/
            SUM(COUNT(cs.customer_id)) OVER()
            , 2
        ) AS pct_customers
FROM customers_group c 
JOIN customer_segments cs ON c.id = cs.customer_id
WHERE segment = 'Inactive Customers'
GROUP BY c.age_group;

SELECT u.traffic_source,
        COUNT(c.customer_id) AS num_of_customers,
        ROUND(
            COUNT(c.customer_id)*100.0/
            SUM(COUNT(c.customer_id)) OVER()
            , 2
        ) AS pct_customers
FROM customer_segments c JOIN users u ON c.customer_id = u.id
WHERE segment = 'Inactive Customers'
GROUP BY u.traffic_source;
-- Inactive Customers look identical to the overall baseline across all 4 dimensions (gender, country, age, traffic source)
-- Same pattern holds for the other segments

-- Deep-dive by product preference
SELECT 
    cs.segment,
    p.department,
    COUNT(DISTINCT oi.order_id) AS num_orders,
    SUM(oi.sale_price) AS revenue,
    ROUND(SUM(oi.sale_price)*100.0/SUM(SUM(oi.sale_price)) OVER(PARTITION BY cs.segment), 2) AS pct_revenue_within_segment
FROM customer_segments cs
JOIN orders o ON cs.customer_id = o.user_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.id
WHERE o.status = 'Complete'
GROUP BY cs.segment, p.department
ORDER BY cs.segment, revenue DESC;
-- Department split is fairly even across segments


SELECT 
    cs.segment,
    p.category,
    COUNT(DISTINCT oi.order_id) AS num_orders,
    SUM(oi.sale_price) AS revenue,
    ROUND(SUM(oi.sale_price)*100.0/SUM(SUM(oi.sale_price)) OVER(PARTITION BY cs.segment), 2) AS pct_revenue_within_segment
FROM customer_segments cs
JOIN orders o ON cs.customer_id = o.user_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.id
WHERE o.status = 'Complete'
GROUP BY cs.segment, p.category
ORDER BY cs.segment, revenue DESC;

/*** 
- Outerwear & Coats typically have a higher retail price than other categories (Socks, Underwear, Accessories...),
  which explains why customers who buy a lot of Outerwear & Coats in their first order tend to fall into the
  "High-Value New" segment -> they buy high-value products right from the start
- Loyal Customers (3+ purchases) have the lowest top-3 category revenue share (28.17%) of any segment --
  this shows that across multiple purchases, they tend to buy a more diverse mix of categories rather than
  concentrating on just 1-2 categories.
-> Their basket expands over time -- loyal customers don't just repeat-buy the same product type, they explore
  more categories across the platform.
- All 5 segments agree on the same top-3 categories (Jeans, Outerwear & Coats, Sweaters), except New Customers,
  whose #1 category is Jeans
-> These are the platform's core categories overall
***/


-- Top 5 categories per segment
WITH ranked_category AS (
    SELECT 
        cs.segment,
        p.category,
        SUM(oi.sale_price) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY cs.segment ORDER BY SUM(oi.sale_price) DESC) AS category_rank
    FROM customer_segments cs
    JOIN orders o ON cs.customer_id = o.user_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.id
    WHERE o.status = 'Complete'
    GROUP BY cs.segment, p.category
)
SELECT segment, category, revenue, category_rank
FROM ranked_category
WHERE category_rank <= 5
ORDER BY segment, category_rank;


-- Number of customers by category
SELECT p.category, 
    COUNT(DISTINCT oi.[user_id]) AS num_of_customers
FROM products p JOIN order_items oi ON p.id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.[status] = 'Complete'
GROUP BY p.category
ORDER BY COUNT(DISTINCT oi.[user_id]) DESC;


-- Check % revenue from top 3 categories per segment
WITH category_revenue AS (
    SELECT 
        cs.segment,
        p.category,
        SUM(oi.sale_price) AS revenue
    FROM customer_segments cs
    JOIN orders o ON cs.customer_id = o.user_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.id
    WHERE o.status = 'Complete'
    GROUP BY cs.segment, p.category
),
ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY segment ORDER BY revenue DESC) AS rn,
        SUM(revenue) OVER (PARTITION BY segment) AS total_segment_revenue
    FROM category_revenue
)
SELECT 
    segment,
    SUM(revenue) AS top3_revenue,
    MAX(total_segment_revenue) AS total_segment_revenue,
    ROUND(SUM(revenue) * 100.0 / MAX(total_segment_revenue), 2) AS pct_top3
FROM ranked
WHERE rn <= 3
GROUP BY segment
ORDER BY pct_top3 DESC;

-- Cohort Retention
WITH first_purchase AS (
    SELECT [user_id],
        MIN(YEAR(created_at)) AS cohort_year
    FROM orders 
    WHERE [status] = 'Complete'
    GROUP BY [user_id]
), customer_orders AS (
    SELECT fp.[user_id],
        fp.cohort_year,
        YEAR(o.created_at) AS order_year,
        YEAR(o.created_at) - fp.cohort_year AS period_offset
    FROM first_purchase fp
    JOIN orders o ON fp.[user_id] = o.[user_id]
    WHERE o.[status] = 'Complete'
), cohort_size AS (
    SELECT cohort_year,
        COUNT(DISTINCT [user_id]) AS num_customers
    FROM first_purchase
    GROUP BY cohort_year
), retention AS (
    SELECT cohort_year,
        period_offset,
        COUNT(DISTINCT [user_id]) AS active_customers
    FROM customer_orders
    GROUP BY cohort_year, period_offset
) 
SELECT r.cohort_year,
    r.period_offset,
    r.active_customers,
    cs.num_customers AS cohort_size,
    ROUND(r.active_customers * 100.0/cs.num_customers, 2) AS retention_rate
FROM retention r JOIN cohort_size cs ON r.cohort_year = cs.cohort_year
ORDER BY r.cohort_year, r.period_offset;

-- Quarter
WITH first_purchase AS (
    SELECT 
        o.user_id,
        MIN(DATEFROMPARTS(YEAR(o.created_at), (DATEPART(QUARTER, o.created_at)-1)*3+1, 1)) AS cohort_quarter_date
    FROM orders o
    WHERE o.status = 'Complete'
    GROUP BY o.user_id
),
customer_orders AS (
    SELECT 
        fp.user_id,
        fp.cohort_quarter_date,
        DATEFROMPARTS(YEAR(o.created_at), (DATEPART(QUARTER, o.created_at)-1)*3+1, 1) AS order_quarter
    FROM first_purchase fp
    JOIN orders o ON fp.user_id = o.user_id
    WHERE o.status = 'Complete'
),
with_offset AS (
    SELECT 
        user_id,
        cohort_quarter_date,
        DATEDIFF(QUARTER, cohort_quarter_date, order_quarter) AS period_offset
    FROM customer_orders
),
cohort_size AS (
    SELECT cohort_quarter_date, COUNT(DISTINCT user_id) AS num_customers
    FROM first_purchase
    GROUP BY cohort_quarter_date
),
retention AS (
    SELECT cohort_quarter_date, period_offset, COUNT(DISTINCT user_id) AS active_customers
    FROM with_offset
    GROUP BY cohort_quarter_date, period_offset
)
SELECT 
    CONCAT(YEAR(r.cohort_quarter_date), '-Q', DATEPART(QUARTER, r.cohort_quarter_date)) AS cohort_quarter_label,
    r.period_offset,
    r.active_customers,
    cs.num_customers AS cohort_size,
    ROUND(r.active_customers * 100.0 / cs.num_customers, 2) AS retention_pct
FROM retention r
JOIN cohort_size cs ON r.cohort_quarter_date = cs.cohort_quarter_date
ORDER BY r.cohort_quarter_date, r.period_offset;
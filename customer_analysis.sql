USE thelook;
GO


-- Topic 2: Revenue Growth Strategy
-- Customer Analysis

/***
- Business Overview và Customer Profile sử dụng định nghĩa rộng (loại Cancelled/Returned) 
để phản ánh đúng quy mô hoạt động kinh doanh.
- RFM Segmentation sử dụng định nghĩa hẹp hơn (chỉ Complete) vì đây là input cho quyết định hành động (targeting/marketing), 
cần dữ liệu giao dịch đã hoàn tất chắc chắn.
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
SELECT COUNT(DISTINCT u.id) AS total_users, -- users đăng ký
        COUNT(DISTINCT o.[user_id]) AS total_customers, -- users có ít nhất 1 order hợp lệ -> customers
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
-- Customer behaviour nên include cả đơn Processing/Shipped, chỉ loại Cancelled/Returned
-- (vì Cancelled có thể là khách chơi, không phản ánh nhu cầu thật;
--  Returned là tiền đã hoàn lại, không còn thuộc công ty).

-- Có 27.775% users có ít nhất 1 order complete
SELECT 
    COUNT(DISTINCT u.id) AS total_registered_users,
    COUNT(DISTINCT o.user_id) AS customers_active,
    COUNT(DISTINCT CASE WHEN o.[status]='Complete' THEN o.user_id END) AS customers_with_complete_order,
    COUNT(DISTINCT u.id) - COUNT(DISTINCT o.user_id) AS users_not_purchased,
    ROUND(COUNT(DISTINCT o.user_id) * 100.0 / COUNT(DISTINCT u.id), 2) AS conversion_rate_pct
FROM users u
LEFT JOIN orders o ON u.id = o.user_id AND o.status NOT IN ('Cancelled', 'Returned');
 



-- Tính customers trong số registered users
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
-- Số lượng cust gần như 50-50, revenue lệch nhẹ về male vì AOV cao hơn
-- Gender không ảnh hưởng đến việc thu hút khách hàng nhưng ảnh hưởng đến spending behavior 1 chút

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
-- AOV, Revenue/Customer gần như đồng đều giữa all groups
-- Sự khác biệt về revenue chủ yếu đến từ quy mô khách hàng (số lượng khách hàng lớn -> doanh thu cao)
-- Age không phải yếu tố phân biệt giá trị khách hàng


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
-- Customer tập trung mạnh ở ba thị trường: China, USA, Brasil
-- Các thị trường lớn tạo doanh thu lớn chủ yếu do quy mô khách hàng (thị trường lớn tạo doanh thu do có nhiều khách hàng hơn, không phải khách ở đó chi tiêu nhiều hơn)
-- Gía trị khách hàng (AOV, revenue per customer) giữa các quốc gia lớn khá đồng đều (bỏ qua các nước nhỏ
-- Một vài thị trường nhỏ hơn có spending cao hơn chút nhưng quy mô khách hàng nhỏ, đóng góp doanh thu còn hạn chế



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
- Search là nguồn acquisition quan trọng nhất
- Customer share và revenue share khá tuonwg đồng ở các traffic source, điều đó cho thấy sau khi users đăng ký tài khoản và mua hàng,
giá trị họ tạo ra tương đương với sự acquisition
- AOV giữa các nguồn khá đồng đều 
-> Traffic source ảnh hưởng nhiều đến khả năng thu hút khách hàng hơn là giá trị chi tiêu của khách hàng
***/

-- 2. Customer Value - Giá trị/doanh thu phân phối ra sao...
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

--- Tính pareto revenue
-- Mỗi dòng là customer và revenue order desc

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
--- 12682 khách hàng chiếm tổng 45.66% tổng customers tạo ra 80% revenue

-- Chia khách hàng theo percentile bucket
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
        CEILING(rn * 20.0 / total_customers) AS bucket  -- chia 20 bucket, mỗi bucket 5%
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

-- Tính raw R, F, M

WITH snapshot_date AS (
    SELECT DATEADD(day, 1, MAX(created_at)) AS snap_date -- ngày cuối cùng của data là 10/5/2024
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
-- frequency chỉ có từ 1 -> 4, % cust chỉ mua 1 lần áp đảo, 88.09%
-- Chỉ 11.91% khách hàng quay lại mua lần 2 trở lên
-- -> phần lớn mất khách hàng ngay sau lần mua đầu tiên
-- -> Vấn đề retention kém

-- Các nhóm frequency mang lại bao nhiêu revenue?
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
-- Nhóm khách hàng mua 1 lần vẫn đóng góp phần lớn revenue vì họ chiếm số đông
-- Rev per cust của 2+ có giá trị trung bình gấp hơn 2 lần so với khách hàng chỉ mua 1 lần tuy số lượng khách hàng chỉ chiếm 11.91%
-- -> Acquisition vẫn là động lực doanh thu chính do quy mô
-- -> Đầu tư vào retention mang lại giá trị trên từng khách hàng cao hơn đáng kể

SELECT AVG(num_of_item*1.0) AS avg_items_per_order
FROM orders
WHERE status = 'Complete';



-- Các segments của customers
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
-- Loyal customers có revenue/customer cao -> cho thấy việc khách hàng trung thành mang lại giá trị cao dù chỉ chiếm số lượng nhỏ
-- High-value Newlaf nhóm khách hàng mới mua lần đầu nhưng revenue/customer của họ cũng cao -> tiềm năng. Vì vậy, nếu convert họ thành loyal customers thì sẽ rất tốt -> khuyến khích mua lần 2 ....
-- Lost và Inactive chiếm số lượng lớn, revenue tổng chiếm 60% -> kéo performance xuống. Cần tìm chiến lược để kéo Inactive Customers lại...
-- Còn Lost thì quá lâu 

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
-- Basket size không phải yếu tố phân biệt Loyal Customers với khách hàng rời bỏ - sự khác biệt nằm ở tần suất quay lại, không phải quy mô đơn hàng. (Basket size giữa các segments tương đương nhau)
-- Loyal Customers không có AOV cao nhất, họ tạo value nhờ purchase frequency cao hơn



-- Deepdive - Focus on segments: High-value New, Loyal Customers và Inactive

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
-- Loyal Customers giống hệt baseline ở cả 4 chiều (gender, country, age, traffic source)
-- Tương tự với các segments khác

-- Deep-dive theo product preference
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
-- Department gần như đồng đều ở các segments


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
- Outerwear & Coats (áo khoác) thường có retail price cao hơn các category khác (Socks, Underwear, Accessories...), 
điều này giải thích được việc khách hàng mua nhiều Outerwear & Coats trong đơn đầu tiên dễ rơi vào nhóm "High-Value New"
-> họ mua sản phẩm giá trị cao ngay từ đầu
- Loyal Customers (mua ≥3 lần) có tỷ trọng top 3 category thấp nhất (28.17%) so với các segments trên - 
điều này cho thấy qua nhiều lần mua khác nhau, họ có xu hướng mua đa dạng category hơn thay vì chỉ tập trung vào 1-2 loại.
-> basket mở rộng over time, khách hàng trung thành không chỉ mua lặp lại cùng 1 loại sản phẩm, mà khám phá thêm các category khác của platform.
- Cả 5 segment đều thống nhất Top 3 category (Jeans, Outerwear & Coats, Sweaters) trừ New customers có Jeans top 1
-> core categories của toàn platform
***/


-- Top 5 categories according to each segment
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


-- Kiểm tra % Revenue Top 3 Category theo từng segment
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


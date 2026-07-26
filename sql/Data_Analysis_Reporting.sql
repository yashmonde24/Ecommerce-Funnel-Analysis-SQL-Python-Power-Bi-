-- ============================================================
-- PROJECT: E-Commerce Funnel Analysis - All Queries
-- DATABASE: MS SQL Server | Dataset: Olist (Kaggle)
-- ============================================================
-- HOW TO USE THIS FILE:
-- Run queries one by one. Each has a label, explanation,
-- and the actual SQL. Read the explanation first.
-- ============================================================

USE Ecommerce_Funnel;
GO

-- Data Standardization
UPDATE customers
SET 
    customer_id = TRIM(REPLACE(customer_id,'"','')),
    customer_unique_id = TRIM(REPLACE(customer_unique_id, '"', '')),
    customer_zip_code = TRIM(REPLACE(customer_zip_code, '"', ''))
   
UPDATE order_items
SET
    order_id = TRIM(REPLACE(order_id,'"','')),
    product_id = TRIM(REPLACE(product_id,'"','')),
    seller_id = TRIM(REPLACE(seller_id,'"',''))
 
UPDATE orders
SET
    order_id = TRIM(REPLACE(order_id,'"','')),
    customer_id= TRIM(REPLACE(customer_id,'"',''))

UPDATE payments 
SET  
    order_id = TRIM(REPLACE(order_id,'"',''))

UPDATE products
SET  
    product_id = TRIM(REPLACE(product_id,'"',''))



-- ============================================================
-- QUERY 1: Basic Data Sanity Check
-- WHY: Always do this first. Understand your data before
--      building anything. Catch nulls, bad counts, surprises.
-- ============================================================

-- How many rows in each table?
SELECT 'customers'   AS table_name, COUNT(*) AS row_count FROM customers   UNION ALL   -- Result : 99441
SELECT 'orders'      AS table_name, COUNT(*) AS row_count FROM orders       UNION ALL  -- Result : 99441 
SELECT 'order_items' AS table_name, COUNT(*) AS row_count FROM order_items  UNION ALL  -- Result : 112650
SELECT 'products'    AS table_name, COUNT(*) AS row_count FROM products     UNION ALL  -- Result : 32951
SELECT 'payments'    AS table_name, COUNT(*) AS row_count FROM payments     UNION ALL  -- Result : 99224
SELECT 'reviews'     AS table_name, COUNT(*) AS row_count FROM reviews;

-- What order statuses exist? (understand data categories)
SELECT 
    order_status,
    COUNT(*) AS total_orders,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS percent_dist
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- How many orders have NULL in key funnel timestamp columns?
-- NULL means that stage was never reached = drop-off
SELECT
    COUNT(*)                                                             AS total_orders,   -- Result : 99441
    SUM(CASE WHEN order_approved_at           IS NULL THEN 1 ELSE 0 END) AS never_approved, -- Result : 160 
    SUM(CASE WHEN order_delivered_carrier_dt  IS NULL THEN 1 ELSE 0 END) AS never_shipped,  -- Result : 1783
    SUM(CASE WHEN order_delivered_customer_dt IS NULL THEN 1 ELSE 0 END) AS never_delivered -- Result : 2965
FROM orders;


-- ============================================================
-- QUERY 2: The Core Funnel — Stage-by-Stage Drop-off
-- WHY:Shows how many orders made it through each stage and who dropped off.
--
-- FUNNEL STAGES:
--   Stage 1 = Order placed (every order starts here)
--   Stage 2 = Payment approved
--   Stage 3 = Handed to shipping carrier
--   Stage 4 = Delivered to customer
--   Stage 5 = Customer left a review
-- ============================================================
-- Comparative Analysis 
WITH funnel AS (
    SELECT
        -- Stage 1: All unique orders that were placed
        COUNT(DISTINCT o.order_id)                                                  AS s1_placed,   -- Result : 99441

        -- Stage 2: Unique Orders that got payment approval
        COUNT(DISTINCT CASE WHEN o.order_approved_at IS NOT NULL 
                            THEN o.order_id END)                                    AS s2_approved, -- Result : 99281

        -- Stage 3: Orders that were handed to a shipping carrier
        COUNT(DISTINCT CASE WHEN o.order_delivered_carrier_dt IS NOT NULL 
                            THEN o.order_id END)                                    AS s3_shipped,  -- Result : 97658

        -- Stage 4: Orders that were actually delivered to the customer
        COUNT(DISTINCT CASE WHEN o.order_delivered_customer_dt IS NOT NULL 
                            THEN o.order_id END)                                    AS s4_delivered, -- Result : 96476

        -- Stage 5: Delivered orders where customer also wrote a review
        COUNT(DISTINCT CASE WHEN o.order_delivered_customer_dt IS NOT NULL 
                            AND r.review_id IS NOT NULL 
                            THEN o.order_id END)                                    AS s5_reviewed   -- Result : 36244
    FROM orders o
    LEFT JOIN reviews r ON o.order_id = r.order_id
)
SELECT
    -- Show each stage as a row with count, % vs stage 1, and % drop from previous stage
    stage,
    stage_count,
    -- Overall conversion: how many % of ALL orders reached this stage
    CAST(stage_count * 100.0 / s1_placed AS DECIMAL(5,2))                         AS percent_of_total,
    -- Step conversion: how many % made it from the PREVIOUS stage to current one 
    CAST(stage_count * 100.0 / LAG(stage_count) OVER (ORDER BY stage_order) 
         AS DECIMAL(5,2))                                                       AS percent_from_prev_stage
FROM (
    SELECT 1 AS stage_order, 'Stage 1: Placed'    AS stage, s1_placed    AS stage_count, s1_placed FROM funnel UNION ALL
    SELECT 2,                'Stage 2: Approved'  AS stage, s2_approved  AS stage_count, s1_placed FROM funnel UNION ALL
    SELECT 3,                'Stage 3: Shipped'   AS stage, s3_shipped   AS stage_count, s1_placed FROM funnel UNION ALL
    SELECT 4,                'Stage 4: Delivered' AS stage, s4_delivered AS stage_count, s1_placed FROM funnel UNION ALL
    SELECT 5,                'Stage 5: Reviewed'  AS stage, s5_reviewed  AS stage_count, s1_placed FROM funnel
) t
ORDER BY stage_order;

-- INSIGHTS :
-- Which stage has the biggest drop? This is the problem area.
-- If Stage 2→3 drops a lot: shipping/logistics issue.
-- If Stage 4→5 drops a lot: customers don't bother reviewing.


-- ============================================================
-- QUERY 3: Conversion Rate Summary 
-- ============================================================

WITH stage_counts AS (
    SELECT
        COUNT(DISTINCT o.order_id)                                              AS total_placed,
        COUNT(DISTINCT CASE WHEN o.order_approved_at IS NOT NULL 
                            THEN o.order_id END)                                AS total_approved,
        COUNT(DISTINCT CASE WHEN o.order_delivered_customer_dt IS NOT NULL 
                            THEN o.order_id END)                                AS total_delivered,
        COUNT(DISTINCT CASE WHEN o.order_delivered_customer_dt IS NOT NULL 
                             AND r.review_id IS NOT NULL 
                            THEN o.order_id END)                                AS total_reviewed
    FROM orders o
    LEFT JOIN reviews r ON o.order_id = r.order_id
)
SELECT
    total_placed,
    total_approved,
    total_delivered,
    total_reviewed,
    -- End-to-end conversion: what % of placed orders got delivered?
    CAST(total_delivered * 100.0 / total_placed     AS DECIMAL(5,2)) AS delivery_conv_rate_percent,
    -- Review rate: of delivered, how many got a review?
    CAST(total_reviewed * 100.0 / total_delivered   AS DECIMAL(5,2)) AS review_rate_percent
FROM stage_counts;


-- ============================================================
-- QUERY 4: Time Between Funnel Stages (Time Gap / Speed Analysis)
-- WHY: Speed matters in e-commerce. How long does each step take? 
--      Slow stages = customer frustration = churn.
--      Here we use DATEDIFF() to handle these scenario.
-- ============================================================

SELECT

    -- Average hours from order placed to payment approved
    AVG(DATEDIFF(HOUR, order_purchase_timestamp, order_approved_at))            AS avg_hours_to_approval,       -- Result : 10 hrs

    -- Average Days from approval to handed to carrier
    AVG(DATEDIFF(DAY, order_approved_at, order_delivered_carrier_dt))          AS avg_days_approval_to_ship,    -- Result : 2 days

    -- Average days from carrier pickup to customer delivery
    AVG(DATEDIFF(DAY, order_delivered_carrier_dt, order_delivered_customer_dt)) AS avg_days_ship_to_delivery,   -- Result : 9 days

    -- Average total days from order placed to delivered
    AVG(DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_dt))   AS avg_total_days_to_deliver    -- Result : 12 days

    -- Median is better than average for skewed data (outliers mess up averages)
    -- PERCENTILE_CONT(0.5) = median
    --PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY 
        --DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_dt))
        --OVER ()                                                              
        --AS median_days_to_deliver
FROM orders
WHERE order_delivered_customer_dt IS NOT NULL   -- only look at orders that were actually delivered
  AND order_approved_at IS NOT NULL
  AND order_delivered_carrier_dt IS NOT NULL


-- WHAT INSIGHTS TO LOOK FOR:
-- If avg_hours_to_approval is very high → payment system is slow
-- If avg_days_ship_to_delivery is very high → last-mile delivery is broken
-- If median >> average or vice versa → lots of outliers in your data


-- ============================================================
-- QUERY 5: Revenue by Funnel Stage
-- WHY: Not all drop-offs are equal. A $500 order dropping off
--      hurts more than a $10 order. This shows revenue impact.
-- ============================================================

SELECT
    order_status,
    COUNT(DISTINCT o.order_id)          AS order_count,
    -- Total revenue = sum of all item prices (not including freight)
    SUM(oi.price)                       AS total_revenue,
    -- Average order value
    AVG(oi.price)                       AS avg_item_price,
    -- Revenue that was LOST (orders that didn't complete)
    CAST(COUNT(DISTINCT o.order_id) * 100.0 / 
         SUM(COUNT(DISTINCT o.order_id)) OVER() AS DECIMAL(5,2)) AS percent_of_orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY order_status
ORDER BY total_revenue DESC;

-- Revenue from ONLY delivered orders (actual revenue)
SELECT
    SUM(oi.price)           AS actual_revenue,
    SUM(oi.freight_value)   AS total_freight_collected,
    SUM(oi.price + oi.freight_value) AS total_billed_to_customers
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';


-- ============================================================
-- QUERY 6: Payment Method Analysis at Each Funnel Stage
-- WHY: Different payment methods have different approval rates.
--      Credit cards might approve faster than boleto (bank slip).
--      This is a classic business insight.
-- ============================================================

SELECT
    p.payment_type,
    COUNT(DISTINCT o.order_id)                                                      AS total_orders,

    -- How many with this payment type got delivered?
    COUNT(DISTINCT CASE WHEN o.order_status = 'delivered'  THEN o.order_id END)     AS delivered_orders,

    -- Delivery rate per payment method
    CAST(
        COUNT(DISTINCT CASE WHEN o.order_status = 'delivered' THEN o.order_id END) 
        * 100.0 / COUNT(DISTINCT o.order_id) AS DECIMAL(5,2))                        AS delivery_rate_percent,

    -- Average payment amount per method
    ROUND(AVG(p.payment_value),2)                                                    AS avg_payment_value,

    -- Average installments (tells you about customer affordability behavior)
    ROUND(AVG(CAST(p.payment_installments AS FLOAT)),0)                              AS avg_installments
FROM orders o
INNER JOIN payments p ON o.order_id = p.order_id
GROUP BY p.payment_type
ORDER BY total_orders DESC;

--INSIGHTS :
-- If boleto has lower delivery_rate → customers abandon boleto payments
-- If credit card has high installments → customers buying expensive items on credit


-- ============================================================
-- QUERY 7: Review Score Distribution vs Delivery Speed
-- WHY: Shows whether slow delivery hurts satisfaction.
--      "Faster delivery = better reviews = more repeat orders"
-- ============================================================

SELECT
    r.review_score,
    COUNT(DISTINCT o.order_id)  AS order_count,
    -- Average delivery time for each review score group
    AVG(DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_dt))  AS avg_days_to_deliver,
    -- Were they delivered on time?
    ROUND(AVG(CASE 
                   WHEN o.order_delivered_customer_dt <= o.order_estimated_delivery_dt 
                   THEN 1.0 
                   ELSE 0.0 
               END) * 100,2)      AS percent_delivered_on_time
FROM orders o
JOIN reviews r ON o.order_id = r.order_id
WHERE o.order_delivered_customer_dt IS NOT NULL
GROUP BY r.review_score
ORDER BY r.review_score DESC;

-- INSIGHTS :
-- Score 1 and 2 order takes longer delivery times
-- This proves delivery speed directly impacts customer satisfaction


-- ============================================================
-- QUERY 8: Repeat Customers — Funnel Loyalty Analysis
-- WHY: Repeat customers are 5x cheaper to retain than
--      acquiring new ones. Identifying them is key.
--
-- LOGIC: Same customer ID appearing in multiple orders
--        means they came back. That's funnel success.
-- ============================================================

WITH customer_order_count AS (
    SELECT
        REPLACE(c.customer_unique_id,'"','') as customer_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        MIN(o.order_purchase_timestamp) AS first_order_date,
        MAX(o.order_purchase_timestamp) AS last_order_date,
        SUM(oi.price) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'  -- only count completed orders
    GROUP BY c.customer_unique_id
)
SELECT
    -- Segment customers based on their orders
    CASE 
        WHEN total_orders = 1 THEN '1 - One-time buyer'
        WHEN total_orders = 2 THEN '2 - Bought twice'
        WHEN total_orders >= 3 THEN '3+ - Loyal customer'
    END AS customer_segment,

    COUNT(*) AS customer_count,
    AVG(total_spent) AS avg_total_spent,

    -- Days between first and last order (how long they stayed active)
    AVG(DATEDIFF(DAY, first_order_date, last_order_date)) AS avg_days_active,

    -- % of total customers
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS percent_of_customers
FROM customer_order_count
GROUP BY 
    CASE 
        WHEN total_orders = 1 THEN '1 - One-time buyer'
        WHEN total_orders = 2 THEN '2 - Bought twice'
        WHEN total_orders >= 3 THEN '3+ - Loyal customer'
    END
ORDER BY customer_segment;

-- INSIGHTS :
-- Most of our buyers are One Time.
-- Business is loosing customers.
-- There is a drop in user from platform.
-- Loyal customer had highest spent per order . 


-- ============================================================
-- QUERY 9: Category-Level Funnel Performance
-- WHY: Some product categories may have terrible delivery
--      rates. Maybe heavy items get damaged. Maybe electronics
--      get canceled more. This surfaces those patterns.
-- ============================================================

SELECT TOP 20
    p.product_category_name,
    COUNT(DISTINCT o.order_id)              AS total_orders,

    -- Delivered count
    COUNT(DISTINCT CASE WHEN o.order_status = 'delivered' 
                        THEN o.order_id END) AS delivered_count,

    -- Canceled count
    COUNT(DISTINCT CASE WHEN o.order_status = 'canceled'  
                        THEN o.order_id END) AS canceled_count,

    -- Delivery rate per category
    CAST(
        COUNT(DISTINCT CASE WHEN o.order_status = 'delivered' THEN o.order_id END)
        * 100.0 / COUNT(DISTINCT o.order_id)
    AS DECIMAL(5,2))                        AS delivery_rate_percent,

    -- Average review score for this category
    ROUND(AVG(CAST(r.review_score AS FLOAT)),2)      AS avg_review_score,

    -- Average price per item in this category
    ROUND(AVG(oi.price),2)                           AS avg_item_price

FROM orders o
JOIN order_items oi  ON o.order_id   = oi.order_id
JOIN products p      ON oi.product_id = p.product_id
LEFT JOIN reviews r  ON o.order_id   = r.order_id
WHERE p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
--HAVING COUNT(DISTINCT o.order_id) > 100     -- only show categories with enough orders
ORDER BY delivery_rate_percent DESC;             -- worst performing categories first

-- INSIGHTS :
-- Categories with low delivery_rate and low avg_review_score are problem areas
-- High price + low review = quality issue or broken product on arrival


-- ============================================================
-- QUERY 10: Monthly Funnel Trend (Time Series Analysis)
-- WHY: Are things getting better or worse over time?
--      This shows whether the business is improving or
--      has seasonal patterns. Recruiters love time trends.
-- ============================================================

SELECT
    -- Extract year and month from order date
    YEAR(order_purchase_timestamp)      AS order_year,
    MONTH(order_purchase_timestamp)     AS order_month,

    -- FORMAT creates a readable label like "2018-01"
    FORMAT(order_purchase_timestamp, 'yyyy-MM') AS year_month,

    COUNT(DISTINCT order_id)            AS total_orders,

    -- Delivered in that month
    COUNT(DISTINCT CASE WHEN order_status = 'delivered' 
                        THEN order_id END) AS delivered_orders,

    -- Canceled in that month
    COUNT(DISTINCT CASE WHEN order_status = 'canceled'  
                        THEN order_id END) AS canceled_orders,

    -- Monthly delivery rate
    CAST(
        COUNT(DISTINCT CASE WHEN order_status = 'delivered' THEN order_id END)
        * 100.0 / COUNT(DISTINCT order_id)
    AS DECIMAL(5,2))                    AS monthly_delivery_rate_pct,

    -- Month-over-month order growth
    -- LAG() looks at the previous row (previous month's count)
    COUNT(DISTINCT order_id) 
    - LAG(COUNT(DISTINCT order_id)) OVER (ORDER BY 
        YEAR(order_purchase_timestamp), 
        MONTH(order_purchase_timestamp)) AS mom_order_change    -- mom = month over month

FROM orders
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY 
    YEAR(order_purchase_timestamp),
    MONTH(order_purchase_timestamp),
    FORMAT(order_purchase_timestamp, 'yyyy-MM')
ORDER BY order_year, order_month;

-- WHAT TO LOOK FOR:
-- Is delivery rate improving month over month?
-- Are there months with sudden drops? (operational issues, holidays)
-- Is volume growing? Flat volume + better delivery rate = good operations


-- ============================================================
-- QUERY 11: Late Delivery Impact on Funnel Completion
-- WHY: Late deliveries are the #1 reason customers don't
--      return. This directly links late delivery to poor
--      review scores = funnel failure at the last step.
-- ============================================================

WITH delivery_flag AS (
    SELECT
        o.order_id,
        o.order_status,
        -- Was this delivered late? 1 = yes, 0 = no
        CASE 
            WHEN o.order_delivered_customer_dt > o.order_estimated_delivery_dt 
            THEN 1 ELSE 0 
        END AS is_late,

        -- How many days late 
        DATEDIFF(DAY, o.order_estimated_delivery_dt, o.order_delivered_customer_dt) 
            AS days_late,

        r.review_score
    FROM orders o
    LEFT JOIN reviews r ON o.order_id = r.order_id
    WHERE o.order_delivered_customer_dt IS NOT NULL
      AND o.order_estimated_delivery_dt IS NOT NULL
)
SELECT
    CASE WHEN is_late = 1 
         THEN 'Late Delivery' 
         ELSE 'On-Time Delivery' 
         END AS delivery_timeliness,

    COUNT(*)                            AS order_count,
    AVG(days_late)                      AS avg_days_late,
    ROUND(AVG(CAST(review_score AS FLOAT)),2)    AS avg_review_score,

    -- What % left a review score of 1 or 2 (very unhappy)?
    CAST(
        SUM(CASE WHEN review_score IN (1,2) THEN 1 ELSE 0 END) * 100.0 
        / COUNT(*)
    AS DECIMAL(5,2))                    AS percent_bad_reviews

FROM delivery_flag
GROUP BY is_late
ORDER BY is_late DESC;

--INSIGHTS :
-- We need to focus on reducing late delivery.
-- Bad Reviews affects business growth and valuation.


-- ============================================================
-- QUERY 12: FINAL EXECUTIVE SUMMARY — Full Funnel Dashboard
-- ============================================================

WITH base AS (
    SELECT
        o.order_id,
        o.order_status,
        o.order_purchase_timestamp,
        o.order_approved_at,
        o.order_delivered_carrier_dt,
        o.order_delivered_customer_dt,
        o.order_estimated_delivery_dt,
        r.review_score,
        p.payment_type,
        oi.price,
        oi.freight_value
    FROM orders o
    LEFT JOIN reviews  r  ON o.order_id   = r.order_id
    LEFT JOIN payments p  ON o.order_id   = p.order_id
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
),
summary AS (
    SELECT
        COUNT(DISTINCT order_id)                                        AS total_orders,

        -- Funnel counts
        COUNT(DISTINCT CASE WHEN order_approved_at IS NOT NULL 
                            THEN order_id END)                          AS approved,
        COUNT(DISTINCT CASE WHEN order_delivered_carrier_dt IS NOT NULL 
                            THEN order_id END)                          AS shipped,
        COUNT(DISTINCT CASE WHEN order_delivered_customer_dt IS NOT NULL 
                            THEN order_id END)                          AS delivered,
        COUNT(DISTINCT CASE WHEN review_score IS NOT NULL 
                            THEN order_id END)                          AS reviewed,
        -- Revenue
        SUM(CASE WHEN order_status = 'delivered' THEN price ELSE 0 END) AS total_revenue,
        -- Speed
        AVG(DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_dt))  AS avg_days_to_deliver,                                                                 
        -- Satisfaction
        AVG(CAST(review_score AS FLOAT))  AS avg_review_score,
        -- Late deliveries
        SUM(CASE WHEN order_delivered_customer_dt > order_estimated_delivery_dt 
                 THEN 1
                  ELSE 0
            END)  AS late_deliveries
    FROM base
)
SELECT
    total_orders,
    approved,
    shipped,
    delivered,
    reviewed,
    CAST(approved  * 100.0 / total_orders AS DECIMAL(5,2)) AS approval_rate_pct,
    CAST(shipped   * 100.0 / total_orders AS DECIMAL(5,2)) AS ship_rate_pct,
    CAST(delivered * 100.0 / total_orders AS DECIMAL(5,2)) AS delivery_rate_pct,
    CAST(reviewed  * 100.0 / delivered    AS DECIMAL(5,2)) AS review_rate_pct,
    total_revenue                    AS total_revenue,
    avg_days_to_deliver,
    CAST(avg_review_score AS DECIMAL(3,2))                 AS avg_review_score,
    late_deliveries,
    CAST(late_deliveries * 100.0 / delivered AS DECIMAL(5,2)) AS late_delivery_percent
FROM summary;

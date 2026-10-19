-- Answer Business Questions

USE Ecommerce_Funnel;
GO
 
 

-- SANITY CHECK : Row Counts Per Table
SELECT 'vw_orders_clean'       AS source, COUNT(*) AS row_count FROM vw_orders_clean       UNION ALL
SELECT 'vw_customers_clean'    AS source, COUNT(*) AS row_count FROM vw_customers_clean    UNION ALL
SELECT 'vw_order_items_clean'  AS source, COUNT(*) AS row_count FROM vw_order_items_clean  UNION ALL
SELECT 'vw_payments_clean'     AS source, COUNT(*) AS row_count FROM vw_payments_clean     UNION ALL
SELECT 'vw_reviews_clean'      AS source, COUNT(*) AS row_count FROM vw_reviews_clean      UNION ALL
SELECT 'vw_products_clean'     AS source, COUNT(*) AS row_count FROM vw_products_clean     UNION ALL
SELECT 'vw_customer_rfm'       AS source, COUNT(*) AS row_count FROM vw_customer_rfm;
 
-- What order status exist?
SELECT
    order_status,
    COUNT(*)  AS total_orders,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS percent_dist
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;
 
-- NULL check on funnel timestamp columns
SELECT
    COUNT(*)  AS total_orders,
    SUM(CASE WHEN order_approved_at          IS NULL THEN 1 ELSE 0 END)      AS never_approved,
    SUM(CASE WHEN order_delivered_carrier_dt IS NULL THEN 1 ELSE 0 END)      AS never_shipped,
    SUM(CASE WHEN order_delivered_customer_dt IS NULL THEN 1 ELSE 0 END)     AS never_delivered
FROM vw_orders_clean;
-- Result : 99441 total | 160 never approved | 1783 never shipped | 2965 never delivered
 
 

-- QUERY 2 : Core Funnel — Stage-by-Stage Drop-off
WITH funnel AS (
    SELECT
        COUNT(DISTINCT o.order_id)                                              AS s1_placed,
        COUNT(DISTINCT CASE WHEN o.order_approved_at IS NOT NULL
                            THEN o.order_id END)                                AS s2_approved,
        COUNT(DISTINCT CASE WHEN o.order_delivered_carrier_dt IS NOT NULL
                            THEN o.order_id END)                                AS s3_shipped,
        COUNT(DISTINCT CASE WHEN o.order_delivered_customer_dt IS NOT NULL
                            THEN o.order_id END)                                AS s4_delivered,
        COUNT(DISTINCT CASE WHEN o.order_delivered_customer_dt IS NOT NULL
                             AND r.review_score IS NOT NULL
                            THEN o.order_id END)                                AS s5_reviewed
    FROM vw_orders_clean o
    LEFT JOIN vw_reviews_clean r ON o.order_id = r.order_id
)
SELECT
    stage, stage_count,
    CAST(stage_count * 100.0 / s1_placed AS DECIMAL(5,2))                      AS percent_of_total,
    CAST(stage_count * 100.0 / LAG(stage_count) OVER (ORDER BY stage_order)
         AS DECIMAL(5,2))                                                       AS percent_from_prev_stage
FROM (
    SELECT 1, 'Stage 1: Placed',    s1_placed,    s1_placed FROM funnel UNION ALL
    SELECT 2, 'Stage 2: Approved',  s2_approved,  s1_placed FROM funnel UNION ALL
    SELECT 3, 'Stage 3: Shipped',   s3_shipped,   s1_placed FROM funnel UNION ALL
    SELECT 4, 'Stage 4: Delivered', s4_delivered, s1_placed FROM funnel UNION ALL
    SELECT 5, 'Stage 5: Reviewed',  s5_reviewed,  s1_placed FROM funnel
) t (stage_order, stage, stage_count, s1_placed)
ORDER BY stage_order;

-- INSIGHTS:
-- Biggest drop is at Stage 3 (Shipped) — 1,623 orders lost there
-- Stage 4→5 also drops: 96,476 delivered but only 36,244 reviewed
 
 
-- QUERY 3 : Conversion Rate 
WITH stage_counts AS (
    SELECT
        COUNT(DISTINCT o.order_id)                                              AS total_placed,
        COUNT(DISTINCT CASE WHEN o.order_approved_at IS NOT NULL
                            THEN o.order_id END)                                AS total_approved,
        COUNT(DISTINCT CASE WHEN o.order_delivered_customer_dt IS NOT NULL
                            THEN o.order_id END)                                AS total_delivered,
        COUNT(DISTINCT CASE WHEN o.order_delivered_customer_dt IS NOT NULL
                             AND r.review_score IS NOT NULL
                            THEN o.order_id END)                                AS total_reviewed
    FROM vw_orders_clean o
    LEFT JOIN vw_reviews_clean r ON o.order_id = r.order_id
)
SELECT
    total_placed, total_approved, total_delivered, total_reviewed,
    CAST(total_delivered * 100.0 / total_placed    AS DECIMAL(5,2))            AS delivery_conv_rate_percent,
    CAST(total_reviewed  * 100.0 / total_delivered AS DECIMAL(5,2))            AS review_rate_percent
FROM stage_counts;
 
 
-- QUERY 4 : Time Between Funnel Stages
SELECT
    AVG(DATEDIFF(HOUR, order_purchase_timestamp, order_approved_at))             AS avg_hours_to_approval,
    AVG(DATEDIFF(DAY,  order_approved_at, order_delivered_carrier_dt))           AS avg_days_approval_to_ship,
    AVG(DATEDIFF(DAY,  order_delivered_carrier_dt, order_delivered_customer_dt)) AS avg_days_ship_to_delivery,
    AVG(DATEDIFF(DAY,  order_purchase_timestamp, order_delivered_customer_dt))   AS avg_total_days_to_deliver
FROM vw_orders_clean    
WHERE order_delivered_customer_dt IS NOT NULL
  AND order_approved_at IS NOT NULL
  AND order_delivered_carrier_dt IS NOT NULL;
 
-- Result : 10 hrs to approval | 2 days to ship | 9 days delivery | 12 days total
-- INSIGHTS:
-- Carrier delivery (9 days) is where most time is lost
-- Focus on last-mile logistics to reduce the 12-day average
 
 
-- QUERY 5 : Revenue by Funnel Stage
SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id)                                                  AS order_count,
    SUM(i.price)                                                                AS total_revenue,
    AVG(i.price)                                                                AS avg_item_price,
    CAST(COUNT(DISTINCT o.order_id) * 100.0 /
         SUM(COUNT(DISTINCT o.order_id)) OVER() AS DECIMAL(5,2))               AS percent_of_orders
FROM vw_orders_clean o
JOIN vw_order_items_clean i ON o.order_id = i.order_id
GROUP BY o.order_status
ORDER BY total_revenue DESC;

-- Delivered revenue only
SELECT
    SUM(i.price)                        AS actual_revenue,
    SUM(i.freight_value)                AS total_freight_collected,
    SUM(i.price + i.freight_value)      AS total_billed_to_customers
FROM vw_orders_clean o
JOIN vw_order_items_clean i ON o.order_id = i.order_id
WHERE o.order_status = 'delivered';
 
 
-- QUERY 6 : Payment Method Analysis
SELECT
    p.payment_type,
    COUNT(DISTINCT o.order_id)                                                  AS total_orders,
    COUNT(DISTINCT CASE WHEN o.order_status = 'delivered'
                        THEN o.order_id END)                                    AS delivered_orders,
    CAST(
        COUNT(DISTINCT CASE WHEN o.order_status = 'delivered' THEN o.order_id END)
        * 100.0 / COUNT(DISTINCT o.order_id)
    AS DECIMAL(5,2))                                                            AS delivery_rate_percent,
    ROUND(AVG(p.payment_value), 2)                                              AS avg_payment_value,
    ROUND(AVG(CAST(p.payment_installments AS FLOAT)), 0)                        AS avg_installments
FROM vw_orders_clean o
JOIN vw_payments_clean p ON o.order_id = p.order_id
GROUP BY p.payment_type
ORDER BY total_orders DESC;
 
-- INSIGHTS:
-- Credit card dominates at 74% of orders with highest delivery rate
-- Boleto users have lower delivery rate — possible payment abandonment
 

-- QUERY 7 : Review Score vs Delivery Speed
-- CHANGE : FROM vw_master_orders → vw_orders_clean + vw_reviews_clean
SELECT
    r.review_score,
    COUNT(DISTINCT o.order_id)                                                  AS order_count,
    AVG(DATEDIFF(DAY, o.order_purchase_timestamp,
                 o.order_delivered_customer_dt))                              AS avg_days_to_deliver,
    ROUND(AVG(CASE
                  WHEN o.order_delivered_customer_dt
                       <= o.order_estimated_delivery_dt
                  THEN 1.0 ELSE 0.0
              END) * 100, 2)                                                    AS percent_delivered_on_time
FROM vw_orders_clean o
JOIN vw_reviews_clean r ON o.order_id = r.order_id
WHERE o.order_delivered_customer_dt IS NOT NULL
GROUP BY r.review_score
ORDER BY r.review_score DESC;
 
-- INSIGHTS:
-- Score 1 orders average 28 days | Score 5 orders average 10 days
-- Delivery speed is the single strongest driver of review score
 

-- QUERY 8 : Repeat Customers — Loyalty Analysis
SELECT
    rfm_segment                                             AS customer_segment,
    COUNT(*)                                                AS customer_count,
    ROUND(AVG(monetary), 2)                                 AS avg_total_spent,
    ROUND(AVG(CAST(recency_days AS FLOAT)), 0)              AS avg_days_since_last_order,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()
         AS DECIMAL(5,2))                                   AS percent_of_customers
FROM vw_customer_rfm   
GROUP BY rfm_segment
ORDER BY avg_total_spent DESC;
 
-- INSIGHTS:
-- Champions and Loyal customers spend the most per order
-- 90%+ of customers are one-time buyers — retention is the biggest opportunity
 

-- QUERY 9 : Category-Level Funnel Performance
SELECT TOP 20
    p.product_category_name,
    COUNT(DISTINCT o.order_id)                                                  AS total_orders,
    COUNT(DISTINCT CASE WHEN o.order_status = 'delivered'
                        THEN o.order_id END)                                    AS delivered_count,
    COUNT(DISTINCT CASE WHEN o.order_status = 'canceled'
                        THEN o.order_id END)                                    AS canceled_count,
    CAST(
        COUNT(DISTINCT CASE WHEN o.order_status = 'delivered' THEN o.order_id END)
        * 100.0 / COUNT(DISTINCT o.order_id)
    AS DECIMAL(5,2))                                                            AS delivery_rate_percent,
    ROUND(AVG(CAST(r.review_score AS FLOAT)), 2)                                AS avg_review_score,
    ROUND(AVG(i.price), 2)                                                      AS avg_item_price
FROM vw_orders_clean o
JOIN vw_order_items_clean i  ON o.order_id   = i.order_id
JOIN vw_products_clean p     ON i.product_id = p.product_id
LEFT JOIN vw_reviews_clean r ON o.order_id   = r.order_id
WHERE p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
ORDER BY delivery_rate_percent DESC;
-- INSIGHTS:
-- Categories with low delivery_rate + low avg_review_score are problem areas
-- High avg_order_revenue + high canceled_count = revenue at risk
 
 

-- QUERY 10 : Monthly Funnel Trend 
SELECT
    YEAR(order_purchase_timestamp)                                              AS order_year,
    MONTH(order_purchase_timestamp)                                             AS order_month,
    FORMAT(order_purchase_timestamp, 'yyyy-MM')                                 AS year_month,
    COUNT(DISTINCT order_id)                                                    AS total_orders,
    COUNT(DISTINCT CASE WHEN order_status = 'delivered'
                        THEN order_id END)                                      AS delivered_orders,
    COUNT(DISTINCT CASE WHEN order_status = 'canceled'
                        THEN order_id END)                                      AS canceled_orders,
    CAST(
        COUNT(DISTINCT CASE WHEN order_status = 'delivered' THEN order_id END)
        * 100.0 / COUNT(DISTINCT order_id)
    AS DECIMAL(5,2))                                                            AS monthly_delivery_rate_pct,
    COUNT(DISTINCT order_id)
    - LAG(COUNT(DISTINCT order_id)) OVER (ORDER BY
        YEAR(order_purchase_timestamp),
        MONTH(order_purchase_timestamp))                                        AS mom_order_change
FROM vw_orders_clean
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY
    YEAR(order_purchase_timestamp),
    MONTH(order_purchase_timestamp),
    FORMAT(order_purchase_timestamp, 'yyyy-MM')
ORDER BY order_year, order_month;

-- INSIGHTS:
-- Steady growth through 2017 into early 2018
-- Months where orders grew but delivery rate dropped = logistics not scaling
 
 

-- QUERY 11 : Late Delivery Impact
SELECT
    is_late                                                                         AS delivery_timeliness,
    COUNT(*)                                                                        AS order_count,
    AVG(DATEDIFF(DAY, order_estimated_delivery_dt,
                 order_delivered_customer_dt))                                      AS avg_days_late,
    ROUND(AVG(CAST(review_score AS FLOAT)), 2)                                      AS avg_review_score,
    CAST(
        SUM(CASE WHEN review_score IN (1,2) THEN 1 ELSE 0 END) * 100.0
        / COUNT(*)
    AS DECIMAL(5,2))                                                                AS percent_bad_reviews
FROM vw_orders_clean o             
LEFT JOIN vw_reviews_clean r ON o.order_id = r.order_id
WHERE order_delivered_customer_dt IS NOT NULL
  AND order_estimated_delivery_dt IS NOT NULL
GROUP BY is_late
ORDER BY is_late DESC;
 
-- INSIGHTS:
-- Late deliveries average 2.5 stars | On-time deliveries average 4.3 stars
-- Reducing late deliveries is the single highest-impact operational fix
 
 

-- QUERY 12 : Executive Summary — Full Funnel Dashboard
WITH base AS (
    SELECT
        o.order_id,
        o.order_status,
        o.order_purchase_timestamp,
        o.order_approved_at,
        o.order_delivered_carrier_dt,
        o.order_delivered_customer_dt,
        o.order_estimated_delivery_dt,
        o.days_to_deliver,
        o.is_late,
        r.review_score,
        p.payment_type,
        i.price,
        i.freight_value
    FROM vw_orders_clean o
    LEFT JOIN vw_reviews_clean    r ON o.order_id = r.order_id
    LEFT JOIN vw_payments_clean   p ON o.order_id = p.order_id
    LEFT JOIN vw_order_items_clean i ON o.order_id = i.order_id
),
summary AS (
    SELECT
        COUNT(DISTINCT order_id)                                                AS total_orders,
        COUNT(DISTINCT CASE WHEN order_approved_at IS NOT NULL
                            THEN order_id END)                                  AS approved,
        COUNT(DISTINCT CASE WHEN order_delivered_carrier_dt IS NOT NULL
                            THEN order_id END)                                  AS shipped,
        COUNT(DISTINCT CASE WHEN order_delivered_customer_dt IS NOT NULL
                            THEN order_id END)                                  AS delivered,
        COUNT(DISTINCT CASE WHEN review_score IS NOT NULL
                            THEN order_id END)                                  AS reviewed,
        SUM(CASE WHEN order_status = 'delivered'
                 THEN price ELSE 0 END)                                         AS total_revenue,
        AVG(days_to_deliver)                                                    AS avg_days_to_deliver,
        AVG(CAST(review_score AS FLOAT))                                        AS avg_review_score,
        SUM(CASE WHEN is_late = 'Late' THEN 1 ELSE 0 END)                      AS late_deliveries
    FROM base
)
SELECT
    total_orders, approved, shipped, delivered, reviewed,
    CAST(approved  * 100.0 / total_orders AS DECIMAL(5,2))                     AS approval_rate_pct,
    CAST(shipped   * 100.0 / total_orders AS DECIMAL(5,2))                     AS ship_rate_pct,
    CAST(delivered * 100.0 / total_orders AS DECIMAL(5,2))                     AS delivery_rate_pct,
    CAST(reviewed  * 100.0 / delivered    AS DECIMAL(5,2))                     AS review_rate_pct,
    total_revenue,
    avg_days_to_deliver,
    CAST(avg_review_score AS DECIMAL(3,2))                                      AS avg_review_score,
    late_deliveries,
    CAST(late_deliveries * 100.0 / delivered AS DECIMAL(5,2))                  AS late_delivery_percent
FROM summary;
 








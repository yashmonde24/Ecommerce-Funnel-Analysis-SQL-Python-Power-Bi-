-- Data Cleaning and Transformation and Prepartion

USE Ecommerce_Funnel;
GO

-- VIEW 1 : Orders
-- Adds: days_to_deliver, is_late, is_delivered flags

CREATE VIEW vw_orders_clean AS
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_dt,
    order_delivered_customer_dt,
    order_estimated_delivery_dt,

    DATEDIFF(DAY,
        order_purchase_timestamp,
        order_delivered_customer_dt)          AS days_to_deliver,

    CASE
        WHEN order_delivered_customer_dt
             > order_estimated_delivery_dt
        THEN 'Late'
        ELSE 'On Time'
    END                                         AS is_late,

    CASE
        WHEN order_delivered_customer_dt IS NOT NULL
        THEN 'Delivered'
        ELSE 'Not Delivered'
    END                                         AS is_delivered

FROM orders
WHERE order_status IS NOT NULL;
GO


-- VIEW 2 : customers 
-- Standardises city and state casing

CREATE VIEW vw_customers_clean AS
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code,
    UPPER(TRIM(customer_state))                 AS customer_state,
    LOWER(TRIM(customer_city))                  AS customer_city
FROM customers;
GO


--  VIEW 3 :order_items
-- Adds total_value per line item

CREATE VIEW vw_order_items_clean AS
SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    price,
    freight_value,
    price + freight_value                       AS line_total
FROM order_items;
GO


-- VIEW 4 : payments
-- Deduplicates to primary payment per order

CREATE VIEW vw_payments_clean AS
SELECT
    order_id,
    payment_type,
    payment_value,
    payment_installments
FROM (
    SELECT
        order_id,
        payment_type,
        payment_value,
        payment_installments,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY payment_sequential ASC
        ) AS rn
    FROM payments
    WHERE payment_type IS NOT NULL
) t
WHERE rn = 1;
GO


--VIEW 5 : reviews
-- Deduplicates to first review per order

CREATE VIEW vw_reviews_clean AS
SELECT
    order_id,
    review_id,
    review_score,
    review_creation_date,
    review_answer_timestamp
FROM (
    SELECT
        order_id,
        review_id,
        review_score,
        review_creation_date,
        review_answer_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY review_answer_timestamp ASC
        ) AS rn
    FROM reviews
) t
WHERE rn = 1;
GO


-- VIEW 6 : products
-- Handles NULL category names

CREATE VIEW vw_products_clean AS
SELECT
    product_id,
    ISNULL(product_category_name, 'Unknown')    AS product_category_name,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM products;
GO


-- VIEW 7 :customer_rfm
-- Only view that joins tables — intentionally

CREATE VIEW vw_customer_rfm AS
WITH rfm_base AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id)              AS frequency,
        SUM(i.price)                            AS monetary,
        DATEDIFF(DAY,
            MAX(o.order_purchase_timestamp),
            GETDATE())                          AS recency_days
    FROM vw_orders_clean     o
    JOIN vw_customers_clean  c ON o.customer_id  = c.customer_id
    JOIN vw_order_items_clean i ON o.order_id    = i.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    customer_unique_id,
    frequency,
    monetary,
    recency_days,
    CASE
        WHEN frequency >= 3 AND monetary >= 500 THEN 'Champion'
        WHEN frequency >= 2                     THEN 'Loyal'
        WHEN recency_days <= 180                THEN 'At Risk'
        ELSE                                         'Lost'
    END                                         AS rfm_segment
FROM rfm_base;
GO
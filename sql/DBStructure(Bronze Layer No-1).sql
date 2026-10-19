-- Database Structure

-- Step 1: Create the database 
CREATE DATABASE Ecommerce_Funnel;
GO

USE Ecommerce_Funnel;
GO

-- TABLE 1: customers
-- One row per customer. Stores location info.
IF OBJECT_ID('customers', 'U') IS NOT NULL
    DROP TABLE customers;
GO
CREATE TABLE customers (
    customer_id             VARCHAR(50)     PRIMARY KEY,
    customer_unique_id      VARCHAR(50)     NOT NULL,
    customer_zip_code       VARCHAR(10),
    customer_city           VARCHAR(100),
    customer_state          VARCHAR(10)
);
GO


-- TABLE 2: orders
-- One row per order. This is the CORE table.
-- It has timestamps for every funnel stage.
IF OBJECT_ID('orders', 'U') IS NOT NULL
    DROP TABLE orders;
GO
CREATE TABLE orders (
    order_id                    VARCHAR(50)     PRIMARY KEY,
    customer_id                 VARCHAR(50)     NOT NULL,
    order_status                VARCHAR(30),       
    order_purchase_timestamp    DATETIME,          
    order_approved_at           DATETIME,          
    order_delivered_carrier_dt  DATETIME,          
    order_delivered_customer_dt DATETIME,           
    order_estimated_delivery_dt DATETIME           
);
GO

-- TABLE 3: order_items
-- One order can have multiple items.
-- Stores price and freight per item.
IF OBJECT_ID('order_items', 'U') IS NOT NULL
    DROP TABLE order_items;
GO
CREATE TABLE order_items (
    order_id            VARCHAR(50)     NOT NULL,
    order_item_id       INT             NOT NULL,  
    product_id          VARCHAR(50),
    seller_id           VARCHAR(50),
    shipping_limit_date DATETIME,
    price               DECIMAL(10,2),
    freight_value       DECIMAL(10,2),
    CONSTRAINT pk_order_items PRIMARY KEY (order_id, order_item_id)
);
GO


-- TABLE 4: products
-- Product catalog with category info.
IF OBJECT_ID('products', 'U') IS NOT NULL
    DROP TABLE products;
GO
CREATE TABLE products (
    product_id                  VARCHAR(50)     PRIMARY KEY,
    product_category_name       VARCHAR(100),
    product_name_length         INT,
    product_description_length  INT,
    product_photos_qty          INT,
    product_weight_g            DECIMAL(10,2),
    product_length_cm           DECIMAL(10,2),
    product_height_cm           DECIMAL(10,2),
    product_width_cm            DECIMAL(10,2)
);
GO


-- TABLE 5: payments
-- One order can have multiple payment rows
IF OBJECT_ID('payments', 'U') IS NOT NULL
    DROP TABLE payments;
GO
CREATE TABLE payments (
    order_id                VARCHAR(50)     NOT NULL,
    payment_sequential      INT             NOT NULL,   
    payment_type            VARCHAR(30),                -- credit_card, boleto, voucher, debit_card
    payment_installments    INT,                        -- number of installments chosen
    payment_value           DECIMAL(10,2),
    CONSTRAINT pk_payments PRIMARY KEY (order_id, payment_sequential)
);
GO

-- TABLE 6: reviews
-- Customer review after delivery.
-- Score 1-5. Represents final funnel stage engagement.
IF OBJECT_ID('reviews', 'U') IS NOT NULL
    DROP TABLE reviews;
GO
CREATE TABLE reviews (
    review_id               VARCHAR(50),
    order_id                VARCHAR(50)     NOT NULL,
    review_score            INT,                    -- 1 to 5
    review_comment_title    VARCHAR(255),
    review_comment_message  VARCHAR(MAX),
    review_creation_date    DATETIME,
    review_answer_timestamp DATETIME
);
GO


-- VERIFICATION: Check all tables were created
SELECT 
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_CATALOG = 'Ecommerce_Funnel'
ORDER BY TABLE_NAME;
GO

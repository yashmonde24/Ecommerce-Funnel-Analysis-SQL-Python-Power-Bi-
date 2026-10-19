# E-Commerce Orders Funnel Analysis - Where Do Customers Drop Off And Why ?

# 1. Background and Overview

Most e-commerce reports stop at total orders and total revenue. This project goes further — it follows each order from placement through approval, shipping, delivery, and review to find exactly where the leaks are.

The analysis runs across three tools: SQL for the database and business queries, Python for deeper analysis and visualisation and Power BI for a one-page interactive dashboard.

The central question: where do orders drop off between being placed and reaching the customer?

The analysis covers the full workflow — database design in SQL, exploratory analysis in Python, and a one-page interactive dashboard in Power BI.

Problem Statement :
An e-commerce business cannot fix what it cannot see. This platform had no clear picture of how many orders were falling apart between being placed and reaching the customer — or why. Bad reviews were piling up, customers were not returning, and delivery problems in certain regions were going unnoticed behind a healthy-looking headline number.

Objective :
Track every order across all 5 stages of the buying journey, find where and why customers are dropping off, prove the findings statistically, and give the business a clear set of actions backed by data.


# 2. Data Structure Overview

- Source: Olist Brazilian E-Commerce Dataset — Kaggle Size: 99,441 orders across 6 tables

- File	What it contains
  - olist_orders_dataset.csv:	Every order with a timestamp for each funnel stage
  - olist_order_items_dataset.csv:	Products inside each order, with price and freight
  - olist_customers_dataset.csv:	Customer city and state
  - olist_products_dataset.csv: Product names and categories
  - olist_order_payments_dataset.csv:	Payment method and amount paid
  - olist_order_reviews_dataset.csv:	Customer review score from 1 to 5

- How the tables connect: The orders table sits at the centre. Every other table links to it through order_id or customer_id. The project follows Medallion Architecture — raw data loads into Bronze tables, a Silver layer of SQL views handles transformation and deduplication per table, and Power BI and Python read from Silver Layer views. This keeps the Star Schema intact in Power BI while ensuring no raw data reaches the reporting layer directly.

- Project files:

  - Tool	File	Purpose :

     - MS SQL Server DBStructure(Bronze Layer No-1).sql Creates the database & table structure
     - MS SQL Server Data_Loading(Bronze Layer No-1).sql Loads data into each table
     - MS SQL Server Data Preparation (Silver Layer No -2).sql - Data Transformation & Deduplication per table
     - MS SQL Server Data_Analysis_Reporting(Gold Layer No -3).sql All business analysis queries
     - Python ecommerce_funnel_eda.ipynb Full exploratory data analysis
     - Power BI reporting.pbix One-page interactive dashboard
   - 
## 3. Executive Summary

The business delivers 97% of orders successfully. But two problems sit underneath that number.

Orders that arrived late averaged 2.5 stars. Orders that arrived on time averaged 4.3 stars. That gap is not random — it was confirmed statistically. And more than 90% of customers never placed a second order, making the business almost entirely dependent on new buyers, which is an expensive way to grow.

The funnel :

1. Order Placed (100%) 
2. Approved (99.84%) 
3. Shipped (98.21%) 
4. Delivered (97.02%) 
5. Reviewed (96.37%)
                     

The biggest single drop happens at the Shipped stage — 1,623 orders fell off there, the largest absolute drop across all 5 stages.

## 4. Insights Deep Dive

- Delivery speed and satisfaction :
Orders rated 1 star took an average of 28 days to arrive. Orders rated 5 stars took 10    days. A regression model confirmed this — every extra day of delivery drops the   predicted review score, and the relationship is statistically significant (p < 0.05).

- State-level delivery problems :
The national late delivery rate is around 8%. Amazonas (AM) sits at 31% and Roraima (RR) is close behind. These are not small variations — they point to a logistics failure that the national average hides entirely.

- Payment behaviour :
Credit card was used in 74% of orders and had the strongest delivery record. Voucher users left a disproportionate share of 1 and 2-star reviews. Whether this is a delivery issue or a product expectation mismatch needs further investigation.

- Customer retention :
The RFM analysis showed that Champions and Loyal Customers — the small group who came back — spent significantly more per order on average. But they make up a tiny fraction of the base. More than 90% of customers are one-time buyers.

- Category performance:
Bed and Bath, Health and Beauty and Computers led on order volume. Computers and Watches had high revenue but also higher cancellation rates — a cancellation in a high-value category costs more than one in a low-value one.

## 5. Recommendations

- Fix delivery in AM and RR first :
A 31% late delivery rate in AM is not noise. The business should audit its carrier partnerships in the north and northeast and set region-specific targets.

- Set a 10-day delivery target :
The regression shows that orders delivered within 10 days consistently score above 4 stars. This is a concrete, measurable operational goal.

- Add a second-purchase trigger :
A simple discount or offer within 2 weeks of first delivery is a low-cost starting point for pulling the 90% one-time buyer rate down.

- Investigate voucher order experience :
Voucher users leave more bad reviews. Check whether these orders skew toward slower delivery routes or specific product categories before drawing conclusions.

- Protect revenue in high-cancellation categories :
Computers and Watches drive significant revenue. Even a small improvement in their cancellation rate would have an outsized impact on total revenue.

## 6. Assumptions and Limitations
- All analysis is based on historical data. Patterns found here may not reflect current operations.
- The dataset does not include return or refund data. Orders marked as delivered may still have had post-delivery issues not captured here.
- Product category names are in Portuguese. Some were left untranslated, which may affect readability of category-level charts.
- The late delivery flag was calculated by comparing actual delivery date against the estimated delivery date in the dataset. If those estimates were already        inflated, the true late rate could be higher.
- Repeat customer analysis is based on customer_unique_id. Customers who used different emails or accounts for different orders would be counted as new buyers.

## 7. Future Enhancements
- Add return and refund data for a complete post-delivery picture.
- Add seller-level analysis — the dataset includes seller data not used in this version.
- Build a time series forecast for monthly order volume to help plan logistics capacity ahead of peak periods.

## 8. Deliverables
- DBStructure.sql	Full DDL script : creates database and all 6 tables
- Data_Loading.sql:	Loads all CSV data into the database
- Data_Analysis_Reporting.sql:	Business queries covering funnel, revenue, delivery, payments, and trends
- ecommerce_funnel_eda.ipynb:	Python notebook with data cleaning, merging, and 10 charts
- reporting.pbix:	One-page Power BI dashboard with 10 visuals, DAX measures, and slicers
- README.md:	Full project documentation

## 9. Outcomes Preview :
- Dashboard : https://github.com/yashmonde24/Ecommerce-Funnel-Analysis-SQL-Python-Power-Bi-/blob/main/powerbi/Powerbi_Outcomes/Dashboard.jpg
- EDA Visualization : https://github.com/yashmonde24/Ecommerce-Funnel-Analysis-SQL-Python-Power-Bi-/tree/main/notebook/EDA_outcomes
- Query Summary : https://github.com/yashmonde24/Ecommerce-Funnel-Analysis-SQL-Python-Power-Bi-/blob/main/notebook/EDA_outcomes/Quick%20Summary.jpg



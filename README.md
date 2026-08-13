# E-Commerce Funnel Analysis — End-to-End Data Analyst Project

Tools: MS SQL Server · Python (Jupyter Notebook) · Power BI Dataset: Olist Brazilian E-Commerce — Kaggle

# 1. Background and Overview

E-commerce businesses lose customers at every step — from placing an order to actually receiving it. Most companies know their total sales number. Very few know exactly where in the process things break down.

This project picks up that problem. I used a real dataset from Olist, a Brazilian marketplace, to track 100,000+ orders across every stage of the buying journey and find where and why customers were falling off.

The central question: where do orders drop off between being placed and reaching the customer?

The analysis covers the full workflow — database design in SQL, exploratory analysis in Python, and a one-page interactive dashboard in Power BI.

# 2. Data Structure Overview

Source: Olist Brazilian E-Commerce Dataset — Kaggle Size: ~100,000 orders across 6 tables

File	What it contains
olist_orders_dataset.csv:	Every order with a timestamp for each funnel stage
olist_order_items_dataset.csv:	Products inside each order, with price and freight
olist_customers_dataset.csv:	Customer city and state
olist_products_dataset.csv: Product names and categories
olist_order_payments_dataset.csv:	Payment method and amount paid
olist_order_reviews_dataset.csv:	Customer review score from 1 to 5

How the tables connect: The orders table sits at the centre. Every other table links to it through order_id or customer_id. This structure was replicated as a Star Schema in the Power BI data model.

Project files:

Tool	File	Purpose
MS SQL Server	DBStructure.sql	Creates the database and all 6 tables
MS SQL Server	Data_Loading.sql	Loads data into each table
MS SQL Server	Data_Analysis_Reporting.sql	All business analysis queries
Python	ecommerce_funnel_eda.ipynb	Full exploratory data analysis
Power BI reporting.pbix	One-page interactive dashboard

## 3. Executive Summary

The business is operationally solid — 97% of orders were delivered successfully. But two problems stand out clearly when you look past that headline number.

First, delivery speed has a direct impact on customer satisfaction. Orders that arrived late averaged a 2.5-star review. Orders that arrived on time averaged 4.3. That gap does not close on its own.

Second, 90%+ of customers never placed a second order. The business is almost entirely dependent on new customers. That is an expensive way to grow.

The funnel at a glance:

Order Placed -> Approved -> Shipped -> Delivered -> Reviewed
   100%          96%        93%        87%         72%

The biggest single drop happens between Delivered and Reviewed — 15 percentage points. Customers receive the order but do not engage after. This matters because reviews drive future buyer trust.

## 4. Insights Deep Dive

- Delivery and satisfaction Late orders averaged 28 days to arrive. Orders that got a 5-star review averaged 10 days. The relationship is consistent across the      data — the longer the wait, the lower the score. This is not a coincidence; it held across payment types and product categories.

- State-level delivery problems The national late delivery rate sits at around 8%. But Amazonas (AM) was at 31% and Roraima (RR) was close behind. These are not     small rounding errors — they point to a logistics failure in specific regions that the overall average hides.

- Payment behaviour Credit card was used in 74% of orders and had the highest delivery success rate. Voucher users, on the other hand, left a disproportionately     high share of 1 and 2-star reviews. This could be a delivery issue, a product expectation mismatch, or both — but it needs a closer look.

- Customer retention More than 90% of customers bought once and left. The ones who did return spent significantly more on average. That gap in spend between one-    time and repeat buyers makes retention the single highest-leverage opportunity in the dataset.

- Category performance Bed and Bath, Health and Beauty, and Computers were the top revenue categories. Computers and Watches had high revenue but also a higher      cancellation rate than other categories. A cancellation in a high-value category costs more than a cancellation in a low-value one.

## 5. Recommendations

- Fix delivery in AM and RR first A 31% late delivery rate in AM is not a blip. The business should audit its carrier partnerships in the north and northeast        states and set region-specific delivery targets.

- Set a 10-day delivery target The data shows that orders delivered within 10 days consistently get 4-star+ reviews. This is a concrete operational target, not a    vague goal.

- Add a second-purchase trigger 90% one-time buyers is a retention problem with a straightforward starting fix. A discount or personalised offer after first         delivery — timed within 2 weeks — is a standard and low-cost way to start pulling that number down.

- Investigate voucher order experience Voucher users are leaving more bad reviews. Before writing this off as a payment issue, check whether voucher orders skew     toward longer delivery routes or lower-rated product categories.

- Protect revenue in high-cancellation categories Computers and Watches drive significant revenue. Even a modest improvement in their cancellation rate would have   an outsized effect on total revenue. These categories deserve their own delivery SLA.

## 6. Assumptions and Limitations
- All analysis is based on historical data. Patterns found here may not reflect current operations.
- The dataset does not include return or refund data. Orders marked as delivered may still have had post-delivery issues not captured here.
- Product category names are in Portuguese. Some were left untranslated, which may affect readability of category-level charts.
- The late delivery flag was calculated by comparing actual delivery date against the estimated delivery date in the dataset. If those estimates were already        inflated, the true late rate could be higher.
- Repeat customer analysis is based on customer_unique_id. Customers who used different emails or accounts for different orders would be counted as new buyers.

## 7. Future Enhancements
- Add return and refund data to get a complete picture of post-delivery customer experience.
- Build a customer segmentation model in Python using RFM scoring — Recency, Frequency, Monetary — to identify which one-time buyers are most likely to return       with the right nudge.
- Automate the dashboard by connecting Power BI to a live SQL database instead of static CSV files, so the report updates without manual refreshes.
- Add a seller-level analysis to find which sellers have the worst delivery times and review scores — the Olist dataset includes seller data that this project did   not use.
- Forecast monthly order volume using a simple time series model to help the business plan logistics capacity ahead of peak seasons.

## 8. Deliverables
- DBStructure.sql	Full DDL script : creates database and all 6 tables
- Data_Loading.sql:	Loads all CSV data into the database
- Data_Analysis_Reporting.sql:	Business queries covering funnel, revenue, delivery, payments, and trends
- ecommerce_funnel_eda.ipynb:	Python notebook with data cleaning, merging, and 10 charts
- reporting.pbix:	One-page Power BI dashboard with 10 visuals, DAX measures, and slicers
- README.md:	Full project documentation

## Outcomes Preview :
- Dashboard : https://github.com/yashmonde24/Ecommerce-Funnel-Analysis-SQL-Python-Power-Bi-/blob/main/powerbi/Powerbi_Outcomes/Dashboard.jpg
- EDA Visualization : https://github.com/yashmonde24/Ecommerce-Funnel-Analysis-SQL-Python-Power-Bi-/tree/main/notebook/EDA_outcomes
- Query Summary : https://github.com/yashmonde24/Ecommerce-Funnel-Analysis-SQL-Python-Power-Bi-/blob/main/notebook/EDA_outcomes/Quick%20Summary.jpg



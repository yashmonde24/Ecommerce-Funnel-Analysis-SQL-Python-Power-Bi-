#  E-Commerce Funnel Analysis  End-to-End Data Analyst Project

##  What is This Project?

This is a full **end-to-end data analyst project** built on real e-commerce data.

The goal was simple : answer one business question:

 **"Where do customers drop off between placing an order and receiving it?"**

  That's called **Funnel Analysis**. It tracks how customers move through each step —
  from placing an order -> getting it approved -> shipped  delivered -> leaving a review.
  At every step, some orders fall off. This project finds where, why, and what it costs.


 **Tools Used:** MS SQL Server | Python ( Google Colab / Jupyter  ) | Power BI  
 **Dataset:** Olist Brazilian E-Commerce — [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)  
 

### Data Files 
*`olist_orders_dataset.csv` -  Every order with timestamps for each funnel stage 
*`olist_order_items_dataset.csv` - Items in each order — price, product 
*`olist_customers_dataset.csv` - Customer city and state 
*`olist_products_dataset.csv` - Product names and categories 
*`olist_order_payments_dataset.csv` - Payment method and amount
*`olist_order_reviews_dataset.csv` - Customer review score (1–5) 

---

##  Tools & Files

 * MS SQL Server  (`DBStructure.sql`) - Created database and all 6 tables from scratch 
 * MS SQL Server  (`Data_Loading.sql`) - Inserted Data into each table 
 * MS SQL Server  (`Data_Analysis_Reporting.sql`) - Business analysis queries 
 * Python  (`ecommerce_funnel_eda.ipynb`) -  Exploratory Data Analysis 
 * Power BI  (`reporting.pbix`) -  Interactive dashboard 


##  The Funnel — 5 Stages

Stage 1 (Order Placed)  ->  Stage 2  (Payment Approved)  ->  Stage 3 (Handed to Carrier)  ->  Stage 4 (Delivered  to Customer)  ->   Stage 5 (Customer Reviews)     

##  Key Insights

- **97%** of orders were successfully delivered.
- **Late deliveries** had significantly lower review scores — orders delivered late averaged 2.5 stars vs 4.3 stars for on-time orders.
- **Credit card** was used in 74% of orders and had the highest delivery rate.
- **90%+** of customers were one-time buyers — very low repeat customer rate.
- **Amazon state (AM)** had the worst late delivery rate at 31% — a clear logistics problem.
- Orders with **review score 1** took on average **28 days** to deliver vs **10 days** for score 5.

## Recommendations

1. Improve delivery in problem states
States like AM and RR have very high late delivery rates. The business should review its logistics partners there and fix the root cause.

2. Set a delivery speed target
Faster delivery directly led to better reviews in the data. Targeting delivery within 10 days would likely improve customer satisfaction across the board.

3. Bring customers back
90%+ of customers only bought once. A simple discount or offer on the second order could turn one-time buyers into repeat ones.

4. Investigate voucher orders
Voucher users left more bad reviews than credit card users. It is worth checking whether these orders have longer delivery times or different product types.

5. Protect high-value categories
Computers and Watches generate high revenue but also have higher cancellation rates. Fixing delivery for just these categories would have an outsized impact on total revenue

## Outcomes Preview :
- Dashboard : https://github.com/yashmonde24/Ecommerce-Funnel-Analysis-SQL-Python-Power-Bi-/blob/main/powerbi/Powerbi_Outcomes/Dashboard.jpg




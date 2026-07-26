---INSERTING DATA INTO TABLE ------
USE Ecommerce_Funnel
GO
CREATE or ALTER PROCEDURE  Ecommerce_Funnel_Procedure AS
BEGIN 
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '================================================';
		PRINT 'Loading Ecommerce Funnel Layer';
		PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading  Customers Table';
		PRINT '------------------------------------------------';
		PRINT '>> Truncating Table: customers'
		TRUNCATE TABLE customers;
		PRINT '>> Inserting Data Into: customers';
		BULK INSERT customers
		FROM 'C:\SQL PROJECTS\SQL ANALYSIS\olist_customers_dataset.csv'
		WITH(
			FIRSTROW= 2,
			FIELDTERMINATOR= ',',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		PRINT '------------------------------------------------';
		PRINT 'Loading Orders Table';
		PRINT '------------------------------------------------';
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: orders'
		TRUNCATE TABLE orders;
		PRINT '>> Inserting Data Into: orders';
		BULK INSERT orders
		FROM 'C:\SQL PROJECTS\SQL ANALYSIS\olist_orders_dataset.csv'
		WITH(
			FIRSTROW= 2,
			FIELDTERMINATOR= ',',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';


		PRINT '------------------------------------------------';
		PRINT 'Loading Order_Items Table';
		PRINT '------------------------------------------------';
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: order_items'
		TRUNCATE TABLE order_items;
		PRINT '>> Inserting Data Into: order_items';
		BULK INSERT order_items
		FROM 'C:\SQL PROJECTS\SQL ANALYSIS\olist_order_items_dataset.csv'
		WITH(
			FIRSTROW= 2,
			FIELDTERMINATOR= ',',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		PRINT '------------------------------------------------';
		PRINT 'Loading Products Table';
		PRINT '------------------------------------------------';
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: products'
		TRUNCATE TABLE products;
		PRINT '>> Inserting Data Into: products';
		BULK INSERT products
		FROM 'C:\SQL PROJECTS\SQL ANALYSIS\olist_products_dataset.csv'
		WITH(
			FIRSTROW= 2,
			FIELDTERMINATOR= ',',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		PRINT '------------------------------------------------';
		PRINT 'Loading Payment Table';
		PRINT '------------------------------------------------';
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: payments'
		TRUNCATE TABLE payments;
		PRINT '>> Inserting Data Into: payments';
		BULK INSERT payments
		FROM 'C:\SQL PROJECTS\SQL ANALYSIS\olist_order_payments_dataset.csv'
		WITH(
			FIRSTROW= 2,
			FIELDTERMINATOR= ',',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		------- Used Import Flat File for inserting data into reviews table
		/* 
		PRINT '>> Truncating Table: reviews'
		TRUNCATE TABLE reviews ;
		BULK INSERT reviews 
		FROM 'C:\SQL PROJECTS\SQL ANALYSIS\olist_order_reviews_dataset.csv'
		WITH(
			FIRSTROW= 2,
			FIELDTERMINATOR= ',',
			ROWTERMINATOR = '0x0a',
			CODEPAGE = '65001',
			TABLOCK
		); 
		*/
		SET @batch_end_time = GETDATE();
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END 

GO

Select * From customers;
Select * From orders;
Select * From order_items;
Select * From products;
Select * From payments;
Select * From reviews;

EXEC Ecommerce_Funnel_Procedure;
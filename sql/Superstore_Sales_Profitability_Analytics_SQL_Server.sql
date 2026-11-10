/*
Project: Superstore Sales & Profitability Analytics
Database: Microsoft SQL Server
Table: dbo.superstore

This is SQL Server (T-SQL), not PostgreSQL syntax.
Expected columns (based on the imported table):
Row_ID, Order_ID, Order_Date, Ship_Date, Ship_Mode, Customer_ID,
Customer_Name, Segment, Country, City, State, Postal_Code, Region,
Product_ID, Category, Sub_Category, Product_Name, Sales, Quantity,
Discount, Profit.

Run the sections individually while learning. Each SELECT returns a result set.
*/

USE [SuperstoreDB];
GO

/* 0. DATA VALIDATION */
SELECT TOP (10) *
FROM dbo.superstore;

SELECT COUNT(*) AS total_records
FROM dbo.superstore;

/* 1. OVERALL BUSINESS KPIs */
SELECT
    SUM([Sales]) AS total_sales,
    SUM([Profit]) AS total_profit,
    CAST(100.0 * SUM([Profit]) / NULLIF(SUM([Sales]), 0) AS DECIMAL(10, 2)) AS profit_margin_percent,
    COUNT(DISTINCT [Order_ID]) AS total_orders,
    COUNT(DISTINCT [Customer_ID]) AS total_customers,
    SUM([Quantity]) AS units_sold,
    CAST(SUM([Sales]) * 1.0 / NULLIF(COUNT(DISTINCT [Order_ID]), 0) AS DECIMAL(12, 2)) AS average_order_value,
    CAST(AVG([Discount]) * 100.0 AS DECIMAL(10, 2)) AS average_discount_percent
FROM dbo.superstore;


/* 2. CATEGORY PERFORMANCE */
SELECT
    [Category],
    SUM([Sales]) AS sales,
    SUM([Profit]) AS profit,
    SUM([Quantity]) AS quantity_sold,
    CAST(100.0 * SUM([Profit]) / NULLIF(SUM([Sales]), 0) AS DECIMAL(10, 2)) AS profit_margin_percent
FROM dbo.superstore
GROUP BY [Category]
ORDER BY profit DESC;

/* 3. SUB-CATEGORY PERFORMANCE AND LOSS-MAKERS */
SELECT
    [Category], [Sub_Category],
    SUM([Sales]) AS sales,
    SUM([Profit]) AS profit,
    CAST(100.0 * SUM([Profit]) / NULLIF(SUM([Sales]), 0) AS DECIMAL(10, 2)) AS profit_margin_percent
FROM dbo.superstore
GROUP BY [Category], [Sub_Category]
ORDER BY profit ASC;

/* 4. TOP 10 PRODUCTS BY PROFIT */
SELECT TOP (10)
    [Product_ID], [Product_Name], [Category], [Sub_Category],
    SUM([Sales]) AS sales,
    SUM([Profit]) AS profit,
    SUM([Quantity]) AS quantity_sold
FROM dbo.superstore
GROUP BY [Product_ID], [Product_Name], [Category], [Sub_Category]
ORDER BY profit DESC;

/* 5. BOTTOM 10 PRODUCTS BY PROFIT */
SELECT TOP (10)
    [Product_ID], [Product_Name], [Category], [Sub_Category],
    SUM([Sales]) AS sales,
    SUM([Profit]) AS profit,
    SUM([Quantity]) AS quantity_sold
FROM dbo.superstore
GROUP BY [Product_ID], [Product_Name], [Category], [Sub_Category]
ORDER BY profit ASC;

/* 6. TOP 10 CUSTOMERS BY PROFIT */
SELECT TOP (10)
    [Customer_ID], [Customer_Name],
    SUM([Sales]) AS sales,
    SUM([Profit]) AS profit,
    COUNT(DISTINCT [Order_ID]) AS total_orders
FROM dbo.superstore
GROUP BY [Customer_ID], [Customer_Name]
ORDER BY profit DESC;

/* 7. CUSTOMER VALUE SEGMENTATION
   Customer sales are compared with the 75th percentile of customer-level sales.
*/
;WITH customer_metrics AS
(
    SELECT
        [Customer_ID], [Customer_Name],
        SUM([Sales]) AS sales,
        SUM([Profit]) AS profit,
        COUNT(DISTINCT [Order_ID]) AS total_orders
    FROM dbo.superstore
    GROUP BY [Customer_ID], [Customer_Name]
),
customer_threshold AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY sales) OVER () AS sales_75th_percentile
    FROM customer_metrics
)
SELECT
    cm.[Customer_ID], cm.[Customer_Name], cm.sales, cm.profit, cm.total_orders,
    CASE
        WHEN cm.sales >= ct.sales_75th_percentile AND cm.profit > 0 THEN 'High sales / profitable'
        WHEN cm.sales >= ct.sales_75th_percentile AND cm.profit <= 0 THEN 'High sales / low or negative profit'
        WHEN cm.profit > 0 THEN 'Lower sales / profitable'
        ELSE 'Lower sales / unprofitable'
    END AS customer_group
FROM customer_metrics AS cm
CROSS JOIN customer_threshold AS ct
ORDER BY cm.sales DESC;

/* 8. REGIONAL AND STATE PERFORMANCE */
SELECT
    [Region], [State],
    SUM([Sales]) AS sales,
    SUM([Profit]) AS profit,
    CAST(100.0 * SUM([Profit]) / NULLIF(SUM([Sales]), 0) AS DECIMAL(10, 2)) AS profit_margin_percent
FROM dbo.superstore
GROUP BY [Region], [State]
ORDER BY profit ASC;

/* 9. DISCOUNT BAND PERFORMANCE */
;WITH tagged AS
(
    SELECT [Sales], [Profit], [Discount],
        CASE
            WHEN [Discount] = 0 THEN '0%'
            WHEN [Discount] <= 0.10 THEN '>0-10%'
            WHEN [Discount] <= 0.20 THEN '>10-20%'
            WHEN [Discount] <= 0.30 THEN '>20-30%'
            WHEN [Discount] <= 0.40 THEN '>30-40%'
            ELSE '>40%'
        END AS discount_band
    FROM dbo.superstore
)
SELECT
    discount_band,
    COUNT(*) AS transaction_rows,
    SUM([Sales]) AS sales,
    SUM([Profit]) AS profit,
    CAST(100.0 * SUM([Profit]) / NULLIF(SUM([Sales]), 0) AS DECIMAL(10, 2)) AS profit_margin_percent
FROM tagged
GROUP BY discount_band
ORDER BY CASE discount_band
    WHEN '0%' THEN 1 WHEN '>0-10%' THEN 2 WHEN '>10-20%' THEN 3
    WHEN '>20-30%' THEN 4 WHEN '>30-40%' THEN 5 ELSE 6 END;

/* 10. YEARLY PERFORMANCE AND YEAR-OVER-YEAR SALES GROWTH */
;WITH yearly AS
(
    SELECT YEAR([Order_Date]) AS order_year,
        SUM([Sales]) AS sales,
        SUM([Profit]) AS profit
    FROM dbo.superstore
    GROUP BY YEAR([Order_Date])
),
yearly_with_previous AS
(
    SELECT order_year, sales, profit,
        LAG(sales) OVER (ORDER BY order_year) AS previous_year_sales
    FROM yearly
)
SELECT
    order_year, sales, profit, previous_year_sales,
    CAST(100.0 * (sales - previous_year_sales) / NULLIF(previous_year_sales, 0) AS DECIMAL(10, 2)) AS yoy_sales_growth_percent
FROM yearly_with_previous
ORDER BY order_year;

/* 11. RANK PRODUCTS WITHIN EACH CATEGORY BY PROFIT */
;WITH product_profit AS
(
    SELECT [Category], [Product_ID], [Product_Name],
        SUM([Sales]) AS sales,
        SUM([Profit]) AS profit
    FROM dbo.superstore
    GROUP BY [Category], [Product_ID], [Product_Name]
)
SELECT
    [Category], [Product_ID], [Product_Name], sales, profit,
    DENSE_RANK() OVER (PARTITION BY [Category] ORDER BY profit DESC) AS category_profit_rank
FROM product_profit
ORDER BY [Category], category_profit_rank;

/* 12. SHIPPING DURATION AND SHIP MODE */
SELECT
    [Ship_Mode],
    COUNT(DISTINCT [Order_ID]) AS total_orders,
    CAST(AVG(1.0 * DATEDIFF(DAY, [Order_Date], [Ship_Date])) AS DECIMAL(10, 2)) AS average_shipping_days,
    SUM([Sales]) AS sales,
    SUM([Profit]) AS profit
FROM dbo.superstore
GROUP BY [Ship_Mode]
ORDER BY average_shipping_days;

/* 13. CUSTOMER SEGMENT x CATEGORY */
SELECT
    [Segment], [Category],
    SUM([Sales]) AS sales,
    SUM([Profit]) AS profit
FROM dbo.superstore
GROUP BY [Segment], [Category]
ORDER BY [Segment], sales DESC;

/* 14. HIGH-SALES / NEGATIVE-PROFIT TRANSACTION ROWS */
SELECT TOP (50)
    [Order_ID], [Product_Name], [Category], [Sub_Category],
    [Sales], [Discount], [Profit]
FROM dbo.superstore
WHERE [Profit] < 0
ORDER BY [Sales] DESC;

/* 15. REGION x CATEGORY PROFIT */
SELECT
    [Region], [Category],
    SUM([Sales]) AS sales,
    SUM([Profit]) AS profit,
    CAST(100.0 * SUM([Profit]) / NULLIF(SUM([Sales]), 0) AS DECIMAL(10, 2)) AS profit_margin_percent
FROM dbo.superstore
GROUP BY [Region], [Category]
ORDER BY [Region], profit;

/* 16. MONTHLY SALES TREND */
SELECT
    YEAR([Order_Date]) AS order_year,
    MONTH([Order_Date]) AS order_month,
    SUM([Sales]) AS sales,
    SUM([Profit]) AS profit
FROM dbo.superstore
GROUP BY YEAR([Order_Date]), MONTH([Order_Date])
ORDER BY order_year, order_month;

/* INTERPRETATION NOTE:
   Discount and profit may be associated, but this analysis alone does not prove
   that discounts caused lower profit. Product mix, order size, category, region,
   and other factors may also influence profitability.
*/

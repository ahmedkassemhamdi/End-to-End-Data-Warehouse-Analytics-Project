/*
===============================================================================
Database Exploration and Validation
===============================================================================
Purpose:
    This script is used to explore and validate the data warehouse tables
    inside the 'gold' schema.

Objectives:
    - Explore database tables and columns structure.
    - Check record counts for fact and dimension tables.
    - Validate primary key uniqueness.
    - Detect NULL values in important columns.
    - Verify referential integrity between fact and dimension tables.
    - Explore customer demographics and distributions.
    - Explore product categories, pricing, and product lines.
    - Analyze sales data including revenue, quantity sold, and order values.
    - Detect suspicious or invalid data records.

Tables Covered:
    - gold.fact_sales
    - gold.dim_customers
    - gold.dim_products

===============================================================================
*/

-- Explore Tables in the Database
SELECT *
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'gold';

-- Explore Columns
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN
(
    'fact_sales',
    'dim_customers',
    'dim_products'
);

-- Count number of records in each table
SELECT 'fact_sales' AS TableName, COUNT(*) AS RecordCount
FROM gold.fact_sales

UNION ALL

SELECT 'dim_customers' AS TableName, COUNT(*) AS RecordCount
FROM gold.dim_customers

UNION ALL

SELECT 'dim_products' AS TableName, COUNT(*) AS RecordCount
FROM gold.dim_products;


-- Check Primary Key Uniqueness
-- for customers
SELECT
    customer_key,
    COUNT(*) AS duplicateCount
FROM gold.dim_customers
WHERE customer_key IS NOT NULL
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- for products
SELECT
    product_key,
    COUNT(*) AS duplicateCount
FROM gold.dim_products
WHERE product_key IS NOT NULL
GROUP BY product_key
HAVING COUNT(*) > 1;



-- Check for NULL values in important columns
-- Check NULLs in customer_key
SELECT
    COUNT(*) AS NullCount
FROM gold.dim_customers
WHERE customer_key IS NULL;

-- Check NULLs in product_key
SELECT
    COUNT(*) AS NullCount
FROM gold.dim_products
WHERE product_key IS NULL;



-- Check Referential Integrity
-- Ensure all customer_keys in fact_sales exist in dim_customers
SELECT DISTINCT fs.customer_key
FROM gold.fact_sales fs
LEFT JOIN gold.dim_customers dc
    ON fs.customer_key = dc.customer_key
WHERE dc.customer_key IS NULL;

-- Ensure all product_keys in fact_sales exist in dim_products
SELECT DISTINCT fs.product_key
FROM gold.fact_sales fs
LEFT JOIN gold.dim_products dp
    ON fs.product_key = dp.product_key
WHERE dp.product_key IS NULL;


-- DIM_CUSTOMERS EXPLORATION
-- Explore all columns quickly
SELECT TOP 10 *
FROM gold.dim_customers;

-- Count total customers
SELECT COUNT(customer_key) AS total_customers
FROM gold.dim_customers;

-- Check distinct countries
SELECT DISTINCT country
FROM gold.dim_customers
ORDER BY country;

-- Customers per country
SELECT
    country,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;

-- Check gender distribution
SELECT
    gender,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;


-- Check marital status distribution
SELECT
    marital_status,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY marital_status
ORDER BY total_customers DESC;

-- Check age distribution
SELECT
    MIN(birthdate) AS oldest_birthdate,
    MAX(birthdate) AS youngest_birthdate
FROM gold.dim_customers;

-- Detect suspicious ages
SELECT *
FROM gold.dim_customers
WHERE birthdate < '1900-01-01'
   OR birthdate > GETDATE();


--------------------------------------
--------------------------------------
--------------------------------------

-- DIM_PRODUCTS EXPLORATION
-- Preview products
SELECT TOP 10 *
FROM gold.dim_products;

-- Total products
SELECT COUNT(product_key) AS total_products
FROM gold.dim_products;

-- Product categories
SELECT DISTINCT category
FROM gold.dim_products
ORDER BY category;

-- Products per category
SELECT
    category,
    COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;

-- product lines 

SELECT DISTINCT product_line
FROM gold.dim_products

-- Products per subcategory
SELECT
    category,
    subcategory,
    COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category, subcategory
ORDER BY total_products DESC;

-- Check product costs/prices
SELECT
    MIN(cost) AS min_price,
    MAX(cost) AS max_price,
    AVG(cost) AS avg_price
FROM gold.dim_products;

-- Detect invalid prices
SELECT *
FROM gold.dim_products
WHERE cost <= 0;

-------------------------------------------
---------------------------------------------
-----------------------------------------------

-- FACT_SALES EXPLORATION
-- Preview sales table
SELECT TOP 10 *
FROM gold.fact_sales;


-- Total Sales Records
SELECT COUNT(*) AS total_sales_records
FROM gold.fact_sales;



-- Total Quantity Sold
SELECT SUM(quantity) AS total_quantity_sold
FROM gold.fact_sales;


-- Total Revenue
SELECT SUM(sales_amount) AS total_revenue
FROM gold.fact_sales;


-- Average Order Value
SELECT AVG(sales_amount) AS avg_order_value
FROM gold.fact_sales;


-- Minimum / Maximum Sales
SELECT
    MIN(sales_amount) AS min_sale,
    MAX(sales_amount) AS max_sale
FROM gold.fact_sales;

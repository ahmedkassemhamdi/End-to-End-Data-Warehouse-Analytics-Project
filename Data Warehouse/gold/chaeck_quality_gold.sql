/*
===============================================================================
Gold Layer Data Quality Checks
===============================================================================
Purpose:
    This script validates the integrity of the Gold layer (dimension and fact
    tables) by checking:
    - Uniqueness of surrogate keys in dimension tables
    - Referential integrity between fact and dimension tables

    It ensures the data model is consistent and ready for analytics/BI usage.
===============================================================================
*/

-- ---------------------------------------------------------------------------------
-- Data Quality Checks for Gold Layer
-- Checking 'gold.dim_customers'
-- ----------------------------------------------------------------------------------
-- Check for Uniqueness of Customer Key in gold.dim_customers
-- Expectation: No results 
SELECT 
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- ---------------------------------------------------------------------------------
-- Checking 'gold.product_key'
-- ---------------------------------------------------------------------------------
-- Check for Uniqueness of Product Key in gold.dim_products
-- Expectation: No results 
SELECT 
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- ---------------------------------------------------------------------------------
-- Checking 'gold.fact_sales'
-- ---------------------------------------------------------------------------------
-- Check the data model connectivity between fact and dimensions
SELECT * 
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
WHERE p.product_key IS NULL OR c.customer_key IS NULL  
/*
===============================================================================
Sales Report
===============================================================================
Purpose:
    - This report consolidates key sales metrics and trends.

Highlights:
    1. Tracks sales performance over time.
    2. Aggregates monthly sales metrics:
       - total sales
       - total orders
       - total customers
       - total products
       - total quantity sold
    3. Calculates valuable KPIs:
       - average order value (AOV)
       - previous month sales
       - sales growth percentage
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_sales
-- =============================================================================

IF OBJECT_ID('gold.report_sales', 'V') IS NOT NULL
    DROP VIEW gold.report_sales;
GO

CREATE VIEW gold.report_sales AS

WITH base_query AS (
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core sales data
---------------------------------------------------------------------------*/
    SELECT
        order_number,
        customer_key,
        product_key,
        order_date,
        sales_amount,
        quantity
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
),

sales_aggregation AS (
/*---------------------------------------------------------------------------
2) Monthly Sales Aggregations
---------------------------------------------------------------------------*/
    SELECT

        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,

        SUM(sales_amount) AS total_sales,

        COUNT(DISTINCT order_number) AS total_orders,

        COUNT(DISTINCT customer_key) AS total_customers,

        COUNT(DISTINCT product_key) AS total_products,

        SUM(quantity) AS total_quantity

    FROM base_query

    GROUP BY
        YEAR(order_date),
        MONTH(order_date)
),

sales_metrics AS (
/*---------------------------------------------------------------------------
3) Calculate Previous Month Sales
---------------------------------------------------------------------------*/
    SELECT
        *,
        LAG(total_sales) OVER (
            ORDER BY order_year, order_month
        ) AS previous_month_sales

    FROM sales_aggregation
)

/*---------------------------------------------------------------------------
4) Final Report
---------------------------------------------------------------------------*/
SELECT

    order_year,
    order_month,

    total_sales,
    total_orders,
    total_customers,
    CASE
        WHEN total_customers = 0 THEN 0
        ELSE ROUND(
            total_sales * 1.0
            / total_customers,
            2
        )
    END AS revenue_per_customer,
    total_products,
    total_quantity,

    -- Average Order Value (AOV)
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE ROUND(total_sales * 1.0 / total_orders, 2)
    END AS avg_order_value,

    previous_month_sales,

    -- Sales Growth %
    CASE
        WHEN previous_month_sales IS NULL
             OR previous_month_sales = 0
        THEN NULL

        ELSE ROUND(
            ((total_sales - previous_month_sales) * 100.0)
            / previous_month_sales
        ,2)
    END AS sales_growth_pct

FROM sales_metrics;
GO

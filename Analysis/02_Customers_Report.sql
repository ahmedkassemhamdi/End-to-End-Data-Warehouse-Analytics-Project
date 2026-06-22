/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors.

Highlights:
    1. Gathers essential customer information.
    2. Segments customers by age and value.
    3. Aggregates customer-level metrics:
       - total orders
       - total sales
       - total quantity purchased
       - total products purchased
       - lifespan
    4. Calculates valuable KPIs:
       - recency
       - average order value
       - average monthly spend
       - purchase frequency
       - customer lifetime value
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_customers
-- =============================================================================

IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
    DROP VIEW gold.report_customers;
GO

CREATE VIEW gold.report_customers AS

WITH base_query AS (
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core customer and sales data
---------------------------------------------------------------------------*/
    SELECT
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,

        c.customer_key,
        c.customer_number,

        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,

        DATEDIFF(YEAR, c.birthdate, GETDATE())
        -
        CASE
            WHEN DATEADD(
                    YEAR,
                    DATEDIFF(YEAR, c.birthdate, GETDATE()),
                    c.birthdate
                 ) > GETDATE()
            THEN 1
            ELSE 0
        END AS age

    FROM gold.fact_sales f

    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key

    WHERE f.order_date IS NOT NULL
),

customer_aggregation AS (
/*---------------------------------------------------------------------------
2) Customer Aggregations
---------------------------------------------------------------------------*/
    SELECT

        customer_key,   
        customer_number,
        customer_name,
        age,

        MIN(order_date) AS first_order_date,
        MAX(order_date) AS last_order_date,

        COUNT(DISTINCT order_number) AS total_orders,

        SUM(sales_amount) AS total_sales,

        SUM(quantity) AS total_quantity,

        COUNT(DISTINCT product_key) AS total_products,

        DATEDIFF(
            MONTH,
            MIN(order_date),
            MAX(order_date)
        ) AS lifespan

    FROM base_query

    GROUP BY
        customer_key,
        customer_number,
        customer_name,
        age
),
customer_metrics AS (
    SELECT
        *,

        ROUND(
            total_sales * 100.0
            / SUM(total_sales) OVER(),
            2
        ) AS customer_contribution_pct

    FROM customer_aggregation
)

/*---------------------------------------------------------------------------
3) Final Report
---------------------------------------------------------------------------*/
SELECT

    customer_key,
    customer_number,
    customer_name,

    age,

    CASE
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50+'
    END AS age_group,

    CASE 
    WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
    WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
    ELSE 'New'
    END AS customer_segment,

    first_order_date,
    last_order_date,

    lifespan,

    DATEDIFF(
        MONTH,
        last_order_date,
        GETDATE()
    ) AS recency,

    total_orders,
    total_sales,
    total_quantity,
    total_products,
    customer_contribution_pct,

    -- Average Order Value (AOV)
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE ROUND(
            total_sales * 1.0 / total_orders,
            2
        )
    END AS avg_order_value,

    -- Average Monthly Spend
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE ROUND(
            total_sales * 1.0 / lifespan,
            2
        )
    END AS avg_monthly_spend,

    -- Purchase Frequency
    CASE
        WHEN lifespan = 0 THEN total_orders
        ELSE ROUND(
            total_orders * 1.0 / lifespan,
            2
        )
    END AS purchase_frequency,
    CASE
        WHEN total_orders <= 1 THEN NULL
        ELSE ROUND(
            DATEDIFF(
                DAY,
                first_order_date,
                last_order_date
                ) * 1.0
                /
                (total_orders - 1),
                2
                )
    END AS avg_days_between_purchases,

    -- Customer Lifetime Value
    total_sales AS customer_lifetime_value

FROM customer_metrics;
GO

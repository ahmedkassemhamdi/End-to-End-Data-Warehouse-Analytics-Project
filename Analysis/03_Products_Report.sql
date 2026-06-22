/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential product information.
    2. Measures product sales and profitability.
    3. Segments products based on revenue performance.
    4. Calculates key KPIs:
       - sales
       - profit
       - profit margin
       - average selling price
       - average order revenue
       - average monthly revenue
       - revenue contribution
       - rankings
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_products
-- =============================================================================

IF OBJECT_ID('gold.report_products', 'V') IS NOT NULL
    DROP VIEW gold.report_products;
GO

CREATE VIEW gold.report_products AS

WITH base_query AS (
/*---------------------------------------------------------------------------
1) Base Query
---------------------------------------------------------------------------*/
    SELECT
        f.order_number,
        f.order_date,
        f.customer_key,
        f.sales_amount,
        f.quantity,

        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost

    FROM gold.fact_sales f

    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key

    WHERE f.order_date IS NOT NULL
),

product_aggregations AS (
/*---------------------------------------------------------------------------
2) Product Aggregations
---------------------------------------------------------------------------*/
    SELECT

        product_key,
        product_name,
        category,
        subcategory,
        cost,

        MIN(order_date) AS first_sale_date,
        MAX(order_date) AS last_sale_date,

        DATEDIFF(
            MONTH,
            MIN(order_date),
            MAX(order_date)
        ) AS lifespan,

        COUNT(DISTINCT order_number) AS total_orders,

        COUNT(DISTINCT customer_key) AS total_customers,

        SUM(quantity) AS total_quantity,

        SUM(sales_amount) AS total_sales,

        SUM(
            sales_amount -
            (cost * quantity)
        ) AS total_profit,

        ROUND(
            AVG(
                CAST(sales_amount AS FLOAT)
                / NULLIF(quantity, 0)
            ),
            2
        ) AS avg_selling_price

    FROM base_query

    GROUP BY
        product_key,
        product_name,
        category,
        subcategory,
        cost
),

final_report AS (
/*---------------------------------------------------------------------------
3) Additional Metrics
---------------------------------------------------------------------------*/
    SELECT

        *,

        DENSE_RANK()
        OVER(
            ORDER BY total_sales DESC
        ) AS sales_rank,

        DENSE_RANK()
        OVER(
            ORDER BY total_profit DESC
        ) AS profit_rank,

        ROUND(
            total_sales * 100.0
            / SUM(total_sales) OVER(),
            2
        ) AS revenue_contribution_pct,

        ROUND(
            total_profit * 100.0
            / SUM(total_profit) OVER(),
            2
        ) AS profit_contribution_pct

FROM product_aggregations
)

/*---------------------------------------------------------------------------
4) Final Report
---------------------------------------------------------------------------*/
SELECT

    product_key,
    product_name,

    category,
    subcategory,

    cost,

    first_sale_date,
    last_sale_date,

    lifespan,

    DATEDIFF(
        MONTH,
        last_sale_date,
        GETDATE()
    ) AS recency,

    total_orders,
    total_customers,
    total_quantity,

    total_sales,
    total_profit,

    CASE
        WHEN total_sales = 0 THEN 0
        ELSE ROUND(
            total_profit * 100.0
            / total_sales,
            2
        )
    END AS profit_margin,

    avg_selling_price,

    CASE
        WHEN total_orders = 0 THEN 0
        ELSE ROUND(
            total_sales * 1.0
            / total_orders,
            2
        )
    END AS avg_order_revenue,

    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE ROUND(
            total_sales * 1.0
            / lifespan,
            2
        )
    END AS avg_monthly_revenue,

    revenue_contribution_pct,
    profit_contribution_pct,

    sales_rank,
    profit_rank,

    CASE
        WHEN total_sales >= 50000
            THEN 'High Performer'

        WHEN total_sales >= 10000
            THEN 'Mid Performer'

        ELSE 'Low Performer'
    END AS product_segment

FROM final_report;
GO

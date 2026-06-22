/*
===============================================================================
Category Report
===============================================================================
Purpose:
    - This report consolidates category-level sales and profitability metrics.

Highlights:
    1. Measures category performance.
    2. Calculates sales and profit KPIs.
    3. Calculates contribution percentages.
    4. Provides category rankings.
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_categories
-- =============================================================================

IF OBJECT_ID('gold.report_categories', 'V') IS NOT NULL
    DROP VIEW gold.report_categories;
GO

CREATE VIEW gold.report_categories AS

WITH base_query AS (
/*---------------------------------------------------------------------------
1) Base Query
---------------------------------------------------------------------------*/
    SELECT

        f.order_number,
        f.customer_key,
        f.quantity,
        f.sales_amount,

        p.product_key,
        p.category,
        p.cost

    FROM gold.fact_sales f

    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
),

category_aggregations AS (
/*---------------------------------------------------------------------------
2) Category Aggregations
---------------------------------------------------------------------------*/
    SELECT

        category,

        COUNT(DISTINCT order_number) AS total_orders,

        COUNT(DISTINCT customer_key) AS total_customers,

        COUNT(DISTINCT product_key) AS total_products,

        SUM(quantity) AS total_quantity,

        SUM(sales_amount) AS total_sales,

        SUM(
            sales_amount -
            (cost * quantity)
        ) AS total_profit

    FROM base_query

    GROUP BY category
),

final_report AS (
/*---------------------------------------------------------------------------
3) Additional Metrics
---------------------------------------------------------------------------*/
    SELECT

        *,

        ROUND(
            total_sales * 100.0
            / SUM(total_sales) OVER(),
            2
        ) AS revenue_contribution_pct,

        DENSE_RANK()
        OVER(
            ORDER BY total_sales DESC
        ) AS sales_rank,

        DENSE_RANK()
        OVER(
            ORDER BY total_profit DESC
        ) AS profit_rank

    FROM category_aggregations
)

/*---------------------------------------------------------------------------
4) Final Report
---------------------------------------------------------------------------*/
SELECT

    category,

    total_orders,
    total_customers,
    total_products,
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
    END AS profit_margin_pct,

    revenue_contribution_pct,

    sales_rank,
    profit_rank

FROM final_report;
GO

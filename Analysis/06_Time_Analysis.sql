/*
===============================================================================
Time Analysis Report
===============================================================================
Purpose:
    - Analyze sales performance over time.
    - Measure growth and trends.
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_time_analysis
-- =============================================================================

IF OBJECT_ID('gold.report_time_analysis', 'V') IS NOT NULL
    DROP VIEW gold.report_time_analysis;
GO

CREATE VIEW gold.report_time_analysis AS

WITH monthly_sales AS (
/*---------------------------------------------------------------------------
1) Monthly Aggregation
---------------------------------------------------------------------------*/
    SELECT

        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,

        DATEFROMPARTS(
            YEAR(order_date),
            MONTH(order_date),
            1
        ) AS month_start,

        SUM(sales_amount) AS total_sales,

        COUNT(DISTINCT order_number) AS total_orders,

        COUNT(DISTINCT customer_key) AS total_customers

    FROM gold.fact_sales

    WHERE order_date IS NOT NULL

    GROUP BY
        YEAR(order_date),
        MONTH(order_date)
),

time_metrics AS (
/*---------------------------------------------------------------------------
2) Time Metrics
---------------------------------------------------------------------------*/
    SELECT

        *,

        LAG(total_sales) OVER (
            ORDER BY month_start
        ) AS previous_month_sales,
        LAG(total_sales,12) OVER (
            ORDER BY month_start
        ) AS same_month_last_year_sales,

        SUM(total_sales) OVER (
            ORDER BY month_start
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS running_total_sales,

        AVG(total_sales * 1.0) OVER (
            ORDER BY month_start
            ROWS BETWEEN 2 PRECEDING
            AND CURRENT ROW
        ) AS moving_avg_3_months

    FROM monthly_sales
)

SELECT

    order_year,
    order_month,
    month_start,

    total_sales,
    total_orders,
    total_customers,

    previous_month_sales,

    CASE
        WHEN previous_month_sales IS NULL
             OR previous_month_sales = 0
        THEN NULL

        ELSE ROUND(
            (
                (total_sales - previous_month_sales)
                * 100.0
            )
            / previous_month_sales,
            2
        )
    END AS sales_growth_pct,
    same_month_last_year_sales,
    CASE
        WHEN same_month_last_year_sales IS NULL
            OR same_month_last_year_sales = 0
        THEN NULL

        ELSE ROUND(
            (
                (total_sales - same_month_last_year_sales)
                * 100.0
            )
            /
            same_month_last_year_sales,
            2
        )
    END AS yoy_growth_pct,

    running_total_sales,

    ROUND(
        moving_avg_3_months,
        2
    ) AS moving_avg_3_months

FROM time_metrics;
GO

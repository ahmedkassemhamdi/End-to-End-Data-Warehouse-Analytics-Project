/*
===============================================================================
Customer RFM Report
===============================================================================
Purpose:
    - Performs RFM analysis to identify customer value and behavior.

R = Recency
F = Frequency
M = Monetary
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_customer_rfm
-- =============================================================================

IF OBJECT_ID('gold.report_customer_rfm', 'V') IS NOT NULL
    DROP VIEW gold.report_customer_rfm;
GO

CREATE VIEW gold.report_customer_rfm AS

WITH customer_metrics AS (
/*---------------------------------------------------------------------------
1) Calculate RFM Metrics
---------------------------------------------------------------------------*/
    SELECT

        c.customer_key,
        c.customer_number,

        CONCAT(
            c.first_name,
            ' ',
            c.last_name
        ) AS customer_name,

        DATEDIFF(
            DAY,
            MAX(f.order_date),
            GETDATE()
        ) AS recency,

        COUNT(DISTINCT f.order_number) AS frequency,

        SUM(f.sales_amount) AS monetary

    FROM gold.fact_sales f

    INNER JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key

    WHERE f.order_date IS NOT NULL

    GROUP BY
        c.customer_key,
        c.customer_number,
        c.first_name,
        c.last_name
),

rfm_scores AS (
/*---------------------------------------------------------------------------
2) Generate RFM Scores
---------------------------------------------------------------------------*/
    SELECT

        *,

        NTILE(5) OVER (
            ORDER BY recency ASC
        ) AS r_score,

        NTILE(5) OVER (
            ORDER BY frequency DESC
        ) AS f_score,

        NTILE(5) OVER (
            ORDER BY monetary DESC
        ) AS m_score

    FROM customer_metrics
),

final_report AS (
/*---------------------------------------------------------------------------
3) Create RFM Score
---------------------------------------------------------------------------*/
    SELECT

        *,

        CONCAT(
            r_score,
            f_score,
            m_score
        ) AS rfm_score

    FROM rfm_scores
)

SELECT

    customer_key,
    customer_number,
    customer_name,

    recency,
    frequency,
    monetary,

    r_score,
    f_score,
    m_score,

    rfm_score,

    CASE

        WHEN r_score >= 4
         AND f_score >= 4
         AND m_score >= 4
        THEN 'Champions'

        WHEN r_score >= 3
         AND f_score >= 3
         AND m_score >= 3
        THEN 'Loyal Customers'

        WHEN r_score >= 3
         AND f_score >= 2
        THEN 'Potential Loyalists'

        WHEN r_score <= 2
         AND f_score >= 3
        THEN 'At Risk'

        ELSE 'Lost Customers'

    END AS customer_segment

FROM final_report;
GO

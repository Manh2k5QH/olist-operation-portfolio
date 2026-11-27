-- ============================================================================
-- ANALYSIS: Delivery Performance Deep Dive
-- ============================================================================
-- Business Questions:
--   Q1. What is the late vs on-time review penalty?
--   Q2. How has the monthly late rate trended over time?
--   Q3. What is the delivery time distribution?
--   Q4. What is the revenue at risk from late delivery?
--   Q5. Which states have the highest delivery risk (rate + volume)?
-- Skills:  CTEs, window functions (LAG, RANK, PERCENT_RANK), CASE, aggregation
-- ============================================================================

-- =========================================
-- Q1: Late vs On-Time Review Penalty
-- Date-based SLA. Review means use one averaged score per reviewed order.
-- =========================================
SELECT
    is_late,
    COUNT(*)                            AS delivered_orders,
    ROUND(AVG(review_score), 2)         AS avg_review_score,
    ROUND(AVG(delay_days), 1)           AS avg_delay_days,
    ROUND(SUM(gmv), 2)                  AS total_gmv
FROM mart_order_delivery
GROUP BY is_late
ORDER BY is_late;


-- =========================================
-- Q2: Monthly Late Rate Trend with MoM Change
-- Uses LAG() window function for period-over-period comparison
-- =========================================
WITH monthly AS (
    SELECT
        order_month,
        COUNT(*)                                              AS delivered_orders,
        SUM(CASE WHEN is_late THEN 1 ELSE 0 END)             AS late_orders,
        ROUND(AVG(CASE WHEN is_late THEN 1.0 ELSE 0.0 END) * 100, 2) AS late_rate_pct,
        ROUND(SUM(gmv), 2)                                   AS monthly_gmv
    FROM mart_order_delivery
    GROUP BY order_month
)
SELECT
    order_month,
    delivered_orders,
    late_orders,
    late_rate_pct,
    monthly_gmv,
    -- Month-over-month change using LAG window function
    CASE WHEN DATE_DIFF('month', LAG(order_month) OVER (ORDER BY order_month), order_month) = 1
        THEN ROUND(late_rate_pct - LAG(late_rate_pct) OVER (ORDER BY order_month), 2) END
        AS mom_change_pp,
    -- Volume confidence flag
    CASE WHEN delivered_orders < 100 THEN '⚠ low volume' ELSE '✓' END AS confidence
FROM monthly
ORDER BY order_month;


-- =========================================
-- Q3: Delivery Time Distribution (Percentiles)
-- How long do orders take from purchase to delivery?
-- =========================================
SELECT
    ROUND(PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY delivery_days), 1) AS p10_days,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY delivery_days), 1) AS p25_days,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY delivery_days), 1) AS p50_median,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY delivery_days), 1) AS p75_days,
    ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY delivery_days), 1) AS p90_days,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY delivery_days), 1) AS p95_days,
    ROUND(AVG(delivery_days), 1)  AS avg_days,
    MIN(delivery_days)            AS min_days,
    MAX(delivery_days)            AS max_days
FROM mart_order_delivery
WHERE delivery_days IS NOT NULL AND delivery_days > 0;


-- =========================================
-- Q4: Revenue at Risk from Late Delivery
-- GMV flowing through degraded customer experience
-- =========================================
SELECT
    is_late,
    COUNT(*)                                    AS orders,
    ROUND(SUM(gmv), 2)                          AS gmv,
    ROUND(SUM(gmv) * 100.0 / SUM(SUM(gmv)) OVER(), 2)  AS gmv_share_pct,
    ROUND(AVG(review_score), 2)                 AS avg_review
FROM mart_order_delivery
GROUP BY is_late
ORDER BY is_late;


-- =========================================
-- Q5: State Delivery Risk Ranking
-- Combines rate + volume using RANK() window function
-- Minimum volume guardrail: 100 delivered orders
-- =========================================
WITH state_metrics AS (
    SELECT
        customer_state,
        COUNT(*)                                              AS delivered_orders,
        SUM(CASE WHEN is_late THEN 1 ELSE 0 END)             AS late_orders,
        ROUND(AVG(CASE WHEN is_late THEN 1.0 ELSE 0.0 END) * 100, 2) AS late_rate_pct,
        ROUND(AVG(review_score), 2)                           AS avg_review,
        ROUND(SUM(gmv), 2)                                    AS total_gmv
    FROM mart_order_delivery
    GROUP BY customer_state
    HAVING COUNT(*) >= 100  -- Volume guardrail
)
SELECT
    customer_state,
    delivered_orders,
    late_orders,
    late_rate_pct,
    avg_review,
    total_gmv,
    RANK() OVER (ORDER BY late_rate_pct DESC)   AS rank_by_rate,
    RANK() OVER (ORDER BY late_orders DESC)     AS rank_by_volume,
    -- Composite risk: average of rate rank and volume rank (lower = higher risk)
    ROUND((RANK() OVER (ORDER BY late_rate_pct DESC)
         + RANK() OVER (ORDER BY late_orders DESC)) / 2.0, 1) AS composite_risk_rank
FROM state_metrics
ORDER BY composite_risk_rank;

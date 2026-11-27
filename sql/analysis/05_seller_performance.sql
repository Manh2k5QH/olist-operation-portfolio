-- ============================================================================
-- ANALYSIS: Seller Performance Scorecard
-- ============================================================================
-- Business Questions:
--   Q1. Seller scorecard with volume guardrails
--   Q2. Seller-level late rate analysis
--   Q3. Top vs bottom seller comparison
--   Q4. Seller concentration (cumulative % / Pareto)
--   Q5. Seller-state cross analysis
-- Skills:  CTEs, window functions (NTILE, PERCENT_RANK, cumulative SUM),
--          CASE expressions, volume guardrails
-- ============================================================================

-- =========================================
-- Q1: Full Seller Scorecard with Volume Guardrails
-- Only sellers with ≥30 delivered orders get rate-based metrics
-- =========================================
SELECT
    seller_id,
    seller_state,
    total_orders,
    delivered_orders,
    gmv,
    freight_value,
    ROUND(freight_share * 100, 2) AS freight_share_pct,
    late_orders,
    ROUND(late_rate * 100, 2)     AS late_rate_pct,
    ROUND(avg_review_score, 2)    AS avg_review,
    volume_flag,
    -- Performance tier using NTILE (only for sufficient-volume sellers)
    CASE
        WHEN volume_flag = 'sufficient' THEN
            CASE NTILE(4) OVER (
                PARTITION BY volume_flag
                ORDER BY late_rate
            )
                WHEN 1 THEN 'Top 25%'
                WHEN 2 THEN 'Above Average'
                WHEN 3 THEN 'Below Average'
                WHEN 4 THEN 'Bottom 25%'
            END
        ELSE 'Insufficient Data'
    END AS performance_tier
FROM mart_seller
WHERE total_orders > 0
ORDER BY gmv DESC;


-- =========================================
-- Q2: Seller-Level Late Rate Distribution
-- How spread out is delivery quality across sellers?
-- =========================================
WITH seller_quality AS (
    SELECT
        seller_id,
        seller_state,
        delivered_orders,
        late_orders,
        late_rate,
        avg_review_score,
        gmv
    FROM mart_seller
    WHERE volume_flag = 'sufficient'  -- Only sellers with ≥30 orders
)
SELECT
    'Seller delivery quality distribution (n=' || COUNT(*) || ' sellers with ≥30 orders)' AS label,
    ROUND(PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY late_rate) * 100, 2) AS p10_late_rate,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY late_rate) * 100, 2) AS p25_late_rate,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY late_rate) * 100, 2) AS p50_median,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY late_rate) * 100, 2) AS p75_late_rate,
    ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY late_rate) * 100, 2) AS p90_late_rate,
    ROUND(AVG(late_rate) * 100, 2) AS avg_late_rate
FROM seller_quality;


-- =========================================
-- Q3: Top 10 vs Bottom 10 Sellers (by GMV, with quality overlay)
-- =========================================
(
    SELECT
        'Top 10 by GMV' AS segment,
        seller_id,
        seller_state,
        total_orders,
        ROUND(gmv, 2) AS gmv,
        ROUND(late_rate * 100, 2) AS late_rate_pct,
        ROUND(avg_review_score, 2) AS avg_review,
        volume_flag
    FROM mart_seller
    WHERE total_orders > 0
    ORDER BY gmv DESC
    LIMIT 10
)
UNION ALL
(
    SELECT
        'Bottom 10 by late rate (≥30 orders)' AS segment,
        seller_id,
        seller_state,
        total_orders,
        ROUND(gmv, 2) AS gmv,
        ROUND(late_rate * 100, 2) AS late_rate_pct,
        ROUND(avg_review_score, 2) AS avg_review,
        volume_flag
    FROM mart_seller
    WHERE volume_flag = 'sufficient'
    ORDER BY late_rate DESC
    LIMIT 10
);


-- =========================================
-- Q4: Seller Concentration / Pareto Analysis
-- What % of sellers drive what % of GMV?
-- =========================================
WITH seller_ranked AS (
    SELECT
        seller_id,
        seller_state,
        gmv,
        total_orders,
        ROW_NUMBER() OVER (ORDER BY gmv DESC) AS gmv_rank,
        COUNT(*) OVER () AS total_sellers
    FROM mart_seller
    WHERE gmv > 0
)
SELECT
    gmv_rank,
    seller_id,
    seller_state,
    total_orders,
    ROUND(gmv, 2) AS gmv,
    -- Individual share
    ROUND(gmv * 100.0 / SUM(gmv) OVER(), 2) AS gmv_share_pct,
    -- Cumulative share (Pareto curve)
    ROUND(SUM(gmv) OVER (ORDER BY gmv DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
        * 100.0 / SUM(gmv) OVER(), 2) AS cumulative_gmv_pct,
    -- Seller percentile position
    ROUND(gmv_rank * 100.0 / total_sellers, 1) AS seller_percentile
FROM seller_ranked
ORDER BY gmv_rank;


-- =========================================
-- Q5: Seller-State Cross Analysis
-- How does seller origin state relate to delivery quality?
-- =========================================
SELECT
    seller_state,
    COUNT(*)                                    AS seller_count,
    SUM(total_orders)                           AS total_orders,
    ROUND(SUM(gmv), 2)                          AS total_gmv,
    ROUND(AVG(gmv), 2)                          AS avg_gmv_per_seller,
    -- Weighted average late rate (by delivered orders, not simple average)
    ROUND(SUM(late_orders) * 100.0
        / NULLIF(SUM(delivered_orders), 0), 2)  AS weighted_late_rate_pct,
    ROUND(AVG(CASE WHEN volume_flag = 'sufficient'
        THEN avg_review_score END), 2)          AS avg_review_qualified,
    SUM(CASE WHEN volume_flag = 'sufficient'
        THEN 1 ELSE 0 END)                     AS qualified_sellers
FROM mart_seller
WHERE total_orders > 0
GROUP BY seller_state
HAVING COUNT(*) >= 5  -- Minimum sellers per state
ORDER BY total_gmv DESC;

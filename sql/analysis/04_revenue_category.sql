-- ============================================================================
-- ANALYSIS: Revenue, Category & Payment Analytics
-- ============================================================================
-- Business Questions:
--   Q1. Monthly revenue trend with running totals and MoM growth
--   Q2. Category Pareto analysis (cumulative GMV %)
--   Q3. Category freight exposure ranking
--   Q4. Payment method distribution and analysis
--   Q5. AOV by category with ranking
-- Skills:  Window functions (SUM OVER, LAG, CUME_DIST), CTEs, Pareto analysis
-- ============================================================================

-- =========================================
-- Q1: Monthly Revenue Trend with Running Total & MoM Growth
-- =========================================
WITH finance AS (
    SELECT order_id, SUM(price) AS gmv
    FROM read_csv_auto('data/olist_order_items_dataset.csv')
    GROUP BY order_id
),
months AS (
    SELECT UNNEST(GENERATE_SERIES(
        (SELECT MIN(order_month) FROM stg_orders),
        (SELECT MAX(order_month) FROM stg_orders), INTERVAL 1 MONTH)) AS order_month
),
monthly_values AS (
    SELECT
        order_month,
        COUNT(DISTINCT order_id)    AS orders,
        ROUND(SUM(gmv), 2)         AS gmv,
        ROUND(SUM(gmv) / NULLIF(COUNT(gmv), 0), 2) AS aov
    FROM stg_orders LEFT JOIN finance USING (order_id)
    GROUP BY order_month
),
monthly_rev AS (
    SELECT m.order_month, COALESCE(v.orders, 0) AS orders,
           COALESCE(v.gmv, 0) AS gmv, v.aov
    FROM months m LEFT JOIN monthly_values v USING(order_month)
)
SELECT
    order_month,
    orders,
    gmv,
    aov,
    -- Running cumulative GMV
    ROUND(SUM(gmv) OVER (ORDER BY order_month), 2) AS cumulative_gmv,
    -- Month-over-month GMV change
    ROUND(gmv - LAG(gmv) OVER (ORDER BY order_month), 2) AS mom_gmv_change,
    -- MoM percentage change
    ROUND((gmv - LAG(gmv) OVER (ORDER BY order_month))
        / NULLIF(LAG(gmv) OVER (ORDER BY order_month), 0) * 100, 1) AS mom_pct_change,
    -- 3-month moving average
    ROUND(AVG(gmv) OVER (
        ORDER BY order_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3m,
    -- Volume confidence
    CASE WHEN orders < 100 THEN '⚠ low volume' ELSE '✓' END AS confidence
FROM monthly_rev
ORDER BY order_month;


-- =========================================
-- Q2: Category Pareto Analysis (Cumulative GMV %)
-- Demonstrates the concentration of revenue across categories
-- =========================================
WITH category_gmv AS (
    SELECT
        category,
        item_rows,
        gmv,
        freight_value,
        freight_share
    FROM mart_category
)
SELECT
    category,
    item_rows,
    ROUND(gmv, 2)                       AS gmv,
    ROUND(gmv * 100.0 / SUM(gmv) OVER(), 2) AS gmv_share_pct,
    -- Cumulative share for Pareto analysis
    ROUND(SUM(gmv) OVER (ORDER BY gmv DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
        * 100.0 / SUM(gmv) OVER(), 2)  AS cumulative_gmv_pct,
    -- Row number for top-N identification
    ROW_NUMBER() OVER (ORDER BY gmv DESC) AS gmv_rank,
    ROUND(freight_share * 100, 2)       AS freight_share_pct
FROM category_gmv
ORDER BY gmv DESC;


-- =========================================
-- Q3: Category Freight Exposure Ranking
-- Identifies categories with highest logistics cost burden
-- =========================================
SELECT
    category,
    item_rows,
    ROUND(gmv, 2)                           AS gmv,
    ROUND(freight_value, 2)                 AS freight_value,
    ROUND(freight_share * 100, 2)           AS freight_share_pct,
    RANK() OVER (ORDER BY freight_share DESC) AS freight_rank,
    -- Flag high-freight categories (>25% threshold)
    CASE
        WHEN freight_share > 0.25 THEN '🔴 HIGH'
        WHEN freight_share > 0.18 THEN '🟡 ELEVATED'
        ELSE '🟢 NORMAL'
    END AS freight_alert
FROM mart_category
WHERE item_rows >= 10  -- Minimum items for meaningful rate
ORDER BY freight_share DESC;


-- =========================================
-- Q4: Payment Method Distribution
-- =========================================
WITH payment_data AS (
    SELECT
        payment_type,
        COUNT(*)                        AS payment_rows,
        COUNT(DISTINCT order_id)        AS orders_using,
        SUM(payment_value)              AS total_value,
        AVG(payment_installments)       AS avg_installments
    FROM read_csv_auto('data/olist_order_payments_dataset.csv', header=true)
    GROUP BY payment_type
)
SELECT
    payment_type,
    payment_rows,
    orders_using,
    ROUND(total_value, 2)                   AS total_value,
    ROUND(total_value * 100.0 / SUM(total_value) OVER(), 2) AS value_share_pct,
    ROUND(avg_installments, 1)              AS avg_installments,
    RANK() OVER (ORDER BY total_value DESC) AS value_rank
FROM payment_data
ORDER BY total_value DESC;


-- =========================================
-- Q5: AOV by Category with Ranking
-- =========================================
SELECT
    category,
    order_count,
    ROUND(gmv, 2)                           AS total_gmv,
    ROUND(gmv / NULLIF(order_count, 0), 2)  AS aov,
    RANK() OVER (ORDER BY gmv / NULLIF(order_count, 0) DESC) AS aov_rank,
    RANK() OVER (ORDER BY gmv DESC)         AS gmv_rank,
    item_rows,
    -- Average items per order in this category
    ROUND(item_rows * 1.0 / NULLIF(order_count, 0), 2) AS avg_items_per_order
FROM mart_category
WHERE order_count >= 20  -- Minimum orders for stable AOV
ORDER BY aov DESC;

-- ============================================================================
-- ANALYSIS: Customer Behavior & Retention
-- ============================================================================
-- Business Questions:
--   Q1. What is the repeat rate at the correct grain (customer_unique_id)?
--   Q2. What does the customer cohort retention look like?
--   Q3. How do one-time vs repeat buyers compare?
--   Q4. What does RFM segmentation reveal?
--   Q5. How are customers distributed geographically?
-- Skills:  CTEs, window functions (NTILE, ROW_NUMBER), cohort logic, CASE
-- ============================================================================

-- =========================================
-- Q1: Repeat Rate at Correct Grain
-- CRITICAL: Use customer_unique_id, NOT customer_id
-- Expected: 2,997 repeat / 96,096 unique = 3.1%
-- =========================================
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id)  AS order_count,
        MIN(TRY_CAST(o.order_purchase_timestamp AS TIMESTAMP)) AS first_order,
        MAX(TRY_CAST(o.order_purchase_timestamp AS TIMESTAMP)) AS last_order,
        SUM(i.total_gmv)           AS lifetime_gmv
    FROM read_csv_auto('data/olist_orders_dataset.csv', header=true) o
    JOIN read_csv_auto('data/olist_customers_dataset.csv', header=true) c
        USING (customer_id)
    LEFT JOIN (
        SELECT order_id, SUM(price) AS total_gmv
        FROM read_csv_auto('data/olist_order_items_dataset.csv', header=true)
        GROUP BY order_id
    ) i USING (order_id)
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*)                                            AS unique_customers,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END)   AS repeat_buyers,
    ROUND(SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2)                          AS repeat_rate_pct,
    ROUND(AVG(order_count), 2)                          AS avg_orders_per_customer,
    ROUND(AVG(lifetime_gmv), 2)                         AS avg_lifetime_gmv
FROM customer_orders;


-- =========================================
-- Q2: Customer Cohort Retention Analysis
-- Group customers by first purchase month, track return rates
-- =========================================
WITH customer_first AS (
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month', MIN(TRY_CAST(o.order_purchase_timestamp AS TIMESTAMP))) AS cohort_month
    FROM read_csv_auto('data/olist_orders_dataset.csv', header=true) o
    JOIN read_csv_auto('data/olist_customers_dataset.csv', header=true) c
        USING (customer_id)
    GROUP BY c.customer_unique_id
),
customer_activity AS (
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month', TRY_CAST(o.order_purchase_timestamp AS TIMESTAMP)) AS activity_month
    FROM read_csv_auto('data/olist_orders_dataset.csv', header=true) o
    JOIN read_csv_auto('data/olist_customers_dataset.csv', header=true) c
        USING (customer_id)
),
cohort_data AS (
    SELECT
        cf.cohort_month,
        DATE_DIFF('month', cf.cohort_month, ca.activity_month) AS months_since_first,
        COUNT(DISTINCT ca.customer_unique_id) AS active_customers
    FROM customer_first cf
    JOIN customer_activity ca USING (customer_unique_id)
    GROUP BY cf.cohort_month, months_since_first
),
cohort_size AS (
    SELECT cohort_month, COUNT(*) AS cohort_customers
    FROM customer_first
    GROUP BY cohort_month
)
SELECT
    cs.cohort_month,
    cs.cohort_customers,
    age.months_since_first,
    CASE WHEN cs.cohort_month + (age.months_since_first + 1) * INTERVAL 1 MONTH
              <= DATE_TRUNC('month', (SELECT MAX(purchased_at) FROM stg_orders))
         THEN COALESCE(cd.active_customers, 0) END AS active_customers,
    CASE WHEN cs.cohort_month + (age.months_since_first + 1) * INTERVAL 1 MONTH
              <= DATE_TRUNC('month', (SELECT MAX(purchased_at) FROM stg_orders))
         THEN ROUND(COALESCE(cd.active_customers, 0) * 100.0 / cs.cohort_customers, 2)
         END AS retention_pct
FROM cohort_size cs
CROSS JOIN RANGE(0, 13) age(months_since_first)
LEFT JOIN cohort_data cd ON cs.cohort_month = cd.cohort_month
    AND age.months_since_first = cd.months_since_first
WHERE cs.cohort_customers >= 50
ORDER BY cs.cohort_month, age.months_since_first;


-- =========================================
-- Q3: One-Time vs Repeat Buyer Comparison
-- =========================================
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(i.total_gmv) AS lifetime_gmv
    FROM read_csv_auto('data/olist_orders_dataset.csv', header=true) o
    JOIN read_csv_auto('data/olist_customers_dataset.csv', header=true) c
        USING (customer_id)
    LEFT JOIN (
        SELECT order_id, SUM(price) AS total_gmv
        FROM read_csv_auto('data/olist_order_items_dataset.csv', header=true)
        GROUP BY order_id
    ) i USING (order_id)
    GROUP BY c.customer_unique_id
)
SELECT
    CASE WHEN order_count > 1 THEN 'Repeat' ELSE 'One-time' END AS customer_type,
    COUNT(*)                        AS customer_count,
    ROUND(AVG(order_count), 2)      AS avg_orders,
    ROUND(AVG(lifetime_gmv), 2)     AS avg_lifetime_gmv,
    ROUND(SUM(lifetime_gmv), 2)     AS total_gmv,
    ROUND(SUM(lifetime_gmv) * 100.0 / SUM(SUM(lifetime_gmv)) OVER(), 2)
                                    AS gmv_share_pct
FROM customer_orders
GROUP BY CASE WHEN order_count > 1 THEN 'Repeat' ELSE 'One-time' END;


-- =========================================
-- Q4: RFM Segmentation using NTILE
-- Recency (days since last order), Frequency (order count), Monetary (total GMV)
-- =========================================
WITH customer_rfm AS (
    SELECT
        c.customer_unique_id,
        DATE_DIFF('day',
            MAX(TRY_CAST(o.order_purchase_timestamp AS TIMESTAMP)),
            (SELECT MAX(purchased_at) FROM stg_orders)
        ) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        COALESCE(SUM(i.total_gmv), 0) AS monetary
    FROM read_csv_auto('data/olist_orders_dataset.csv', header=true) o
    JOIN read_csv_auto('data/olist_customers_dataset.csv', header=true) c
        USING (customer_id)
    LEFT JOIN (
        SELECT order_id, SUM(price) AS total_gmv
        FROM read_csv_auto('data/olist_order_items_dataset.csv', header=true)
        GROUP BY order_id
    ) i USING (order_id)
    GROUP BY c.customer_unique_id
),
rfm_scored AS (
    SELECT
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        -- Frequency is a fixed 1..5+ count score so equal counts stay together.
        -- Deterministic customer tie-breakers stabilize recency and value quantiles.
        NTILE(5) OVER (ORDER BY recency_days DESC, customer_unique_id)  AS r_score,  -- Lower recency = higher score
        LEAST(frequency, 5)           AS f_score,
        NTILE(5) OVER (ORDER BY monetary, customer_unique_id)            AS m_score
    FROM customer_rfm
)
SELECT
    r_score, f_score, m_score,
    COUNT(*) AS customer_count,
    ROUND(AVG(recency_days), 0)  AS avg_recency_days,
    ROUND(AVG(frequency), 2)     AS avg_frequency,
    ROUND(AVG(monetary), 2)      AS avg_monetary
FROM rfm_scored
GROUP BY r_score, f_score, m_score
HAVING COUNT(*) >= 50
ORDER BY r_score DESC, f_score DESC, m_score DESC;


-- =========================================
-- Q5: Customer Geographic Distribution
-- =========================================
SELECT
    customer_state,
    COUNT(DISTINCT customer_unique_id)  AS unique_customers,
    COUNT(*)                            AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS order_share_pct,
    ROUND(SUM(gmv), 2)                 AS total_gmv,
    ROUND(AVG(review_score), 2)        AS avg_review
FROM mart_order_delivery
GROUP BY customer_state
ORDER BY total_orders DESC;

-- Q6. Observed 90-day repeat purchase among customers with a mature window.
-- All created-order statuses are included consistently with the headline repeat metric.
-- A sparse snapshot tail can affect maturity; verify a business cutoff before pilot use.
WITH customer_purchase AS (
    SELECT c.customer_unique_id, o.order_id, o.purchased_at,
           MIN(o.purchased_at) OVER(PARTITION BY c.customer_unique_id) AS first_purchase
    FROM stg_orders o
    JOIN read_csv_auto('data/olist_customers_dataset.csv') c USING(customer_id)
), mature_customers AS (
    SELECT customer_unique_id, first_purchase,
           COUNT(DISTINCT order_id) FILTER (
               WHERE purchased_at <= first_purchase + INTERVAL 90 DAY) AS orders_90d
    FROM customer_purchase
    WHERE first_purchase + INTERVAL 90 DAY <= (SELECT MAX(purchased_at) FROM stg_orders)
    GROUP BY customer_unique_id, first_purchase
)
SELECT DATE_TRUNC('month',first_purchase) AS cohort_month,
       COUNT(*) AS mature_customers,
       COUNT(*) FILTER(WHERE orders_90d > 1) AS repeat_customers_90d,
       ROUND(COUNT(*) FILTER(WHERE orders_90d > 1)*100.0/COUNT(*),2) AS repeat_rate_90d_pct
FROM mature_customers GROUP BY cohort_month ORDER BY cohort_month;

-- Descriptive uncertainty and review comparisons for calendar-date delivery SLA.
-- Wilson bounds describe binomial sampling uncertainty under independent trials.
-- Correlated geography/seller events and selection into reviews remain limitations.

-- Q1. All states remain visible; 100 orders is a screening threshold, not proof.
WITH counts AS (
    SELECT customer_state, COUNT(*) AS delivered_orders,
           SUM(is_late::INT) AS late_orders, AVG(is_late::INT) AS late_rate
    FROM mart_order_delivery GROUP BY customer_state
)
SELECT *,
    (late_rate + 3.841458820694124 / (2 * delivered_orders)
        - 1.959963984540054 * SQRT(late_rate * (1-late_rate) / delivered_orders
            + 3.841458820694124 / (4 * delivered_orders * delivered_orders)))
        / (1 + 3.841458820694124 / delivered_orders) AS late_rate_wilson95_lower,
    (late_rate + 3.841458820694124 / (2 * delivered_orders)
        + 1.959963984540054 * SQRT(late_rate * (1-late_rate) / delivered_orders
            + 3.841458820694124 / (4 * delivered_orders * delivered_orders)))
        / (1 + 3.841458820694124 / delivered_orders) AS late_rate_wilson95_upper,
    CASE WHEN delivered_orders >= 100 THEN 'meets_screening_minimum'
         ELSE 'small_sample_monitor_only' END AS sample_flag
FROM counts ORDER BY delivered_orders DESC;

-- Q2. Comparable state and purchase-month cells with coverage for both groups.
WITH strata AS (
    SELECT customer_state, order_month,
           COUNT(*) FILTER (WHERE is_late) AS late_orders,
           COUNT(*) FILTER (WHERE NOT is_late) AS on_time_orders,
           COUNT(review_score) FILTER (WHERE is_late) AS late_reviewed,
           COUNT(review_score) FILTER (WHERE NOT is_late) AS on_time_reviewed,
           AVG(review_score) FILTER (WHERE is_late) AS late_review,
           AVG(review_score) FILTER (WHERE NOT is_late) AS on_time_review
    FROM mart_order_delivery GROUP BY customer_state, order_month
)
SELECT *, late_reviewed * 1.0 / NULLIF(late_orders,0) AS late_review_coverage,
       on_time_reviewed * 1.0 / NULLIF(on_time_orders,0) AS on_time_review_coverage,
       on_time_review - late_review AS descriptive_review_gap,
       CASE WHEN late_reviewed >= 30 AND on_time_reviewed >= 30
            THEN 'comparable_screening_cell' ELSE 'small_or_missing_review_group' END AS comparison_flag
FROM strata ORDER BY customer_state, order_month;

-- Q3. Common-mix descriptive means, weighted by pooled reviewed orders per cell.
-- Both groups use identical weights. This is neither a treatment effect nor a forecast.
WITH strata AS (
    SELECT customer_state, order_month,
           COUNT(review_score) FILTER (WHERE is_late) AS late_reviewed,
           COUNT(review_score) FILTER (WHERE NOT is_late) AS on_time_reviewed,
           AVG(review_score) FILTER (WHERE is_late) AS late_review,
           AVG(review_score) FILTER (WHERE NOT is_late) AS on_time_review
    FROM mart_order_delivery GROUP BY customer_state, order_month
), common_cells AS (
    SELECT *, late_reviewed + on_time_reviewed AS pooled_weight
    FROM strata WHERE late_reviewed >= 30 AND on_time_reviewed >= 30
)
SELECT COUNT(*) AS comparable_cells, SUM(late_reviewed) AS late_reviewed,
       SUM(on_time_reviewed) AS on_time_reviewed,
       SUM(late_review * pooled_weight) / SUM(pooled_weight) AS common_mix_late_review,
       SUM(on_time_review * pooled_weight) / SUM(pooled_weight) AS common_mix_on_time_review,
       SUM((on_time_review - late_review) * pooled_weight) / SUM(pooled_weight)
           AS common_mix_descriptive_gap,
       SUM(pooled_weight) * 1.0 / (SELECT COUNT(review_score) FROM mart_order_delivery)
           AS fraction_of_reviewed_orders_in_common_cells
FROM common_cells;

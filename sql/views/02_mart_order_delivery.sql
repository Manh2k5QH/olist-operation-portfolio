-- ============================================================================
-- VIEW: mart_order_delivery (Delivery Performance Mart)
-- ============================================================================
-- Purpose:   Central fact table for delivery analysis. Joins order header with
--            customer attributes, aggregated item financials, and aggregated
--            review scores. Filtered to delivered orders with both delivery
--            dates present (96,470 rows).
-- Grain:     One row per delivered order
-- Key:       order_id
-- Design:    Each CTE aggregates to order grain BEFORE joining to prevent
--            row multiplication from 1:N relationships.
-- ============================================================================

CREATE OR REPLACE VIEW mart_order_delivery AS

-- CTE 1: Customer attributes (1:1 with orders via customer_id)
WITH customer AS (
    SELECT
        customer_id,
        customer_unique_id,
        customer_state,
        customer_city
    FROM read_csv_auto('data/olist_customers_dataset.csv', header=true)
),

-- CTE 2: Review scores aggregated to order level
-- Averages observed review rows per order. Coverage is reported separately.
review AS (
    SELECT
        order_id,
        AVG(review_score)   AS review_score,
        COUNT(*)            AS review_count
    FROM read_csv_auto('data/olist_order_reviews_dataset.csv', header=true)
    GROUP BY order_id
),

-- CTE 3: Item financials aggregated to order level
-- GMV = SUM(price), NOT payment_value. Freight is a cost signal, not margin.
finance AS (
    SELECT
        order_id,
        SUM(price)                  AS gmv,
        SUM(freight_value)          AS freight_value,
        COUNT(*)                    AS item_count,
        COUNT(DISTINCT seller_id)   AS seller_count,
        COUNT(DISTINCT product_id)  AS product_count
    FROM read_csv_auto('data/olist_order_items_dataset.csv', header=true)
    GROUP BY order_id
)

-- Final assembly: join all CTEs to staged orders
SELECT
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_state,
    c.customer_city,
    o.order_status,
    o.purchased_at,
    o.approved_at,
    o.delivered_carrier_at,
    o.delivered_at,
    o.estimated_at,
    o.order_month,
    o.order_year,
    o.delay_days,
    o.delay_elapsed_days,
    o.is_late,
    o.delivery_days,
    f.gmv,
    f.freight_value,
    -- Freight share: cost signal, NOT profit margin
    f.freight_value / NULLIF(f.gmv + f.freight_value, 0)  AS freight_share,
    f.item_count,
    f.seller_count,
    f.product_count,
    r.review_score,
    r.review_count
FROM stg_orders o
LEFT JOIN customer c USING (customer_id)
LEFT JOIN finance  f USING (order_id)
LEFT JOIN review   r USING (order_id)
WHERE o.order_status = 'delivered'
  AND o.delivered_at  IS NOT NULL
  AND o.estimated_at  IS NOT NULL;

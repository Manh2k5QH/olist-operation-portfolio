-- ============================================================================
-- VIEW: mart_seller (Seller Performance Mart)
-- ============================================================================
-- Purpose:   Aggregate seller-level performance metrics including order volume,
--            GMV, freight, and delivery quality (late rate). Joins item-level
--            data with delivery outcomes for a complete seller scorecard.
-- Grain:     One row per seller (3,095 sellers)
-- Design:    Two-stage aggregation: (1) items → seller totals, (2) delivery
--            mart → seller late rate. Volume guardrail flag included.
-- ============================================================================

CREATE OR REPLACE VIEW mart_seller AS

-- CTE 1: Seller profile from seller registry
WITH seller_profile AS (
    SELECT
        seller_id,
        seller_state,
        seller_city,
        seller_zip_code_prefix
    FROM read_csv_auto('data/olist_sellers_dataset.csv', header=true)
),

-- CTE 2: Item-level aggregation per seller
seller_items AS (
    SELECT
        seller_id,
        COUNT(*)                    AS item_rows,
        COUNT(DISTINCT order_id)    AS total_orders,
        SUM(price)                  AS gmv,
        SUM(freight_value)          AS freight_value,
        AVG(price)                  AS avg_item_price,
        SUM(freight_value) / NULLIF(SUM(price) + SUM(freight_value), 0)
                                    AS freight_share
    FROM read_csv_auto('data/olist_order_items_dataset.csv', header=true)
    GROUP BY seller_id
),

-- CTE 3: Delivery quality per seller (from delivered orders only)
-- Each seller-order contributes once. This measures exposure, not carrier/seller liability.
seller_order AS (
    SELECT DISTINCT seller_id, order_id
    FROM read_csv_auto('data/olist_order_items_dataset.csv', header=true)
),
seller_delivery AS (
    SELECT
        i.seller_id,
        COUNT(DISTINCT m.order_id)  AS delivered_orders,
        SUM(CASE WHEN m.is_late THEN 1 ELSE 0 END)  AS late_orders,
        AVG(CASE WHEN m.is_late THEN 1.0 ELSE 0.0 END) AS late_rate,
        AVG(m.review_score)         AS avg_review_score,
        AVG(m.delay_days)           AS avg_delay_days
    FROM seller_order i
    INNER JOIN mart_order_delivery m ON i.order_id = m.order_id
    GROUP BY i.seller_id
)

SELECT
    sp.seller_id,
    sp.seller_state,
    sp.seller_city,
    si.item_rows,
    si.total_orders,
    si.gmv,
    si.freight_value,
    si.avg_item_price,
    si.freight_share,
    sd.delivered_orders,
    sd.late_orders,
    sd.late_rate,
    sd.avg_review_score,
    sd.avg_delay_days,
    -- Volume guardrail: flag sellers with insufficient sample for rate metrics
    CASE
        WHEN sd.delivered_orders >= 30 THEN 'sufficient'
        ELSE 'insufficient_sample'
    END AS volume_flag
FROM seller_profile sp
LEFT JOIN seller_items    si ON sp.seller_id = si.seller_id
LEFT JOIN seller_delivery sd ON sp.seller_id = sd.seller_id;

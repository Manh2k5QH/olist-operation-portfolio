-- ============================================================================
-- VIEW: stg_orders (Staging Layer — Order Header)
-- ============================================================================
-- Purpose:   Parse raw order timestamps into typed columns and derive
--            delivery performance fields for downstream marts.
-- Source:    data/olist_orders_dataset.csv
-- Grain:     One row per order (99,441 rows)
-- Key:       order_id (unique)
-- Usage:     Base view for mart_order_delivery and all delivery analysis
-- ============================================================================

CREATE OR REPLACE VIEW stg_orders AS
SELECT
    order_id,
    customer_id,
    order_status,

    -- Parsed timestamps
    TRY_CAST(order_purchase_timestamp       AS TIMESTAMP) AS purchased_at,
    TRY_CAST(order_approved_at              AS TIMESTAMP) AS approved_at,
    TRY_CAST(order_delivered_carrier_date   AS TIMESTAMP) AS delivered_carrier_at,
    TRY_CAST(order_delivered_customer_date  AS TIMESTAMP) AS delivered_at,
    TRY_CAST(order_estimated_delivery_date  AS TIMESTAMP) AS estimated_at,

    -- Derived time dimensions
    DATE_TRUNC('month', TRY_CAST(order_purchase_timestamp AS TIMESTAMP))  AS order_month,
    EXTRACT(YEAR  FROM TRY_CAST(order_purchase_timestamp AS TIMESTAMP))   AS order_year,
    EXTRACT(DOW   FROM TRY_CAST(order_purchase_timestamp AS TIMESTAMP))   AS day_of_week,

    -- Delivery performance fields (only meaningful for delivered orders with both dates)
    DATE_DIFF('day',
        TRY_CAST(order_estimated_delivery_date  AS TIMESTAMP),
        TRY_CAST(order_delivered_customer_date  AS TIMESTAMP)
    ) AS delay_days,

    EPOCH(TRY_CAST(order_delivered_customer_date AS TIMESTAMP)
        - TRY_CAST(order_estimated_delivery_date AS TIMESTAMP)) / 86400.0
        AS delay_elapsed_days,
    CASE
        WHEN order_status <> 'delivered'
          OR TRY_CAST(order_delivered_customer_date AS TIMESTAMP) IS NULL
          OR TRY_CAST(order_estimated_delivery_date AS TIMESTAMP) IS NULL THEN NULL
        ELSE CAST(order_delivered_customer_date AS DATE)
           > CAST(order_estimated_delivery_date AS DATE)
    END AS is_late,

    -- Total delivery duration (purchase to delivery, in days)
    DATE_DIFF('day',
        TRY_CAST(order_purchase_timestamp       AS TIMESTAMP),
        TRY_CAST(order_delivered_customer_date  AS TIMESTAMP)
    ) AS delivery_days

FROM read_csv_auto('data/olist_orders_dataset.csv', header=true);

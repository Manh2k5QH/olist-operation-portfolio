-- ============================================================================
-- ANALYSIS: Control Totals & Cross-Table Reconciliation
-- ============================================================================
-- Purpose:   Verify data integrity across tables. Confirm row counts, key
--            uniqueness, and cross-table metric reconciliation.
-- Expected:  orders=99,441 | GMV=R$13,591,643.70 | Freight=R$2,251,909.54
--            Payment=R$16,008,872.12 | Gap(payment - GMV+freight)=~R$165K
-- ============================================================================

-- 1. Order table integrity
SELECT
    'orders'            AS source,
    COUNT(*)            AS total_rows,
    COUNT(DISTINCT order_id)  AS distinct_keys,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_rows
FROM read_csv_auto('data/olist_orders_dataset.csv', header=true);

-- 2. Order status distribution
SELECT
    order_status,
    COUNT(*)            AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM read_csv_auto('data/olist_orders_dataset.csv', header=true)
GROUP BY order_status
ORDER BY order_count DESC;

-- 3. GMV and Freight from items (source of truth for financial metrics)
SELECT
    'order_items'       AS source,
    COUNT(*)            AS item_rows,
    COUNT(DISTINCT order_id) AS distinct_orders,
    ROUND(SUM(price), 2)          AS gmv,
    ROUND(SUM(freight_value), 2)  AS freight_value,
    ROUND(SUM(price) + SUM(freight_value), 2) AS gmv_plus_freight
FROM read_csv_auto('data/olist_order_items_dataset.csv', header=true);

-- 4. Payment total (should NOT equal GMV; different measurement)
SELECT
    'payments'          AS source,
    COUNT(*)            AS payment_rows,
    COUNT(DISTINCT order_id) AS distinct_orders,
    ROUND(SUM(payment_value), 2)  AS payment_total
FROM read_csv_auto('data/olist_order_payments_dataset.csv', header=true);

-- 5. Reconciliation gap (payment vs items)
WITH items AS (
    SELECT SUM(price) + SUM(freight_value) AS item_total
    FROM read_csv_auto('data/olist_order_items_dataset.csv', header=true)
),
payments AS (
    SELECT SUM(payment_value) AS payment_total
    FROM read_csv_auto('data/olist_order_payments_dataset.csv', header=true)
)
SELECT
    ROUND(i.item_total, 2)                        AS item_total_gmv_freight,
    ROUND(p.payment_total, 2)                     AS payment_total,
    ROUND(p.payment_total - i.item_total, 2)      AS gap,
    ROUND((p.payment_total - i.item_total) / i.item_total * 100, 2) AS gap_pct
FROM items i, payments p;
-- The difference is observable; fees, insurance or refunds require separate evidence.

-- 6. Data quality summary across all tables
SELECT 'customers'   AS tbl, COUNT(*) AS rows, COUNT(DISTINCT customer_id) AS dk FROM read_csv_auto('data/olist_customers_dataset.csv', header=true)
UNION ALL
SELECT 'reviews',    COUNT(*), COUNT(DISTINCT review_id) FROM read_csv_auto('data/olist_order_reviews_dataset.csv', header=true)
UNION ALL
SELECT 'products',   COUNT(*), COUNT(DISTINCT product_id) FROM read_csv_auto('data/olist_products_dataset.csv', header=true)
UNION ALL
SELECT 'sellers',    COUNT(*), COUNT(DISTINCT seller_id) FROM read_csv_auto('data/olist_sellers_dataset.csv', header=true)
UNION ALL
SELECT 'geolocation', COUNT(*), COUNT(DISTINCT geolocation_zip_code_prefix) FROM read_csv_auto('data/olist_geolocation_dataset.csv', header=true);

-- 7. Reconcile each order before interpreting the aggregate difference.
WITH item_total AS (
    SELECT order_id, ROUND(SUM(price + freight_value), 2) AS item_amount
    FROM read_csv_auto('data/olist_order_items_dataset.csv') GROUP BY order_id
), payment_total AS (
    SELECT order_id, ROUND(SUM(payment_value), 2) AS payment_amount
    FROM read_csv_auto('data/olist_order_payments_dataset.csv') GROUP BY order_id
), comparison AS (
    SELECT COALESCE(i.order_id,p.order_id) AS order_id,
           COALESCE(i.item_amount,0) AS item_amount,
           COALESCE(p.payment_amount,0) AS payment_amount,
           CASE WHEN i.order_id IS NULL THEN 'payment_without_items'
                WHEN p.order_id IS NULL THEN 'items_without_payment'
                WHEN ABS(p.payment_amount-i.item_amount) < 0.005 THEN 'matched'
                WHEN p.payment_amount > i.item_amount THEN 'payment_higher'
                ELSE 'payment_lower' END AS reconciliation_group
    FROM item_total i FULL OUTER JOIN payment_total p USING(order_id)
)
SELECT reconciliation_group, COUNT(*) AS orders,
       ROUND(SUM(item_amount),2) AS item_amount,
       ROUND(SUM(payment_amount),2) AS payment_amount,
       ROUND(SUM(payment_amount-item_amount),2) AS difference
FROM comparison GROUP BY reconciliation_group ORDER BY reconciliation_group;

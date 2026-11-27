-- ============================================================================
-- VIEW: mart_category (Category Economics Mart)
-- ============================================================================
-- Purpose:   Aggregate item-level data by translated product category to
--            support category GMV, freight share, and volume analysis.
-- Grain:     One row per translated category (74 categories + 'Unknown')
-- Design:    Translates Portuguese category names to English. Products with
--            NULL category are mapped to 'Unknown' (610 products, ~1,603 items).
--            Freight share is labeled as a cost signal, NOT margin.
-- ============================================================================

CREATE OR REPLACE VIEW mart_category AS

WITH translation AS (
    SELECT
        product_category_name,
        product_category_name_english
    FROM read_csv_auto('data/product_category_name_translation.csv', header=true)
),

products AS (
    SELECT
        product_id,
        product_category_name
    FROM read_csv_auto('data/olist_products_dataset.csv', header=true)
)

SELECT
    -- Translate category: English name > Portuguese name > 'Unknown'
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS category,

    -- Volume metrics
    COUNT(*)                    AS item_rows,
    COUNT(DISTINCT i.order_id)  AS order_count,
    COUNT(DISTINCT i.seller_id) AS seller_count,

    -- Financial metrics
    SUM(i.price)                AS gmv,
    SUM(i.freight_value)        AS freight_value,
    AVG(i.price)                AS avg_price,
    AVG(i.freight_value)        AS avg_freight,

    -- Freight share: logistics cost signal, NOT profit margin
    SUM(i.freight_value) / NULLIF(SUM(i.price) + SUM(i.freight_value), 0)
        AS freight_share

FROM read_csv_auto('data/olist_order_items_dataset.csv', header=true) i
LEFT JOIN products    p USING (product_id)
LEFT JOIN translation t USING (product_category_name)
GROUP BY 1;

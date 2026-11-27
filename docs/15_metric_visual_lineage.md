# Metric and visual lineage

Reviewed 27 November 2026 against the native project source. The authoritative editable source is the locally retained PBIP source, project.SemanticModel (see [exported DAX](../dax/measures.md)) and project.Report (see [exported DAX](../dax/measures.md)). Only the final native report is included in this public package.

The native model defines **27 measures**. The mapping below enumerates every definition and its direct query references in the current report. A measure may be used transitively by another measure even when it has no direct visual reference. A structural reference check establishes that visual queries name existing measures. Desktop rendering and selected filter checks are recorded in [the UAT register](14_dashboard_uat.md).

## Definitions and direct visual locations

Category interactions use the active single-direction `CategoryMart.category â†’ Items.category` relationship. Item GMV, item-order AOV and freight share respond to category selection. Payment Total follows the selected order/date/state population; payment values are not allocated to product categories.

### CategoryMart[Category GMV]

Supporting count, comparison or financial context. Source fields are Products.product_category_name + translations; Items.price/freight_value and selection via TREATAS. Governed reference is [sql/views/03_mart_category.sql](../sql/views/03_mart_category.sql).

```dax
CALCULATE([GMV], TREATAS(VALUES(CategoryMart[category]), Items[category]))
```

Definition is CategoryMart.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Sales and Orders.

### CategoryMart[Category Freight Share]

KPI-003. Source fields are Products.product_category_name + translations; Items.price/freight_value and selection via TREATAS. Governed reference is [sql/views/03_mart_category.sql](../sql/views/03_mart_category.sql).

```dax
CALCULATE([Freight Share], TREATAS(VALUES(CategoryMart[category]), Items[category]))
```

Definition is CategoryMart.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Sales and Orders.

### Customers[Unique Customers]

Supporting count, comparison or financial context. Source fields are Customers.customer_unique_id/customer_id; Orders.order_id/customer_id. Governed reference is [sql/analysis/03_customer_analysis.sql](../sql/analysis/03_customer_analysis.sql).

```dax
CALCULATE(DISTINCTCOUNT(Customers[customer_unique_id]), TREATAS(VALUES(Orders[customer_id]), Customers[customer_id]))
```

Definition is Customers.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Customer Insights.

### Customers[Repeat Buyers]

Supporting count, comparison or financial context. Source fields are Customers.customer_unique_id/customer_id; Orders.order_id/customer_id. Governed reference is [sql/analysis/03_customer_analysis.sql](../sql/analysis/03_customer_analysis.sql).

```dax
COUNTROWS(FILTER(VALUES(Customers[customer_unique_id]), CALCULATE(DISTINCTCOUNT(Orders[order_id])) > 1))
```

Definition is Customers.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Customer Insights.

### Customers[Repeat Rate]

KPI-007. Source fields are Customers.customer_unique_id/customer_id; Orders.order_id/customer_id. Governed reference is [sql/analysis/03_customer_analysis.sql](../sql/analysis/03_customer_analysis.sql).

```dax
DIVIDE([Repeat Buyers], [Unique Customers])
```

Definition is Customers.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Customer Insights, Overview.

### Items[GMV]

KPI-001. Source fields are Items.price, freight_value, order_id; products.category; Orders order/date/state filter. Governed reference is [sql/views/03_mart_category.sql](../sql/views/03_mart_category.sql).

```dax
SUMX(Items, Items[price])
```

Definition is Items.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Overview, Sales and Orders.

### Items[Freight]

Supporting count, comparison or financial context. Source fields are Items.price, freight_value, order_id; products.category; Orders order/date/state filter. Governed reference is [sql/views/03_mart_category.sql](../sql/views/03_mart_category.sql).

```dax
SUMX(Items, Items[freight_value])
```

Definition is Items.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Defined for use by other measures or further analysis; no direct active visual query.

### Items[Freight Share]

KPI-003. Source fields are Items.price, freight_value, order_id; products.category; Orders order/date/state filter. Governed reference is [sql/views/03_mart_category.sql](../sql/views/03_mart_category.sql).

```dax
DIVIDE([Freight], [GMV] + [Freight])
```

Definition is Items.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Sales and Orders.

### OrderDelivery[Delivered Orders]

Supporting count, comparison or financial context. Source fields are Orders delivery timestamps/status; per-order AVG(Reviews.review_score); calendar is_late/delay_days. Governed reference is [sql/views/02_mart_order_delivery.sql](../sql/views/02_mart_order_delivery.sql).

```dax
CALCULATE(DISTINCTCOUNT(OrderDelivery[order_id]))
```

Definition is OrderDelivery.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Customer Reviews, Delivery Performance, Overview.

### OrderDelivery[Late Orders]

Supporting count, comparison or financial context. Source fields are Orders delivery timestamps/status; per-order AVG(Reviews.review_score); calendar is_late/delay_days. Governed reference is [sql/views/02_mart_order_delivery.sql](../sql/views/02_mart_order_delivery.sql).

```dax
CALCULATE(DISTINCTCOUNT(OrderDelivery[order_id]), OrderDelivery[is_late] = TRUE())
```

Definition is OrderDelivery.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Delivery Performance, Overview.

### OrderDelivery[Late Delivery Rate]

KPI-004. Source fields are Orders delivery timestamps/status; per-order AVG(Reviews.review_score); calendar is_late/delay_days. Governed reference is [sql/views/02_mart_order_delivery.sql](../sql/views/02_mart_order_delivery.sql).

```dax
DIVIDE([Late Orders], [Delivered Orders])
```

Definition is OrderDelivery.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Delivery Performance, Overview.

### OrderDelivery[Average Late Days]

KPI-009. Source fields are Orders delivery timestamps/status; per-order AVG(Reviews.review_score); calendar is_late/delay_days. Governed reference is [sql/views/02_mart_order_delivery.sql](../sql/views/02_mart_order_delivery.sql).

```dax
CALCULATE(AVERAGE(OrderDelivery[delay_days]), OrderDelivery[is_late] = TRUE())
```

Definition is OrderDelivery.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Delivery Performance.

### OrderDelivery[Average Review]

KPI-006. Source fields are Orders delivery timestamps/status; per-order AVG(Reviews.review_score); calendar is_late/delay_days. Governed reference is [sql/views/02_mart_order_delivery.sql](../sql/views/02_mart_order_delivery.sql).

```dax
AVERAGE(OrderDelivery[review_score])
```

Definition is OrderDelivery.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Customer Reviews, Overview.

### OrderDelivery[On-time Review]

Supporting count, comparison or financial context. Source fields are Orders delivery timestamps/status; per-order AVG(Reviews.review_score); calendar is_late/delay_days. Governed reference is [sql/views/02_mart_order_delivery.sql](../sql/views/02_mart_order_delivery.sql).

```dax
CALCULATE([Average Review], OrderDelivery[is_late] = FALSE())
```

Definition is OrderDelivery.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Defined for use by other measures or further analysis; no direct active visual query.

### OrderDelivery[Late-order Review]

Supporting count, comparison or financial context. Source fields are Orders delivery timestamps/status; per-order AVG(Reviews.review_score); calendar is_late/delay_days. Governed reference is [sql/views/02_mart_order_delivery.sql](../sql/views/02_mart_order_delivery.sql).

```dax
CALCULATE([Average Review], OrderDelivery[is_late] = TRUE())
```

Definition is OrderDelivery.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Defined for use by other measures or further analysis; no direct active visual query.

### OrderDelivery[Review Gap]

KPI-005. Source fields are Orders delivery timestamps/status; per-order AVG(Reviews.review_score); calendar is_late/delay_days. Governed reference is [sql/views/02_mart_order_delivery.sql](../sql/views/02_mart_order_delivery.sql).

```dax
[On-time Review] - [Late-order Review]
```

Definition is OrderDelivery.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Customer Reviews.

### OrderDelivery[Reviewed Orders]

Supporting count, comparison or financial context. Source fields are Orders delivery timestamps/status; per-order AVG(Reviews.review_score); calendar is_late/delay_days. Governed reference is [sql/views/02_mart_order_delivery.sql](../sql/views/02_mart_order_delivery.sql).

```dax
COUNT(OrderDelivery[review_score])
```

Definition is OrderDelivery.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Defined for use by other measures or further analysis; no direct active visual query.

### OrderDelivery[Review Coverage]

KPI-010. Source fields are Orders delivery timestamps/status; per-order AVG(Reviews.review_score); calendar is_late/delay_days. Governed reference is [sql/views/02_mart_order_delivery.sql](../sql/views/02_mart_order_delivery.sql).

```dax
DIVIDE([Reviewed Orders], [Delivered Orders])
```

Definition is OrderDelivery.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Customer Reviews.

### Orders[Orders]

Supporting count, comparison or financial context. Source fields are Orders.order_id, order_status; Items.order_id/price; Payments.payment_value. Governed reference is [sql/analysis/01_control_totals.sql](../sql/analysis/01_control_totals.sql).

```dax
DISTINCTCOUNT(Orders[order_id])
```

Definition is Orders.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Overview.

### Orders[AOV]

KPI-002. Source fields are Orders.order_id, order_status; Items.order_id/price; Payments.payment_value. Governed reference is [sql/analysis/01_control_totals.sql](../sql/analysis/01_control_totals.sql).

```dax
DIVIDE([GMV], DISTINCTCOUNT(Items[order_id]))
```

Definition is Orders.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Customer Insights, Sales and Orders.

### Orders[Payment Total]

Supporting count, comparison or financial context. Source fields are Orders.order_id, order_status; Items.order_id/price; Payments.payment_value. Governed reference is [sql/analysis/01_control_totals.sql](../sql/analysis/01_control_totals.sql).

```dax
SUM(Payments[payment_value])
```

Definition is Orders.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Sales and Orders.

### Orders[Cancellation Rate]

Supporting count, comparison or financial context. Source fields are Orders.order_id, order_status; Items.order_id/price; Payments.payment_value. Governed reference is [sql/analysis/01_control_totals.sql](../sql/analysis/01_control_totals.sql).

```dax
DIVIDE(CALCULATE([Orders], Orders[order_status] = "canceled"), [Orders])
```

Definition is Orders.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Defined for use by other measures or further analysis; no direct active visual query.

### SellerMart[Seller Eligible Orders]

Supporting count, comparison or financial context. Source fields are Items.seller_id/order_id; eligible OrderDelivery.order_id/is_late; DISTINCTCOUNT per selected seller. Governed reference is [sql/views/04_mart_seller.sql](../sql/views/04_mart_seller.sql).

```dax
CALCULATE(DISTINCTCOUNT(Items[order_id]), TREATAS(VALUES(OrderDelivery[order_id]), Items[order_id]))
```

Definition is SellerMart.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Delivery Performance.

### SellerMart[Seller Late Orders]

Supporting count, comparison or financial context. Source fields are Items.seller_id/order_id; eligible OrderDelivery.order_id/is_late; DISTINCTCOUNT per selected seller. Governed reference is [sql/views/04_mart_seller.sql](../sql/views/04_mart_seller.sql).

```dax
CALCULATE(DISTINCTCOUNT(Items[order_id]), TREATAS(CALCULATETABLE(VALUES(OrderDelivery[order_id]), OrderDelivery[is_late] = TRUE()), Items[order_id]))
```

Definition is SellerMart.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Delivery Performance.

### SellerMart[Seller Late Rate]

KPI-008. Source fields are Items.seller_id/order_id; eligible OrderDelivery.order_id/is_late; DISTINCTCOUNT per selected seller. Governed reference is [sql/views/04_mart_seller.sql](../sql/views/04_mart_seller.sql).

```dax
IF([Seller Eligible Orders] >= 30, DIVIDE([Seller Late Orders], [Seller Eligible Orders]))
```

Definition is SellerMart.tmdl (see [exported DAX](../dax/measures.md)). Direct report pages are Delivery Performance.

## Visual query inventory

| Page | Visual type | Direct measures | Source definition |
|---|---|---|---|
| Overview | card | OrderDelivery[Late Delivery Rate] | 26dfcdbdae4ab03402e7 (see [exported DAX](../dax/measures.md)) |
| Overview | card | Items[GMV] | 3afbb334e163be5427e7 (see [exported DAX](../dax/measures.md)) |
| Overview | card | Orders[Orders] | 5ad5b6f44bb2322af177 (see [exported DAX](../dax/measures.md)) |
| Overview | barChart | OrderDelivery[Average Review] | 68aae00475fee7382e12 (see [exported DAX](../dax/measures.md)) |
| Overview | lineChart | Items[GMV] | 92f5a885be1d6a74b555 (see [exported DAX](../dax/measures.md)) |
| Overview | barChart | OrderDelivery[Late Orders] | d19bcd451ad4da4b8b20 (see [exported DAX](../dax/measures.md)) |
| Overview | card | Customers[Repeat Rate] | d8b06da6ce4fe013de77 (see [exported DAX](../dax/measures.md)) |
| Overview | donutChart | OrderDelivery[Delivered Orders] | da952e9e8fd6c076ddef (see [exported DAX](../dax/measures.md)) |
| Sales and Orders | card | Orders[AOV] | 554aea2b900d88a12ee5 (see [exported DAX](../dax/measures.md)) |
| Sales and Orders | card | Items[Freight Share] | 5a5ee79b84c71b4921b4 (see [exported DAX](../dax/measures.md)) |
| Sales and Orders | card | Orders[Payment Total] | 8e63d2088d4cca00c3b0 (see [exported DAX](../dax/measures.md)) |
| Sales and Orders | treemap | CategoryMart[Category Freight Share], CategoryMart[Category GMV] | c357ae179be146e7ec53 (see [exported DAX](../dax/measures.md)) |
| Sales and Orders | lineChart | Items[GMV] | d16f824c4c37b2e4bb8f (see [exported DAX](../dax/measures.md)) |
| Sales and Orders | barChart | CategoryMart[Category Freight Share], CategoryMart[Category GMV] | ec2497930add75b7d818 (see [exported DAX](../dax/measures.md)) |
| Sales and Orders | card | Items[GMV] | f762742ddcce6f1d271e (see [exported DAX](../dax/measures.md)) |
| Customer Insights | card | Customers[Repeat Buyers] | 15d3acba411805ac7e27 (see [exported DAX](../dax/measures.md)) |
| Customer Insights | lineChart | Customers[Repeat Rate] | 1ed4020cf2aa0ceccdc0 (see [exported DAX](../dax/measures.md)) |
| Customer Insights | barChart | Customers[Unique Customers] | 2fdecbe17234e50b6650 (see [exported DAX](../dax/measures.md)) |
| Customer Insights | card | Customers[Unique Customers] | 4fa1b9b1ed5952b7f75a (see [exported DAX](../dax/measures.md)) |
| Customer Insights | card | Customers[Repeat Rate] | 5650918383384c955f69 (see [exported DAX](../dax/measures.md)) |
| Customer Insights | card | Orders[AOV] | 951f18b6e88d78c93559 (see [exported DAX](../dax/measures.md)) |
| Delivery Performance | lineChart | OrderDelivery[Late Delivery Rate] | 1d07a73f1d9fd140ecfc (see [exported DAX](../dax/measures.md)) |
| Delivery Performance | card | OrderDelivery[Late Delivery Rate] | 2230c96fab936696336b (see [exported DAX](../dax/measures.md)) |
| Delivery Performance | card | OrderDelivery[Average Late Days] | 7084f3185e01ba5861f4 (see [exported DAX](../dax/measures.md)) |
| Delivery Performance | tableEx | OrderDelivery[Delivered Orders], OrderDelivery[Late Delivery Rate], OrderDelivery[Late Orders] | 7879245c7b7dc0ff220e (see [exported DAX](../dax/measures.md)) |
| Delivery Performance | card | OrderDelivery[Delivered Orders] | b1aae02c650e8121601c (see [exported DAX](../dax/measures.md)) |
| Delivery Performance | tableEx | SellerMart[Seller Eligible Orders], SellerMart[Seller Late Orders], SellerMart[Seller Late Rate] | c04a647c1b8fd6dd1610 (see [exported DAX](../dax/measures.md)) |
| Delivery Performance | barChart | OrderDelivery[Late Delivery Rate] | e8d0e76b4c29f2d0035c (see [exported DAX](../dax/measures.md)) |
| Delivery Performance | card | OrderDelivery[Late Orders] | f19f50e20e9da15d9a8d (see [exported DAX](../dax/measures.md)) |
| Customer Reviews | card | OrderDelivery[Average Review] | 10e7afb7dfcf92223ffc (see [exported DAX](../dax/measures.md)) |
| Customer Reviews | barChart | OrderDelivery[Average Review] | 54365c11a79a88450339 (see [exported DAX](../dax/measures.md)) |
| Customer Reviews | card | OrderDelivery[Review Coverage] | c61d278902b18f9e8600 (see [exported DAX](../dax/measures.md)) |
| Customer Reviews | columnChart | OrderDelivery[Delivered Orders] | d197b8914570666e630c (see [exported DAX](../dax/measures.md)) |
| Customer Reviews | card | OrderDelivery[Review Gap] | e3be5352a4df3b77beeb (see [exported DAX](../dax/measures.md)) |
| Customer Reviews | lineChart | OrderDelivery[Average Review] | edf3b340fe8f97c8d7db (see [exported DAX](../dax/measures.md)) |

## Interpretation and total behavior

- Item financial measures follow the selected item population. Item GMV includes all statuses unless the selection filters them. AOV divides by item-bearing distinct orders.
- OrderDelivery is the delivered subset with valid actual and estimated dates. Its count, review, coverage and SLA metrics use that population. The native review score averages the per-order mean from the governed data preparation.
- Same-date delivery is on time. Delay Days counts calendar boundaries, while elapsed-duration evidence is separately named.
- Category measures use TREATAS to apply category selection to item rows and then evaluate total financial measures. Freight share remains a ratio of total charges and amounts.
- Seller exposure uses distinct item order IDs, intersected with eligible or late delivery order IDs. The seller rate returns blank below 30 eligible orders. A shared order outcome does not establish an individual seller's responsibility.
- Customer count and repeat rate use customer_unique_id within the current order/date/state selection. A monthly repeat chart describes repeat behavior within that month, which differs from 90-day cohort retention.
- Full-snapshot evidence remains the reference for all-period values. DAX equality under a new combination of slicers requires a matching SQL comparison. The UAT register identifies the combinations actually exercised.

## Native delivery MoM extension

OrderDelivery[Late Rate MoM pp] compares the selected complete purchase month with the immediately prior calendar month. It removes only purchase-date and purchase-month filters when constructing full comparison months, retains destination context, requires current selected order count to match full-month order count, and requires at least 100 eligible deliveries in both months. It returns percentage points. Multiple/partial months and absent/low-volume comparators return BLANK.

OrderDelivery[Delivery MoM] formats that measure or shows Select one month, Full month needed or Insufficient data. It is bound to the fifth Delivery KPI card. Exact DAX is in OrderDelivery.tmdl (see [exported DAX](../dax/measures.md)); independent SQL/DAX cases are in [native_cases.json](../evidence/acceptance/native_cases.json). The reference analytical query is Q2 in [02_delivery_analysis.sql](../sql/analysis/02_delivery_analysis.sql); the native indicator additionally enforces the stated 100-order comparison guardrail.

The direct Delivery MoM card binding is 007dfcecbd1044819550 (see [exported DAX](../dax/measures.md)).

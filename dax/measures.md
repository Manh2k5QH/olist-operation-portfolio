# Native Power BI measures

27 measures exported from the verified native semantic model. The downloadable project.pbix contains the model and five report pages.

## CategoryMart[Category GMV]

```dax
CALCULATE([GMV], TREATAS(VALUES(CategoryMart[category]), Items[category]))
```

## CategoryMart[Category Freight Share]

```dax
CALCULATE([Freight Share], TREATAS(VALUES(CategoryMart[category]), Items[category]))
```

## Customers[Unique Customers]

```dax
CALCULATE(DISTINCTCOUNT(Customers[customer_unique_id]), TREATAS(VALUES(Orders[customer_id]), Customers[customer_id]))
```

## Customers[Repeat Buyers]

```dax
COUNTROWS(FILTER(VALUES(Customers[customer_unique_id]), CALCULATE(DISTINCTCOUNT(Orders[order_id])) > 1))
```

## Customers[Repeat Rate]

```dax
DIVIDE([Repeat Buyers], [Unique Customers])
```

## Items[GMV]

```dax
SUMX(Items, Items[price])
```

## Items[Freight]

```dax
SUMX(Items, Items[freight_value])
```

## Items[Freight Share]

```dax
DIVIDE([Freight], [GMV] + [Freight])
```

## OrderDelivery[Delivered Orders]

```dax
CALCULATE(DISTINCTCOUNT(OrderDelivery[order_id]))
```

## OrderDelivery[Late Orders]

```dax
CALCULATE(DISTINCTCOUNT(OrderDelivery[order_id]), OrderDelivery[is_late] = TRUE())
```

## OrderDelivery[Late Delivery Rate]

```dax
DIVIDE([Late Orders], [Delivered Orders])
```

## OrderDelivery[Average Late Days]

```dax
CALCULATE(AVERAGE(OrderDelivery[delay_days]), OrderDelivery[is_late] = TRUE())
```

## OrderDelivery[Average Review]

```dax
AVERAGE(OrderDelivery[review_score])
```

## OrderDelivery[On-time Review]

```dax
CALCULATE([Average Review], OrderDelivery[is_late] = FALSE())
```

## OrderDelivery[Late-order Review]

```dax
CALCULATE([Average Review], OrderDelivery[is_late] = TRUE())
```

## OrderDelivery[Review Gap]

```dax
[On-time Review] - [Late-order Review]
```

## OrderDelivery[Reviewed Orders]

```dax
COUNT(OrderDelivery[review_score])
```

## OrderDelivery[Review Coverage]

```dax
DIVIDE([Reviewed Orders], [Delivered Orders])
```

## OrderDelivery[Late Rate MoM pp]

```dax
VAR MonthKey = SELECTEDVALUE(Orders[Order Month])
VAR MonthStart = IF(NOT ISBLANK(MonthKey), DATE(VALUE(LEFT(MonthKey, 4)), VALUE(RIGHT(MonthKey, 2)), 1))
VAR NextBoundary = EDATE(MonthStart, 1)
VAR PriorBoundary = EDATE(MonthStart, -1)
VAR CurrentMonthRows = COUNTROWS(Orders)
VAR FullMonthRows = CALCULATE(COUNTROWS(Orders), REMOVEFILTERS(Orders[order_purchase_timestamp]), REMOVEFILTERS(Orders[Order Month]), Orders[order_purchase_timestamp] >= MonthStart, Orders[order_purchase_timestamp] < NextBoundary)
VAR CurrentEligible = [Delivered Orders]
VAR PreviousEligible = CALCULATE([Delivered Orders], REMOVEFILTERS(Orders[order_purchase_timestamp]), REMOVEFILTERS(Orders[Order Month]), Orders[order_purchase_timestamp] >= PriorBoundary, Orders[order_purchase_timestamp] < MonthStart)
VAR PreviousRate = CALCULATE([Late Delivery Rate], REMOVEFILTERS(Orders[order_purchase_timestamp]), REMOVEFILTERS(Orders[Order Month]), Orders[order_purchase_timestamp] >= PriorBoundary, Orders[order_purchase_timestamp] < MonthStart)
RETURN IF(NOT ISBLANK(MonthKey) && CurrentMonthRows = FullMonthRows && CurrentEligible >= 100 && PreviousEligible >= 100, 100 * ([Late Delivery Rate] - PreviousRate))
```

## OrderDelivery[Delivery MoM]

```dax
VAR MonthKey = SELECTEDVALUE(Orders[Order Month])
VAR MonthStart = IF(NOT ISBLANK(MonthKey), DATE(VALUE(LEFT(MonthKey, 4)), VALUE(RIGHT(MonthKey, 2)), 1))
VAR NextBoundary = EDATE(MonthStart, 1)
VAR FullMonthRows = CALCULATE(COUNTROWS(Orders), REMOVEFILTERS(Orders[order_purchase_timestamp]), REMOVEFILTERS(Orders[Order Month]), Orders[order_purchase_timestamp] >= MonthStart, Orders[order_purchase_timestamp] < NextBoundary)
RETURN SWITCH(TRUE(), ISBLANK(MonthKey), "Select one month", COUNTROWS(Orders) <> FullMonthRows, "Full month needed", ISBLANK([Late Rate MoM pp]), "Insufficient data", FORMAT([Late Rate MoM pp], "+0.00;-0.00;0.00") & " pp")
```

## Orders[Orders]

```dax
DISTINCTCOUNT(Orders[order_id])
```

## Orders[AOV]

```dax
DIVIDE([GMV], DISTINCTCOUNT(Items[order_id]))
```

## Orders[Payment Total]

```dax
SUM(Payments[payment_value])
```

## Orders[Cancellation Rate]

```dax
DIVIDE(CALCULATE([Orders], Orders[order_status] = "canceled"), [Orders])
```

## SellerMart[Seller Eligible Orders]

```dax
CALCULATE(DISTINCTCOUNT(Items[order_id]), TREATAS(VALUES(OrderDelivery[order_id]), Items[order_id]))
```

## SellerMart[Seller Late Orders]

```dax
CALCULATE(DISTINCTCOUNT(Items[order_id]), TREATAS(CALCULATETABLE(VALUES(OrderDelivery[order_id]), OrderDelivery[is_late] = TRUE()), Items[order_id]))
```

## SellerMart[Seller Late Rate]

```dax
IF([Seller Eligible Orders] >= 30, DIVIDE([Seller Late Orders], [Seller Eligible Orders]))
```

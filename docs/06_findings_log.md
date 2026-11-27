# Findings log

Version 3.0 · 27 November 2026 · Historical portfolio exercise · Stakeholder decisions remain proposed.

These findings use the calendar-date SLA and preserve descriptive interpretation. Monetary figures use all item rows unless explicitly qualified.

## F-01 Calendar-date delivery breaches

6,534 of 96,470 eligible delivered orders were late, 6.77%. The timestamp method gave 8.11%.

The decision implication is to use the date-only SLA consistently before comparing segments or targets.

Evidence is [sql/analysis/02_delivery_analysis.sql](../sql/analysis/02_delivery_analysis.sql). The limitation is the promise semantics are an analytical assumption pending operational validation.

## F-02 Review association with delivery outcome

Reviewed late orders average 2.27/5 versus 4.29/5 for on-time orders, a 2.02-point gap. Reviewed samples are 6,381 and 89,443 orders.

The decision implication is to investigate delivery experience and use review score as a secondary pilot outcome.

Evidence is [sql/analysis/02_delivery_analysis.sql](../sql/analysis/02_delivery_analysis.sql). The limitation is different review coverage, product mix, season and customer expectations may influence the gap.

The review gap also remains after a limited compositional check. In **49 state×purchase-month cells** with at least 30 reviewed orders in each delivery group, pooled common-mix weights give **2.44 late versus 4.28 on time**, a **1.85-point descriptive gap**. Those cells contain 4,287 late and 45,703 on-time reviewed orders, **52.17%** of the reviewed eligible population. This sensitivity check addresses state/month mix within matched cells. It does not establish a treatment effect or describe the unmatched remainder. Evidence is [common-mix comparison](../evidence/06_delivery_uncertainty_q03.csv) and [stratified counts and coverage](../evidence/06_delivery_uncertainty_q02.csv). Links are REQ-002 and REQ-015.

## F-03 Late volume and late rate imply different priorities

SP has 1,820 late of 40,494 (4.49%), RJ 1,495 of 12,350 (12.11%), MG 519 of 11,354 (4.57%) and BA 396 of 3,256 (12.16%).

The decision implication is to choose pilot candidates using absolute volume, rate, operational feasibility and uncertainty.

Evidence is [sql/analysis/02_delivery_analysis.sql](../sql/analysis/02_delivery_analysis.sql). The limitation is destination state is not a carrier or an origin–destination route.

Rate uncertainty supports different levels of caution. SP's 4.49% rate has a **95% Wilson interval of 4.30%–4.70%**, compared with RJ's 12.11% and **11.54%–12.69%**. Intervals describe binomial uncertainty within the observed cohort and do not account for seasonal changes, common shocks or operational selection. The **100-delivery** flag is a display-screening assumption. Pilot sample-size planning requires its own effect and power choices. Evidence is [state rates and Wilson bounds](../evidence/06_delivery_uncertainty_q01.csv). Links are REQ-003 and REQ-015.

## F-04 Late duration needs an explicit unit

Late orders average 10.62 calendar days after the promised date, or 11.30 elapsed 24-hour days after the stored estimated timestamp.

The decision implication is to keep calendar and elapsed measures visibly labeled.

Evidence is [sql/views/01_stg_orders.sql](../sql/views/01_stg_orders.sql). The limitation is midnight estimates create a systematic difference between these two durations.

## F-05 Merchandise population affects financial totals

All item GMV is R$13,591,643.70 on 98,666 item-bearing orders. Delivered item GMV is R$13,221,498.11. Eligible-delivery GMV is R$13,220,248.93.

The decision implication is to name each financial population in reports and reconcile matching filters.

Evidence is [sql/analysis/01_control_totals.sql](../sql/analysis/01_control_totals.sql). The limitation is gMV is transaction merchandise value. Platform revenue, realized profit and seller payout require other fields.

## F-06 Payment reconciliation has a material residual

Payment value R$16,008,872.12 exceeds item plus freight R$15,843,553.24 by R$165,318.88.

The decision implication is to inspect per-order residuals and missing payment/item combinations.

Evidence is [sql/analysis/01_control_totals.sql](../sql/analysis/01_control_totals.sql). The limitation is the residual alone cannot identify refunds, fees or discounts.

## F-07 Seller volume is concentrated

The 619 sellers with most item rows account for 93,099 of 112,650 item rows, approximately 82.64%.

The decision implication is to assess high-volume sellers for coaching reach, then apply distinct seller–order outcome checks.

Evidence is [sql/analysis/05_seller_performance.sql](../sql/analysis/05_seller_performance.sql). The limitation is order-level delivery outcomes provide seller exposure. Attribution requires shipment evidence.

## F-08 Snapshot multi-order share has a follow-up limitation

2,997 of 96,096 customer_unique_id values have more than one created order, 3.12%.

The decision implication is to use equal follow-up windows for a retention outcome and state eligible statuses.

Evidence is [sql/analysis/03_customer_analysis.sql](../sql/analysis/03_customer_analysis.sql). The limitation is customers have different observation lengths and may buy through channels outside the snapshot.

## F-09 Freight share varies with category mix

Overall customer-facing freight share is 14.21%. Furniture_decor is 19.14% on R$729,762.49 item GMV. Home_comfort_2 is 35.05% on 30 item rows.

The decision implication is to prioritize material monetary exposure with sample-size guardrails.

Evidence is [sql/analysis/04_revenue_category.sql](../sql/analysis/04_revenue_category.sql). The limitation is freight charged is not observed operating cost. Category ratios require ratio-of-sums aggregation.

## F-10 Snapshot edges distort growth comparisons

Order purchases span September 2016–October 2018, with only 16 created orders in September 2018 and 4 in October 2018.

The decision implication is to flag sparse edge periods and compare complete calendar months.

Evidence is [sql/analysis/04_revenue_category.sql](../sql/analysis/04_revenue_category.sql). The limitation is the snapshot cannot establish whether business demand actually collapsed at the edge.

## Finding register maintenance

Each ID represents one distinct conclusion. Repeated historical items about late-order GMV and growth have been consolidated. F-07 is now seller concentration and F-08 is now repeat behavior. Downstream references were updated in the canonical RTM. Numerical confidence describes snapshot reproducibility, while operational validation and causal interpretation remain separate decisions.

# Olist fulfillment reliability diagnostic
Version 3.0 · 27 November 2026 · Historical portfolio exercise · Stakeholder decisions remain proposed.
## Decision to support

Where should marketplace operations test delivery exception management, and what evidence would justify expanding it?

The intended readers are the logistics operations lead, customer experience manager, seller manager and commercial lead. The supplied snapshot contains 99,441 orders created between 4 September 2016 and 17 October 2018. Most volume lies in 2017–August 2018. The sparse opening and closing months are unsuitable for a like-for-like growth claim.

## Observed problem

Among 96,470 delivered orders with both dates, 6,534 arrived after the promised calendar date, a 6.77% late rate. Reviewed late orders averaged 2.27/5, versus 4.29/5 for reviewed on-time orders. The 2.02-point difference supports investigation of delivery reliability as an experience issue. Review completion and other differences between the groups can affect the comparison.

Late volume and late rate suggest different priorities. SP accounts for 1,820 late orders at 4.49%, whereas RJ has 1,495 at 12.11%. A pilot selection should consider both the number of actionable exceptions and the ability of local operations to resolve them.

## Hypotheses to investigate

- Dispatch timing, distance and promise calibration may explain some geographic variation. A destination state identifies where the customer receives goods. Carrier and route attribution require shipment-level events.
- Earlier operational attention may reduce breaches. The snapshot contains final statuses and cannot test the effect of an intervention.
- Repeat purchases may vary with delivery experience. The observed 3.12% multi-order customer share is sensitive to observation windows, channel coverage and eligible statuses.

## Scope

The analytical scope covers data quality, calendar-day delivery reliability, review associations, seller exposure, customer repeat behavior, GMV and customer-facing freight charges. The business scope proposes a small delivery exception pilot with a named owner and measurable outcomes.

Checkout promise algorithms, carrier allocation, merchant sanctions, voucher economics and live alert delivery require separate feasibility and approval decisions. Source data contains no true carrier cost, contribution margin, support workload, intervention outcome or shipment-level proof of responsibility.

## Decision gates

1. Accept the metric contract and reconcile the report with source control totals.
2. Confirm operational event availability, authority to act and capacity to clear the queue.
3. Select an eligible cohort and comparator, establish sample-size and follow-up requirements, then approve the pilot.
4. Expand only after outcome and guardrail results support the decision.

Targets remain hypotheses. A 10% relative reduction from a comparable 6.77% baseline would be about 6.10%, but the number of avoided late orders must use the pilot cohort's expected late count.

See [stakeholder decisions](02_stakeholders_raci.md), [BRD](07_BRD.md), [TO-BE pilot](11_to_be_process.md) and [metric contract](04_kpi_tree.md).

# Executive memo on the Olist delivery pilot

Prepared 27 November 2026 for the executive sponsor, logistics lead and CX manager. This is a historical portfolio diagnostic. Roles and decisions are modeled, and operational approval remains pending.

## Decision requested

Authorize a pilot-readiness assessment for a focused delivery exception workflow. Launch should follow acceptance of the metric contract, event availability, staffing, cohort/comparator, sample size, cost ceiling and stopping rules.

## Evidence

The supplied Olist snapshot covers 99,441 orders from 4 September 2016 to 17 October 2018. Among 96,470 delivered orders with both dates, **6,534 arrived after the promised calendar date**, a **6.77% late rate**. The 8 delivered orders missing dates are excluded.

Reviewed late orders averaged **2.27/5**, versus **4.29/5** for reviewed on-time orders. These means use 6,381 and 89,443 reviewed orders respectively and average reviews within each order first. The 2.02-point association warrants investigation and does not establish a causal review lift from intervention.

SP has the greatest absolute late volume at **1,820 of 40,494** eligible deliveries (**4.49%**). RJ has **1,495 of 12,350** (**12.11%**), followed by MG at **519 of 11,354** (**4.57%**). AL has the highest observed state rate, **85 of 397 (21.41%)**, with a much smaller denominator. Candidate selection must consider volume, rate, uncertainty and operational feasibility.

## Recommended action

Logistics should validate whether a queue beginning **3 calendar days before ETA** provides actionable lead time. The queue needs an owner, response deadline, source freshness check, action history and closed-case outcome. Use a narrow cohort and an appropriate comparator before expansion.

Seller management should use distinct seller–order exposure counts and visible sample sizes to support investigation and coaching. A shared order-level delivery outcome does not establish individual seller responsibility. Commercial and BI should keep financial context aligned with the selected population.

## Sizing and decision conditions

A **10% relative reduction** is an illustrative planning assumption. Applied to the overall baseline, it gives approximately **6.10%** and about **653 fewer late orders across the full historical snapshot**. The actual pilot volume must be sized from the selected cohort and its observation period.

All-item GMV is **R$13,591,643.70**. Late-order GMV is **R$985,924.34** within the eligible delivery cohort. Financial benefits require operating and intervention costs, validated contribution and measured outcomes.

The primary outcome is calendar late rate. Guardrails include cancellations/unresolved orders, promise length, review coverage, queue burden, handling cost and feed freshness. Expansion requires a useful measured effect and acceptable uncertainty after the agreed follow-up.

## Limits and next gate

The historical snapshot has no live intervention log, carrier event stream or true logistics cost. Repeat behavior reflects unequal observation periods and created-order statuses. Outcome evaluation needs new operational data. Sponsor approval, source-license confirmation and Power BI report UAT are separate completion gates.

Sources are [evidence/kpis.json](../evidence/kpis.json), [state metrics](../evidence/state_kpis.csv), [metric contract](04_kpi_tree.md), [requirements](10_RTM.md) and [pilot design](11_to_be_process.md). The SLA was restated from timestamp comparison to calendar-date comparison on 27 November 2026.

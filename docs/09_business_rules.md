# Business rules and policy assumptions

Version 3.0 · 27 November 2026 · Historical portfolio exercise · Stakeholder decisions remain proposed.

Calendar-date SLA is the adopted analytical rule D-001. Operational policy thresholds are proposals requiring accountable role acceptance. Rule IDs align with REQ and US in the canonical RTM.

## BR-001 Delivery exception queue

At the decision time, include an order with an estimated date, no confirmed delivery and an eligible open status when the local calendar date reaches ETA minus 3 days. Three days is a proposed configurable threshold. Retain one active order case, policy version, owner, due time and event timestamp. Delivered and canceled orders close active work. A stale feed pauses automated case generation and triggers an incident.

Owner is Logistics. Links are REQ-001, US-001 and AC-001. Evidence maturity is Pilot design.

## BR-002 Delivery experience comparison

Classify delivery only for delivered orders with valid actual and estimated dates. Actual DATE greater than estimated DATE is late. Same date is on time. Missing either date is unknown. Calculate review mean once per order, then compare groups and expose reviewed counts.

Owner is CX. Links are REQ-002, US-002 and AC-002. Evidence maturity is Analytical implementation.

## BR-003 State delivery prioritization

Compare state rates only with visible eligible volume and data coverage. Display absolute late count alongside rate. A 100-order historical display threshold is a screening assumption. Pilot selection additionally requires intervention capacity, a comparator and sample-size justification.

Owner is Logistics. Links are REQ-003, US-003 and AC-003. Evidence maturity is Analytical implementation.

## BR-004 Delivery trend

Build delivery trends by purchase calendar month, label the eligible delivered population and show counts. A monthly comparison refers to the prior calendar month. A missing or zero denominator gives unavailable rather than an invented percentage change.

The native Delivery MoM card requires one complete selected purchase month and at least 100 eligible deliveries in both that month and the immediately preceding calendar month. It reports percentage-point change. Multiple months show "Select one month"; partial months show "Full month needed"; insufficient current/prior populations show "Insufficient data". Seller selection filters exposure only and does not redefine the marketplace delivery denominator.

Owner is BI. Links are REQ-004, US-004 and AC-004. Evidence maturity is Analytical implementation.

## BR-005 Seller exposure scorecard

Deduplicate items to one seller-order pair before joining delivery outcome. Each pair contributes once to the seller denominator and at most once to late count. Item financials remain summed from item rows. Seller totals are exposure measures.

Owner is Seller lead. Links are REQ-005, US-005 and AC-005. Evidence maturity is Analytical implementation.

## BR-006 Seller comparison guardrails

Mark sellers with fewer than 30 eligible delivered orders as insufficient sample. Thirty is a screening parameter. Rankings display sample size and avoid claims of responsibility or automatic sanctions. Equal values use stable identifiers for deterministic display.

Owner is Seller lead. Links are REQ-006, US-006 and AC-006. Evidence maturity is Analytical implementation.

## BR-007 New seller quality gate

Evaluate onboarding quality only after defining onboarding date, observation window and eligible completed orders. A human policy owner reviews uncertainty and seller evidence before a restriction can be considered. This is a proposed future control.

Owner is Seller lead. Links are REQ-007, US-007 and AC-007. Evidence maturity is Future design.

## BR-008 Customer multi-order baseline

Group customers by customer_unique_id and count distinct order_id. The snapshot multi-order numerator contains customers with more than one created order. The denominator contains customers with at least one created order. Record status policy and observation window.

Owner is Growth. Links are REQ-008, US-008 and AC-008. Evidence maturity is Analytical implementation.

## BR-009 Customer recovery workflow

Recovery cases require an approved policy, customer consent and cost authority. Use a unique order-action key to prevent duplicate contacts. Record offered and accepted remedies separately. Voucher costs and causal lift require new data.

Owner is CX. Links are REQ-009, US-009 and AC-009. Evidence maturity is Future design.

## BR-010 Review theme analysis

Review themes require a manual labeling protocol, Portuguese-language review and measured precision/recall. Uncertain cases remain unclassified or go to human review. A theme is evidence of a reported experience rather than proof of liability.

Owner is CX. Links are REQ-010, US-010 and AC-010. Evidence maturity is Future design.

## BR-011 Customer cohort follow-up

Assign cohorts using first eligible purchase and compare returns within equal calendar follow-up. Observed zero-return periods are zero. Periods after the analysis cutoff are unavailable. Define created-order versus delivered-order policy explicitly.

Owner is Growth. Links are REQ-011, US-011 and AC-011. Evidence maturity is Analytical implementation.

## BR-012 Category merchandise and freight

GMV equals summed item price on the selected status population. Freight share equals summed customer freight charge divided by summed price plus freight. Category totals use ratio-of-sums and retain missing categories as Unknown.

Owner is Commercial. Links are REQ-012, US-012 and AC-012. Evidence maturity is Analytical implementation.

## BR-013 Freight exposure alert

A freight alert requires an approved ratio threshold, a minimum order/item sample and monetary materiality for the same period. Its output is an investigation case. Customer charges alone do not establish loss or profitability.

Owner is Category. Links are REQ-013, US-013 and AC-013. Evidence maturity is Future design.

## BR-014 Monthly merchandise baseline

Monthly merchandise totals must reconcile to the same population as headline GMV. Calendar gaps are explicit, sparse edge months are marked and MoM uses an adjacent calendar period. Revenue forecasts require a separate modeling and backtest decision.

Owner is Commercial. Links are REQ-014, US-014 and AC-014. Evidence maturity is Analytical implementation.

## BR-015 Metric governance

Every released KPI records definition ID/version, grain, eligible population, missing-data policy, source fields, SQL, evidence, DAX, visual and acceptance result. A failed refresh or parity check is visible and blocks release of a claimed refreshed baseline.

Owner is BI. Links are REQ-015, US-015 and AC-015. Evidence maturity is Analytical implementation.

## Delivery classification examples

| Status | Actual date | Estimate date | Classification |
|---|---|---|---|
| delivered | 2018-01-10 18:00 | 2018-01-10 00:00 | On time |
| delivered | 2018-01-11 01:00 | 2018-01-10 00:00 | Late, 1 calendar day |
| delivered | Missing | 2018-01-10 | Unknown and excluded |
| delivered | 2018-01-10 | Missing | Unknown and excluded |
| canceled | Missing | 2018-01-10 | Outside delivery eligibility |

## Proposed queue state transitions

| Current state | Event | Next state | Required audit |
|---|---|---|---|
| Unflagged | ETA minus 3 days reached, open and fresh | New | Source time, policy version and case key |
| New | Owner accepts | Assigned | Owner and acceptance time |
| Assigned | Action taken | Action recorded | Action, time, evidence and cost |
| Assigned | Response deadline expires | Escalated | Escalation recipient and reason |
| Any active | Delivered or canceled | Closed | Terminal source status and closure reason |
| Closed | Corrected source reopens order | Review required | Correction history and authorized decision |

Idempotent refresh retains existing assignments. One customer action can reference multiple seller contexts. Event correction, access control and retention policy require validation with the operational data owner before pilot deployment.

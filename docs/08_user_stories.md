# User stories and acceptance criteria

Version 3.0 · 27 November 2026 · Historical portfolio exercise · Stakeholder decisions remain proposed.

Stories share their numeric ID with REQ and BR in the canonical RTM. Analytical implementation indicates available SQL logic. Report UAT and operational acceptance have their own evidence states.

## US-001 Delivery exception queue

As the Logistics owner, I want delivery exception queue so that I can make the decision described by REQ-001.

Priority is Must. Stage is Pilot design. Links are REQ-001, BR-001, SH-001 and F-01, F-03.

```gherkin
Scenario: AC-001 Delivery exception queue
  Given ETA is within the agreed threshold and delivery is unconfirmed
  When the queue refreshes
  Then one active case appears with order_id, owner, due date, threshold version and flag time
```

Evidence state is Live events and intervention log required.

## US-002 Delivery experience comparison

As the CX owner, I want delivery experience comparison so that I can make the decision described by REQ-002.

Priority is Must. Stage is Analytical implementation. Links are REQ-002, BR-002, SH-002 and F-01, F-02.

```gherkin
Scenario: AC-002 Delivery experience comparison
  Given eligible delivered orders with and without reviews
  When the period and state are selected
  Then late and on-time counts, reviewed counts and mean order-level scores use the same delivery cohort
```

Evidence state is SQL evidence; report UAT required.

## US-003 State delivery prioritization

As the Logistics owner, I want state delivery prioritization so that I can make the decision described by REQ-003.

Priority is Must. Stage is Analytical implementation. Links are REQ-003, BR-003, SH-001 and F-03.

```gherkin
Scenario: AC-003 State delivery prioritization
  Given states have differing rate and volume
  When the risk view is opened
  Then both late count and late rate appear with denominator, threshold and missing-date coverage
```

Evidence state is SQL evidence; report UAT required.

## US-004 Delivery trend

As the BI owner, I want delivery trend so that I can make the decision described by REQ-004.

Priority is Must. Stage is Analytical implementation. Links are REQ-004, BR-004, SH-001 and F-01, F-10.

```gherkin
Scenario: AC-004 Delivery trend
  Given the prior calendar month has no eligible deliveries
  When a monthly change is calculated
  Then the missing comparator is displayed as unavailable and sparse periods are flagged
```

Evidence state is SQL evidence; report UAT required.

## US-005 Seller exposure scorecard

As the Seller lead owner, I want seller exposure scorecard so that I can make the decision described by REQ-005.

Priority is Must. Stage is Analytical implementation. Links are REQ-005, BR-005, SH-004 and F-07.

```gherkin
Scenario: AC-005 Seller exposure scorecard
  Given a seller has multiple items on one eligible order
  When the scorecard aggregates delivery outcomes
  Then that seller-order counts once and the late count cannot exceed the eligible delivered count
```

Evidence state is SQL evidence; report UAT required.

## US-006 Seller comparison guardrails

As the Seller lead owner, I want seller comparison guardrails so that I can make the decision described by REQ-006.

Priority is Must. Stage is Analytical implementation. Links are REQ-006, BR-006, SH-004 and F-07.

```gherkin
Scenario: AC-006 Seller comparison guardrails
  Given a seller has fewer than 30 eligible delivered orders
  When the comparison is displayed
  Then the rate retains its denominator and is marked insufficient sample, with no punitive recommendation
```

Evidence state is SQL evidence; report UAT required.

## US-007 New seller quality gate

As the Seller lead owner, I want new seller quality gate so that I can make the decision described by REQ-007.

Priority is Could. Stage is Future design. Links are REQ-007, BR-007, SH-005 and F-07.

```gherkin
Scenario: AC-007 New seller quality gate
  Given a seller reaches an agreed observation threshold
  When a quality review occurs
  Then a human reviews evidence and records the decision and dispute path
```

Evidence state is Onboarding date and policy required.

## US-008 Customer multi-order baseline

As the Growth owner, I want customer multi-order baseline so that I can make the decision described by REQ-008.

Priority is Must. Stage is Analytical implementation. Links are REQ-008, BR-008, SH-006 and F-08.

```gherkin
Scenario: AC-008 Customer multi-order baseline
  Given one customer_unique_id appears on two customer_id values
  When the snapshot share is calculated
  Then the person counts once in the denominator and once in the multi-order numerator
```

Evidence state is SQL evidence; report UAT required.

## US-009 Customer recovery workflow

As the CX owner, I want customer recovery workflow so that I can make the decision described by REQ-009.

Priority is Should. Stage is Future design. Links are REQ-009, BR-009, SH-002 and F-02.

```gherkin
Scenario: AC-009 Customer recovery workflow
  Given a confirmed late order meets an approved recovery policy
  When a case is assigned
  Then the action, consent, cost and outcome are recorded and duplicate contacts are prevented
```

Evidence state is Consent, service history and budget required.

## US-010 Review theme analysis

As the CX owner, I want review theme analysis so that I can make the decision described by REQ-010.

Priority is Could. Stage is Future design. Links are REQ-010, BR-010, SH-002 and F-02.

```gherkin
Scenario: AC-010 Review theme analysis
  Given a manually labeled Portuguese review sample exists
  When a theme model is evaluated
  Then precision and recall by theme and uncertain predictions are reported before production use
```

Evidence state is Labeled review sample and validation required.

## US-011 Customer cohort follow-up

As the Growth owner, I want customer cohort follow-up so that I can make the decision described by REQ-011.

Priority is Should. Stage is Analytical implementation. Links are REQ-011, BR-011, SH-006 and F-08.

```gherkin
Scenario: AC-011 Customer cohort follow-up
  Given a cohort lacks a full observation window
  When retention is displayed
  Then unobserved periods remain unavailable and observed zero-return periods display zero
```

Evidence state is SQL evidence; cohort UAT required.

## US-012 Category merchandise and freight

As the Commercial owner, I want category merchandise and freight so that I can make the decision described by REQ-012.

Priority is Must. Stage is Analytical implementation. Links are REQ-012, BR-012, SH-007 and F-05, F-09.

```gherkin
Scenario: AC-012 Category merchandise and freight
  Given more than one category is selected
  When freight share is summarized
  Then total freight is divided by total merchandise plus freight for the same selected items
```

Evidence state is SQL evidence; report UAT required.

## US-013 Freight exposure alert

As the Category owner, I want freight exposure alert so that I can make the decision described by REQ-013.

Priority is Should. Stage is Future design. Links are REQ-013, BR-013, SH-008 and F-09.

```gherkin
Scenario: AC-013 Freight exposure alert
  Given a category exceeds an agreed ratio and monetary materiality threshold
  When the period closes
  Then one investigation is created with supporting amounts, volume and policy version
```

Evidence state is Configurable materiality threshold required.

## US-014 Monthly merchandise baseline

As the Commercial owner, I want monthly merchandise baseline so that I can make the decision described by REQ-014.

Priority is Must. Stage is Analytical implementation. Links are REQ-014, BR-014, SH-007 and F-05, F-10.

```gherkin
Scenario: AC-014 Monthly merchandise baseline
  Given all-status GMV is selected
  When the monthly trend is totaled
  Then the result reconciles to the all-item control total and identifies incomplete edge months
```

Evidence state is SQL evidence; report UAT required.

## US-015 Metric governance

As the BI owner, I want metric governance so that I can make the decision described by REQ-015.

Priority is Must. Stage is Analytical implementation. Links are REQ-015, BR-015, SH-009 and F-05, F-06.

```gherkin
Scenario: AC-015 Metric governance
  Given a KPI definition or source version changes
  When a release is prepared
  Then SQL, evidence, DAX, visual, README and memo identify the same definition and population
```

Evidence state is Automated parity and report UAT required.

## Cross-cutting acceptance cases

UAT additionally covers empty selections, invalid date ranges, missing source data, canceled orders, missing reviews, refresh failure and authorized access. A live queue must reject stale event feeds, use an order-level idempotency key, exclude delivered/canceled cases from active work and record reassignment, escalation and closure. A multi-seller case retains seller context without creating duplicate customer actions.

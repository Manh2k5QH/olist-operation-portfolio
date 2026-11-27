# Business requirements for a fulfillment reliability pilot
Version 3.0 · 27 November 2026 · Historical portfolio exercise · Stakeholder decisions remain proposed.
## Business need and decision

The sponsor decision is whether to fund a focused exception-management pilot using reliable historical baselines and measurable live outcomes. The analytical case is 6,534 late of 96,470 eligible delivered orders under the calendar-date SLA, with a 2.02-point review difference between reviewed on-time and late orders. These figures describe the snapshot.

## Objectives and scope

OBJ-01 is to reduce the calendar late rate in a feasible pilot cohort. OBJ-02 is to measure customer experience with review coverage. OBJ-03 is to make prioritization reproducible across geography, seller exposure and merchandise context.

The current deliverable is a BA/DA portfolio containing governed SQL, evidence, a Power BI reporting model and a proposed operating design. The next business gate covers data readiness, staffing and pilot design. Automated checkout ETA, merchant suspension, premium carrier selection, coupons and a production alert service require separate policy, technology and financial decisions.

## Requirements baseline

[The canonical RTM](10_RTM.json) defines 15 requirements. Their matching US, BR and AC numbers provide direct traceability. This baseline replaces earlier FR numbering whose meanings differed between the BRD and Excel RTM.

| ID | Required capability | Priority | Delivery stage |
|---|---|---|---|
| REQ-001 | Delivery exception queue | Must | Pilot design |
| REQ-002 | Delivery experience comparison | Must | Analytical implementation |
| REQ-003 | State delivery prioritization | Must | Analytical implementation |
| REQ-004 | Delivery trend | Must | Analytical implementation |
| REQ-005 | Seller exposure scorecard | Must | Analytical implementation |
| REQ-006 | Seller comparison guardrails | Must | Analytical implementation |
| REQ-007 | New seller quality gate | Could | Future design |
| REQ-008 | Customer multi-order baseline | Must | Analytical implementation |
| REQ-009 | Customer recovery workflow | Should | Future design |
| REQ-010 | Review theme analysis | Could | Future design |
| REQ-011 | Customer cohort follow-up | Should | Analytical implementation |
| REQ-012 | Category merchandise and freight | Must | Analytical implementation |
| REQ-013 | Freight exposure alert | Should | Future design |
| REQ-014 | Monthly merchandise baseline | Must | Analytical implementation |
| REQ-015 | Metric governance | Must | Analytical implementation |

## Nonfunctional and transition requirements

| ID | Requirement and acceptance evidence | Owner |
|---|---|---|
| NFR-001 | Baseline reproducibility. A clean dependency installation regenerates evidence and passes controls. Record source counts, input hashes and tool versions. | BI |
| NFR-002 | Report usability. Five report pages identify selected dates, population and rate denominator. UAT checks blank selections, small samples and readable exports. | BA/BI |
| NFR-003 | Freshness and failure visibility. Show snapshot or last successful refresh time. A live feed SLA is agreed during pilot readiness and tested with delayed/missing events. | BI |
| NFR-004 | Access and privacy. Pilot roles receive the minimum customer data needed for their task. Test unauthorized access, approved export and consent-dependent actions. | Data owner |
| NFR-005 | Auditability. Preserve metric/policy version, queue event, actor, decision time and source event time. Verify replay and duplicate events keep state consistent. | Logistics/BI |
| NFR-006 | Performance and recovery. Establish refresh and queue response targets from measured data volume and operational needs. Test failure recovery before committing to a production SLA. | BI/IT |
| TR-001 | Assign owners, train queue users, validate escalation contacts and rehearse a complete case before pilot launch. | Logistics |
| TR-002 | Migrate the calendar-date definition, explain historical KPI restatement and archive the prior timestamp baseline. | BA/BI |
| TR-003 | Verify source-license and embedded-report distribution conditions before public release. | Project owner |

## Dependencies and assumptions

Calendar-date promise semantics are adopted for analysis and await operational confirmation. Live cases need a stable order ID, estimated date, current status, source event time and timezone. Seller attribution needs package-level handoff evidence. Customer contact needs consent and approved templates. Financial benefit evaluation needs intervention cost, operational cost and measured outcome.

The snapshot cannot validate runtime latency, live event freshness, current staffing, carrier authority or an agreed budget. Operational acceptance criteria remain open until those sources and role owners exist.

## Risks and response

| Risk | Observable indicator | Response and accountable role |
|---|---|---|
| Excessive queue demand | Open cases exceed staffed capacity | Narrow cohort or threshold, Logistics |
| Apparent improvement through ETA inflation | ETA length rises with lower late rate | Track ETA length and promise changes, Logistics |
| Survivorship in delivered-only rate | Undelivered/canceled share increases | Report terminal outcomes alongside delivery rate, BI |
| Unfair seller interpretation | Multi-seller or disputed cases | Use exposure labels and human review, Seller lead |
| Weak causal inference | Treated and comparator groups differ | Predefine assignment and analysis, BA |
| Unproven savings | Charges treated as costs | Require cost evidence and sensitivity assumptions, Commercial |
| Definition drift | Report differs from SQL | Version definitions and block release on parity failure, BI |

## Acceptance and governance

Analytical acceptance requires reproducible control totals, null/duplicate handling and aligned source populations. Report acceptance requires filter-context parity, readable visuals and refresh evidence. Pilot acceptance requires agreed cohort/comparator, sample size, sufficient follow-up, capacity, an escalation workflow and a stopping rule. Sponsor launch approval remains pending.

Change requests record business rationale, affected REQ/BR/KPI IDs, input/output populations, test impact, owner and decision. The [RTM](10_RTM.md), [user stories](08_user_stories.md), [rules](09_business_rules.md) and [pilot design](11_to_be_process.md) carry the detailed acceptance evidence.

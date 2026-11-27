# Operational handoff and approval register

This is the boundary between the accepted historical portfolio and a live pilot. All owner names are proposed roles; none represents an actual Olist authorization.

## Required decisions before a live pilot

1. **Logistics sponsor:** confirm calendar-date ETA semantics, timezone, the proposed three-day trigger and action authority. Deliver a signed KPI/threshold decision with effective date and version.
2. **Operations lead:** provide event source, freshness target, named case owners, staffing, response SLA and escalation route. Deliver an event contract and staffed runbook.
3. **CX/privacy owner:** confirm permitted contact, consent, retention, access and duplicate-contact controls. Deliver an access matrix and communication policy; test unauthorized access and revoked consent before any message.
4. **Experiment owner and finance:** choose cohort, assignment/comparator, baseline, target effect, power, sample size, duration, cost ceiling and stopping rule. Deliver an approved experiment protocol. The 10% relative reduction remains a planning assumption.
5. **BI/platform owner:** implement monitored refresh, stale-feed detection, replay/idempotency, failure alerting, rollback and recovery. Retain event-replay and failure-recovery results from the actual target system.
6. **Sponsor:** approve or reject launch only after the preceding evidence is supplied. Record decision, accountable person, date and conditions. Reassess expansion using observed outcomes and guardrails.

## Acceptance scenarios supplied for implementation

- Replaying one qualifying event twice creates one active case; revisions retain a versioned audit trail.
- An already delivered or canceled order does not enter the active queue. Closure requires a permitted transition and reason.
- A stale feed prevents an actionable queue from being presented as current; the responsible role receives an incident.
- A user outside the role matrix cannot read or mutate cases. A case owner cannot approve their own policy override.
- A refresh failure retains the last successful timestamp and clearly marks stale results; recovery reprocesses events without duplicate cases or contacts.
- Contact requires policy authority, consent and an idempotency key. Exhausted cost authority blocks a financial offer.
- The experiment reports eligible late outcomes together with cancellation/unresolved outcomes, ETA length, review coverage, workload and cost; stopping/expansion follows the pre-agreed rule.

These are specified tests, not executed production tests. The current project contains no live queue service, messaging integration or operational deployment. New-seller gates, recovery automation, Portuguese theme classification and freight alert dispatch remain future capabilities in the RTM. Completing documentation or historical DAX tests does not implement those services.

## Publication handoff

The final PBIX and report screenshots are included for public portfolio review after the release checks. Refer to [data attribution](../DATA_ATTRIBUTION.md) before redistribution. The owner authorized publication of these portfolio artifacts on GitHub. No live Power BI service or operational workflow is deployed.

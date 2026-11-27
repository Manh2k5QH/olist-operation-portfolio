# Requirements traceability matrix

Version 3.1 · 27 November 2026 · Historical portfolio exercise · Stakeholder decisions remain proposed.

[10_RTM.json](10_RTM.json) is the canonical register. Excel and Markdown use the same 15 IDs and evidence states. [Final local acceptance](14_dashboard_uat.md#final-local-acceptance) records executed tests.

| Requirement | Story and rule | Priority | Stage | Evidence |
|---|---|---|---|---|
| REQ-001 Delivery exception queue | US-001; BR-001 | Must | Pilot design | Live events and intervention log required |
| REQ-002 Delivery experience comparison | US-002; BR-002 | Must | Analytical implementation | Historical SQL + native DAX UAT passed; operational acceptance separate |
| REQ-003 State delivery prioritization | US-003; BR-003 | Must | Analytical implementation | Historical SQL + native DAX UAT passed; operational acceptance separate |
| REQ-004 Delivery trend | US-004; BR-004 | Must | Analytical implementation | Historical SQL + native DAX UAT passed; operational acceptance separate |
| REQ-005 Seller exposure scorecard | US-005; BR-005 | Must | Analytical implementation | Historical SQL + native DAX UAT passed; operational acceptance separate |
| REQ-006 Seller comparison guardrails | US-006; BR-006 | Must | Analytical implementation | Historical SQL + native DAX UAT passed; operational acceptance separate |
| REQ-007 New seller quality gate | US-007; BR-007 | Could | Future design | Onboarding date and policy required |
| REQ-008 Customer multi-order baseline | US-008; BR-008 | Must | Analytical implementation | Historical SQL + native DAX UAT passed; operational acceptance separate |
| REQ-009 Customer recovery workflow | US-009; BR-009 | Should | Future design | Consent, service history and budget required |
| REQ-010 Review theme analysis | US-010; BR-010 | Could | Future design | Labeled review sample and validation required |
| REQ-011 Customer cohort follow-up | US-011; BR-011 | Should | Analytical implementation | SQL cohort output accepted; native cohort page outside five-page scope |
| REQ-012 Category merchandise and freight | US-012; BR-012 | Must | Analytical implementation | Historical SQL + native DAX UAT passed; operational acceptance separate |
| REQ-013 Freight exposure alert | US-013; BR-013 | Should | Future design | Configurable materiality threshold required |
| REQ-014 Monthly merchandise baseline | US-014; BR-014 | Must | Analytical implementation | Historical SQL + native DAX UAT passed; operational acceptance separate |
| REQ-015 Metric governance | US-015; BR-015 | Must | Analytical implementation | Historical SQL + native DAX UAT passed; operational acceptance separate |

## Artifact and acceptance mapping

| Requirement | SQL artifact | Acceptance case | Accountable role |
|---|---|---|---|
| REQ-001 | [sql/views/01_stg_orders.sql](../sql/views/01_stg_orders.sql) | [AC-001](14_dashboard_uat.md#final-local-acceptance) | Logistics |
| REQ-002 | [sql/analysis/02_delivery_analysis.sql](../sql/analysis/02_delivery_analysis.sql) | [AC-002](14_dashboard_uat.md#final-local-acceptance) | CX |
| REQ-003 | [sql/analysis/02_delivery_analysis.sql](../sql/analysis/02_delivery_analysis.sql) | [AC-003](14_dashboard_uat.md#final-local-acceptance) | Logistics |
| REQ-004 | [sql/analysis/02_delivery_analysis.sql](../sql/analysis/02_delivery_analysis.sql) | [AC-004](14_dashboard_uat.md#final-local-acceptance) | BI |
| REQ-005 | [sql/views/04_mart_seller.sql](../sql/views/04_mart_seller.sql) | [AC-005](14_dashboard_uat.md#final-local-acceptance) | Seller lead |
| REQ-006 | [sql/analysis/05_seller_performance.sql](../sql/analysis/05_seller_performance.sql) | [AC-006](14_dashboard_uat.md#final-local-acceptance) | Seller lead |
| REQ-007 | Operational design only | [AC-007](14_dashboard_uat.md#final-local-acceptance) | Seller lead |
| REQ-008 | [sql/analysis/03_customer_analysis.sql](../sql/analysis/03_customer_analysis.sql) | [AC-008](14_dashboard_uat.md#final-local-acceptance) | Growth |
| REQ-009 | Operational design only | [AC-009](14_dashboard_uat.md#final-local-acceptance) | CX |
| REQ-010 | Operational design only | [AC-010](14_dashboard_uat.md#final-local-acceptance) | CX |
| REQ-011 | [sql/analysis/03_customer_analysis.sql](../sql/analysis/03_customer_analysis.sql) | [AC-011](14_dashboard_uat.md#final-local-acceptance) | Growth |
| REQ-012 | [sql/views/03_mart_category.sql](../sql/views/03_mart_category.sql) | [AC-012](14_dashboard_uat.md#final-local-acceptance) | Commercial |
| REQ-013 | [sql/analysis/04_revenue_category.sql](../sql/analysis/04_revenue_category.sql) | [AC-013](14_dashboard_uat.md#final-local-acceptance) | Category |
| REQ-014 | [sql/analysis/04_revenue_category.sql](../sql/analysis/04_revenue_category.sql) | [AC-014](14_dashboard_uat.md#final-local-acceptance) | Commercial |
| REQ-015 | [sql/analysis/01_control_totals.sql](../sql/analysis/01_control_totals.sql) | [AC-015](14_dashboard_uat.md#final-local-acceptance) | BI |

## Completion gates

Historical analytical acceptance covers governed SQL, native DAX comparisons, selected UI interactions and relocated refresh. Operational acceptance still requires live feeds, accountable people, authority, budget, privacy controls and sponsor approval. Future-design rows do not represent deployed services.

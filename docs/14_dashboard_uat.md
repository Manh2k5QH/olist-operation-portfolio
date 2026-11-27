# Dashboard and requirements acceptance register

Reviewed 27 November 2026. Authoritative local sources: the locally retained PBIP source, native TMDL/PBIR and the Desktop-saved [project.pbix](../project.pbix).

## Final local acceptance

**Native model result: 26/26 passed**, observed in Power BI Desktop after cache-free relocated refresh. The [DAX query](../evidence/acceptance/native_acceptance.dax) compares native results with [independent raw-CSV/DuckDB expectations](../evidence/acceptance/native_cases.json), using absolute numeric tolerance 0.00001 and explicit BLANK checks. [Result capture](../evidence/acceptance/native-dax-26-pass.png) records the native result. This is engine acceptance through Desktop, not a claim that every conceivable mouse path was tested.

The status-message regression was observed at 23/26 before correction and 26/26 afterward. The original 19-case baseline also passed. Cases were expanded after independent review to test genuine missing prior-month data and seller–order exposure, beyond simple order counts.

| AC | Historical acceptance evidence | Outcome / boundary |
|---|---|---|
| AC-001 | Exception queue process, threshold, ownership and state transitions documented | Design accepted for portfolio; live implementation/approval remains external |
| AC-002 | January 2018 order-weighted review 4.1087266505 and 7,013 reviewed eligible orders; native values match SQL; full/AL comparisons recorded | Historical analysis passed |
| AC-003 | SP 40,494 eligible / 1,820 late; RJ 12,350 / 1,495; actual table matches rounded SQL; state uncertainty and coverage exported | Historical analysis passed |
| AC-004 | January 2018 MoM -1.7541583 pp; Oct2016 low prior volume; Jan2017/SP absent prior; multi-month/partial-month blank; explicit status tests | Native MoM passed; both months require 100 eligible orders |
| AC-005 | Multi-item seller 1,819 eligible distinct orders; two participating sellers in one selected order each contribute one, summed exposure two | Native grain acceptance passed; no seller blame inferred |
| AC-006 | Seller with 29 eligible orders has blank rate; seller with 30 has 1/30 = 3.3333% | Native threshold passed |
| AC-007 | Proposed onboarding data/policy acceptance defined | Future operational capability |
| AC-008 | One person with multiple customer_id records returns one unique customer and one repeat buyer | Native identity passed; selected-window repeat is not fixed-window retention |
| AC-009 | Consent, authority, deduplication and recovery workflow specified | Future operational capability |
| AC-010 | Portuguese theme labeling/validation requirement specified | Future analytical capability; no classifier claimed |
| AC-011 | SQL cohort calendar output distinguishes observed zero/unobserved null and includes mature 90-day follow-up; 31-query pipeline/regressions pass | SQL deliverable accepted; cohort page is outside the five-page native report |
| AC-012 | health_beauty + watches_gifts GMV R$2,463,687.02; AOV R$170.4148; freight share 10.306674% | Native multi-category totals and ratio passed |
| AC-013 | Freight materiality/assignment policy specified | Future alert service, no dispatch claimed |
| AC-014 | Full GMV R$13,591,643.70; January2018 R$950,030.36; January+AL R$5,134.08, 37 item orders, AOV138.76 and freight20.8% | Native base/month/state/combined context passed |
| AC-015 | 15 aligned canonical IDs/statuses, 27 native measures, release readback/hashes, 31-query regression, clean relocated refresh | Local analytical governance passed; external approval separate |

## UI and filter semantics

Five pages have been opened and visually inspected. Page tabs navigate between the distinct compositions. Existing state/date tests cover all periods, a complete month, AL, combined January2018/AL, low-volume timeline and clearing selection. The final native report adds category and seller dropdowns so users can explicitly select sets.

Category filters affect item GMV, item-order AOV and freight share. Payment Total retains the order/date/state population; payments are not allocated to categories. Seller selection affects the seller exposure table; delivery headline cards, state visuals and MoM retain marketplace date/state context. This single-direction design prevents a seller selection from silently redefining the delivery denominator.

Empty eligible selections yield BLANK counts/rates rather than an invented zero rate. The timeline requires 100 eligible deliveries for delivery-rate trends and 100 created orders for other monthly trends. No query error is an acceptable empty-state substitute.

## Reproducibility and release

Final manual UI cases also passed on the authoritative native source:

- Selecting `agro_industry_and_commerce` + `air_conditioning` through the category checkboxes produced GMV R$127.56K (SQL R$127,555.43), AOV R$293.23 and freight share 9.0% (SQL 8.985363%). Clearing the slicer restored the full baseline. [Reference](../evidence/acceptance/manual_category_reference.json).
- Selecting seller `0015a82c2db000af6aaaf3ae2ecb0532` reduced the exposure table to 3 eligible orders and a blank guarded rate, matching SQL. Marketplace delivery cards remained at their date/state scope. [Reference](../evidence/acceptance/manual_seller_reference.json).
- Delivery date selection 1–31 January 2018 showed 7,069 eligible, 403 late, 5.7% and **-1.75 pp** MoM, matching SQL. Date selection 1–30 November 2016 showed empty cards/charts/tables without a query error. Resetting dates restored 96,470 / 6,534 / 6.8% at displayed precision.

The accompanying `manual-*.png` captures in evidence/acceptance record these states. The full monthly/seller/category engine comparisons remain reproducible through the DAX acceptance query.

An independent directory under .validation/clean-copy was populated with declared source/code/native files, excluding .pbi caches. A separate venv installed pinned duckdb==2.0.1. Profiler and regression commands both exited 0; all nine source hashes match and headline KPIs match within absolute 1e-8. Floating-point sum order changes below that tolerance were examined before acceptance. The relocated PBIP then opened empty and successfully refreshed in Desktop. [Execution record](../evidence/acceptance/clean_copy.json) and adjacent logs retain results.

The [release manifest](../evidence/report_release.json) records the final PBIX and dashboard hashes. [Operational handoff](16_operational_handoff.md) retains the unexecuted live scenarios, named-role dependencies and launch decision. No simulated role provides actual sponsor sign-off.

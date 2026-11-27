# Olist portfolio completion review

Reviewed 27 November 2026. Scope: historical BA/DA portfolio and local Power BI handoff.

## Verdict

The finite local remediation and acceptance work is closed for the historical portfolio: governed SQL/evidence, native DAX, five distinct report pages, editable diagrams, requirements traceability, README, executive memo, relocated refresh and release identification. This is a reviewable BA/DA case study, with explicit decision logic and reproducible evidence.

The full original plan also contains operational implementation and approval gates. Those remain external dependencies. The project does not contain a deployed queue, live messaging, production access controls or an executed experiment, and no real Olist stakeholder has signed it off. It would be inaccurate to call every proposed capability implemented or the live pilot 100% complete.

## Verification evidence

- Nine source files / 1,550,922 rows are identified by hashes in the [source manifest](../evidence/reproducibility_manifest.json).
- Calendar-date SLA: 6,534 / 96,470 = 6.77%. On-time/late reviewed means: 4.29 / 2.27. Seller exposure uses distinct seller–order pairs.
- All-item GMV R$13,591,643.70 and payments R$16,008,872.12 are reconciled independently. These are different populations, not profit or fees.
- The isolated relocated run of profiler and regression checks passed all 31 analytical queries, with matching source hashes and KPI parity to absolute floating-point tolerance 1e-8. A cache-free PBIP refreshed successfully in Desktop at the new folder. See [clean-copy evidence](../evidence/acceptance/clean_copy.json).
- Native Desktop DAX acceptance passed **26/26** independent SQL comparisons. These cover seller volumes 29/30, multiple item/seller grains, two-category sums and weighted freight share, customer identity, review/month scope, empty populations, MoM and unavailable statuses. See the [UAT register](14_dashboard_uat.md#final-local-acceptance), [query](../evidence/acceptance/native_acceptance.dax) and [SQL cases](../evidence/acceptance/native_cases.json).
- The MoM display distinguishes one-month selection, partial month and insufficient comparison data. January 2018 versus December 2017 is -1.75 percentage points. Missing/low-volume comparators return unavailable rather than zero.
- The model contains 27 native measures and 36 measure-bearing visuals: 20 KPI cards and 16 analytical visuals. Five compositions share the owner's template while emphasizing different decisions.
- Canonical JSON, Markdown and Excel RTM retain the same 15 IDs/statuses and link to executed UAT. Three process/data diagrams have editable draw.io sources. The executive PDF has been visually checked.
- The final [release record](../evidence/report_release.json) identifies the Desktop-saved PBIX and five actual dashboard captures. The source and screenshot hashes support version identification, not operational approval.

## Independent review

A fresh read-only reviewer identified three material acceptance gaps: a purported missing-month case only tested low volume; the multi-seller case only tested order counts; and the MoM unavailable message gave a misleading cause. The cases now separately test missing and low-volume comparators, each participating seller plus total exposure, and three explicit status messages. The display regression was observed at 23/26 before the correction and 26/26 after it.

## Interpretation and external gates

The portfolio is suitable for explaining BA/DA judgment to a recruiter or reviewer: problem framing, stakeholder roles, KPI contracts, grain corrections, SQL/DAX verification, requirements and an actionable proposed pilot. Visual polish is an assessment, not a certification or evidence of business impact.

The [operational handoff](16_operational_handoff.md) specifies the remaining source, staffing, privacy, experiment, monitoring and sponsor decisions. Future-design RTM rows remain future designs. Source attribution and the publisher's stated license are documented in [DATA_ATTRIBUTION.md](../DATA_ATTRIBUTION.md); the original download version is unknown, so local hashes identify the analyzed copy.

No pilot savings, causal review improvement, actual customer intervention or production approval is claimed.

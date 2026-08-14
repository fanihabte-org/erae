# Enterprise Revenue Analytics Engine (ERAE)
## Business Case & Business Requirements Document — Northwind Systems

| Field | Value |
|---|---|
| **Document ID** | ERAE-BRD-002 |
| **Version** | 2.0 (supersedes v1.0, PMO draft) |
| **Status** | For Executive Review & Sign-Off |
| **Author** | Principal Program Manager, Northwind Systems PMO |
| **Contributing owners** | Analytics Engineering · Data Platform · RevOps · Finance Systems · Sales Operations · IT Operations |
| **Approvers** | CRO · CFO · VP Engineering · Head of Data Governance |
| **Data window in scope** | 2023-01-01 → present (rolling), 3.5 years of history at time of writing |
| **Source estate** | CRM (FakeForce REST API) · `ops` Postgres · `erp` Postgres |

---

## 0. How to read this document

v1.0 was written before the analytics team had access to the three source systems. It described the value we want. It did not describe the estate we actually have. This version keeps the strategic intent intact and rewrites everything below it to be buildable, testable, and defensible in front of Finance.

**Section map**

| § | Section | Who needs to read it |
|---|---|---|
| 1 | Revised business case & what changed from v1.0 | Exec leadership |
| 2 | Scope, out-of-scope, assumptions, dependencies | Exec, all delivery leads |
| 3 | Foundational data requirements (DR-1 … DR-7) | Analytics Eng, Data Platform, Finance |
| 4 | Functional requirements by analytics tier (FR-1 … FR-4) | All |
| 5 | BI, UX, and access requirements | RevOps, Sales Ops, Security |
| 6 | Non-functional requirements | Data Platform, Security |
| 7 | Analytics team deliverables register (D-01 … D-32) | Analytics Engineering |
| 8 | Data quality, testing, and release strategy | Analytics Eng, QA |
| 9 | Revised roadmap, critical path, and phase gates | Exec, PMO |
| 10 | Operating model & RACI | All |
| 11 | Risk register | Exec, PMO |
| 12 | Open decisions requiring a named owner | Exec, PMO |
| A–C | Appendices: amended metric definitions, source-quirk glossary, change log | Reference |

---

# Part 1 — Business Case (Revised)

## 1.1 Executive summary

Northwind Systems sells IT infrastructure — hardware, software licences, support plans, professional services, and consumables — to business customers through five legal entities and six sales regions. The company runs three operational systems owned by three different teams: a **CRM** owned by Sales Operations, an **`ops`** order-management and service database owned by IT Operations, and an **`erp`** ledger owned by Finance.

These three systems have **no enforced relationships between them**. Each database enforces its own keys internally; nothing crosses the boundary. Every question that matters to the business — *what did we book, what did we bill, why is there a gap, which accounts are at risk* — requires stitching those systems together on business keys that were never designed to be joined.

The Enterprise Revenue Analytics Engine (ERAE) builds that stitched layer once, governs it, and serves four progressive tiers of intelligence on top of it: **Descriptive, Diagnostic, Predictive, Prescriptive**.

The strategic case from v1.0 stands. What changes in v2.0 is the honesty of the plan underneath it.

> **The central reframing:** v1.0 treated cross-system integration as a Phase 1 sub-bullet. In the Northwind estate, cross-system integration **is** the project. Identity resolution, currency normalisation, and the bookings-to-billed bridge are not plumbing beneath the analytics — they are the first three deliverables the business will be asked to trust, and every predictive and prescriptive capability is a direct dependent of them.

## 1.2 What changed from v1.0, and why

This table is the most important page in the document. Each row is a v1.0 commitment that the source estate will not support as written.

| # | v1.0 commitment | What the estate actually contains | v2.0 amendment |
|---|---|---|---|
| A | *"100% data reconciliation across CRM and ERP"* | Bookings and billed revenue are different measures on different clocks. Credit notes (`CRN`) reverse invoices in earlier periods. Adjustment postings (`ADJ`) are booked at entity level with `order_ref` NULL and trace to no order at all. `PENDING` orders count as bookings and never reach the ledger. **These figures will never be equal, and equality is not the goal.** | Replaced with a **governed bookings→billed bridge** (FR-1.2). Target: 100% of the gap classified into named categories; **unexplained residual ≤ 0.5%** of billed revenue per entity-period. |
| B | *"Real-time and daily-snapshot views of MRR and ARR"* | Northwind sells one-off orders. There is no contract table, no subscription line, no term, no renewal date, and no expiry field in any of the three systems. **MRR and ARR are not derivable.** | ARR/MRR **removed from scope**. Replaced by Bookings, Billed Revenue, and *Recurring-Proxy Revenue* (Support Plan + Software License categories) with the recognition assumption printed on the tile. A contracts source system is a prerequisite — tracked as **OPEN-01**. |
| C | *"Real-time"* dashboards | The event chain is deliberately causal and lagged: Closed Won → order (1–3d) → shipment (1–5d) → invoice (0–3d) → ERP posting (1–2d). **Source-to-ledger lag is 3–13 calendar days.** One deterministic 1-day source-delivery SLA breach occurs per ISO week by design. | "Real-time" replaced by two explicit tiers: **intraday operational** (CRM pipeline, order entry) and **T+1 financial** (ledger). Every dashboard carries a visible `data_as_of` watermark (NFR-4). |
| D | *"Churn indicators 60 to 90 days before contract expiration"* | There is no contract expiration. Churn at Northwind is **behavioural**: logo churn is defined as no order in a trailing window from a customer who ordered before it. | Reframed as **lapse prediction** against segment-specific reorder cadence. Horizon expressed in days-since-last-order and predicted-next-order date, never days-to-expiry (FR-3.2). |
| E | *"Recommend optimal discount ranges"* | `crm.opportunities.DiscountPercent` is subject to an approval ceiling **that has not been constant over the window**, and that ceiling is recorded nowhere. A model trained naively on history will recommend discounts that are no longer approvable. | Requires a new **effective-dated discount-approval-policy reference table** owned by RevOps (**D-24**). All model output is clipped to the ceiling in force on the quote date (FR-4.2). |
| F | *"Win probability scores (0–100%)"* | `crm.opportunities.Probability` is stage-implied — a deterministic function of `StageName`, not a model. `SalesCycleDays` (= `CloseDate − CreatedDate`) and `LossReason` exist **only on closed rows**. Training on them is target leakage. | Stage probability becomes the **baseline to beat**, not a feature. A point-in-time feature store and a published leakage blocklist are mandatory (DR-3, D-25). |
| G | *"Dashboards render within <3 seconds"* | Correct intent, silent on volume: 4.6M order lines, 2.4M opportunities, 1.3M revenue postings, 1.3M shipments. | Restated with window and percentile: **p95 < 3s on a rolling 13-month window; p95 < 8s on full history**, with a declared aggregate strategy (NFR-1). |
| H | *8-month, 4-phase plan* | Ops and ERP change-data-capture is **gated on an audit-column backfill that has not completed**. Until `generator.audit_backfill` finishes and is validated, a NULL audit field cannot be read as an absent business event. | **Phase 0 added**; Phase 1 extended. **11 months** to full prescriptive rollout, with descriptive value landing in **month 4**. Critical path named in §9. |
| I | *Metric targets stated as bare percentages* | e.g. "20% increase in pipeline conversion efficiency" has no baseline, no measurement method, and no window — it cannot be passed or failed. | Every target in §1.3 now carries a **baseline, measurement method, and measurement window**. |

## 1.3 Value drivers with measurable targets

| Tier | Capability | Business outcome | Target | Baseline & measurement |
|---|---|---|---|---|
| **1. Descriptive** | Governed bookings, billed revenue, and the bridge between them; operational scorecards | One agreed revenue number per entity-period, with the sales/finance gap explained rather than argued | ≤ **0.5%** unexplained residual per `(fiscal_period, company_code)`; **0** exceptions aged >10 business days | Baseline set from a 12-month back-test at Phase 1 exit. Measured monthly at close +3 business days. |
| **2. Diagnostic** | Funnel leakage, realised-vs-approved discount, margin decomposition, churn attribution | Movements in win rate, margin, OTD and churn are attributed to a cause, not narrated | **≥ 80%** of period-over-period margin and win-rate variance attributed to named drivers (mix, price, volume, FX, discount) | Baseline = current attribution rate of 0% (no capability exists). Measured quarterly against a manual RevOps/FP&A review panel. |
| **3. Predictive** | Opportunity win-scoring, account lapse risk, demand and lateness forecasting | Reps and AMs work a ranked list instead of a flat pipeline | Win model **AUC ≥ 0.72** and beats the stage-probability baseline by **≥ 0.08 AUC** on a time-blocked holdout; order-volume forecast **MAPE ≤ 12%** at 4-week horizon, regional grain | Baseline = `crm.opportunities.Probability`. Measured on a rolling out-of-time holdout, reported monthly. |
| **4. Prescriptive** | Next-Best-Action, policy-aware deal guidance, stall escalation | Guidance delivered where the work happens, inside CRM and BI | **≥ 60%** NBA surfacing rate on eligible accounts; measured lift on a **holdout control group**, not on adopters vs non-adopters | Randomised holdout established before rollout. Any lift claim without a control group is not accepted. |

## 1.4 ROI and strategic justification (revised)

- **Cycle-time and effort recovery.** RevOps, FP&A and Sales Ops currently reconcile CRM, `ops` and `erp` by hand each period. The bridge (FR-1.2) replaces that with a governed model and an exception queue. **Quantified benefit is the reduction in reconciliation hours, which is measurable from day one** — unlike revenue-attribution claims, which are not.
- **Proactive retention.** Lapse prediction targets accounts whose ordering cadence is decaying, using order recency, support-case history and resolution time — all of which have real signal in this data.
- **Margin protection.** Realised discount (`1 − unit_price/list_price_usd`) diverges from approved discount (`DiscountPercent`). Quantifying that divergence is a Phase 2 deliverable and is the honest, defensible version of v1.0's margin claim.
- **Guided selling.** NBA and deal guidance are Phase 4, and their ROI claim is deliberately deferred until a holdout control group exists. **This document does not pre-book benefits it cannot measure.**

---

# Part 2 — Business Requirements Document

## 2. Scope

### 2.1 In scope

1. Incremental extraction from all three source systems into a governed analytical warehouse.
2. Cross-system identity resolution (account, opportunity, order, posting) with a stewarded exception queue.
3. Currency and FX normalisation to three reporting bases: document, company (functional), and group (USD).
4. A dimensional analytical layer supporting all four tiers, with full lineage to source transactions.
5. Role-based BI delivery with region- and entity-scoped access control.
6. Predictive models for opportunity win, account lapse, order-volume demand, and shipment lateness.
7. Prescriptive NBA delivery into BI, plus a scoped CRM write-back integration.
8. Data quality monitoring calibrated against the estate's known anomaly budget.

### 2.2 Explicitly out of scope

| Item | Reason |
|---|---|
| ARR, MRR, and any subscription metric | No contract, term, or renewal data exists in the estate. See **OPEN-01**. |
| Contractual churn and renewal forecasting | Same. Behavioural lapse prediction is the in-scope substitute. |
| Master data management / golden-record authoring in the source systems | ERAE **reads and reconciles**; it does not become the system of record. Source corrections are routed to the owning team. |
| Write-back to `ops` or `erp` | Both are transactional systems of record. `erp.revenue_postings` is enforced append-only (migration `005_enforce_revenue_posting_immutability.sql`). |
| Statutory / regulatory financial reporting | ERAE is a management-reporting layer. Statutory reporting remains with Finance in `erp`. |
| Real-time (sub-minute) streaming | Source-to-ledger lag is 3–13 days; streaming would add cost without changing decision latency. |
| Cost-to-serve and full P&L allocation | Requires expense-side data beyond `erp.revenue_postings`. Candidate for a Phase 5 business case. |

### 2.3 Source systems of record

| System | Owner | Access | Notes constraining design |
|---|---|---|---|
| **CRM** | Sales Operations | FakeForce REST API, Salesforce-shaped | PascalCase fields, 18-char all-digit string ids, soft deletes, `SystemModstamp` watermark |
| **`ops`** | IT Operations | Dedicated Postgres, `localhost:5433` | ~1.5M orders, 4.6M order lines, 1.3M shipments, 400K support cases; audit-column backfill in progress |
| **`erp`** | Finance | Dedicated Postgres, `localhost:5434` | ~1.3M revenue postings; append-only; dual-currency by design |

**Constraint of record:** a constraint never crosses a source-system boundary. Every cross-system relationship is a business key that ERAE must reconcile and *prove*, not a join the database will guarantee.

### 2.4 Assumptions

| ID | Assumption | If false |
|---|---|---|
| A-1 | Sales Ops grants API access at a call budget sufficient for a full daily incremental plus periodic reconciliation sweeps | Extraction cadence degrades to weekly; freshness SLA (NFR-4) cannot be met |
| A-2 | Finance accepts a documented FX policy (**OPEN-03**) rather than per-report ad-hoc rates | Group-currency reporting cannot be certified; all cross-entity roll-ups stay provisional |
| A-3 | The `ops` and `erp` audit backfills complete and validate before Phase 1 exit | CDC on `updated_at` remains unsafe; fallback is PK-range reload at materially higher cost (**R-2**) |
| A-4 | RevOps can reconstruct the historical discount-approval ceiling to at least quarterly granularity | FR-4.2 deal guidance descopes to advisory-only with no policy clipping |
| A-5 | Region-level RBAC satisfies Legal and Privacy for a five-entity, multi-jurisdiction estate | Additional entity-level controls and possible data residency work enter scope |

### 2.5 Dependencies

- **D-dep-1:** `python -m generator.audit_backfill` (ops) and `--system erp` complete and pass zero-null validation → gates migrations `004_enforce_audit_metadata.sql` on both sides → gates safe `updated_at`-based CDC.
- **D-dep-2:** `python -m generator.metadata_registry` is run after **every** source schema change, so `analytics.metadata.table_versions` / `column_versions` stay current. ERAE's CI gate reads those versions (D-29).
- **D-dep-3:** CRM contract registration remains API-driven and is **not** inferred from local Parquet. Schema drift detection for CRM must be built against the API, not against landed files.

---

## 3. Foundational Data Requirements

These precede every functional requirement. Nothing in §4 can be accepted until its parent DR is accepted.

### DR-1 — Cross-system identity resolution

| Link | From → To | Reality |
|---|---|---|
| Account | `ops.customers.account_number` → `crm.accounts."AccountNumber"` | 1:1 in principle. Canonical form is `ACC-` + six digits. **Accounts opened before the mid-2024 CRM migration were keyed by hand**, so `ops` holds whatever the operator typed. Format varies with `created_at`. |
| Opportunity | `ops.orders.opportunity_ref` → `crm.opportunities."Id"` | N:1. NULL always for `ECOMM`, and for a minority of `DIRECT`/`PARTNER` orders booked without an opportunity. **Referenced opportunities may have been soft-deleted since.** |
| Order | `erp.revenue_postings.order_ref` → `ops.orders.order_id` | N:1. NULL for `ADJ` postings, which are entity-level. |
| Entity | `ops.customers.company_code` → `erp.companies.company_code` | N:1. `ops` validates the legal-entity code set locally but cannot hold an ERP foreign key. Determines booking currency. |

**DR-1.1** A deterministic normalisation ruleset for `account_number` (case, whitespace, separator, zero-padding, prefix variants) must be authored, version-controlled, and unit-tested against the pre-2024 hand-keyed population specifically.

**DR-1.2** Every match must carry a **confidence tier** — `EXACT`, `NORMALISED`, `PROBABILISTIC`, `UNMATCHED` — persisted on the account bridge and exposed as a filter in BI. Executives must be able to see revenue on unmatched accounts, not have it silently dropped or silently included.

**DR-1.3** `PROBABILISTIC` and `UNMATCHED` rows enter a stewarded exception queue with a named owner and a 5-business-day resolution SLA.

**DR-1.4** **Orphaned opportunity references are expected, not a defect.** Whether they appear depends on the extraction endpoint: `/query` omits soft-deleted records, `/queryAll` includes them, and `/sobjects/Opportunity/deleted` lists removed ids. Orders in `ops` were placed before any deletion and still carry the ids. Extraction must use `/queryAll` plus the deleted-ids endpoint so that ERAE can distinguish *deleted in CRM* from *never existed*.

**DR-1.5** `IsDeleted` state must be modelled as an attribute with an observed-at date, not used to filter rows out of history.

**Acceptance:** ≥ 99.0% of `ops.customers` resolve to exactly one CRM account under the ruleset; **zero** many-to-one collisions in the accepted set; unmatched revenue is quantified and visible on every revenue dashboard as a named line.

### DR-2 — Currency, FX, and reporting basis

Money in this estate is stated in the currency named beside it. Only `list_price_usd`, `standard_cost_usd`, `unit_cost_usd`, `freight_cost_usd` and `credit_limit_usd` are pre-converted, and they say so in their names.

**DR-2.1 — Three bases, all persisted.** Every revenue and margin fact carries: **document currency** (what the customer transacted in), **company currency** (the booking entity's functional currency — already dual-stated on `erp.revenue_postings` as `amount_doc` / `amount_company`), and **group currency (USD)** for cross-entity roll-up. `amount_doc` and `amount_company` describing the same money on two bases **is not a discrepancy** and must never be tested as one.

**DR-2.2 — FX densification is mandatory.** `erp.fx_rates` has two conventions that will silently corrupt any naive join:
- Rates are published on **banking days only** — no row exists for a Saturday, Sunday, or market holiday.
- **Identity pairs are never published** — there is no `USD → USD` row, because the rate is 1 by definition.

ERAE must build a dense FX dimension over a full date spine with last-observation-carried-forward and a synthesised identity rate of exactly 1.0. **Without this, every weekend and holiday order loses its conversion silently, and every USD transaction drops out of an inner join.** This is a top-three defect risk (R-1).

**DR-2.3 — Minor units.** Amounts are rounded to the ISO 4217 minor unit of their currency. **JPY has no minor unit**, so JPY values are whole numbers and are numerically far larger than USD equivalents. No test, threshold, outlier rule, or axis scale may be authored on unconverted mixed-currency amounts.

**DR-2.4 — Constant-currency reporting.** Every period-over-period revenue and margin comparison must be available in both **actual** and **constant-currency** form. Without it, FX movement across five functional currencies presents as growth or decline in the diagnostic tier and will be acted on as if it were performance.

**DR-2.5 — Rate policy.** The rate used for group reporting (daily spot at `posting_date` vs month-end close vs period average) is a **Finance decision, not an engineering one** — see **OPEN-03**. The chosen policy is encoded once in the FX dimension and used everywhere.

**Acceptance:** 100% of orders and postings resolve a rate for their business date and currency; zero rows fall out of the currency join; a documented reconciliation of `amount_company` against `amount_doc × rate` at declared tolerance.

### DR-3 — Temporal grain, late-arriving facts, and point-in-time correctness

**DR-3.1 — Dates carry meaning; pick the right one.**

| Concept | Column | Not to be confused with |
|---|---|---|
| Revenue timing (sales view) | `ops.orders.order_date` | `created_at`, which diverges when orders are entered retrospectively |
| Revenue timing (Finance view) | `erp.revenue_postings.posting_date` — *the date the revenue belongs to* | `posted_at`, when the document hit the ledger |
| Physical shipment | `ops.shipments.ship_date` | `created_at` on the shipment record |
| Case opening | `ops.support_cases.opened_at` | `created_at` |
| Account acquisition (cohorts) | `ops.customers.created_at` | — |

**DR-3.2 — Late-arriving facts are structural.** `posted_at` is always ≥ `posting_date`, **and the gap is not constant** — month-end close and backdated corrections both widen it. A posting landing today can belong to a period closed weeks ago.

**DR-3.3 — Restatement window and frozen snapshots.** Marts must re-materialise a trailing restatement window (initial proposal: 45 days, plus any period reopened by Finance). Separately, **as-reported figures must be frozen in an immutable accounting snapshot at close**, so a period's reported number never changes retroactively on an executive dashboard. Both *as-reported* and *as-restated* views are required, and the difference between them is itself a Finance-facing metric.

**DR-3.4 — Credit notes reverse prior periods.** `reverses_posting_id` is set on `CRN` rows and only on `CRN` rows, and the invoice it points at is frequently in an earlier period. Net revenue for a closed period is therefore mutable by design. This is a first-class case for DR-3.3, not an anomaly.

**DR-3.5 — Point-in-time features for all models.** Model features must be reconstructed **as of the scoring date**, never from current-state columns. Named leakage blocklist for opportunity win-scoring:

| Field | Why it leaks |
|---|---|
| `Probability` | Deterministic function of `StageName`; encodes the outcome path |
| `SalesCycleDays` | Defined as `CloseDate − CreatedDate`; unknowable while open |
| `LossReason` | Populated only when `StageName = 'Closed Lost'` |
| `CloseDate` on closed rows | Actual close for closed stages, forecast for open — different semantics per row |
| `LastModifiedById`, `LastModifiedDate`, `SystemModstamp` | Advance after close |
| `StageName` itself | Terminal values are the label |

**DR-3.6 — Cohort maturation and right-censoring.** `delivered_date` NULL means **in transit, not missing**. OTD must be computed only on shipments whose `promised_delivery_date` has matured past the as-of date; otherwise recent shipments bias the rate. The same discipline applies to sales cycle (only closed opportunities have one — survivorship bias) and to logo churn (trailing-window definitions are censored at the edge of the data window).

### DR-4 — Incremental extraction and change data capture

**DR-4.1 — CRM.** Extract changed Accounts and Opportunities using the **ordered pair `(SystemModstamp, Id)`**, not `LastModifiedDate` alone. `SystemModstamp` is always ≥ `LastModifiedDate`. Older locally generated seed files remain readable because FakeForce presents historical `LastModifiedDate` and `OwnerId` as compatibility fallbacks — the pipeline must not depend on that fallback persisting.

**DR-4.2 — Watermark boundary safety.** Timestamps are **second-granularity and naive** (no timezone, no sub-second). Bulk maintenance jobs stamp many rows with an identical `updated_at`. A strict `>` watermark will therefore skip rows; a `>=` watermark will re-read them. **The pipeline must use `>=` with idempotent primary-key merge**, never `>`.

**DR-4.3 — Ops/ERP audit rollout gate.** Migration `002_add_audit_metadata.sql` added audit fields as **nullable** so large existing databases were not rewritten. New seed loads and simulated events populate them from that release onward. Migration `003_add_audit_backfill_state.sql` supplies durable, resumable checkpoints for `python -m generator.audit_backfill` (ERP resumes `revenue_postings` by `posting_id`). **Until the backfill completes and validates, a NULL audit field in a pre-migration row must not be read as an absent business event or a deletion.** Migration `004_enforce_audit_metadata.sql` then makes the fields mandatory and rejects `updated_at` earlier than `created_at`.

**DR-4.4 — ERP is append-only.** Corrections create new `CRN` or `ADJ` rows rather than changing a posted entry; migration `005` rejects `UPDATE` and `DELETE` on posted journal records. `created_at` equals `posted_at`, and there is intentionally no `updated_at`. Incremental extraction may therefore key on `posting_id` — but downstream **period aggregates must still honour the DR-3.3 restatement window**, because a newly appended posting can carry an old `posting_date`.

**DR-4.5 — Replay-safe, business-date-keyed pipelines.** The source simulation advances one calendar date at a time at midnight `America/Los_Angeles` and always resumes from the last successfully completed date — if the host was down two days, it generates both missing dates in order and never jumps to today or dumps the gap at once. **ERAE's orchestration must mirror this semantics exactly:** keyed on business date, resumable, idempotent on retry, never backfilling a gap as a single oversized load.

**DR-4.6 — Salesforce ids are all-digit strings.** `Id`, `AccountId`, `OwnerId`, `CampaignId`, `CreatedById`, `LastModifiedById`. `pandas.read_csv` will read `001000000000000001` as an integer and drop the leading zeros unless the dtype is pinned. **Every hop — extraction, Parquet staging, warehouse DDL, BI dataset — must carry these as strings.** Enforced by contract test (D-28).

### DR-5 — Historical attribution and slowly changing dimensions

**DR-5.1 — Validity ranges, not flags.** `erp.cost_centers` is slowly changing. A centre is the correct attribution for a posting when `valid_from <= posting_date < COALESCE(valid_to, 'infinity')`. Retired centres keep all historical postings and must remain joinable. `dim_cost_center` is **SCD Type 2 with an effective-dated join** — a current-state join silently misattributes history.

**DR-5.2 — Current-state flags are not history.** `ops.customers.is_active`, `ops.products.is_discontinued`, and `erp.cost_centers.is_active` describe **now**. Date ranges carry history: `valid_from`/`valid_to`, `launch_date`/`discontinued_on`, `created_at`. No historical metric may be filtered on a current-state flag.

**DR-5.3 — Snapshot from day one.** Where the source holds only current state, **history not captured now is lost permanently.** Snapshot jobs for `ops.customers` (activity/segment), `ops.products` (discontinuation), and CRM opportunity stage transitions must be deployed in **Phase 0**, ahead of any dashboard, even though they return no visible value for months. This is a deliberate sequencing decision and is on the critical path.

**DR-5.4 — Discontinuation is not termination.** Support renewals and open orders legitimately continue past `discontinued_on`. Product-lifecycle reporting must not treat post-discontinuation revenue as an error.

### DR-6 — NULL semantics and the anomaly budget

**DR-6.1 — NULL frequently means something specific.** The semantic layer must encode the meaning per column, and data-quality tests must not flag these as defects:

| Column | NULL means |
|---|---|
| `ops.orders.opportunity_ref` / `rep_id` | Self-serve order; always for `ECOMM`, sometimes for `DIRECT`/`PARTNER` |
| `ops.shipments.delivered_date` | In transit at the edge of the window |
| `ops.support_cases.resolution_hours` | Case is still `Open` |
| `ops.support_cases.csat_score` | No survey response — **most of the time** |
| `erp.revenue_postings.order_ref` / `cost_center_code` | Entity-level `ADJ` posting |
| `crm.opportunities.LossReason` | Not `Closed Lost` |
| `crm.opportunities.CampaignId` | `LeadSource` is not `Marketing Campaign` |
| `erp.cost_centers.valid_to` | Still open |
| `crm.sales_reps.departure_date` | Current staff |

**DR-6.2 — CSAT response bias.** CSAT response is **not random — it correlates with resolution time**. Any CSAT figure must be reported alongside its response rate, and unweighted average CSAT is prohibited on executive views (FR-2.3, NFR-6).

**DR-6.3 — Alert thresholds must sit above the anomaly budget.** The estate carries a known, intentional exception rate. Monitoring calibrated to zero will page constantly and be ignored within a week.

| Exception | Expected rate | Monitoring posture |
|---|---|---|
| Long-open opportunity | 0.6% | Statistical control limits; alert on rate shift, not on instances |
| Delayed CRM→Ops conversion | 0.4% | Same |
| Stalled shipment | 0.8% | Same; feeds FR-3.4 lateness model as a label, not an alert |
| Late ERP posting | 0.4% | Same; must not trigger a close-blocking alert |
| Source-delivery SLA breach | Once per ISO week, 1 day | **Recoverable by design — logs and self-heals on the next run; must not page.** Dashboards reflect it via `data_as_of`. |

**DR-6.4 — Recovery path.** Before a business date is marked complete, a bounded reconciliation confirms each newly planned Ops and ERP event has both its local retry marker and its expected order, shipment, invoice or revenue-posting record. A mismatch leaves the date incomplete so the normal replay path recovers it. **ERAE must consume completion state and refuse to publish a partially loaded business date as final.**

### DR-7 — Lineage, contracts, and auditability

**DR-7.1** Every calculated revenue metric traces to raw source transactions, at posting-line and order-line grain, with the transformation path documented and machine-readable.

**DR-7.2** ERAE consumes the central contract registry — `analytics.metadata.table_versions` and `analytics.metadata.column_versions` — as a **CI gate**. A source schema change that has not been re-registered (`python -m generator.metadata_registry`) fails the build rather than silently breaking a downstream model. CRM contract registration is API-driven and must be checked against the API, never inferred from local Parquet.

**DR-7.3** The generator is deterministic: the same `--seed` and `--scale` reproduce the dataset exactly. **ERAE exploits this for golden-dataset regression testing in CI** (D-30) — a capability most production estates do not have, and one we should not waste.

---

## 4. Functional Requirements by Analytics Tier

Each requirement now carries its source mapping and its acceptance criteria.

### FR-1 — Descriptive: *What happened?*

**FR-1.1 — Consolidated revenue reporting**
- *Sources:* `ops.orders`, `ops.order_lines`, `erp.revenue_postings`, `int_fx_rates_densified`
- Publish **Bookings** (sum of `line_amount` on non-cancelled orders, by `order_date`) and **Billed Revenue** (sum of `amount_doc` by `posting_date`, net of credit notes) as two separately named, separately owned measures. They are different measures. **Never present one as a correction of the other.**
- Publish **Recurring-Proxy Revenue** (Support Plan + Software License categories) with its recognition assumption on the tile. ARR/MRR remain out of scope pending OPEN-01.
- All measures available in document, company, and group (USD) currency, actual and constant-currency.
- *Acceptance:* measures reconcile to source at line and posting grain within rounding tolerance for the ISO 4217 minor unit of each currency; JPY validated explicitly as a zero-decimal case.

**FR-1.2 — The bookings→billed bridge** *(replaces "100% reconciliation" — the flagship Phase 1 deliverable)*
- Produce, for every `(fiscal_period, company_code)`, an explained waterfall:

```
Bookings (non-cancelled orders, by order_date)
  − orders not yet shipped or invoiced          [status = PENDING]
  − cancelled after booking                     [status = CANCELLED, lines retained]
  ± timing lag                                  [order_date vs posting_date, 3–13 day chain]
  − orders shipped but not yet posted           [invoice→posting SLA 1–2d, plus 0.4% late budget]
  − credit notes                                [CRN, reverses_posting_id, often a prior period]
  ± entity-level adjustments                    [ADJ, order_ref NULL, no order trace]
  ± FX basis difference                         [amount_doc vs amount_company vs group USD]
  ± unmatched identity                          [DR-1 exception queue]
  = Billed Revenue (erp.revenue_postings, by posting_date, net)
```

- Every bridge line drills to its constituent transactions.
- *Acceptance:* **≥ 99.5% of absolute variance classified into named categories; unexplained residual ≤ 0.5% of billed revenue per entity-period; zero exceptions aged beyond 10 business days.** Signed off by the Controller before Phase 1 exit.

**FR-1.3 — Historical performance reporting**
- YoY / QoQ / MoM across region, entity, segment, product category, product family (`Core`/`Extended`/`Aurora`), channel (`DIRECT`/`PARTNER`/`ECOMM`), and rep.
- **Constant-currency toggle is mandatory on every cross-entity comparison** (DR-2.4).
- Cohort retention curves anchored on `ops.customers.created_at`.
- *Acceptance:* 3.5 years of history renders within NFR-1; effective-dated cost-centre attribution verified against a Finance-supplied test period.

**FR-1.4 — Operational scorecards**
- **Delivery:** carrier and lane OTD on matured shipments only (DR-3.6), including **published vs actual** — `ops.carriers.published_otd_rate` is the contractual claim and is not obliged to agree with `ops.shipments`. The gap is the metric.
- **Service:** case volume, time-to-resolution as median and p90 (never mean) by priority `P1`–`P4`, channel, and `assigned_region`. **`assigned_region` is the handling team, not the customer's region** — the two must be modelled separately.
- **Sales:** quota attainment as rep bookings ÷ pro-rated `quota_usd_annual`, pro-rated on `hire_date` and `departure_date`. Reps ramp over roughly two quarters; attainment for reps inside the ramp window is flagged, not hidden.

### FR-2 — Diagnostic: *Why did it happen?*

**FR-2.1 — Pipeline variance and funnel leakage**
- *Sources:* `crm.opportunities` (stage snapshots), `crm.sales_reps`, `crm.campaigns`
- Stage-to-stage conversion across `Prospecting → Qualification → Proposal → Negotiation → Closed Won/Lost`, sliced by segment, region, rep, `LeadSource`.
- Loss decomposition on the six `LossReason` values (`Price`, `Competitor`, `No Decision`, `Timing`, `Feature Gap`, `Budget Cut`).
- **Requires the stage-transition snapshot from DR-5.3.** Funnel analytics cannot be reconstructed from current stage alone. If Phase 0 snapshots do not land, this requirement slips wholesale.
- *Acceptance:* conversion rates reproducible from snapshot history for any as-of date after snapshot go-live; long-open opportunities (0.6% budget) excluded from cycle-time medians and reported separately.

**FR-2.2 — Discount, price, and margin decomposition**
- **Realised discount** (`1 − unit_price / list_price_usd`, common currency basis) versus **approved discount** (`order_discount_pct`, `DiscountPercent`). The divergence between the two is the primary margin-leakage signal.
- Margin = `line_amount − (quantity × unit_cost_usd)`, **with both sides forced onto the same currency basis first** (DR-2).
- Period-over-period margin movement decomposed into **volume · mix · price · discount · FX**. Gross margin differs sharply by category, so category mix shift is a first-class driver, not a residual.
- *Acceptance:* ≥ 80% of margin variance attributed to named drivers; decomposition sums to actual within 1%.

**FR-2.3 — Churn and retention attribution**
- Logo churn (no order in trailing window, given a prior order) and cohort NRR (cohort revenue this period ÷ same cohort last period), by segment, region, entity, acquisition cohort.
- Candidate drivers: order recency decay, support-case volume and severity mix, time-to-resolution, product discontinuation exposure, realised-price change.
- **CSAT may be used as a driver only with its response rate stated** (DR-6.2).
- *Acceptance:* churn definitions parameterised (trailing window length is a configurable input, not hard-coded); censoring at the window edge disclosed on every chart.

**FR-2.4 — Changepoint and cause detection** *(new in v2.0)*
- The business has a history — it grew, launched and retired products, changed pricing, renegotiated a carrier contract, reorganised a support team, and met a new competitor in one region. **None of it is labelled anywhere in the data.** It is visible only as movements in the numbers.
- Provide changepoint detection over the primary series (margin, win rate, freight cost per kg, OTD, churn by region) with an annotation workflow so that RevOps, Finance and Ops can **attach a human explanation to a detected break and have it persist**.
- *Acceptance:* detection surfaces the known historical breaks in a back-test; annotations persist across model reruns and appear on the corresponding executive charts.

### FR-3 — Predictive: *What will happen?*

All models are subject to DR-3.5 (point-in-time features, leakage blocklist).

**FR-3.1 — Opportunity win-scoring**
- Real-time win probability on open pipeline. Legitimate features: `Amount`, `CurrencyIsoCode`, approved discount, segment, region, channel, `LeadSource`, campaign attribution, account order history, account support history, days in current stage, rep identity and tenure.
- **Rep is a legitimate but hazardous feature.** Reps differ in win rate, deal size and discount appetite; those differences are stable and recorded nowhere. Including rep improves accuracy and risks a self-fulfilling loop once scores drive rep behaviour through FR-4.1. **Requirement: publish both a rep-inclusive and a rep-blind model; the rep-blind score is what is shown to sales management for performance conversations.**
- *Acceptance:* AUC ≥ 0.72 on a time-blocked out-of-time holdout; ≥ 0.08 AUC over the `Probability` baseline; calibration curve published; leakage blocklist enforced by an automated feature-lineage test.

**FR-3.2 — Account lapse (churn) risk**
- Daily account health score. Features: order recency against **segment-specific** reorder cadence (segment drives order frequency, basket size, cycle length and retention), basket trend, case volume and priority mix, resolution time, discontinued-product exposure, payment terms, credit utilisation.
- Output is **predicted days-to-lapse and lapse probability**, not days-to-expiry (see amendment D).
- *Acceptance:* precision@k reported at the k the retention team can actually work; back-test on held-out cohorts; label definition versioned with the model.

**FR-3.3 — Demand and revenue forecasting**
- Daily and weekly order volume by region — a well-behaved target with trend, weekly seasonality, quarter-end effects and holidays. Weighted pipeline forecast and expected revenue-recognition dates derived from historical stage velocity and the observed 3–13 day conversion chain.
- *Acceptance:* MAPE ≤ 12% at 4-week horizon, regional grain; forecast intervals published, not point estimates alone; backtest covers at least two full seasonal cycles (the 3.5-year window supports this).

**FR-3.4 — Shipment lateness and freight cost** *(new in v2.0 — high-confidence, low-cost signal)*
- Lateness risk from carrier, lane, service level (`STANDARD` 5d / `EXPEDITED` 2d / `ECONOMY` 9d) and season. Freight cost is close to a regression on distance, weight, service level and carrier.
- Carrier mix is **not constant across the window** — the model must be retrained on a rolling window and monitored for drift rather than fitted once.
- *Acceptance:* lateness model beats a carrier-average baseline on a matured holdout; freight model R² ≥ 0.85; both feed the FR-4.3 escalation engine.

### FR-4 — Prescriptive: *What should we do?*

**FR-4.1 — Next-Best-Action engine**
- Actions delivered in BI and, subject to scope agreement with Sales Operations, written back to CRM. Example: *"Account X: three P2 cases open, order cadence 40% below its Enterprise-segment norm — schedule a service review."*
- **CRM write-back is a separate, negotiated integration** with its own API budget, rate limits, error handling and rollback, and its own sign-off from the CRM owner. It is **not** a sub-task of the model.
- Every recommendation persists its inputs, model version, and timestamp, so a rep can ask *why* and get an answer.
- *Acceptance:* ≥ 60% surfacing rate on eligible accounts; recommendation latency within the daily batch; a **randomised holdout control group established before rollout** — no lift claim is accepted without it.

**FR-4.2 — Policy-aware deal guidance**
- Recommend a discount range at quote creation that maximises expected margin-weighted win probability.
- **Hard constraint:** recommendations are clipped to the approval ceiling in force on the quote date, sourced from the new effective-dated policy table (D-24). The historical ceiling has moved; a model trained on history without this constraint will confidently recommend discounts that RevOps will reject, and the tool will lose credibility in its first week.
- *Acceptance:* zero recommendations exceeding the in-force ceiling in production shadow-mode testing; guidance quotes an expected-margin impact alongside the win-probability impact.

**FR-4.3 — Automated escalation**
- Alert Sales Leadership when a high-value deal stalls beyond its **segment- and stage-specific** duration norm — not a single global threshold, since sales-cycle length varies by segment by design.
- Alert Ops when a shipment's lateness risk (FR-3.4) crosses threshold while intervention is still possible.
- **Thresholds calibrated above the anomaly budget** (DR-6.3): the 0.6% long-open and 0.8% stalled-shipment rates are the expected baseline, not the alert condition.
- *Acceptance:* alert precision measured over a 30-day pilot; a documented suppression and acknowledgement path; **alert volume per recipient capped and reviewed monthly.**

---

## 5. BI, User Interface, and Access Requirements

### 5.1 Role-based views

| View | Primary users | Content | Default scope |
|---|---|---|---|
| **Executive** | CRO, CFO, ELT | Bookings & billed revenue trend, bridge summary, forecast accuracy, top risks, constant-currency toggle | All entities, group USD |
| **Finance / Controller** | Controller, FP&A | Full bridge with drill-to-posting, CRN and ADJ detail, cost-centre attribution, as-reported vs as-restated, FX basis detail | Own entity, expandable |
| **RevOps** | RevOps analysts | Funnel leakage, realised vs approved discount, pipeline coverage, identity exception queue | All regions |
| **Sales Manager** | Regional managers | Team quota attainment (ramp-flagged), deal win scores (**rep-blind version**), stalled-deal escalations | Own region |
| **Sales Rep** | Individual reps | Own pipeline, win scores, deal guidance, NBA, account health | Own accounts only |
| **Service & Logistics** | Support and Ops leads | Case volume, TTR p50/p90, CSAT with response rate, carrier scorecards, lateness alerts | Own region |

### 5.2 Interactivity and export
- Slice across region, entity, segment, industry, product category, product family, channel, carrier, service level, campaign, and date.
- Currency basis selector (document / company / group USD) and constant-currency toggle present on every monetary view.
- Export to CSV and PDF; scheduled daily and weekly email summaries. **Exports carry the `data_as_of` watermark and the currency basis in the filename and header** — an undated, unlabelled export circulating in email is how reconciliation disputes start.

### 5.3 Access control
- RBAC scoped by **region and legal entity**. A five-entity, multi-jurisdiction estate means access design is a Legal and Privacy question, not only a permissions question (A-5).
- Rep-level performance data (win rates, discount behaviour) is visible to the rep and their management chain, not laterally across the sales organisation.
- All access grants reviewed quarterly with evidence retained.

---

## 6. Non-Functional Requirements

| ID | Requirement | Target |
|---|---|---|
| **NFR-1** | Dashboard render performance | p95 **< 3s** on a rolling 13-month window; p95 **< 8s** on the full 3.5-year history. Aggregate strategy declared and reviewed at each phase gate. |
| **NFR-2** | Batch completion | All transformations complete before **06:00 `America/Los_Angeles`**, aligned to the source simulation's midnight advance in the same timezone. |
| **NFR-3** | Pipeline recoverability | Every job idempotent and replayable by business date; a two-day outage recovers by processing both dates in order, never as a single oversized load (DR-4.5). |
| **NFR-4** | Freshness transparency | Every dashboard, export and API response carries `data_as_of` per source system. **A stale dashboard that says so is acceptable; one that does not is not.** |
| **NFR-5** | Lineage and auditability | Every published metric traces to source transactions; lineage machine-readable and exposed in the catalogue (DR-7.1). |
| **NFR-6** | Statistical integrity | Median and p90 for skewed distributions (resolution time, deal size); response rate published with any survey metric; censored populations disclosed on the chart. |
| **NFR-7** | Data type integrity | Salesforce ids as strings end to end; currency amounts never compared or aggregated across currencies without conversion (DR-2.3, DR-4.6). |
| **NFR-8** | Security | RBAC enforced in the warehouse, not only in the BI tool. Row-level security testable and tested. |
| **NFR-9** | Cost | Warehouse spend tracked per model and reviewed at each phase gate; incremental strategies mandatory on the four largest facts (order lines, opportunities, postings, shipments). |
| **NFR-10** | Documentation | Every published model carries an owner, a description, and a freshness expectation. Undocumented models fail CI. |

---

## 7. Analytics Team Deliverables Register

The concrete artefacts the analytics team owns. Phase in brackets.

### 7.1 Ingestion & platform

| ID | Deliverable | Notes |
|---|---|---|
| D-01 | CRM extractor with `(SystemModstamp, Id)` watermark, `/queryAll` + deleted-ids endpoint | [P0] DR-4.1, DR-1.4 |
| D-02 | `ops` extractor with `>=` watermark and PK merge; PK-range fallback until backfill validates | [P0] DR-4.2, DR-4.3 |
| D-03 | `erp` extractor keyed on `posting_id` (append-only) | [P0] DR-4.4 |
| D-04 | Raw landing zone with pinned string dtypes for all Salesforce ids | [P0] DR-4.6 |
| D-05 | Business-date-keyed, resumable orchestration DAG with completion-state gate | [P0] DR-4.5, DR-6.4 |
| D-06 | Source freshness monitors per system, calibrated to the causal SLA chain | [P0] DR-6.3 |

### 7.2 dbt project — staging

| ID | Deliverable | Notes |
|---|---|---|
| D-07 | `stg_ops__*` (customers, products, orders, order_lines, shipments, invoices, support_cases, warehouses, carriers) | [P0] Rename, cast, enum-validate; no business logic |
| D-08 | `stg_erp__*` (companies, cost_centers, gl_accounts, fx_rates, revenue_postings) | [P0] |
| D-09 | `stg_crm__*` (accounts, opportunities, sales_reps, campaigns) | [P0] PascalCase → snake_case; ids stay strings |
| D-10 | `sources.yml` with per-table freshness thresholds and documented NULL semantics | [P0] DR-6.1 |

### 7.3 dbt project — snapshots *(Phase 0, non-negotiable)*

| ID | Deliverable | Notes |
|---|---|---|
| D-11 | `snap_ops_customers` — `is_active`, `segment`, `credit_limit_usd` | [P0] DR-5.3 |
| D-12 | `snap_ops_products` — `is_discontinued`, price, cost | [P0] |
| D-13 | `snap_crm_opportunity` — stage, amount, discount, owner over time | [P0] Sole basis for FR-2.1 funnel and FR-3.1 point-in-time features |

> **Escalation note for the steering committee:** D-11 through D-13 produce no user-visible output for roughly four months. They are still first in the build order. Every day they are deferred is a day of stage-transition and lifecycle history that cannot be recovered later at any price.

### 7.4 dbt project — intermediate

| ID | Deliverable | Notes |
|---|---|---|
| D-14 | `int_fx_rates_densified` — full date spine, LOCF, synthesised identity pair | [P1] DR-2.2 — build and test this **before** any revenue model |
| D-15 | `int_account_bridge` — normalisation ruleset, confidence tier, exception flag | [P1] DR-1.1–1.3 |
| D-16 | `int_opportunity_order_bridge` — including orphan and deleted-in-CRM classification | [P1] DR-1.4 |
| D-17 | `int_order_posting_bridge` — order ↔ posting, ADJ handled as unattributable by design | [P1] |
| D-18 | `int_revenue_bridge` — the FR-1.2 waterfall, one row per category per entity-period | [P1] Flagship |
| D-19 | `int_shipment_matured` — maturation logic for OTD | [P1] DR-3.6 |

### 7.5 dbt project — marts

| ID | Deliverable | Notes |
|---|---|---|
| D-20 | Conformed dimensions: `dim_date`, `dim_customer`, `dim_product`, `dim_sales_rep`, `dim_campaign`, `dim_company`, `dim_gl_account`, `dim_carrier`, `dim_warehouse`, `dim_currency` | [P1] |
| D-21 | `dim_cost_center` — **SCD Type 2**, effective-dated join on `posting_date` | [P1] DR-5.1 |
| D-22 | Facts: `fct_bookings` (order-line grain), `fct_billed_revenue` (posting grain), `fct_revenue_bridge`, `fct_pipeline_snapshot`, `fct_shipment`, `fct_support_case`, `fct_quota_attainment` | [P1–P2] Incremental with restatement window per DR-3.3 |
| D-23 | Semantic/metric layer encoding all Appendix A definitions once | [P1] Prevents metric drift across dashboards |
| D-24 | `ref_discount_approval_policy` — effective-dated, RevOps-owned seed | [P2] Gates FR-4.2 (A-4) |
| D-25 | `feat_*_asof` point-in-time feature models with enforced leakage blocklist | [P3] DR-3.5 |
| D-26 | `fct_period_snapshot` — immutable as-reported freeze at close | [P2] DR-3.3 |

### 7.6 Quality, CI/CD, and operations

| ID | Deliverable | Notes |
|---|---|---|
| D-27 | Test suite: uniqueness, not-null, accepted-values, **within-system** referential tests only | [P0] Never assert an FK across a system boundary |
| D-28 | Custom tests: FX coverage (zero unmatched rate lookups), bridge residual ≤ 0.5%, string-id integrity, minor-unit rounding, anomaly-rate control limits | [P1] |
| D-29 | CI gate reading `analytics.metadata.table_versions` / `column_versions`; unregistered schema change fails the build | [P0] DR-7.2 |
| D-30 | Golden-dataset regression suite using the deterministic `--seed`/`--scale` generator | [P1] DR-7.3 |
| D-31 | Runbooks: weekly SLA-breach recovery, unmatched-account queue, FX gap, audit backfill, restatement/reopen | [P1] |
| D-32 | dbt exposures mapping every dashboard to its upstream models, with an impact report on every PR | [P1] |

---

## 8. Data Quality, Testing, and Release Strategy

**8.1 Test tiers**
1. **Contract tests** — schema and type conformance against the registry (D-29). Block merge.
2. **Structural tests** — keys, enums, not-null, within-system relationships (D-27). Block merge.
3. **Semantic tests** — bridge residual, FX coverage, minor-unit rounding, currency-basis consistency (D-28). Block deploy.
4. **Statistical monitors** — anomaly rates against control limits, volume and distribution drift (DR-6.3). Alert, do not block.
5. **Golden regression** — deterministic seed replay; any diff in a published metric requires explicit approval (D-30).

**8.2 Release process**
- Trunk-based with short-lived branches; PR triggers a slim CI build on a seeded dataset using `state:modified+` selection.
- Every PR renders an exposure impact report (D-32) naming which dashboards are affected and who owns them.
- Production deploys blue/green by schema swap; failed post-deploy semantic tests roll back automatically.
- Model and metric definition changes require the metric owner's approval; changing a definition without a version bump is a release blocker.

**8.3 What is deliberately *not* alerted on**
The weekly source-delivery SLA breach, the four budgeted anomaly rates at nominal levels, in-transit shipments, unresponded CSAT surveys, and ADJ postings with a NULL `order_ref`. **All are expected. Alerting on them trains people to ignore alerts.**

---

## 9. Revised Roadmap and Phase Gates

### 9.1 Phases

**Phase 0 — Foundation & Irreversibility (Months 1–2)**
Extraction, landing, staging, **snapshots (D-11–D-13)**, orchestration, CI contract gate.
*Gate: snapshots capturing daily; extraction replayable across a simulated two-day outage; contract gate blocking an unregistered schema change.*

**Phase 1 — Reconciliation & Descriptive (Months 3–5)**
FX densification, identity resolution, the bridge, conformed dimensions and core facts, executive and Finance dashboards.
*Gate: **Controller sign-off on FR-1.2** at ≤0.5% unexplained residual for three consecutive closed periods. This is the hardest gate in the programme and it is the one that earns the rest of the budget.*

**Phase 2 — Diagnostic (Months 6–7)**
Funnel leakage, discount and margin decomposition, churn attribution, changepoint detection with annotation, `ref_discount_approval_policy`, period-snapshot freeze.
*Gate: ≥80% variance attribution validated against a manual RevOps/FP&A panel.*

**Phase 3 — Predictive (Months 8–10)**
Point-in-time feature store, win-scoring (rep-inclusive and rep-blind), lapse risk, demand forecasting, lateness and freight models.
*Gate: all four models meet §1.3 thresholds on out-of-time holdouts; leakage blocklist enforced by automated test.*

**Phase 4 — Prescriptive (Months 10–11)**
NBA engine, policy-clipped deal guidance, escalation, CRM write-back integration, holdout control group, full rollout and enablement.
*Gate: 30-day pilot with a measured control group; alert precision and volume within agreed bounds.*

### 9.2 Critical path

```
Audit backfill (ops + erp) ──┐
                             ├──► Safe CDC ──► Staging ──┐
CRM /queryAll access ────────┘                           │
                                                         ├──► Bridge (FR-1.2) ──► Controller sign-off
FX densification (D-14) ─────────────────────────────────┤          │
Identity resolution (D-15) ──────────────────────────────┘          │
                                                                    ▼
Snapshots (D-11–D-13) ──► ~4 months of history ──► Funnel (FR-2.1) ──► PIT features ──► Models ──► NBA
```

**Two hard truths for the steering committee:**
1. **The Controller's sign-off on the bridge gates the entire predictive and prescriptive investment.** If Finance does not trust the descriptive layer, no amount of model accuracy will make them trust a recommendation built on it.
2. **The snapshots must start in month 1** even though they show nothing until month 5. History not captured is not recoverable.

### 9.3 Changes from the v1.0 timeline

| | v1.0 | v2.0 | Why |
|---|---|---|---|
| Total duration | 8 months | 11 months | Phase 0 added; Phase 1 extended from 2 to 3 months |
| First business value | Month 2 | Month 4 (partial), Month 5 (signed off) | Reconciliation cannot be short-cut and then retrofitted |
| Predictive start | Month 5 | Month 8 | Gated on ≥4 months of accumulated snapshot history |
| Integration effort | Implicit sub-task | Named critical path with its own gate | The estate has no cross-system referential integrity |

---

## 10. Operating Model & RACI

| Activity | Exec Sponsor | PMO | Analytics Eng | Data Platform | RevOps | Finance Sys | Sales Ops | IT Ops | Governance |
|---|---|---|---|---|---|---|---|---|---|
| Business case & funding | **A** | R | C | C | C | C | C | C | I |
| Source access & API budget | I | R | C | C | I | C | **A** | **A** | C |
| Extraction & orchestration | I | I | R | **A** | I | C | C | C | I |
| Identity resolution ruleset | I | I | **A/R** | C | C | C | C | C | C |
| Exception-queue stewardship | I | I | C | I | **A/R** | C | R | I | C |
| FX policy | I | I | C | I | I | **A/R** | I | I | C |
| Bridge definition & sign-off | I | R | R | I | C | **A** | C | I | C |
| Metric definitions | I | R | R | I | C | **A** | C | I | C |
| Model development & validation | I | I | **A/R** | C | C | C | C | I | C |
| CRM write-back | I | R | R | C | C | I | **A** | I | C |
| RBAC design & review | I | I | C | R | I | C | C | I | **A** |

**Cadence:** weekly delivery stand-up · biweekly steering committee · monthly metric-definition review board (Finance chairs) · quarterly access review.

---

## 11. Risk Register

| ID | Risk | L | I | Mitigation | Owner |
|---|---|---|---|---|---|
| **R-1** | FX densification missed or wrong; weekend/holiday orders and all USD rows silently drop from currency joins | High | **Critical** | D-14 built and tested before any revenue model; zero-unmatched-lookup test blocks deploy (D-28) | Analytics Eng |
| **R-2** | Audit backfill does not complete; `updated_at` CDC unsafe; NULL audit fields misread as deletions | Med | High | PK-range fallback budgeted in Phase 0; backfill run in bounded resumable batches; zero-null validation before migration `004` | Data Platform |
| **R-3** | Pre-2024 hand-keyed account numbers resist normalisation; unmatched revenue material | High | High | Confidence tiers make unmatched revenue visible rather than silent (DR-1.2); stewarded queue with SLA; matched-rate reported at every gate | RevOps |
| **R-4** | Finance rejects the bridge because they expected the exact tie v1.0 promised | Med | **Critical** | Expectation reset in this document (amendment A); Controller engaged from month 3, not month 5; residual target agreed in writing before build | PMO / Finance Sys |
| **R-5** | Executives ask for ARR/MRR anyway | High | Med | Amendment B communicated at approval; Recurring-Proxy Revenue offered as the honest substitute; OPEN-01 tracked visibly | Exec Sponsor |
| **R-6** | Win-scoring leaks target information and looks excellent in dev, fails in production | Med | High | Blocklist enforced by automated feature-lineage test (D-25); out-of-time holdout only; stage-probability baseline always reported alongside | Analytics Eng |
| **R-7** | Discount guidance recommends non-approvable discounts; sales loses trust in week one | Med | High | D-24 policy table is a hard prerequisite; shadow-mode test asserting zero ceiling breaches | RevOps |
| **R-8** | Alert fatigue from monitoring calibrated to zero anomalies | High | Med | DR-6.3 control-limit posture; per-recipient volume cap reviewed monthly | Analytics Eng |
| **R-9** | CRM API budget insufficient for daily incremental plus reconciliation sweeps | Med | High | A-1 confirmed with Sales Ops before Phase 0 exit; degraded-cadence contingency documented | Sales Ops |
| **R-10** | Late-arriving postings restate closed periods; executives see reported figures change | Med | High | DR-3.3 as-reported freeze plus as-restated view; restatement delta reported to Finance as a metric in its own right | Finance Sys |
| **R-11** | NBA lift claimed without a control group and later challenged | Med | Med | Randomised holdout mandated pre-rollout (FR-4.1); no lift claim accepted without it | PMO |
| **R-12** | Rep-level scores used punitively, distorting CRM data entry | Med | High | Rep-blind model is the management-facing artefact (FR-3.1); usage policy agreed with Sales leadership before rollout | Exec Sponsor |

---

## 12. Open Decisions

Each requires a named decision-maker. Unresolved items become risks at the next steering committee.

| ID | Decision | Owner | Needed by | Impact if unresolved |
|---|---|---|---|---|
| **OPEN-01** | Is a contracts/subscriptions source system in scope for FY-next? Without one, ARR/MRR/NRR-by-contract remain permanently unavailable | CRO + CFO | Phase 1 exit | Recurring-revenue narrative stays proxy-based indefinitely |
| **OPEN-02** | Definitive trailing-window length for logo churn, per segment | RevOps | Phase 2 start | FR-2.3 and FR-3.2 cannot be parameterised or back-tested |
| **OPEN-03** | Group-reporting FX policy: daily spot at `posting_date`, month-end close, or period average | CFO / Controller | Phase 1 month 1 | Cross-entity roll-ups cannot be certified; blocks D-14 |
| **OPEN-04** | Restatement window length and the definition of "period closed" for ERAE | Controller | Phase 1 month 2 | DR-3.3 cannot be implemented; blocks D-26 |
| **OPEN-05** | CRM write-back scope, API budget, and error-handling ownership | Sales Ops + VP Eng | Phase 3 start | FR-4.1 degrades to BI-only delivery |
| **OPEN-06** | Historical discount-approval ceilings — can RevOps reconstruct them to quarterly granularity? | RevOps | Phase 2 start | FR-4.2 descopes to advisory-only (A-4) |
| **OPEN-07** | Does Legal require entity-level data residency beyond region-level RBAC? | Governance + Legal | Phase 1 exit | Potential architecture rework late in the programme |
| **OPEN-08** | Extraction endpoint policy for soft-deleted CRM records (`/queryAll` confirmed?) | Sales Ops | Phase 0 month 1 | Orphan-reference rate becomes unmeasurable; blocks D-16 |
| **OPEN-09** | Bookings or billed revenue as the primary executive headline number | CRO + CFO | Phase 1 exit | Two competing headline numbers reach the board |
| **OPEN-10** | Rep-score usage policy — insight only, or an input to performance management? | CRO | Phase 3 start | R-12 materialises; CRM data quality degrades |

---

## Appendix A — Amended Metric Definitions

Source-faithful, with the amendment noted where v1.0 differed.

| Metric | Definition | Amendment note |
|---|---|---|
| **Bookings** | Sum of `line_amount` on non-cancelled orders, by `order_date`. The sales view. | — |
| **Billed revenue** | Sum of `amount_doc` on `erp.revenue_postings` by `posting_date`, net of credit notes. The Finance view. | **Will not equal bookings. The gap is informative and is the subject of FR-1.2.** |
| **Recurring-proxy revenue** | Revenue from `Support Plan` + `Software License` categories, recognition assumption stated on the tile | **New.** Substitute for ARR/MRR (amendment B) |
| **Gross margin** | `line_amount − (quantity × unit_cost_usd)`, once both sides are on the same currency basis | Currency-basis clause is a hard precondition, not a footnote |
| **ASP** | `line_amount / quantity` | Never averaged across currencies unconverted |
| **Realised discount** | `1 − (unit_price / list_price_usd)` on a common currency basis | Differs from `discount_pct`, which is the **approved** figure. The divergence is the margin-leakage metric |
| **Win rate** | Closed Won ÷ (Closed Won + Closed Lost), over a close-date window | Excludes open pipeline; long-open exceptions reported separately |
| **Sales cycle** | `CloseDate − CreatedDate` on closed opportunities | Survivorship-biased by construction; **not usable as a feature for open-deal scoring** (DR-3.5) |
| **Quota attainment** | Rep bookings ÷ pro-rated `quota_usd_annual` | Pro-rated on `hire_date`/`departure_date`; ramping reps flagged |
| **On-time delivery** | `delivered_date <= promised_delivery_date` over delivered shipments | **Matured cohorts only** (DR-3.6); reported against `published_otd_rate` |
| **Freight cost ratio** | `freight_cost_usd` ÷ order revenue, USD basis | Both sides USD |
| **Cost per kg / per km** | Freight efficiency by carrier, lane, service level | Carrier mix not constant across the window — always trend, never a single figure |
| **Logo churn** | Customers with no order in a trailing window who had one before it | Window parameterised (**OPEN-02**); censored at window edge |
| **Net revenue retention** | Cohort revenue this period ÷ same cohort last period | Cohort-based, not contract-based (amendment D) |
| **Time to resolution** | `resolution_hours` on resolved cases | **Median or p90, never mean** (NFR-6) |
| **CSAT** | `csat_score` 1–5 | **Always published with response rate**; unweighted average prohibited on exec views (DR-6.2) |
| **Campaign cost per opportunity** | `budget_usd` ÷ opportunities attributed to the campaign | Attribution path: campaigns → `CampaignId` → orders → revenue |

---

## Appendix B — Source-Quirk Glossary

The one-page briefing for anyone joining the project. Every item here has broken an analytics project somewhere.

| Quirk | Consequence |
|---|---|
| No FKs across CRM / ops / erp | Every cross-system join must be proved and monitored, never assumed |
| Pre-2024 account numbers hand-keyed | Identity resolution is fuzzy for the oldest, largest accounts |
| Soft-deleted CRM records | `/query` hides them; orders still reference their ids. Endpoint choice determines orphan rate |
| FX banking days only | Weekend and holiday orders find no rate |
| No `USD → USD` FX row | Every USD transaction drops out of an inner join |
| JPY has no minor unit | JPY amounts are whole numbers, numerically far larger; breaks naive outlier tests |
| Two currency bases per posting | `amount_doc` ≠ `amount_company` is correct, not a discrepancy |
| Salesforce ids are all-digit strings | Integer inference drops leading zeros and silently corrupts joins |
| Second-granularity `updated_at`, bulk-stamped | `>` watermarks skip rows; use `>=` with idempotent merge |
| Nullable audit columns pending backfill | NULL ≠ absent event ≠ deletion, until backfill validates |
| `erp.revenue_postings` append-only | Corrections are new CRN/ADJ rows; migration `005` rejects UPDATE/DELETE |
| `posted_at ≥ posting_date`, gap varies | Late-arriving facts restate closed periods |
| `CRN` reverses earlier periods | Closed-period net revenue is mutable by design |
| `ADJ` has NULL `order_ref` | Entity-level; traces to no order and never will |
| Cost-centre validity is a range | Effective-dated join required; retired centres keep their history |
| `is_active` / `is_discontinued` are current state | Cannot be used for historical filtering |
| `delivered_date` NULL = in transit | Excluding it without maturation logic biases OTD |
| `csat_score` NULL is non-random | Correlates with resolution time; unweighted CSAT is misleading |
| `Probability` is stage-implied | A baseline, not a feature |
| Discount approval ceiling has moved and is unrecorded | Historical models recommend non-approvable discounts |
| Rep differences are real, stable, and recorded nowhere | Rep is a powerful and hazardous feature |
| `assigned_region` ≠ customer region | Support-team reorg is visible only as a shift in the numbers |
| Anomaly budget is intentional | Zero-tolerance alerting guarantees alert fatigue |
| Weekly 1-day SLA breach | Recoverable by design; must not page |
| Generator is deterministic | Golden-dataset regression testing is available — use it |

---

## Appendix C — Change Log

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0 | — | PMO | Initial business case and BRD, authored before source-system access |
| **2.0** | 2026-08-10 | Principal PM | Rewritten against the Northwind source estate. ARR/MRR and contract-based churn removed as non-derivable. "100% reconciliation" replaced with a governed bridge and a residual tolerance. Foundational data requirements DR-1 through DR-7 added. Every functional requirement given source mapping and acceptance criteria. Deliverables register, testing strategy, RACI, risk register and open-decision log added. Timeline extended to 11 months with Phase 0 and a named critical path. |

---

*Sign-off below constitutes agreement with the amendments in §1.2, in particular the removal of ARR/MRR from scope and the replacement of exact reconciliation with a governed bridge at ≤0.5% unexplained residual.*

| Role | Name | Date | Signature |
|---|---|---|---|
| CRO | | | |
| CFO | | | |
| VP Engineering | | | |
| Head of Data Governance | | | |

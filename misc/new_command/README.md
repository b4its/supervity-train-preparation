# Dropbox Procurement Exception Commander

This prompt pack replaces the Supabase and Slack assumptions in `misc/call_command/` with the requested live integrations:

- Dropbox: immutable source-data repository and case-artifact store.
- Microsoft Outlook: disruption intake, approval notification, and stakeholder notification.
- Jira: durable incident record, execution queue, escalation record, and audit trail.
- Supervity Human Review: the mandatory human-in-command approval gate.

## Why This Design

The official Operations brief requires a channel, a system of record, a real exception routed to a person, multiple distinct operators, and an orchestrator that uses parallelism, branching, retry behavior, and escalation. This pack provides all of them without treating a local CSV as a live integration or pretending Dropbox is a relational database.

| Requirement | Implementation |
|---|---|
| Channel | Outlook receives exception emails and sends updates. |
| System of record | Dropbox holds the supplied enterprise export and generated case artifacts; Jira holds the live incident/work record. |
| Human loop | A native Supervity Human Review step pauses every high-risk case. Outlook delivers the review notification. |
| Distinct operators | Intake, data quality, impact, compliance, recovery planning, approval/execution, and closeout. |
| Parallel work | Impact and compliance run in parallel after data quality validation. |
| Business outcome | Jira and the final report record time-to-triage, time-to-decision, time-to-recovery, risk value, and estimated avoidable cost. |

## Required Dropbox Layout

Create this layout before building or running the Auto App. Do not rename the eight source CSV files.

```text
/Procurement-Exception-Commander/
  source/
    suppliers.csv
    contracts.csv
    purchase_order_headers.csv
    purchase_order_lines.csv
    order_confirmations.csv
    inventory_positions.csv
    demand_signals.csv
    disruption_notices.csv
  inbox/
    <new disruption export or manually uploaded notice file>
  cases/
    <created by workflow: CASE-DN-xxxx.json and CASE-DN-xxxx.md>
  reports/
    <created by workflow: daily or case summary reports>
  archive/
    <closed input files, never overwrite source files>
```

`source/` is read-only for the workflow. Generated content goes only into `cases/`, `reports/`, or `archive/`.

## Build Order

1. Complete the setup checklists under `integrations/`.
2. Create Operators `01` through `07` in order and test each one with a single disruption.
3. Create `08-procurement-exception-commander.md` only after the operators are saved with the requested names.
4. Configure the native Human Review step for the procurement commander or backup approver.
5. Run three evidence cases: safe/low, recoverable/medium, and contract/sole-source/high.

## Operator Names

| File | Saved operator name | Primary responsibility |
|---|---|---|
| `01-outlook-disruption-intake.md` | Outlook Disruption Intake | Read and deduplicate incoming exception notices. |
| `02-dropbox-data-quality-steward.md` | Dropbox Data Quality Steward | Validate, normalize, and preserve source data. |
| `03-impact-mapper.md` | Procurement Impact Mapper | Calculate operational and financial blast radius. |
| `04-contract-policy-guard.md` | Contract Policy Guard | Detect contract, supplier, and expedite restrictions. |
| `05-recovery-planner.md` | Recovery Options Planner | Propose evidence-backed recovery options only. |
| `06-human-approval-and-jira.md` | Human Approval and Jira Execution | Pause for native approval and create/update Jira. |
| `07-closeout-reporter.md` | Recovery Closeout Reporter | Notify, measure, and archive the completed case. |
| `08-procurement-exception-commander.md` | Procurement Exception Commander | Orchestrate the complete incident lifecycle. |

## Important Operating Rule

No operator may modify a purchase order, amend a supplier contract, email an external supplier, or claim a confirmed delivery date. The available integrations do not provide a procurement execution system. Instead, the workflow creates a traceable Jira action for a human procurement owner. This is safer, truthful, auditable, and aligned with Human-in-Command governance.

## Data Quality Rules

The hidden judging set can differ from the supplied synthetic data. Never hardcode record IDs, names, counts, or a specific supplier. The workflow must handle:

- Dates in ISO timestamp, `DD/MM/YYYY`, and `Mon DD YYYY` formats.
- Empty values, malformed rows, or unparseable dates.
- Extra whitespace and non-unique-looking supplier names. Join by `supplier_id`, never supplier name.
- Inconsistent lifecycle statuses (`issued`, `received`, `backordered`, `closed`, `soft_closed`, `confirmed`, `delayed`, `at_risk`).
- Missing order confirmations, contracts, inventory, or demand signals.
- Multiple contracts for a supplier and contract text containing commas.

If a required fact is missing, mark it `UNKNOWN`, explain the data gap, and route the case to Human Review. Do not invent a value.

## Evidence for Demo

For each run, show:

1. Outlook trigger or manual input.
2. Dropbox source read and generated case artifact.
3. Parallel Impact Mapper and Contract Policy Guard steps in the Auto Manager Console.
4. Jira incident creation with impact, options, and link to the Dropbox case artifact.
5. Native Supervity Human Review for a high-risk case.
6. Outlook completion notification and quantified metrics.

## Relevant Supervity Capabilities

This design follows the Supervity documentation:

- Operators plan and coordinate work; workflows execute deterministic steps.
- Independent work should run in parallel.
- Human Review pauses the workflow, preserves context, generates a review form, and resumes from the human decision.
- Integrations are governed tools with least-privilege permissions and audit logs.
- Runs and step-level outputs are observable, retryable, and auditable.

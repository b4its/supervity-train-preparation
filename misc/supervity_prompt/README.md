# Procurement Exception Commander — Supervity Prompt Pack V2

Automated procurement disruption triage, human review, and closeout on Supervity. Replaces Jira with Supabase `action_tasks` + Outlook email task assignment. No raw SQL in prompts — all Supabase access uses named integration actions (Query/Insert/Update row).

## Data Flow

```
INPUT (External sources the workflow READS from):
  ├── Outlook      ───  Incoming disruption emails
  ├── Supabase     ───  Reference tables (suppliers, contracts, PO, inventory, etc.)
  └── Dropbox      ───  Human-uploaded raw JSON and case artifacts

  ▼
SUPERVITY (Processing):
  8 Operators + 1 Rules Engine + 1 Orchestrator
  ▼

OUTPUT (External destinations the workflow WRITES to):
  ├── Dropbox      ───  cases/CASE-<key>/input/ (raw JSON), output/ (artifacts)
  ├── Supabase     ───  raw imports, clean records, predictions, incidents, tasks
  ├── Outlook      ───  Task assignment emails, escalation emails
  └── Slack        ───  Process audit notifications from every operator
```

All inputs come from external systems connected via Supervity integrations — not from Supervity itself.

## Architecture

```
01 Intake ─► Dropbox input/ ─► 02 Raw Import ─► 03 Clean + Predict ─► ┌─ 04 Compliance ┐
                                                                         └─ 05 History    ┘─► 06 Planner ─► 09 Rules ─┬─► 07 Approval ─► 08 Closeout
                                                                                                                        └─► (LOW → 08 Closeout)
```

### 8 Operators + 1 Rules Engine + 1 Orchestrator

The parent orchestrator invokes Saved Operators 01-08 through native Supervity subworkflow steps, passes the documented JSON input contract, and uses the returned output in the next step. Operator 09 is the inline Rules step; Operator 10 is the parent.

| # | Saved Name | File | Role | Input | Output |
|---|------------|------|------|-------|--------|
| 01 | Outlook Disruption Intake | `01-outlook-disruption-intake.md` | Create Dropbox-first case and input/output folders | Outlook/manual text | Dropbox case envelope, Supabase incident envelope |
| 02 | Dropbox Data Quality Steward | `02-dropbox-data-quality-steward.md` | Check/upload-import raw JSON unchanged | Dropbox `input/` | Supabase `raw_data_imports`, Dropbox import artifact |
| 03 | Procurement Impact Mapper | `03-procurement-impact-mapper.md` | Clean raw JSON and calculate assessment/prediction | Supabase raw layer + reference tables | Supabase clean layer + prediction, Dropbox clean/impact artifact |
| 04 | Contract Policy Guard | `04-contract-policy-guard.md` | Contract risk detection (VP, penalty, rebate, sole source) | Supabase (suppliers, contracts), Dropbox (case) | Dropbox (compliance artifact) |
| 05 | Supplier History Detector | `05-supplier-history-detector.md` | Chronic pattern in configurable lookback window | Supabase (disruption_notices), Dropbox (case) | (analysis only — no external write) |
| 06 | Recovery Options Planner | `06-recovery-options-planner.md` | Max 3 evidence-backed recovery options | Supabase (inventory, confirmations), Dropbox (all prior artifacts) | Dropbox (recovery options artifact) |
| 07 | Human Approval and Task Execution | `07-human-approval-and-task-execution.md` | Native Human Review form + Supabase action_tasks + Outlook assignment | Dropbox (case artifacts), Supabase (action_tasks) | Supabase (action_tasks), Outlook (task email) |
| 08 | Recovery Closeout Reporter | `08-recovery-closeout-reporter.md` | Metrics, report, notifications, archive | Dropbox (case), Supabase (action_tasks) | Dropbox (report), Supabase (status update), Outlook (email) |
| 09 | Procurement Exception Routing Policy | `09-procurement-exception-routing-policy.md` | **Rules** — decision table, LOW/MEDIUM/HIGH, 6 hard overrides | (from prior operators) | (route decision to orchestrator) |
| 10 | Procurement Exception Commander | `10-procurement-exception-commander.md` | **Orchestrator** — trigger, parallel branches, retry, partial failure | All | All |

## Key Design Decisions

| Aspect | Decision |
|--------|----------|
| **Supabase access** | Via integration actions (`Query table`, `Insert row`, `Update row`) — no raw SQL or credentials in prompts |
| **Human approval** | Native Supervity Human Review form (pause/resume) — Outlook and Slack notify, but Slack cannot approve |
| **Production data safety** | Never writes to PO, order, or inventory reference tables |
| **System of record** | Dropbox raw input + Supabase raw/clean/result layers + case state |
| **Dirty data** | Raw JSON is immutable; only clean layer is normalized; flags preserve uncertainty |
| **Chronic risk** | Dedicated operator 05 with configurable window (LOOKBACK_DAYS) and threshold (CHRONIC_THRESHOLD) |
| **Routing** | Rules engine (GoRules JDM) — deterministic, instant, configurable without editing prompts |
| **Unknown data** | Never invented — set `UNKNOWN` + flag for human review |

## Environment Variables

| Variable | Default | Used By |
|----------|---------|---------|
| OUTLOOK_INTAKE_FOLDER | — | 01, 10 |
| PROCUREMENT_TEAM_EMAIL | — | 07, 08 |
| PROCUREMENT_MANAGER_EMAIL | — | 07, 10 |
| HUMAN_REVIEW_TIMEOUT_HOURS | 24 | 07, 09 |
| DROPBOX_ROOT_PATH | Dropbox shared folder link (e.g. https://www.dropbox.com/sh/abc123/xyz) | All operators |
| LOOKBACK_DAYS | 90 | 05 |
| CHRONIC_THRESHOLD | 3 | 05 |
| PROCUREMENT_SLACK_CHANNEL | — | 01-08 |

## External Systems — Input vs Output

### Dropbox (Input + Output)

Shared folder link as root (`DROPBOX_ROOT_PATH`). Operator 01 creates one folder per case. Humans upload source JSON to `input/`; operators write artifacts to `output/`.

| Subfolder | Direction | Purpose |
|-----------|-----------|---------|
| `cases/CASE-<case_key>/input/` | INPUT | Human-uploaded raw `.json` documents; operators never modify them |
| `cases/CASE-<case_key>/output/` | OUTPUT | Intake, import, clean, impact, compliance, planner, and closeout artifacts |

### Supabase (Input + Output)

All 13 tables are created by `supabase-action-tasks.sql`:

| Group | Tables | Direction |
|-------|--------|-----------|
| **Reference** (8 tables) | `suppliers`, `contracts`, `purchase_order_headers`, `purchase_order_lines`, `order_confirmations`, `inventory_positions`, `demand_signals`, `disruption_notices` | **INPUT** (read-only) |
| **Project raw** | `raw_data_imports` | **OUTPUT** from Operator 02; untouched Dropbox JSON payloads |
| **Project clean** | `clean_procurement_records` | **OUTPUT** from Operator 03; normalized records plus flags |
| **Project result** | `procurement_predictions` | **OUTPUT** from Operator 03; evidence-backed result/prediction |
| **Project workflow** | `disruption_incidents`, `action_tasks` | **OUTPUT** for case state and human tasks |

See `supabase-action-tasks.sql` for full schema.

## Setup

See [setup.md](./setup.md) for step-by-step instructions.

# Procurement Exception Commander — Supervity Prompt Pack V2

Automated procurement disruption triage, human review, and closeout on Supervity. Replaces Jira with Supabase `action_tasks` + Outlook email task assignment. No raw SQL in prompts — all Supabase access uses named integration actions (Query/Insert/Update row).

## Data Flow

```
INPUT (External sources the workflow READS from):
  ├── Outlook      ───  Incoming disruption emails
  ├── Supabase     ───  Reference tables (suppliers, contracts, PO, inventory, etc.)
  └── Dropbox      ───  Existing case artifacts (dedup lookup)

  ▼
SUPERVITY (Processing):
  8 Operators + 1 Rules Engine + 1 Orchestrator
  ▼

OUTPUT (External destinations the workflow WRITES to):
  ├── Dropbox      ───  cases/ (artifacts), reports/ (closeout), archive/
  ├── Supabase     ───  disruption_incidents, action_tasks (new/updated rows)
  ├── Outlook      ───  Task assignment emails, escalation emails
  └── Slack        ───  Notification messages
```

All inputs come from external systems connected via Supervity integrations — not from Supervity itself.

## Architecture

```
Outlook ─► 01 Intake ─► 02 Data Quality ─► ┌─ 03 Impact        ┐
                                              ├─ 04 Compliance     ├─► 06 Planner ─► 09 Rules ─┬─► 07 Approval ─► 08 Closeout
                                              └─ 05 History       ┘                             └─► (LOW → 08 Closeout)
```

### 8 Operators + 1 Rules Engine + 1 Orchestrator

| # | Saved Name | File | Role | Input | Output |
|---|------------|------|------|-------|--------|
| 01 | Outlook Disruption Intake | `01-outlook-disruption-intake.md` | Parse email, dedup, create case | Outlook (email), Dropbox (dedup), Supabase (dedup) | Dropbox (case JSON), Supabase (disruption_incidents) |
| 02 | Dropbox Data Quality Steward | `02-dropbox-data-quality-steward.md` | Validate against 7 Supabase tables, set confidence | Dropbox (case JSON), Supabase (7 reference tables) | Dropbox (data quality artifact) |
| 03 | Procurement Impact Mapper | `03-procurement-impact-mapper.md` | Financial blast radius (line vs PO exposure) | Supabase (PO, inventory, demand), Dropbox (case) | Dropbox (impact artifact) |
| 04 | Contract Policy Guard | `04-contract-policy-guard.md` | Contract risk detection (VP, penalty, rebate, sole source) | Supabase (suppliers, contracts), Dropbox (case) | Dropbox (compliance artifact) |
| 05 | Supplier History Detector | `05-supplier-history-detector.md` | Chronic pattern in configurable lookback window | Supabase (disruption_notices), Dropbox (case) | (analysis only — no external write) |
| 06 | Recovery Options Planner | `06-recovery-options-planner.md` | Max 3 evidence-backed recovery options | Supabase (inventory, confirmations), Dropbox (all prior artifacts) | Dropbox (recovery options artifact) |
| 07 | Human Approval and Task Execution | `07-human-approval-and-task-execution.md` | Native Human Review form + Supabase action_tasks + Outlook assignment | Dropbox (case artifacts), Supabase (action_tasks) | Supabase (action_tasks), Outlook (task email), Slack (notification) |
| 08 | Recovery Closeout Reporter | `08-recovery-closeout-reporter.md` | Metrics, report, notifications, archive | Dropbox (case), Supabase (action_tasks) | Dropbox (report), Supabase (status update), Outlook (email), Slack (notification) |
| 09 | Procurement Exception Routing Policy | `09-procurement-exception-routing-policy.md` | **Rules** — decision table, LOW/MEDIUM/HIGH, 6 hard overrides | (from prior operators) | (route decision to orchestrator) |
| 10 | Procurement Exception Commander | `10-procurement-exception-commander.md` | **Orchestrator** — trigger, parallel branches, retry, partial failure | All | All |

## Key Design Decisions

| Aspect | Decision |
|--------|----------|
| **Supabase access** | Via integration actions (`Query table`, `Insert row`, `Update row`) — no raw SQL or credentials in prompts |
| **Human approval** | Native Supervity Human Review form (pause/resume) — Slack is notification-only |
| **Production data safety** | Never writes to PO, order, or inventory tables — only `disruption_incidents` + `action_tasks` |
| **System of record** | Dropbox (immutable artifacts) + Supabase (state machine + action_tasks) |
| **Dirty data** | Preserve raw text, set `UNKNOWN`, add flags, partial failure tolerance |
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
| PROCUREMENT_SLACK_CHANNEL | — | 07, 08 |
| LOOKBACK_DAYS | 90 | 05 |
| CHRONIC_THRESHOLD | 3 | 05 |

## External Systems — Input vs Output

### Dropbox (Input + Output)

Shared folder link as root (`DROPBOX_ROOT_PATH`). The workflow **reads** existing artifacts from `cases/` (dedup) and **writes** new artifacts to all subfolders.

| Subfolder | Direction | Purpose |
|-----------|-----------|---------|
| `cases/` | INPUT + OUTPUT | Read for dedup; write intake, data quality, impact, compliance, recovery options |
| `reports/` | OUTPUT only | Final closeout reports (RECOVERY-<case_key>.md) |
| `archive/` | OUTPUT only | Archived source artifacts after case is resolved |

### Supabase (Input + Output)

All 10 tables are created by `supabase-action-tasks.sql`:

| Group | Tables | Direction |
|-------|--------|-----------|
| **Reference** (8 tables) | `suppliers`, `contracts`, `purchase_order_headers`, `purchase_order_lines`, `order_confirmations`, `inventory_positions`, `demand_signals`, `disruption_notices` | **INPUT** (read-only) |
| **Project** (2 tables) | `disruption_incidents` (case status + metrics), `action_tasks` (task queue — replaces Jira) | **OUTPUT** (write new/updated rows) |

See `supabase-action-tasks.sql` for full schema.

## Setup

See [setup.md](./setup.md) for step-by-step instructions.

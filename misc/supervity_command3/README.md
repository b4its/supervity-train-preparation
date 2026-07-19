# Supervity Command 3

Command3 is a governed procurement-exception workflow built from Command2's proven Dropbox-first intake pattern. It adds LLM-assisted, evidence-grounded assessment, deterministic routing, human-owned tasks, and verified closeout without custom code or external model APIs.

## Focused Architecture

```text
01 Upload Gate -> 02 Raw Import -> 03 Clean -> 04 Impact Prediction
    -> 05 Compliance -> 06 History -> 07 Plan + Route
    -> 08 Human Decision + Task -> 09 Verified Closeout
    -> 10 Procurement Exception Commander 3
```

| # | Saved operator | Purpose |
|---|---|---|
| 01 | `Upload Verification Gate` | Upload request and Native Human Review only |
| 02 | `Raw Evidence Importer` | Dropbox copy and immutable raw database import only |
| 03 | `Procurement Data Cleaner` | Raw-to-clean transformation only |
| 04 | `Evidence-Grounded Impact Predictor` | LLM impact prediction from cleaned operational evidence only |
| 05 | `Contract Policy Guard` | Supplier/contract governance checks only |
| 06 | `Supplier History Detector` | Historical disruption pattern only |
| 07 | `Recovery Planner and Router` | LLM bounded options and deterministic routing only |
| 08 | `Human Decision and Task` | Native review and task record only |
| 09 | `Verified Closeout Reporter` | Completed-task verification and closeout only |
| 10 | `Procurement Exception Commander 3` | Popup-linked parent orchestration |

## What Is New Versus Command2

- Built-in Supervity LLM is isolated to impact prediction and recovery planning.
- Deterministic policy overrides the LLM for HIGH-risk governance decisions.
- Recovery options are limited, cited, and human-owned.
- MEDIUM/HIGH cases create one tracked `action_tasks` row.
- Approval is not closure. MEDIUM/HIGH closes only after a human marks its task `completed`.
- A case report, metrics, and incident resolution state are saved only after verified completion.

## LLM Guardrails

Command3 uses Supervity's built-in operator reasoning. Do not attach Gemini, OpenAI, external model endpoints, API keys, SDKs, Python, JavaScript, HTTP actions, or custom code.

The assessment LLM may only use evidence retrieved from the connected Supabase tables and imported Dropbox source. It must cite its evidence, mark unknown values `UNKNOWN`, preserve raw data unchanged, and never claim supplier capability, savings, external communication, or recovery completion without evidence.

## Native Integrations

| Integration | Use |
|---|---|
| Dropbox | intake files, immutable evidence copy, case artifacts |
| Supabase | source/reference evidence, raw/clean/assessment/task/closeout records |
| Slack | upload request, review link delivery, concise audit notifications |
| Microsoft Outlook | upload/review link delivery and human task assignment |
| Supervity Native Human Review | the sole approval/decision channel |

Slack and Outlook never approve a case; they only deliver the generated Native Human Review link.

## Immutable Raw File Storage

Every `.json` or `.csv` file found in Dropbox `incoming/` is copied unchanged to the case `input/` folder and stored as one `raw_data_imports` row before any clean/prediction operator runs. The raw row keeps the original full text in `raw_file_text`, parsed JSON or CSV wrapper in `raw_payload`, original/copy Dropbox paths, format, optional size/checksum, and source metadata. `clean_procurement_records` is the only layer allowed to normalize data.

## Database Setup

1. Run `00-command3-schema.sql`. It creates all 14 source, pipeline, assessment, and task tables from scratch, including RLS policies and grants.
2. Import the eight source CSV data tables from `operations/dataset/csv/` using `01-dataset-import.md`.

`00-command3-reset.sql` is for demos/tests only. It deletes all Command3 table data but keeps schema, policies, and grants. `00-command3-drop-all.sql` permanently deletes all 14 Command3 tables and the Command3 timestamp function; run it only before rebuilding the schema from scratch.

## Required Parent Inputs

Enter each only once in Operator 10:

```text
PROCUREMENT_SLACK_CHANNEL_ID
PROCUREMENT_TEAM_EMAIL
PROCUREMENT_MANAGER_EMAIL
DROPBOX_ROOT_PATH
raw_notice_text
received_at
trigger_type
```

`PROCUREMENT_SLACK_CHANNEL_ID` is shared by all operators that send audit or review-link notifications. The orchestrator maps it to each child; do not enter it separately for every child.

## Dropbox Layout

```text
<DROPBOX_ROOT_PATH>/incoming/                         Human-uploaded JSON/CSV
<DROPBOX_ROOT_PATH>/cases/CASE-<case_key>/input/      Immutable source copies
<DROPBOX_ROOT_PATH>/cases/CASE-<case_key>/output/     Manifest, assessment, task, closeout artifacts
```

## Build Order

Follow `setup.md`. Create/test/save Operators 01-09, then create Operator 10 and select each child through the Supervity popup. Do not paste child batch payloads manually.

## Test Data

See `test-data.md` and `input-guide.md`.

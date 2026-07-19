# Supervity Command 2 Setup

## Purpose

This package solves the Procurement Exception Commander scenario with the minimum permitted architecture:

- 2 Saved Operators
- 1 Orchestrator
- Dropbox, Supabase, Slack, Outlook, and Native Human Review
- Raw data preservation, cleaning, prediction, severity routing, and human governance

## 1. Database

For a new demo project:

1. Run `00-command2-schema.sql` in Supabase SQL Editor using the `service_role` key.
2. Follow `01-dataset-import.md` to import all eight CSVs from `operations/dataset/csv/`.
3. Run the verification count query from `01-dataset-import.md`.

For an existing Command2 demo database, run `00-command2-drop.sql` first, then repeat steps 1-3. Do not run the drop script in production.

## 2. Integrations

| Integration | Used By | Direction |
|---|---|---|
| Dropbox | Operators 01, 02 | Input raw JSON / output artifacts |
| Supabase | Operators 01, 02 | Read dataset / write case, raw, clean, result layers |
| Slack | Operators 01, 02 | Output audit notifications only |
| Microsoft Outlook | Operator 02 | Output human-review/task notification; optional trigger source |
| Native Human Review | Operators 01, 02 | Human upload acknowledgement and material-result approval |

Use the Supabase `service_role` key. Do not put Supabase credentials in prompts; connect them in Supervity Integrations.

## 3. Environment Variables

```text
DROPBOX_ROOT_PATH=https://www.dropbox.com/sh/<shared-folder-id>
PROCUREMENT_SLACK_CHANNEL=#procurement-alerts
PROCUREMENT_TEAM_EMAIL=procurement@company.com
PROCUREMENT_MANAGER_EMAIL=manager@company.com
```

## 4. Create Saved Operators

Create exactly these operators, using the exact names:

| Order | Name | Prompt |
|---|---|---|
| 01 | `Dropbox Raw JSON Ingestion` | `01-dropbox-raw-json-ingestion.md` |
| 02 | `Severity Data Cleaner` | `02-severity-data-cleaner.md` |
| 03 | `Supervity Command 2 Orchestrator` | `03-command2-orchestrator.md` |

Connect each integration listed in the prompt. In the orchestrator, use native **Run Operator / Subworkflow** steps and choose Operators 01 and 02 by name. Do not add HTTP calls to `/workflow-runs` and do not paste a run ID into a workflow step.

Do not configure Gemini or an external LLM API key. If the Supervity UI asks for one, remove the Gemini/custom-LLM integration and keep only the integrations named in the operator prompt.

## 5. Manual Test

1. Create `<DROPBOX_ROOT_PATH>/incoming/` if it does not already exist.
2. Upload the JSON from `test-data.md` to `incoming/` without creating or entering a case key.
3. Start Operator 03 with the manual input in `test-data.md`.
4. Operator 01 reads the uploaded file, generates the case key automatically, copies the unchanged evidence to `cases/CASE-<case_key>/input/`, and imports it to `raw_data_imports`.
5. Operator 02 writes normalized data to `clean_procurement_records` and assessment result to `procurement_predictions`.
6. Confirm Slack shows start, import, clean, severity assessment, and review/complete events.

## Success Criteria

- Original uploaded JSON remains unchanged in Dropbox `input/`.
- `raw_data_imports.raw_payload` equals the uploaded JSON.
- `clean_procurement_records.clean_payload` contains normalized values and flags.
- `procurement_predictions.prediction_payload` contains impact, contract, history, severity route, and recommendations.
- MEDIUM/HIGH routes pause for Native Human Review; Slack never approves.

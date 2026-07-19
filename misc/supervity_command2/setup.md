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
| Microsoft Outlook | Operators 01, 02 | Operator 01 sends upload-verification email; Operator 02 sends optional task notification |
| Native Human Review | Operators 01, 02 | Operator 01 approval verifies upload; Operator 02 approval governs material results |

Use the Supabase `service_role` key. Do not put Supabase credentials in prompts; connect them in Supervity Integrations.

Before a run, confirm this attachment checklist in the operator editor:

| Saved Operator | Required attached native connections |
|---|---|
| `Dropbox Source File Intake and Import` | Dropbox, Supabase, Slack, Microsoft Outlook, Native Human Review |
| `Severity Data Cleaner` | Dropbox, Supabase, Slack, Microsoft Outlook, Native Human Review |
| `Supervity Command 2 Orchestrator` | Native Run Operator/Subworkflow access to Operators 01 and 02 |

If Supabase is visible only in the workspace connection list but is not attached to the saved operator, the operator cannot query or write database tables. Attach the connected Supabase service in the operator editor and authorize it before testing.

## 3. Environment Variables

```text
DROPBOX_ROOT_PATH=https://www.dropbox.com/sh/<shared-folder-id>
PROCUREMENT_SLACK_CHANNEL_ID=C0123456789
PROCUREMENT_TEAM_EMAIL=procurement@company.com
PROCUREMENT_MANAGER_EMAIL=manager@company.com
```

## 4. Create Saved Operators

Create exactly these operators, using the exact names:

| Order | Name | Prompt |
|---|---|---|
| 01 | `Dropbox Source File Intake and Import` | `01-dropbox-raw-json-ingestion.md` |
| 02 | `Severity Data Cleaner` | `02-severity-data-cleaner.md` |
| 03 | `Supervity Command 2 Orchestrator` | `03-command2-orchestrator.md` |

Build Operators 01 and 02 first, test each independently, and save them before creating Operator 03. In the Operator 03 editor, type each `Call the sub-operator ...` instruction from `03-command2-orchestrator.md`. When Supervity opens its popup, select the matching saved operator. Supervity then creates the workflow connection and maps compatible input/output types automatically.

Do not type workflow names, IDs, run IDs, `{{...}}` expressions, manual JSON mappings, HTTP calls, or polling steps in the orchestrator. Do not attempt to connect children by API.

For each saved operator, attach the actual authenticated Dropbox, Supabase, and Slack connections in the Supervity UI before running it. The prompt does not contain, expose, or generate a Supabase URL, `service_role` key, Slack bot token, or API endpoint. Those credentials stay inside the connected Supervity service. Verify the connection status is connected/authorized and grant the Supabase connection access to the Command2 database before testing.

Do not configure Gemini or an external LLM API key. If the Supervity UI asks for one, remove the Gemini/custom-LLM integration and keep only the integrations named in the operator prompt.

Set `PROCUREMENT_SLACK_CHANNEL_ID` to the Slack conversation/channel ID, not its display name. For example, use `C0123456789`, not `procurement-alerts` or `#procurement-alerts`.

## 5. Manual Test

1. Create `<DROPBOX_ROOT_PATH>/incoming/` if it does not already exist.
2. Start Operator 03 once with the manual input in `test-data.md`.
3. Operator 01 sends the Slack upload request, creates Native Human Review, then sends Outlook verification with a `Verify Upload in Supervity` button that opens the review. The parent run pauses without ending.
4. Upload all JSON and/or CSV source files to `incoming/` without creating or entering case keys.
5. In the same Native Human Review form, choose `Approve - Files Uploaded` only after every file is fully uploaded. Choose `Reject - Files Not Uploaded` if any file is missing; do not start Operator 03 again.
6. Operator 01 resumes, reads every new supported source file, creates case folders, and imports all raw sources to `raw_data_imports`.
7. Operator 02 automatically receives the imported batch, writes cleaned records to `clean_procurement_records`, writes predictions to `procurement_predictions`, then posts the batch completion/audit Slack notification.

## Success Criteria

- Original uploaded JSON remains unchanged in Dropbox `input/`.
- `raw_data_imports.raw_payload` equals the uploaded JSON.
- `clean_procurement_records.clean_payload` contains normalized values and flags.
- `procurement_predictions.prediction_payload` contains impact, contract, history, severity route, and recommendations.
- MEDIUM/HIGH routes pause for Native Human Review; Slack never approves.

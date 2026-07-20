# Command3 Setup

## 1. Database

1. Run `00-command3-schema.sql` in Supabase SQL Editor. It is standalone and creates every Command3 table, trigger, index, RLS policy, grant, and sequence permission.
2. Import CSVs using `01-dataset-import.md`. Do not import `00_INDEX.csv` or `Field_Dictionary.csv` as source tables.
3. Verify all project tables exist: `disruption_incidents`, `raw_data_imports`, `clean_procurement_records`, `procurement_predictions`, `procurement_assessments`, and `action_tasks`.

## 2. Connections

Attach authenticated native connections to every saved operator that uses them:

- Dropbox
- Supabase (OAuth — do NOT use Custom URL+API key mode)
- Slack
- Microsoft Outlook
- Supervity Native Human Review

Make sure every operator's Supabase nodes use the OAuth-connected Supabase integration from the connection dropdown, not Custom/manual mode. Never expose Supabase URL/key, Slack token, or Outlook credentials in a prompt or input field.

## 3. Build Operators

Build in this strict order:

1. `01-upload-verification-gate.md`
2. `02-raw-evidence-importer.md`
3. `03-procurement-data-cleaner.md`
4. `04-impact-predictor.md`
5. `05-contract-policy-guard.md`
6. `06-supplier-history-detector.md`
7. `07-recovery-planner-and-router.md`
8. `08-human-decision-and-task.md`
9. `09-verified-closeout-reporter.md`
10. `10-command3-orchestrator.md`

For operators 01-09, native action palette nodes only. If a generated workflow contains Python, JavaScript, HTTP Request, `python-httpx`, `/rest/v1/`, or custom code, delete that node and regenerate using the prompt's allowed native action list.

Save with exact names:

```text
Upload Verification Gate
Raw Evidence Importer
Procurement Data Cleaner
Evidence-Grounded Impact Predictor
Contract Policy Guard
Supplier History Detector
Recovery Planner and Router
Human Decision and Task
Verified Closeout Reporter
Procurement Exception Commander 3
```

## 4. Link the Orchestrator

In Operator 10, add the nine `Call the sub-operator` instructions one by one. Use the Supervity popup to select the exact saved name.

- Map the parent consolidated inputs to Operator 01 once.
- Map every preceding operator output to its immediate successor.
- Reuse parent Slack/team/manager values for all relevant children.
- Reuse parent Slack/team/manager values; do not create duplicate user inputs.

If a child output payload appears as a user-required form field, save/test the upstream operator first, edit the child call, and select the upstream output in the popup. Do not paste JSON manually in normal orchestration.

## 5. End-to-End Test

1. Run Operator 10 once using `test-data.md`.
2. Upload test JSON/CSV to `/cases/incoming/` when Slack asks.
3. Open the Native Human Review link from Slack or Outlook and choose `Approve - Files Uploaded`.
4. Confirm Operator 01 returns nonzero `files_found` and `files_saved`.
5. Confirm Operators 03-07 write clean records, impact prediction, compliance/history evidence, and routed assessment.
6. For MEDIUM/HIGH, open the second Native Human Review and choose a decision.
7. Confirm Operator 08 writes one `action_tasks` row. Set its status to `completed` only after the human operational action actually finishes.
8. Resume/re-run the completion stage and confirm Operator 09 writes `RECOVERY-<case_key>.md` and incident status `resolved`.

## 6. Safety Checks

- No reference table is ever updated by operators.
- Raw Dropbox sources and `raw_data_imports.raw_file_text`, `raw_payload`, and `source_metadata` remain unchanged.
- `UNKNOWN` plus flags is correct when evidence is insufficient.
- Approval is not completion.
- Slack reports discovered, saved, assessed, task, and closure counts separately.

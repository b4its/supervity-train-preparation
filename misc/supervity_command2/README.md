# Supervity Command 2

Minimal Dropbox-first workflow with exactly **2 operators** and **1 orchestrator**. It addresses the procurement exception scenario: disruption intake, dirty source-data preservation, cleaning, PO/inventory/demand/contract/history assessment, severity routing, evidence-backed recommendation, and Native Human Review for material or uncertain outcomes.

## Files

| # | Saved Operator Name | Prompt File |
|---|---|---|
| 01 | `Dropbox Source File Intake and Import` | `01-dropbox-raw-json-ingestion.md` |
| 02 | `Severity Data Cleaner` | `02-severity-data-cleaner.md` |
| 03 | `Supervity Command 2 Orchestrator` | `03-command2-orchestrator.md` |

## Package Files

| File | Purpose |
|---|---|
| `00-command2-schema.sql` | Self-contained dataset-aligned Supabase schema |
| `00-command2-drop.sql` | Demo/test reset only |
| `01-dataset-import.md` | CSV import order and verification for `operations/dataset/csv/` |
| `02-supervity-connection-rls.sql` | RLS access for a native Supervity connection using `authenticated` |
| `03-command2-diagnostic.sql` | Diagnostic — run in Supabase to verify tables, RLS, grants, and live INSERTs |
| `04-command2-grant-current-role.sql` | Fix — grants ALL privileges + RLS policies for authenticated and current role when Supabase writes return `42501` |
| `input-guide.md` | Dummy inputs for Operators 01-03 and input-field reference |
| `test-data.md` | Manual run input and dirty JSON upload example |
| `setup.md` | End-to-end Supervity configuration |

## Required Integrations

| Operator | Integrations |
|---|---|
| 01 | Dropbox, Supabase, Slack, Native Human Review; Outlook is optional for email-triggered input |
| 02 | Dropbox, Supabase, Slack, Microsoft Outlook, Native Human Review |
| 03 | Popup-linked native sub-operator calls to Operators 01 and 02 |

The integrations must be authenticated and attached to each Saved Operator in the Supervity UI. Prompts intentionally do not include Supabase URLs, service-role keys, Slack tokens, or API endpoints. Operators must use the attached native connections, not SDKs or custom HTTP calls.

Create, test, and save Operators 01 and 02 before creating the orchestrator. In the orchestrator editor, select each sub-operator through Supervity's popup when prompted by the `Call the sub-operator ...` instructions. Do not manually reference workflow names/IDs or map child inputs and outputs yourself.

## Required Environment Variables

```text
DROPBOX_ROOT_PATH
PROCUREMENT_SLACK_CHANNEL_ID
PROCUREMENT_TEAM_EMAIL
PROCUREMENT_MANAGER_EMAIL
```

## Required Supabase Tables

Run `00-command2-schema.sql` before testing. The schema matches all CSV headers in `operations/dataset/csv/` and requires these project tables:

```text
disruption_incidents
raw_data_imports
clean_procurement_records
procurement_predictions
```

## Dropbox Flow

```text
<DROPBOX_ROOT_PATH>/incoming/                         # Human uploads JSON or CSV here
<DROPBOX_ROOT_PATH>/cases/CASE-<case_key>/input/      # Immutable copy of uploaded source
<DROPBOX_ROOT_PATH>/cases/CASE-<case_key>/output/
```

1. Operator 01 sends Slack upload instructions, creates the Native Human Review, then sends Outlook verification with a `Verify Upload in Supervity` button linked to that review before checking Dropbox.
2. Operator 01 waits in the same running workflow at Native Human Review. The user uploads all `.json` and/or `.csv` sources to `incoming/`, without entering case keys, then chooses `Approve - Files Uploaded`. Reject keeps the workflow waiting.
3. The same workflow resumes; Operator 01 reads every supported new source, generates case keys, creates case folders, and writes raw imports to `raw_data_imports`.
4. Operator 02 cleans every imported JSON document and CSV row into `clean_procurement_records`.
5. For material cases, Operator 02 creates a Native Human Review and sends Outlook with a `Review Decision in Supervity` button that opens the generated review link.
6. Operator 02 calculates severity, writes evidence-backed predictions to `procurement_predictions`, and sends `BATCH_PREDICTED_AND_AUDITED` to Slack.
7. Slack never confirms uploads or approves decisions. Outlook only delivers the native review links; Native Human Review is the confirmation/approval channel.

## Dummy Inputs

Read [`input-guide.md`](input-guide.md) before testing manually. It contains ready-to-paste dummy input for all three saved operators, the required Dropbox source JSON, and a field-by-field explanation of which values are entered by the user versus generated automatically.

## Slack Channel ID

Set `PROCUREMENT_SLACK_CHANNEL_ID` to the Slack channel/conversation ID, for example `C0123456789`. Do not use a display name such as `procurement-alerts` or `#procurement-alerts`.

## Dataset Coverage

Operator 02 evaluates the actual dataset relationships:

- Supplier tier, inactive status, and sole-source risk
- Contract expedite, escalation, and penalty terms
- Issued/backordered PO lines and PO-header exposure
- Confirmation delay/at-risk status
- Inventory safety/reorder position
- Forecast versus actual demand signal
- Prior disruption pattern for the same supplier

All source columns remain TEXT in Supabase; only the clean layer parses values when unambiguous. This preserves the intended dirty-data scenarios.

## No Gemini API Key

Command2 does not require Gemini or any external LLM API key. Use Supervity built-in reasoning plus the connected integrations. If Supervity asks for a Gemini key, remove any Gemini/custom-LLM integration from the saved operator and reconnect only the integrations listed in this README.

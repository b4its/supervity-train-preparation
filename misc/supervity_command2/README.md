# Supervity Command 2

Minimal Dropbox-first workflow with exactly **2 operators** and **1 orchestrator**. It addresses the procurement exception scenario: disruption intake, dirty source-data preservation, cleaning, PO/inventory/demand/contract/history assessment, severity routing, evidence-backed recommendation, and Native Human Review for material or uncertain outcomes.

## Files

| # | Saved Operator Name | Prompt File |
|---|---|---|
| 01 | `Dropbox Raw JSON Ingestion` | `01-dropbox-raw-json-ingestion.md` |
| 02 | `Severity Data Cleaner` | `02-severity-data-cleaner.md` |
| 03 | `Supervity Command 2 Orchestrator` | `03-command2-orchestrator.md` |

## Package Files

| File | Purpose |
|---|---|
| `00-command2-schema.sql` | Self-contained dataset-aligned Supabase schema |
| `00-command2-drop.sql` | Demo/test reset only |
| `01-dataset-import.md` | CSV import order and verification for `operations/dataset/csv/` |
| `input-guide.md` | Dummy inputs for Operators 01-03 and input-field reference |
| `test-data.md` | Manual run input and dirty JSON upload example |
| `setup.md` | End-to-end Supervity configuration |

## Required Integrations

| Operator | Integrations |
|---|---|
| 01 | Dropbox, Supabase, Slack, Native Human Review; Outlook is optional for email-triggered input |
| 02 | Dropbox, Supabase, Slack, Microsoft Outlook, Native Human Review |
| 03 | Native subworkflow calls to Operators 01 and 02 |

## Required Environment Variables

```text
DROPBOX_ROOT_PATH
PROCUREMENT_SLACK_CHANNEL
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
<DROPBOX_ROOT_PATH>/incoming/                         # Human uploads JSON here
<DROPBOX_ROOT_PATH>/cases/CASE-<case_key>/input/      # Immutable copy of uploaded JSON
<DROPBOX_ROOT_PATH>/cases/CASE-<case_key>/output/
```

1. Human uploads dirty `.json` source file(s) to `incoming/`, without entering a case key.
2. Operator 01 generates a case key from the uploaded JSON and creates the case folders.
3. Operator 01 copies the source unchanged to the case `input/` folder and into `raw_data_imports`.
4. Operator 02 writes normalized data to `clean_procurement_records`.
5. Operator 02 cleans data, calculates severity, and writes the evidence-backed result to `procurement_predictions`.
6. Both operators send Slack audit messages. Slack cannot approve anything.

## Dummy Inputs

Read [`input-guide.md`](input-guide.md) before testing manually. It contains ready-to-paste dummy input for all three saved operators, the required Dropbox source JSON, and a field-by-field explanation of which values are entered by the user versus generated automatically.

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

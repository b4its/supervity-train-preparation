# Command2 Input Guide

The normal workflow requires one manual submission only: start Operator 03 once, upload all source files when requested, and answer the pending Native Human Review form. Supervity resumes the same execution and automatically passes the imported batch from Operator 01 to Operator 02.

## Build Order In Supervity

1. Create, test, and save `Dropbox Source File Intake and Import`.
2. Create, test, and save `Severity Data Cleaner` using a real imported batch from Operator 01.
3. Create `Supervity Command 2 Orchestrator` only after both sub-operators are saved.
4. Type the `Call the sub-operator ...` instructions from the orchestrator prompt. Select each exact saved operator in the Supervity popup and allow automatic input/output mapping.
5. Do not enter workflow IDs, run IDs, `{{...}}` expressions, or manual JSON mappings.

## Operator 01: Dropbox Source File Intake and Import

For independent testing only, paste this input once:

```json
{
  "raw_notice_text": "NOTICE_ID: DEMO-5000\nSUPPLIER_ID: 3022\nITEM: SKU-EL-440\nTYPE: quality_hold",
  "received_at": "2026-07-19T10:30:00+08:00",
  "trigger_type": "manual"
}
```

Expected sequence: Slack upload request, Native Human Review creation, Outlook upload-verification email with a `Verify Upload in Supervity` button, upload all `.json`/`.csv` files to `DROPBOX_ROOT_PATH/incoming/`, click the button, then choose `Approve - Files Uploaded`. Approval resumes the import automatically; rejection means files are not yet ready and keeps the same run waiting. Do not rerun the operator after upload.

## Operator 02: Severity Data Cleaner

For independent testing, run Operator 01 first and use its actual `IMPORTED_BATCH` output. In normal Orchestrator use, do not type this input manually: Supervity maps the batch automatically.

The required automatically mapped shape is:

```json
{
  "status": "IMPORTED_BATCH",
  "cases": [
    {
      "case_key": "DEMO-5000",
      "notice": {},
      "dropbox_case_path": "cases/CASE-DEMO-5000",
      "dropbox_input_path": "cases/CASE-DEMO-5000/input",
      "dropbox_output_path": "cases/CASE-DEMO-5000/output",
      "raw_import_ids": [1]
    }
  ]
}
```

Never invent `raw_import_ids`; use the real IDs returned by Operator 01.

## Operator 03: Supervity Command 2 Orchestrator

This is the recommended entry point. Paste once only:

```json
{
  "raw_notice_text": "NOTICE_ID: DEMO-5000\nRECEIVED: 2026-07-19 10:30\nSUPPLIER_ID: 3022\nITEM: SKU-EL-440\nTYPE: quality_hold\nMESSAGE: QA hold on inbound SKU-EL-440 pending inspection.",
  "received_at": "2026-07-19T10:30:00+08:00",
  "trigger_type": "manual"
}
```

Then follow the Slack and Outlook upload instructions, upload all source files to `incoming/`, and select `Approve - Files Uploaded` in the already-pending Native Human Review. The same workflow resumes automatically. If not all files are ready, select `Reject - Files Not Uploaded`; do not submit Operator 03 a second time.

## Field Reference

| Field | Value | Entered By |
|---|---|---|
| `raw_notice_text` | Optional notice context; may be empty when source files are complete | User/trigger |
| `received_at` | ISO 8601 timestamp or empty | User/trigger |
| `trigger_type` | `manual` for UI tests; `outlook` for Outlook trigger | User/trigger |
| `case_key` | Generated from each uploaded source | Operator 01 |
| `raw_import_ids` | Generated after all source files are imported | Operator 01 |
| `PROCUREMENT_SLACK_CHANNEL_ID` | Slack channel ID, e.g. `C0123456789`, never a channel name | Supervity configuration |

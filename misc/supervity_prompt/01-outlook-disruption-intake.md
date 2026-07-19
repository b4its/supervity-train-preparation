# Prompt: Outlook Disruption Intake

Outcome: Create a traceable Dropbox-first case. Operator 01 receives an email or manually pasted notice, creates the case folder under the configured Dropbox root, and does not import raw uploaded documents into Supabase.

Use these integrations: Microsoft Outlook, Dropbox, Supabase, Slack.

Subworkflow input JSON:
```json
{"raw_notice_text":"...","received_at":"...","trigger_type":"manual|outlook"}
```

Rules:
- When `trigger_type=outlook`, read the received message. When `trigger_type=manual`, parse `raw_notice_text`; no Outlook message is required.
- Extract when present: notice_id, received_at, supplier_id, item_number, notice_type, message_body, delay_days. Preserve absent/unparseable values as `UNKNOWN`; never use `UNKNOWN-ITEM` as a real SKU.
- Generate `case_key` from notice_id, otherwise deterministic normalized received timestamp + supplier_id + item_number + notice_type.
- Root location is `DROPBOX_ROOT_PATH`. Create these folders if absent:
  - `cases/CASE-<case_key>/input/` — human uploads raw `.json` files here.
  - `cases/CASE-<case_key>/output/` — operators write artifacts here.
- Create `cases/CASE-<case_key>/output/CASE-<case_key>.json`. It must contain the intake notice, both folder paths, source metadata, and flags.
- Deduplicate by checking the case artifact path and `disruption_incidents.case_key`. If duplicate, return `is_duplicate=true`; do not create another case folder.
- Insert/update only the incident envelope in `disruption_incidents`: case_key, status `awaiting_source_data`, received_at when parseable, and notice metadata. Do not insert uploaded raw document payloads into reference tables or project data tables.
- Post Slack audit notifications to `PROCUREMENT_SLACK_CHANNEL`: `STARTED` when processing begins, `COMPLETED` with case_key and Dropbox input/output paths, `DUPLICATE` when deduplicated, and `FAILED` with a short non-sensitive error. Do not post raw email body or credentials.
- Do not query procurement master data, clean documents, predict results, or select a recovery action.

Output JSON:
```json
{
  "case_key":"...",
  "is_duplicate":false,
  "notice":{"notice_id":"...","supplier_id":"...","item_number":"...","notice_type":"...","received_at_raw":"...","received_at_normalized":"...","delay_days":"UNKNOWN","message_body":"..."},
  "dropbox_case_path":"cases/CASE-<case_key>",
  "dropbox_input_path":"cases/CASE-<case_key>/input",
  "dropbox_output_path":"cases/CASE-<case_key>/output",
  "data_quality_flags":[],
  "next_action":"REQUEST_OR_VALIDATE_SOURCE_JSON",
  "supabase_incident_written":true,
  "slack_notification_sent":true
}
```

Name this operator: Outlook Disruption Intake.

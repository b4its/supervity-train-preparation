# Command3 Test Data

## Operator 10 Input

```json
{
  "PROCUREMENT_SLACK_CHANNEL_ID": "C0BJ9M57YAV",
  "PROCUREMENT_TEAM_EMAIL": "procurement-team@example.com",
  "PROCUREMENT_MANAGER_EMAIL": "procurement-manager@example.com",
  "DROPBOX_ROOT_PATH": "/cases",
  "raw_notice_text": "NOTICE_ID: DEMO-5000\nRECEIVED: 2026-07-19 10:30\nSUPPLIER_ID: 3022\nITEM: SKU-EL-440\nTYPE: quality_hold\nMESSAGE: QA hold pending inspection.",
  "received_at": "2026-07-19T10:30:00+08:00",
  "trigger_type": "manual"
}
```

## Upload To `/cases/incoming/`

`supplier-evidence.json`:

```json
{
  "notice_id": "DEMO-5000",
  "supplier_id": "3022 ",
  "item_number": " sku-el-440",
  "notice_type": "QUALITY HOLD",
  "received_at": "19/07/2026",
  "po_line_id": "90005-1",
  "line_total": "29,197.41",
  "on_hand_qty": "811 units",
  "safety_stock": "354",
  "comment": "QA hold pending inspection."
}
```

`additional-evidence.csv`:

```csv
notice_id,supplier_id,item_number,notice_type,received_at,po_line_id,line_total,on_hand_qty,safety_stock,comment
DEMO-5001,3022 ,SKU-EL-441,DELAYED DELIVERY,19/07/2026,90006-1,"12,500.00",120 units,250,Confirmation is delayed.
DEMO-5002,3022 ,SKU-EL-442,QUALITY HOLD,19/07/2026,90007-1,"8,100.00",75 units,100,Inspection pending.
```

## Test Input for Each Operator (Standalone Testing)

Paste the full JSON below as the workflow trigger payload when testing an operator standalone.

### Operator 03 — Procurement Data Cleaner

Source: Operator 02 `IMPORTED_BATCH` output (real, with import IDs 14-23).
Copy and paste this entire JSON as the trigger payload:

```json
{"status":"IMPORTED_BATCH","files_found":10,"files_saved":10,"cases":[{"case_key":"Field_Dictionary","dropbox_case_path":"/cases/CASE-Field_Dictionary","dropbox_input_path":"/cases/CASE-Field_Dictionary/input","dropbox_output_path":"/cases/CASE-Field_Dictionary/output","raw_import_ids":[14]},{"case_key":"00_INDEX","dropbox_case_path":"/cases/CASE-00_INDEX","dropbox_input_path":"/cases/CASE-00_INDEX/input","dropbox_output_path":"/cases/CASE-00_INDEX/output","raw_import_ids":[15]},{"case_key":"contracts","dropbox_case_path":"/cases/CASE-contracts","dropbox_input_path":"/cases/CASE-contracts/input","dropbox_output_path":"/cases/CASE-contracts/output","raw_import_ids":[16]},{"case_key":"demand_signals","dropbox_case_path":"/cases/CASE-demand_signals","dropbox_input_path":"/cases/CASE-demand_signals/input","dropbox_output_path":"/cases/CASE-demand_signals/output","raw_import_ids":[17]},{"case_key":"disruption_notices","dropbox_case_path":"/cases/CASE-disruption_notices","dropbox_input_path":"/cases/CASE-disruption_notices/input","dropbox_output_path":"/cases/CASE-disruption_notices/output","raw_import_ids":[18]},{"case_key":"inventory_positions","dropbox_case_path":"/cases/CASE-inventory_positions","dropbox_input_path":"/cases/CASE-inventory_positions/input","dropbox_output_path":"/cases/CASE-inventory_positions/output","raw_import_ids":[19]},{"case_key":"purchase_order_headers","dropbox_case_path":"/cases/CASE-purchase_order_headers","dropbox_input_path":"/cases/CASE-purchase_order_headers/input","dropbox_output_path":"/cases/CASE-purchase_order_headers/output","raw_import_ids":[20]},{"case_key":"purchase_order_lines","dropbox_case_path":"/cases/CASE-purchase_order_lines","dropbox_input_path":"/cases/CASE-purchase_order_lines/input","dropbox_output_path":"/cases/CASE-purchase_order_lines/output","raw_import_ids":[21]},{"case_key":"suppliers","dropbox_case_path":"/cases/CASE-suppliers","dropbox_input_path":"/cases/CASE-suppliers/input","dropbox_output_path":"/cases/CASE-suppliers/output","raw_import_ids":[22]},{"case_key":"order_confirmations","dropbox_case_path":"/cases/CASE-order_confirmations","dropbox_input_path":"/cases/CASE-order_confirmations/input","dropbox_output_path":"/cases/CASE-order_confirmations/output","raw_import_ids":[23]}],"flags":[]}
```

### Operator 04 — Evidence-Grounded Impact Predictor

Paste after Operator 03 runs. Mock payload with clean record IDs:

```json
{"status":"CLEANED_BATCH","cases":[{"case_key":"suppliers","raw_import_ids":[22],"clean_record_ids":[1],"dropbox_output_path":"/cases/CASE-suppliers/output","flags":[]},{"case_key":"contracts","raw_import_ids":[16],"clean_record_ids":[2],"dropbox_output_path":"/cases/CASE-contracts/output","flags":[]},{"case_key":"purchase_order_headers","raw_import_ids":[20],"clean_record_ids":[3],"dropbox_output_path":"/cases/CASE-purchase_order_headers/output","flags":[]},{"case_key":"purchase_order_lines","raw_import_ids":[21],"clean_record_ids":[4],"dropbox_output_path":"/cases/CASE-purchase_order_lines/output","flags":[]},{"case_key":"order_confirmations","raw_import_ids":[23],"clean_record_ids":[5],"dropbox_output_path":"/cases/CASE-order_confirmations/output","flags":[]},{"case_key":"inventory_positions","raw_import_ids":[19],"clean_record_ids":[6],"dropbox_output_path":"/cases/CASE-inventory_positions/output","flags":[]},{"case_key":"demand_signals","raw_import_ids":[17],"clean_record_ids":[7],"dropbox_output_path":"/cases/CASE-demand_signals/output","flags":[]},{"case_key":"disruption_notices","raw_import_ids":[18],"clean_record_ids":[8],"dropbox_output_path":"/cases/CASE-disruption_notices/output","flags":[]}]}
```

### Operator 05 — Contract Policy Guard

```json
{"status":"IMPACT_PREDICTED","cases":[{"case_key":"disruption_notices","prediction_id":1,"impact":{"direct_line_value_at_risk_myr":"UNKNOWN","confirmation_risk":"UNKNOWN","inventory_gap":"UNKNOWN","demand_pressure":"UNKNOWN"},"evidence_confidence":"LOW","dropbox_impact_path":"/cases/CASE-disruption_notices/output/IMPACT-disruption_notices.md","flags":["no_po_line_match"]},{"case_key":"suppliers","prediction_id":2,"impact":{"direct_line_value_at_risk_myr":"UNKNOWN","confirmation_risk":"UNKNOWN","inventory_gap":"UNKNOWN","demand_pressure":"UNKNOWN"},"evidence_confidence":"LOW","dropbox_impact_path":"/cases/CASE-suppliers/output/IMPACT-suppliers.md","flags":["reference_table_no_impact"]}]}
```

### Operator 06 — Supplier History Detector

```json
{"status":"COMPLIANCE_CHECKED","cases":[{"case_key":"disruption_notices","compliance":{"supplier_status":"UNKNOWN","sole_source":"UNKNOWN","published_contract_exists":"UNKNOWN","expedite_allowed":"UNKNOWN","vp_signoff_required":false,"penalty_risk":false},"flags":["supplier_id_not_found"],"dropbox_compliance_path":"/cases/CASE-disruption_notices/output/COMPLIANCE-disruption_notices.md"},{"case_key":"suppliers","compliance":{"supplier_status":"active","sole_source":"false","published_contract_exists":"true","expedite_allowed":"true","vp_signoff_required":false,"penalty_risk":false},"flags":[],"dropbox_compliance_path":"/cases/CASE-suppliers/output/COMPLIANCE-suppliers.md"}]}
```

### Operator 07 — Recovery Planner and Router

```json
{"status":"HISTORY_CHECKED","cases":[{"case_key":"disruption_notices","history":{"lookback_days":90,"valid_notice_count":1,"is_chronic_risk":false,"notice_types":["quality_hold"]},"flags":[],"dropbox_history_path":"/cases/CASE-disruption_notices/output/HISTORY-disruption_notices.md"},{"case_key":"suppliers","history":{"lookback_days":90,"valid_notice_count":1,"is_chronic_risk":false,"notice_types":["quality_hold"]},"flags":[],"dropbox_history_path":"/cases/CASE-suppliers/output/HISTORY-suppliers.md"}]}
```

### Operator 08 — Human Decision and Task

```json
{"status":"ROUTED_BATCH","cases":[{"case_key":"disruption_notices","assessment_id":1,"route":"HIGH","review_required":true,"reviewer_level":"COMMANDER","recommended_option_id":"OPTION-1","options":[{"id":"OPTION-1","label":"Monitor and request supplier reconfirmation","confidence":"MEDIUM","human_action_required":"Contact supplier for updated delivery commitment and QA status.","evidence_citations":["disruption_notices.notice_type=quality_hold","inventory_positions.on_hand_qty=811 units"]}],"dropbox_plan_path":"/cases/CASE-disruption_notices/output/PLAN-disruption_notices.md","flags":[]}]}
```

### Operator 09 — Verified Closeout Reporter

Paste after human approves via Native Review. Must include `task_status`:

```json
{"status":"TASK_CREATED","cases":[{"case_key":"disruption_notices","task_id":1,"task_status":"approved","review_status":"APPROVED"}]}
```

## Expected Results

- Operator 01 verifies upload; Operator 02 imports raw JSON/CSV unchanged and returns real raw import IDs.
- Operators 03-07 separately clean, predict impact, check compliance, detect history, and write the cited route/options.
- LOW/high-confidence monitoring cases can close without a task.
- MEDIUM/HIGH or uncertain cases create one Native Human Review and one `action_tasks` row.
- Only after a human updates the task to `completed` can Operator 09 resolve the incident and write a closeout report.

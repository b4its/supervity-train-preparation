# Command2 Test Data

## One Manual Orchestrator Input

Run Operator 03 once with this input. Do not provide a case key, file path, raw import ID, intake stage, or **Imported Batch Payload** — that payload is the output of Operator 01 and is automatically passed by the orchestrator's "Call the sub-operator" mapping.

```json
{
  "raw_notice_text": "NOTICE_ID: DEMO-5000\nRECEIVED: 2026-07-19 10:30\nSUPPLIER_ID: 3022\nITEM: SKU-EL-440\nTYPE: quality_hold\nMESSAGE: QA hold on inbound SKU-EL-440 pending inspection.",
  "received_at": "2026-07-19T10:30:00+08:00",
  "trigger_type": "manual"
}
```

Operator 01 sends Slack and Outlook instructions, then waits in the same run for the Native Human Review answer.

## Files To Upload During The Same Run

Upload one or more supported files to `<DROPBOX_ROOT_PATH>/incoming/`, then select `Approve - Files Uploaded` in the pending Native Human Review form. If any source is missing, select `Reject - Files Not Uploaded`; do not start the orchestrator again.

### `supplier-evidence.json`

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
  "comment": "QA hold pending inspection; source retained unchanged."
}
```

### `additional-evidence.csv`

```csv
notice_id,supplier_id,item_number,notice_type,received_at,po_line_id,line_total,on_hand_qty,safety_stock,comment
DEMO-5001,3022 ,SKU-EL-441,DELAYED DELIVERY,19/07/2026,90006-1,"12,500.00",120 units,250,Confirmation is delayed.
DEMO-5002,3022 ,SKU-EL-442,QUALITY HOLD,19/07/2026,90007-1,"8,100.00",75 units,100,Inspection pending.
```

Expected: Operator 01 imports all three source records/files without changing the raw source. Operator 02 writes one clean record for the JSON document and one clean record for each CSV row, writes predictions, and sends `BATCH_PREDICTED_AND_AUDITED` to Slack after database writes finish.

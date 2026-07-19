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

## Expected Results

- Operator 01 verifies upload; Operator 02 imports raw JSON/CSV unchanged and returns real raw import IDs.
- Operators 03-07 separately clean, predict impact, check compliance, detect history, and write the cited route/options.
- LOW/high-confidence monitoring cases can close without a task.
- MEDIUM/HIGH or uncertain cases create one Native Human Review and one `action_tasks` row.
- Only after a human updates the task to `completed` can Operator 09 resolve the incident and write a closeout report.

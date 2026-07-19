# Command2 Test Data

## Upload Before Running

Upload a file named `supplier-evidence.json` to `<DROPBOX_ROOT_PATH>/incoming/`. Do not provide a case key; Operator 01 derives it from `notice_id` in this file.

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

## Orchestrator Manual Input

```json
{
  "raw_notice_text": "NOTICE_ID: DEMO-5000\nRECEIVED: 2026-07-19 10:30\nSUPPLIER_ID: 3022\nITEM: SKU-EL-440\nTYPE: quality_hold\nMESSAGE: QA hold on inbound SKU-EL-440 pending inspection.",
  "received_at": "2026-07-19T10:30:00+08:00",
  "trigger_type": "manual"
}
```

Expected: the clean operator trims/normalizes values, retains all originals as `raw_*` fields, flags the conversions, checks the real dataset tables, and produces a route with an evidence-backed explanation.

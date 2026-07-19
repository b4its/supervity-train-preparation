# Command3 Input Guide

## Normal Entry Point: Operator 10

Run **Procurement Exception Commander 3** once with:

```json
{
  "PROCUREMENT_SLACK_CHANNEL_ID": "C0BJ9M57YAV",
  "PROCUREMENT_TEAM_EMAIL": "procurement-team@example.com",
  "PROCUREMENT_MANAGER_EMAIL": "procurement-manager@example.com",
  "DROPBOX_ROOT_PATH": "/cases",
  "raw_notice_text": "NOTICE_ID: DEMO-5000\nSUPPLIER_ID: 3022\nITEM: SKU-EL-440\nTYPE: quality_hold",
  "received_at": "2026-07-19T10:30:00+08:00",
  "trigger_type": "manual"
}
```

Do not enter case keys, raw import IDs, imported batch payloads, clean batches, impact/compliance/history/planning outputs, task IDs, or review URLs. Supervity generates/maps them between saved sub-operators.

## Independent Operator Tests

### Operator 01

Use the first five shared fields plus optional notice fields. Upload files to `<DROPBOX_ROOT_PATH>/incoming/`, then approve the generated Native Human Review.

### Operators 02-09

For independent testing, run all upstream focused operators and use the actual immediate predecessor output. Every ID must exist in Supabase. In normal Operator 10 use, every payload is auto-mapped.

## Consolidated Field Reference

| Field | Enter once in Operator 10 | Used by |
|---|---:|---|
| `PROCUREMENT_SLACK_CHANNEL_ID` | Yes | 01, 02, 03 |
| `PROCUREMENT_TEAM_EMAIL` | Yes | 01, 03 |
| `PROCUREMENT_MANAGER_EMAIL` | Yes | 03 |
| `DROPBOX_ROOT_PATH` | Yes | 01 |
| `raw_notice_text` | Yes | 01 fallback only |
| `received_at` | Yes | 01 fallback only |
| `trigger_type` | Yes | 01 |

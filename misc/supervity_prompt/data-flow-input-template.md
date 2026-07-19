# Dropbox-First Data Flow Template

Use this template for a manual end-to-end test. The source JSON is intentionally dirty and must be uploaded by a human to Dropbox, not pasted into Supabase.

## 1. Manual Input to Operator 10

```json
{
  "raw_notice_text": "NOTICE_ID: DEMO-EL-440-001\nRECEIVED: 2026-07-19 10:30\nSUPPLIER_ID: 3022\nITEM: SKU-EL-440\nTYPE: quality_hold\nMESSAGE: QA hold on inbound SKU-EL-440 pending inspection.",
  "received_at": "2026-07-19T10:30:00+08:00",
  "trigger_type": "manual"
}
```

Operator 01 creates:

```text
<DROPBOX_ROOT_PATH>/cases/CASE-DEMO-EL-440-001/input/
<DROPBOX_ROOT_PATH>/cases/CASE-DEMO-EL-440-001/output/
```

## 2. JSON File Uploaded by Human

When Operator 07 requests source data, upload one file such as `supplier-evidence.json` into the generated `input/` folder.

```json
{
  "supplier_id": "3022 ",
  "item_number": " sku-el-440",
  "notice_type": "QUALITY HOLD",
  "received_at": "19/07/2026",
  "po_line_id": "90005-1",
  "line_total": "29,197.41",
  "on_hand_qty": "811 units",
  "safety_stock": "354",
  "comment": "QA hold pending inspection; raw source retained exactly."
}
```

## 3. Operator 02 Input: Check Source

```json
{
  "case_key": "DEMO-EL-440-001",
  "notice": {"supplier_id":"3022","item_number":"SKU-EL-440","notice_type":"quality_hold"},
  "dropbox_case_path": "cases/CASE-DEMO-EL-440-001",
  "dropbox_input_path": "cases/CASE-DEMO-EL-440-001/input",
  "dropbox_output_path": "cases/CASE-DEMO-EL-440-001/output",
  "mode": "CHECK_SOURCE"
}
```

Expected before upload:

```json
{
  "source_data_status": "UPLOAD_REQUIRED",
  "raw_import_ids": [],
  "force_human_review": true
}
```

## 4. Operator 02 Input: Import Raw

After upload acknowledgement:

```json
{
  "case_key": "DEMO-EL-440-001",
  "notice": {"supplier_id":"3022","item_number":"SKU-EL-440","notice_type":"quality_hold"},
  "dropbox_case_path": "cases/CASE-DEMO-EL-440-001",
  "dropbox_input_path": "cases/CASE-DEMO-EL-440-001/input",
  "dropbox_output_path": "cases/CASE-DEMO-EL-440-001/output",
  "mode": "IMPORT_RAW"
}
```

Expected Supabase write:

```text
raw_data_imports.raw_payload = exact contents of supplier-evidence.json
```

## 5. Operator 03 Input: Clean and Predict

```json
{
  "case_key": "DEMO-EL-440-001",
  "notice": {"supplier_id":"3022","item_number":"SKU-EL-440","notice_type":"quality_hold"},
  "dropbox_case_path": "cases/CASE-DEMO-EL-440-001",
  "dropbox_output_path": "cases/CASE-DEMO-EL-440-001/output",
  "data_quality": {
    "source_data_status": "IMPORTED",
    "raw_import_ids": [101],
    "evidence_confidence": "HIGH"
  }
}
```

Expected Supabase writes:

```text
clean_procurement_records.clean_payload:
  supplier_id: "3022"
  item_number: "SKU-EL-440"
  notice_type: "quality_hold"
  line_total: 29197.41
  on_hand_qty: 811
  safety_stock: 354

clean_procurement_records.normalization_flags:
  ["TRIMMED_SUPPLIER_ID", "NORMALIZED_ITEM_CASE", "PARSED_NUMERIC_WITH_COMMA", "STRIPPED_UNIT_SUFFIX", "PARSED_DMY_DATE"]

procurement_predictions.prediction_payload:
  evidence-backed impact assessment and flags
```

## Final Rule

`input/` is immutable raw evidence. `raw_data_imports` is its exact Supabase copy. Only `clean_procurement_records` may be normalized. `procurement_predictions` holds the derived result.

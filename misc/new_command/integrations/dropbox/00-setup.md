# Dropbox Setup

## Outcome

Provide one live, controlled repository from which Supervity can read the supplied procurement data and to which it can write immutable case evidence.

## Complete Before Building

1. Connect Dropbox in `Settings -> Integrations` with the smallest available scope that permits listing, reading, uploading, moving, and creating folders inside one dedicated project folder.
2. Create `/Procurement-Exception-Commander/` and the exact layout in `../../README.md`.
3. Upload the eight CSV files from `operations/dataset/csv/` to `/Procurement-Exception-Commander/source/`.
4. Verify the integration can list and download all eight source files and can upload a test file to `cases/`.
5. Do not grant the workflow permission to alter or delete the `source/` directory.

## Data Contract

The source filenames are fixed inputs, but their rows are not. The workflow must discover content by column header, not position alone.

| File | Minimum columns used |
|---|---|
| `suppliers.csv` | id, status, x_tier, x_sole_source |
| `contracts.csv` | supplier_id, status, x_expedite_allowed, x_escalation_clause, x_penalty_terms |
| `purchase_order_headers.csv` | id, supplier_id, status, po_total, need_by_date |
| `purchase_order_lines.csv` | id, po_header_id, item_number, quantity, line_total, need_by_date, status |
| `order_confirmations.csv` | po_line_id, supplier_id, promised_date, confirmed_quantity, status, delay_reason |
| `inventory_positions.csv` | item_number, on_hand_qty, safety_stock, reorder_point |
| `demand_signals.csv` | signal_date, item_number, forecast_qty, actual_demand |
| `disruption_notices.csv` | notice_id, received_at, channel, supplier_id, item_number, notice_type, message_body |

## Generated Artifacts

For each case, upload:

- `cases/CASE-<case_key>.json`: structured evidence and operator outputs.
- `cases/CASE-<case_key>.md`: human-readable brief with evidence references.
- `reports/RECOVERY-<case_key>.md`: final closeout report.

Never overwrite an existing case artifact. If an artifact already exists, treat it as a duplicate/idempotency signal and update the matching Jira issue instead of creating a new incident.

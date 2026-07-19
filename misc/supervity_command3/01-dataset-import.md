# Command3 Dataset Import

Run `00-command3-schema.sql` first. In Supabase Table Editor, import each CSV from `operations/dataset/csv/` into the matching table with header row enabled.

| Order | CSV file | Table | Import mode |
|---:|---|---|---|
| 1 | `suppliers.csv` | `suppliers` | Upsert on `id` |
| 2 | `contracts.csv` | `contracts` | Upsert on `id` |
| 3 | `purchase_order_headers.csv` | `purchase_order_headers` | Upsert on `id` |
| 4 | `purchase_order_lines.csv` | `purchase_order_lines` | Upsert on `id` |
| 5 | `order_confirmations.csv` | `order_confirmations` | Upsert on `id` |
| 6 | `inventory_positions.csv` | `inventory_positions` | Upsert on `item_number` |
| 7 | `demand_signals.csv` | `demand_signals` | Append; leave generated `id` empty |
| 8 | `disruption_notices.csv` | `disruption_notices` | Upsert on `notice_id` |

Do not import `00_INDEX.csv` or `Field_Dictionary.csv` into Supabase. Keep them in Dropbox as documentation evidence only.

All imported fields are TEXT by design. Do not coerce dates, amounts, or quantities during import; Command3 records every safe normalization only in `clean_procurement_records`.

## Verification

Run this after import:

```sql
SELECT 'suppliers' AS table_name, COUNT(*) AS row_count FROM suppliers
UNION ALL SELECT 'contracts', COUNT(*) FROM contracts
UNION ALL SELECT 'purchase_order_headers', COUNT(*) FROM purchase_order_headers
UNION ALL SELECT 'purchase_order_lines', COUNT(*) FROM purchase_order_lines
UNION ALL SELECT 'order_confirmations', COUNT(*) FROM order_confirmations
UNION ALL SELECT 'inventory_positions', COUNT(*) FROM inventory_positions
UNION ALL SELECT 'demand_signals', COUNT(*) FROM demand_signals
UNION ALL SELECT 'disruption_notices', COUNT(*) FROM disruption_notices;
```

After an Operator 02 test import, verify the immutable raw-file layer with:

```sql
SELECT
    id,
    case_key,
    source_file_name,
    source_file_format,
    source_dropbox_path,
    source_copied_dropbox_path,
    length(raw_file_text) AS raw_file_characters,
    import_status
FROM raw_data_imports;
```

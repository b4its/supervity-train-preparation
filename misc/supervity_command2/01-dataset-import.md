# Command2 Dataset Import

`00-command2-schema.sql` matches every source column in `operations/dataset/csv/` exactly. Source values deliberately remain TEXT because the dataset contains mixed date formats, irregular whitespace, nullable fields, and numeric values stored as text.

## Import Order

Use Supabase Table Editor CSV import after running the schema. Import each source CSV into the table of the same name.

1. `suppliers.csv` → `suppliers`
2. `contracts.csv` → `contracts`
3. `purchase_order_headers.csv` → `purchase_order_headers`
4. `purchase_order_lines.csv` → `purchase_order_lines`
5. `order_confirmations.csv` → `order_confirmations`
6. `inventory_positions.csv` → `inventory_positions`
7. `demand_signals.csv` → `demand_signals`
8. `disruption_notices.csv` → `disruption_notices`

Do not import `00_INDEX.csv` or `Field_Dictionary.csv` as database tables. They document the dataset.

## Why Table Editor Import

Supabase SQL Editor cannot access files in this local repository. Table Editor CSV import uses the actual source files without transforming dates, numbers, `None`, whitespace, or mixed values. This preserves the intended dirty-data test conditions.

## Verification Queries

Run these after import:

```sql
SELECT 'suppliers' AS table_name, COUNT(*) FROM suppliers
UNION ALL SELECT 'contracts', COUNT(*) FROM contracts
UNION ALL SELECT 'purchase_order_headers', COUNT(*) FROM purchase_order_headers
UNION ALL SELECT 'purchase_order_lines', COUNT(*) FROM purchase_order_lines
UNION ALL SELECT 'order_confirmations', COUNT(*) FROM order_confirmations
UNION ALL SELECT 'inventory_positions', COUNT(*) FROM inventory_positions
UNION ALL SELECT 'demand_signals', COUNT(*) FROM demand_signals
UNION ALL SELECT 'disruption_notices', COUNT(*) FROM disruption_notices;
```

Expected counts: 50, 45, 80, 171, 130, 16, 140, 45.

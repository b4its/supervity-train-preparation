# Prompt: Supabase Data Loader

```text
Outcome: Verify CSV file uploads in batches, load them into Supabase reference tables once all are confirmed present, and report completion so downstream operators query structured data instead of parsing raw CSVs.

Use Dropbox and Supabase. CSVs may arrive in batches (e.g., 3 files at a time) due to upload limits. Verify each batch is present in Dropbox before loading. Once all 8 files are confirmed, parse and upsert every row into the matching Supabase table by primary key. Write a load report to /Procurement-Exception-Commander/reports/data-load-summary.json. Never modify, move, or overwrite files under source/.

Required source files and target tables:
1. suppliers.csv → suppliers table (PK: id)
2. contracts.csv → contracts table (PK: id)
3. purchase_order_headers.csv → purchase_order_headers table (PK: id)
4. purchase_order_lines.csv → purchase_order_lines table (PK: id)
5. order_confirmations.csv → order_confirmations table (PK: id)
6. inventory_positions.csv → inventory_positions table (PK: item_number)
7. demand_signals.csv → demand_signals table (PK: id, auto-generated SERIAL)
8. disruption_notices.csv → disruption_notices table (PK: notice_id)

Batch verification rules:
- Check which of the 8 CSV files exist in /Procurement-Exception-Commander/source/.
- Check up to 3 files per verification cycle. After each cycle, report which files are confirmed present and which are still missing.
- If files are missing, return load_status=WAITING_FOR_FILES, list the missing files, and stop. Do not load partial data.
- Re-run the operator after more files are uploaded. Each run re-checks all previously confirmed files plus any new uploads.
- Only proceed to loading when all 8 files are confirmed present.

Loading rules:
- Discover fields by exact CSV header names. Never infer a column by row position.
- Parse CSV using quoted-field support because contract text and message bodies contain commas.
- Normalize dates to ISO YYYY-MM-DD only when they match YYYY-MM-DD HH:MM:SS, DD/MM/YYYY, or Mon DD YYYY. Preserve the raw value when unsupported.
- Normalize boolean fields case-insensitively: true/false. Treat invalid values as NULL.
- Treat empty numeric fields as NULL. Treat empty text fields as empty string.
- Trim whitespace from text fields.
- For demand_signals, use INSERT (not UPSERT) because the id is auto-generated SERIAL; the table has no natural unique key.
- For all other tables, use UPSERT on the primary key so re-running the loader is idempotent.
- Process all 8 files in sequence. If one file fails, log the error, skip that table, and continue with the next file. Do not abort the entire load.
- After loading, run a verification query for each table and include row counts in the summary.

Return exactly:
{
  "load_status": "WAITING_FOR_FILES|COMPLETE|PARTIAL|FAILED",
  "files_confirmed":["suppliers.csv","..."],
  "files_missing":["demand_signals.csv","..."],
  "tables_loaded": [
    {"table":"suppliers","rows_read":0,"rows_upserted":0,"errors":[]},
    {"table":"contracts","rows_read":0,"rows_upserted":0,"errors":[]},
    {"table":"purchase_order_headers","rows_read":0,"rows_upserted":0,"errors":[]},
    {"table":"purchase_order_lines","rows_read":0,"rows_upserted":0,"errors":[]},
    {"table":"order_confirmations","rows_read":0,"rows_upserted":0,"errors":[]},
    {"table":"inventory_positions","rows_read":0,"rows_upserted":0,"errors":[]},
    {"table":"demand_signals","rows_read":0,"rows_upserted":0,"errors":[]},
    {"table":"disruption_notices","rows_read":0,"rows_upserted":0,"errors":[]}
  ],
  "load_id":"...",
  "dropbox_report_path":"..."
}

Name this operator: Supabase Data Loader.
Ask only for missing Dropbox or Supabase permissions. Present the plan and wait for explicit approval before saving or running.
```

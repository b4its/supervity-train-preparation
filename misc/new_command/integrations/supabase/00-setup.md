# Supabase Setup

## Role in This Workflow

Supabase serves two roles alongside Dropbox, Jira, Outlook, and Slack:

1. **Structured query layer** — reference tables (suppliers, contracts, POs, inventory, order confirmations, demand signals, disruption notices) are populated from the CSV dataset. Operators query Supabase for fast structured lookups and cross-reference against Dropbox CSV evidence.

2. **Case state machine** — the `disruption_incidents` table tracks each case lifecycle: `intaken → data_quality → assessing → scoring → planning → awaiting_approval → notifying → resolved`. Any step may transition to `failed` or `escalated`.

## When to Set Up

Complete these steps after Dropbox, Jira, and Outlook are connected in Supervity Settings → Integrations but before building the operators.

## Steps

### 1. Connect Supabase in Supervity

1. Go to **Settings → Integrations**.
2. Click **Add Integration** and select **Supabase**.
3. Enter your Supabase project URL and `service_role` key (for full table access; restrict to necessary tables in production).
4. Click **Connect** and verify the connection status shows green.

### 2. Create All Tables

Open `integrations/supabase/schema.sql` (in this directory) and copy-paste the entire content into your Supabase SQL Editor, then click **Run**. This creates all reference tables matching the CSV dataset plus the operational case-state table.

The SQL file avoids markdown formatting issues — just open it and copy the plain SQL.

### 3. Import CSV Data into Reference Tables

Import the eight CSV files from the dataset into tables 1-8 using the Supabase Dashboard → Table Editor → Import, or via `psql`:

```bash
\copy suppliers FROM 'operations/dataset/csv/suppliers.csv' WITH CSV HEADER NULL '';
\copy contracts FROM 'operations/dataset/csv/contracts.csv' WITH CSV HEADER NULL '';
\copy purchase_order_headers FROM 'operations/dataset/csv/purchase_order_headers.csv' WITH CSV HEADER NULL '';
\copy purchase_order_lines FROM 'operations/dataset/csv/purchase_order_lines.csv' WITH CSV HEADER NULL '';
\copy order_confirmations FROM 'operations/dataset/csv/order_confirmations.csv' WITH CSV HEADER NULL '';
\copy inventory_positions FROM 'operations/dataset/csv/inventory_positions.csv' WITH CSV HEADER NULL '';
\copy demand_signals FROM 'operations/dataset/csv/demand_signals.csv' WITH CSV HEADER NULL '';
\copy disruption_notices FROM 'operations/dataset/csv/disruption_notices.csv' WITH CSV HEADER NULL '';
```

### 4. Verify

Run these verification queries:

```sql
SELECT COUNT(*) AS total_suppliers FROM suppliers;
SELECT notice_type, COUNT(*) FROM disruption_notices GROUP BY notice_type;
SELECT COUNT(*) FROM disruption_incidents;
```

All counts should match the CSV row counts. `disruption_incidents` starts empty — it is populated by the workflow.

## Environment Variables

Set these in the Supervity workflow after connecting the integration:

| Variable | Example | Purpose |
|---|---|---|
| `SUPABASE_INCIDENTS_TABLE` | `disruption_incidents` | Case state table name (default shown) |

## Permissions

The connected Supabase role must have `SELECT`, `INSERT`, `UPDATE` on all reference tables and `disruption_incidents`. The workflow never `DELETE`s rows or alters schema.

## Relationship to Other Integrations

| Integration | Supabase role |
|---|---|
| Dropbox | Raw evidence archive — Supabase queries complement, not replace, Dropbox file reads |
| Jira | Work system — Supabase mirrors case state for queryability; Jira remains the authoritative human-action record |
| Outlook | Channel — Supabase does not handle email; notification logic stays in Outlook |
| Slack | Alerts — Supabase does not send notifications; Slack is the alert channel |

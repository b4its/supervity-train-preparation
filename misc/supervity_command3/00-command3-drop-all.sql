-- DANGER: Permanently deletes every Command3 table, its data, indexes,
-- triggers, RLS policies, and foreign-key dependents. This does not delete
-- any Dropbox files. Run only when rebuilding Command3 from scratch.
BEGIN;

DROP TABLE IF EXISTS action_tasks CASCADE;
DROP TABLE IF EXISTS procurement_assessments CASCADE;
DROP TABLE IF EXISTS procurement_predictions CASCADE;
DROP TABLE IF EXISTS clean_procurement_records CASCADE;
DROP TABLE IF EXISTS raw_data_imports CASCADE;
DROP TABLE IF EXISTS disruption_incidents CASCADE;

DROP TABLE IF EXISTS disruption_notices CASCADE;
DROP TABLE IF EXISTS demand_signals CASCADE;
DROP TABLE IF EXISTS inventory_positions CASCADE;
DROP TABLE IF EXISTS order_confirmations CASCADE;
DROP TABLE IF EXISTS purchase_order_lines CASCADE;
DROP TABLE IF EXISTS purchase_order_headers CASCADE;
DROP TABLE IF EXISTS contracts CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;

DROP FUNCTION IF EXISTS command3_update_updated_at() CASCADE;

COMMIT;

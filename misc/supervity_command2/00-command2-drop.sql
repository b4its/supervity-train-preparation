-- =============================================================
-- Supervity Command 2 — Demo/Test Reset
-- Drops all Command2 tables and helper function.
-- Use only for a demo/test project because this deletes data.
-- =============================================================

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
DROP FUNCTION IF EXISTS command2_update_updated_at();

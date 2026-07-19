-- =============================================================
-- Supervity Command 2 — Demo/Test Reset
-- Drops all Command2 tables and helper function.
-- Use only for a demo/test project because this deletes data.
-- =============================================================

TRUNCATE TABLE
    procurement_predictions,
    clean_procurement_records,
    raw_data_imports,
    disruption_incidents,
    disruption_notices,
    demand_signals,
    inventory_positions,
    order_confirmations,
    purchase_order_lines,
    purchase_order_headers,
    contracts,
    suppliers
RESTART IDENTITY CASCADE;
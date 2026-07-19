SELECT 'clean_procurement_records' AS nama_tabel, COUNT(*) AS total FROM clean_procurement_records
UNION ALL
SELECT 'procurement_predictions', COUNT(*) FROM procurement_predictions
UNION ALL
SELECT 'raw_data_imports', COUNT(*) FROM raw_data_imports
UNION ALL
SELECT 'disruption_incidents', COUNT(*) FROM disruption_incidents
UNION ALL
SELECT 'disruption_notices', COUNT(*) FROM disruption_notices
UNION ALL
SELECT 'demand_signals', COUNT(*) FROM demand_signals
UNION ALL
SELECT 'inventory_positions', COUNT(*) FROM inventory_positions
UNION ALL
SELECT 'order_confirmations', COUNT(*) FROM order_confirmations
UNION ALL
SELECT 'purchase_order_lines', COUNT(*) FROM purchase_order_lines
UNION ALL
SELECT 'purchase_order_headers', COUNT(*) FROM purchase_order_headers
UNION ALL
SELECT 'contracts', COUNT(*) FROM contracts
UNION ALL
SELECT 'suppliers', COUNT(*) FROM suppliers;
-- Demo/test reset only. It deletes all Command3 table data but keeps tables, policies, grants, and functions.
TRUNCATE TABLE
    action_tasks,
    procurement_assessments,
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

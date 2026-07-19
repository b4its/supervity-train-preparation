-- Run once after 00-command2-schema.sql for a Supervity native Supabase
-- connection that authenticates as the Supabase `authenticated` role.
-- Do not create anon write policies.

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON TABLE
    suppliers, contracts, purchase_order_headers, purchase_order_lines,
    order_confirmations, inventory_positions, demand_signals, disruption_notices
TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE
    disruption_incidents, raw_data_imports,
    clean_procurement_records, procurement_predictions
TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

DO $$
DECLARE tbl TEXT;
BEGIN
    FOR tbl IN SELECT unnest(ARRAY[
        'suppliers', 'contracts', 'purchase_order_headers',
        'purchase_order_lines', 'order_confirmations', 'inventory_positions',
        'demand_signals', 'disruption_notices'
    ])
    LOOP
        EXECUTE format(
            'DROP POLICY IF EXISTS command2_authenticated_read_%I ON %I;',
            tbl, tbl
        );
        EXECUTE format(
            'CREATE POLICY command2_authenticated_read_%I ON %I FOR SELECT TO authenticated USING (true);',
            tbl, tbl
        );
    END LOOP;

    FOR tbl IN SELECT unnest(ARRAY[
        'disruption_incidents', 'raw_data_imports',
        'clean_procurement_records', 'procurement_predictions'
    ])
    LOOP
        EXECUTE format(
            'DROP POLICY IF EXISTS command2_authenticated_workflow_%I ON %I;',
            tbl, tbl
        );
        EXECUTE format(
            'CREATE POLICY command2_authenticated_workflow_%I ON %I FOR ALL TO authenticated USING (true) WITH CHECK (true);',
            tbl, tbl
        );
    END LOOP;
END;
$$;

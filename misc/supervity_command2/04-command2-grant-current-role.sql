-- =============================================================
-- Supervity Command 2 — Fix: GRANT + POLICY for ALL common roles
-- 
-- Run ONCE in Supabase SQL Editor (use service_role).
-- Grants ALL on workflow tables and SELECT on source tables
-- to authenticated AND the current SQL Editor role.
-- =============================================================

DO $$
DECLARE
    session_role_name TEXT;
    target_roles TEXT[] := ARRAY['authenticated'];
    r TEXT;
    tbl TEXT;
BEGIN
    session_role_name := current_user;
    IF session_role_name != 'authenticated' THEN
        target_roles := target_roles || session_role_name;
    END IF;

    RAISE NOTICE 'Target roles: %', target_roles;

    FOREACH r IN ARRAY target_roles
    LOOP
        EXECUTE format('GRANT USAGE ON SCHEMA public TO %I', r);

        FOR tbl IN SELECT unnest(ARRAY[
            'suppliers', 'contracts', 'purchase_order_headers', 'purchase_order_lines',
            'order_confirmations', 'inventory_positions', 'demand_signals', 'disruption_notices'
        ])
        LOOP
            BEGIN
                EXECUTE format('GRANT SELECT ON %I TO %I', tbl, r);
            EXCEPTION WHEN OTHERS THEN END;
        END LOOP;

        FOR tbl IN SELECT unnest(ARRAY[
            'disruption_incidents', 'raw_data_imports',
            'clean_procurement_records', 'procurement_predictions'
        ])
        LOOP
            BEGIN
                EXECUTE format('GRANT ALL ON %I TO %I', tbl, r);
            EXCEPTION WHEN OTHERS THEN END;
        END LOOP;

        BEGIN
            EXECUTE format('GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO %I', r);
        EXCEPTION WHEN OTHERS THEN END;

        FOR tbl IN SELECT unnest(ARRAY[
            'suppliers', 'contracts', 'purchase_order_headers', 'purchase_order_lines',
            'order_confirmations', 'inventory_positions', 'demand_signals', 'disruption_notices',
            'disruption_incidents', 'raw_data_imports', 'clean_procurement_records', 'procurement_predictions'
        ])
        LOOP
            BEGIN
                EXECUTE format('DROP POLICY IF EXISTS command2_all_%I ON %I', r, tbl);
                IF tbl = ANY(ARRAY['suppliers','contracts','purchase_order_headers','purchase_order_lines',
                    'order_confirmations','inventory_positions','demand_signals','disruption_notices']) THEN
                    EXECUTE format('CREATE POLICY command2_all_%I ON %I FOR SELECT TO %I USING (true)', r, tbl, r);
                ELSE
                    EXECUTE format('CREATE POLICY command2_all_%I ON %I FOR ALL TO %I USING (true) WITH CHECK (true)', r, tbl, r);
                END IF;
            EXCEPTION WHEN OTHERS THEN END;
        END LOOP;
        RAISE NOTICE 'Role % — OK', r;
    END LOOP;

    RAISE NOTICE 'DONE. Now re-run 03-command2-diagnostic.sql to verify.';
END;
$$;

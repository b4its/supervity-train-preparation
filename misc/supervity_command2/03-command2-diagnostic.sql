-- =============================================================
-- Supervity Command 2 — Supabase Write Diagnostic
-- Run in Supabase SQL Editor (service_role key).
-- Reports the exact reason Supabase writes are failing.
-- =============================================================

DO $$
DECLARE
    tbl TEXT;
    rec RECORD;
    role_name TEXT;
    table_exists BOOLEAN;
    rls_enabled BOOLEAN;
    has_policy BOOLEAN;
    has_grant BOOLEAN;
    test_case_key TEXT := 'diagnostic_test_' || floor(random() * 999999)::TEXT;
    test_id BIGINT;
    error_msg TEXT;
BEGIN
    RAISE NOTICE '==========================================================';
    RAISE NOTICE 'COMMAND 2 DIAGNOSTIC — Checking every failure point';
    RAISE NOTICE '==========================================================';

    -- 1. CHECK: Do the tables exist?
    RAISE NOTICE '';
    RAISE NOTICE '--- STEP 1: Table existence ---';
    FOR tbl IN SELECT unnest(ARRAY[
        'suppliers', 'contracts', 'purchase_order_headers', 'purchase_order_lines',
        'order_confirmations', 'inventory_positions', 'demand_signals', 'disruption_notices',
        'disruption_incidents', 'raw_data_imports', 'clean_procurement_records', 'procurement_predictions'
    ])
    LOOP
        SELECT EXISTS (
            SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = tbl
        ) INTO table_exists;
        IF NOT table_exists THEN
            RAISE NOTICE 'MISSING TABLE: public.% — run 00-command2-schema.sql first', tbl;
        ELSE
            RAISE NOTICE 'TABLE OK: public.%', tbl;
        END IF;
    END LOOP;

    -- 2. CHECK: RLS enabled and policies exist
    RAISE NOTICE '';
    RAISE NOTICE '--- STEP 2: RLS & Policies ---';
    FOR tbl IN SELECT unnest(ARRAY[
        'suppliers', 'contracts', 'purchase_order_headers', 'purchase_order_lines',
        'order_confirmations', 'inventory_positions', 'demand_signals', 'disruption_notices',
        'disruption_incidents', 'raw_data_imports', 'clean_procurement_records', 'procurement_predictions'
    ])
    LOOP
        SELECT relrowsecurity FROM pg_class WHERE relname = tbl INTO rls_enabled;
        IF NOT rls_enabled THEN
            RAISE NOTICE 'RLS OFF: % — RLS not enabled on this table', tbl;
        ELSE
            -- Check for service_role policy
            SELECT EXISTS (
                SELECT FROM pg_policies
                WHERE tablename = tbl AND schemaname = 'public'
                AND (rolename = 'service_role' OR rolename = 'authenticated' OR rolename = 'public')
            ) INTO has_policy;
            IF NOT has_policy THEN
                RAISE NOTICE 'NO POLICY: % — table has RLS enabled but no policy for service_role/authenticated/public. ALL WRITES WILL FAIL.', tbl;
            ELSE
                RAISE NOTICE 'POLICY OK: % — has at least one matching policy', tbl;
            END IF;
        END IF;
    END LOOP;

    -- 3. CHECK: Table-level privileges for authenticated role
    RAISE NOTICE '';
    RAISE NOTICE '--- STEP 3: GRANT privileges for authenticated role ---';
    FOR role_name IN SELECT 'authenticated'::name
    LOOP
        FOR tbl IN SELECT unnest(ARRAY[
            'suppliers', 'contracts', 'purchase_order_headers', 'purchase_order_lines',
            'order_confirmations', 'inventory_positions', 'demand_signals', 'disruption_notices'
        ])
        LOOP
            SELECT EXISTS (
                SELECT FROM information_schema.table_privileges
                WHERE table_schema = 'public' AND table_name = tbl
                AND grantee = role_name AND privilege_type = 'SELECT'
            ) INTO has_grant;
            IF NOT has_grant THEN
                RAISE NOTICE 'MISSING GRANT: % — % has no SELECT grant on % — run 02-supervity-connection-rls.sql', tbl, role_name, tbl;
            END IF;
        END LOOP;
        FOR tbl IN SELECT unnest(ARRAY[
            'disruption_incidents', 'raw_data_imports', 'clean_procurement_records', 'procurement_predictions'
        ])
        LOOP
            SELECT EXISTS (
                SELECT FROM information_schema.table_privileges
                WHERE table_schema = 'public' AND table_name = tbl
                AND grantee = role_name AND privilege_type = 'INSERT'
            ) INTO has_grant;
            IF NOT has_grant THEN
                RAISE NOTICE 'MISSING GRANT: % — % has no INSERT grant on %', tbl, role_name, tbl;
            END IF;
        END LOOP;
    END LOOP;

    -- 4. CHECK: Sequence privileges
    RAISE NOTICE '';
    RAISE NOTICE '--- STEP 4: Sequence privileges ---';
    SELECT EXISTS (
        SELECT FROM information_schema.role_usage_grants
        WHERE object_type = 'SEQUENCE' AND grantee = 'authenticated' AND object_schema = 'public'
        LIMIT 1
    ) INTO has_grant;
    IF NOT has_grant THEN
        RAISE NOTICE 'MISSING SEQUENCE GRANT for authenticated — run 02-supervity-connection-rls.sql';
    ELSE
        RAISE NOTICE 'SEQUENCE GRANT OK';
    END IF;

    -- 5. LIVE TEST: Try inserting a row into disruption_incidents as the current role
    RAISE NOTICE '';
    RAISE NOTICE '--- STEP 5: Live INSERT test on disruption_incidents ---';
    BEGIN
        INSERT INTO disruption_incidents (
            case_key, status, received_at_raw, notice_payload,
            dropbox_case_path, dropbox_input_path, dropbox_output_path
        ) VALUES (
            test_case_key, 'diagnostic_test', '19/07/2026',
            '{"test": true}'::jsonb,
            'diagnostic/' || test_case_key,
            'diagnostic/' || test_case_key || '/input',
            'diagnostic/' || test_case_key || '/output'
        )
        RETURNING id INTO test_id;
        RAISE NOTICE 'INSERT SUCCESS: disruption_incidents id=%', test_id;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        RAISE NOTICE 'INSERT FAILED on disruption_incidents: %', error_msg;
        RAISE NOTICE 'ROOT CAUSE: %', error_msg;
    END;

    -- 6. LIVE TEST: Try inserting raw_data_imports (requires parent from step 5)
    RAISE NOTICE '';
    RAISE NOTICE '--- STEP 6: Live INSERT test on raw_data_imports ---';
    BEGIN
        INSERT INTO raw_data_imports (
            case_key, source_file_name, source_dropbox_path, raw_payload, import_status, import_flags
        ) VALUES (
            test_case_key, 'diagnostic_test.json', 'diagnostic/diagnostic_test.json',
            '{"test": true}'::jsonb, 'imported', '[]'::jsonb
        )
        RETURNING id INTO test_id;
        RAISE NOTICE 'INSERT SUCCESS: raw_data_imports id=%', test_id;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        RAISE NOTICE 'INSERT FAILED on raw_data_imports: %', error_msg;
    END;

    -- 7. Cleanup: remove test rows
    RAISE NOTICE '';
    RAISE NOTICE '--- STEP 7: Cleanup diagnostic rows ---';
    DELETE FROM disruption_incidents WHERE case_key = test_case_key;
    RAISE NOTICE 'CLEANUP OK: removed test case_key=%', test_case_key;

    RAISE NOTICE '';
    RAISE NOTICE '==========================================================';
    RAISE NOTICE 'DIAGNOSTIC COMPLETE';
    RAISE NOTICE 'If any step above shows FAILED or MISSING, follow the fix';
    RAISE NOTICE 'indicated in the message and re-run this diagnostic.';
    RAISE NOTICE '==========================================================';
END;
$$;

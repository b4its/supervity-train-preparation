-- =============================================================
-- Supervity Command 3 — Complete Standalone Supabase Schema
-- Run once in Supabase SQL Editor before importing the CSV dataset.
-- Source columns are TEXT to preserve dirty/mixed source values exactly.
-- =============================================================

CREATE OR REPLACE FUNCTION command3_update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Reference/source tables: import operations/dataset/csv into these tables.
CREATE TABLE IF NOT EXISTS suppliers (
    id TEXT PRIMARY KEY, supplier_number TEXT, name TEXT, status TEXT,
    primary_contact_email TEXT, country TEXT, x_tier TEXT, x_sole_source TEXT,
    created_at TEXT, updated_at TEXT
);
CREATE TABLE IF NOT EXISTS contracts (
    id TEXT PRIMARY KEY, contract_number TEXT, supplier_id TEXT, name TEXT,
    status TEXT, start_date TEXT, end_date TEXT, x_expedite_allowed TEXT,
    x_escalation_clause TEXT, x_penalty_terms TEXT, currency TEXT, created_at TEXT
);
CREATE TABLE IF NOT EXISTS purchase_order_headers (
    id TEXT PRIMARY KEY, po_number TEXT, supplier_id TEXT, status TEXT,
    po_total TEXT, currency TEXT, ship_to_location TEXT, need_by_date TEXT,
    created_at TEXT, updated_at TEXT
);
CREATE TABLE IF NOT EXISTS purchase_order_lines (
    id TEXT PRIMARY KEY, po_header_id TEXT, line_num TEXT, item_number TEXT,
    description TEXT, quantity TEXT, uom TEXT, unit_price TEXT, line_total TEXT,
    need_by_date TEXT, x_confirmed_date TEXT, status TEXT
);
CREATE TABLE IF NOT EXISTS order_confirmations (
    id TEXT PRIMARY KEY, po_line_id TEXT, supplier_id TEXT, promised_date TEXT,
    confirmed_quantity TEXT, status TEXT, delay_reason TEXT, created_at TEXT
);
CREATE TABLE IF NOT EXISTS inventory_positions (
    item_number TEXT PRIMARY KEY, description TEXT, location TEXT, on_hand_qty TEXT,
    safety_stock TEXT, reorder_point TEXT, unit_cost TEXT, uom TEXT
);
CREATE TABLE IF NOT EXISTS demand_signals (
    id BIGSERIAL PRIMARY KEY, signal_date TEXT, item_number TEXT,
    forecast_qty TEXT, actual_demand TEXT, channel TEXT
);
CREATE TABLE IF NOT EXISTS disruption_notices (
    notice_id TEXT PRIMARY KEY, received_at TEXT, channel TEXT, supplier_id TEXT,
    item_number TEXT, notice_type TEXT, message_body TEXT
);

-- Project evidence pipeline: raw source -> clean data -> prediction/assessment -> task/closeout.
CREATE TABLE IF NOT EXISTS disruption_incidents (
    id BIGSERIAL PRIMARY KEY,
    case_key TEXT UNIQUE NOT NULL,
    status TEXT NOT NULL DEFAULT 'awaiting_source_data',
    received_at_raw TEXT,
    received_at TIMESTAMPTZ,
    notice_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    dropbox_case_path TEXT,
    dropbox_input_path TEXT,
    dropbox_output_path TEXT,
    route TEXT,
    review_required BOOLEAN NOT NULL DEFAULT false,
    reviewer_level TEXT,
    direct_line_value_at_risk_myr NUMERIC,
    broader_po_value_exposure_myr NUMERIC,
    estimated_avoidable_cost_myr NUMERIC,
    triaged_at TIMESTAMPTZ,
    decision_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- Makes the standalone script safe to run after an earlier Command2-style table exists.
ALTER TABLE disruption_incidents
    ADD COLUMN IF NOT EXISTS received_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS route TEXT,
    ADD COLUMN IF NOT EXISTS review_required BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS reviewer_level TEXT,
    ADD COLUMN IF NOT EXISTS direct_line_value_at_risk_myr NUMERIC,
    ADD COLUMN IF NOT EXISTS broader_po_value_exposure_myr NUMERIC,
    ADD COLUMN IF NOT EXISTS estimated_avoidable_cost_myr NUMERIC,
    ADD COLUMN IF NOT EXISTS triaged_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS decision_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMPTZ;
CREATE TABLE IF NOT EXISTS raw_data_imports (
    id BIGSERIAL PRIMARY KEY,
    case_key TEXT NOT NULL REFERENCES disruption_incidents(case_key) ON DELETE CASCADE,
    source_file_name TEXT NOT NULL,
    source_dropbox_path TEXT NOT NULL,
    source_copied_dropbox_path TEXT,
    source_file_format TEXT,
    source_file_size_bytes BIGINT,
    source_content_sha256 TEXT,
    raw_file_text TEXT,
    raw_payload JSONB NOT NULL,
    source_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    import_status TEXT NOT NULL DEFAULT 'imported',
    import_flags JSONB NOT NULL DEFAULT '[]'::jsonb,
    imported_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (case_key, source_dropbox_path)
);
-- Adds/migrates raw-file evidence columns when upgrading from an earlier schema.
-- Supervity native Dropbox download may not return file content as text,
-- so raw_file_text and source_file_format are nullable.
ALTER TABLE raw_data_imports
    ADD COLUMN IF NOT EXISTS source_copied_dropbox_path TEXT,
    ADD COLUMN IF NOT EXISTS source_file_format TEXT,
    ADD COLUMN IF NOT EXISTS source_file_size_bytes BIGINT,
    ADD COLUMN IF NOT EXISTS source_content_sha256 TEXT,
    ADD COLUMN IF NOT EXISTS raw_file_text TEXT,
    ADD COLUMN IF NOT EXISTS source_metadata JSONB NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE raw_data_imports ALTER COLUMN raw_file_text DROP NOT NULL;
ALTER TABLE raw_data_imports ALTER COLUMN source_file_format DROP NOT NULL;
CREATE TABLE IF NOT EXISTS clean_procurement_records (
    id BIGSERIAL PRIMARY KEY,
    raw_import_id BIGINT NOT NULL REFERENCES raw_data_imports(id) ON DELETE CASCADE,
    case_key TEXT NOT NULL REFERENCES disruption_incidents(case_key) ON DELETE CASCADE,
    record_type TEXT NOT NULL,
    clean_payload JSONB NOT NULL,
    normalization_flags JSONB NOT NULL DEFAULT '[]'::jsonb,
    confidence TEXT NOT NULL DEFAULT 'LOW',
    cleaned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (raw_import_id, record_type)
);
CREATE TABLE IF NOT EXISTS procurement_predictions (
    id BIGSERIAL PRIMARY KEY,
    case_key TEXT NOT NULL REFERENCES disruption_incidents(case_key) ON DELETE CASCADE,
    clean_record_id BIGINT REFERENCES clean_procurement_records(id) ON DELETE SET NULL,
    prediction_type TEXT NOT NULL DEFAULT 'procurement_exception_assessment',
    prediction_payload JSONB NOT NULL,
    confidence TEXT NOT NULL DEFAULT 'LOW',
    result_dropbox_path TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS procurement_assessments (
    id BIGSERIAL PRIMARY KEY,
    case_key TEXT NOT NULL UNIQUE REFERENCES disruption_incidents(case_key) ON DELETE CASCADE,
    assessment_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    evidence_confidence TEXT NOT NULL DEFAULT 'LOW',
    route TEXT NOT NULL DEFAULT 'HIGH',
    review_required BOOLEAN NOT NULL DEFAULT false,
    reviewer_level TEXT NOT NULL DEFAULT 'NONE',
    assessment_dropbox_path TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS action_tasks (
    id BIGSERIAL PRIMARY KEY,
    case_key TEXT NOT NULL UNIQUE REFERENCES disruption_incidents(case_key) ON DELETE CASCADE,
    assessment_id BIGINT REFERENCES procurement_assessments(id) ON DELETE SET NULL,
    task_type TEXT NOT NULL DEFAULT 'procurement_recovery',
    summary TEXT NOT NULL,
    description TEXT NOT NULL,
    assignee TEXT,
    priority TEXT NOT NULL DEFAULT 'Medium',
    status TEXT NOT NULL DEFAULT 'pending',
    decision TEXT,
    reviewer TEXT,
    rationale TEXT,
    selected_option_id TEXT,
    review_url TEXT,
    decided_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_contracts_supplier ON contracts(supplier_id);
CREATE INDEX IF NOT EXISTS idx_poh_supplier ON purchase_order_headers(supplier_id);
CREATE INDEX IF NOT EXISTS idx_pol_item ON purchase_order_lines(item_number);
CREATE INDEX IF NOT EXISTS idx_pol_header ON purchase_order_lines(po_header_id);
CREATE INDEX IF NOT EXISTS idx_oc_line ON order_confirmations(po_line_id);
CREATE INDEX IF NOT EXISTS idx_dn_supplier ON disruption_notices(supplier_id);
CREATE INDEX IF NOT EXISTS idx_raw_case ON raw_data_imports(case_key);
CREATE INDEX IF NOT EXISTS idx_clean_case ON clean_procurement_records(case_key);
CREATE INDEX IF NOT EXISTS idx_prediction_case ON procurement_predictions(case_key);
CREATE INDEX IF NOT EXISTS idx_assessment_route ON procurement_assessments(route);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON action_tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_case ON action_tasks(case_key);

DROP TRIGGER IF EXISTS trg_command3_incident_updated ON disruption_incidents;
CREATE TRIGGER trg_command3_incident_updated BEFORE UPDATE ON disruption_incidents
FOR EACH ROW EXECUTE FUNCTION command3_update_updated_at();
DROP TRIGGER IF EXISTS trg_command3_raw_updated ON raw_data_imports;
CREATE TRIGGER trg_command3_raw_updated BEFORE UPDATE ON raw_data_imports
FOR EACH ROW EXECUTE FUNCTION command3_update_updated_at();
DROP TRIGGER IF EXISTS trg_command3_clean_updated ON clean_procurement_records;
CREATE TRIGGER trg_command3_clean_updated BEFORE UPDATE ON clean_procurement_records
FOR EACH ROW EXECUTE FUNCTION command3_update_updated_at();
DROP TRIGGER IF EXISTS trg_command3_prediction_updated ON procurement_predictions;
CREATE TRIGGER trg_command3_prediction_updated BEFORE UPDATE ON procurement_predictions
FOR EACH ROW EXECUTE FUNCTION command3_update_updated_at();
DROP TRIGGER IF EXISTS trg_command3_assessment_updated ON procurement_assessments;
CREATE TRIGGER trg_command3_assessment_updated BEFORE UPDATE ON procurement_assessments
FOR EACH ROW EXECUTE FUNCTION command3_update_updated_at();
DROP TRIGGER IF EXISTS trg_command3_task_updated ON action_tasks;
CREATE TRIGGER trg_command3_task_updated BEFORE UPDATE ON action_tasks
FOR EACH ROW EXECUTE FUNCTION command3_update_updated_at();

-- Native Supervity connection access. Reference tables are read-only; workflow tables are read/write.
GRANT USAGE ON SCHEMA public TO authenticated, service_role;
GRANT SELECT ON suppliers, contracts, purchase_order_headers, purchase_order_lines,
    order_confirmations, inventory_positions, demand_signals, disruption_notices
TO authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON disruption_incidents, raw_data_imports,
    clean_procurement_records, procurement_predictions, procurement_assessments, action_tasks
TO authenticated, service_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated, service_role;

ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_order_headers ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_order_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_confirmations ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE demand_signals ENABLE ROW LEVEL SECURITY;
ALTER TABLE disruption_notices ENABLE ROW LEVEL SECURITY;
ALTER TABLE disruption_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE raw_data_imports ENABLE ROW LEVEL SECURITY;
ALTER TABLE clean_procurement_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE procurement_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE procurement_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE action_tasks ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
    tbl TEXT;
    role_name TEXT;
BEGIN
    FOREACH role_name IN ARRAY ARRAY['authenticated', 'service_role']
    LOOP
        FOREACH tbl IN ARRAY ARRAY[
            'suppliers', 'contracts', 'purchase_order_headers', 'purchase_order_lines',
            'order_confirmations', 'inventory_positions', 'demand_signals', 'disruption_notices'
        ]
        LOOP
            EXECUTE format('DROP POLICY IF EXISTS command3_read_%I_%I ON %I', role_name, tbl, tbl);
            EXECUTE format('CREATE POLICY command3_read_%I_%I ON %I FOR SELECT TO %I USING (true)', role_name, tbl, tbl, role_name);
        END LOOP;
        FOREACH tbl IN ARRAY ARRAY[
            'disruption_incidents', 'raw_data_imports', 'clean_procurement_records',
            'procurement_predictions', 'procurement_assessments', 'action_tasks'
        ]
        LOOP
            EXECUTE format('DROP POLICY IF EXISTS command3_write_%I_%I ON %I', role_name, tbl, tbl);
            EXECUTE format('CREATE POLICY command3_write_%I_%I ON %I FOR ALL TO %I USING (true) WITH CHECK (true)', role_name, tbl, tbl, role_name);
        END LOOP;
    END LOOP;
END;
$$;

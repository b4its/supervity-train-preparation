-- =============================================================
-- Supervity Command 2 — Supabase Schema
-- Dataset-aligned procurement source tables + dirty-data pipeline.
-- All source fields are TEXT to preserve the operations/dataset
-- values exactly, including mixed dates and malformed values.
-- Run in Supabase SQL Editor using the service_role key.
-- =============================================================

CREATE OR REPLACE FUNCTION command2_update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================================
-- SOURCE TABLES: match every CSV header in operations/dataset/csv
-- =============================================================

CREATE TABLE IF NOT EXISTS suppliers (
    id TEXT PRIMARY KEY,
    supplier_number TEXT,
    name TEXT,
    status TEXT,
    primary_contact_email TEXT,
    country TEXT,
    x_tier TEXT,
    x_sole_source TEXT,
    created_at TEXT,
    updated_at TEXT
);

CREATE TABLE IF NOT EXISTS contracts (
    id TEXT PRIMARY KEY,
    contract_number TEXT,
    supplier_id TEXT,
    name TEXT,
    status TEXT,
    start_date TEXT,
    end_date TEXT,
    x_expedite_allowed TEXT,
    x_escalation_clause TEXT,
    x_penalty_terms TEXT,
    currency TEXT,
    created_at TEXT
);

CREATE TABLE IF NOT EXISTS purchase_order_headers (
    id TEXT PRIMARY KEY,
    po_number TEXT,
    supplier_id TEXT,
    status TEXT,
    po_total TEXT,
    currency TEXT,
    ship_to_location TEXT,
    need_by_date TEXT,
    created_at TEXT,
    updated_at TEXT
);

CREATE TABLE IF NOT EXISTS purchase_order_lines (
    id TEXT PRIMARY KEY,
    po_header_id TEXT,
    line_num TEXT,
    item_number TEXT,
    description TEXT,
    quantity TEXT,
    uom TEXT,
    unit_price TEXT,
    line_total TEXT,
    need_by_date TEXT,
    x_confirmed_date TEXT,
    status TEXT
);

CREATE TABLE IF NOT EXISTS order_confirmations (
    id TEXT PRIMARY KEY,
    po_line_id TEXT,
    supplier_id TEXT,
    promised_date TEXT,
    confirmed_quantity TEXT,
    status TEXT,
    delay_reason TEXT,
    created_at TEXT
);

CREATE TABLE IF NOT EXISTS inventory_positions (
    item_number TEXT PRIMARY KEY,
    description TEXT,
    location TEXT,
    on_hand_qty TEXT,
    safety_stock TEXT,
    reorder_point TEXT,
    unit_cost TEXT,
    uom TEXT
);

CREATE TABLE IF NOT EXISTS demand_signals (
    id BIGSERIAL PRIMARY KEY,
    signal_date TEXT,
    item_number TEXT,
    forecast_qty TEXT,
    actual_demand TEXT,
    channel TEXT
);

CREATE TABLE IF NOT EXISTS disruption_notices (
    notice_id TEXT PRIMARY KEY,
    received_at TEXT,
    channel TEXT,
    supplier_id TEXT,
    item_number TEXT,
    notice_type TEXT,
    message_body TEXT
);

-- =============================================================
-- PROJECT TABLES: Dropbox raw -> clean -> prediction/result
-- =============================================================

CREATE TABLE IF NOT EXISTS disruption_incidents (
    id BIGSERIAL PRIMARY KEY,
    case_key TEXT UNIQUE NOT NULL,
    status TEXT NOT NULL DEFAULT 'awaiting_source_data',
    received_at_raw TEXT,
    notice_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    dropbox_case_path TEXT,
    dropbox_input_path TEXT,
    dropbox_output_path TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw_data_imports (
    id BIGSERIAL PRIMARY KEY,
    case_key TEXT NOT NULL REFERENCES disruption_incidents(case_key) ON DELETE CASCADE,
    source_file_name TEXT NOT NULL,
    source_dropbox_path TEXT NOT NULL,
    raw_payload JSONB NOT NULL,
    import_status TEXT NOT NULL DEFAULT 'imported',
    import_flags JSONB NOT NULL DEFAULT '[]'::jsonb,
    imported_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (case_key, source_dropbox_path)
);

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

CREATE INDEX IF NOT EXISTS idx_contracts_supplier ON contracts(supplier_id);
CREATE INDEX IF NOT EXISTS idx_poh_supplier ON purchase_order_headers(supplier_id);
CREATE INDEX IF NOT EXISTS idx_pol_item ON purchase_order_lines(item_number);
CREATE INDEX IF NOT EXISTS idx_pol_header ON purchase_order_lines(po_header_id);
CREATE INDEX IF NOT EXISTS idx_oc_line ON order_confirmations(po_line_id);
CREATE INDEX IF NOT EXISTS idx_dn_supplier ON disruption_notices(supplier_id);
CREATE INDEX IF NOT EXISTS idx_raw_case ON raw_data_imports(case_key);
CREATE INDEX IF NOT EXISTS idx_clean_case ON clean_procurement_records(case_key);
CREATE INDEX IF NOT EXISTS idx_prediction_case ON procurement_predictions(case_key);

CREATE TRIGGER trg_command2_incident_updated
    BEFORE UPDATE ON disruption_incidents
    FOR EACH ROW EXECUTE FUNCTION command2_update_updated_at();
CREATE TRIGGER trg_command2_raw_updated
    BEFORE UPDATE ON raw_data_imports
    FOR EACH ROW EXECUTE FUNCTION command2_update_updated_at();
CREATE TRIGGER trg_command2_clean_updated
    BEFORE UPDATE ON clean_procurement_records
    FOR EACH ROW EXECUTE FUNCTION command2_update_updated_at();
CREATE TRIGGER trg_command2_prediction_updated
    BEFORE UPDATE ON procurement_predictions
    FOR EACH ROW EXECUTE FUNCTION command2_update_updated_at();

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

DO $$
DECLARE tbl TEXT;
BEGIN
    FOR tbl IN SELECT unnest(ARRAY[
        'suppliers', 'contracts', 'purchase_order_headers',
        'purchase_order_lines', 'order_confirmations', 'inventory_positions',
        'demand_signals', 'disruption_notices', 'disruption_incidents',
        'raw_data_imports', 'clean_procurement_records', 'procurement_predictions'
    ])
    LOOP
        EXECUTE format(
            'CREATE POLICY command2_service_role_%I ON %I FOR ALL TO service_role USING (true) WITH CHECK (true);',
            tbl, tbl
        );
    END LOOP;
END;
$$;

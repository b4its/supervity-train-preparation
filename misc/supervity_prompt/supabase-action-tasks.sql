-- =============================================================
-- Procurement Exception Commander — Supabase Schema
-- All 10 tables (8 reference + 2 project), indexes, triggers,
-- and RLS policies. Run in Supabase SQL Editor (service_role).
-- Safe to re-run — uses IF EXISTS everywhere.
-- =============================================================

-- -------------------------------------------------------------
-- Helper: auto-update updated_at on any row change
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================================
-- REFERENCE TABLES (Input — existing procurement master data)
-- =============================================================

-- -------------------------------------------------------------
-- 1. suppliers
-- Queried by: 02-DataQuality, 04-Compliance
-- Columns: id, status, x_tier, x_sole_source
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS suppliers (
    id              SERIAL PRIMARY KEY,
    name            TEXT,
    status          TEXT DEFAULT 'active',        -- active | inactive
    x_tier          TEXT,                          -- tier-1 | tier-2 | tier-3
    x_sole_source   BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_suppliers_status ON suppliers(status);

CREATE TRIGGER trg_suppliers_updated_at
    BEFORE UPDATE ON suppliers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- -------------------------------------------------------------
-- 2. contracts
-- Queried by: 02-DataQuality, 04-Compliance
-- Columns: supplier_id, status, x_expedite_allowed,
--          escalation_clause, penalty_terms
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS contracts (
    id                  SERIAL PRIMARY KEY,
    supplier_id         INTEGER NOT NULL REFERENCES suppliers(id),
    status              TEXT DEFAULT 'published',  -- published | expired
    x_expedite_allowed  TEXT,                      -- true | false | UNKNOWN
    escalation_clause   TEXT,
    penalty_terms       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_contracts_supplier ON contracts(supplier_id);
CREATE INDEX IF NOT EXISTS idx_contracts_status   ON contracts(status);

CREATE TRIGGER trg_contracts_updated_at
    BEFORE UPDATE ON contracts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- -------------------------------------------------------------
-- 3. purchase_order_headers
-- Queried by: 02-DataQuality, 03-Impact
-- Columns: supplier_id, status, total
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS purchase_order_headers (
    id              SERIAL PRIMARY KEY,
    supplier_id     INTEGER NOT NULL REFERENCES suppliers(id),
    status          TEXT,                          -- open | issued | closed | received
    total           NUMERIC,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_poh_supplier   ON purchase_order_headers(supplier_id);
CREATE INDEX IF NOT EXISTS idx_poh_status     ON purchase_order_headers(status);

CREATE TRIGGER trg_poh_updated_at
    BEFORE UPDATE ON purchase_order_headers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- -------------------------------------------------------------
-- 4. purchase_order_lines
-- Queried by: 02-DataQuality, 03-Impact
-- Columns: po_header_id, item_number, status, value
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS purchase_order_lines (
    id              SERIAL PRIMARY KEY,
    po_header_id    INTEGER NOT NULL REFERENCES purchase_order_headers(id),
    item_number     TEXT,
    status          TEXT,                          -- open | issued | closed | received
    value           NUMERIC,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pol_header   ON purchase_order_lines(po_header_id);
CREATE INDEX IF NOT EXISTS idx_pol_item     ON purchase_order_lines(item_number);
CREATE INDEX IF NOT EXISTS idx_pol_status   ON purchase_order_lines(status);

CREATE TRIGGER trg_pol_updated_at
    BEFORE UPDATE ON purchase_order_lines
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- -------------------------------------------------------------
-- 5. order_confirmations
-- Queried by: 02-DataQuality, 03-Impact
-- Columns: po_line_id, status (confirmed | delayed | at_risk)
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS order_confirmations (
    id              SERIAL PRIMARY KEY,
    po_line_id      INTEGER NOT NULL REFERENCES purchase_order_lines(id),
    status          TEXT,                          -- confirmed | delayed | at_risk
    delay_reason    TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_oc_po_line ON order_confirmations(po_line_id);
CREATE INDEX IF NOT EXISTS idx_oc_status  ON order_confirmations(status);

CREATE TRIGGER trg_oc_updated_at
    BEFORE UPDATE ON order_confirmations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- -------------------------------------------------------------
-- 6. inventory_positions
-- Queried by: 02-DataQuality, 03-Impact
-- Columns: item_number, on_hand_qty, safety_stock,
--          reorder_point, unit_cost
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS inventory_positions (
    id              SERIAL PRIMARY KEY,
    item_number     TEXT NOT NULL,
    on_hand_qty     NUMERIC,
    safety_stock    NUMERIC,
    reorder_point   NUMERIC,
    unit_cost       NUMERIC,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ip_item ON inventory_positions(item_number);

CREATE TRIGGER trg_ip_updated_at
    BEFORE UPDATE ON inventory_positions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- -------------------------------------------------------------
-- 7. demand_signals
-- Queried by: 02-DataQuality, 03-Impact
-- Columns: item_number, actual, forecast, period
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS demand_signals (
    id              SERIAL PRIMARY KEY,
    item_number     TEXT NOT NULL,
    actual          NUMERIC,
    forecast        NUMERIC,
    period          DATE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ds_item   ON demand_signals(item_number);
CREATE INDEX IF NOT EXISTS idx_ds_period ON demand_signals(period);

CREATE TRIGGER trg_ds_updated_at
    BEFORE UPDATE ON demand_signals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- -------------------------------------------------------------
-- 8. disruption_notices
-- Queried by: 05-History
-- Columns: supplier_id, received_at, notice_type
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS disruption_notices (
    id              SERIAL PRIMARY KEY,
    supplier_id     INTEGER NOT NULL REFERENCES suppliers(id),
    received_at     TIMESTAMPTZ,
    notice_type     TEXT,                          -- supplier_delay | demand_spike
                                                   -- | port_cutoff_miss | quality_hold
    notice_data     JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dn_supplier   ON disruption_notices(supplier_id);
CREATE INDEX IF NOT EXISTS idx_dn_received   ON disruption_notices(received_at);
CREATE INDEX IF NOT EXISTS idx_dn_type       ON disruption_notices(notice_type);

CREATE TRIGGER trg_dn_updated_at
    BEFORE UPDATE ON disruption_notices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================
-- PROJECT TABLES (Output — created for this workflow)
-- =============================================================

-- -------------------------------------------------------------
-- 9. disruption_incidents
-- Core case state machine.
-- Status flow: intaken → data_quality → assessing → scoring
--              → awaiting_approval → awaiting_execution → resolved
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS disruption_incidents (
    id                              SERIAL PRIMARY KEY,
    case_key                        TEXT UNIQUE NOT NULL,
    status                          TEXT NOT NULL DEFAULT 'intaken',
    received_at                     TIMESTAMPTZ,
    notice_data                     JSONB,
    -- Metrics (filled by Recovery Closeout Reporter)
    direct_line_value_at_risk_myr   NUMERIC,
    broader_po_value_exposure_myr   NUMERIC,
    estimated_avoidable_cost_myr    NUMERIC,
    time_to_triage_hours            NUMERIC,
    time_to_decision_hours          NUMERIC,
    time_to_recovery_hours          NUMERIC,
    resolved_at                     TIMESTAMPTZ,
    -- Metadata
    created_at                      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_di_case_key   ON disruption_incidents(case_key);
CREATE INDEX IF NOT EXISTS idx_di_status     ON disruption_incidents(status);
CREATE INDEX IF NOT EXISTS idx_di_received   ON disruption_incidents(received_at);

CREATE TRIGGER trg_di_updated_at
    BEFORE UPDATE ON disruption_incidents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- -------------------------------------------------------------
-- 10. action_tasks
-- Human-action task queue. Replaces Jira.
-- Status: pending → approved | rejected | expired | more_evidence
--         → completed
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS action_tasks (
    id                  SERIAL PRIMARY KEY,
    case_key            TEXT UNIQUE NOT NULL,
    task_type           TEXT NOT NULL DEFAULT 'procurement_action',
    summary             TEXT,
    description         TEXT,
    assignee            TEXT NOT NULL DEFAULT 'procurement_owner',
    priority            TEXT NOT NULL DEFAULT 'Medium',
    status              TEXT NOT NULL DEFAULT 'pending',
    decision            TEXT,
    reviewer            TEXT,
    rationale           TEXT,
    selected_option_id  TEXT,
    completed_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_at_case_key   ON action_tasks(case_key);
CREATE INDEX IF NOT EXISTS idx_at_status     ON action_tasks(status);
CREATE INDEX IF NOT EXISTS idx_at_assignee   ON action_tasks(assignee);

CREATE TRIGGER trg_at_updated_at
    BEFORE UPDATE ON action_tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================
-- RLS: enable on all tables for security hygiene
-- Prompts connect via service_role key → bypasses RLS.
-- Policies exist so future anon/authenticated keys have a base.
-- =============================================================
ALTER TABLE suppliers              ENABLE ROW LEVEL SECURITY;
ALTER TABLE contracts              ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_order_headers ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_order_lines   ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_confirmations    ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_positions    ENABLE ROW LEVEL SECURITY;
ALTER TABLE demand_signals         ENABLE ROW LEVEL SECURITY;
ALTER TABLE disruption_notices     ENABLE ROW LEVEL SECURITY;
ALTER TABLE disruption_incidents   ENABLE ROW LEVEL SECURITY;
ALTER TABLE action_tasks           ENABLE ROW LEVEL SECURITY;

-- Service role has full access on all tables
DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOR tbl IN
        SELECT unnest(ARRAY[
            'suppliers', 'contracts', 'purchase_order_headers',
            'purchase_order_lines', 'order_confirmations',
            'inventory_positions', 'demand_signals',
            'disruption_notices', 'disruption_incidents', 'action_tasks'
        ])
    LOOP
        EXECUTE format(
            'CREATE POLICY service_role_all_%I ON %I FOR ALL TO service_role USING (true) WITH CHECK (true);',
            tbl, tbl
        );
    END LOOP;
END;
$$;

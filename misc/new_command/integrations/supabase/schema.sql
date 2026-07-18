-- =====================================================
-- SUPABASE FULL SCHEMA
-- Procurement Exception Commander — Operations Track
-- Autopilot Asia Hackathon 2026
-- =====================================================

-- CLEANUP (reverse dependency order)
DROP TABLE IF EXISTS disruption_incidents CASCADE;
DROP TABLE IF EXISTS disruption_notices CASCADE;
DROP TABLE IF EXISTS demand_signals CASCADE;
DROP TABLE IF EXISTS inventory_positions CASCADE;
DROP TABLE IF EXISTS order_confirmations CASCADE;
DROP TABLE IF EXISTS purchase_order_lines CASCADE;
DROP TABLE IF EXISTS purchase_order_headers CASCADE;
DROP TABLE IF EXISTS contracts CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;

-- 1. SUPPLIERS
CREATE TABLE suppliers (
    id                  INT PRIMARY KEY,
    supplier_number     TEXT,
    name                TEXT,
    status              TEXT,
    primary_contact_email TEXT,
    country             TEXT,
    x_tier              TEXT,
    x_sole_source       BOOLEAN,
    created_at          TIMESTAMPTZ,
    updated_at          TIMESTAMPTZ
);

-- 2. CONTRACTS
CREATE TABLE contracts (
    id                  INT PRIMARY KEY,
    contract_number     TEXT,
    supplier_id         INT REFERENCES suppliers(id),
    name                TEXT,
    status              TEXT,
    start_date          TEXT,
    end_date            TEXT,
    x_expedite_allowed  BOOLEAN,
    x_escalation_clause TEXT,
    x_penalty_terms     TEXT,
    currency            TEXT,
    created_at          TIMESTAMPTZ
);

-- 3. PURCHASE ORDER HEADERS
CREATE TABLE purchase_order_headers (
    id                  INT PRIMARY KEY,
    po_number           TEXT,
    supplier_id         INT REFERENCES suppliers(id),
    status              TEXT,
    po_total            NUMERIC,
    currency            TEXT,
    ship_to_location    TEXT,
    need_by_date        TEXT,
    created_at          TIMESTAMPTZ,
    updated_at          TIMESTAMPTZ
);

-- 4. PURCHASE ORDER LINES
CREATE TABLE purchase_order_lines (
    id                  TEXT PRIMARY KEY,
    po_header_id        INT REFERENCES purchase_order_headers(id),
    line_num            INT,
    item_number         TEXT,
    description         TEXT,
    quantity            NUMERIC,
    uom                 TEXT,
    unit_price          NUMERIC,
    line_total          NUMERIC,
    need_by_date        TEXT,
    x_confirmed_date    TEXT,
    status              TEXT
);

-- 5. ORDER CONFIRMATIONS
CREATE TABLE order_confirmations (
    id                  TEXT PRIMARY KEY,
    po_line_id          TEXT REFERENCES purchase_order_lines(id),
    supplier_id         INT REFERENCES suppliers(id),
    promised_date       TEXT,
    confirmed_quantity  NUMERIC,
    status              TEXT,
    delay_reason        TEXT DEFAULT '',
    created_at          TIMESTAMPTZ
);

-- 6. INVENTORY POSITIONS
CREATE TABLE inventory_positions (
    item_number         TEXT PRIMARY KEY,
    description         TEXT,
    location            TEXT,
    on_hand_qty         NUMERIC,
    safety_stock        NUMERIC,
    reorder_point       NUMERIC,
    unit_cost           NUMERIC,
    uom                 TEXT
);

-- 7. DEMAND SIGNALS
CREATE TABLE demand_signals (
    id                  SERIAL PRIMARY KEY,
    signal_date         TIMESTAMPTZ,
    item_number         TEXT,
    forecast_qty        NUMERIC,
    actual_demand       NUMERIC,
    channel             TEXT
);

-- 8. DISRUPTION NOTICES
CREATE TABLE disruption_notices (
    notice_id           TEXT PRIMARY KEY,
    received_at         TIMESTAMPTZ,
    channel             TEXT,
    supplier_id         INT REFERENCES suppliers(id),
    item_number         TEXT,
    notice_type         TEXT,
    message_body        TEXT
);

-- 9. DISRUPTION INCIDENTS (operational state machine)
CREATE TABLE disruption_incidents (
    id                      SERIAL PRIMARY KEY,
    case_key                TEXT UNIQUE NOT NULL,
    status                  TEXT DEFAULT 'intaken',
    severity_route          TEXT,
    reviewer_level          TEXT,
    direct_line_value_at_risk_myr NUMERIC,
    inventory_gap_to_safety NUMERIC,
    estimated_avoidable_cost_myr NUMERIC,
    time_to_triage_hours    NUMERIC,
    time_to_decision_hours  NUMERIC,
    time_to_recovery_hours  NUMERIC,
    jira_issue_key          TEXT,
    decision                TEXT,
    decision_rationale      TEXT,
    flags                   TEXT[],
    dropbox_case_path       TEXT,
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    received_at             TIMESTAMPTZ,
    resolved_at             TIMESTAMPTZ
);

-- INDEXES
CREATE INDEX idx_incident_case_key ON disruption_incidents(case_key);
CREATE INDEX idx_incident_status   ON disruption_incidents(status);
CREATE INDEX idx_po_lines_item     ON purchase_order_lines(item_number);
CREATE INDEX idx_incident_jira_key ON disruption_incidents(jira_issue_key);

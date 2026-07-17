-- =====================================================
-- SUPABASE DATABASE SETUP
-- Procurement Exception Commander — Operations Track
-- Autopilot Asia Hackathon 2026
-- Struktur mengikuti CSV dataset persis
-- =====================================================

-- CLEANUP: drop existing tables (urut reverse dependency)
DROP TABLE IF EXISTS disruption_incidents CASCADE;
DROP TABLE IF EXISTS disruption_notices CASCADE;
DROP TABLE IF EXISTS demand_signals CASCADE;
DROP TABLE IF EXISTS inventory_positions CASCADE;
DROP TABLE IF EXISTS order_confirmations CASCADE;
DROP TABLE IF EXISTS purchase_order_lines CASCADE;
DROP TABLE IF EXISTS purchase_order_headers CASCADE;
DROP TABLE IF EXISTS contracts CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;

-- =====================================================
-- 1. SUPPLIERS (master)
-- File: suppliers.csv
-- Columns: id, supplier_number, name, status, primary_contact_email, country, x_tier, x_sole_source, created_at, updated_at
-- =====================================================
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

-- =====================================================
-- 2. CONTRACTS (master)
-- File: contracts.csv
-- Columns: id, contract_number, supplier_id, name, status, start_date, end_date, x_expedite_allowed, x_escalation_clause, x_penalty_terms, currency, created_at
-- Notes: x_escalation_clause contains commas within quoted text
-- =====================================================
CREATE TABLE contracts (
    id                  INT PRIMARY KEY,
    contract_number     TEXT,
    supplier_id         INT REFERENCES suppliers(id),
    name                TEXT,
    status              TEXT,
    start_date          TEXT,       -- multiple date formats, keep as text
    end_date            TEXT,
    x_expedite_allowed  BOOLEAN,
    x_escalation_clause TEXT,
    x_penalty_terms     TEXT,
    currency            TEXT,
    created_at          TIMESTAMPTZ
);

-- =====================================================
-- 3. PURCHASE ORDER HEADERS (transactional)
-- File: purchase_order_headers.csv
-- Columns: id, po_number, supplier_id, status, po_total, currency, ship_to_location, need_by_date, created_at, updated_at
-- Notes: need_by_date has 3 different date formats
-- =====================================================
CREATE TABLE purchase_order_headers (
    id                  INT PRIMARY KEY,
    po_number           TEXT,
    supplier_id         INT REFERENCES suppliers(id),
    status              TEXT,
    po_total            NUMERIC,
    currency            TEXT,
    ship_to_location    TEXT,
    need_by_date        TEXT,       -- 3 date formats, keep as text
    created_at          TIMESTAMPTZ,
    updated_at          TIMESTAMPTZ
);

-- =====================================================
-- 4. PURCHASE ORDER LINES (transactional)
-- File: purchase_order_lines.csv
-- Columns: id, po_header_id, line_num, item_number, description, quantity, uom, unit_price, line_total, need_by_date, x_confirmed_date, status
-- Notes: id format "90000-1", need_by_date multiple formats
-- =====================================================
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

-- =====================================================
-- 5. ORDER CONFIRMATIONS (transactional)
-- File: order_confirmations.csv
-- Columns: id, po_line_id, supplier_id, promised_date, confirmed_quantity, status, delay_reason, created_at
-- Notes: id format "OC117741", empty delay_reason = ''
-- =====================================================
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

-- =====================================================
-- 6. INVENTORY POSITIONS (master)
-- File: inventory_positions.csv
-- Columns: item_number, description, location, on_hand_qty, safety_stock, reorder_point, unit_cost, uom
-- Notes: no id column — item_number is the natural key
-- =====================================================
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

-- =====================================================
-- 7. DEMAND SIGNALS (transactional)
-- File: demand_signals.csv
-- Columns: signal_date, item_number, forecast_qty, actual_demand, channel
-- =====================================================
CREATE TABLE demand_signals (
    id                  SERIAL PRIMARY KEY,
    signal_date         TIMESTAMPTZ,
    item_number         TEXT,
    forecast_qty        NUMERIC,
    actual_demand       NUMERIC,
    channel             TEXT
);

-- =====================================================
-- 8. DISRUPTION NOTICES (transactional — TRIGGER SOURCE)
-- File: disruption_notices.csv
-- Columns: notice_id, received_at, channel, supplier_id, item_number, notice_type, message_body
-- Notes: This table is the INPUT — operators read from here
-- =====================================================
CREATE TABLE disruption_notices (
    notice_id           TEXT PRIMARY KEY,
    received_at         TIMESTAMPTZ,
    channel             TEXT,
    supplier_id         INT REFERENCES suppliers(id),
    item_number         TEXT,
    notice_type         TEXT,
    message_body        TEXT
);

-- =====================================================
-- 9. DISRUPTION INCIDENTS (operational — orchestrator state machine)
-- This table tracks the lifecycle of each disruption from receipt to resolution
-- Status flow: received → parsing → assessing → scoring → sourcing → awaiting_approval → notifying → resolved
--              Any step → failed → escalated
-- =====================================================
CREATE TABLE disruption_incidents (
    id                      SERIAL PRIMARY KEY,
    notice_id               TEXT UNIQUE REFERENCES disruption_notices(notice_id),
    status                  TEXT DEFAULT 'received',
    severity_score          INT,
    routing                 TEXT,
    total_po_value_at_risk  NUMERIC,
    stock_cover_days        NUMERIC,
    flags                   TEXT[],
    cost_avoided            NUMERIC,
    time_to_recovery_hours  NUMERIC,
    resolution_summary      TEXT,
    jira_ticket             TEXT,
    approved_by             TEXT,
    decision_detail         JSONB,
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    received_at             TIMESTAMPTZ,
    resolved_at             TIMESTAMPTZ
);

-- =====================================================
-- INDEXES for query performance
-- =====================================================
CREATE INDEX idx_po_lines_item         ON purchase_order_lines(item_number);
CREATE INDEX idx_po_lines_po_header    ON purchase_order_lines(po_header_id);
CREATE INDEX idx_po_headers_supplier   ON purchase_order_headers(supplier_id);
CREATE INDEX idx_contracts_supplier    ON contracts(supplier_id);
CREATE INDEX idx_order_conf_po_line    ON order_confirmations(po_line_id);
CREATE INDEX idx_demand_signals_item   ON demand_signals(item_number);
CREATE INDEX idx_disruption_supplier   ON disruption_notices(supplier_id);
CREATE INDEX idx_disruption_item       ON disruption_notices(item_number);
CREATE INDEX idx_disruption_type       ON disruption_notices(notice_type);
CREATE INDEX idx_incident_notice       ON disruption_incidents(notice_id);
CREATE INDEX idx_incident_status       ON disruption_incidents(status);

-- =====================================================
-- IMPORT DATA INSTRUCTIONS
-- =====================================================
--
-- Method A: Import via Supabase Dashboard (recommended)
-- 1. Buka Supabase Dashboard → Table Editor
-- 2. Buka masing-masing table → klik "Import" → pilih CSV dari folder:
--    ../../operations/dataset/csv/
-- 3. Import urut sesuai foreign key dependency:
--    (1) suppliers.csv
--    (2) contracts.csv
--    (3) purchase_order_headers.csv
--    (4) purchase_order_lines.csv
--    (5) order_confirmations.csv
--    (6) inventory_positions.csv
--    (7) demand_signals.csv
--    (8) disruption_notices.csv
--
-- Method B: Import via psql (from train directory)
-- \copy suppliers FROM 'operations/dataset/csv/suppliers.csv' WITH CSV HEADER NULL '';
-- \copy contracts FROM 'operations/dataset/csv/contracts.csv' WITH CSV HEADER NULL '';
-- \copy purchase_order_headers FROM 'operations/dataset/csv/purchase_order_headers.csv' WITH CSV HEADER NULL '';
-- \copy purchase_order_lines FROM 'operations/dataset/csv/purchase_order_lines.csv' WITH CSV HEADER NULL '';
-- \copy order_confirmations FROM 'operations/dataset/csv/order_confirmations.csv' WITH CSV HEADER NULL '';
-- \copy inventory_positions FROM 'operations/dataset/csv/inventory_positions.csv' WITH CSV HEADER NULL '';
-- \copy demand_signals FROM 'operations/dataset/csv/demand_signals.csv' WITH CSV HEADER NULL '';
-- \copy disruption_notices FROM 'operations/dataset/csv/disruption_notices.csv' WITH CSV HEADER NULL '';
-- =====================================================

-- VERIFICATION QUERIES
-- SELECT COUNT(*) AS total_suppliers FROM suppliers;
-- SELECT COUNT(*) AS total_contracts FROM contracts;
-- SELECT notice_type, COUNT(*) FROM disruption_notices GROUP BY notice_type;
-- SELECT status, COUNT(*) FROM purchase_order_lines GROUP BY status;
-- SELECT COUNT(*) FROM disruption_incidents WHERE status = 'received';

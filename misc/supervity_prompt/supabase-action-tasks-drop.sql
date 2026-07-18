-- =============================================================
-- Procurement Exception Commander — Supabase Schema DROP
-- Reverses supabase-action-tasks.sql completely.
-- Drops all 10 tables + triggers + policies + function.
-- Run in Supabase SQL Editor (service_role).
-- Safe to re-run — uses IF EXISTS everywhere.
-- Order: triggers → policies (via CASCADE) → tables → function
-- =============================================================

-- Drop all triggers (they depend on tables)
DROP TRIGGER IF EXISTS trg_suppliers_updated_at              ON suppliers;
DROP TRIGGER IF EXISTS trg_contracts_updated_at              ON contracts;
DROP TRIGGER IF EXISTS trg_poh_updated_at                    ON purchase_order_headers;
DROP TRIGGER IF EXISTS trg_pol_updated_at                    ON purchase_order_lines;
DROP TRIGGER IF EXISTS trg_oc_updated_at                     ON order_confirmations;
DROP TRIGGER IF EXISTS trg_ip_updated_at                     ON inventory_positions;
DROP TRIGGER IF EXISTS trg_ds_updated_at                     ON demand_signals;
DROP TRIGGER IF EXISTS trg_dn_updated_at                     ON disruption_notices;
DROP TRIGGER IF EXISTS trg_di_updated_at                     ON disruption_incidents;
DROP TRIGGER IF EXISTS trg_at_updated_at                     ON action_tasks;

-- Drop all tables (CASCADE drops indexes, policies, foreign keys)
DROP TABLE IF EXISTS action_tasks           CASCADE;
DROP TABLE IF EXISTS disruption_incidents   CASCADE;
DROP TABLE IF EXISTS disruption_notices     CASCADE;
DROP TABLE IF EXISTS demand_signals         CASCADE;
DROP TABLE IF EXISTS inventory_positions    CASCADE;
DROP TABLE IF EXISTS order_confirmations    CASCADE;
DROP TABLE IF EXISTS purchase_order_lines   CASCADE;
DROP TABLE IF EXISTS purchase_order_headers CASCADE;
DROP TABLE IF EXISTS contracts              CASCADE;
DROP TABLE IF EXISTS suppliers              CASCADE;

-- Drop the helper function
DROP FUNCTION IF EXISTS update_updated_at_column();

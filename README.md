# Procurement Exception Commander — Operations Track

**Autopilot Asia Hackathon 2026 · Supervity Auto**

An AI Employee that treats supply chain disruptions like incidents — maps blast radius, sources alternatives, weighs trade-offs, and executes fixes with human commander approval for high-impact actions.

---

## Table of Contents

- [Problem Statement](#problem-statement)
- [Architecture Overview](#architecture-overview)
- [Operator Definitions](#operator-definitions)
- [Orchestrator Workflow](#orchestrator-workflow)
- [Human-in-the-Loop](#human-in-the-loop)
- [Database Schema (Supabase)](#database-schema-supabase)
- [Integrations](#integrations)
- [How to Build in Supervity Auto](#how-to-build-in-supervity-auto)
- [Evaluation Criteria Coverage](#evaluation-criteria-coverage)
- [File Structure](#file-structure)

---

## Problem Statement

### Scenario

A supply planner (Wei) receives a disruption alert. An alert is not the damage — the manual scramble that follows is, pulling data from three systems and chasing three teams to execute a fix.

### Dataset

The dataset simulates a Coupa (procure-to-pay) system with adjacent ERP inventory and demand feeds:

| Table | Description | Records |
|---|---|---|
| `suppliers` | Supplier master with tier and sole-source flags | 50 |
| `contracts` | Contracts with expedite, escalation, and penalty terms | 45 |
| `purchase_order_headers` | PO header with status, total, need-by-date | 80 |
| `purchase_order_lines` | PO line items with status (issued/received/backordered) | 171 |
| `order_confirmations` | Supplier ASN feed (confirmed/delayed/at_risk) | 130 |
| `inventory_positions` | ERP stock snapshot with safety stock | 17 |
| `demand_signals` | Forecast vs actual demand | 140 |
| `disruption_notices` | Inbound disruption alerts (the trigger) | 45 |

### Disruption Types (4)

| Type | Count | Description |
|---|---|---|
| `supplier_delay` | 14 | Supplier advises delay (5–19 days) |
| `demand_spike` | 12 | Demand surge exceeding safety stock |
| `quality_hold` | 10 | QA hold on inbound SKU pending inspection |
| `port_cutoff_miss` | 9 | Shipment will miss port cut-off |

### Seeded Traps (Judging Scenarios)

1. **Tier-2 supplier failure** — supplier_delay + tier-2
2. **Demand spike beyond safety stock** — demand_spike + low stock cover
3. **Port cut-off miss** — port_cutoff_miss + sole source supplier
4. **Expedite breaches escalation clause** — expedite needed + contract has penalty

---

## Architecture Overview

```
                    ┌─────────────────────────────────────────┐
                    │   Outlook Email (Disruption Notice)      │
                    └────────────────┬────────────────────────┘
                                     ▼
              ┌──────────────────────────────────┐
              │  01  Disruption Intake            │
              │  Parse → classify → structure     │
              └────────────────┬─────────────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                 ▼
   ┌──────────────────┐  ┌──────────────────┐
   │ 02 Impact         │  │ 03 Contract       │  ◄── PARALLEL
   │ Assessment        │  │ Compliance        │
   └────────┬─────────┘  └────────┬─────────┘
            │                     │
            └─────────┬──────────┘
                      ▼
              ┌──────────────────┐
              │ 04 Severity       │
              │ Router            │
              │ Score 0–100       │
              └────────┬─────────┘
                       │
         ┌─────────────┼─────────────┐
         ▼              ▼              ▼
      LOW(0-30)    MEDIUM(30-70)    HIGH(70+)
         │              │              │
         │       ┌──────┘       ┌──────┘
         │       ▼              ▼
         │  ┌──────────┐  ┌──────────┐
         │  │05 Alt.    │  │05 Alt.    │
         │  │Sourcing   │  │Sourcing   │
         │  └────┬─────┘  └────┬─────┘
         │       │              │
         │       ▼              ▼
         │  Auto-Execute  ┌──────────┐
         │               │06 Approval│  ◄── HUMAN IN THE LOOP
         │               │Router     │
         │               └────┬─────┘
         │                    │
         └──────────┬─────────┘
                    ▼
              ┌──────────────────┐
              │ 07 Notifier       │
              │ Metrics → Close   │
              └──────────────────┘
```

---

## Operator Definitions

Each operator is a self-contained AI Employee with one responsibility.

### 01 — Disruption Intake
- **Focus:** Data parsing & normalization
- **Goal:** Convert raw email text into structured incident data
- **Handles:** 3 date formats (`YYYY-MM-DD HH:MM:SS`, `DD/MM/YYYY`, `Mon DD YYYY`), regex extraction of item_number and delay_days, CSV quoting
- **Edge cases:** Empty fields → "UNKNOWN", unparseable dates → "DATE_UNPARSED"

### 02 — Impact Assessment
- **Focus:** Financial impact quantification
- **Goal:** Calculate blast radius — affected POs, lines, inventory buffer, total value at risk
- **Calculates:** `total_po_value_at_risk`, `stock_cover_days`, `past_due_lines`, `critical_backorder_lines`
- **Correlates:** PO lines ↔ headers ↔ order confirmations ↔ inventory

### 03 — Contract Compliance
- **Focus:** Legal risk detection
- **Goal:** Extract contract terms — expedite rules, escalation clauses, penalty amounts
- **Detects:** `"VP Procurement sign-off"`, `"early-termination penalty"`, `"Penalty RM120k"`
- **Flags:** `SOLE_SOURCE`, `VP_APPROVAL_REQUIRED`, `PENALTY_AT_RISK`, `EXPEDITE_BLOCKED`

### 04 — Severity Router
- **Focus:** Decision intelligence
- **Goal:** Calculate severity score (0–100) and route to LOW/MEDIUM/HIGH path
- **Scoring:** Financial impact (40pt) + supply criticality (30pt) + contract risk (30pt) + inventory urgency (25pt) + disruption type (15pt)
- **Trap override:** Specific patterns auto-force HIGH

### 05 — Alternative Sourcing
- **Focus:** Supply chain optimization
- **Goal:** Find best alternatives via 3-layer search (inventory → same supplier → substitute)
- **Ranking:** `speed_score * 0.4 + cost_score * 0.3 + reliability_score * 0.2 + tier_score * 0.1`
- **Output:** Top 3 ranked alternatives with risk levels

### 06 — Approval Router
- **Focus:** Human-in-the-loop collaboration
- **Goal:** Send Slack approval request with Block Kit, wait for decision, execute or escalate
- **Timeout:** 30 minutes → auto-escalate to manager
- **Fallback:** Slack down → Outlook email approval

### 07 — Notifier
- **Focus:** Stakeholder communication & metrics
- **Goal:** Send severity-tailored email notifications, calculate and log business metrics
- **Metrics:** `cost_avoided`, `time_to_recovery_hours`
- **Recipients:** procurement team + supplier + approver

### 08 — Orchestrator
- **Focus:** Workflow coordination & state management
- **Goal:** Coordinate all 7 operators in correct sequence with parallel execution, branching, retries, and state transitions
- **State machine:** `received → parsing → assessing → scoring → sourcing → awaiting_approval → notifying → resolved`

---

## Orchestrator Workflow

### State Machine

```
received ──→ parsing ──→ assessing ──→ scoring ──→ sourcing ──→ awaiting_approval ──→ notifying ──→ resolved
                    │                                              │                      │
                    └──→ failed ──→ escalated                       └──→ failed ──→ escalated
```

### Execution Flow

| Step | Action | Type |
|---|---|---|
| 1 | Run Disruption Intake | Sequential |
| 2 | Run Impact Assessment + Contract Compliance | **Parallel** |
| 3 | Run Severity Router | Sequential |
| 4 | Route by severity (LOW/MEDIUM/HIGH) | **Branch** |
| 5 | (HIGH only) Run Approval Router — wait for human | **Human** |
| 6 | Run Notifier — close loop | Sequential |

### Context Passing

A shared context object flows through all steps:

```json
{
  "disruption": { "...intake output..." },
  "impact": { "...impact assessment output..." },
  "contract": { "...contract compliance output..." },
  "severity": { "...severity router output..." },
  "alternatives": { "...sourcing output..." },
  "approval": null,
  "notification": { "...notifier output..." }
}
```

### Error Handling

- Every operator: retry once after 5 seconds on failure
- Critical steps (1–3) fail → status = "failed", P0 Jira ticket, Slack alert
- Non-critical steps fail → proceed with partial data, flag the issue
- Human approval timeout (30 min) → auto-escalate

---

## Human-in-the-Loop

The mandatory human loop is implemented in **Operator 06 — Approval Router** for all HIGH-severity disruptions.

### How it works:

1. Severity Router scores > 70 → routing = HIGH
2. Orchestrator runs Alternative Sourcing, then Approval Router
3. Approval Router sends Slack Block Kit message to `#procurement-approvals`:
   - Disruption summary + severity score
   - Impact breakdown (PO value, stock cover days, etc.)
   - Top 3 ranked alternatives with cost/risk
   - Approve / Reject buttons
4. Human commander responds in Slack
5. On approve → execute the chosen alternative, create Jira task
6. On reject/timeout → escalate to manager via email, create P0 Jira task

This loop is **never bypassed** for HIGH severity. It is the core differentiator of the AI Employee architecture.

---

## Database Schema (Supabase)

9 tables total — 8 from the dataset + 1 operational table for state tracking.

### Table: `suppliers`
| Column | Type | Description |
|---|---|---|
| `id` | INT PK | Supplier ID |
| `supplier_number` | TEXT | SUP10000 format |
| `name` | TEXT | Company name |
| `status` | TEXT | active / inactive |
| `primary_contact_email` | TEXT | Contact |
| `country` | TEXT | Country code |
| `x_tier` | TEXT | tier-1 / tier-2 / tier-3 |
| `x_sole_source` | BOOLEAN | Sole source flag |

### Table: `contracts`
| Column | Type | Description |
|---|---|---|
| `id` | INT PK | Contract ID |
| `supplier_id` | INT FK | → suppliers |
| `x_expedite_allowed` | BOOLEAN | Can expedite? |
| `x_escalation_clause` | TEXT | "Standard expedite" / "VP sign-off" / "penalty clause" |
| `x_penalty_terms` | TEXT | "None" / "Breach voids rebate" / "Penalty RM120k" |

### Table: `purchase_order_headers`
| Column | Type | Description |
|---|---|---|
| `id` | INT PK | PO header ID |
| `po_number` | TEXT | PO number |
| `supplier_id` | INT FK | → suppliers |
| `status` | TEXT | issued / closed / soft_closed |
| `po_total` | NUMERIC | Total value |
| `need_by_date` | TEXT | Multiple date formats |

### Table: `purchase_order_lines`
| Column | Type | Description |
|---|---|---|
| `id` | TEXT PK | Format "90000-1" |
| `po_header_id` | INT FK | → purchase_order_headers |
| `item_number` | TEXT | SKU-XXX format |
| `status` | TEXT | issued / received / backordered |

### Table: `order_confirmations`
| Column | Type | Description |
|---|---|---|
| `id` | TEXT PK | Format "OC117741" |
| `po_line_id` | TEXT FK | → purchase_order_lines |
| `status` | TEXT | confirmed / delayed / at_risk |
| `delay_reason` | TEXT | logistics delay / raw material shortage / supplier capacity |

### Table: `inventory_positions`
| Column | Type | Description |
|---|---|---|
| `item_number` | TEXT PK | SKU-XXX format |
| `on_hand_qty` | NUMERIC | Current stock |
| `safety_stock` | NUMERIC | Minimum buffer |
| `reorder_point` | NUMERIC | Reorder trigger |

### Table: `demand_signals`
| Column | Type | Description |
|---|---|---|
| `signal_date` | TIMESTAMPTZ | Date |
| `item_number` | TEXT | SKU-XXX |
| `forecast_qty` | NUMERIC | Predicted demand |
| `actual_demand` | NUMERIC | Real demand |

### Table: `disruption_notices`
| Column | Type | Description |
|---|---|---|
| `notice_id` | TEXT PK | Format "DN-5000" |
| `notice_type` | TEXT | supplier_delay / demand_spike / port_cutoff_miss / quality_hold |
| `message_body` | TEXT | Raw notification text |

### Table: `disruption_incidents` *(operational)*
| Column | Type | Description |
|---|---|---|
| `id` | SERIAL PK | Auto-increment |
| `notice_id` | TEXT FK | → disruption_notices |
| `status` | TEXT | State machine status |
| `severity_score` | INT | 0–100 score |
| `routing` | TEXT | LOW / MEDIUM / HIGH |
| `total_po_value_at_risk` | NUMERIC | Financial impact |
| `stock_cover_days` | NUMERIC | Inventory buffer |
| `flags` | TEXT[] | Warning flags |
| `cost_avoided` | NUMERIC | Business metric |
| `time_to_recovery_hours` | NUMERIC | Business metric |
| `jira_ticket` | TEXT | Reference |
| `approved_by` | TEXT | Human approver name |
| `decision_detail` | JSONB | Full decision context |

Full DDL available at: `misc/call_command/integrations/supabase/00-database-setup.sql`

---

## Integrations

| Integration | Type | Usage |
|---|---|---|
| **Outlook** | Channel | Receive disruption notices + send resolution notifications |
| **Supabase** | System of Record | Read/write all procurement, inventory, and operational data |
| **Slack** | Human Loop | Send approval requests to commander, receive decisions |
| **Jira** | System of Record | Create tasks for failures, escalations, and resolved incidents |

### Integration Architecture

```
Disruption Notice
     │
     ▼
  Outlook ──→ [Disruption Intake] ──→ Supabase
                                           │
                              ┌────────────┼────────────┐
                              ▼            ▼            ▼
                         Supabase     Supabase     Supabase
                        (orders)    (inventory)  (contracts)
                              │            │            │
                              └────────────┼────────────┘
                                           ▼
                                    [Severity Router]
                                           │
                                      HIGH │
                                           ▼
                                    Slack ──→ [Approval Router] ←── Human
                                           │
                                           ▼
                                    Jira (task created)
                                           │
                                    Outlook (notification) ──→ Stakeholders
```

---

## How to Build in Supervity Auto

### Step 1: Setup Database
1. Create Supabase project → save Project URL + anon key
2. Run `00-database-setup.sql` in Supabase SQL Editor
3. Import all CSV files via Table Editor (in dependency order)
4. Verify with count queries

### Step 2: Setup Integrations
1. **Supabase:** Add integration in Supervity with Project URL + anon key
2. **Outlook:** Connect email account
3. **Slack:** Connect workspace and configure `#procurement-approvals` channel
4. **Jira:** Connect and set project key (e.g., "PROC")

### Step 3: Build Operators (1–7)
For each operator file in `misc/call_command/`:
1. Open Supervity Auto → Create New Operator
2. Copy the prompt from the markdown file
3. Answer the assistant's clarification questions
4. Confirm and save with the specified name
5. Test individually

**Build order:** 01 → 02 → 03 → 04 → 05 → 06 → 07

### Step 4: Build Orchestrator (8)
1. Once all 7 operators are built and tested
2. Open Supervity Auto → Create New Orchestrator
3. Copy prompt from `08-orchestrator.md`
4. Configure the workflow sequence, parallel branches, and error handling
5. Save as "Procurement Exception Commander — Orchestrator"

### Step 5: Test End-to-End
1. Insert a `disruption_notices` row into Supabase
2. The orchestration trigger picks it up
3. Watch the state machine progress: `received → parsing → assessing → scoring → ... → resolved`
4. Verify Slack approval request appears for HIGH severity
5. Verify email notification and metrics are logged

---

## Evaluation Criteria Coverage

| Criteria | Weight | How We Address It |
|---|---|---|
| **Business Output** | 40% | Quantified `cost_avoided` and `time_to_recovery` calculated and logged per incident. State machine tracks every step. |
| **Technical Architecture** | 20% | 7 distinct operators + 1 orchestrator. Parallel execution (Step 2), branching (LOW/MED/HIGH), retries, error handling, state machine. |
| **Customizability** | 20% | All thresholds and rules are configurable via Supervity AI Policies — severity thresholds, approval matrix, routing rules, notification templates. |
| **Demo & Console** | 20% | Live walkthrough on Auto Manager Console. Orchestrator displays real-time state transitions. Metrics visible per disruption. |

### Bonus Points
- Seeded trap detection (auto-route to HIGH)
- Trap-specific annotations in orchestrator output
- Jira task creation for traceability
- Slack Block Kit for rich approval UX
- Fallback mechanisms (email if Slack down)

---

## File Structure

```
train/
├── README.md                                    ← This file
├── ProblemStatement__Procurement_Exception_Commander.pdf
├── misc/
│   ├── Autopilot_Asia_Hackathon_Round1_Handbook.pdf
│   ├── Supervity Auto Cheatsheet.pdf
│   ├── Supervity Auto platform walkthrough.mp4
│   └── call_command/
│       ├── 01-disruption-intake.md              ← Prompt: Intake Operator
│       ├── 02-impact-assessment.md              ← Prompt: Impact Assessment
│       ├── 03-contract-compliance.md            ← Prompt: Contract Compliance
│       ├── 04-severity-router.md                ← Prompt: Severity Router
│       ├── 05-alternative-sourcing.md           ← Prompt: Alternative Sourcing
│       ├── 06-approval-router.md                ← Prompt: Approval Router (HITL)
│       ├── 07-notifier.md                       ← Prompt: Notifier
│       ├── 08-orchestrator.md                   ← Prompt: Orchestrator
│       └── integrations/
│           └── supabase/
│               └── 00-database-setup.sql        ← Database DDL + import guide
└── operations/
    └── dataset/
        ├── operations_enterprise_export.xlsx
        └── csv/
            ├── suppliers.csv
            ├── contracts.csv
            ├── purchase_order_headers.csv
            ├── purchase_order_lines.csv
            ├── order_confirmations.csv
            ├── inventory_positions.csv
            ├── demand_signals.csv
            ├── disruption_notices.csv
            ├── Field_Dictionary.csv
            └── 00_INDEX.csv
```

---

## Quick Reference

### Build Order
```
1. Database  → integrations/supabase/00-database-setup.sql
2. Operators → 01 → 02 → 03 → 04 → 05 → 06 → 07
3. Orchestrator → 08
4. Test → Insert disruption notice → watch state machine
```

### Key Metrics
- **cost_avoided** = original_po_value_at_risk - total_estimated_cost_of_alternative
- **time_to_recovery** = resolved_at - received_at (hours)
- **severity_score** = financial(40) + criticality(30) + contract(30) + inventory(25) + type(15)

### Mandatory Requirements
- ✅ Orchestrator + ≥2 distinct operators
- ✅ Parallel execution (Impact + Contract)
- ✅ Branching (LOW/MEDIUM/HIGH)
- ✅ Human-in-the-loop for HIGH severity
- ✅ ≥3 live integrations (Outlook + Supabase + Slack)
- ✅ State machine with context passing
- ✅ Error handling with retries

---

*Built for Autopilot Asia Hackathon 2026 · Operations Track · Supervity Auto Platform*

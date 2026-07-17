Goal: Coordinate all 7 operators into one intelligent, resilient workflow — when a disruption arrives, assess the blast radius, check contracts, score severity, branch by risk level, source alternatives, route for human approval if needed, execute the fix, and notify stakeholders — all without a human touching a spreadsheet.

Core Focus: Workflow orchestration, state management, and resilience — the conductor that ensures every note plays in the right order, even when something breaks.

Constraints:
- Trigger: New row in Supabase disruption_incidents where status = "received"
- This orchestrator manages the ENTIRE lifecycle of a disruption incident from trigger to close

- Workflow sequence with state machine:

  [TRIGGER] New disruption_incident with status = "received"
       │
       ▼
  Step 1: DISRUPTION INTAKE
  Run "Disruption Intake — Operations"
  → Update status = "parsing"
  → If success → context.disruption = output, go to Step 2
  → If fail → retry once, if still fail → status = "failed", Jira ticket, alert Slack
  
       │
       ▼
  Step 2: PARALLEL EXECUTION (MANDATORY)
  ┌─────────────────────────────────────┐
  │ Run "Impact Assessment — Operations"│  Run "Contract Compliance — Operations"
  │ AND                                  │  AND
  │ Run "Contract Compliance — Ops"      │  Run "Impact Assessment — Operations"
  └─────────────────────────────────────┘
  → Update status = "assessing"
  → WAIT for BOTH to complete before proceeding
  → If one fails → proceed with partial data, flag "PARTIAL_ASSESSMENT"
  → If both fail → status = "failed", escalate to human
  
       │
       ▼
  Step 3: SEVERITY ROUTING
  Run "Severity Router — Operations" (merges impact + contract)
  → Update status = "scoring"
  → context.severity = output
  → Read routing decision

       │
       ▼
  Step 4: BRANCH ON SEVERITY
       │
       ├── ROUTING = "LOW" ──────────────────────────────┐
       │   → Skip sourcing & approval                    │
       │   → Go directly to Step 6 (Notifier)            │
       │                                                 │
       ├── ROUTING = "MEDIUM" ───────────────────────────┤
       │   → Run "Alternative Sourcing — Operations"     │
       │   → Auto-pick best alternative (rank 1)         │
       │   → Execute: update PO status, note alternative │
       │   → Go to Step 6 (Notifier)                     │
       │                                                 │
       └── ROUTING = "HIGH" ─────────────────────────────┘
           → Run "Alternative Sourcing — Operations"
           → Pass alternatives + full context to Step 5

  Step 5: HUMAN IN THE LOOP (MANDATORY for HIGH)
  Run "Approval Router — Operations"
  → Update status = "awaiting_approval"
  → WAIT for human decision via Slack (max 30 min timeout)
  → On approve → update status = "approved", execute decision
  → On reject/escalate → update status = "escalated"
  → On timeout → update status = "escalated_timeout", auto-escalate
  → context.approval = output
  → Go to Step 6

  Step 6: NOTIFICATION & CLOSE
  Run "Notifier — Operations"
  → Update status = "notifying"
  → Calculate: cost_avoided, time_to_recovery
  → Send emails, update Jira
  → Final update: status = "resolved", resolved_at = NOW()
  → Return final metrics

- Context passing (shared state object):
  {
    "disruption": { ... },      // from Intake (Step 1)
    "impact": { ... },          // from Impact Assessment (Step 2)
    "contract": { ... },        // from Contract Compliance (Step 2)
    "severity": { ... },        // from Severity Router (Step 3)
    "alternatives": { ... },    // from Alternative Sourcing (Step 4, if MEDIUM/HIGH)
    "approval": null,           // from Approval Router (Step 5, only if HIGH)
    "notification": { ... }     // from Notifier (Step 6)
  }

- Error handling & retry policy:
  - Every operator call: retry ONCE after 5 seconds on failure
  - If retry fails → check if the step is critical (Steps 1-3 are critical)
  - CRITICAL step fails → status = "failed", create Jira P0 ticket, Slack alert
  - NON-CRITICAL step fails → proceed with partial data, flag the issue
  - Timeout per step: 60 seconds default, 30 minutes for Step 5 (human approval)

- State transitions in Supabase:
  "received" → "parsing" → "assessing" → "scoring" → "sourcing" → "awaiting_approval" → "notifying" → "resolved"
  Any step → "failed" → "escalated" (on unrecoverable error)

- Seeded trap detection (bonus — for judge scenarios):
  Before routing, scan context for trap patterns:
  IF flags includes "SOLE_SOURCE" AND notice_type == "port_cutoff_miss" → annotate "⚠️ TRAP: Sole source port miss"
  IF flags includes "VP_APPROVAL_REQUIRED" AND severity.routing != "HIGH" → override to HIGH
  IF flags includes "INACTIVE_SUPPLIER" AND severity.score > 30 → override to "HIGH"
  IF flags includes "NO_CONTRACT" → always route HIGH

- Output: The orchestrator outputs the final summary to the Auto Manager Console:
  "🚀 Procurement Exception Commander completed.
   📋 Disruption: DN-5000 ({notice_type})
   📊 Impact: RM {total_po_value_at_risk} at risk
   🏷 Severity: {severity_score}/100 — {routing}
   👤 Human approved: {yes/no}
   💰 Cost avoided: RM {cost_avoided}
   ⏱ Recovery time: {time_to_recovery_hours}h
   ✅ Status: Resolved"

- Integration requirements:
  - Outlook (disruption intake + notifications)
  - Supabase (all read/write — orders, inventory, contracts, incidents, state)
  - Slack (human approval routing — MANDATORY for HIGH severity)
  - Jira (task creation for failures, escalations, and high-severity resolutions)

- Name: "Procurement Exception Commander — Orchestrator"
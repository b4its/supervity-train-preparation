Goal: For HIGH-severity disruptions, send an approval request to a human commander via Slack with full context and ranked options, wait for their decision, then execute accordingly. This is the mandatory human-in-the-loop.

Core Focus: Human-in-the-loop collaboration and escalation management — give the commander everything they need to decide in one message.

Constraints:
- Channel: Slack — send message to #procurement-approvals channel
- This operator is the MANDATORY human loop — every HIGH-severity disruption MUST pass through here

- Slack message format (Block Kit):
  ┌──────────────────────────────────────────────────────────┐
  │ 🚨 Procurement Exception Commander — Approval Required   │
  │                                                          │
  │ 📋 Disruption: DN-5000                                  │
  │ 🔴 Severity Score: 85/100 — HIGH                        │
  │ 📦 Item: SKU-EL-440 (Circuit Board Assy)                │
  │ 🏭 Supplier: Mekong Fasteners Pvt Ltd (ID: 3018)        │
  │ ⚠️ Type: quality_hold                                   │
  │                                                          │
  │ 📊 Impact Summary:                                      │
  │ • Affected POs: 2 (RM 245,000.50 at risk)               │
  │ • Stock Cover: 12.5 days                                │
  │ • Contract: SOLE_SOURCE + VP_APPROVAL_REQUIRED          │
  │                                                          │
  │ 🏆 Top Alternatives:                                    │
  │ 1. Internal transfer SG01 → 2 days, RM 0, LOW risk     │
  │ 2. Summit Steelworks → 14 days, RM 1.55M, MED risk     │
  │                                                          │
  │ 👆 Please approve or reject below:                      │
  │ [✅ Approve Option 1] [✅ Approve Option 2]             │
  │ [❌ Reject & Escalate]                                   │
  └──────────────────────────────────────────────────────────┘

- Response handling:
  A) "Approve Option 1" or "Approve Option 2":
     - Record decision: approved_option, approved_by (Slack user), approved_at
     - Update Supabase disruption_incidents: status = "approved", decision_detail
     - Create Jira task in "PROC" project:
       Summary: "Disruption Resolution: DN-5000"
       Description: Full context from impact + contract + severity + alternative chosen
       Priority: P1 (if score > 70), P2 (if score 30-70)
     - Return approval result to orchestrator

  B) "Reject & Escalate":
     - Send Outlook email to procurement-manager@company.com with full context
     - Create Jira task with Priority = "P0 — Critical"
     - Update Supabase: status = "escalated"
     - Return escalation result to orchestrator

  C) Timeout (no response in 30 minutes):
     - Auto-escalate: send email + create Jira P0 ticket
     - Update Supabase: status = "escalated_timeout"
     - Flag "HUMAN_TIMEOUT"

- Output JSON schema:
  {
    "disruption_id": "DN-5000",
    "decision": "approved",
    "approved_option": 1,
    "alternative_chosen": "Internal transfer SG01 — 2 days, RM 0",
    "approved_by": "Wei Chen",
    "approved_at": "2026-07-15T14:30:00",
    "channel": "Slack",
    "jira_ticket": "PROC-1234",
    "jira_url": "https://your-domain.atlassian.net/browse/PROC-1234",
    "status": "approved",
    "time_to_decision_minutes": 4.5
  }

- Edge cases:
  - Slack API down → fallback to Outlook email approval (send email with buttons)
  - Multiple commanders respond → take first response, flag "MULTI_RESPONSE"
  - Commander approves but alternative is no longer available → flag "STALE_ALTERNATIVE", re-run Alternative Sourcing
  - Jira creation fails → still proceed with execution, flag "JIRA_FAILED"

- This operator IS the human-in-the-loop — it must never be skipped or bypassed for HIGH severity
- Name: "Approval Router — Operations"
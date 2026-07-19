# Data Flow & Input Template — Procurement Exception Commander

Each operator is a **separate workflow** (subworkflow). The orchestrator calls them via
Supervity subworkflow API (workflowId → runId). Below is the exact data each operator
receives and returns.

---

## Raw Trigger Input (pasted by user)

```json
{
  "trigger_type": "manual",
  "input_text": "NOTICE_ID: DN-5000\nRECEIVED: 2026-06-27 10:30\nSUPPLIER_ID: 3022\nITEM: SKU-EL-440\nTYPE: quality_hold\nMESSAGE: QA hold on inbound SKU-EL-440 pending inspection.\nDELAY_DAYS: null"
}
```

---

## Operator 01 — Outlook Disruption Intake

**Input:** Raw trigger input (email body or pasted JSON above)

**Output:**
```json
{
  "case_key": "DN-5000",
  "is_duplicate": false,
  "notice": {
    "notice_id": "DN-5000",
    "supplier_id": "3022",
    "item_number": "SKU-EL-440",
    "notice_type": "quality_hold",
    "received_at_raw": "2026-06-27 10:30",
    "received_at_normalized": "2026-06-27T10:30:00+08:00",
    "delay_days": null,
    "message_body": "QA hold on inbound SKU-EL-440 pending inspection."
  },
  "data_quality_flags": [],
  "dropbox_case_path": "cases/CASE-DN-5000.json",
  "next_action": "RUN_DATA_QUALITY_STEWARD",
  "supabase_inserted": true
}
```

**Supabase write:** `INSERT INTO disruption_incidents (case_key, status, ...)`

---

## Operator 02 — Dropbox Data Quality Steward

**Input:** Output of Operator 01

**Output:**
```json
{
  "case_key": "DN-5000",
  "evidence_confidence": "HIGH",
  "force_human_review": false,
  "matching_record_ids": {
    "supplier_id": "3022",
    "po_header_ids": ["90000", "90004", "90034", "90054"],
    "po_line_ids": ["90000-1", "90004-1", "90034-1", "90054-1"],
    "contract_ids": ["7017"],
    "confirmation_ids": ["OC117741", "OC339246"],
    "inventory_items": ["SKU-EL-440"]
  },
  "data_quality_flags": [],
  "dropbox_evidence_path": "cases/CASE-DN-5000-data-quality.md",
  "next_action": "RUN_IMPACT_AND_COMPLIANCE_AND_HISTORY_IN_PARALLEL"
}
```

**Supabase writes:** `UPDATE disruption_incidents SET status = 'data_quality'`

---

## Operator 03 — Procurement Impact Mapper

**Input:** Output of Operator 01 + Operator 02 (merged)

**Output:**
```json
{
  "case_key": "DN-5000",
  "direct_line_value_at_risk_myr": "68528.77",
  "broader_po_value_exposure_myr": "72551.35",
  "affected_po_header_ids": ["90000"],
  "affected_po_line_ids": ["90000-1"],
  "confirmation_summary": {
    "confirmed": 1,
    "delayed": 0,
    "at_risk": 0,
    "delay_reasons": []
  },
  "inventory": {
    "on_hand_qty": "811",
    "safety_stock": "354",
    "reorder_point": "571",
    "gap_to_safety": "0",
    "gap_to_reorder": "0",
    "unit_cost": "3681.77"
  },
  "demand_pressure": {
    "actual_minus_forecast": "UNKNOWN",
    "actual_to_forecast_ratio": "UNKNOWN",
    "stock_cover_days": "UNKNOWN"
  },
  "impact_flags": [],
  "dropbox_impact_path": "cases/CASE-DN-5000-impact.md"
}
```

**Supabase writes:** `UPDATE disruption_incidents SET status = 'assessing'`

---

## Operator 04 — Contract Policy Guard

**Input:** Output of Operator 01 + Operator 02 (merged)

**Output:**
```json
{
  "case_key": "DN-5000",
  "supplier": {
    "supplier_id": "3022",
    "status": "inactive",
    "tier": "tier-3",
    "sole_source": false
  },
  "contracts": [
    {
      "contract_id": "7017",
      "status": "published",
      "expedite_allowed": "false",
      "escalation_clause": "Standard expedite",
      "penalty_terms": null
    }
  ],
  "risk_flags": ["SUPPLIER_INACTIVE"],
  "human_review_required": true,
  "compliance_position": "RECOMMEND_WITH_REVIEW",
  "dropbox_compliance_path": "cases/CASE-DN-5000-compliance.md"
}
```

---

## Operator 05 — Supplier History Detector

**Input:** Output of Operator 01 + Operator 02 (merged)

**Output:**
```json
{
  "case_key": "DN-5000",
  "is_chronic_risk": false,
  "disruption_count_in_window": 0,
  "pattern_summary": "No recurring pattern detected in the lookback window."
}
```

---

## Operator 06 — Recovery Options Planner

**Input:** Merged outputs of 01 + 02 + 03 + 04 + 05

**Output:**
```json
{
  "case_key": "DN-5000",
  "recommended_option_id": "OPTION-1",
  "review_level": "COMMANDER",
  "estimated_avoidable_cost_myr": "UNKNOWN",
  "options": [
    {
      "id": "OPTION-1",
      "action": "Allocate existing internal inventory and monitor quality hold status",
      "evidence": [
        "On-hand SKU-EL-440: 811 units (above safety stock 354)",
        "No backorder on affected PO lines",
        "No chronic disruption pattern"
      ],
      "benefit": "Lowest disruption to supply; zero procurement action needed",
      "risks": ["Quality hold may extend if inspection fails"],
      "human_action_required": "Monitor quality inspection outcome",
      "confidence": "HIGH"
    }
  ],
  "decision_rationale": "Supplier is inactive but inventory is sufficient; no chronic risk detected.",
  "recovery_flags": [],
  "dropbox_recovery_path": "cases/CASE-DN-5000-recovery-options.md"
}
```

**Supabase writes:** `UPDATE disruption_incidents SET status = 'scoring'`

---

## Rules Engine — Procurement Exception Routing Policy

**Input:** Evidence confidence + supplier status + tier + all risk flags + scores

**Output:**
```json
{
  "route": "HIGH",
  "review_required": true,
  "reviewer_level": "COMMANDER",
  "priority": "High",
  "score": 25,
  "score_breakdown": [{"item":"supplier_inactive","points":15}],
  "hard_overrides": ["SUPPLIER_INACTIVE"],
  "reason": "Supplier status is inactive -> hard override to HIGH"
}
```

---

## Operator 07 — Human Approval and Task Execution

**Input:** Merged outputs of 01-06 + rules engine decision

**Output (approved):**
```json
{
  "case_key": "DN-5000",
  "task_id": "AT-DN-5000",
  "review_required": true,
  "review_status": "APPROVED",
  "reviewer": "procurement_commander",
  "decision": "approve_recommended_option",
  "selected_option_id": "OPTION-1",
  "next_action": "TASK_CREATED",
  "supabase_status_updated": true,
  "slack_notification_sent": true,
  "outlook_task_sent": true
}
```

**Supabase writes:** `INSERT INTO action_tasks` + `UPDATE disruption_incidents SET status = 'awaiting_execution'`

---

## Operator 08 — Recovery Closeout Reporter

**Input:** Output of 07 + completed action_tasks record from Supabase

**Output:**
```json
{
  "case_key": "DN-5000",
  "case_status": "CLOSED",
  "task_id": "AT-DN-5000",
  "time_to_triage_hours": "0.5",
  "time_to_decision_hours": "2.3",
  "time_to_recovery_hours": "26.4",
  "estimated_avoidable_cost_myr": "UNKNOWN",
  "direct_line_value_at_risk_myr": "68528.77",
  "dropbox_report_path": "reports/RECOVERY-DN-5000.md",
  "outlook_notification_sent": true,
  "supabase_status_updated": true,
  "slack_notification_sent": true,
  "open_risks": []
}
```

**Supabase writes:** `UPDATE disruption_incidents SET status = 'resolved' + metrics`

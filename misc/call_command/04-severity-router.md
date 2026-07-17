Goal: Merge impact + contract data, calculate a severity score (0-100), and decide the routing path: LOW (auto-resolve), MEDIUM (auto-remediate with sourcing), or HIGH (human commander approval needed).

Core Focus: Decision intelligence and risk scoring — translate raw data into actionable routing decisions.

Constraints:
- Input: JSON outputs from Impact Assessment + Contract Compliance
- The router is the brain of the operation — it decides what needs human attention

- Severity scoring formula (all thresholds configurable via AI Policies):
  score = 0
  
  // Financial impact (max 40 points)
  IF total_po_value_at_risk > 100000 → score += 40
  ELSE IF total_po_value_at_risk > 50000 → score += 20
  ELSE IF total_po_value_at_risk > 10000 → score += 10

  // Supply criticality (max 30 points)
  IF x_sole_source == true → score += 30
  IF x_tier == "tier-1" → score += 20
  IF x_tier == "tier-2" → score += 10

  // Contract risk (max 30 points)
  IF escalation_risk == "requires_vp_approval" → score += 25
  IF escalation_risk == "has_penalty" → score += 30
  IF x_expedite_allowed == false → score += 10

  // Inventory urgency (max 25 points)
  IF stock_cover_days >= 0 AND stock_cover_days < 2 → score += 25
  IF stock_cover_days >= 2 AND stock_cover_days < 5 → score += 15
  IF stock_cover_days >= 5 AND stock_cover_days < 10 → score += 5
  IF stock_cover_days == -1 → score += 10  // unknown inventory

  // Disruption type severity (max 15 points)
  IF notice_type == "supplier_delay" AND delay_days > 14 → score += 10
  IF notice_type == "supplier_delay" AND delay_days > 7 → score += 5
  IF notice_type == "demand_spike" → score += 15
  IF notice_type == "port_cutoff_miss" → score += 10
  IF notice_type == "quality_hold" → score += 5

  // Seeded trap patterns — always force HIGH (score = 100)
  // These are the "trick" scenarios the judges will test:
  IF flags includes "SOLE_SOURCE" AND notice_type == "port_cutoff_miss" → score = 100
  IF flags includes "VP_APPROVAL_REQUIRED" AND delay_days > 0 → score = 100
  IF flags includes "PENALTY_AT_RISK" AND expedite_needed == true → score = 100
  IF flags includes "SOLE_SOURCE" AND stock_cover_days < 2 → score = 100

- Routing thresholds:
  score < 30 → "LOW"     → auto-resolve, notify only
  30 <= score <= 70 → "MEDIUM" → auto-source alternatives, auto-execute
  score > 70 → "HIGH"    → human commander must approve

- Force HIGH conditions (overrides score):
  - Any "UNPARSED" field from intake → HUMAN MUST DECIDE
  - Any "MISSING" field from impact → HUMAN MUST DECIDE
  - flags includes "NO_CONTRACT" → HUMAN MUST DECIDE
  - flags includes "INACTIVE_SUPPLIER" → HUMAN MUST DECIDE

- Output JSON schema:
  {
    "disruption_id": "DN-5000",
    "severity_score": 85,
    "routing": "HIGH",
    "score_breakdown": {
      "financial_impact": 40,
      "supply_criticality": 30,
      "contract_risk": 25,
      "inventory_urgency": 0,
      "disruption_type": 10,
      "trap_override": 0
    },
    "summary": "Sole source tier-2 supplier with VP approval clause — impact RM245k. Supplier is inactive. Must route to human commander.",
    "triggers": ["SOLE_SOURCE", "VP_APPROVAL_REQUIRED", "INACTIVE_SUPPLIER", "HIGH_VALUE"],
    "needs_human_approval": true
  }

- Store score + routing decision in Supabase disruption_incidents record
- The human_in_the_loop flag is true whenever routing = "HIGH"
- Name: "Severity Router — Operations"
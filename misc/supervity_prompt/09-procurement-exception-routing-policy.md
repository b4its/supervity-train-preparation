# Prompt: Procurement Exception Routing Policy

Outcome: Create a configurable, testable decision rule for the Procurement Exception Commander so business users can change thresholds, approval routing, and templates without editing operator prompts.

Create a Supervity decision rule named "Procurement Exception Routing Policy". Use variables and decision tables rather than dataset-specific IDs, supplier names, PO numbers, or fixed dates. The rule must be versioned and testable with sample inputs.

Inputs:
- evidence_confidence: HIGH, MEDIUM, LOW
- supplier_status: active, inactive, UNKNOWN
- supplier_tier: tier-1, tier-2, tier-3, UNKNOWN
- sole_source: true, false, UNKNOWN
- published_contract_exists: true, false, UNKNOWN
- expedite_allowed: true, false, UNKNOWN
- vp_signoff_required: true, false
- penalty_risk: true, false
- is_chronic_risk: true, false
- direct_line_value_at_risk_myr: number or UNKNOWN
- inventory_gap_to_safety: number or UNKNOWN
- confirmation_risk: none, delayed, at_risk, UNKNOWN
- notice_type: supplier_delay, demand_spike, port_cutoff_miss, quality_hold, UNKNOWN
- recovery_option_confidence: HIGH, MEDIUM, LOW, NONE

Configurable policy variables with initial defaults:
- HIGH_VALUE_THRESHOLD_MYR = 100000
- MEDIUM_VALUE_THRESHOLD_MYR = 50000
- MATERIAL_INVENTORY_GAP = 1
- HUMAN_REVIEW_TIMEOUT_HOURS = 24
- LOW_ROUTE_MAX_SCORE = 24
- MEDIUM_ROUTE_MAX_SCORE = 59

Hard governance overrides — always route to HIGH and review_required=true:
- evidence_confidence = LOW
- supplier_status = inactive or UNKNOWN
- sole_source = true or UNKNOWN
- published_contract_exists = false or UNKNOWN
- expedite_allowed = false or UNKNOWN when recovery would require expedite
- vp_signoff_required = true
- penalty_risk = true
- is_chronic_risk = true
- recovery_option_confidence = NONE

Score other cases transparently:
- direct line value above HIGH_VALUE_THRESHOLD_MYR: +30
- direct line value above MEDIUM_VALUE_THRESHOLD_MYR: +15
- inventory gap at or above MATERIAL_INVENTORY_GAP: +15
- confirmation risk = at_risk: +15
- confirmation risk = delayed: +10
- notice type = demand_spike: +10
- notice type = port_cutoff_miss: +10
- supplier tier = tier-1: +5
- supplier tier = tier-2: +10
- recovery option confidence = MEDIUM: +10

Routes:
- LOW: no hard override and score <= LOW_ROUTE_MAX_SCORE. Monitoring-only. Human review optional only if no human action or external communication proposed.
- MEDIUM: no hard override and score <= MEDIUM_ROUTE_MAX_SCORE. Human review required.
- HIGH: hard override or score > MEDIUM_ROUTE_MAX_SCORE. Human review required. reviewer_level is LEGAL_OR_VP when VP sign-off or penalty risk applies, otherwise COMMANDER.

Return exactly:
{
  "route": "LOW|MEDIUM|HIGH",
  "review_required": true,
  "reviewer_level": "NONE|COMMANDER|LEGAL_OR_VP",
  "priority": "Low|Medium|High|Highest",
  "score": 0,
  "score_breakdown": [],
  "hard_overrides": [],
  "reason": "..."
}

Create at least five rule tests: a low monitoring case, a medium operational case, a sole-source case, a penalty-clause case, a chronic-risk case, and a missing-data case. Present the rule and tests for approval before publishing.

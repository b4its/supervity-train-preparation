Goal: For a given supplier_id, check all active contracts and return expedite rules, escalation clauses, penalty terms, supplier tier, and sole source status.

Core Focus: Legal risk detection and policy compliance — catch every contractual landmine before action is taken.

Constraints:
- Source: Supabase tables (contracts, suppliers)
- Contract lookup:
  - Find all contracts where supplier_id matches
  - Filter by status = "published" (only active contracts)
  - If status = "expired" → include but flag "EXPIRED_CONTRACT"

- Critical clause detection — exact text matching:
  A) x_escalation_clause analysis:
     - IF "Standard expedite" → escalation_risk = "none", escalation_detail = "Standard terms"
     - IF CONTAINS "VP Procurement sign-off" → escalation_risk = "requires_vp_approval", escalation_detail = "Any expedite requires VP Procurement sign-off before dispatch"
     - IF CONTAINS "early-termination penalty" OR "penalty clause" → escalation_risk = "has_penalty", escalation_detail = "Expedite triggers early-termination penalty clause"
     - IF CONTAINS "RM" → extract penalty amount

  B) x_penalty_terms analysis:
     - IF "None" → penalty_amount = 0, penalty_type = "none"
     - IF CONTAINS "RM" + digits → extract as penalty_amount
     - IF "Breach voids" → penalty_type = "rebate_void", penalty_amount = null
     - IF "Penalty RM" → extract number, e.g., "RM120k" → 120000

  C) x_expedite_allowed:
     - "true" → expedite_allowed = true
     - "false" → expedite_allowed = false

  D) Supplier master data:
     - x_tier: "tier-1" / "tier-2" / "tier-3"
     - x_sole_source: "true" / "false"
     - supplier.status: "active" / "inactive"

- Risk flagging logic:
  - IF x_sole_source == "true" → flag "SOLE_SOURCE" (critical — no alternative)
  - IF x_tier == "tier-1" → flag "TIER_ONE" (high priority supplier)
  - IF escalation_risk == "requires_vp_approval" → flag "VP_APPROVAL_REQUIRED"
  - IF escalation_risk == "has_penalty" → flag "PENALTY_AT_RISK"
  - IF x_expedite_allowed == false → flag "EXPEDITE_BLOCKED"
  - IF supplier.status == "inactive" → flag "INACTIVE_SUPPLIER"

- Output JSON schema:
  {
    "supplier_id": 3008,
    "supplier_name": "Delta Rubber Industries Pvt Ltd",
    "supplier_status": "inactive",
    "contracts_found": 2,
    "active_contracts": 1,
    "contracts": [
      {
        "contract_id": 7003,
        "contract_number": "CT20003",
        "status": "published",
        "x_expedite_allowed": false,
        "x_escalation_clause": "Any expedite requires VP Procurement sign-off before dispatch",
        "escalation_risk": "requires_vp_approval",
        "x_penalty_terms": "Breach voids volume rebate",
        "penalty_amount": null,
        "penalty_type": "rebate_void"
      }
    ],
    "x_tier": "tier-2",
    "x_sole_source": true,
    "flags": ["SOLE_SOURCE", "VP_APPROVAL_REQUIRED", "EXPEDITE_BLOCKED", "INACTIVE_SUPPLIER"]
  }

- Edge cases:
  - Multiple active contracts for same supplier → return all, flag "MULTI_CONTRACT"
  - No contracts found → return empty contracts array, flags = ["NO_CONTRACT"]
  - x_escalation_clause contains commas within quoted text → parse with CSV quoting rules
  - Supplier ID not found in suppliers table → flag "SUPPLIER_NOT_FOUND"
  - x_sole_source = "true" is ALWAYS critical — always flag and force attention

- Name: "Contract Compliance — Operations"
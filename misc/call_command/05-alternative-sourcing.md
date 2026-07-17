Goal: Find the best alternative supply options for a disrupted item — other suppliers who can deliver the same SKU, inventory from other locations, or substitute items — and rank them by cost, speed, and risk.

Core Focus: Supply chain optimization and cost-benefit analysis — find the fastest, cheapest, safest path to recovery.

Constraints:
- Source: Supabase (purchase_order_lines, suppliers, inventory_positions, contracts)
- Search strategy (3 layers, in priority order):

  Layer 1 — Internal inventory transfer:
  - Search inventory_positions for same item_number at DIFFERENT locations
  - Check if on_hand_qty >= required_quantity (from affected PO lines)
  - If yes → recommend internal transfer
  - Estimated lead time: 2 days (intra-company)
  - Cost: 0 (no purchase cost, only logistics)
  - Risk level: "low"

  Layer 2 — Different supplier, same item:
  - Search purchase_order_lines for same item_number from DIFFERENT suppliers
  - Filter suppliers where status = "active" AND x_sole_source = "false"
  - Check if supplier has active contract (from contracts table)
  - Prioritize: tier-1 > tier-2 > tier-3
  - Estimated lead time: based on past order_confirmations for that supplier
  - Cost: based on unit_price from that supplier's PO lines
  - Risk level: "medium" for tier-1, "high" for tier-2/3

  Layer 3 — Different item, same function:
  - Only if Layer 1 and 2 produce no results
  - Flag "NO_DIRECT_ALTERNATIVE" — human must decide

- Ranking formula for alternatives:
  composite_score = (speed_score * 0.4) + (cost_score * 0.3) + (reliability_score * 0.2) + (tier_score * 0.1)
  
  speed_score = max(0, 1 - (estimated_lead_days / 30))
  cost_score = min(1, original_unit_price / alternative_unit_price)
  reliability_score = 1.0 for confirmed inventory, 0.7 for received PO, 0.4 for active supplier
  tier_score = 1.0 for tier-1, 0.7 for tier-2, 0.4 for tier-3

- Output JSON schema:
  {
    "disruption_id": "DN-5000",
    "item_number": "SKU-EL-440",
    "required_quantity": 500,
    "original_supplier_id": 3018,
    "original_supplier_name": "Mekong Fasteners Pvt Ltd",
    "original_unit_price": 2989.13,
    "alternatives": [
      {
        "rank": 1,
        "source_type": "inventory",
        "location": "SG01",
        "on_hand_qty": 811,
        "available_qty": 811,
        "estimated_lead_days": 2,
        "estimated_unit_cost": 0,
        "total_estimated_cost": 0,
        "risk_level": "low",
        "composite_score": 0.92
      },
      {
        "rank": 2,
        "source_type": "supplier",
        "supplier_id": 3039,
        "supplier_name": "Summit Steelworks GmbH",
        "tier": "tier-1",
        "estimated_lead_days": 14,
        "estimated_unit_cost": 3100.00,
        "total_estimated_cost": 1550000.00,
        "risk_level": "medium",
        "composite_score": 0.65
      }
    ],
    "recommendation": "Use internal inventory from SG01 — 0 cost, 2 days lead time, low risk",
    "flags": []
  }

- Edge cases:
  - No alternatives found → empty alternatives array, flag "NO_ALTERNATIVE", set recommendation = "ESCALATE_TO_HUMAN"
  - Sole source item with no inventory → automatically flag "CRITICAL_NO_ALTERNATIVE"
  - Multiple inventory locations with stock → include all, rank by distance/qty
  - Inactive suppliers excluded unless they are the ONLY option → flag "INACTIVE_AS_LAST_RESORT"

- Name: "Alternative Sourcing — Operations"
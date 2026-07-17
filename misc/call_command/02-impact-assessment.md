Goal: Given a structured disruption incident, calculate the blast radius by finding all affected purchase orders, lines, inventory impact, and total value at risk.

Core Focus: Financial impact quantification and supply chain visibility — map every dollar and every day at risk.

Constraints:
- Source data: Supabase tables (purchase_order_headers, purchase_order_lines, inventory_positions, order_confirmations, demand_signals)
- Matching logic:
  1. Find all purchase_order_lines where item_number = disruption.item_number
  2. Filter by supplier_id = disruption.supplier_id to isolate the affected supplier's lines
  3. Cross-reference po_header_id to get PO-level details from purchase_order_headers
  4. Exclude already closed/delivered POs (status = "closed" or status = "received")

- Impact calculations:
  A) Financial impact:
     - affected_po_count = count of distinct po_header_id
     - affected_line_count = count of po_line entries
     - total_po_value_at_risk = SUM of po_total from affected headers
     - line_value_at_risk = SUM of line_total from affected lines

  B) Inventory buffer analysis:
     - Look up inventory_positions by item_number
     - Calculate stock_cover_days = on_hand_qty / avg_daily_demand
     - avg_daily_demand from demand_signals = AVG(actual_demand) over last 30 days
     - Compare on_hand_qty vs safety_stock and reorder_point
     - Flag: "below_safety_stock" if on_hand_qty < safety_stock
     - Flag: "below_reorder" if on_hand_qty < reorder_point
     - If no inventory record → stock_cover_days = -1, flag "NO_INVENTORY_DATA"

  C) Order confirmation correlation:
     - Find order_confirmations where po_line_id matches affected lines
     - Count: confirmed_count, delayed_count, at_risk_count
     - Collect delay_reason values for delayed/at_risk items

- Date handling:
  - Normalize all need_by_date values to YYYY-MM-DD before comparison
  - 3 date formats to handle: "YYYY-MM-DD HH:MM:SS", "DD/MM/YYYY", "Mon DD YYYY"
  - If need_by_date is in the past AND line status is "issued" → flag "PAST_DUE"
  - If need_by_date is within 7 days AND line status is "backordered" → flag "CRITICAL_BACKORDER"

- Output JSON schema:
  {
    "disruption_id": "DN-5000",
    "item_number": "SKU-EL-440",
    "supplier_id": 3022,
    "affected_po_count": 2,
    "affected_line_count": 3,
    "affected_po_ids": [90000, 90005],
    "affected_po_numbers": ["4500000", "4500005"],
    "total_po_value_at_risk": 245000.50,
    "line_value_at_risk": 87500.00,
    "stock_cover_days": 12.5,
    "on_hand_qty": 811,
    "safety_stock": 354,
    "reorder_point": 571,
    "inventory_status": "adequate",
    "order_confirmations": {
      "confirmed": 1,
      "delayed": 1,
      "at_risk": 1,
      "delay_reasons": ["raw material shortage"]
    },
    "past_due_lines": [],
    "critical_backorder_lines": [],
    "flags": []
  }

- Edge cases:
  - Supplier_id has no matching PO → affected_po_count = 0, flag "NO_MATCHING_PO"
  - Item_number has no inventory record → stock_cover_days = -1, flag "NO_INVENTORY"
  - Multiple POs with different need_by_dates → include all, flag "MULTI_TIMELINE"
  - Empty order_confirmations → empty arrays, not null

- Name: "Impact Assessment — Operations"
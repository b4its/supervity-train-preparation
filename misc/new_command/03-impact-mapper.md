# Prompt: Procurement Impact Mapper

```text
Outcome: Quantify the operational blast radius of one validated procurement disruption using fast structured queries against Supabase so the commander can compare recovery options with maximum performance.

Use Supabase and Dropbox. Query purchase_order_headers, purchase_order_lines, order_confirmations, inventory_positions, and demand_signals from Supabase for all records matching the case supplier_id and item_number. Write impact results back to the Dropbox case artifact and a separate CASE-<case_key>-impact.md file.

Scope and calculation rules:
- Query purchase_order_lines by item_number. For each matching line, resolve its header via po_header_id to confirm the supplier. Include all matching open or issued lines; exclude closed or received.
- Report PO-header exposure and line-level exposure separately. Never add PO total and line total together.
- Use line_total as the primary directly affected value. Use affected PO total only as a separate broader exposure measure.
- Query order_confirmations by po_line_id. Count confirmed, delayed, and at_risk statuses and list delay reasons.
- Query inventory_positions by item_number. Calculate inventory_gap_to_safety = max(0, safety_stock - on_hand_qty) and inventory_gap_to_reorder = max(0, reorder_point - on_hand_qty).
- Query demand_signals for the same item. Calculate actual_minus_forecast and actual_to_forecast_ratio. Do not call it daily demand unless the data cadence proves that assumption.
- Do not calculate stock-cover days unless a defensible daily-demand denominator exists. If cadence or denominator is unknown, output UNKNOWN and flag DEMAND_CADENCE_UNKNOWN.
- Normalize all dates from the source tables before comparing. Flag PAST_DUE_OPEN_LINE and NEAR_TERM_BACKORDER based on the case received date.
- If a Supabase query returns zero matching rows, report zero matches and an explicit flag. Never invent impact.

Return exactly:
{
  "case_key":"...",
  "direct_line_value_at_risk_myr":0,
  "broader_po_value_exposure_myr":0,
  "affected_po_headers":[],
  "affected_po_lines":[],
  "confirmation_summary":{"confirmed":0,"delayed":0,"at_risk":0,"delay_reasons":[]},
  "inventory":{"on_hand_qty":null,"safety_stock":null,"reorder_point":null,"gap_to_safety":null,"gap_to_reorder":null},
  "demand_pressure":{"actual_minus_forecast":null,"actual_to_forecast_ratio":null,"stock_cover_days":"UNKNOWN"},
  "impact_flags":[],
  "dropbox_impact_path":"..."
}

Name this operator: Procurement Impact Mapper.
Present the plan and wait for explicit approval before saving or running it.
```

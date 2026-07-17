Goal: Every time a disruption notice arrives via Outlook email, parse it into a structured incident with notice_type, supplier_id, item_number, and delay details so downstream operators can act on it.

Core Focus: Data parsing, normalization, and signal clarity — convert raw text into machine-readable intelligence.

Constraints:
- Source: Outlook email inbox, subject line contains "Disruption Notice" or "DN-"
- Parse message_body using these extraction rules in order:

  A) Notice type detection — match exact keywords:
     - "supplier_delay" or "delay" → notice_type = "supplier_delay"
     - "demand_spike" or "demand surge" → notice_type = "demand_spike"
     - "port_cutoff_miss" or "port cut-off" → notice_type = "port_cutoff_miss"
     - "quality_hold" or "QA hold" → notice_type = "quality_hold"

  B) Item number extraction:
     - Pattern: [A-Z]{2,4}-\d{2,4}  (e.g., SKU-EL-440, SKU-PK-770)
     - If multiple items found, take the first one and flag "MULTI_ITEM"

  C) Supplier ID extraction:
     - Look for numeric ID after "supplier" or at standard position
     - If not found, flag "SUPPLIER_ID_MISSING"

  D) Date parsing — 3 format priority:
     1. "YYYY-MM-DD HH:MM:SS" → parse directly
     2. "DD/MM/YYYY" → normalize to YYYY-MM-DD
     3. "Mon DD YYYY" (e.g., "Jul 20 2026") → normalize to YYYY-MM-DD
     If all fail → set parsed_date = null AND flag "DATE_UNPARSED"

  E) Delay duration extraction — regex patterns:
     - "(\d+)\s*day.*delay" → extract days directly
     - "(\d+)\s*week.*delay" → multiply by 7
     - "next sailing in (\d+) days" → extract days
     - "miss the.*cut-off on (\d{4}-\d{2}-\d{2})" → calculate days from today
     If no delay found → delay_days = 0

- Edge cases to handle:
  - Empty or missing fields → set to "UNKNOWN", do not crash
  - Extra whitespace in supplier names → trim before matching
  - Comma inside quoted fields → respect CSV quoting rules
  - Multiple disruption notices in same email → process first, flag "BATCH"

- Output JSON schema (exact):
  {
    "notice_id": "DN-5000",
    "received_at": "2026-06-27T00:00:00",
    "channel": "email",
    "supplier_id": 3022,
    "supplier_name": "Bharat Industrial Supplies LLC",
    "item_number": "SKU-EL-440",
    "notice_type": "quality_hold",
    "delay_days": 0,
    "parsed_date": "2026-06-27T00:00:00",
    "original_message": "QA hold on inbound SKU-EL-440 pending inspection.",
    "flags": []
  }

- Write the structured output to Supabase table "disruption_incidents"
- Record all flags in the flags array for downstream operators to inspect
- Name this workflow: "Disruption Intake — Operations"
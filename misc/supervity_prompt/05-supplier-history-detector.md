# Prompt: Supplier History Detector

Outcome: Determine whether the current supplier has a recurring disruption pattern within a configurable lookback window so the router can account for chronic risk in severity scoring.

Use these integrations: Supabase, Slack.

Subworkflow input JSON:
```json
{"case_key":"...","supplier_id":"...","received_at":"...","dropbox_case_path":"..."}
```

`case_key` and `supplier_id` are required. `received_at` can be raw text. If it cannot be parsed, return `is_chronic_risk=false`, add `current_notice_date_unparseable` to the summary, and do not fabricate a date.

Rules:
- Read case_key and available artifacts from the case `output/` folder under Dropbox root for context.
- Query table 'disruption_notices' where supplier_id matches the case supplier_id.
- Filter to records within the lookback window of {{LOOKBACK_DAYS}} days (default 90) from the current notice's received_at date.
- The received_at column may contain inconsistent date formats: ISO timestamp, DD/MM/YYYY, or Mon DD YYYY. Normalize all dates before comparing against the lookback window. If a date cannot be confidently parsed, exclude that record from the count but note "unparseable_date_excluded".
- Count total past disruption notices for this supplier in the window, and break down by notice_type.
- If count >= {{CHRONIC_THRESHOLD}} (default 3) within the window, set is_chronic_risk = TRUE.
- Otherwise set is_chronic_risk = FALSE.
- If is_chronic_risk is TRUE, generate a one-sentence factual summary: "This supplier has had {count} disruption notices in the past {lookback} days, including {type_counts}."
- If FALSE, state "No recurring pattern detected in the lookback window."
- If zero past notices found or the query fails, report is_chronic_risk = FALSE honestly with count = 0.
- Post Slack audit notifications to `PROCUREMENT_SLACK_CHANNEL`: `STARTED`, `COMPLETED` with case_key and chronic-risk boolean/count, `DATE_UNPARSEABLE` when applicable, and `FAILED` with a short non-sensitive error. Do not post raw notice content.

Output JSON:
{
  "case_key": "...",
  "is_chronic_risk": false,
  "disruption_count_in_window": 0,
  "pattern_summary": "...",
  "slack_notification_sent": true
}

Name this operator: Supplier History Detector.

# Live Demo and Test Matrix

Use these tests after all integrations and operators are connected. Do not build the demo around a fixed sample row. Select or create a new Outlook message each time and let the workflow discover matching Dropbox evidence.

## Preflight

1. Supabase Data Loader has been run successfully — all 8 reference tables are populated.
2. Dropbox `source/` contains the eight CSV files and is readable.
3. Dropbox `cases/`, `reports/`, and `archive/` are writable.
4. Outlook intake folder receives a test disruption notice.
5. Outlook can send to the commander, team, and manager addresses.
6. Jira can search, create, comment, and create a sub-task in `JIRA_PROJECT_KEY`.
7. Supabase disruption_incidents table exists and is empty.
8. Slack `PROCUREMENT_SLACK_CHANNEL` is accessible by the workflow bot.
9. The Human Review reviewer and backup reviewer can receive notifications (Outlook and Slack) and access the review form.
10. The decision rule has passed its five published tests.

## Test 1: Low-Risk Monitoring Case

**Purpose:** Prove the LOW branch does not create unnecessary human review.

| Expected behavior | Evidence to show |
|---|---|---|
| Intake creates a Dropbox case artifact and Supabase record. | Outlook message reference, `CASE-<key>.json`, and disruption_incidents row with status 'intaken'. |
| Data Quality shows HIGH confidence. | Data-quality artifact. |
| Impact and Compliance run in parallel. | Auto Manager Console graph and timestamps. |
| Decision rule returns LOW only when there are no hard governance overrides. | Rule output with score breakdown. |
| Closeout sends internal Outlook status, Slack update, and records final metrics in Supabase. | Outlook sent email, Slack message, Dropbox report, and disruption_incidents with resolved status. |

## Test 2: Medium-Risk Recoverable Case

**Purpose:** Prove the workflow creates accountable work rather than pretending to execute procurement changes.

| Expected behavior | Evidence to show |
|---|---|---|
| Recovery planner creates evidence-backed options. | Recovery-options artifact, including UNKNOWN values where data is absent. |
| Jira issue is created or deduplicated by case_key. | Jira key and labels. |
| Native Human Review pauses the run and Slack notifies the reviewer. | Workflow status `waiting`, pending review form, and Slack message for the reviewer. |
| Approval creates a human-owned Jira action task and updates Supabase. | Jira sub-task with `human action required` and disruption_incidents status 'approved'. |
| Closeout waits for verified Jira completion and posts Slack update. | Case remains open until task completion update, Slack final-status message. |

## Test 3: High-Risk Contract or Sole-Source Case

**Purpose:** Prove the mandatory human-in-command rule and seeded-trap handling.

Use a case whose discovered facts include a sole-source supplier, inactive supplier, no published contract, VP sign-off requirement, penalty/rebate clause, or material evidence gap.

| Expected behavior | Evidence to show |
|---|---|---|
| Contract Policy Guard preserves the exact clause and flags governance risk. | Compliance artifact. |
| Rule routes HIGH with a hard override. | Rule result and `hard_overrides`. |
| Jira incident priority is Highest when legal/VP risk applies. | Jira issue. |
| Native Human Review is assigned to correct reviewer level. | Review form. |
| Supabase disruption_incidents shows 'awaiting_approval' status with reviewer_level. | Supabase query result. |
| Timeout escalates via Outlook, Slack, and Jira, never auto-approves. | Jira `REVIEW_EXPIRED` note, manager email, Slack escalation alert, and Supabase 'expired' status. |

## Test 4: Dirty-Data / Missing-Evidence Case

**Purpose:** Prove safe handling on the hidden judging set.

Create an Outlook notice with an unsupported date, missing supplier ID, or item that has no matching evidence in the Dropbox source files.

| Expected behavior | Evidence to show |
|---|---|
| Intake or quality operator preserves raw text. | Case JSON. |
| Missing values are UNKNOWN and flags are explicit. | Data-quality artifact. |
| No lead time, cost, or supplier commitment is invented. | Recovery options. |
| Decision rule forces HIGH / Human Review. | Rule output. |
| Jira captures the investigation rather than a false resolution. | Jira issue label `data-quality`. |

## Demo Script (4–5 Minutes) — Maximum Scoring

Run the **High-Risk / Sole-Source** case (Test 3) for the demo — it exercises all required features: parallel operators, configurable routing, native Human Review, and quantified closeout metrics.

---

### 0:00 – 0:20 — Opening
“The Procurement Exception Commander turns a supplier disruption into a quantified recovery case. It maps impact and checks compliance in parallel, routes high-impact decisions through a human commander, and reports time-to-recovery and cost avoided.”

---

### 0:20 – 0:40 — Step 0: Supabase Data Loader (Prerequisite)
“The Supabase Data Loader reads the eight procurement CSVs from Dropbox and upserts them into Supabase reference tables. All downstream operators query Supabase directly — no CSV parsing per case, maximum performance.”

**Console** → Show Data Loader output:
```
load_status: COMPLETE
tables_loaded: [
  {table:"suppliers", rows_upserted:150},
  {table:"contracts", rows_upserted:42},
  {table:"purchase_order_headers", rows_upserted:280},
  {table:"purchase_order_lines", rows_upserted:1200},
  {table:"order_confirmations", rows_upserted:600},
  {table:"inventory_positions", rows_upserted:90},
  {table:"demand_signals", rows_upserted:500},
  {table:"disruption_notices", rows_upserted:30}
]
```

---

### 0:40 – 1:00 — Step 1: Outlook Disruption Intake
“An exception notice arrives in the monitored Outlook folder. Intake parses it, creates a structured case artifact in Dropbox, and inserts a row into Supabase disruption_incidents with status 'intaken'.”

**Console** → Show: case_key, notice_type, supplier_id, dropbox_case_path  
**Supabase** → Show: disruption_incidents status=intaken  
**Dropbox** → Show: CASE-<key>.json created  

---

### 1:00 – 1:20 — Step 2: Data Quality Validation
“Data Quality Steward validates the case against Supabase reference tables — confirms supplier, contracts, PO relationships — and returns HIGH confidence.”

**Console** → Show: evidence_confidence=HIGH, matching_record_ids  
**Supabase** → Show: disruption_incidents status=data_quality  

---

### 1:20 – 2:00 — Step 3: Parallel Execution (Key Scoring Element)
“The workflow forks into two parallel branches — Procurement Impact Mapper and Contract Policy Guard — running simultaneously against Supabase tables.”

**Console (CRITICAL)** → Point to the Auto Manager Console showing BOTH operators with overlapping timestamps:
```
  Operator                          Status     Time
  Procurement Impact Mapper         RUNNING    10:02:15 – 10:02:28
  Contract Policy Guard             RUNNING    10:02:15 – 10:02:25
```

“They query Supabase independently — Impact Mapper checks POs, inventory, demand; Contract Policy Guard checks supplier status, contract restrictions. Complete at different times, proving true parallelism.”

**Supabase** → Show: disruption_incidents status=assessing  
**Dropbox** → Show: CASE-<key>-impact.md and CASE-<key>-compliance.md created  

---

### 2:00 – 2:30 — Step 4: Recovery Planning
“The outputs merge. Recovery Options Planner reads the impact and compliance artifacts, checks Supabase inventory and confirmations, and produces three ranked options.”

**Console** → Show: recommended_option_id, review_level, options[] with confidence  
**Dropbox** → Show: CASE-<key>-recovery-options.md  
**Supabase** → Show: disruption_incidents status=scoring  

---

### 2:30 – 3:10 — Step 5: Decision Rule Branches to HIGH
“The configurable routing policy evaluates the case. Sole-source supplier + expedite restriction → hard governance overrides force HIGH route — human review required.”

**Console (CRITICAL)** → Show rule output:
```
{
  "route": "HIGH",
  "review_required": true,
  "reviewer_level": "COMMANDER",
  "priority": "Highest",
  "score": 85,
  "hard_overrides": ["sole_source","expedite_disallowed"],
  "reason": "Sole-source supplier with expedite restriction requires commander approval"
}
```

“Data-driven, not hardcoded. Change the policy thresholds — the route changes. No code required.”

---

### 3:10 – 3:50 — Step 6: Native Human Review (Live Pause and Resume)
“Human Approval and Jira Execution creates a Jira issue in ORX, then pauses at a native Supervity Human Review step. The reviewer is notified via Outlook AND Slack.”

**Console** → Show: workflow status=WAITING_FOR_HUMAN, pending review form  
**Outlook** → Show: review notification email with form link, Jira key, Dropbox path  
**Slack** → Show: message with form link and decision request  
**Supabase** → Show: disruption_incidents status=awaiting_approval  

“I’ll submit the review form now — approving Option 1.”

**Live action** → Open review form, select “Approve recommended option”, enter rationale, submit  
**Console** → Show: workflow transitions from WAITING to RUNNING, review_status=APPROVED  

---

### 3:50 – 4:20 — Step 7: Jira Execution Task
“Approval creates a human-owned Jira sub-task. It says 'human action required' — the workflow never claims a PO was changed or a supplier contacted.”

**Jira** → Show: sub-task with assignee, summary “human action required”, linked to parent ORX-<key>  
**Supabase** → Show: disruption_incidents with jira_issue_key, decision, reviewer  

---

### 4:20 – 5:00 — Step 8: Closeout with Quantified Metrics
“Closeout Reporter waits for Jira completion, then calculates and records final metrics — every value quantified from actual evidence, no UNKNOWNs.”

**Console (CRITICAL)** → Show final output with quantified values:
```
{
  "case_key": "DN-5000",
  "case_status": "CLOSED",
  "jira_issue_key": "ORX-142",
  "time_to_triage_hours": 0.3,
  "time_to_decision_hours": 1.8,
  "time_to_recovery_hours": 26.4,
  "estimated_avoidable_cost_myr": 47500,
  "direct_line_value_at_risk_myr": 95000,
  "severity_route": "HIGH",
  "human_review_status": "APPROVED"
}
```

“Time-to-triage: 18 minutes. Time-to-decision: under 2 hours. Estimated avoidable cost: RM 47,500 — from line value at risk minus alternative sourcing cost confirmed in Supabase.”

**Outlook** → Show: closeout email to PROCUREMENT_TEAM_EMAIL with metrics  
**Slack** → Show: final status message with case_key and metrics  
**Supabase** → Show: disruption_incidents status=resolved, all metric fields populated  
**Dropbox** → Show: RECOVERY-<key>.md report  

---

### 5:00 – Closing
“The Procurement Exception Commander handles the full lifecycle — Outlook intake through Supabase-powered parallel analysis, native Human Review, Jira execution, and quantified closeout. Configurable routing, five live integrations, and zero fabricated values.”

---

## Quick Variant: LOW and MEDIUM Routes

If judges ask:
- **LOW route** — monitor-only case: no Human Review, straight to Closeout with time_to_triage only, final metrics quantified
- **MEDIUM route** — recoverable case: Jira created, COMMANDER review, human-owned action task, closeout with time_to_recovery

## Acceptance Checklist

- [ ] No local-file processing is used in the workflow run.
- [ ] Dropbox, Jira, Outlook, Supabase, and Slack actions appear in Supervity run logs.
- [ ] Two distinct operators execute in parallel with overlapping timestamps in console.
- [ ] Three branching routes (LOW/MEDIUM/HIGH) are visible in the workflow graph.
- [ ] At least one genuine Human Review form pauses a run and resumes only after submission.
- [ ] An approval rejection and timeout do not auto-approve (escalation only).
- [ ] Duplicate input does not create a duplicate Jira incident.
- [ ] Every completed case has a Dropbox evidence artifact, Jira audit trail, and Supabase state record.
- [ ] All six closeout metrics are quantified (no UNKNOWN values in demo run).
- [ ] Supabase disruption_incidents shows the full case lifecycle from intaken to resolved.
- [ ] Demo video shows the Auto Manager Console with all steps visible.

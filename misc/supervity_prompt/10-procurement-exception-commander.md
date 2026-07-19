# Prompt: Procurement Exception Commander

Outcome: For every new procurement disruption, orchestrate 8 subworkflows (operators) and 1 rules engine to create an evidence-backed recovery case — calling each via Supervity subworkflow API (workflowId → runId).

Architecture: This Auto App is the **orchestrator**. Each operator below is a **separate workflow** (subworkflow). The orchestrator calls them by workflowId, receives a runId, and waits for completion before proceeding. The rules engine runs inline (no subworkflow).

Use only the connected Dropbox, Microsoft Outlook, Supabase, and Slack integrations plus Supervity native Human Review. Do not use local files, undocumented systems, or unconnected tools.

Save these as separate workflows (one Auto App or Operator each):
1. Outlook Disruption Intake
2. Dropbox Data Quality Steward
3. Procurement Impact Mapper
4. Contract Policy Guard
5. Supplier History Detector
6. Recovery Options Planner
7. Human Approval and Task Execution
8. Recovery Closeout Reporter

Save the rules engine as: "Procurement Exception Routing Policy"

Trigger and input:
- Auto trigger: a new Outlook message in OUTLOOK_INTAKE_FOLDER.
- Manual trigger (demo): user pastes disruption notice text into the Run dialog.
- The trigger passes the raw input (email body or pasted text) to subworkflow 01.
- Subworkflow 01 generates the case_key. All subsequent subworkflows carry it.
- Set timezone to Asia/Kuala_Lumpur.

Subworkflow orchestration (each step calls a subworkflow by workflowId):

1. Call subworkflow "Outlook Disruption Intake" with raw input.
   - If duplicate → COMPLETED_DUPLICATE. Do not proceed.
   - On success → update Supabase status to 'intaken'.
   - Output: case_key, notice data, dropbox_case_path.

2. Call subworkflow "Dropbox Data Quality Steward" with output of step 1.
   - On success → update Supabase status to 'data_quality'.
   - Output: evidence_confidence, matching_record_ids.

3. Call three subworkflows in **parallel** (each gets output of step 1 + step 2):
   - "Procurement Impact Mapper"
   - "Contract Policy Guard"
   - "Supplier History Detector"
   - Wait for all three to complete before proceeding.
   - On success → update Supabase status to 'assessing'.
   - Merge all three outputs.

4. Call subworkflow "Recovery Options Planner" with merged data (steps 1-3).
   - On success → update Supabase status to 'scoring'.
   - Output: recovery options, review_level, estimated_avoidable_cost.

5. Evaluate using inline rules engine "Procurement Exception Routing Policy":
   - Input: evidence_confidence, supplier_status, all risk flags, scores.
   - Output: route (LOW | MEDIUM | HIGH), reviewer_level, priority.

6. Route based on severity:
   - **LOW** → skip step 7. Go directly to step 8.
   - **MEDIUM** → call subworkflow "Human Approval and Task Execution" with COMMANDER review.
   - **HIGH** → call subworkflow "Human Approval and Task Execution" with appropriate reviewer.
   - Each route is a separate conditional branch calling a subworkflow.

7. (only for MEDIUM/HIGH) Subworkflow "Human Approval and Task Execution":
   - Must use native Supervity Human Review step (is_human_input_step = true).
   - Native review form is mandatory. Slack and Outlook are notification only.
   - Decision captured via form: approve / reject / more_evidence.
   - On timeout → escalate via Outlook, never auto-approve.
   - On approval → insert action_tasks row in Supabase + send Outlook task email.
   - Update Supabase status to 'awaiting_approval' → 'awaiting_execution'.
   - Wait for action_tasks status to become 'completed' (poll Supabase).
   - Only proceed to step 8 after completion.

8. Call subworkflow "Recovery Closeout Reporter" with data from all prior steps.
   - Query action_tasks where status = 'completed'. If not found, return NOT_CLOSED.
   - On success → update Supabase status to 'resolved' with final metrics.
   - Output: report path, metrics, final status.

Reliability and governance:
- Every subworkflow call must retry once with backoff. Log failures.
- Validate all integration access before first live run.
- Partial data is acceptable. If one parallel branch fails, proceed with available data and flag the gap.
- Preserve raw data. All artifacts go to 'cases' or 'reports' subfolder under Dropbox root.
- Never auto-approve on timeout. Escalate via Outlook.

Configuration variables:
OUTLOOK_INTAKE_FOLDER, PROCUREMENT_TEAM_EMAIL, PROCUREMENT_MANAGER_EMAIL, HUMAN_REVIEW_TIMEOUT_HOURS, DROPBOX_ROOT_PATH, PROCUREMENT_SLACK_CHANNEL, LOOKBACK_DAYS, CHRONIC_THRESHOLD.

Final output:
{
  "case_key": "...",
  "run_status": "COMPLETED|WAITING_FOR_HUMAN|ESCALATED|COMPLETED_DUPLICATE|NOT_CLOSED",
  "severity_route": "LOW|MEDIUM|HIGH",
  "task_id": "...",
  "dropbox_case_path": "...",
  "human_review_status": "NOT_REQUIRED|PENDING|APPROVED|REJECTED|EXPIRED",
  "direct_line_value_at_risk_myr": 95000,
  "estimated_avoidable_cost_myr": 47500,
  "time_to_triage_hours": 0.5,
  "time_to_decision_hours": 2.3,
  "time_to_recovery_hours": 26.4,
  "open_risks": []
}

Present the full plan with subworkflow architecture, severity routing, and parallel branches for review. Ask only for missing configuration values. Wait for explicit "yes, proceed" before saving.

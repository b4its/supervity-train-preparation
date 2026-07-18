# Prompt: Procurement Exception Commander

Outcome: For every new procurement disruption, create an evidence-backed recovery case that maps impact, compliance, and history in parallel, routes any material decision through Supervity Human Review, creates accountable action tasks in Supabase, and reports time-to-recovery and supported avoidable-cost evidence — with maximum performance via Supabase structured queries and configurable routing rules.

Build an Auto App named "Procurement Exception Commander - V2". Use only the connected Dropbox, Microsoft Outlook, Supabase, and Slack integrations plus Supervity native Human Review. Do not use local files, undocumented systems, or unconnected tools.

Use these saved operators exactly by name:
1. Outlook Disruption Intake
2. Dropbox Data Quality Steward
3. Procurement Impact Mapper
4. Contract Policy Guard
5. Supplier History Detector
6. Recovery Options Planner
7. Human Approval and Task Execution
8. Recovery Closeout Reporter

Use the saved rule exactly by name: "Procurement Exception Routing Policy"

Workflow trigger and input:
- Primary trigger: a new Outlook message in OUTLOOK_INTAKE_FOLDER that appears to be a procurement disruption.
- Allow a manual run for demo with a pasted disruption notice or a selected Dropbox input file.
- Set the workflow timezone explicitly to Asia/Kuala_Lumpur.
- Each run must carry case_key as its idempotency and correlation key.

Required deterministic workflow per case:
1. Run Outlook Disruption Intake.
   - If duplicate, add evidence to the existing case and end as COMPLETED_DUPLICATE. Update Supabase accordingly. Do not create a duplicate task.
   - On success, update Supabase disruption_incidents status to 'intaken'.
2. Run Dropbox Data Quality Steward.
   - Validates all case relationships against Supabase. If confidence is LOW, force human review downstream.
   - Update Supabase status to 'data_quality'.
3. Run Procurement Impact Mapper, Contract Policy Guard, and Supplier History Detector in parallel. These query Supabase tables independently — the visual workflow must display them as parallel branches for maximum performance.
   - Update Supabase status to 'assessing'.
4. Merge outputs with intake and data-quality output. Run Recovery Options Planner.
   - Update Supabase status to 'scoring' with the route decision and metrics.
5. Evaluate using the saved rule "Procurement Exception Routing Policy":
   - LOW: high data confidence, no supplier or contract or chronic risk, no material exposure. Run Closeout Reporter directly.
   - MEDIUM: evidence-backed option exists but requires human procurement owner. Run Human Approval and Task Execution with COMMANDER review.
   - HIGH: any hard override or score above threshold. Run Human Approval and Task Execution with correct reviewer level.
6. Human Approval and Task Execution must use a native Supervity Human Review step. Native review form is mandatory. Slack and Outlook are notification channels only — the decision must go through the form.
   - Update Supabase status to 'awaiting_approval'. On timeout, escalate but never auto-approve.
7. After approval, insert row into Supabase 'action_tasks' table and send task assignment via Outlook. Do not claim a PO was changed, an order expedited, inventory transferred, or a supplier contacted.
8. Run Recovery Closeout Reporter only after 'action_tasks' status is 'completed'. Rejected or expired cases remain open and receive internal status notifications.
   - Update Supabase status to 'resolved' with all final metrics on close.

Reliability and governance:
- Every external integration action must retry once with backoff on transient failure. If it fails again, capture error context in Outlook and Slack; do not fail silently.
- Validate integration access before first live run. If any integration is disconnected or lacks permission, stop safely with a clear configuration error.
- Use least privilege. Do not store passwords, API keys, or recipient addresses in prompts; use Supervity integration credentials and environment variables.
- Use native workflow logs and the Auto Manager Console to show inputs, step outputs, retries, Human Review status, task records, Dropbox artifacts, and final metrics.
- Preserve raw data. All derived records must go to the 'cases' or 'reports' subfolder under the Dropbox root and reference their source files.
- If the reviewer times out, escalate via Outlook. Never auto-approve.
- Partial data is acceptable. If one parallel branch fails partially, proceed with available data and flag the gap.

Configuration variables to request if missing:
OUTLOOK_INTAKE_FOLDER, PROCUREMENT_TEAM_EMAIL, PROCUREMENT_MANAGER_EMAIL, HUMAN_REVIEW_TIMEOUT_HOURS, DROPBOX_ROOT_PATH, PROCUREMENT_SLACK_CHANNEL, LOOKBACK_DAYS, CHRONIC_THRESHOLD.

Final output shown in the Auto Manager Console:
{
  "case_key": "...",
  "run_status": "COMPLETED|WAITING_FOR_HUMAN|ESCALATED|COMPLETED_DUPLICATE",
  "severity_route": "LOW|MEDIUM|HIGH",
  "task_id": "...",
  "dropbox_case_path": "...",
  "human_review_status": "NOT_REQUIRED|PENDING|APPROVED|REJECTED|EXPIRED",
  "direct_line_value_at_risk_myr": 95000,
  "estimated_avoidable_cost_myr": 47500,
  "time_to_triage_hours": 0.3,
  "time_to_decision_hours": 1.8,
  "time_to_recovery_hours": 26.4,
  "open_risks": []
}

Present the full plan, integrations, approval form, branching rules, retries, parallel operators, History Detector, Dirty Data handling, and expected outputs for review. Ask only for missing configuration values. Wait for explicit "yes, proceed" before saving or running the workflow.

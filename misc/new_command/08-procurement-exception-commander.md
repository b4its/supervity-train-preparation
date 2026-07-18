# Prompt: Procurement Exception Commander

```text
Outcome: For every new procurement disruption, create an evidence-backed recovery case that maps impact and compliance in parallel, routes any material decision through Supervity Human Review, creates accountable Jira work, and reports time-to-recovery and supported avoidable-cost evidence.

Build an Auto App named "Procurement Exception Commander - Dropbox, Jira, Outlook". Use only the connected Dropbox, Jira, and Microsoft Outlook integrations plus Supervity native Human Review. Do not use local files, Supabase, Slack, undocumented systems, or unconnected tools.

Use these saved operators exactly by name:
1. Outlook Disruption Intake
2. Dropbox Data Quality Steward
3. Procurement Impact Mapper
4. Contract Policy Guard
5. Recovery Options Planner
6. Human Approval and Jira Execution
7. Recovery Closeout Reporter

Workflow trigger and input:
- Primary trigger: a new Outlook message in OUTLOOK_INTAKE_FOLDER that appears to be a procurement disruption.
- Allow a manual run for demo with a pasted disruption notice or a selected Dropbox input file.
- Set the workflow timezone explicitly to Asia/Kuala_Lumpur.
- Each run must carry case_key as its idempotency and correlation key.

Required deterministic workflow:
1. Run Outlook Disruption Intake.
   - If duplicate, add evidence to the existing case and end as COMPLETED_DUPLICATE. Do not create a second Jira issue.
2. Run Dropbox Data Quality Steward.
   - If a required source file, required join, or required date is missing, preserve the evidence gap and continue to an approval/escalation path. Never invent data.
3. Run Procurement Impact Mapper and Contract Policy Guard in parallel. These are independent and the visual workflow must display them as parallel branches.
4. Merge the two outputs with the intake and data-quality output. Run Recovery Options Planner.
5. Decide the route using configurable workflow rules, not hardcoded data rows:
   - LOW / monitor-only: HIGH data confidence, no supplier or contract risk, no material inventory or confirmation risk, and the planner recommends monitoring only. Create/update Jira only if an accountable follow-up is required; then run Closeout Reporter.
   - MEDIUM / action proposal: evidence-backed operational option exists but requires a human procurement owner to perform an action. Run Human Approval and Jira Execution with COMMANDER review.
   - HIGH / governance risk: any sole-source condition, inactive supplier, missing required data, no published contract, expedite restriction, VP sign-off, penalty/rebate clause, severe inventory gap, delayed/at-risk confirmation with material exposure, no evidence-backed option, or planner review_level LEGAL_OR_VP. Run Human Approval and Jira Execution with the correct reviewer level.
6. Human Approval and Jira Execution must use a native Supervity Human Review step. The run must move to waiting state, preserve full context, notify via Outlook, and resume only after a submitted approval, rejection, or request for more evidence. Do not substitute an Outlook reply, a Jira comment, or an assumed approval for the review form.
7. After approval, create the human-owned Jira action task. Do not claim that a PO was changed, an order expedited, inventory transferred, or a supplier contacted.
8. Run Recovery Closeout Reporter only after Jira contains a verified completion update. Rejected, expired, blocked, or more-evidence cases remain open or escalated and receive internal Outlook status notifications.

Reliability and governance:
- Every external integration action must retry once with backoff on a transient failure. If it fails again, capture the error context in Jira and Outlook; do not fail silently.
- Validate integration access before the first live run. If Dropbox, Jira, or Outlook is disconnected or lacks permission, stop safely with a clear configuration error.
- Use least privilege. Do not store passwords, API keys, or recipient addresses in prompts; use Supervity integration credentials and environment variables.
- Use native workflow logs and the Auto Manager Console to show inputs, step outputs, retries, Human Review status, Jira key, Dropbox artifacts, and final metrics.
- Preserve raw data. All derived records must go to Dropbox cases/ or reports/ and reference their source files.
- If the reviewer times out, escalate via Outlook and Jira. Never auto-approve.

Configuration variables to request if missing:
OUTLOOK_INTAKE_FOLDER, PROCUREMENT_COMMANDER_EMAIL, PROCUREMENT_TEAM_EMAIL, PROCUREMENT_MANAGER_EMAIL, JIRA_PROJECT_KEY, HUMAN_REVIEW_TIMEOUT_HOURS, DROPBOX_ROOT_PATH.

Final output shown in the Auto Manager Console:
{
  "case_key":"...",
  "run_status":"COMPLETED|WAITING_FOR_HUMAN|ESCALATED|COMPLETED_DUPLICATE",
  "severity_route":"LOW|MEDIUM|HIGH",
  "jira_issue_key":"...",
  "dropbox_case_path":"...",
  "human_review_status":"NOT_REQUIRED|PENDING|APPROVED|REJECTED|EXPIRED",
  "direct_line_value_at_risk_myr":0,
  "estimated_avoidable_cost_myr":"UNKNOWN",
  "time_to_triage_hours":"UNKNOWN",
  "time_to_decision_hours":"UNKNOWN",
  "time_to_recovery_hours":"UNKNOWN",
  "open_risks":[]
}

Present the full plan, integrations, approval form, branching rules, retries, and expected outputs for review. Ask only for missing configuration values. Wait for explicit "yes, proceed" before saving or running the workflow.
```

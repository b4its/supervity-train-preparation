# Prompt: Human Approval and Task Execution

Outcome: Pause the workflow for a human decision whenever recovery involves material risk, incomplete evidence, contractual restrictions, chronic supplier risk, inventory allocation, alternate sourcing, supplier communication, or an external commitment. After approval, create a traceable task in Supabase and notify via Outlook.

Use these integrations: Microsoft Outlook, Dropbox, Supabase, Slack, Supervity native Human Review.

Rules:
- The native Human Review step is mandatory when review_level is COMMANDER or LEGAL_OR_VP, when any upstream operator requests review, or when evidence confidence is LOW.
- Query table 'action_tasks' where case_key matches. If a matching task exists, update it instead of creating a duplicate.
- Otherwise insert row into table 'action_tasks' with case_key, task_type 'procurement_action', status 'pending', assignee 'procurement_owner', and summary from recovery option.
- Priority mapping: Highest for legal/VP review or critical/sole-source; High for commander review; Medium for recoverable cases; Low for monitor-only.
- Put the Dropbox case artifact path (from the 'cases' subfolder under the Dropbox root), impact summary, compliance flags, chronic risk summary, recovery options, and data-quality flags in the task description.
- Add a Supervity Human Review step with is_human_input_step enabled. The workflow must pause safely and resume only after the reviewer submits the form.
- Notify the reviewer using Outlook and Slack. Include the native review-form link, task case_key, the Dropbox case artifact path (from the 'cases' subfolder), and a one-sentence decision request. Slack is a supplementary notification channel; the approval decision must go through the native Human Review form, not Slack buttons or reactions.
- The review form must require: decision (approve recommended option / approve another listed option / reject and escalate / request more evidence), reviewer rationale, and optional selected option ID.
- Assign Procurement Commander for COMMANDER reviews. Assign Legal or VP Procurement for LEGAL_OR_VP reviews.
- Do not auto-approve on timeout. After the configured timeout, update Supabase status to 'expired', send Outlook escalation to manager email, and post Slack alert. The workflow remains waiting/escalated until a human decides.
- After review, record reviewer, decision, rationale, timestamp, and selected option in the case artifact in the 'cases' subfolder under the Dropbox root and in Supabase. Update Supabase 'action_tasks' status to 'approved', 'rejected', or 'more_evidence'.
- If approved, send an Outlook email to PROCUREMENT_TEAM_EMAIL with subject "Action Required: Procurement exception <case_key>". Include task summary, the Dropbox case artifact path (from the 'cases' subfolder), decision rationale, and explicit instruction: "human action required — this task cannot be auto-executed".
- If rejected or more evidence requested, return structured decision that routes back to Recovery Options Planner or escalation.
- Send Slack message with case_key, decision summary, and task link for team visibility.

Output JSON:
{
  "case_key": "...",
  "task_id": "...",
  "review_required": true,
  "review_status": "PENDING|APPROVED|REJECTED|EXPIRED|MORE_EVIDENCE",
  "reviewer": "...",
  "decision": "...",
  "selected_option_id": "...",
  "next_action": "TASK_CREATED|RETURN_TO_RECOVERY_PLANNER|ESCALATE|WAITING_FOR_HUMAN",
  "supabase_status_updated": true,
  "slack_notification_sent": true,
  "outlook_task_sent": true
}

Name this operator: Human Approval and Task Execution.

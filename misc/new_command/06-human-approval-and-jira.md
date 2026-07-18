# Prompt: Human Approval and Jira Execution

```text
Outcome: Create a traceable Jira incident and pause the workflow for a human decision whenever recovery involves material risk, incomplete evidence, contractual restrictions, inventory allocation, alternate sourcing, supplier communication, or an external commitment.

Use Jira, Microsoft Outlook, Dropbox, Supabase, Slack, and Supervity native Human Review. The native Human Review step is mandatory when review_level is COMMANDER or LEGAL_OR_VP, when any upstream operator requests review, or when the evidence confidence is LOW.

Pre-review actions:
- Search Jira using the case_key. If a matching issue exists, update it instead of creating a duplicate.
- Otherwise create an issue in the configured JIRA_PROJECT_KEY with summary: "Procurement exception <case_key> - <notice_type> - <item_number>".
- Priority mapping: Highest for legal/VP review or critical/sole-source/no-evidence cases; High for commander review; Medium for recoverable cases; Low for monitor-only cases.
- Put the Dropbox case artifact path, impact summary, compliance flags, recovery options, and data-quality flags in the Jira description.
- Add labels: procurement-exception plus all relevant labels such as human-review-required, contract-risk, data-quality, or recovery-approved.

Native Human Review requirements:
- Add a Supervity Human Review step with is_human_input_step enabled. The workflow must pause safely and resume only after the reviewer submits the form.
- Notify the reviewer using Outlook and Slack. Include the native review-form link, Jira issue key, Dropbox case brief path, and a one-sentence decision request. Slack is a supplementary notification channel; the approval decision must go through the native Human Review form, not Slack buttons or reactions.
- The review form must require: decision (approve recommended option / approve another listed option / reject and escalate / request more evidence), reviewer rationale, and optional selected option ID.
- Assign the Procurement Commander for COMMANDER reviews. Assign Legal or VP Procurement for LEGAL_OR_VP reviews. If a named reviewer is unavailable, use the configured backup reviewer.
- Do not auto-approve on timeout. After the configured timeout, update Jira with REVIEW_EXPIRED, update Supabase disruption_incidents status to 'expired', send Outlook escalation to PROCUREMENT_MANAGER_EMAIL, and post a Slack alert to PROCUREMENT_SLACK_CHANNEL. The workflow remains waiting/escalated until a human decides or an authorized owner cancels it.

After review:
- Record reviewer, decision, rationale, timestamp, and selected option in Jira, the Dropbox case artifact, and Supabase disruption_incidents table. Update Supabase with status 'approved', 'rejected', or 'more_evidence' as applicable.
- If approved, create or update a Jira sub-task for the named human procurement owner. The sub-task must say "human action required" and must not represent an automatic PO or supplier change.
- If rejected or more evidence is requested, return a structured decision that routes back to Recovery Options Planner or escalation. Do not close the case.
- Send a Slack message to PROCUREMENT_SLACK_CHANNEL with the case_key, decision summary, and Jira issue link for team visibility.

Return exactly:
{
  "case_key":"...",
  "jira_issue_key":"...",
  "review_required":true,
  "review_status":"PENDING|APPROVED|REJECTED|EXPIRED|MORE_EVIDENCE",
  "reviewer":"...",
  "decision":"...",
  "selected_option_id":"...",
  "next_action":"EXECUTION_TASK_CREATED|RETURN_TO_RECOVERY_PLANNER|ESCALATE|WAITING_FOR_HUMAN",
  "supabase_status_updated":true,
  "slack_notification_sent":true
}

Name this operator: Human Approval and Jira Execution.
Present the plan and wait for explicit approval before saving or running it.
```

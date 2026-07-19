# Prompt: Human Approval and Task Execution

Outcome: Pause the workflow for a human decision whenever recovery involves material risk, incomplete evidence, contractual restrictions, chronic supplier risk, inventory allocation, alternate sourcing, supplier communication, or an external commitment. After approval, create a traceable task in Supabase and notify via Outlook.

Use these integrations: Microsoft Outlook, Dropbox, Supabase, Slack, Supervity native Human Review.

Subworkflow input JSON:
```json
{"case_key":"...","mode":"SOURCE_UPLOAD_REQUEST|RECOVERY_APPROVAL","notice":{},"dropbox_case_path":"...","dropbox_input_path":"...","dropbox_output_path":"...","data_quality":{},"impact":{},"compliance":{},"history":{},"planner":{},"routing":{}}
```

`case_key` and `mode` are required. This workflow may enter `waiting` while its native Human Review is pending; that is a valid state returned to the parent, not a failure.

Rules:
- When `mode=SOURCE_UPLOAD_REQUEST`, do not create an action_tasks row and do not request recovery approval. Create a native Human Review form instructing the user to upload one or more valid `.json` source documents into `dropbox_input_path`. The form must display the exact path and require an acknowledgement after upload. On resume, list the folder and return `next_action=IMPORT_RAW_SOURCE` only when at least one `.json` file exists; otherwise return `next_action=WAITING_FOR_SOURCE_UPLOAD`.
- When `mode=RECOVERY_APPROVAL`, follow the recovery approval rules below. `planner` and `routing` are required in this mode.
- The native Human Review step is mandatory when review_level is COMMANDER or LEGAL_OR_VP, when any upstream operator requests review, or when evidence confidence is LOW.
- Query table 'action_tasks' where case_key matches. If a matching task exists, update it instead of creating a duplicate.
- Otherwise insert row into table 'action_tasks' with case_key, task_type 'procurement_action', status 'pending', assignee 'procurement_owner', and summary from recovery option.
- Priority mapping: Highest for legal/VP review or critical/sole-source; High for commander review; Medium for recoverable cases; Low for monitor-only.
- Put the Dropbox case `output/` artifact path, impact summary, compliance flags, chronic risk summary, recovery options, and data-quality flags in the task description.
- Add a Supervity Human Review step with is_human_input_step enabled. The workflow must pause safely and resume only after the reviewer submits the form.
- Notify the reviewer using Outlook. Include the native review-form link, task case_key, the Dropbox case `output/` artifact path, and a one-sentence decision request. The approval decision must go through the native Human Review form.
- The review form must require: decision (approve recommended option / approve another listed option / reject and escalate / request more evidence), reviewer rationale, and optional selected option ID.
- Assign Procurement Commander for COMMANDER reviews. Assign Legal or VP Procurement for LEGAL_OR_VP reviews.
- Do not auto-approve on timeout. After the configured timeout, update Supabase status to 'expired' and send Outlook escalation to `PROCUREMENT_MANAGER_EMAIL`. The workflow remains waiting/escalated until a human decides.
- After review, record reviewer, decision, rationale, timestamp, and selected option in the case envelope in the `output/` folder under Dropbox root and in Supabase. Update Supabase 'action_tasks' status to 'approved', 'rejected', or 'more_evidence'.
- If approved, send an Outlook email to PROCUREMENT_TEAM_EMAIL with subject "Action Required: Procurement exception <case_key>". Include task summary, the Dropbox case `output/` artifact path, decision rationale, and explicit instruction: "human action required — this task cannot be auto-executed".
- If rejected or more evidence requested, return structured decision that routes back to Recovery Options Planner or escalation.
- Post Slack audit notifications to `PROCUREMENT_SLACK_CHANNEL`: `STARTED`, `WAITING_FOR_SOURCE_UPLOAD`, `WAITING_FOR_HUMAN`, `APPROVED`, `REJECTED`, `EXPIRED`, and `FAILED`. Include case_key, mode, review status, and Dropbox path only. Slack is notification-only; no Slack button, reply, or reaction may approve a request.

Output JSON:
{
  "case_key": "...",
  "mode":"SOURCE_UPLOAD_REQUEST|RECOVERY_APPROVAL",
  "task_id": "...",
  "review_required": true,
  "review_status": "PENDING|APPROVED|REJECTED|EXPIRED|MORE_EVIDENCE",
  "reviewer": "...",
  "decision": "...",
  "selected_option_id": "...",
  "next_action": "IMPORT_RAW_SOURCE|WAITING_FOR_SOURCE_UPLOAD|TASK_CREATED|RETURN_TO_RECOVERY_PLANNER|ESCALATE|WAITING_FOR_HUMAN",
  "supabase_status_updated": true,
  "outlook_task_sent": true,
  "slack_notification_sent": true
}

Name this operator: Human Approval and Task Execution.

# Jira Setup

## Outcome

Create an auditable incident and action record for every material procurement exception without falsely claiming that the workflow can alter the upstream Coupa purchase order.

## Complete Before Building

1. Connect Jira in `Settings -> Integrations` with permission to search, create, comment on, and transition issues in one project.
2. Create or select a Jira project. Set its key as the workflow variable `JIRA_PROJECT_KEY`.
3. Configure these issue types if available: `Incident` and `Task`. If they are unavailable, use `Task` consistently.
4. Configure priorities: `Highest`, `High`, `Medium`, `Low`.
5. Create labels: `procurement-exception`, `human-review-required`, `data-quality`, `contract-risk`, `recovery-approved`.

## Required Jira Fields

Every created or updated issue must include:

- Summary: `Procurement exception <case_key> - <notice_type> - <item_number>`
- Description: source reference, supplier ID, item number, impact evidence, contract evidence, risk flags, options, and the Dropbox case artifact path.
- Labels: `procurement-exception` plus relevant risk labels.
- Priority: derived from the severity decision.
- Idempotency key: the `case_key` in the summary and description.

## State Mapping

| Supervity decision | Jira action |
|---|---|
| Data invalid or evidence incomplete | Create/update issue, label `data-quality`, assign for investigation. |
| Low risk | Create/update an informational issue only if an action is needed; otherwise document in Dropbox and notify. |
| Medium risk | Create/update task with recommended recovery action; no external commitment is made. |
| High risk | Create/update highest-priority incident before Human Review; add the review decision afterward. |
| Approval rejected or expired | Update incident with decision and escalation rationale. |
| Approved | Add a comment with approver, option selected, and required human procurement action. |

## Safety Constraint

Jira is the action queue, not the procurement system. Do not represent Jira task creation as a supplier order, a PO amendment, a shipment expedite, or a confirmed recovery.

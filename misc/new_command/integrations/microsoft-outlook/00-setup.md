# Microsoft Outlook Setup

## Outcome

Use Outlook as a live exception channel, approval-notification channel, and stakeholder communication channel.

## Complete Before Building

1. Connect Microsoft Outlook in `Settings -> Integrations` with least-privilege read access to the dedicated intake mailbox/folder and send access from the approved operations mailbox.
2. Create an Outlook folder called `Procurement Exceptions`.
3. Route test disruption emails to that folder. Use a subject containing one of: `Disruption`, `Supplier Delay`, `Demand Spike`, `Port Cut-off`, or `Quality Hold`.
4. Create and store these workflow environment variables in Supervity, not in prompts:
   - `PROCUREMENT_COMMANDER_EMAIL`
   - `PROCUREMENT_TEAM_EMAIL`
   - `PROCUREMENT_MANAGER_EMAIL`
   - `OUTLOOK_INTAKE_FOLDER`
5. Confirm Outlook can send an internal test notification to the commander.

## Accepted Intake Fields

The body may be free text or may include structured fields. The operator should extract `notice_id`, `supplier_id`, `item_number`, `notice_type`, and any delay or affected date. If the message lacks a stable identifier, create a deterministic `case_key` from normalized sender, received timestamp, supplier ID, item number, and notice type.

## Safety Constraint

Outlook may notify internal stakeholders and the assigned reviewer. It must not email an external supplier, promise delivery, accept commercial terms, or communicate a final customer commitment without a separate human-approved workflow.

# Slack Setup

## Role in This Workflow

Slack is a supplementary notification and alert channel alongside Microsoft Outlook. It does **not** replace the Supervity native Human Review — all approval decisions must go through the native review form, not Slack buttons or reactions.

### What Slack is used for:
- **Review notifications** — send the native Human Review form link to the reviewer's Slack DM or a dedicated channel
- **Escalation alerts** — post timeout/escalation notifications to `PROCUREMENT_SLACK_CHANNEL`
- **Status updates** — case closed, metrics summary, failure alerts
- **Team visibility** — keep the procurement team informed without email overload

### What Slack is NOT used for:
- Human approval decisions (no Slack buttons, reactions, or threads as approval mechanism)
- Case state storage (Supabase and Jira hold state)
- Intake trigger (Outlook is the sole trigger)

## When to Set Up

Complete after Dropbox, Jira, and Outlook are connected, and after Supabase tables are created.

## Steps

### 1. Connect Slack in Supervity

1. Go to **Settings → Integrations**.
2. Click **Add Integration** and select **Slack**.
3. Follow the OAuth flow to authorize Supervity to post messages in your workspace.
4. Scope required: `chat:write`, `chat:write.public` (or restrict to specific channels).

### 2. Create a Slack Channel

Create a dedicated channel (e.g., `#procurement-exceptions`) for workflow notifications. Note its name or ID — this becomes `PROCUREMENT_SLACK_CHANNEL`.

### 3. Set Environment Variable

| Variable | Example | Purpose |
|---|---|---|
| `PROCUREMENT_SLACK_CHANNEL` | `#procurement-exceptions` or `C0123456789` | Target channel or user DM for all workflow notifications |

## Relationship to Other Integrations

| Integration | Slack role |
|---|---|
| Outlook | Primary notification channel — Slack supplements, does not replace |
| Supervity Human Review | Slack notifies the reviewer about pending reviews but the form itself is the sole decision mechanism |
| Jira | Slack alerts reference Jira issue keys for traceability |
| Supabase | Slack does not read or write Supabase data |

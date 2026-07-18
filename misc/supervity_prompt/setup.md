# Setup Guide — Procurement Exception Commander V2

## Prerequisites

| Item | I/O | Required For | Notes |
|------|-----|-------------|-------|
| Supervity workspace | — | Orchestrator, Operators, Rules | Admin or Builder role |
| Supabase project | **INPUT** (read reference data) + **OUTPUT** (write cases & tasks) | All Supabase queries and inserts | URL + service_role key (Settings → API → service_role) |
| Dropbox Business/Team | **INPUT** (read dedup) + **OUTPUT** (write artifacts & reports) | Artifact storage | Shared folder link (create a shared folder, copy the link) |
| Microsoft 365 / Outlook | **INPUT** (trigger emails) + **OUTPUT** (send task/assignment emails) | Email intake & task assignment | Microsoft Graph API access |
| Slack workspace | **OUTPUT** only (notifications) | Notifications | Incoming webhook or Bot token |

## Step 1 — Supabase Schema

Run `supabase-action-tasks.sql` in your Supabase SQL Editor.

```sql
CREATE TABLE IF NOT EXISTS action_tasks (
    id              SERIAL PRIMARY KEY,
    case_key        TEXT UNIQUE NOT NULL,
    task_type       TEXT DEFAULT 'procurement_action',
    summary         TEXT,
    description     TEXT,
    assignee        TEXT DEFAULT 'procurement_owner',
    priority        TEXT DEFAULT 'Medium',
    status          TEXT DEFAULT 'pending',
    decision        TEXT,
    reviewer        TEXT,
    completed_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_action_tasks_case_key ON action_tasks(case_key);
CREATE INDEX idx_action_tasks_status   ON action_tasks(status);
```

Also ensure these tables exist (reference data): `suppliers`, `contracts`, `purchase_order_headers`, `purchase_order_lines`, `order_confirmations`, `inventory_positions`, `demand_signals`, `disruption_notices`, `disruption_incidents`.

If `disruption_incidents` does not exist, create it:

```sql
CREATE TABLE IF NOT EXISTS disruption_incidents (
    id              SERIAL PRIMARY KEY,
    case_key        TEXT UNIQUE NOT NULL,
    status          TEXT DEFAULT 'intaken',
    received_at     TIMESTAMPTZ,
    notice_data     JSONB,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_disruption_incidents_case_key ON disruption_incidents(case_key);
```

## Step 2 — Configure Integrations in Supervity

Navigate to **Settings → Integrations** in Supervity. Add each of the following:

### 2a. Supabase Integration (INPUT + OUTPUT)

Reads reference data (suppliers, contracts, PO, inventory, etc.) and writes new/updated rows (disruption_incidents, action_tasks).

| Field | Value |
|-------|-------|
| Name | `Supabase` (or any name, referenced in prompts as "Supabase") |
| Type | Supabase |
| URL | `https://<project>.supabase.co` |
| Service Role Key | `eyJ...` (from Supabase Settings → API → service_role) |

> **Important**: The prompts use action names like `Query table 'suppliers' where ...`, not raw SQL. Supervity translates these into Supabase REST calls using the service_role key.

### 2b. Dropbox Integration (INPUT + OUTPUT)

Reads existing artifacts from `cases/` (dedup lookup) and writes new artifacts, reports, and archives. The root folder is determined by the `DROPBOX_ROOT_PATH` environment variable — a **shared folder link** (e.g., `https://www.dropbox.com/sh/abc123/xyz`). Subfolders (`cases/`, `reports/`, `archive/`) are created automatically by the operators.

| Field | Value |
|-------|-------|
| Name | `Dropbox` |
| Type | Dropbox |
| Access Token | From Dropbox App Console → OAuth 2 |

### 2c. Microsoft Outlook Integration (INPUT + OUTPUT)

Receives incoming disruption emails (trigger) and sends task assignment/escalation emails.

| Field | Value |
|-------|-------|
| Name | `Microsoft Outlook` |
| Type | Microsoft Graph / Outlook |
| Tenant ID | From Azure AD |
| Client ID | From App Registration |
| Client Secret | From App Registration |

Ensure the app registration has these Microsoft Graph permissions:
- `Mail.Read` — **INPUT**: read intake folder for disruption emails
- `Mail.Send` — **OUTPUT**: send task assignment emails
- `Mail.ReadWrite` — move/flag messages

### 2d. Slack Integration (OUTPUT only)

Sends notification messages to the procurement channel. No data is read from Slack.

| Field | Value |
|-------|-------|
| Name | `Slack` |
| Type | Slack |
| Webhook URL or Bot Token | From Slack App |

## Step 3 — Create Operators

Navigate to **Build → Operators → Create New Operator**. For each operator:

1. Click **Create New Operator**
2. Paste the full prompt content
3. Set the **Name** exactly as specified (case-sensitive — the orchestrator references these names)
4. Connect the required integrations (click "Connect Integration" and select from the list)
5. Click **Save**

### Operator List (create in order)

| # | Exact Name | Prompt File | Integrations | I/O |
|---|------------|-------------|-------------|-----|
| 01 | `Outlook Disruption Intake` | `01-outlook-disruption-intake.md` | Outlook, Dropbox, Supabase | **IN**: Outlook email, Dropbox (dedup), Supabase (dedup) — **OUT**: Dropbox (case), Supabase (incident) |
| 02 | `Dropbox Data Quality Steward` | `02-dropbox-data-quality-steward.md` | Dropbox, Supabase | **IN**: Dropbox (case), Supabase (7 reference tables) — **OUT**: Dropbox (quality artifact) |
| 03 | `Procurement Impact Mapper` | `03-procurement-impact-mapper.md` | Supabase, Dropbox | **IN**: Supabase (PO, inventory, demand), Dropbox (case) — **OUT**: Dropbox (impact artifact) |
| 04 | `Contract Policy Guard` | `04-contract-policy-guard.md` | Supabase, Dropbox | **IN**: Supabase (suppliers, contracts), Dropbox (case) — **OUT**: Dropbox (compliance artifact) |
| 05 | `Supplier History Detector` | `05-supplier-history-detector.md` | Supabase | **IN**: Supabase (disruption_notices), Dropbox (case) — **OUT**: none (analysis only) |
| 06 | `Recovery Options Planner` | `06-recovery-options-planner.md` | Supabase, Dropbox | **IN**: Supabase (inventory, confirmations), Dropbox (all prior artifacts) — **OUT**: Dropbox (options artifact) |
| 07 | `Human Approval and Task Execution` | `07-human-approval-and-task-execution.md` | Outlook, Dropbox, Supabase, Slack | **IN**: Dropbox (case), Supabase (action_tasks) — **OUT**: Supabase (action_tasks), Outlook (task email), Slack (notification) |
| 08 | `Recovery Closeout Reporter` | `08-recovery-closeout-reporter.md` | Dropbox, Outlook, Supabase, Slack | **IN**: Dropbox (case), Supabase (action_tasks) — **OUT**: Dropbox (report), Supabase (status), Outlook (email), Slack (notification) |

> **Important**: The **Name** must match exactly. The orchestrator (`10-procurement-exception-commander.md`) references these names to call them. If the name differs, the orchestrator will fail.

### Post-Paste Steps for Each Operator

After pasting the prompt:

1. **Verify integration names match**: The prompts say "Use these integrations: [list]". Check that the integration names you configured in Step 2 match. If you named your Supabase integration "Supabase DB" instead of "Supabase", update the prompt text accordingly.
2. **Enable error handling**: In the operator settings, enable **Retry on failure** (1 retry with backoff).
3. **Set timeout**: Set a reasonable timeout (30-60 seconds for data operators, 120+ seconds for Human Review).
4. **Test the operator**: Use the **Run** button with sample input JSON to verify it works before connecting to the orchestrator.

## Step 4 — Create the Rules Engine Rule (Internal Processing)

The rules engine does not read from or write to external systems. It receives data from prior operators and returns a routing decision (LOW/MEDIUM/HIGH) to the orchestrator.

Navigate to **Build → Rules → Create New Rule**.

1. Click **Create New Rule**
2. Name: `Procurement Exception Routing Policy`
3. Set **Type** to Decision Table
4. Define inputs (all mandatory):

| Input Name | Type | Values |
|-----------|------|--------|
| evidence_confidence | String | HIGH, MEDIUM, LOW |
| supplier_status | String | active, inactive, UNKNOWN |
| supplier_tier | String | tier-1, tier-2, tier-3, UNKNOWN |
| sole_source | String | true, false, UNKNOWN |
| published_contract_exists | String | true, false, UNKNOWN |
| expedite_allowed | String | true, false, UNKNOWN |
| vp_signoff_required | String | true, false |
| penalty_risk | String | true, false |
| is_chronic_risk | String | true, false |
| direct_line_value_at_risk_myr | Number | |
| inventory_gap_to_safety | Number | |
| confirmation_risk | String | none, delayed, at_risk, UNKNOWN |
| notice_type | String | supplier_delay, demand_spike, port_cutoff_miss, quality_hold, UNKNOWN |
| recovery_option_confidence | String | HIGH, MEDIUM, LOW, NONE |

5. Define outputs:

| Output Name | Type |
|------------|------|
| route | String (LOW / MEDIUM / HIGH) |
| review_required | Boolean |
| reviewer_level | String (NONE / COMMANDER / LEGAL_OR_VP) |
| priority | String (Low / Medium / High / Highest) |
| score | Number |
| score_breakdown | Array |
| hard_overrides | Array |
| reason | String |

6. Create the decision rules in order (first match wins):

**Rule 1-7: Hard Overrides → HIGH**

| Condition | Result |
|-----------|--------|
| `evidence_confidence = LOW` | HIGH, review_required=true, reviewer_level=COMMANDER |
| `supplier_status = inactive OR UNKNOWN` | HIGH, review_required=true, reviewer_level=COMMANDER |
| `sole_source = true OR UNKNOWN` | HIGH, review_required=true, reviewer_level=COMMANDER |
| `published_contract_exists = false OR UNKNOWN` | HIGH, review_required=true, reviewer_level=COMMANDER |
| `expedite_allowed = false OR UNKNOWN` | HIGH, review_required=true, reviewer_level=COMMANDER |
| `vp_signoff_required = true` | HIGH, review_required=true, reviewer_level=LEGAL_OR_VP |
| `penalty_risk = true` | HIGH, review_required=true, reviewer_level=LEGAL_OR_VP |
| `is_chronic_risk = true` | HIGH, review_required=true, reviewer_level=COMMANDER |
| `recovery_option_confidence = NONE` | HIGH, review_required=true, reviewer_level=COMMANDER |

**Rule 8-9: Score-based rules**

| Condition | Result |
|-----------|--------|
| `score > 59` or any hard override active | HIGH |
| `score > 24 AND score <= 59` | MEDIUM, review_required=true, reviewer_level=COMMANDER |
| otherwise | LOW, review_required=false, reviewer_level=NONE |

7. Define configurable policy variables:
   - `HIGH_VALUE_THRESHOLD_MYR` = 100000
   - `MEDIUM_VALUE_THRESHOLD_MYR` = 50000
   - `MATERIAL_INVENTORY_GAP` = 1
   - `LOW_ROUTE_MAX_SCORE` = 24
   - `MEDIUM_ROUTE_MAX_SCORE` = 59

8. Scoring rules (additive):

| Condition | Points |
|-----------|--------|
| `direct_line_value_at_risk_myr > 100000` | +30 |
| `direct_line_value_at_risk_myr > 50000` | +15 |
| `inventory_gap_to_safety >= 1` | +15 |
| `confirmation_risk = at_risk` | +15 |
| `confirmation_risk = delayed` | +10 |
| `notice_type = demand_spike` | +10 |
| `notice_type = port_cutoff_miss` | +10 |
| `supplier_tier = tier-1` | +5 |
| `supplier_tier = tier-2` | +10 |
| `recovery_option_confidence = MEDIUM` | +10 |

9. Create test cases (in Rules → Test tab):

| Test | Input | Expected Route |
|------|-------|---------------|
| 1. Low monitoring | HIGH confidence, active, no risks, value < 50K | LOW |
| 2. Medium operational | HIGH confidence, active, value 75K, delayed confirmation | MEDIUM |
| 3. Sole source | sole_source=true | HIGH |
| 4. Penalty clause | penalty_risk=true | HIGH (LEGAL_OR_VP) |
| 5. Chronic risk | is_chronic_risk=true | HIGH |
| 6. Missing data | evidence_confidence=LOW | HIGH |

10. Save and **Publish** the rule.

## Step 5 — Set Environment Variables (Configuration Input)

These are configuration values set by the administrator, not data inputs from external systems. They control folder paths, email addresses, timeouts, and thresholds.

Navigate to **Environment Variables** (Settings → Environment or within the Auto App settings).

| Variable | Type | Example Value | Notes |
|----------|------|-------------|-------|
| `OUTLOOK_INTAKE_FOLDER` | Config | `ProcurementExceptions` | Outlook folder name for incoming disruption emails |
| `PROCUREMENT_TEAM_EMAIL` | Config | `procurement@company.com` | Shared mailbox or distribution list |
| `PROCUREMENT_MANAGER_EMAIL` | Config | `manager@company.com` | Escalation recipient |
| `HUMAN_REVIEW_TIMEOUT_HOURS` | Config | `24` | Hours before escalation on no response |
| `DROPBOX_ROOT_PATH` | Config | `https://www.dropbox.com/sh/abc123/xyz` | Dropbox shared folder link — root for all artifacts; subfolders `cases/`, `reports/`, `archive/` are created automatically |
| `PROCUREMENT_SLACK_CHANNEL` | Config | `#procurement-alerts` | Slack channel for notifications |
| `LOOKBACK_DAYS` | Config | `90` | Days to look back for chronic pattern detection |
| `CHRONIC_THRESHOLD` | Config | `3` | Number of disruptions in window to qualify as chronic |

## Step 6 — Create the Orchestrator (Auto App)

Navigate to **Build → Auto Apps → Create New Auto App**.

1. Name: `Procurement Exception Commander - V2`
2. Set timezone: **Asia/Kuala_Lumpur**
3. Define the workflow step by step using the visual builder:

### Workflow Steps

#### Step A — Trigger (INPUT: Outlook email)

| Setting | Value |
|---------|-------|
| Trigger type | Outlook folder + Manual run |
| Outlook folder | `{{OUTLOOK_INTAKE_FOLDER}}` |
| Email filter | Subject or body matches disruption keywords |
| Manual trigger | Accept paste disruption notice or Dropbox file |

#### Step B — Operator: Outlook Disruption Intake (INPUT + OUTPUT)

Reads from Outlook (incoming email), Dropbox (dedup lookup), Supabase (dedup lookup). Writes to Dropbox (case artifact) and Supabase (disruption_incidents row).

| Setting | Value |
|---------|-------|
| Operator | `Outlook Disruption Intake` (select from dropdown) |
| Input | From trigger |
| On duplicate | End flow: COMPLETED_DUPLICATE |

#### Step C — Operator: Dropbox Data Quality Steward (INPUT + OUTPUT)

Reads from Dropbox (case JSON) and Supabase (7 reference tables). Writes to Dropbox (data quality artifact).

| Setting | Value |
|---------|-------|
| Operator | `Dropbox Data Quality Steward` |
| Input | Output of Step B |

> Enable **Retry** (1 retry, 5s backoff). Update Supabase status to `data_quality`.

#### Step D — Parallel Branch: Impact + Compliance + History (INPUT + OUTPUT)

Three parallel operators, each reading from Supabase + Dropbox and writing their own artifact to Dropbox.

| Branch | Operator | Input | Output |
|--------|----------|-------|--------|
| D1 | `Procurement Impact Mapper` | Step B output + Step C Dropbox path | Dropbox (impact artifact) |
| D2 | `Contract Policy Guard` | Step B output + Step C Dropbox path | Dropbox (compliance artifact) |
| D3 | `Supplier History Detector` | Step B output + Step C case_key | (analysis only — no external write) |

> Update Supabase status to `assessing` after all branches complete.

#### Step E — Merge

Merge outputs of D1, D2, D3 with Step B and Step C outputs. Pass all to Step F. No external I/O.

#### Step F — Operator: Recovery Options Planner (INPUT + OUTPUT)

Reads from Supabase (inventory, confirmations) and Dropbox (all prior artifacts). Writes to Dropbox (recovery options artifact).

| Setting | Value |
|---------|-------|
| Operator | `Recovery Options Planner` |
| Input | Merged outputs (D1 + D2 + D3 + Step B + Step C) |

> Update Supabase status to `scoring`.

#### Step G — Rules Engine: Procurement Exception Routing Policy (Internal)

No external I/O. Evaluates data from prior operators and returns a routing decision.

| Setting | Value |
|---------|-------|
| Rule | `Procurement Exception Routing Policy` |
| Input | Map fields from Planner output + Data Quality + Compliance + History |
| Map route to workflow branch | See Step H |

#### Step H — Route (Conditional Branch — Internal)

| Route | Action |
|-------|--------|
| **LOW** | Go directly to Step J (Recovery Closeout Reporter) |
| **MEDIUM** | Go to Step I-1 (Human Approval with COMMANDER review) |
| **HIGH** | Go to Step I-1 (Human Approval with appropriate reviewer) |

#### Step I-1 — Operator: Human Approval and Task Execution (INPUT + OUTPUT)

Reads from Dropbox (case artifacts) and Supabase (action_tasks). Writes to Supabase (action_tasks), Outlook (task email), Slack (notification).

| Setting | Value |
|---------|-------|
| Operator | `Human Approval and Task Execution` |
| Input | All case data + rule decision |

**Configure the Native Human Review Form (Internal — Supervity):**

1. In the operator settings, enable **is_human_input_step = true**
2. The workflow will **pause** at this step
3. The reviewer receives the form with these fields:
   - **Decision**: dropdown (approve recommended option / approve another listed option / reject and escalate / request more evidence)
   - **Selected Option ID**: text (optional)
   - **Reviewer Rationale**: text (required)
4. On timeout: update Supabase status to `expired`, send Outlook escalation email, post Slack alert. **Never auto-approve.**
5. After submission: capture `decision`, `reviewer`, `rationale`, `timestamp`

#### Step I-2 — Create Supabase Action Task (OUTPUT)

After approval in Step I-1:
1. Insert row into `action_tasks` (case_key, task_type='procurement_action', status='pending', assignee='procurement_owner', summary from recovery option) — **OUTPUT to Supabase**
2. Send Outlook email to `PROCUREMENT_TEAM_EMAIL` with subject "Action Required: Procurement exception {case_key}" — **OUTPUT to Outlook**
3. Post Slack notification — **OUTPUT to Slack**
4. Update Supabase `disruption_incidents` status to `awaiting_execution` — **OUTPUT to Supabase**

#### Step I-3 — Wait for Task Completion (INPUT)

The workflow waits until a human marks the `action_tasks` record as `completed`. Polls Supabase for status change.

> **Note**: This can be a separate monitoring workflow or a manual update. In the Auto App, use a **Wait** step that periodically checks `Query table 'action_tasks' where case_key = {case_key} AND status = 'completed'`.

#### Step J — Operator: Recovery Closeout Reporter (OUTPUT)

Reads from Dropbox (case) and Supabase (action_tasks). Writes to Dropbox (report), Supabase (status update), Outlook (email), Slack (notification).

| Setting | Value |
|---------|-------|
| Operator | `Recovery Closeout Reporter` |
| Input | All case data + action_tasks record |
| Runs for | LOW (directly after Step G) or MEDIUM/HIGH (after Step I-3) |

> Update Supabase `disruption_incidents` status to `resolved`.

### Auto App Settings Checklist

- [ ] Trigger: Outlook folder + manual
- [ ] Timezone: Asia/Kuala_Lumpur
- [ ] Parallel branches for Step D properly configured
- [ ] Rules engine correctly maps all input fields
- [ ] Native Human Review step enabled (is_human_input_step = true)
- [ ] Retry enabled on all operator steps (1 retry with backoff)
- [ ] Timeout set on Human Review step (use `HUMAN_REVIEW_TIMEOUT_HOURS`)
- [ ] Escalation path configured for timeout
- [ ] `DROPBOX_ROOT_PATH` set to a Dropbox shared folder link (not a filesystem path)
- [ ] All environment variables referenced correctly as `{{VARIABLE_NAME}}`
- [ ] Slack notifications configured as supplementary only (not for decisions)
- [ ] Error handling: partial failure allowed, continue with available data

## Step 7 — Testing

### Test 1: LOW Route (Standard Replacement)

Trigger an email with:
- Supplier delay notice, known supplier (tier-1)
- Line value < 50K MYR
- No chronic history
- Active contract, expedite allowed
- Inventory sufficient

Expected: Route = LOW → Closeout Reporter → COMPLETED

### Test 2: MEDIUM Route (Sole Source + Chronic)

Trigger an email with:
- Supplier delay notice
- sole_source = true
- 4 disruption notices in past 90 days
- Value 75K MYR

Expected: Route = HIGH (hard override: sole_source + chronic) → Human Review → task created in action_tables → after task completed → Closeout

### Test 3: HIGH Route (Penalty + Value)

Trigger an email with:
- Demand spike
- Value 150K MYR
- Contract has penalty clause
- LOW data confidence (missing inventory data)

Expected: Route = HIGH (hard overrides: penalty_risk + LOW confidence) → Human Review (LEGAL_OR_VP) → task created → after task completed → Closeout

### Test Results

Record test results in the Auto App's test run log. Verify:
- Dropbox artifacts created in `cases/` and `reports/` subfolders under the root shared link
- Supabase `disruption_incidents` row created and status transitions
- Supabase `action_tasks` row created on approval
- Slack notification sent (supplementary)
- Outlook task assignment email sent

## Step 8 — Go Live

1. Confirm all 8 operators + 1 rule + 1 orchestrator are saved and published
2. Run a full end-to-end test with a real Outlook email
3. Verify human reviewer receives the Supervity native form
4. Verify the reviewer can pause/resume the workflow
5. Verify completion triggers the closeout report
6. Monitor the first 5 live runs in the Auto Manager Console

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Operator not found in orchestrator | Name mismatch | Check exact name in Auto App vs saved operator name |
| Supabase query returns 0 rows | Missing table or wrong table name | Verify table name in Supabase; update prompt if needed |
| Human Review form not appearing | is_human_input_step not enabled | Edit operator → enable Human Review step |
| Slack notification not sent | Wrong channel name or token expired | Check `PROCUREMENT_SLACK_CHANNEL` env var and Slack integration |
| Outlook cannot read folder | Missing Mail.Read permission | Check Azure App Registration permissions |
| Rules engine returns unexpected route | Rule order wrong | Reorder rules: hard overrides first, then score-based |
| Timeout but no escalation | Missing timeout handler | Configure On Timeout action in Human Review operator |
| Parallel branch fails | Partial data | Check flag output — flow should continue with available data |
| `action_tasks` table does not exist | Step 1 not run | Run `supabase-action-tasks.sql` in Supabase SQL Editor |

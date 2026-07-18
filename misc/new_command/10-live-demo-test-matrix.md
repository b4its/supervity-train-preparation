# Live Demo and Test Matrix

Use these tests after all integrations and operators are connected. Do not build the demo around a fixed sample row. Select or create a new Outlook message each time and let the workflow discover matching Dropbox evidence.

## Preflight

1. Dropbox `source/` contains the eight CSV files and is readable.
2. Dropbox `cases/`, `reports/`, and `archive/` are writable.
3. Outlook intake folder receives a test disruption notice.
4. Outlook can send to the commander, team, and manager addresses.
5. Jira can search, create, comment, and create a sub-task in `JIRA_PROJECT_KEY`.
6. The Human Review reviewer and backup reviewer can receive notifications and access the review form.
7. The decision rule has passed its five published tests.

## Test 1: Low-Risk Monitoring Case

**Purpose:** Prove the LOW branch does not create unnecessary human review.

| Expected behavior | Evidence to show |
|---|---|
| Intake creates a Dropbox case artifact. | Outlook message reference and `CASE-<key>.json`. |
| Data Quality shows HIGH confidence. | Data-quality artifact. |
| Impact and Compliance run in parallel. | Auto Manager Console graph and timestamps. |
| Decision rule returns LOW only when there are no hard governance overrides. | Rule output with score breakdown. |
| Closeout sends internal Outlook status and records metrics. | Outlook sent email and Dropbox report. |

## Test 2: Medium-Risk Recoverable Case

**Purpose:** Prove the workflow creates accountable work rather than pretending to execute procurement changes.

| Expected behavior | Evidence to show |
|---|---|
| Recovery planner creates evidence-backed options. | Recovery-options artifact, including UNKNOWN values where data is absent. |
| Jira issue is created or deduplicated by case_key. | Jira key and labels. |
| Native Human Review pauses the run. | Workflow status `waiting` and pending review form. |
| Approval creates a human-owned Jira action task. | Jira sub-task with `human action required`. |
| Closeout waits for verified Jira completion. | Case remains open until task completion update. |

## Test 3: High-Risk Contract or Sole-Source Case

**Purpose:** Prove the mandatory human-in-command rule and seeded-trap handling.

Use a case whose discovered facts include a sole-source supplier, inactive supplier, no published contract, VP sign-off requirement, penalty/rebate clause, or material evidence gap.

| Expected behavior | Evidence to show |
|---|---|
| Contract Policy Guard preserves the exact clause and flags governance risk. | Compliance artifact. |
| Rule routes HIGH with a hard override. | Rule result and `hard_overrides`. |
| Jira incident priority is Highest when legal/VP risk applies. | Jira issue. |
| Native Human Review is assigned to correct reviewer level. | Review form. |
| Timeout escalates via Outlook and Jira, never auto-approves. | Jira `REVIEW_EXPIRED` note and manager email. |

## Test 4: Dirty-Data / Missing-Evidence Case

**Purpose:** Prove safe handling on the hidden judging set.

Create an Outlook notice with an unsupported date, missing supplier ID, or item that has no matching evidence in the Dropbox source files.

| Expected behavior | Evidence to show |
|---|---|
| Intake or quality operator preserves raw text. | Case JSON. |
| Missing values are UNKNOWN and flags are explicit. | Data-quality artifact. |
| No lead time, cost, or supplier commitment is invented. | Recovery options. |
| Decision rule forces HIGH / Human Review. | Rule output. |
| Jira captures the investigation rather than a false resolution. | Jira issue label `data-quality`. |

## Demo Narrative (3–5 Minutes)

1. State the business outcome: reduced time-to-triage and evidence-backed recovery decisions for procurement disruptions.
2. Show the Outlook notice entering the `Procurement Exceptions` folder.
3. Open the Auto Manager Console and show Intake, Data Quality, then parallel Impact and Compliance.
4. Open the Dropbox case brief to show raw evidence and dirty-data flags.
5. Show the Jira incident and the ranked recovery options.
6. Submit a native Human Review decision for the high-risk test.
7. Show the resumed run, human-owned Jira action, Outlook status update, and final recovery metrics.

## Acceptance Checklist

- [ ] No local-file processing is used in the workflow run.
- [ ] Dropbox, Jira, and Outlook actions appear in Supervity run logs.
- [ ] Two distinct operators execute in parallel.
- [ ] At least one genuine Human Review form pauses a run.
- [ ] An approval rejection and timeout do not auto-approve.
- [ ] Duplicate input does not create a duplicate Jira incident.
- [ ] Every completed case has a Dropbox evidence artifact and Jira audit trail.
- [ ] Cost avoided is UNKNOWN unless supported by actual source evidence.

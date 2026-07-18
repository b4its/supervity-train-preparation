# Analysis and Proof of Fit

## Materials Reviewed

This pack was designed after reviewing:

- `ProblemStatement__Procurement_Exception_Commander.pdf`
- `misc/Autopilot_Asia_Hackathon_Round1_Handbook.pdf`
- `misc/Supervity Auto Cheatsheet.pdf`
- The Supervity documentation at `https://auto.supervity.ai/docs`, including platform concepts, operators, workflows, integrations, schedules, Human Review, security, troubleshooting, rules, workflow runs, user forms, and APIs.
- Every CSV under `operations/dataset/csv/`, including `00_INDEX.csv` and `Field_Dictionary.csv`.
- The earlier `misc/call_command/` pack and its Supabase SQL schema.

## Problem Requirement to Design Mapping

| Official requirement | New-command implementation | Evidence file |
|---|---|---|
| AI Employee handles disruptions from impact through corrective action | Seven focused operators coordinated by one commander. | `08-procurement-exception-commander.md` |
| Orchestrator coordinates at least two distinct operators | Seven distinct operators; intake, data quality, impact, policy, recovery, approval/Jira, and closeout. | `README.md` |
| Parallel, branching, or stateful behavior | Impact Mapper and Contract Policy Guard run in parallel; LOW/MEDIUM/HIGH routes branch; `case_key` is a stateful idempotency key. | `08-procurement-exception-commander.md` |
| Three live integrations across categories | Outlook channel, Dropbox file store, Jira work system. | `integrations/` |
| Live exception to a human | Native Supervity Human Review pauses the run and Outlook sends the review notification. | `06-human-approval-and-jira.md` |
| Handle messy data and record mismatches | Dedicated Data Quality Steward with raw preservation, quoted CSV parsing, normalized dates, ID joins, and explicit UNKNOWN values. | `02-dropbox-data-quality-steward.md` |
| Do not hardcode to sample data | Header-based discovery, configurable policy inputs, no sample record IDs or names in operational rules. | `09-ai-policy-rules.md` |
| Real quantified output | Direct line value at risk, broader PO exposure, time-to-triage, time-to-decision, time-to-recovery, and supported avoidable-cost estimate. | `03-impact-mapper.md`, `07-closeout-reporter.md` |
| Configurable logic without code | Versioned Supervity decision-rule prompt with thresholds and five test scenarios. | `09-ai-policy-rules.md` |

## Why the Old Pack Was Not Reused

The previous `call_command` workflow is not suitable for the requested Dropbox, Jira, and Outlook stack:

| Old assumption | Why it is a problem | New treatment |
|---|---|---|
| Supabase is the system of record | Supabase is no longer one of the requested integrations. | Dropbox stores raw and generated evidence; Jira stores operational incident/action state. |
| Slack buttons are the approval system | A chat message is not Supervity's native pause/resume Human Review governance primitive. | Native Human Review form is mandatory for material decisions; Outlook only notifies the reviewer. |
| Operators automatically update POs or trigger supplier action | The permitted integrations do not expose Coupa or another procurement execution system. Claiming execution would be false. | Jira creates a human-owned procurement action task after approval. |
| Cost avoided equals full PO value | PO header value and line value can overlap, creating double counting. | Direct line exposure is reported separately; avoidable cost is UNKNOWN unless a supported lower alternative cost exists. |
| Inventory transfer cost is zero and lead time is two days | Neither claim is in the dataset. | Options are evidence-backed proposals with UNKNOWN operational values where no data exists. |

## Dirty Data Evidence and Controls

| Observed data characteristic | Risk | Required control in new pack |
|---|---|---|
| Dates appear as ISO timestamps, `DD/MM/YYYY`, and `Mon DD YYYY` | Wrong due-date or delay comparison | Parse only the three known formats, preserve raw text, flag `DATE_UNPARSED`. |
| CSV fields include commas inside quoted message and contract text | Naive split corrupts clauses and notices | Use quoted CSV parsing, discover fields by headers. |
| Supplier names have double/trailing whitespace and duplicate-looking organization names | Incorrect supplier match | Join only by `supplier_id`; names are display fields. |
| Supplier statuses include inactive suppliers; two suppliers are sole-source | Unsafe recovery proposal | Contract Policy Guard raises mandatory Human Review. |
| Contracts include published and expired records; one has VP sign-off and one has penalty text | Illegal or costly expedite recommendation | Separate active versus expired contracts, preserve exact clause text, route legal/VP risk to review. |
| PO/line/confirmation lifecycle fields use different status vocabularies | Incorrect exposure count | Impact Mapper treats header, line, and confirmation states separately. |
| Demand data does not prove a daily cadence | Unsupported stock-cover calculation | Report demand pressure but leave stock-cover UNKNOWN without a defensible denominator. |
| The judging dataset is hidden and may differ | Sample-specific logic fails | Configurable rule table and header/ID-driven processing. |

## Native Human Review Proof

The documentation specifies that a Human Review step pauses a workflow, generates a review form with context, and resumes only after a submitted decision. The new design therefore uses `is_human_input_step` in `06-human-approval-and-jira.md`.

This matters because the Operations brief requires a genuine human exception. The workflow cannot treat an Outlook reply, Jira update, or timeout as implicit approval. On timeout, it escalates but does not auto-approve.

## No-Fabrication Policy

The new pack intentionally refuses to invent:

- supplier capacity or alternate supplier lead time;
- internal transfer route, cost, or delivery date;
- a PO change, expedite, inventory movement, or supplier communication;
- actual realized savings;
- facts missing from a CSV row or integration response.

Instead it writes an evidence-backed recovery proposal and creates a Jira task assigned to a human procurement owner after approval. This produces a defensible, enterprise-grade workflow rather than a staged demo.

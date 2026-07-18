# Five-File Submission Instructions

## Goal

The full `new_command/` directory is a build and audit pack. If the submission platform accepts a maximum of **five files**, do not upload all prompt, setup, analysis, and test files separately.

Submit five consolidated Markdown documents that preserve the required Supervity architecture:

1. Integration and data setup
2. Intake and data-quality operator
3. Parallel impact and compliance operators
4. Recovery policy, Human Review, and Jira execution
5. Commander orchestrator, test plan, and demo evidence

This keeps the submission within the limit while retaining the mandatory Orchestrator, multiple distinct Operators, three live integrations, parallelism, branching, native Human Review, retries, escalation, and outcome metrics.

## Recommended Five Files

| Submission file | Combine from the detailed pack | Why it belongs together |
|---|---|---|
| `01-integration-and-data-setup.md` | `integrations/dropbox/00-setup.md`, `integrations/jira/00-setup.md`, `integrations/microsoft-outlook/00-setup.md`, `integrations/supabase/00-setup.md`, `integrations/slack/00-setup.md`, `integrations/supabase/schema.sql` | All integration prerequisites plus the database schema. |
| `02-data-loader-and-intake.md` | `00-supabase-data-loader.md`, `01-outlook-disruption-intake.md`, `02-dropbox-data-quality-steward.md` | Data Loader fills reference tables; intake and quality validate each case against Supabase. |
| `03-parallel-impact-and-compliance.md` | `03-impact-mapper.md`, `04-contract-policy-guard.md` | Separate Operators that execute in parallel after validation. |
| `04-recovery-policy-approval-and-jira.md` | `05-recovery-planner.md`, `06-human-approval-and-jira.md`, `09-ai-policy-rules.md` | Decision-making, configurable routing, Human Review, and accountable execution. |
| `05-commander-test-and-demo.md` | `08-procurement-exception-commander.md`, `07-closeout-reporter.md`, `10-live-demo-test-matrix.md` | Final orchestration, closeout, test evidence, and demo sequence. |

## Do Not Submit Separately

Keep these files locally as supporting evidence, but do not spend one of the five submission slots on them unless the submission specifically requests documentation:

```text
README.md
00-analysis-and-proof.md
11-five-file-submission-instructions.md
```

Their contents are already represented in the five consolidated submission files.

## Important: Do Not Upload the Old Pack

Do not submit files from `misc/call_command/`. That directory is preserved as historical reference with a different architecture (Slack buttons for approval, no Dropbox file store, no Outlook channel). Use only content derived from `misc/new_command/`.

## Required Content Checklist for the Five Files

Before uploading, ensure that the five consolidated files still explicitly contain all of the following:

- [ ] Dropbox is the live source-data and evidence repository.
- [ ] Microsoft Outlook is the disruption intake and notification channel.
- [ ] Jira is the live incident and human-action work system.
- [ ] Supabase is the case-state machine for lifecycle tracking.
- [ ] Slack is the supplementary notification and alert channel.
- [ ] The workflow has at least two distinct Operators, not one mega-agent.
- [ ] `Procurement Impact Mapper` and `Contract Policy Guard` run in parallel.
- [ ] Data joins use IDs, not supplier names.
- [ ] Mixed date formats, quoted CSV fields, empty fields, and missing records are handled safely.
- [ ] Unknown facts are represented as `UNKNOWN`; the workflow never invents lead times, costs, capacity, or delivery confirmation.
- [ ] LOW, MEDIUM, and HIGH routes are configurable through a Supervity decision rule.
- [ ] HIGH and material MEDIUM cases use a native Supervity Human Review step.
- [ ] The Human Review step pauses the run and resumes only after a form decision.
- [ ] Approval timeout escalates through Outlook and Jira; it never auto-approves.
- [ ] Jira creates a human-owned procurement task rather than claiming an unsupported PO amendment or supplier action.
- [ ] Results quantify direct line value at risk, time-to-triage, time-to-decision, time-to-recovery, and supported avoidable cost.
- [ ] The final Commander prompt calls the individual Operators by their saved names.

## Recommended Submission Order

Upload the files in this sequence if the portal preserves ordering:

```text
1. 01-integration-and-data-setup.md
2. 02-intake-and-data-quality.md
3. 03-parallel-impact-and-compliance.md
4. 04-recovery-policy-approval-and-jira.md
5. 05-commander-test-and-demo.md
```

## How to Build Versus How to Submit

| Activity | Use |
|---|---|
| Build each Supervity Operator | The detailed operator prompts in `01` through `07`, then `09`, then `08`. |
| Configure integrations | The five detailed setup files under `integrations/`. |
| Test and record evidence | `10-live-demo-test-matrix.md`. |
| Upload under a five-file limit | The five consolidated documents listed above. |

Do not try to build one giant Supervity Operator just because the submission has a five-file limit. The limit applies to submitted artifacts, not to the internal Operator architecture. The final Auto App must still contain multiple distinct Operators (eight including the Data Loader) coordinated by the Commander Orchestrator.

## Next Step

Create the five consolidated files from the source prompts listed above, preserving the operator names and architecture. If the submission portal accepts Markdown attachments, upload those five files. If it only accepts text fields, paste the five documents in order and include the Operator URL separately.

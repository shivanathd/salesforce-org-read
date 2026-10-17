---
name: org-read
description: Read a Salesforce org without changing it and write a one-page note on unused licences, stale flows, failing tests and risky automation, with a finish, review or rebuild outcome per area and the evidence behind it. Use when someone asks whether their Salesforce org is worth finishing, what is wrong with it, for an org health check, or for a partner handover read.
---

# Org read

Read-only. Never create, update, delete or deploy anything in the org, and never run Apex tests: report the last test run that already exists. Only run the commands this skill names: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> <check>`, `python3 -I "${CLAUDE_PLUGIN_ROOT}/scripts/summarise.py" <check>`, `sf data query`, `sf org list`, `sf sobject describe`. Never run `sf org display`: it prints the access token.

## 1. Pick the path
- **CLI path** (needed for the full read): the user's `sf` CLI is logged in to the org (`sf org list` shows it). Run each check as its own command, exactly in this form:
  `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> <check>`
  Pipe the output to `python3 -I "${CLAUDE_PLUGIN_ROOT}/scripts/summarise.py" <check>` to get each query's status and row count.
- **Hosted path**: the `salesforce-sobject-reads` MCP server is connected. Use its SOQL query tool for the objects it accepts. It may not reach Tooling API objects (ApexTrigger, WorkflowRule, coverage, Health Check); use the CLI for those.
- If neither works, use the `org-connect` skill.

## 2. Confirm the org
Run the `org` check first (CLI) and the same SOQL through the hosted tool: `SELECT Id, Name, IsSandbox, OrganizationType FROM Organization`. The two paths sign in separately and can reach different orgs. Only combine results when both return the same Id. If they differ, use one path and say which. Put the Org Id, name and sandbox flag in the note header.

## 3. Run the checks
Keep a summary of 20 lines or fewer per area.

| Area | Check names |
| --- | --- |
| Licences | `licences` (user licences, permission set licences, active seats with no login in 90 days) |
| Flows | `flows`, `workflow` |
| Risky automation | `triggers`, compared with record-triggered flows on the same object |
| Tests | `tests`, `async-failures` |
| Legacy metadata versions | `legacy-versions` |
| Security | `security`, `admin-sprawl` |
| Access model | `permission-debt` |
| Integrations and packages | `integrations`, `packages` |
| Limits | `limits` |
| Inventory | `inventory` (one line in the note) |

For a partner handover or takeover, also run `handover` and `fields`. Report counts only: what changed in the last 90 days, flows with no description, classes and triggers under 75% line coverage (from ApexCodeCoverageAggregate), custom fields per object and fields with no description. Never list who changed what.

## 4. Read every result
- Each query prints its own JSON. A document with `"status": 0` worked; anything else failed. Never infer a finding from a failed or missing query.
- A check where a query failed is **Unassessed** for that part. Give the error name (for example `INSUFFICIENT_ACCESS`, `INVALID_TYPE`). The script exits 1 when any query failed.
- If a query returns 200 rows (2000 for `fields`), the list was cut. Say "200 or more", not an exact total.

## 5. Wording rules
- Every finding carries Evidence (check name and count), Confidence (high, medium or low) and an outcome from the `verdict` skill.
  - High: a count read straight from the org. Medium: a capped list, a partial check, or a comparison across objects. Low: a value that may not mean what it shows (for example coverage 0%).
- Name the object each finding came from.
- Never say a flow "never runs". Salesforce has no general last-run record. Say "inactive", "out of date" or "not changed since <date>".
- The `workflow` check shows which Workflow Rules exist, not whether they are active. Say "exist".
- In `flows`, the second query lists Process Builder processes (`ProcessType` in Workflow, CustomEvent, InvocableProcess). Count them separately from Flows.
- Workflow Rules, Process Builder, inactive flows, and a trigger plus a flow on the same object are **migration or review candidates**. They do not prove duplication or that removal is safe. Write "candidate to cut, confirm with the owner": the plugin cannot check dependencies or business use.
- Record-triggered flows on one object: flag only flows with no TriggerOrder, or two flows with the same TriggerOrder. Gaps such as 10, 20, 30 are normal; Salesforce recommends them.
- Coverage: report ApexOrgWideCoverage as it reads. If it is 0% while a completed test run exists, add that coverage may not have been aggregated, and suggest running all tests once. Do not assert either way.
- Legacy metadata versions: Apex on API 30 or lower is old metadata, and 31 to 44 is below 45. These are review items. Salesforce's API 21 to 30 retirement applies to API calls made with those versions, not to the version Apex is saved on, so never say this code breaks. The plugin cannot see which integrations call old API versions; Event Monitoring (API Total Usage) shows that. Salesforce's ICU locale guidance asks for Apex and Visualforce that format dates, numbers or currencies to be on API 45.0 or later.
- Licences: the inactive-seat count leaves out frozen users and integration licences. Users who never logged in count as inactive.
- Admin sprawl: report how many active users have Modify All Data through a profile, and how many through a permission set.
- Limits: report DataStorageMB, FileStorageMB, DailyApiRequests, SingleEmail and HourlyPublishedPlatformEvents first, as used of max. Mention others only if over 80% used.
- No partner claims, no prices, no urgency.

## 6. Write the note
Fill the template at `${CLAUDE_PLUGIN_ROOT}/templates/note.md`, then apply the `verdict` skill. Keep the template's last section: the short brief the owner can send and the link to https://mindcat.ai/contact/org-stuck.

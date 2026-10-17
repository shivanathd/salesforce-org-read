---
name: org-read
description: Read a Salesforce org without changing it and write a one-page note on unused licences, stale flows, failing tests and risky automation, ending with a finish, cut or rebuild verdict. Use when someone asks whether their Salesforce org is worth finishing, what is wrong with it, or for an org health check.
---

# Org read

Read-only. Never create, update, delete or deploy anything in the org, and never run Apex tests: report the last test run that already exists. Only run the commands this skill names: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> <check>`, `sf data query`, `sf org list`, `sf sobject describe`. Never run `sf org display`.

## 1. Pick the path
- **Hosted path**: the `salesforce-sobject-reads` MCP server is connected. Use its SOQL query tool for the record and setup objects it accepts. It may not reach Tooling API objects (`ApexOrgWideCoverage`, `WorkflowRule`, `ApexClass`, `ApexTrigger`, `InstalledSubscriberPackage`, Security Health Check) or org limits, so a full read needs the CLI path.
- **CLI path**: the user's `sf` CLI is logged in to the org (`sf org list` shows it). Run each check as its own command, exactly in this form:
  `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> <check>`
  Exit code 3 means `sf` is not installed: use the `org-connect` skill.
- Use both when both work. If a hosted query fails on a setup object, use the CLI for that check and say so in the note.
- If neither works, use the `org-connect` skill.

## 2. Confirm it is one org
The hosted server and the CLI sign in separately and can point at different orgs.
1. On every path you use, run the `org` check first: on the CLI path `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> org`; on the hosted path the same query through its SOQL tool: `SELECT Id, Name, OrganizationType, IsSandbox FROM Organization`.
2. If both paths ran and the Ids differ, stop. Do not combine the results. Tell the user which path points at which org (sandbox or production, last 4 characters of each Id) and ask which one to read.
3. Stamp the note with the last 4 characters of the org Id, sandbox or production (`IsSandbox`), and the path or paths used. Never print the org name in the "Brief you can paste".

## 3. Run the checks
Keep a summary of 20 lines or fewer per area.

| Area | Check names |
| --- | --- |
| (stamp only) | `org` |
| Licences | `licences` |
| Flows | `flows`, `workflow` |
| Risky automation | `triggers`, compared with record-triggered flows on the same object in `flows` |
| Tests | `tests` |
| Legacy metadata versions | `old-code` |
| Security | `security`, `admins`, `permissions` |
| Integrations | `integrations`, `packages` |
| Background jobs | `async` |
| Limits | `limits` |

## 4. Unassessed areas
An area is **unassessed** when its queries failed, were denied (for example the user lacks "View Setup and Configuration"), or are not available on the path used and no other path ran them. An unassessed area gets no finish, cut or rebuild verdict and no invented numbers. Write "unassessed" and the reason (the error code or "not reachable on the hosted path"). If only some of an area's queries ran, score it on what ran and lower its confidence.

## 5. Evidence and confidence
For every finding, note the evidence: the check and object it came from, the row count, and the path used (hosted or CLI). Give each area a confidence:
- **High**: all its queries ran and none hit the 200-row cap.
- **Medium**: a list hit the 200-row cap, or one of its queries failed.
- **Low**: the finding rests on a comparison or reading the user should confirm (for example, a trigger and a flow on one object).

## 6. Wording rules
- Name the object each finding came from.
- Never say a flow "never runs". Salesforce has no general last-run record. Say "inactive", "out of date" or "not changed since <date>".
- The `workflow` check shows which Workflow Rules exist, not whether they are active. Say "exist".
- In `flows`, `ProcessType` values `Workflow`, `CustomEvent` and `InvocableProcess` are Process Builders, not Flows. Count Process Builders separately from Flows and from Workflow Rules.
- Managed-package flows: a flow whose `ApiName` contains `__` has a namespace prefix and belongs to an installed package. The owner cannot change it. Leave it out of the inactive and out-of-date counts, and say how many were left out.
- Coverage: if `ApexOrgWideCoverage` reads 0 while Apex classes and a completed test run exist, keep the reported value and qualify it: "reported 0%; coverage may not have been recorded". Suggest running all tests once. (Seen in a scratch org on 17 Oct 2026.) Do not score a reported 0% as a Rebuild signal in that case.
- Legacy metadata versions (`old-code`): say "Apex saved on API version 30 or lower". Salesforce's retirement of API versions 21 to 30 (Summer '25, Help article 000389618) stops API calls made on those versions; it does not stop Apex classes or triggers saved at them. Call this tech debt to review, never "retired code" and never a reason to rebuild.
- The note must also say: "Integrations still calling API versions 21 to 30 are not checked by this read; finding them needs Event Log data."
- Licences: the count is active users with no login in 90 days. Integration or API-only users and frozen users can show here although they are in use or already handled. Present the number as "to review", not "unused" or "wasted".
- Admins: the profile count and the permission-set count can include the same user twice. Say "up to <sum> users with Modify All Data".
- Permissions: the permission-set count includes sets from installed packages. Say so.
- Licences also lists permission set licences (`PermissionSetLicense`): report used against total, "to review".
- Integrations: list Named Credentials and Connected Apps that exist, as an inventory "to review". A listed connected app does not prove it holds tokens or is in use; never say it is "connected" or "active". Installed packages (`packages`) are listed by name and version, "to review" whether each is still used.
- Background jobs (`async`): counts of Apex jobs from the last 7 days by type and status. Report job types with `Failed` or `Aborted` status, or with errors, as "to review". Seven days is a short window; say so.
- Limits: from the `limits` output, report only data storage (`DataStorageMB`), file storage (`FileStorageMB`), daily API requests (`DailyApiRequests`), single email (`SingleEmail`) and hourly published platform events (`HourlyPublishedPlatformEvents`), as used of max. Ignore the other limits. If one of these names is missing from the output, say so; do not substitute another.
- Two Apex triggers on the same object, or the same `TriggerOrder` on two record-triggered flows on the same object and trigger type, are review items: "check the run order". Gaps in `TriggerOrder` numbers are normal (Salesforce suggests spacing like 10, 20, 30); never report them.
- If a query returns 200 rows, the list was cut at 200. Say "200 or more", not an exact total.
- No partner claims, no prices, no urgency.

## 7. Write the note
Fill the template at `${CLAUDE_PLUGIN_ROOT}/templates/note.md`, then apply the `verdict` skill. State how many areas were unassessed. Fill the "Brief you can paste" with counts and verdicts only: no org name, no user names, no record data. Keep the template's last line, the link to https://mindcat.ai/contact/org-stuck.

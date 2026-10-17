---
name: org-read
description: Read a Salesforce org without changing it and write a one-page note on unused licences, stale flows, failing tests and risky automation, ending with a finish, cut or rebuild verdict. Use when someone asks whether their Salesforce org is worth finishing, what is wrong with it, or for an org health check.
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" *)
---

# Org read

## 0. Ground rules (every skill in this plugin follows these)
- Read-only. Never create, update, delete or deploy anything in the org, and never run Apex tests: report the last test run that already exists. Only run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> <check> [object]`, `sf data query`, `sf org list` and `sf sobject describe`. Never run `sf org display`: it prints the access token.
- Pick the path and confirm the org (sections 1 and 2) before any other check.
- A query that fails, is denied or cannot run on the path used makes its part **unassessed** (section 4). Never guess its numbers.
- Give every finding its evidence and a confidence (section 5).
- If a list returns exactly its `LIMIT` in rows (200, 500 or 2000), it was cut there: say "<limit> or more", never an exact total.
- Managed-package flows: a flow with a `NamespacePrefix` (or an `ApiName` containing `__`) belongs to an installed package and the owner cannot change it. Leave it out of the owner's counts and say how many were left out.
- Shareable output (the "Brief you can paste", anything "to paste" or "to share") holds counts and verdicts only: no org name, no user names, no record data. The owner's own output may name metadata (classes, flows, objects), never record data.
- No prices, no partner claims, no urgency.

## 1. Pick the path
- **Hosted path**: the `salesforce-sobject-reads` MCP server is connected. Run the same SOQL the script runs for a check (`q` lines in `scripts/org-read-cli.sh`) through its SOQL query tool. Tooling API queries (`qt` lines: coverage, Workflow Rules, Apex versions, installed packages, Health Check) and `limits` may not run there, so a full read needs the CLI path.
- **CLI path**: the user's `sf` CLI is logged in to the org (`sf org list` shows it). Run each check as its own command, exactly in this form:
  `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> <check>`
  Exit code 3 means `sf` is not installed: use the `org-connect` skill.
- Use both when both work. If a hosted query fails on a setup object, use the CLI for that check and say so in the note.
- If neither works, use the `org-connect` skill.

## 2. Confirm it is one org
The hosted server and the CLI sign in separately and can point at different orgs.
1. On every path you use, run the `org` check first: on the CLI path `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> org`; on the hosted path the same query through its SOQL tool: `SELECT Id, Name, OrganizationType, IsSandbox FROM Organization`.
2. If both paths ran and the Ids differ, stop. Do not combine the results. Tell the user which path points at which org (sandbox or production, last 4 characters of each Id) and ask which one to read.
3. Stamp the output with the last 4 characters of the org Id, sandbox or production (`IsSandbox`), and the path or paths used.

## 3. Run the checks
Keep a summary of 20 lines or fewer per area.

| Area | Check names |
| --- | --- |
| (stamp only) | `org` |
| Licences | `licences` |
| Flows | `flows`, `workflow` |
| Risky automation | `triggers` (Apex triggers and record-triggered flows, by object) |
| Tests | `tests` |
| Legacy metadata versions | `old-code` |
| Security | `security`, `admins`, `permissions` |
| Integrations | `integrations`, `packages` |
| Background jobs | `async` |
| Limits | `limits` |

Checks used by the other skills (not part of the one-page note):

| Skill | Check names |
| --- | --- |
| `renewal-prep` | `licences`, `renewal` |
| `handover-audit` | `recent-changes`, `flow-descriptions`, `class-coverage` |
| `release-readiness` | `api-45`, `old-code`, `flows`, `workflow` |
| `object-read` | `object`, `object-code` (take an object API name or DurableId) |
| `field-usage` | `fields`, `field-descriptions` (takes an object API name) |
| `agent-readiness` | `permissions`, `triggers`, `workflow`, `flows`, `field-descriptions` |
| `org-book` | `inventory`, `fields`, `flows`, `workflow`, `packages`, `integrations` |

## 4. Unassessed areas
An area is **unassessed** when its queries failed, were denied (for example the user lacks "View Setup and Configuration"), or are not available on the path used and no other path ran them. An unassessed area gets no finish, cut or rebuild verdict and no invented numbers. Write "unassessed" and the reason (the error code or "not reachable on the hosted path"). If only some of an area's queries ran, the missing ones are not evidence of anything. Name the checks that failed. Partial evidence is enough only when what did run already meets a rule on its own: two Rebuild signals, or a Cut candidate. Then score the area on that, mark confidence medium, and say what was not read. Otherwise the area is unassessed, and any findings from the queries that ran are listed as review items. A Finish needs all of the area's queries to have run.
- Example: if the Health Check queries (`security`) are denied, Security cannot reach two Rebuild signals from `admins` alone, so Security is unassessed: "Security unassessed: SecurityHealthCheck and SecurityHealthCheckRisks denied". Still list the admin and permission counts as review items.

## 5. Evidence and confidence
For every finding, note the evidence: the check and object it came from, the row count, and the path used (hosted or CLI). Give each area a confidence:
- **High**: all its queries ran and none hit its `LIMIT`.
- **Medium**: a list hit its `LIMIT`, or one of its queries failed.
- **Low**: the finding rests on a comparison or reading the user should confirm (for example, a trigger and a flow on one object).

## 6. Wording rules
- Name the object each finding came from.
- Never say a flow "never runs". Salesforce has no general last-run record. Say "inactive", "out of date" or "not changed since <date>".
- The `workflow` check shows which Workflow Rules exist, not whether they are active. Say "exist".
- In `flows`, `ProcessType` values `Workflow`, `CustomEvent` and `InvocableProcess` are Process Builders, not Flows. Count Process Builders separately from Flows and from Workflow Rules.
- Coverage: if `ApexOrgWideCoverage` reads 0 while Apex classes and a completed test run exist, keep the reported value and qualify it: "reported 0%; coverage may not have been recorded". Suggest running all tests once. Do not score a reported 0% as a Rebuild signal in that case.
- Legacy metadata versions (`old-code`): say "Apex saved on API version 30 or lower". Salesforce's retirement of API versions 21 to 30 (Summer '25, Help article 000389618) stops API calls made on those versions; it does not stop Apex classes or triggers saved at them. Call this tech debt to review, never "retired code" and never a reason to rebuild. Keep the template's "Not checked" line on integrations calling those versions.
- Licences: the count is active users with no login in 90 days. Integration or API-only users and frozen users can show here although they are in use or already handled. Present the number as "to review", not "unused" or "wasted". Free licences (Chatter Free, Chatter External, Guest User) are not paid seats: report them separately and leave them out of the count to review. Permission set licences (`PermissionSetLicense`): report used against total, "to review".
- Admins: the first `admins` query returns one row per distinct active user with Modify All Data, whether it comes from their profile (a profile is stored as a permission set) or from a permission set. Count its rows: that is the number the verdict rule uses. The other two queries are the breakdown (by profile, by permission set) and can include the same user twice. If the first query failed, use the profile count alone for the rule (each user has one profile, so it counts distinct users) and say "at least <n>"; never add the two breakdown counts together.
- Matching triggers to flows by object: an Apex trigger's `TableEnumOrId` is the object name for a standard object and an Id for a custom object. Match it to a flow's `TriggerObjectOrEventId`, or for standard objects to `TriggerObjectOrEvent.QualifiedApiName`. If that flow query failed, you may match the `flows` output's `TriggerObjectOrEventLabel` (a label, not an API name) only for standard objects whose label you are sure of, and mark the match low confidence.
- Permissions: the counts are custom profiles and your own custom permission sets; standard and managed-package permission sets are left out. Say so.
- Integrations: list Named Credentials and Connected Apps that exist, as an inventory "to review". A listed connected app does not prove it holds tokens or is in use; never say it is "connected" or "active". Installed packages (`packages`) are listed by name and version, "to review" whether each is still used.
- Background jobs (`async`): counts of Apex jobs from the last 7 days by type and status. Report job types with `Failed` or `Aborted` status, or with errors, as "to review". Seven days is a short window; say so.
- Limits: from the `limits` output, report only data storage (`DataStorageMB`), file storage (`FileStorageMB`), daily API requests (`DailyApiRequests`), single email (`SingleEmail`) and hourly published platform events (`HourlyPublishedPlatformEvents`), as used of max. Ignore the other limits. If one of these names is missing from the output, say so; do not substitute another.
- Two Apex triggers on the same object, or the same `TriggerOrder` on two record-triggered flows on the same object and trigger type, are review items: "check the run order". Gaps in `TriggerOrder` numbers are normal (Salesforce suggests spacing like 10, 20, 30); never report them.

## 7. Write the note
Fill the template at `${CLAUDE_PLUGIN_ROOT}/templates/note.md`, then apply the `verdict` skill. State how many areas were unassessed. Keep the "Brief you can paste" to counts and verdicts (section 0). Keep the template's last line, the link to https://mindcat.ai/contact/org-stuck.

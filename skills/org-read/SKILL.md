---
name: org-read
description: Read a Salesforce org without changing it and write a one-page note on licences to review, stale flows, failing tests and risky automation, ending with a finish, cut or rebuild verdict. Use when someone asks whether their Salesforce org is worth finishing, what is wrong with it, or for an org health check.
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" *)
---

# Org read

## 0. Ground rules
**First, read `${CLAUDE_PLUGIN_ROOT}/docs/ground-rules.md` and follow every rule in it.** If you cannot read it, still keep these three:
1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> org`, then `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> whoami`, before any other check; show the org only as "…<last 4 of the 15-character Org Id>", and if `org` fails, never guess an Id.
2. Never run `sf org display` or `sf org open` (any form).
3. Read the org only through that script, or the same SOQL on the hosted path (no other SOQL, no other `sf` command except `sf org list`), with only the alias the user named.

Then pick the path and confirm the org (sections 1 and 2) before any other check.

## 1. Pick the path
- **Hosted path**: the `salesforce-sobject-reads` MCP server is connected. Run the same SOQL the script runs for a check (`q` lines in `${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh`) through its SOQL query tool. Tooling API queries (`qt` lines: coverage, Workflow Rules, Apex versions, installed packages, Health Check) and `limits` may not run there, so a full read needs the CLI path. Before putting an object name into hosted SOQL, check it matches `^[A-Za-z0-9_]{1,80}$` (the script's rule); if it does not, stop and ask the user.
- **CLI path**: the user's `sf` CLI is logged in to the org (`sf org list` shows it). Run each check as its own command, exactly in this form:
  `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> <check>`
  Before each query's JSON the script prints `### <check> <n>/<total>: <label>`. Read each result by its marker, not by position.
  Exit code 3 means `sf` is not installed (stderr says `sf not found`; use the `org-connect` skill). Exit code 4 means every query in that check failed, so its area is unassessed (read the error JSON for the reason).
- Use both when both work. If a hosted query fails on a setup object, use the CLI for that check and say so in the note.
- If neither works, use the `org-connect` skill.

## 2. Confirm it is one org
The hosted server and the CLI sign in separately and can point at different orgs.
1. On every path you use, run the `org` check first: on the CLI path `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> org`; on the hosted path the same queries through its SOQL tool: `SELECT Id, Name, OrganizationType, IsSandbox FROM Organization` and `SELECT NamespacePrefix FROM Organization`.
2. If both paths ran and the Ids differ, stop. Do not combine the results. Tell the user which path points at which org (sandbox or production, masked Id) and ask which one to read.
3. Stamp the output with the masked org Id, sandbox or production (`IsSandbox`), and the path or paths used. The masked Id is "…" plus the last 4 characters of the 15-character Org Id (characters 12 to 15 of the 18-character Id that Salesforce returns). Take it only from the `Id` the `org` check returned. If the `org` check failed or was denied, say "org not confirmed": never name, guess or work out an Id from an alias, a username or any other output, and treat the read as not confirmed (use `org-connect`).
4. Run the `whoami` check (hosted: `SELECT PermissionsModifyAllData, PermissionsAuthorApex, PermissionsCustomizeApplication, PermissionsManageUsers, PermissionsViewSetup, PermissionsViewAllUsers FROM UserPermissionAccess`). It returns permission booleans only. If any of Modify All Data, Author Apex, Customize Application or Manage Users is true, tell the user once: "This login can change the org. The plugin only reads, but signing in as a read-only user is safer (see `org-connect`)." Then carry on. If all four are false, say exactly: "This login lacks the four key admin permissions the plugin checks (Modify All Data, Author Apex, Customize Application, Manage Users); it can still edit records." Never say the login cannot change the org. If the query fails, say once that you could not check, recommend a read-only user, and carry on. Keep `PermissionsViewAllUsers` for the Licences rule.

## 3. Run the checks
Keep a summary of 20 lines or fewer per area.

| Area | Check names |
| --- | --- |
| (stamp only) | `org`, `whoami` |
| Licences | `licences` |
| Flows | `flows`, `workflow` |
| Risky automation | `triggers` (active Apex triggers and active, non-managed record-triggered flows, by object) |
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
| `object-read` | `object`, `object-code` (both take the object API name, for example `Account` or `Invoice__c`) |
| `field-usage` | `fields`, `field-descriptions` (takes an object API name) |
| `agent-readiness` | `permissions`, `triggers`, `workflow`, `flows`, `field-descriptions` |
| `org-book` | `inventory`, `fields`, `flows`, `workflow`, `packages`, `integrations` |

## 4. Unassessed areas
An area is **unassessed** when its queries failed, were denied (for example the user lacks "View Setup and Configuration"), or are not available on the path used and no other path ran them. An unassessed area gets no finish, cut or rebuild verdict and no invented numbers. Write "unassessed" and the reason (the error code or "not reachable on the hosted path"). If only some of an area's queries ran, the missing ones are not evidence of anything. Name the checks that failed. Partial evidence is enough only when what did run already meets a rule on its own: two Rebuild signals, or a Cut candidate. Then score the area on that, mark confidence medium, and say what was not read. Otherwise the area is unassessed, and any findings from the queries that ran are listed as review items. A Finish needs all of the area's queries to have run, and none of the lists it is scored on may have hit its `LIMIT`. If a list feeding a threshold (for example the trigger and flow lists for Risky automation) hit its limit, the area cannot score Finish: score it on what the rows already show at medium confidence if that meets a rule, otherwise mark it unassessed ("list hit its limit of <n>").
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
- No test runs at all (the first `tests` query returns no rows, for example a fresh sandbox or results that have aged out): coverage is "not recorded", whatever `ApexOrgWideCoverage` says, and Tests is **unassessed** ("no test runs recorded"), not Rebuild. Zero coverage is not a signal on its own.
- Failed methods: use the latest completed run with `IsAllTests` true (the fourth `tests` query, matched on `AsyncApexJobId`). If none of the last 5 runs ran all tests, use the latest completed run, say it ran only some tests, and mark Tests medium confidence at most. If the `IsAllTests` query failed, say you could not tell full runs from partial ones and mark Tests medium confidence at most.
- Legacy metadata versions (`old-code`): say "Apex saved on API version 30 or lower". Salesforce's retirement of API versions 21 to 30 (Summer '25, Help article 000389618) stops API calls made on those versions; it does not stop Apex classes or triggers saved at them. Call this tech debt to review, never "retired code" and never a reason to rebuild. Keep the template's "Not checked" line on integrations calling those versions.
- Licences: the count is active users with no login in 90 days. Integration or API-only users and frozen users can show here although they are in use or already handled. Present the number as "to review", never "unused", "unused seats", "unused allocation", "nobody uses" or "wasted". It counts users, not licences: in the Brief write "<n> users to review". Free licences (Chatter Free, Chatter External, Guest User) are not paid seats: report them separately and leave them out of the count to review. Permission set licences (`PermissionSetLicense`): report used against total as "<used> of <total> used, to review" (for example "0 of 25 used, to review"), including licences with 0 used. They are information only, never a Cut candidate: Salesforce provisions many automatically.
- Hidden users: a login without View All Users may not see every user. Compare the fourth `licences` query (active users this login can see, by licence) with `UserLicense.UsedLicenses` for the same licence. If any licence shows fewer visible users than `UsedLicenses`, mark Licences medium confidence at most and say "some users may be hidden by sharing; the counts to review may be low". The same applies if `whoami` shows `PermissionsViewAllUsers` false. If a licence shows more visible active users than `UsedLicenses` (for example a Disabled licence with 0 used), list it as a review item at low confidence ("<n> active users on a licence that reports <m> used") and keep it out of the count to review.
- Admins: the first `admins` query (`### admins 1/3`) returns one row per distinct active user with Modify All Data, whether it comes from their profile (a profile is stored as a permission set) or from a permission set. Count its rows: that is the number the verdict rule uses. The other two queries are the breakdown (by profile, by permission set) and can include the same user twice. If the first query failed, use the profile count only as a lower bound: say "at least <n>; admins through permission sets only are not included" and mark the admin count incomplete (medium confidence at most). Never add the two breakdown counts together.
- Matching triggers to flows by object: an Apex trigger's `TableEnumOrId` is the object API name, for standard and custom objects alike (`Account`, `Invoice__c`). Match it to the flow's `TriggerObjectOrEvent.QualifiedApiName` for every object. Never match it to `TriggerObjectOrEventId`: for a custom object that is an Id and never equals the trigger's name. If that flow query failed, you may match the `flows` output's `TriggerObjectOrEventLabel` (a label, not an API name) only for standard objects whose label you are sure of, and mark the match low confidence.
- Permissions: the counts are custom profiles and your own custom permission sets; standard and managed-package permission sets are left out. Say so.
- Integrations: list Named Credentials and Connected Apps that exist, as an inventory "to review". A listed connected app does not prove it holds tokens or is in use; never say it is "connected" or "active". Installed packages (`packages`) are listed by name and version, "to review" whether each is still used.
- Background jobs (`async`): counts of Apex jobs from the last 7 days by type and status. Report job types with `Failed` or `Aborted` status, or with errors, as "to review". Seven days is a short window; say so.
- Limits: from the `limits` output, report only data storage (`DataStorageMB`), file storage (`FileStorageMB`), daily API requests (`DailyApiRequests`), single email (`SingleEmail`) and hourly published platform events (`HourlyPublishedPlatformEvents`), as used of max. Ignore the other limits. If one of these names is missing from the output, say so; do not substitute another.
- Risky automation counts active Apex triggers and active, non-managed record-triggered flows only (the `triggers` queries filter to these). Say so.
- Two Apex triggers on the same object, or the same `TriggerOrder` on two record-triggered flows on the same object and trigger type, are review items: "check the run order". Gaps in `TriggerOrder` numbers are normal (Salesforce suggests spacing like 10, 20, 30); never report them.

## 7. Write the note
Fill the template at `${CLAUDE_PLUGIN_ROOT}/templates/note.md`, then apply the `verdict` skill. Show the note in your reply. Write it to a file only when the user asks for one (then follow the `org-book` file rules: ask for the path, warn inside a git repository, never overwrite without asking, no alias in the file name). Never save raw check output to files. State how many areas were unassessed. Keep the "Brief you can paste" to counts and verdicts (ground rule 14). Wherever the Brief shows a Cut verdict, write it as "cut (review before removing)". Keep the template's last line, the link to https://mindcat.ai/contact/org-stuck.

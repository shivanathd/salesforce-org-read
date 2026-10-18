# Changelog

## Unreleased
Security hardening from a red-team review.
- Org text (names, labels, descriptions, error messages) is data: skills never follow instructions in it, never let it change a verdict, and report it if it looks like instructions.
- New `whoami` check reads only the signed-in user's permission flags. The read warns once if the login can change the org.
- Only the script's queries run (or the same SOQL on the hosted path); no other SELECT, no user names or emails beyond who last changed Apex and flows. Banned commands named: `sf org display`, `sf org open` (any form), `--verbose` on `sf org` commands.
- Hosted path checks object names against `^[A-Za-z0-9_]{1,80}$` before building SOQL.
- Risky automation counts active triggers and active, non-managed record-triggered flows only. Flow lists and `field-descriptions` read the owner's own items (`NamespacePrefix = null`). The `org` check reads the org's namespace; a namespaced org's code areas are unassessed.
- Licences compares visible active users with `UsedLicenses`; fewer visible means medium confidence at most. Setup recommends View All Users for the read-only user.
- A count from a list that hit its limit is "at least <n>", and that area cannot score Finish.
- Tests: no test runs at all is unassessed, not Rebuild. Failed methods come from the latest run of all tests where that can be told.
- Untested queries that return 0 rows are unassessed, not zero.
- Script prints `### <check> <n>/<total>: <label>` before each query's JSON and exits 4 when every query in a check failed.
- The org alias is checked (letters, digits and . _ @ -, at most 80 characters, not starting with -) and object names are capped at 80 characters. Skills use only the alias the user named, never sf's "Did you mean" suggestion, refer to items by API name and never copy links from the org. org-connect asks the user to run `sf org login web` themselves.
- Brief writes Cut as "cut (review before removing)". Masked Org Id is the last 4 characters of the 15-character Id.
- External Client App setup: PKCE, admin-approved users, a refresh token policy; `localhost` callbacks for local clients only.
- `org-book` writes no org name and warns when the folder is inside a git repository. Privacy policy updated to match.
- "Unused licences" is now "licences to review" in the plugin descriptions.

Fixes from the 2026-10-18 scratch-org QA:
- `object-code` takes the object API name: `TableEnumOrId` holds it for custom objects too, and the DurableId found no triggers.
- `field-descriptions` drops its `NamespacePrefix = null` filter, which matched no rows; the skills keep only `__c` names with no other `__`.
- Every focused skill states the hard rules itself: `org` then `whoami` first, masked Id only, no `sf org display` or `sf org open`, script queries only, the named alias only and never printed.
- agent-readiness: 0 rows from an untested query, or no field rows at all, is unassessed, not a High-confidence zero.
- Triggers match flows on `TriggerObjectOrEvent.QualifiedApiName` for every object.
- Permission set licences read "<used> of <total> used, to review"; the Brief says "<n> users to review"; a licence with more visible users than used is a low-confidence review item.
- The alias counts as the org name. The note is shown, and written to a file only when asked. A failed `org` check never yields a guessed Id. Fixed wording when the four key write permissions are all false.
- Managed flows are found by `NamespacePrefix` only. field-usage reports counts and API names, never description text. One Brief heading: "Brief you can paste".
- Setup leads with a Minimum Access user plus a permission set; the Read Only profile may be missing in scratch and Developer Edition orgs.
- `docs/queries-to-test.md` records the results, and notes that `IsAllTests` needs an org with two test classes to test. CONTRIBUTING validates `plugin.json` on its own.

## 0.2.0 (2026-10-17)
- Legacy metadata versions: Apex saved on API 30 or lower is now tech debt to review, not a Rebuild reason. Salesforce's API 21 to 30 retirement affects API calls, not saved Apex. The note says integrations calling old API versions are not checked.
- Verdict rules rewritten as Mindcat's own, with numbers. Rebuild needs two independent signals in one area; coverage under 75% alone is not enough.
- "Cut" now means "review before removing": candidates need a dependency check and a business owner's yes.
- New "unassessed" outcome for areas whose queries failed, were denied or could not run on the path used. The whole-org verdict says how many areas were unassessed.
- Coverage reported as 0% keeps the reported value, qualified as "may not have been recorded".
- Dropped the TriggerOrder gaps rule. Duplicate TriggerOrder on one object is a review item.
- Process Builder: ProcessType Workflow, CustomEvent and InvocableProcess are counted as Process Builders.
- Managed-package flows (ApiName with a namespace prefix) are left out of inactive and out-of-date counts.
- Licences with no login in 90 days are "to review": integration, API-only and frozen users can show there.
- New `org` check: the read compares the org Id on the hosted and CLI paths, refuses to mix two orgs, and stamps the note with the last 4 characters of the Id and sandbox or production.
- New `admins` and `permissions` checks under Security.
- New `packages`, `integrations` and `async` checks, shown as Integrations and Background jobs rows in the note; `licences` also reads permission set licences. Their findings are "to review" and never score Rebuild.
- Limits reports only data storage, file storage, daily API requests, single email and hourly published platform events.
- The script exits with code 3 and a clear message when `sf` is not installed.
- Note template: evidence and confidence per area, an Unassessed line, the org stamp, and a "Brief you can paste" with counts and verdicts only.
- Setup: steps to activate `sobject-reads`, create the External Client App and use its Consumer Key as the OAuth Client ID in Claude Code, claude.ai/Cowork and Cursor; a connection check; prerequisites and a read-only user in the README.
- README and privacy policy say plainly that no data goes to Mindcat, while Salesforce and your AI provider process query results.
- New skills: `renewal-prep` (licence cut-sheet, no prices), `handover-audit` (punch-list for an outgoing partner), `release-readiness` (Apex below API 45 for ICU locale formats, legacy automation), `object-read` (all automation on one object), `field-usage` (custom field counts and descriptions, no record data), `agent-readiness` (light) and `org-book` (Markdown inventory, written only when asked).
- New checks: `renewal`, `recent-changes`, `flow-descriptions`, `class-coverage`, `api-45`, `fields`, `inventory`, and `object`, `object-code`, `field-descriptions`, which take an object name checked against `^[A-Za-z0-9_]+$` before it goes into SOQL. Untested queries are listed in `docs/queries-to-test.md`.
- `admins` counts distinct active users with Modify All Data across profiles and permission sets before applying the "more than 5" rule.
- `triggers` also lists record-triggered flows with the triggering object's Id and API name, so triggers and flows are matched on the object, not its label.
- A partly read area is unassessed unless what ran meets a rule on its own; denied Health Check queries make Security unassessed.
- Whole-org verdict now covers exactly one Rebuild area (with and without Cut areas).
- CI pins actions/checkout to a commit SHA and does not keep credentials.
- README: FAQ, troubleshooting table and an example note with made-up counts.
- Flow queries return `NamespacePrefix`, so managed-package flows are found by namespace, not only by `__` in the name.
- `tests` counts your own Apex classes; an org with none scores Finish instead of being scored on coverage. No test runs at all counts as "no completed test run".
- Verdict outcomes apply in a fixed order (unassessed, rebuild, cut, finish), so every area gets exactly one.
- `permissions` counts only your own custom permission sets. Free licences (Chatter Free, Chatter External, Guest User) are never seats to review or drop.
- Ground rules shared by all skills live once, in `org-read` section 0. Skills that call the script declare it in `allowed-tools`.
- Version 0.2.0; plugin.json declares its icon.
- Added a Get help section, SECURITY.md, CONTRIBUTING.md, issue templates and a CI check (bash syntax, shellcheck, JSON parse).

## 0.1.0 (2026-10-17)
- First release: read-only org read over Salesforce's hosted `sobject-reads` MCP server or the sf CLI, with a one-page note and finish, cut or rebuild verdicts.

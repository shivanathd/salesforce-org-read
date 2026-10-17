# Changelog

## Unreleased

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

# Changelog

## Unreleased
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
- The script exits with code 3 and a clear message when `sf` is not installed.
- Note template: evidence and confidence per area, an Unassessed line, the org stamp, and a "Brief you can paste" with counts and verdicts only.
- Setup: steps to activate `sobject-reads`, create the External Client App and use its Consumer Key as the OAuth Client ID in Claude Code, claude.ai/Cowork and Cursor; a connection check; prerequisites and a read-only user in the README.
- README and privacy policy say plainly that no data goes to Mindcat, while Salesforce and your AI provider process query results.
- Added a Get help section, SECURITY.md, issue templates and a CI check (bash syntax, shellcheck, JSON parse).

## 0.1.0 (2026-10-17)
- First release: read-only org read over Salesforce's hosted `sobject-reads` MCP server or the sf CLI, with a one-page note and finish, cut or rebuild verdicts.

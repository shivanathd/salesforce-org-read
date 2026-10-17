---
name: renewal-prep
description: Read a Salesforce org's licence use before a contract renewal and write a short cut-sheet of seats the owner could drop per licence type. Use when someone asks how many Salesforce licences they actually use, or is preparing for a Salesforce renewal.
---

# Renewal prep

Read-only, same rules as the `org-read` skill (CLI path, never `sf org display`). Run the `org` check first and put the Org Id and name at the top.

Run:
- `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> licences`: user licences (total and used), permission set licences, active seats with no login in 90 days.
- `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> renewal`: active seats with no login in 60 and in 90 days, per licence.

Check each JSON `status`; a failed query is Unassessed with its error name.

Write the cut-sheet as one table:

| Licence | Total | Used | No login 60 days | No login 90 days | Seats you could drop |
| --- | --- | --- | --- | --- | --- |

- Seats you could drop = (Total minus Used) plus the 90-day count. Show the sum; the owner decides.
- Add permission set licences with Total above 0 as a second table: Total, Used, unused.
- The counts leave out frozen users and integration licences. Users who never logged in count as inactive.
- Say these are candidates: confirm with each user's manager before removing anyone, since some users log in rarely by design.
- No prices. Leave a Price column blank for the owner if they ask for one.

End with the link https://mindcat.ai/contact/org-stuck if they want help with the renewal.

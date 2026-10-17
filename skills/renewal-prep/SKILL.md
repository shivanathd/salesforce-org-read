---
name: renewal-prep
description: Build a read-only Salesforce licence cut-sheet before a contract renewal - seats per licence, users who have not logged in for 60 or 90 days, and permission set licences - so the owner can decide which seats to drop or reassign. Use when someone is preparing for a Salesforce renewal or asks how many licences they really need.
---

# Renewal prep

## Ground rules
- Read-only. Only run the commands the `org-read` skill allows. Never run `sf org display`.
- Pick the path and confirm the org exactly as in the `org-read` skill (sections 1 and 2): run the `org` check on every path used, refuse to combine results from two different org Ids, and stamp the output with the last 4 characters of the org Id and sandbox or production.
- A query that fails, is denied or cannot run on the path used makes its part **unassessed**. Say which part and why; never guess its numbers.
- For each finding give the evidence (check, object, row count, path) and a confidence (high, medium, low), as defined in the `org-read` skill.
- If a list returns exactly its `LIMIT` in rows, say "<limit> or more".
- Shareable output (anything labelled "to paste" or "to share") holds counts and verdicts only: no org name, no user names, no record data. The owner's own output may name metadata (classes, flows, objects) but never record data.
- No prices, no partner claims, no urgency.

## Checks
- `licences`: user licences (total, used), permission set licences (total, used), and active users with no login in 90 days, by licence.
- `renewal`: active users with no login in 60 days, by licence.

Run each as `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> <check>`.

## Wording rules
- Never give or estimate prices or savings. Talk in seats.
- A user with no recent login is a seat **to review**, not a wasted seat: integration or API-only users, frozen users and people on leave can show here. Say so once.
- "Drop" means the seat may not be needed at renewal; "reassign" means a seat held by an inactive user could go to a new joiner instead of buying another. Both need the business owner's yes.
- Permission set licences: report used against total. Fewer than half used is "to review".

## Output: cut-sheet
| Licence | Total | Used | No login 60 days | No login 90 days | Suggestion (to review) |
| --- | --- | --- | --- | --- | --- |

Then: "Seats to review before renewal: <n> (60 days) / <n> (90 days)". Under it, a 2-line "Brief to paste" with the counts only.

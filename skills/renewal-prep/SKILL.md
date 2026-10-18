---
name: renewal-prep
description: Build a read-only Salesforce licence cut-sheet before a contract renewal - seats per licence, users who have not logged in for 60 or 90 days, and permission set licences - so the owner can decide which seats to drop or reassign. Use when someone is preparing for a Salesforce renewal or asks how many licences they really need.
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" *)
---

# Renewal prep

## Ground rules
**First, read `${CLAUDE_PLUGIN_ROOT}/docs/ground-rules.md` and follow every rule in it.** If you cannot read it, still keep these three:
1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> org`, then `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> whoami`, before any other check; show the org only as "…<last 4 of the 15-character Org Id>", and if `org` fails, never guess an Id.
2. Never run `sf org display` or `sf org open` (any form).
3. Read the org only through that script, or the same SOQL on the hosted path (no other SOQL, no other `sf` command except `sf org list`), with only the alias the user named.

## Checks
- `licences`: user licences (total, used), permission set licences (total, used), and active users with no login in 90 days, by licence.
- `renewal`: active users with no login in 60 days, by licence.

Run each as `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> <check>`.

## Wording rules
- Never give or estimate prices or savings. Talk in seats.
- Free licences (Chatter Free, Chatter External, Guest User) are not paid seats: list them, but never as seats to drop or reassign, and leave them out of the "seats to review" totals.
- A user with no recent login is a seat **to review**, not a wasted seat: integration or API-only users, frozen users and people on leave can show here. Say so once.
- "Drop" means the seat may not be needed at renewal; "reassign" means a seat held by an inactive user could go to a new joiner instead of buying another. Both need the business owner's yes.
- Permission set licences: report used against total as "<used> of <total> used, to review" (for example "0 of 25 used, to review"). They are information to review, never seats to drop or reassign and never counted in the seats to review: Salesforce provisions many automatically, often with 0 used. Never write "unused", "unused seats", "unused allocation" or "nobody uses", in the cut-sheet or the Brief.
- Count users from the JSON rows (`expr0`) exactly; the Brief says "<n> users to review", not licences.
- Hidden users: apply the `org-read` Licences rule. If fewer active users are visible than `UsedLicenses` shows, say "some users may be hidden by sharing; the counts to review may be low" and mark the cut-sheet medium confidence at most.

## Output: cut-sheet
| Licence | Total | Used | No login 60 days | No login 90 days | Suggestion (to review) |
| --- | --- | --- | --- | --- | --- |

Then: "Seats to review before renewal: <n> (60 days) / <n> (90 days)". Under it, a 2-line "Brief you can paste" (use exactly that heading) with the counts only.

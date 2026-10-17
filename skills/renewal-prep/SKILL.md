---
name: renewal-prep
description: Build a read-only Salesforce licence cut-sheet before a contract renewal - seats per licence, users who have not logged in for 60 or 90 days, and permission set licences - so the owner can decide which seats to drop or reassign. Use when someone is preparing for a Salesforce renewal or asks how many licences they really need.
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" *)
---

# Renewal prep

## Ground rules
Follow the `org-read` skill's ground rules (section 0) and run its path choice and org check (sections 1 and 2) first. They cover read-only commands, unassessed parts, evidence and confidence, row caps, managed-package flows and what shareable output may hold.

## Checks
- `licences`: user licences (total, used), permission set licences (total, used), and active users with no login in 90 days, by licence.
- `renewal`: active users with no login in 60 days, by licence.

Run each as `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> <check>`.

## Wording rules
- Never give or estimate prices or savings. Talk in seats.
- Free licences (Chatter Free, Chatter External, Guest User) are not paid seats: list them, but never as seats to drop or reassign, and leave them out of the "seats to review" totals.
- A user with no recent login is a seat **to review**, not a wasted seat: integration or API-only users, frozen users and people on leave can show here. Say so once.
- "Drop" means the seat may not be needed at renewal; "reassign" means a seat held by an inactive user could go to a new joiner instead of buying another. Both need the business owner's yes.
- Permission set licences: report used against total. Fewer than half used is "to review".

## Output: cut-sheet
| Licence | Total | Used | No login 60 days | No login 90 days | Suggestion (to review) |
| --- | --- | --- | --- | --- | --- |

Then: "Seats to review before renewal: <n> (60 days) / <n> (90 days)". Under it, a 2-line "Brief to paste" with the counts only.

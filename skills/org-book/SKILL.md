---
name: org-book
description: Write a Markdown inventory of a Salesforce org (counts of custom objects, custom fields, flows, Apex, installed packages and integrations) to a file, only when the user asks for an org book, inventory file or export. Read-only in the org.
---

# Org book

## Ground rules
- Read-only. Only run the commands the `org-read` skill allows. Never run `sf org display`.
- Pick the path and confirm the org exactly as in the `org-read` skill (sections 1 and 2): run the `org` check on every path used, refuse to combine results from two different org Ids, and stamp the output with the last 4 characters of the org Id and sandbox or production.
- A query that fails, is denied or cannot run on the path used makes its part **unassessed**. Say which part and why; never guess its numbers.
- For each finding give the evidence (check, object, row count, path) and a confidence (high, medium, low), as defined in the `org-read` skill.
- If a list returns exactly its `LIMIT` in rows, say "<limit> or more".
- Shareable output (anything labelled "to paste" or "to share") holds counts and verdicts only: no org name, no user names, no record data. The owner's own output may name metadata (classes, flows, objects) but never record data.
- No prices, no partner claims, no urgency.

## When
Only when the user asks for an org book, inventory or export file. Never write a file otherwise. Ask where to save it if they have not said; default to `org-book-<YYYY-MM-DD>.md` in the current folder. Tell the user the path after writing it. If a file with that name exists, ask before overwriting.

## Checks
- `inventory`: counts of Apex classes, Apex triggers and custom objects.
- `fields`: custom fields per object.
- `flows`, `workflow`: flows by type, Process Builders, Workflow Rules.
- `packages`: installed packages (name, version).
- `integrations`: Named Credentials and Connected Apps that exist.

Run each as `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> <check>`.

## Wording rules
- Counts, plus metadata names where the user asked for lists (packages, Named Credentials, Connected Apps). Never record data, never user names.
- A listed Connected App does not prove it holds tokens or is in use.
- Flow counts come from a list capped at 200: say "200 or more" if it hit the cap. Leave managed-package flows out of your own counts and give their number separately.
- Mark any section whose query failed as "unassessed" with the reason.

## File layout
```
# Org book, <date>
Org: …<last 4 of org Id>, <sandbox | production>, <edition>. Read via <path>. Read-only: nothing in the org was changed.

## Counts
| Item | Count | Evidence |
| --- | --- | --- |
| Custom objects | | |
| Custom fields | | |
| Flows (yours / managed) | | |
| Process Builders | | |
| Workflow Rules (exist) | | |
| Apex classes | | |
| Apex triggers | | |
| Installed packages | | |
| Named Credentials | | |
| Connected Apps (listed) | | |

## Installed packages
## Integrations
## Unassessed
```

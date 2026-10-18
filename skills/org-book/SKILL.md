---
name: org-book
description: Write a Markdown inventory of a Salesforce org (counts of custom objects, custom fields, flows, Apex, installed packages and integrations) to a file, only when the user asks for an org book, inventory file or export. Read-only in the org.
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" *)
---

# Org book

## Ground rules
**First, read `${CLAUDE_PLUGIN_ROOT}/docs/ground-rules.md` and follow every rule in it.** If you cannot read it, still keep these three:
1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> org`, then `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> whoami`, before any other check; show the org only as "…<last 4 of the 15-character Org Id>", and if `org` fails, never guess an Id.
2. Never run `sf org display` or `sf org open` (any form).
3. Read the org only through that script, or the same SOQL on the hosted path (no other SOQL, no other `sf` command except `sf org list`), with only the alias the user named.

## When
Only when the user asks for an org book, inventory or export file. Never write a file otherwise. Ask where to save it if they have not said; default to `org-book-<YYYY-MM-DD>.md` in the current folder. If the folder is inside a git repository (it or a parent folder has a `.git` folder or a `.git` file, as linked worktrees do), warn the user before writing that the file could get committed, and offer a folder outside the repo. Tell the user the path after writing it. If a file with that name exists, ask before overwriting.

## Checks
- `inventory`: counts of Apex classes and Apex triggers, and the custom object list. Count custom objects as the rows of the `custom objects (count the rows)` result whose API name ends in `__c` with no other `__` (it already leaves out custom settings, metadata types, platform events, big and external objects). Its source ignores `LIMIT`, so the count is exact.
- `fields`: custom fields per object (match Ids as the `field-usage` skill says).
- `flows`, `workflow`: flows by type, Process Builders, Workflow Rules (ground rule 16).
- `packages`: installed packages (name, version).
- `integrations`: Named Credentials and Connected Apps that exist.

Run each as `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> <check>`.

## Wording rules
- Counts, plus metadata names where the user asked for lists (packages, Named Credentials, Connected Apps). Never record data, never user names, never the org name, the org alias or the username (the alias counts as the org name, also in the file name and the "Read via" line): identify the org only by the masked Id. Write "Read via sf CLI" or "hosted MCP", nothing more.
- A listed Connected App does not prove it holds tokens or is in use.

## File layout
```
# Org book, <date>
Org: …<last 4 characters of the 15-character org Id>, <sandbox | production>, <edition>. Read via <path>. Read-only: nothing in the org was changed.

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

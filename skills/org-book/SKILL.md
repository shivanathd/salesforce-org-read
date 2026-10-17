---
name: org-book
description: Write a Markdown inventory of a Salesforce org (counts of custom objects, custom fields, flows, Apex, installed packages and integrations) to a file, only when the user asks for an org book, inventory file or export. Read-only in the org.
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" *)
---

# Org book

## Ground rules
Follow the `org-read` skill's ground rules (section 0) and run its path choice and org check (sections 1 and 2) first. They cover read-only commands, unassessed parts, evidence and confidence, row caps, managed-package flows and what shareable output may hold.

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

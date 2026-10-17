---
name: object-read
description: Read-only view of all automation on one Salesforce object - Apex triggers, record-triggered flows with their run order, Workflow Rules, and the active validation rule count. Takes the object API name (for example Account or Invoice__c). Use when someone asks what runs when a record of one object is saved.
---

# Object read

## Ground rules
- Read-only. Only run the commands the `org-read` skill allows. Never run `sf org display`.
- Pick the path and confirm the org exactly as in the `org-read` skill (sections 1 and 2): run the `org` check on every path used, refuse to combine results from two different org Ids, and stamp the output with the last 4 characters of the org Id and sandbox or production.
- A query that fails, is denied or cannot run on the path used makes its part **unassessed**. Say which part and why; never guess its numbers.
- For each finding give the evidence (check, object, row count, path) and a confidence (high, medium, low), as defined in the `org-read` skill.
- If a list returns exactly its `LIMIT` in rows, say "<limit> or more".
- Shareable output (anything labelled "to paste" or "to share") holds counts and verdicts only: no org name, no user names, no record data. The owner's own output may name metadata (classes, flows, objects) but never record data.
- No prices, no partner claims, no urgency.

## Input
The object's API name, for example `Account` or `Invoice__c`. It must contain only letters, digits and underscores; the script refuses anything else. Ask the user if the name is unclear; never guess a custom object's suffix.

## Checks
1. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> object <ApiName>`: the object's EntityDefinition `DurableId`, its validation rules, and flows it triggers.
2. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> object-code <DurableId>`: Apex triggers and Workflow Rules on the object. Use the `DurableId` from step 1 (for a standard object this is usually its name, for a custom object an Id; pass it exactly as returned). If step 1 returned no row, the object name is wrong or not visible to this user: stop and say so.

## Wording rules
- Validation rules: report the count of active ones (`Active = true`) and the total. Do not print their formulas or messages.
- Record-triggered flows: list each with `TriggerType`, `RecordTriggerType` and `TriggerOrder`. Two flows with the same `TriggerOrder` and trigger type are a review item: "check the run order". Gaps in the numbers are normal. Leave managed-package flows (`ApiName` containing `__`) out, and say how many.
- Two or more Apex triggers on the object, or triggers and record-triggered flows together, are review items, not proof of overlap.
- Workflow Rules: say "exist", not "active".

## Output
| Automation | Count | Detail | Evidence | Confidence |
| --- | --- | --- | --- | --- |
| Apex triggers | | | | |
| Record-triggered flows | | name, type, run order | | |
| Workflow Rules (exist) | | | | |
| Validation rules (active / total) | | | | |

Then a 1-line "Brief to paste" with the counts only (the object API name may appear; no records).

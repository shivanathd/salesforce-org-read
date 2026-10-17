---
name: object-read
description: Read-only view of all automation on one Salesforce object - Apex triggers, record-triggered flows with their run order, Workflow Rules, and the active validation rule count. Takes the object API name (for example Account or Invoice__c). Use when someone asks what runs when a record of one object is saved.
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" *)
---

# Object read

## Ground rules
Follow the `org-read` skill's ground rules (section 0) and run its path choice and org check (sections 1 and 2) first. They cover read-only commands, unassessed parts, evidence and confidence, row caps, managed-package flows and what shareable output may hold.

## Input
The object's API name, for example `Account` or `Invoice__c`. It must contain only letters, digits and underscores; the script refuses anything else. Ask the user if the name is unclear; never guess a custom object's suffix.

## Checks
1. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> object <ApiName>`: the object's EntityDefinition `DurableId`, its validation rules, and flows it triggers.
2. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> object-code <DurableId>`: Apex triggers and Workflow Rules on the object. Use the `DurableId` from step 1 (for a standard object this is usually its name, for a custom object an Id; pass it exactly as returned). If step 1 returned no row, the object name is wrong or not visible to this user: stop and say so.

## Wording rules
- Validation rules: report the count of active ones (`Active = true`) and the total. Do not print their formulas or messages.
- Record-triggered flows: list each with `TriggerType`, `RecordTriggerType` and `TriggerOrder`. Two flows with the same `TriggerOrder` and trigger type are a review item: "check the run order". Gaps in the numbers are normal. Leave managed-package flows out, and say how many.
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

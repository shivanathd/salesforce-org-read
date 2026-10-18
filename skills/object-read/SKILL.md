---
name: object-read
description: Read-only view of all automation on one Salesforce object - Apex triggers, record-triggered flows with their run order, Workflow Rules, and the active validation rule count. Takes the object API name (for example Account or Invoice__c). Use when someone asks what runs when a record of one object is saved.
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" *)
---

# Object read

## Ground rules
**First, read `${CLAUDE_PLUGIN_ROOT}/docs/ground-rules.md` and follow every rule in it.** If you cannot read it, still keep these three:
1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> org`, then `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> whoami`, before any other check; show the org only as "…<last 4 of the 15-character Org Id>", and if `org` fails, never guess an Id.
2. Never run `sf org display` or `sf org open` (any form).
3. Read the org only through that script, or the same SOQL on the hosted path (no other SOQL, no other `sf` command), with only the alias the user named.

## Input
The object's API name, for example `Account` or `Invoice__c`. It must contain only letters, digits and underscores (`^[A-Za-z0-9_]{1,80}$`); the script refuses anything else, and on the hosted path check the name against the same rule before building any SOQL with it. Ask the user if the name is unclear; never guess a custom object's suffix.

## Checks
1. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> object <ApiName>`: confirms the object exists (its EntityDefinition row), its validation rules, and the record-triggered flows on it. If the first query returned no row, the object name is wrong or not visible to this user: stop and say so.
2. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> object-code <ApiName>`: Apex triggers (active and inactive) and Workflow Rules on the object. Pass the same object API name as in step 1 (for example `Invoice__c`), never the `DurableId`: `TableEnumOrId` holds the API name for standard and custom objects, and a custom object's Id finds nothing.

Check `${CLAUDE_PLUGIN_ROOT}/docs/queries-to-test.md`: a query there with no Result is untested, and 0 rows from it is **unassessed**, not zero. The `object-code` Workflow Rule query is untested on a custom object, so 0 Workflow Rules from it is "unassessed (query not yet tested)", never "none".

## Wording rules
- Validation rules: report the count of active ones (`Active = true`) and the total. Do not print their formulas or messages.
- Record-triggered flows: list each with `TriggerType`, `RecordTriggerType` and `TriggerOrder`. Two flows with the same `TriggerOrder` and trigger type are a review item: "check the run order". Gaps in the numbers are normal. Leave managed-package flows out, and say how many.
- Process Builders: they do not fill `TriggerObjectOrEvent`, so the `object` check cannot find them by object. Mark Process Builders on this object **unassessed** ("Process Builders cannot be listed by object"), never "0" or "none". If the user wants context, run the `flows` check and give the org-wide count of Process Builders (ground rule 16), saying it is org-wide, not for this object. Any Process Builder rows the `object` check does return are still listed.
- Apex triggers: count active ones (`Status` `Active`) and list inactive ones separately. Two or more active triggers on the object, or active triggers and active record-triggered flows together, are review items, not proof of overlap.

## Output
| Automation | Count | Detail | Evidence | Confidence |
| --- | --- | --- | --- | --- |
| Apex triggers | | | | |
| Record-triggered flows | | name, type, run order | | |
| Process Builders | unassessed | cannot be listed by object; org-wide count from `flows` if run | | |
| Workflow Rules (exist) | | | | |
| Validation rules (active / total) | | | | |

Then a 1-line "Brief you can paste" (use exactly that heading) with the counts only (the object API name may appear; no records).

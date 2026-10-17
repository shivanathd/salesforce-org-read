---
name: field-usage
description: Light, read-only count of custom fields per Salesforce object and of fields with no description on chosen objects. Never samples record data. Use when someone asks how many custom fields an org has, which objects are crowded, or how well fields are documented.
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" *)
---

# Field usage (light)

## Ground rules
Follow the `org-read` skill's ground rules (section 0) and run its path choice and org check (sections 1 and 2) first. They cover read-only commands, unassessed parts, evidence and confidence, row caps, managed-package flows and what shareable output may hold.

## Checks
- `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> fields`: custom fields per object (your own, not managed-package fields), plus custom object Ids and names to read the result by.
- `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> field-descriptions <ApiName>`: each field on one object and its description. Run it for at most 5 objects: the ones the user names, or else the 5 with the most custom fields.

## Wording rules
- This skill counts fields. It never reads records, so it cannot say whether a field is filled in or used. Say "fields defined", never "unused fields".
- In `fields`, custom objects show as Ids; match them to the `CustomObject` list (`DeveloperName` + `__c`). Unmatched Ids: count them as "other objects".
- In `field-descriptions`, count only your own custom fields: names that end in `__c` and contain no other `__` (a second `__` means a package namespace). Standard fields rarely carry an admin description; leave them out.
- Report description fill rate as "<n> of <m> custom fields have a description".

## Output
| Object | Custom fields | With description (if read) | Evidence | Confidence |
| --- | --- | --- | --- | --- |

Then a 1-line "Brief to paste" with totals only.

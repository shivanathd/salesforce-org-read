---
name: field-usage
description: Light, read-only count of custom fields per Salesforce object and of fields with no description on chosen objects. Never samples record data. Use when someone asks how many custom fields an org has, which objects are crowded, or how well fields are documented.
---

# Field usage (light)

## Ground rules
- Read-only. Only run the commands the `org-read` skill allows. Never run `sf org display`.
- Pick the path and confirm the org exactly as in the `org-read` skill (sections 1 and 2): run the `org` check on every path used, refuse to combine results from two different org Ids, and stamp the output with the last 4 characters of the org Id and sandbox or production.
- A query that fails, is denied or cannot run on the path used makes its part **unassessed**. Say which part and why; never guess its numbers.
- For each finding give the evidence (check, object, row count, path) and a confidence (high, medium, low), as defined in the `org-read` skill.
- If a list returns exactly its `LIMIT` in rows, say "<limit> or more".
- Shareable output (anything labelled "to paste" or "to share") holds counts and verdicts only: no org name, no user names, no record data. The owner's own output may name metadata (classes, flows, objects) but never record data.
- No prices, no partner claims, no urgency.

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

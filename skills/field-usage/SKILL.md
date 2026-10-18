---
name: field-usage
description: Light, read-only count of custom fields per Salesforce object and of fields with no description on chosen objects. Never samples record data. Use when someone asks how many custom fields an org has, which objects are crowded, or how well fields are documented.
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" *)
---

# Field usage (light)

## Ground rules
**First, read `${CLAUDE_PLUGIN_ROOT}/docs/ground-rules.md` and follow every rule in it.** If you cannot read it, still keep these three:
1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> org`, then `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> whoami`, before any other check; show the org only as "…<last 4 of the 15-character Org Id>", and if `org` fails, never guess an Id.
2. Never run `sf org display` or `sf org open` (any form).
3. Read the org only through that script, or the same SOQL on the hosted path (no other SOQL, no other `sf` command), with only the alias the user named.

## Checks
- `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> fields`: custom fields per object (your own, not managed-package fields), plus custom object Ids and names to read the result by.
- `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> field-descriptions <ApiName>`: each field on one object that is not from a package, and its description. On the hosted path, check the object name matches `^[A-Za-z0-9_]{1,80}$` before building SOQL with it; if not, ask the user. Run it for at most 5 objects: the ones the user names, or else the 5 with the most custom fields.

## Wording rules
- This skill counts fields. It never reads records, so it cannot say whether a field is filled in or used. Say "fields defined", never "unused fields".
- In `fields`, custom objects show as 18-character Ids. Match the first 15 characters to `DurableId` in the `custom object Ids and API names` result, which gives the API name with its real suffix. Report custom objects (`__c`, `IsCustomSetting` false) as objects; list custom settings (`IsCustomSetting` true), custom metadata types (`__mdt`), platform events (`__e`), big objects (`__b`) and external objects (`__x`) by their API name and type, never as custom objects. A name with a second `__` is from a package. Unmatched Ids: count them as "other objects".
- In `field-descriptions`, count only your own custom fields: names that end in `__c` and either contain no other `__`, or start with the org's own namespace from the `org` check (`<ns>__Name__c` in a namespaced org); any other prefix is a managed package. Standard fields rarely carry an admin description; leave them out. If it returned no rows at all, that object is unassessed, not 0.
- Report counts and field API names only. Never quote or paraphrase a field's description text.
- Report description fill rate as "<n> of <m> custom fields have a description".

## Output
| Object | Custom fields | With description (if read) | Evidence | Confidence |
| --- | --- | --- | --- | --- |

Then a 1-line "Brief you can paste" (use exactly that heading) with totals only.

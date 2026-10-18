---
name: release-readiness
description: Read-only check of how ready a Salesforce org's custom code and automation are for platform changes - Apex below API version 45 (ICU locale formats), Apex on API 30 or lower, and Workflow Rules and Process Builders still in the org. Use before a Salesforce release, a locale change, or an automation migration.
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" *)
---

# Release readiness

## Ground rules
**First, read `${CLAUDE_PLUGIN_ROOT}/docs/ground-rules.md` and follow every rule in it.** If you cannot read it, still keep these three:
1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> org`, then `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> whoami`, before any other check; show the org only as "…<last 4 of the 15-character Org Id>", and if `org` fails, never guess an Id.
2. Never run `sf org display` or `sf org open` (any form).
3. Read the org only through that script, or the same SOQL on the hosted path (no other SOQL, no other `sf` command except `sf org list`), with only the alias the user named.

## Checks
- `api-45`: Apex classes and triggers below API version 45. Count the ones on API 30 or lower from the same rows (`ApiVersion` 30 or less); no separate check is needed.
- `flows` and `workflow`: Process Builders and Workflow Rules that exist (ground rule 16).

Run each as `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> <check>`.

## Wording rules
- ICU locale formats: per Salesforce Help ("Enable ICU Locale Formats"), Apex classes and triggers must be on API version 45.0 or later to use ICU formats; below 45 they keep JDK formats even when ICU is on, so dates and numbers they format can differ from the standard UI. Salesforce does not enforce the change at this time. Each class or trigger below 45 is a **review item**, not a defect. Whether the org already uses ICU is shown in Setup > Company Information (Locale Formats); this skill does not read it, so say "check Company Information".
- API 30 or lower: tech debt to review, as in the `org-read` skill. Saved Apex keeps working; integrations calling old API versions are not checked.
- Workflow Rules and Process Builders: Salesforce ended support for them on 31 Dec 2025. They are migration candidates. That they exist does not show whether they run.

## Output
| Item | Count | Evidence | Confidence |
| --- | --- | --- | --- |
| Apex classes below API 45 | | | |
| Apex triggers below API 45 | | | |
| Apex on API 30 or lower | | | |
| Process Builders | | | |
| Workflow Rules (exist) | | | |

Then a 2-line "Brief you can paste" (use exactly that heading) with the counts only.

---
name: release-readiness
description: Read-only check of how ready a Salesforce org's custom code and automation are for platform changes - Apex below API version 45 (ICU locale formats), Apex on API 30 or lower, and Workflow Rules and Process Builders still in the org. Use before a Salesforce release, a locale change, or an automation migration.
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" *)
---

# Release readiness

## Ground rules
Follow the `org-read` skill's ground rules (section 0) and run its path choice and org check (sections 1 and 2) first. They cover read-only commands, unassessed parts, evidence and confidence, row caps, managed-package flows and what shareable output may hold.

## Checks
- `api-45`: Apex classes and triggers below API version 45.
- `old-code`: Apex classes and triggers on API version 30 or lower.
- `flows` and `workflow`: Process Builders (ProcessType `Workflow`, `CustomEvent`, `InvocableProcess`) and Workflow Rules that exist.

Run each as `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> <check>`.

## Wording rules
- ICU locale formats: per Salesforce Help ("Enable ICU Locale Formats"), Apex classes and triggers must be on API version 45.0 or later to use ICU formats; below 45 they keep JDK formats even when ICU is on, so dates and numbers they format can differ from the standard UI. Salesforce does not enforce the change at this time. Each class or trigger below 45 is a **review item**, not a defect. Whether the org already uses ICU is shown in Setup > Company Information (Locale Formats); this skill does not read it, so say "check Company Information".
- API 30 or lower: tech debt to review, as in the `org-read` skill. Saved Apex keeps working; integrations calling old API versions are not checked.
- Workflow Rules and Process Builders: Salesforce ended support for them on 31 Dec 2025. They are migration candidates, counted separately. That they exist does not show whether they run.

## Output
| Item | Count | Evidence | Confidence |
| --- | --- | --- | --- |
| Apex classes below API 45 | | | |
| Apex triggers below API 45 | | | |
| Apex on API 30 or lower | | | |
| Process Builders | | | |
| Workflow Rules (exist) | | | |

Then a 2-line "Brief to paste" with the counts only.

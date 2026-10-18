---
name: agent-readiness
description: Light, read-only view of how ready a Salesforce org is for AI agents - access through permission sets versus profiles, logic in Apex triggers and Workflow Rules versus flows, and field description fill rate on Account, Contact, Opportunity and Case. Use when someone asks whether their org is ready for Agentforce or another AI agent.
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" *)
---

# Agent readiness (light)

## Ground rules
**First, read `${CLAUDE_PLUGIN_ROOT}/docs/ground-rules.md` and follow every rule in it.** If you cannot read it, still keep these three:
1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> org`, then `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> whoami`, before any other check; show the org only as "…<last 4 of the 15-character Org Id>", and if `org` fails, never guess an Id.
2. Never run `sf org display` or `sf org open` (any form).
3. Read the org only through that script, or the same SOQL on the hosted path (no other SOQL, no other `sf` command), with only the alias the user named.

## Checks
- `permissions`: custom profiles and your own custom permission sets.
- `triggers`, `workflow`, `flows`: where the logic lives.
- `field-descriptions` for `Account`, `Contact`, `Opportunity` and `Case` (one call each): `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> field-descriptions Account`, and so on.

Run the others as `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> <check>`.

## Wording rules
- These are signals we use, not a Salesforce readiness score. Say "our reading".
- Access: permission sets make it easier to give an agent user exactly the access it needs. Report "<n> custom profiles, <n> permission sets" and leave the judgement as a review item.
- Logic: report counts of active Apex triggers (the `triggers` check reads active ones only), Workflow Rules, Process Builders and active flows. Autolaunched flows and invocable Apex can be used as agent actions; logic inside Apex triggers, Workflow Rules and Process Builders cannot be called directly, and Workflow Rules and Process Builders are past end of support. Do not claim more than that.
- Field descriptions: count your own custom fields only (end in `__c`, no other `__`). Agents read field metadata; fields with no description give them less to go on. Report "<n> of <m> custom fields on <Object> have a description". If `field-descriptions` returned no rows at all for an object, the field list was not read: that object is **unassessed**, never "0 custom fields" at High confidence. Only when it returned the object's fields and none ends in `__c` is the count a real 0.
- 0 rows from an untested query (no Result in `${CLAUDE_PLUGIN_ROOT}/docs/queries-to-test.md`) is **unassessed**, not a High-confidence zero (ground rule 9).
- Data Cloud, Einstein and Agentforce settings: this plugin has no tested read-only query for them. Report them as **unassessed** ("not read by this plugin"), never as off or on.

## Output
| Signal | What we found | Evidence | Confidence |
| --- | --- | --- | --- |
| Access model | | | |
| Where logic lives | | | |
| Field descriptions (4 objects) | | | |
| Data Cloud / Einstein settings | unassessed | not read by this plugin | |

Then a 2-line "Brief you can paste" (use exactly that heading) with counts only: no org alias, no org name.

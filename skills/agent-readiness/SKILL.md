---
name: agent-readiness
description: Light, read-only view of how ready a Salesforce org is for AI agents - access through permission sets versus profiles, logic in Apex triggers and Workflow Rules versus flows, and field description fill rate on Account, Contact, Opportunity and Case. Use when someone asks whether their org is ready for Agentforce or another AI agent.
---

# Agent readiness (light)

## Ground rules
- Read-only. Only run the commands the `org-read` skill allows. Never run `sf org display`.
- Pick the path and confirm the org exactly as in the `org-read` skill (sections 1 and 2): run the `org` check on every path used, refuse to combine results from two different org Ids, and stamp the output with the last 4 characters of the org Id and sandbox or production.
- A query that fails, is denied or cannot run on the path used makes its part **unassessed**. Say which part and why; never guess its numbers.
- For each finding give the evidence (check, object, row count, path) and a confidence (high, medium, low), as defined in the `org-read` skill.
- If a list returns exactly its `LIMIT` in rows, say "<limit> or more".
- Shareable output (anything labelled "to paste" or "to share") holds counts and verdicts only: no org name, no user names, no record data. The owner's own output may name metadata (classes, flows, objects) but never record data.
- No prices, no partner claims, no urgency.

## Checks
- `permissions`: custom profiles and permission sets.
- `triggers`, `workflow`, `flows`: where the logic lives.
- `field-descriptions` for `Account`, `Contact`, `Opportunity` and `Case` (one call each): `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> field-descriptions Account`, and so on.

Run the others as `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> <check>`.

## Wording rules
- These are signals we use, not a Salesforce readiness score. Say "our reading".
- Access: permission sets make it easier to give an agent user exactly the access it needs. Report "<n> custom profiles, <n> permission sets" and leave the judgement as a review item.
- Logic: report counts of Apex triggers, Workflow Rules, Process Builders and active flows. Autolaunched flows and invocable Apex can be used as agent actions; logic inside Apex triggers, Workflow Rules and Process Builders cannot be called directly, and Workflow Rules and Process Builders are past end of support. Do not claim more than that.
- Field descriptions: count your own custom fields only (end in `__c`, no other `__`). Agents read field metadata; fields with no description give them less to go on. Report "<n> of <m> custom fields on <Object> have a description".
- Data Cloud, Einstein and Agentforce settings: this plugin has no tested read-only query for them. Report them as **unassessed** ("not read by this plugin"), never as off or on.

## Output
| Signal | What we found | Evidence | Confidence |
| --- | --- | --- | --- |
| Access model | | | |
| Where logic lives | | | |
| Field descriptions (4 objects) | | | |
| Data Cloud / Einstein settings | unassessed | not read by this plugin | |

Then a 2-line "Brief to paste" with counts only.

---
name: handover-audit
description: Build a read-only punch-list for an outgoing Salesforce partner or admin - what changed in the last 90 days and who changed it (counts), flows with no description, and Apex classes or triggers under 75% coverage. Use when a partner or admin is leaving, or before accepting a handover.
---

# Handover audit

## Ground rules
- Read-only. Only run the commands the `org-read` skill allows. Never run `sf org display`.
- Pick the path and confirm the org exactly as in the `org-read` skill (sections 1 and 2): run the `org` check on every path used, refuse to combine results from two different org Ids, and stamp the output with the last 4 characters of the org Id and sandbox or production.
- A query that fails, is denied or cannot run on the path used makes its part **unassessed**. Say which part and why; never guess its numbers.
- For each finding give the evidence (check, object, row count, path) and a confidence (high, medium, low), as defined in the `org-read` skill.
- If a list returns exactly its `LIMIT` in rows, say "<limit> or more".
- Shareable output (anything labelled "to paste" or "to share") holds counts and verdicts only: no org name, no user names, no record data. The owner's own output may name metadata (classes, flows, objects) but never record data.
- No prices, no partner claims, no urgency.

## Checks
- `recent-changes`: Apex classes and triggers changed in the last 90 days, counted by who last changed them; flows changed in the last 90 days.
- `flow-descriptions`: flows with no description.
- `class-coverage`: lines covered and uncovered per Apex class or trigger, plus Ids and names to match them.

Run each as `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> <check>`.

## Wording rules
- "Last modified by" is the last person to save the item, not its author or the only person who touched it. Report counts per person in the owner's output only; the brief to paste gives totals, no names.
- Leave managed-package flows (`ApiName` containing `__`) out of the no-description count, and say how many were left out.
- Coverage per class: covered / (covered + uncovered). Report classes and triggers under 75% (our line for this list). A class with 0 covered and 0 uncovered lines has no coverage recorded: say "not recorded", not 0%. Coverage comes from the last test runs in the org; this skill never runs tests.
- Match `ApexClassOrTriggerId` to the Id and name lists. If an Id is in neither list (for example a managed class), leave it out and count how many were left out.

## Output: punch-list for the outgoing partner
1. Changed in the last 90 days: <n> classes, <n> triggers, <n> flows (by person, owner's copy only).
2. Flows with no description: <n> (list them in the owner's copy).
3. Classes and triggers under 75% coverage: <n> (list them in the owner's copy).
4. Ask the partner for: a description on each flow listed, tests for each class listed, and a note on anything changed in the last 90 days.

Then a 2-line "Brief to paste" with the counts only.

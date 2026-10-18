---
name: handover-audit
description: Build a read-only punch-list for an outgoing Salesforce partner or admin - what changed in the last 90 days and who changed it (counts), flows with no description, and Apex classes or triggers under 75% coverage. Use when a partner or admin is leaving, or before accepting a handover.
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" *)
---

# Handover audit

## Ground rules
**First, read `${CLAUDE_PLUGIN_ROOT}/docs/ground-rules.md` and follow every rule in it.** If you cannot read it, still keep these three:
1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> org`, then `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> whoami`, before any other check; show the org only as "…<last 4 of the 15-character Org Id>", and if `org` fails, never guess an Id.
2. Never run `sf org display` or `sf org open` (any form).
3. Read the org only through that script, or the same SOQL on the hosted path (no other SOQL, no other `sf` command except `sf org list`), with only the alias the user named.

## Checks
- `recent-changes`: Apex classes and triggers changed in the last 90 days, counted by who last changed them; flows changed in the last 90 days.
- `flow-descriptions`: flows with no description.
- `class-coverage`: lines covered and uncovered per Apex class or trigger, plus Ids and names to match them.

Run each as `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> <check>`.

## Wording rules
- "Last modified by" is the last person to save the item, not its author or the only person who touched it. Report counts per person in the owner's output only; the "Brief you can paste" gives totals, no names.
- Managed-package flows: the `recent-changes` and `flow-descriptions` queries already leave them out (`NamespacePrefix = null`). Say so.
- Coverage per class: covered / (covered + uncovered). Report classes and triggers under 75% (our line for this list). A class with 0 covered and 0 uncovered lines has no coverage recorded: say "not recorded", not 0%. Coverage comes from the last test runs in the org; this skill never runs tests.
- Match `ApexClassOrTriggerId` to the Id and name lists. If an Id is in neither list (for example a managed class), leave it out and count how many were left out. If a name list returned 500 rows, unmatched Ids may be your own: say so instead of calling them managed.
- Caps: each of the three lists stops at 500 rows. The coverage list comes most uncovered lines first, so if it returned 500 rows it holds the 500 least covered items: say "at least <n> under 75%; only the 500 least covered were read", never a total.

## Output: punch-list for the outgoing partner
1. Changed in the last 90 days: <n> classes, <n> triggers, <n> flows (by person, owner's copy only).
2. Flows with no description: <n> (list them in the owner's copy).
3. Classes and triggers under 75% coverage: <n> (list them in the owner's copy).
4. Ask the partner for: a description on each flow listed, tests for each class listed, and a note on anything changed in the last 90 days.

Then a 2-line "Brief you can paste" (use exactly that heading) with the counts only.

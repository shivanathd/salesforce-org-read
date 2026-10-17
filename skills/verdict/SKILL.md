---
name: verdict
description: Score each area of a Salesforce org read as finish, cut, rebuild or unassessed, using written rules the owner can argue with. Use after the org-read checks have run.
---

# Verdict rules

These are Mindcat's rules of thumb, not Salesforce rules. Score each area, then the org as a whole. Show the rule next to each verdict, in plain words ("our rule: ...").

## Outcomes
- **Unassessed**: the area's queries failed, were denied, or could not run on the path used, and what did run does not meet a rule on its own (see the `org-read` skill, section 4). Never guess its numbers.
- **Finish**: the area works. It has fewer than 5 findings to act on and no Rebuild signal.
- **Cut (review before removing)**: the area holds things that look unused or superseded. They are candidates for migration or removal, not proof that something is duplicated or safe to delete. Before removing anything, check what depends on it (what calls it, what it updates, which reports or integrations use it) and get a yes from the business owner.
- **Rebuild**: only when an area shows **two or more independent Rebuild signals** from the list below. One signal alone is a finding, not a rebuild.

## Cut candidates (each needs a dependency check and a business-owner yes)
- Licences: active users with no login in 90 days, "to review" (some may be integration, API-only or frozen users); permission set licences with fewer than half used, "to review".
- Flows: inactive flows you own (leave out managed-package flows); Workflow Rules that exist; Process Builders. Salesforce ended support for Workflow Rules and Process Builder on 31 Dec 2025, so these are migration candidates.
- Risky automation: an object with both Apex triggers and record-triggered flows. That does not prove they overlap; it means someone should read both.

## Rebuild signals, by area
- **Tests** (needs two):
  - org-wide coverage reported under 75% (not a reported 0% that may not have been recorded);
  - the latest completed test run has failed methods (`MethodsFailed` above 0);
  - no completed test run in the last 5 runs.
- **Security** (needs two):
  - Health Check score under 55;
  - 3 or more high-risk Health Check settings;
  - more than 5 distinct active users with Modify All Data (one count across profiles and permission sets; see the `org-read` admins rule).
- **Risky automation** (needs two):
  - 3 or more objects with both Apex triggers and record-triggered flows;
  - 3 or more objects with two or more Apex triggers each.

Licences, Flows, Legacy metadata versions, Integrations, Background jobs and Limits never score Rebuild under these rules:
- **Legacy metadata versions**: Apex saved on API version 30 or lower is tech debt to review. Score Finish with a review list. It is never a Rebuild reason.
- **Integrations**: Named Credentials, Connected Apps and installed packages are an inventory to review (who owns each, is it still used). Score Finish. A listed connected app does not prove it holds tokens.
- **Background jobs**: each job type with `Failed` or `Aborted` jobs, or errors, in the last 7 days is a finding to review. Score Finish with the list: failing jobs need an owner to fix them, not removal.
- **Limits**: of data storage, file storage, daily API requests, single email and hourly published platform events, any at 80% or more used is a finding to fix. Score Finish.

## Review items (findings, not signals)
- Two Apex triggers on one object, or two record-triggered flows with the same `TriggerOrder` on one object and trigger type: check the run order.
- More than 20 custom profiles: access is hard to review.
- Coverage reported as 0%: may not have been recorded; run all tests once.

## Whole org
Count only assessed areas.
- If more than half the areas are unassessed, give no whole-org verdict: say "unassessed" and what access is needed.
- **Rebuild** if two or more assessed areas score Rebuild.
- **Rebuild <area>, finish the rest** if exactly one area scores Rebuild and none scores Cut. Keep the Rebuild finding; there are no removals to review.
- **Rebuild <area>, review cut candidates, then finish** if exactly one area scores Rebuild and one or more score Cut.
- **Finish** if no area scores Rebuild and at most one scores Cut.
- **Cut (review before removing) first, then finish** if no area scores Rebuild and two or more score Cut.

Always say how many areas were unassessed, for example "8 of 9 areas assessed; Security unassessed (no View Setup and Configuration)".

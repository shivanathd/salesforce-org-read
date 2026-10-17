---
name: verdict
description: Give each area of a Salesforce org read an outcome (finish, review, rebuild or unassessed) using written rules the owner can argue with. Use after the org-read, renewal-prep or object-read checks have run.
---

# Outcome rules

Score each area, then the org as a whole. Show the rule next to each outcome. These are Mindcat's rules of thumb, not Salesforce rules.

- **Unassessed**: the check failed, was denied or is not available. Give the error name. Never guess an outcome from missing data.
- **Finish**: the area works and has a short list of fixes (fewer than 5 findings, no candidates to cut, no strong signal below).
- **Review**: anything else. This includes candidates to cut (unused licences, inactive flows, Workflow Rules or Process Builder still in the org, a trigger and a record-triggered flow on one object) and legacy metadata versions. Write "candidate to cut, confirm with the owner": cutting needs dependency checks and a business owner's yes, which the plugin cannot do.

Strong signals:
- 3 or more HIGH_RISK settings in Security Health Check.
- The latest completed test run has failed methods.
- Org-wide coverage under 75% when it is above 0% and a completed test run exists.
- 20 or more Apex classes and triggers on API 30 or lower.
- More than 5 active users with Modify All Data.
- Failed async jobs, or jobs with errors, in the last 7 days.

**Rebuild** is for the whole org only, and only when 3 or more strong signals from at least 2 areas agree. One signal alone, such as low coverage, is Review.

Whole org: Rebuild as above; Finish if there are no strong signals and most assessed areas are Finish; otherwise Review. If more than half the areas are Unassessed, say the read is incomplete and give no whole-org outcome.

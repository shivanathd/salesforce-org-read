---
name: verdict
description: Score each area of a Salesforce org read as finish, cut or rebuild, using written rules the owner can argue with. Use after the org-read checks have run.
---

# Verdict rules

Score each area, then the org as a whole. Show the rule next to each verdict.

- **Finish**: the area works and has a short list of fixes (fewer than 5 findings, none high-risk).
- **Cut**: the area is unused or duplicated: unused licences, inactive flows, Workflow Rules or Process Builder still in the org (support ended 31 Dec 2025), triggers and flows both firing on one object.
- **Rebuild**: high-risk security settings, org coverage under 75%, failing tests on core objects, or many classes and triggers on API versions 21 to 30, which Salesforce is retiring.

Whole org: rebuild if two or more areas score rebuild; finish if none score rebuild and most score finish; otherwise cut first, then finish.

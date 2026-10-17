# Sample note

Written from the plugin's checks on Mindcat's own test scratch org on 18 October 2026, through the sf CLI. The org holds test metadata only (a trigger and class on API 30, two Account flows, one failing test); no customer data.

---

# Org read: Mindcat Org Read Test, 18 Oct 2026

Org Id: 00DE200000bq0eYMAQ · Sandbox: yes (scratch org) · Edition: Developer Edition · Read through: sf CLI

**Outcome: review.** Two strong signals (a failing test and 13 high-risk security settings) in two areas; Rebuild needs three.

| Area | Outcome | What we found | Evidence (check, count) | Confidence | Source object |
| --- | --- | --- | --- | --- | --- |
| Licences | Review | 1 of 2 Salesforce licences unused; 1 active Chatter Free user with no login in 90 days. Candidate to cut, confirm with the owner. | `licences`: 2 total, 1 used; 1 inactive | High | User, UserLicense, PermissionSetLicense |
| Flows | Review | 2 unmanaged flows, 1 inactive (Account Set Rating (Inactive)). No Process Builder, no Workflow Rules. | `flows`: 2 rows, 0 Process Builder; `workflow`: 0 | High | FlowDefinitionView, WorkflowRule |
| Risky automation | Review | Account has an active trigger (LegacyAccountTrigger) and an active before-save flow. Review item, not proof of duplication. | `triggers`: 1; `object Account`: 1 trigger, 2 flows | Medium | ApexTrigger, FlowDefinitionView |
| Tests | Review | Last run 17 Oct 2026: 2 methods completed, 1 failed. Org-wide coverage reads 0%, which can mean it was not aggregated. LegacyAccountHelper has 0 of 4 lines covered. No failed async jobs in 7 days. | `tests`: 1 failed; coverage 0; `handover`: 2 under 75%; `async-failures`: 0 errors | High (failure), Low (coverage) | ApexTestRunResult, ApexOrgWideCoverage, ApexCodeCoverageAggregate, AsyncApexJob |
| Legacy metadata versions | Review | 2 classes and 1 trigger saved on API 30. None on 31 to 44. This is code age, not breakage; integrations calling old API versions are not visible here. | `legacy-versions`: 2, 1, 0, 0 | High | ApexClass, ApexTrigger |
| Security | Review | Health Check score 66, 13 high-risk settings (for example MFA, clickjack protection, HttpOnly). 1 active user with Modify All Data through a profile, 0 through permission sets. | `security`: 13; `admin-sprawl`: 1, 0 | High | SecurityHealthCheckRisks, User, PermissionSetAssignment |
| Access model | Finish | 1 custom profile, 47 permission sets. | `permission-debt`: 1, 47 | High | PermissionSet |
| Integrations and packages | Finish | 0 named credentials, 1 connected app, 0 installed packages. | `integrations`: 0, 1; `packages`: 0 | High | NamedCredential, ConnectedApplication, InstalledSubscriberPackage |
| Limits | Finish | Data storage 0 of 500 MB, file storage 0 of 50 MB, daily API requests 164 of 5,000,000, single email 0 of 15, hourly platform events 0 of 250,000. | `limits`: 75 limits | High | /limits |

**Inventory:** 0 custom objects, 0 custom fields, 1 active flow, 2 Apex classes, 1 trigger, 0 installed packages, 0 named credentials, 1 connected app.

**First three things to do**
1. Fix the failing test, then run all tests once so coverage is recorded.
2. Work through the 13 high-risk Health Check settings, starting with MFA.
3. Decide with the owner whether the Account trigger and flow should both stay, and move the API 30 class and trigger to a current version.

Read-only: nothing in the org was changed.

**Brief to send us** (counts and outcomes only; no names, no record data)
```
Edition: Developer Edition, sandbox: yes
Outcome: review
Licences: review, 1 inactive seat
Flows: review, 1 inactive, 0 Process Builder, 0 Workflow Rules
Risky automation: review, 1 object with a trigger and a flow
Tests: review, 1 failed method, coverage 0%
Legacy metadata versions: review, 3 on API 30 or lower, 0 on 31 to 44
Security: review, 13 high-risk settings
Unassessed: none
```

Want help with this? Send the brief above: https://mindcat.ai/contact/org-stuck

# Org read: <org name>, <date>

Org Id: <Id> · Sandbox: <yes | no> · Edition: <OrganizationType> · Read through: <sf CLI | hosted MCP | both, same Org Id>

**Outcome: <finish | review | rebuild | incomplete>.** <one sentence why>

| Area | Outcome | What we found | Evidence (check, count) | Confidence | Source object |
| --- | --- | --- | --- | --- | --- |
| Licences | | | | | User, UserLicense, PermissionSetLicense |
| Flows | | | | | FlowDefinitionView, WorkflowRule |
| Risky automation | | | | | ApexTrigger, FlowDefinitionView |
| Tests | | | | | ApexTestRunResult, ApexOrgWideCoverage, AsyncApexJob |
| Legacy metadata versions | | | | | ApexClass, ApexTrigger |
| Security | | | | | SecurityHealthCheckRisks, User, PermissionSetAssignment |
| Access model | | | | | PermissionSet |
| Integrations and packages | | | | | NamedCredential, ConnectedApplication, InstalledSubscriberPackage |
| Limits | | | | | /limits |

Outcomes: Finish, Review (including "candidate to cut, confirm with the owner"), Unassessed (check failed: give the error). Rebuild applies to the whole org only.

**Inventory:** <n> custom objects, <n> custom fields, <n> active flows, <n> Apex classes, <n> triggers, <n> installed packages, <n> named credentials, <n> connected apps.

**First three things to do**
1.
2.
3.

Read-only: nothing in the org was changed.

**Brief to send us** (counts and outcomes only; no names, no record data)
```
Edition: <OrganizationType>, sandbox: <yes | no>
Outcome: <finish | review | rebuild | incomplete>
Licences: <outcome>, <n> inactive seats
Flows: <outcome>, <n> inactive, <n> Process Builder, <n> Workflow Rules
Risky automation: <outcome>, <n> objects with a trigger and a flow
Tests: <outcome>, <n> failed methods, coverage <n>%
Legacy metadata versions: <outcome>, <n> on API 30 or lower, <n> on 31 to 44
Security: <outcome>, <n> high-risk settings
Unassessed: <check names>
```

Want help with this? Send the brief above: https://mindcat.ai/contact/org-stuck

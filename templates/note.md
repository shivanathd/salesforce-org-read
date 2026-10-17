# Org read, <date>

Org: …<last 4 characters of org Id>, <sandbox | production>, <edition>. Read via <hosted MCP | sf CLI | both; Ids matched>.

**Verdict: <finish | cut (review before removing) | rebuild | unassessed>.** <one sentence why>

**Unassessed:** <n> of 7 areas. <area: reason, or "none">

| Area | Verdict | What we found | Evidence (check, object, rows, path) | Confidence |
| --- | --- | --- | --- | --- |
| Licences | | | `licences`: User, UserLicense | |
| Flows | | | `flows`, `workflow`: FlowDefinitionView, WorkflowRule | |
| Risky automation | | | `triggers`, `flows`: ApexTrigger, FlowDefinitionView | |
| Tests | | | `tests`: ApexTestRunResult, ApexOrgWideCoverage | |
| Legacy metadata versions | | | `old-code`: ApexClass, ApexTrigger | |
| Security | | | `security`, `admins`, `permissions`: SecurityHealthCheck, SecurityHealthCheckRisks, User, PermissionSetAssignment, PermissionSet | |
| Limits | | | `limits`: /limits | |

Verdicts follow the rules in the `verdict` skill. "Cut" means review before removing: check what depends on it and get the business owner's yes first.

**Not checked:** integrations still calling API versions 21 to 30. Finding them needs Event Log data.

**First three things to do**
1.
2.
3.

Read-only: nothing in the org was changed.

**Brief you can paste**
> Salesforce org read, <date>: <whole-org verdict>; <n> of 7 areas assessed.
> Licences <verdict>, Flows <verdict>, Risky automation <verdict>, Tests <verdict>, Legacy metadata versions <verdict>, Security <verdict>, Limits <verdict>.
> <n> licences to review, <n> inactive flows, <n> Process Builders, <n> Workflow Rules, coverage <n>%, <n> high-risk settings.

Want this written up properly? Get the written assessment: https://mindcat.ai/contact/org-stuck

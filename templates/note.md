# Org read, <date>

Org: …<last 4 characters of the 15-character org Id>, <sandbox | production>, <edition>. Read via <hosted MCP | sf CLI | both; Ids matched>.

**Verdict: <rebuild | rebuild <area>, finish the rest | rebuild <area>, review cut candidates, then finish | finish | cut (review before removing) first, then finish | unassessed>.** <one sentence why>

**Unassessed:** <n> of 9 areas. <area: reason, or "none">

| Area | Verdict | What we found | Evidence (check, object, rows, path) | Confidence |
| --- | --- | --- | --- | --- |
| Licences | | | `licences`: User, UserLicense, PermissionSetLicense | |
| Flows | | | `flows`, `workflow`: FlowDefinitionView, WorkflowRule | |
| Risky automation | | | `triggers`: ApexTrigger, FlowDefinitionView | |
| Tests | | | `tests`: ApexTestRunResult, ApexOrgWideCoverage, ApexClass, ApexTrigger | |
| Legacy metadata versions | | | `old-code`: ApexClass, ApexTrigger | |
| Security | | | `security`, `admins`, `permissions`: SecurityHealthCheck, SecurityHealthCheckRisks, User, PermissionSetAssignment, PermissionSet | |
| Integrations | | | `integrations`, `packages`: NamedCredential, ConnectedApplication, InstalledSubscriberPackage | |
| Background jobs | | | `async`: AsyncApexJob, last 7 days | |
| Limits | | | `limits`: data and file storage, daily API requests, single email, hourly platform events | |

Verdicts follow the rules in the `verdict` skill. "Cut" means review before removing: check what depends on it and get the business owner's yes first. A count from a list that hit its limit is written "at least <n>".

**Not checked:** integrations still calling API versions 21 to 30. Finding them needs Event Log data.

**First three things to do**
1.
2.
3.

Read-only: nothing in the org was changed.

**Brief you can paste**
<!-- Write each Cut verdict here as "cut (review before removing)". A count from a list that hit its limit is "at least <n>". Drop this line. -->
> Salesforce org read, <date>: <whole-org verdict>; <n> of 9 areas assessed.
> Licences <v>, Flows <v>, Risky automation <v>, Tests <v>, Legacy metadata versions <v>, Security <v>, Integrations <v>, Background jobs <v>, Limits <v>.
> <n> users to review, <n> inactive flows, <n> Process Builders, <n> Workflow Rules, coverage <n>%, <n> high-risk settings, <n> failing job types.

Want this written up properly? Get the written assessment: https://mindcat.ai/contact/org-stuck

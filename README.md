# mindcat-org-read

A read-only plugin for owners of a stuck Salesforce org. It reads the org and produces a one-page note (shown in chat; saved to a file only when you ask) on licences to review, inactive and out-of-date flows, Workflow Rules and Process Builders still in the org, the last test run and org-wide coverage, triggers and flows on the same object, Apex saved on old API versions, Security Health Check risks, admin access, profiles and permission sets, Named Credentials, Connected Apps and installed packages, failed background jobs, and key limits. Each area gets a finish, cut (review before removing), rebuild or unassessed verdict with the rule behind it.

**No data goes to Mindcat. Query results are processed by Salesforce and by the AI provider you chose, under their terms.**

## Skills
| Skill | What it gives you |
| --- | --- |
| `org-read` | The one-page note with finish, cut, rebuild or unassessed per area |
| `org-connect` | Help connecting the hosted MCP server or the sf CLI |
| `renewal-prep` | A licence cut-sheet before renewal: seats to review, drop or reassign (no prices) |
| `handover-audit` | A punch-list for an outgoing partner: recent changes, flows with no description, classes under 75% coverage |
| `release-readiness` | Apex below API 45 (ICU locale formats) and on API 30 or lower, Process Builders and Workflow Rules |
| `object-read` | Every trigger, record-triggered flow, Workflow Rule and validation rule count on one object |
| `field-usage` | Custom fields per object and description fill rate (no record data) |
| `agent-readiness` | Access model, where logic lives, field descriptions on Account, Contact, Opportunity and Case |
| `org-book` | A Markdown inventory file, written only when you ask |

A query not yet run on an org is listed with no Result in [docs/queries-to-test.md](docs/queries-to-test.md). A query that fails is reported as unassessed.

## Before you start
- **Salesforce edition**: the hosted MCP server needs Enterprise Edition or above, or a Developer Edition org. The sf CLI path works on any org you can log in to with API access.
- **Salesforce CLI** (`sf`), installed and logged in: `sf org login web --alias <alias>`. The full read needs it, because the hosted server may not reach Tooling API objects (coverage, Workflow Rules, Apex versions, installed packages, Health Check) or org limits.
- **Permission**: the signed-in user needs "View Setup and Configuration" and API access. Areas the user cannot read are reported as unassessed.
- **Read-only user (recommended)**: sign in as a Minimum Access - Salesforce user with a permission set that grants only API Enabled, View Setup and Configuration and View All Users. The standard Read Only profile is an alternative where it exists (scratch and Developer Edition orgs may not have it); confirm it has both permissions above. This limits what the login can change, but it is not a guarantee: the Read Only profile can still allow some actions (such as Chatter posts), and permission sets add access, so review the user's effective permissions. Without View All Users, sharing can hide some users from the licence counts. The read tells you once if your login can change the org.

## Install
```
/plugin marketplace add shivanathd/salesforce-org-read
/plugin install mindcat-org-read@mindcat
```
Claude chat, Cowork and Claude Code load the skills and the Salesforce MCP server. Cursor reads `.cursor-plugin/plugin.json` and `mcp.json`.

## Connect the hosted MCP server (optional)
Salesforce's standard hosted MCP servers are off by default. An admin sets this up once:
1. In Setup, Quick Find "MCP Servers", open MCP Servers (under API Catalog), then Salesforce Servers, and activate `sobject-reads`.
2. Create an External Client App (Setup > External Client App Manager). Enable OAuth with scopes `mcp_api` and `refresh_token`, issue JWT-based access tokens for named users, and add the callback URL for your client (below). Require PKCE, set Permitted Users to admin-approved users (pre-authorized) and give the app only to the read-only user, and set a refresh token policy that expires tokens. `localhost` callbacks are for clients on your own machine only. Salesforce's guide says a scratch org's Setup cannot create an External Client App: create it in the Dev Hub, package it and install it in the scratch org, or use the CLI path for scratch orgs. It can take up to 30 minutes to start working.
3. Copy the app's Consumer Key (Settings > OAuth Settings > Consumer Key and Secret). Your AI client uses it as the OAuth Client ID.

Then, per client:
- **Claude Code**
  - Callback:
  - `http://localhost:33418/callback`
  - Run `/mcp`, pick `salesforce-sobject-reads` and give the Consumer Key as the client ID. If your version does not ask: `claude mcp add --transport http --client-id <consumer key> --callback-port 33418 salesforce-sobject-reads <server URL>`.
- **Claude chat and Cowork (claude.ai)**
  - Callback:
  - `https://claude.ai/api/mcp/auth_callback`
  - Add a custom connector with the server URL; under Advanced settings, paste the Consumer Key into OAuth Client ID.
- **Cursor**
  - Callbacks (some versions use the second; add both):
  - `http://localhost:8787/callback`
  - `cursor://anysphere.cursor-mcp/oauth/callback`
  - In Cursor's MCP config for the server, add `"auth": { "CLIENT_ID": "<consumer key>" }`. The shipped `mcp.json` has no key, because each org has its own.

Server URL: `https://api.salesforce.com/platform/mcp/v1/platform/sobject-reads` (sandbox or scratch: `https://api.salesforce.com/platform/mcp/v1/sandbox/platform/sobject-reads`).

**Check the connection**: ask Claude to run the `org` check. It reads `Organization` (Id, edition, sandbox or production, namespace) on each path. The `whoami` check then reads only the signed-in user's permission flags, to warn you once if the login has key write permissions (it checks a few flags, not every permission). If the hosted server and the CLI point at different orgs, the read stops instead of mixing results.

Salesforce's guides:
- Get started: https://developer.salesforce.com/docs/platform/hosted-mcp-servers/guide/hosted-mcp-servers-overview.html
- Create an External Client App: https://developer.salesforce.com/docs/platform/hosted-mcp-servers/guide/create-external-client-app.html
- SObject Reads server: https://developer.salesforce.com/docs/platform/hosted-mcp-servers/guide/sobject-reads.html
- Standard servers (off by default): https://developer.salesforce.com/docs/platform/hosted-mcp-servers/guide/servers-reference.html

## Try it
You need a Salesforce org you can sign in to. To test without a customer org, sign up for a free Developer Edition:

- https://developer.salesforce.com/signup

Then sign the CLI in once with `sf org login web --alias my-dev`, and ask Claude:
- "Read my Salesforce org my-dev and tell me what to finish, cut or rebuild."
- "Which flows in my-dev are inactive or on an old API version?"
- "How many Salesforce licences in my-dev are assigned to users who haven't logged in for 90 days?"

## What it runs, sends and fetches
- **Salesforce hosted MCP server** (`sobject-reads`, read-only by Salesforce's design), at `api.salesforce.com`, which Salesforce runs (not Mindcat), signed in with the customer's own Salesforce login. Query results go to the customer's AI client.
- **The customer's `sf` CLI**, through `scripts/org-read-cli.sh`: read-only `sf data query` SELECT queries (including the Tooling API) and `sf org list limits`. Signing in with `sf org login web` stores the login on the user's machine, in the Salesforce CLI's own store; the plugin never reads or copies it.
- **Nothing is sent to Mindcat.** The plugin has no server of its own and no telemetry. Query results are processed by Salesforce and by the AI provider you use.
- **Uses your own Salesforce login, by design.** The plugin never reads, stores or sends your Salesforce login; the sf CLI keeps its own login. The `sf` CLI and the hosted server act as the Salesforce user you signed in as. The plugin never reads, stores or sends that login, and never runs commands that print a token, auth URL or session id: `sf org display`, `sf org open` (including `--url-only`) or `--verbose` on `sf org` commands.
- **Files.** The plugin writes a file only when you ask: the `org-book` inventory, or a saved note.
- **Org text is data.** Names, labels, descriptions and error messages from the org are never followed as instructions; text that looks like instructions is reported to you.
- **No hooks.** The plugin adds no hooks, so it never runs on your other commands or tools. Its skills only use read-only queries; sign in as a read-only Salesforce user so the org itself enforces that.

## FAQ
- **Does it change my org?** No. It runs only SELECT queries and read-only `sf` commands (`sf org list limits`). Sign in as a read-only user and the org enforces that too.
- **What does Mindcat see?** Nothing. There is no Mindcat server and no telemetry. Query results go to Salesforce and to the AI provider behind your client.
- **Does it run Apex tests?** No. It reports the last test run that already exists.

## Troubleshooting
| You see | What to do |
| --- | --- |
| `AuthDecryptError` from `sf` | The saved login can't be read with the current keychain setting. Log in again with `sf org login web --alias <alias>`; if that fails, follow the Salesforce CLI troubleshooting guide for keychain errors. |
| `INSUFFICIENT_ACCESS`, another access error, or a "not supported" error on a check | The signed-in user lacks a permission (often View Setup and Configuration). That area is reported as unassessed; ask an admin for the permission, or accept the gap. |
| OAuth fails with `invalid_client_id` | The External Client App can take up to 30 minutes to start working. Wait and retry, and check the Consumer Key was pasted as the OAuth Client ID. |
| OAuth redirect fails or shows a callback mismatch | The callback URL in the External Client App must match your client exactly (see the list above). For Cursor, add both callback URLs. |
| Sign-in page says the user or org is not found | It may be a sandbox. With `sf`, add the sandbox instance URL (see "Sandbox instance URL" below). For the hosted server, use the server URL with `/sandbox/` in it. Production and Developer Edition use the plain ones. |
| The read stops saying the org Ids differ | The hosted server and the CLI are signed in to different orgs. Sign one of them in to the org you want, then run the read again. |

Sandbox instance URL, for `sf org login web --instance-url`:

- https://test.salesforce.com

## Sample note (example only)
This is an illustration with made-up counts. It is not from a real org.

> **Org read, 17 Oct 2026.** Org: …7Q2A, sandbox, Enterprise Edition. Read via both paths; Ids matched.
>
> **Verdict: cut (review before removing) first, then finish.** No area shows two Rebuild signals; Flows and Licences hold candidates to review.
>
> **Unassessed:** 1 of 9 areas. Security: the Health Check queries were denied on both paths (the user lacks a needed permission).
>
> | Area | Verdict | What we found | Evidence | Confidence |
> | --- | --- | --- | --- | --- |
> | Licences | Cut (review before removing) | 14 active users with no login in 90 days, to review | `licences`, User, 3 rows, CLI | High |
> | Flows | Cut (review before removing) | 9 inactive flows, 4 Process Builders, 12 Workflow Rules exist; 3 managed-package flows left out | `flows`, `workflow`, 61 + 12 rows, CLI | High |
> | Tests | Finish | Coverage 81%; last run 0 failed methods | `tests`, 5 + 1 + 1 + 5 rows, CLI | High |
> | Background jobs | Finish | 1 job type with failed jobs in 7 days, to review | `async`, 6 rows, hosted | High |
> | ... | | | | |

## What it does not check
- Integrations still calling API versions 21 to 30, which Salesforce retired for API calls in Summer '25. Finding them needs Event Log data. The `old-code` check lists Apex saved on API 30 or lower, which is tech debt to review, not code that stopped working.
- Whether a flow or rule actually runs. Salesforce keeps no general last-run record.

## Layout
| Path | What |
| --- | --- |
| `skills/org-read` | Main skill: path choice, org check, checks, wording rules, note |
| `skills/org-connect` | Hosted server, External Client App and sf CLI setup |
| `skills/verdict` | Finish, cut, rebuild and unassessed rules |
| `skills/renewal-prep`, `handover-audit`, `release-readiness`, `object-read`, `field-usage`, `agent-readiness`, `org-book` | Focused reads built on the same checks |
| `docs/ground-rules.md` | Rules every skill reads first (read-only, script only, no tokens, org text is data) |
| `docs/queries-to-test.md` | New queries to run on a scratch org before release |
| `scripts/org-read-cli.sh` | Read-only `sf` queries per check |
| `.mcp.json`, `mcp.json` | Salesforce hosted `sobject-reads` server (Claude, Cursor) |
| `templates/note.md` | The one-page note |
| `.github/workflows/check.yml`, `CONTRIBUTING.md` | CI checks and how to run them locally |

## Get help
- **Setup help or a bug**: open a GitHub issue. Never paste secrets, keys, org Ids or org data into an issue.
  - https://github.com/shivanathd/salesforce-org-read/issues
- **A security problem**: email apps@mindcat.ai. Please don't open a public issue. See [SECURITY.md](SECURITY.md).
- **Want an expert to look at your org?** https://mindcat.ai/contact/org-stuck
- Privacy policy: [PRIVACY.md](PRIVACY.md). Changes: [CHANGELOG.md](CHANGELOG.md). Contributing: [CONTRIBUTING.md](CONTRIBUTING.md).

## Status
Version 0.2.0. The first eight checks have been run against a real Salesforce scratch org, and the two `admins` breakdown queries, the custom profile count, `packages`, `integrations`, `async` and the permission set licence query against a real org. The queries in [docs/queries-to-test.md](docs/queries-to-test.md) were run on a scratch org on 2026-10-18; the one with no Result there (Workflow Rules on one object) has not been run yet. Test coverage can read 0% even after tests run; the note then keeps the reported value and says it may not have been recorded.

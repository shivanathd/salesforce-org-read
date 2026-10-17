# Mindcat Org Read for Salesforce

Plugin id: `mindcat-org-read`.

A read-only plugin for owners of a stuck Salesforce org. It reads the org and writes a one-page note on unused licences, inactive and out-of-date flows, Process Builder and Workflow Rules still in the org, the last test run and coverage, triggers and flows on the same object, Apex on old metadata API versions, admin access, integrations, Security Health Check risks and limits. Each area gets an outcome (finish, review, rebuild for the whole org, or unassessed when a check could not run), with the evidence, a confidence level and the rule behind it.

## Install
```
/plugin marketplace add shivanathd/salesforce-org-read
/plugin install mindcat-org-read@mindcat
```
Claude chat, Cowork and Claude Code load the skills and the Salesforce MCP server. Cursor reads `.cursor-plugin/plugin.json` and `mcp.json`.

## Prerequisites
- **The Salesforce CLI (`sf`) for the full read.** Install it from https://developer.salesforce.com/tools/salesforcecli and run `sf org login web --alias <alias>`. The hosted `sobject-reads` server may not reach Tooling API objects (triggers, Workflow Rules, coverage, Health Check), so those checks need the CLI.
- **Edition:** any edition with API access for the CLI. The hosted MCP server needs Enterprise Edition or higher, or a Developer Edition org.
- **Permission:** the Salesforce user needs API Enabled and View Setup and Configuration. Without it, setup checks come back Unassessed.
- **A read-only user is best.** Create a permission set with API Enabled, View Setup and Configuration and read access to the objects you want checked, assign it to a user with a minimal profile, and sign in as that user. The org then enforces read-only, not just the plugin.

## Try it
To test without a customer org, sign up for a free Developer Edition at https://developer.salesforce.com/signup, then run `sf org login web --alias my-dev` once. Then ask Claude:
- "Read my Salesforce org my-dev and tell me what to finish, review or rebuild."
- "Which flows in my-dev are inactive or still Process Builder?"
- "Prepare my-dev for the licence renewal."
- "What runs when an Account is saved in my-dev?"

See [docs/sample-note.md](docs/sample-note.md) for a note from a test scratch org.

## What it runs, sends and fetches
- **Salesforce hosted MCP server** (`sobject-reads`, read-only by Salesforce's design), at `api.salesforce.com`, which Salesforce runs (not Mindcat), signed in with the customer's own Salesforce login. Query results go to the customer's AI client.
- **The customer's `sf` CLI**, through `scripts/org-read-cli.sh`: read-only `sf data query` (including the Tooling API) and `sf org list limits`. Signing in with `sf org login web` stores the login on the user's machine, in the Salesforce CLI's own store; the plugin never reads or copies it.
- **`scripts/summarise.py`** turns the CLI output into a status and row count per query, so a failed check is marked Unassessed. It reads stdin only.
- **Nothing is sent to Mindcat.** The plugin has no server of its own and no telemetry.
- **Uses your own Salesforce login, by design.** The `sf` CLI and the hosted server act as the Salesforce user you signed in as. The plugin never reads, stores or sends that login, and never runs `sf org display`, which would print the access token.
- **No hooks.** The plugin adds no hooks, so it never runs on your other commands or tools.

## Checks
`bash scripts/org-read-cli.sh <alias> <check>` runs one check and prints sf's JSON. It exits 0 when every query worked, 1 when any query failed (the rest still run), and 2 for a usage error or a missing `sf`.

`org`, `licences`, `renewal`, `flows`, `workflow`, `triggers`, `tests`, `legacy-versions`, `security`, `limits`, `admin-sprawl`, `permission-debt`, `packages`, `integrations`, `async-failures`, `handover`, `fields`, `inventory`, `object <ObjectApiName>`.

## Layout
| Path | What |
| --- | --- |
| `skills/org-read` | Main skill: path choice, org check, checks, wording rules, note |
| `skills/renewal-prep` | Licence use before a renewal, seats you could drop |
| `skills/object-read` | What fires on save for one object |
| `skills/org-connect` | sf CLI and hosted MCP server setup |
| `skills/verdict` | Finish, review, rebuild and unassessed rules |
| `scripts/org-read-cli.sh` | Read-only `sf` queries per check |
| `scripts/summarise.py` | Per-query status and counts from the CLI output |
| `.mcp.json`, `mcp.json` | Salesforce hosted `sobject-reads` server (Claude, Cursor) |
| `templates/note.md` | The one-page note |
| `tests/` | Unit tests with saved scratch-org output |

## FAQ
- **Does it change my org?** No. It only runs SELECT queries and `sf org list limits`. Sign in as a read-only user to make the org enforce that.
- **Does it run my Apex tests?** No. It reports the last run that already exists.
- **Why does a check say Unassessed?** The query failed, usually for lack of permission. The note gives the error name.
- **Does old API version code break?** Not because of its saved version. Salesforce's API 21 to 30 retirement is about API calls made with those versions. The note lists old code as a review item.
- **Does "candidate to cut" mean I can delete it?** No. Check dependencies and confirm with the business owner first.

## Troubleshooting
- `AuthDecryptError`: the CLI can't read its saved login. Run `sf org login web --alias <alias>` again, then see the Salesforce CLI keychain troubleshooting guide.
- `INSUFFICIENT_ACCESS` or `INVALID_TYPE` on a check: the user lacks View Setup and Configuration or object access. The check is Unassessed.
- `invalid_client_id` on the hosted server: the Consumer Key is wrong, or the External Client App is less than 30 minutes old.
- Callback or redirect mismatch: add the client's callback URL to the External Client App (see `skills/org-connect`).
- Sandbox login fails: use `--instance-url https://test.salesforce.com` for the CLI and the `/sandbox/` hosted server URL.

## Get help
- Setup help or a question: open a GitHub issue with the "Setup help" template.
- Bug: open an issue with the "Bug report" template.
- Security issue: email apps@mindcat.ai. Do not open a public issue. See [SECURITY.md](SECURITY.md).
- Never paste tokens, passwords or org data into an issue.
- Want an expert to look at your org? https://mindcat.ai/contact/org-stuck

## Support
- Plugin support: apps@mindcat.ai
- Stuck org help: https://mindcat.ai/contact/org-stuck
- Dubai: info@mindcat.ai, +971 4 266 2348
- India: india@mindcat.ai
- US: usa@mindcat.ai
- Privacy policy: [PRIVACY.md](PRIVACY.md)

## Status
Version 0.2.0. Every check has been run against a real Salesforce scratch org; see [CHANGELOG.md](CHANGELOG.md).

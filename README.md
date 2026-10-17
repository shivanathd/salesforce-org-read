# mindcat-org-read

A read-only plugin for owners of a stuck Salesforce org. It reads the org and writes a one-page note on unused licences, inactive and out-of-date flows, Workflow Rules still in the org, the last test run and org-wide coverage, triggers and flows firing on the same object, code on retiring API versions, Security Health Check risks and limits. Each area gets a finish, cut or rebuild verdict with the rule behind it.

## Install
```
/plugin marketplace add shivanathd/salesforce-org-read
/plugin install mindcat-org-read@mindcat
```
Claude chat, Cowork and Claude Code load the skills and the Salesforce MCP server. Cursor reads `.cursor-plugin/plugin.json` and `mcp.json`.

## Try it
You need a Salesforce org you can sign in to. To test without a customer org, sign up for a free Developer Edition at https://developer.salesforce.com/signup, then run `sf org login web --alias my-dev` once. Then ask Claude:
- "Read my Salesforce org my-dev and tell me what to finish, cut or rebuild."
- "Which flows in my-dev are inactive or on an old API version?"
- "How many Salesforce licences in my-dev are assigned but unused?"

## What it runs, sends and fetches
- **Salesforce hosted MCP server** (`sobject-reads`, read-only by Salesforce's design), at `api.salesforce.com`, which Salesforce runs (not Mindcat), signed in with the customer's own Salesforce login. Query results go to the customer's AI client.
- **The customer's `sf` CLI**, through `scripts/org-read-cli.sh`: read-only `sf data query` (including the Tooling API) and `sf org list limits`. Signing in with `sf org login web` stores the login on the user's machine, in the Salesforce CLI's own store; the plugin never reads or copies it.
- **Nothing is sent to Mindcat.** The plugin has no server of its own and no telemetry.
- **Uses your own Salesforce login, by design.** The `sf` CLI and the hosted server act as the Salesforce user you signed in as. The plugin never reads, stores or sends that login, and never runs `sf org display`, which would print the access token.
- **No hooks.** The plugin adds no hooks, so it never runs on your other commands or tools. Its skills only use read-only queries; sign in as a read-only Salesforce user so the org itself enforces that.

## Layout
| Path | What |
| --- | --- |
| `skills/org-read` | Main skill: path choice, checks, wording rules, note |
| `skills/org-connect` | External Client App and sf CLI setup |
| `skills/verdict` | Finish, cut or rebuild rules |
| `scripts/org-read-cli.sh` | Read-only `sf` queries per check |
| `.mcp.json`, `mcp.json` | Salesforce hosted `sobject-reads` server (Claude, Cursor) |
| `templates/note.md` | The one-page note |

## Support
- Email: apps@mindcat.ai
- Contact: https://mindcat.ai/contact
- Privacy policy: [PRIVACY.md](PRIVACY.md)

## Status
Version 0.1.0. All eight checks have been run against a real Salesforce scratch org. Test coverage can read 0% even after tests run; the note then says coverage was not recorded.

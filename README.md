# mindcat-org-read

Working name: **Finish, Cut or Rebuild**. ("Org Check" is a Salesforce Labs package, so we don't use that name.)

A read-only plugin for owners of a stuck Salesforce org. It reads the org and writes a one-page note on unused licences, inactive and out-of-date flows, Workflow Rules still in the org, the last test run and org-wide coverage, triggers and flows firing on the same object, code on retiring API versions, Security Health Check risks and limits. Each area gets a finish, cut or rebuild verdict with the rule behind it.

## Install
```
/plugin marketplace add shivanathd/salesforce-org-read
/plugin install mindcat-org-read@mindcat
```
Claude chat and Cowork load the skills and the Salesforce MCP server; the read-only hook runs in Claude Code and Cowork. Cursor reads `.cursor-plugin/plugin.json` and `mcp.json`.

## What it runs, sends and fetches
- **Salesforce hosted MCP server** (`sobject-reads`, read-only by Salesforce's design), signed in with the customer's own Salesforce login. Query results go to the customer's AI client.
- **The customer's `sf` CLI**, through `scripts/org-read-cli.sh`: read-only `sf data query` (including the Tooling API) and `sf org list limits`.
- **Nothing is sent to Mindcat.** The plugin has no server of its own and no telemetry.
- **Read-only hook** (`hooks/read_only_guard.py`): blocks any Salesforce command not on its read-only list, any chained or piped Salesforce command, and fails closed when it can't read a tool call. It never runs `sf org display`, which would print the access token. Use a read-only Salesforce user as well; the hook is a backstop.

## Layout
| Path | What |
| --- | --- |
| `skills/org-read` | Main skill: path choice, checks, wording rules, note |
| `skills/org-connect` | External Client App and sf CLI setup |
| `skills/verdict` | Finish, cut or rebuild rules |
| `scripts/org-read-cli.sh` | Read-only `sf` queries per check |
| `hooks/read_only_guard.py` | Read-only guard for Bash |
| `.mcp.json`, `mcp.json` | Salesforce hosted `sobject-reads` server (Claude, Cursor) |
| `templates/note.md` | The one-page note |
| `tests/` | Guard tests: `python3 -I -m unittest discover -s tests` |

## Support
- Email: apps@mindcat.ai
- Contact: https://mindcat.ai/contact
- Privacy policy: https://mindcat.ai/privacy-policy

## Status
Version 0.1.0. All eight checks have been run against a real Salesforce scratch org. Test coverage can read 0% even after tests run; the note then says coverage was not recorded.

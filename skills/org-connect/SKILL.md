---
name: org-connect
description: Help a Salesforce admin connect the org so the org read can run, either through Salesforce's hosted MCP server or by logging in the sf CLI. Use when the org read cannot reach the org.
---

# Connect the org

The hosted server and the sf CLI sign in separately. Either can point at a different org, so finish with the connection check at the end.

## Hosted MCP server
Available on Enterprise Edition and above, and on Developer Edition orgs. The hosted server may not reach Tooling API objects (coverage, Workflow Rules, Apex versions, Security Health Check), so the full read also needs the sf CLI.

An admin does these once in the org:
1. Turn on the server. Salesforce's standard hosted servers are off by default. In Setup, Quick Find "MCP Servers", open MCP Servers (under API Catalog), then Salesforce Servers, and activate `sobject-reads`.
2. Create an External Client App: Setup > External Client App Manager > New External Client App. Enable OAuth. Scopes: `mcp_api` and `refresh_token`. Under Security, issue JWT-based access tokens for named users. Add the callback URL for the client in use (below). The app can take up to 30 minutes to start working.
3. Copy the Consumer Key: open the app's Settings, then OAuth Settings > Consumer Key and Secret. The Consumer Key is the OAuth Client ID the AI client asks for. Treat it like a setting, not a password, but don't paste it into a public issue.
4. Tell the admin that Salesforce may meter hosted MCP use; check the org's current terms before heavy use.

Then connect the AI client:

**Claude Code**
- Callback URL in the External Client App: `http://localhost:33418/callback` (this plugin's `.mcp.json` fixes the port).
- Run `/mcp`, pick `salesforce-sobject-reads`, and give the Consumer Key when asked for the OAuth Client ID. If your version does not ask, add the server yourself: `claude mcp add --transport http --client-id <consumer key> --callback-port 33418 salesforce-sobject-reads <server URL>`.

**Claude chat and Cowork (claude.ai)**
- Callback URL in the External Client App: `https://claude.ai/api/mcp/auth_callback`.
- Add a custom connector with the server URL, open Advanced settings, and paste the Consumer Key into OAuth Client ID.

**Cursor**
- Callback URLs in the External Client App: `http://localhost:8787/callback`, and also `cursor://anysphere.cursor-mcp/oauth/callback`, which some Cursor versions use. Add both.
- In Cursor's MCP config for `salesforce-sobject-reads`, add the Consumer Key as the auth client ID: `"auth": { "CLIENT_ID": "<consumer key>" }`. The plugin's `mcp.json` ships without a key; each org has its own.

Server URL: `https://api.salesforce.com/platform/mcp/v1/platform/sobject-reads` (sandbox or scratch org: `https://api.salesforce.com/platform/mcp/v1/sandbox/platform/sobject-reads`).

## sf CLI
1. Install the Salesforce CLI if `sf` is not found (the org-read script exits with code 3 when it is missing).
2. `sf org login web --alias <alias>` (add `--instance-url https://test.salesforce.com` for a sandbox).
3. `sf org list` to confirm the alias is connected.
4. If `sf` reports `AuthDecryptError`, the saved login can't be read with the current keychain setting. Ask the user to log in again with step 2, and if that fails, to follow the Salesforce CLI troubleshooting guide for keychain errors.

## Connection check
Run the `org` check on every path that is set up:
- CLI: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> org`
- Hosted: the SOQL tool with `SELECT Id, Name, OrganizationType, IsSandbox FROM Organization`

Each should return one row. If both paths work and the Ids differ, they point at different orgs: fix one before running the read.

## Permissions
The signed-in user needs "View Setup and Configuration" for the setup checks, and API access. To keep the read read-only at the org level, sign in as a user on the standard Read Only profile (confirm it has both permissions), or as a Minimum Access - Salesforce user with a permission set that grants only API Enabled and View Setup and Configuration. Checks the user cannot run are reported as unassessed.

Never run `sf org display`: it prints the org's access token into the conversation.
Do not use the `@salesforce/mcp` DX server: it reaches end of life on 2 Nov 2026.

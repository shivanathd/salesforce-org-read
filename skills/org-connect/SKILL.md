---
name: org-connect
description: Help a Salesforce admin connect the org so the org read can run, either through Salesforce's hosted MCP server or by logging in the sf CLI. Use when the org read cannot reach the org.
---

# Connect the org

The full read needs the sf CLI: the hosted `sobject-reads` server may not reach Tooling API objects. The hosted server is optional and adds record and setup object reads in Claude chat, Cowork and Cursor.

## sf CLI
1. Install the Salesforce CLI (`sf`) from Salesforce's CLI page.
2. `sf org login web --alias <alias>`. For a sandbox add `--instance-url https://test.salesforce.com`; for a My Domain login use the org's own login URL.
3. `sf org list` to confirm the alias is connected.
4. Check: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> org` should print the org's Id and name.
5. If `sf` reports `AuthDecryptError`, the saved login can't be read with the current keychain setting. Ask the user to log in again with step 2, and if that fails, to follow the Salesforce CLI troubleshooting guide for keychain errors.

## Hosted MCP server
Available on Enterprise Edition and up, and on Developer Edition orgs for testing. The steps follow Salesforce's Hosted MCP Servers guide ("Connect MCP Clients").

1. **Turn on the server.** Setup > Quick Find "MCP Servers" > MCP Servers (under API Catalog). Turn on `sobject-reads`. It can take about 2 minutes to become active.
2. **Create an External Client App** (Connected Apps are not supported). Setup > External Client App Manager > New External Client App.
   - Enable OAuth. Scopes: Access MCP servers (`mcp_api`) and Perform requests at any time (`refresh_token`).
   - Keep PKCE on. Under Security, select "Issue JSON Web Token (JWT)-based access tokens for named users".
   - Callback URLs, one per client you use:
     - Claude chat and Cowork (connector on claude.ai): `https://claude.ai/api/mcp/auth_callback`
     - Claude Code with this plugin (`.mcp.json` fixes the port): `http://localhost:33418/callback`
     - Cursor: `http://localhost:8787/callback`, and also `cursor://anysphere.cursor-mcp/oauth/callback` for older Cursor versions
   - Create, then wait: a new app can take up to 30 minutes to work.
   - Settings > OAuth Settings > Consumer Key and Secret: copy the Consumer Key. It is the OAuth client ID, not a secret token.
   - Scratch orgs can't create External Client Apps in Setup; create it in a Dev Hub, package it and install it.
3. **Enter the Consumer Key in each client.** Server URL: `https://api.salesforce.com/platform/mcp/v1/platform/sobject-reads` (sandbox or scratch org: `https://api.salesforce.com/platform/mcp/v1/sandbox/platform/sobject-reads`).
   - Claude chat and Cowork: Customize > Connectors > Add > Add custom connector. Enter the server URL, choose "Use your own OAuth client", paste the Consumer Key as OAuth Client ID, leave the secret blank, then Connect. Claude Code can use the same connector.
   - Claude Code: use the claude.ai connector above, or add a server with the Consumer Key: `claude mcp add --transport http --client-id <consumer key> --callback-port 33418 salesforce <server URL>`, then `/mcp` to sign in.
   - Cursor: in the plugin's `mcp.json`, replace `<consumer key>` under `auth` > `CLIENT_ID` with the Consumer Key.
4. **Check the connection.** Ask the client to run `SELECT Id, Name, IsSandbox, OrganizationType FROM Organization` with the hosted query tool. If the CLI is connected too, the Id must match the CLI `org` check.
5. Tell the admin that Salesforce may meter hosted MCP use; check the org's current terms before heavy use.

## Common errors
- `invalid_client_id` or "unknown client": the Consumer Key is wrong, or the app is less than 30 minutes old.
- Redirect or callback mismatch: the client's callback URL is not in the External Client App.
- `INSUFFICIENT_ACCESS` on a check: the user lacks "View Setup and Configuration" or object access. That check is Unassessed.
- Wrong org: a sandbox needs the sandbox login URL and the sandbox server URL.

Never run `sf org display`: it prints the org's access token into the conversation.
Do not use the `@salesforce/mcp` DX server: it reaches end of life on 2 Nov 2026.

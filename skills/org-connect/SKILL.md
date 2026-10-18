---
name: org-connect
description: Help a Salesforce admin connect the org so the org read can run, either through Salesforce's hosted MCP server or by logging in the sf CLI. Use when the org read cannot reach the org.
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" *)
---

# Connect the org

The hosted server and the sf CLI sign in separately. Either can point at a different org, so finish with the connection check at the end.

**First, read `${CLAUDE_PLUGIN_ROOT}/docs/ground-rules.md` and follow every rule in it.** If you cannot read it, still keep these three:
1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> org`, then `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> whoami`, before any other check; show the org only as "…<last 4 of the 15-character Org Id>", and if `org` fails, never guess an Id.
2. Never run `sf org display` or `sf org open` (any form).
3. Read the org only through that script, or the same SOQL on the hosted path (no other SOQL, no other `sf` command), with only the alias the user named.

## Hosted MCP server
Available on Enterprise Edition and above, and on Developer Edition orgs. The hosted server may not reach Tooling API objects (coverage, Workflow Rules, Apex versions, installed packages, Security Health Check) or org limits, so the full read also needs the sf CLI.

An admin does these once in the org:
1. Turn on the server. Salesforce's standard hosted servers are off by default. In Setup, Quick Find "MCP Servers", open MCP Servers (under API Catalog), then Salesforce Servers, and activate `sobject-reads`.
2. Create an External Client App: Setup > External Client App Manager > New External Client App. Enable OAuth. Scopes: `mcp_api` and `refresh_token`. Under Security, issue JWT-based access tokens for named users. Add the callback URL for the client in use (below). The app can take up to 30 minutes to start working. Scratch orgs: Salesforce's guide says Setup in a scratch org cannot create an External Client App, so create it in the Dev Hub, package it and install it in the scratch org, or use the CLI path instead.
   Also set:
   - Require PKCE.
   - Permitted Users: "Admin approved users are pre-authorized", then give the app only to the read-only user, through a permission set.
   - A refresh token policy that expires tokens, for example after a set number of days without use.
   - `localhost` callbacks are only for clients on the user's own machine (Claude Code, Cursor). claude.ai uses its own https callback.
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
1. Install the Salesforce CLI if `sf` is not found (the org-read script then prints `sf not found` and exits with code 3).
2. Ask the user to run `sf org login web --alias <alias>` themselves. Don't run it for them: it opens a browser sign-in and can point an existing alias at a different org. For a sandbox they add `--instance-url` with the sandbox instance URL:
   - https://test.salesforce.com
3. Run the `org` check (below) to confirm the alias is connected.
4. If `sf` reports `AuthDecryptError`, the saved login can't be read with the current keychain setting. Ask the user to log in again with step 2, and if that fails, to follow the Salesforce CLI troubleshooting guide for keychain errors.

## Connection check
Run the `org` check on every path that is set up:
- CLI: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> org`
- Hosted: the SOQL tool with `SELECT Id, Name, OrganizationType, IsSandbox, NamespacePrefix FROM Organization`

Each should return one row. If both paths work and the Ids differ, they point at different orgs: fix one before running the read. When you name an org to the user, use "…" and the last 4 characters of the 15-character Org Id.

## Permissions
The signed-in user needs "View Setup and Configuration" for the setup checks, and API access. To limit what the login can change, sign in as a Minimum Access - Salesforce user with a permission set that grants only API Enabled, View Setup and Configuration and View All Users. That works in every org. The standard Read Only profile is an alternative where it exists, but some orgs (for example scratch and Developer Edition orgs) have no Read Only profile; if you use it, confirm it has both permissions and add View All Users through a permission set if it lacks it. View All Users lets the licence checks see every user; without it, sharing can hide some and the counts to review come out low. Checks the user cannot run are reported as unassessed. The `whoami` check reads a few key write permissions (Modify All Data, Author Apex, Customize Application, Manage Users); it is not a full review. Neither the Read Only profile nor `whoami` guarantees the login cannot write (for example, Read Only can still allow Chatter posts, and permission sets add access), so never tell the user the org blocks every change; suggest they review the user's effective permissions.

Token commands: see rule 2 at the top (and ground rule 5). Use the `org` check to identify orgs.
Do not use the `@salesforce/mcp` DX server: it reaches end of life on 2 Nov 2026.

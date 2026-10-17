---
name: org-connect
description: Help a Salesforce admin connect the org so the org read can run, either through Salesforce's hosted MCP server or by logging in the sf CLI. Use when the org read cannot reach the org.
---

# Connect the org

## Hosted MCP server
Available on Enterprise Edition and up, and on Developer Edition orgs for testing.
1. Setup > External Client App Manager > New External Client App.
2. Enable OAuth. Scopes: `mcp_api` and `refresh_token`. Issue JWT-based access tokens.
3. Callback URL for the client in use:
   - Claude (claude.ai, Cowork, and Claude Code when the connector is added on claude.ai): `https://claude.ai/api/mcp/auth_callback`
   - Cursor: `http://localhost:8787/callback`
4. Server URL: `https://api.salesforce.com/platform/mcp/v1/platform/sobject-reads` (sandbox: `https://api.salesforce.com/platform/mcp/v1/sandbox/platform/sobject-reads`).
5. Tell the admin that Salesforce may meter hosted MCP use; check the org's current terms before heavy use.

## sf CLI
1. `sf org login web --alias <alias>` (add `--instance-url https://test.salesforce.com` for a sandbox).
2. `sf org list` to confirm the alias is connected.
3. If `sf` reports `AuthDecryptError` on macOS, the login was saved with a different keychain setting. Ask the user to run `export SF_USE_GENERIC_UNIX_KEYCHAIN=true` in their shell (or log in again) and retry.

Never run `sf org display`: it prints the org's access token into the conversation.
Do not use the `@salesforce/mcp` DX server: it reaches end of life on 2 Nov 2026.

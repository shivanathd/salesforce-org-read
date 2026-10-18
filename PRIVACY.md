# Privacy policy: Mindcat Org Read for Salesforce

Effective 18 October 2026. Publisher: Mindcat (Mindcat Technology Consultants FZE), Dubai. Contact: apps@mindcat.ai.

**In short: no data goes to Mindcat. Query results are processed by Salesforce, which runs your org and its hosted MCP server, and by the AI provider you chose for your client, under their own terms.**

## What the plugin reads
Setup and usage data from the Salesforce org you sign in to: the org's Id, name, edition, sandbox flag and namespace (the note and the shareable brief show only the last 4 characters of the 15-character Id, never the name), the signed-in user's own permission flags (true or false only, no name or email), user and licence counts, last-login dates, flows, Workflow Rules, triggers, Apex test results and API versions, security settings, counts of users with Modify All Data, profile and permission set counts, permission set licence counts, names of Named Credentials, Connected Apps and installed packages, counts of background Apex jobs from the last 7 days, org limits, and, for the focused skills: who last changed Apex and flows (names, counted), flow and field descriptions, validation rule names, per-class code coverage and object metadata. It runs only the plugin script's queries, or the same SOQL through the hosted server, and no other SELECT. It never reads business records such as accounts, contacts, opportunities or cases, and does not query Salesforce usernames or email addresses. It does read the names of people who last changed Apex and flows, counted per person, and shows them only in your own output, never in the shareable brief. It reads this with your own Salesforce login, through the Salesforce CLI or Salesforce's hosted MCP server.

## Where it runs
Everything runs in your own AI client (Claude Code, Cowork, Claude apps or Cursor) and on your own machine. What the plugin reads passes through that client's conversation, under that client's own data terms.

## What is stored
The plugin writes nothing to disk unless you ask: to save the one-page note, or for an org book (the `org-book` skill writes, only when you ask for one, a Markdown inventory to the path you choose: the last 4 characters of the 15-character Org Id, edition and sandbox flag (no org name), the read path used, counts, metadata names and unassessed items. If that folder is inside a git repository, the skill warns you first, because the file could get committed). Your Salesforce login is stored by the Salesforce CLI or your AI client, not by the plugin.

## What Mindcat receives
Nothing. The plugin has no Mindcat server, sends no data to Mindcat, and has no analytics or telemetry. Mindcat cannot see your data, your files or your use of the plugin.

## Third parties
The plugin itself sends data to no third party. Queries go from your machine or AI client to your own Salesforce org, through Salesforce's own services. The results are then processed by Salesforce and by the AI provider behind your client (for example Anthropic for Claude), under that provider's terms. Mindcat is not one of them.

## Retention and deletion
Mindcat retains nothing, because it receives nothing. Files the plugin writes are on your disk; delete them when you like. Uninstall the plugin with `/plugin uninstall`.

## Children
The plugin is for businesses and is not intended for anyone under 18.

## Changes and contact
Changes to this policy are published in this file, with a new effective date. Questions: apps@mindcat.ai or https://mindcat.ai/contact. This policy covers the plugin only; https://mindcat.ai/privacy-policy covers the mindcat.ai website.

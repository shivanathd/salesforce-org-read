# Security

Report a security issue privately to apps@mindcat.ai. Do not open a public GitHub issue.

Include what you found, the plugin version and steps to reproduce. Do not send access tokens, passwords or org data. We reply within 5 working days.

The plugin is read-only by design: it runs SELECT queries and `sf org list limits`, adds no hooks, and never runs `sf org display`. A way to make it change an org, print a token or send data anywhere other than the user's own Salesforce org and AI client is in scope.

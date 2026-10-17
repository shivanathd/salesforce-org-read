# Changelog

## 0.2.0
- Outcomes are now Finish, Review, Rebuild (whole org only, when 3 or more strong signals agree) and Unassessed (a check failed). "Cut" became "candidate to cut, confirm with the owner".
- Every finding carries Evidence, Confidence and an outcome. The note header shows the Org Id, name and sandbox flag.
- New `org` check; the skill compares the Org Id from the CLI and the hosted server before combining results.
- New checks: `renewal`, `admin-sprawl`, `permission-debt`, `packages`, `integrations`, `async-failures`, `handover`, `fields`, `inventory`, `object <ObjectApiName>`. Permission set licences added to `licences`.
- `licences` leaves out frozen users and integration licences. `flows` leaves out managed-package flows and lists Process Builder separately.
- `old-code` renamed `legacy-versions`, with Apex on API 30 or lower and 31 to 44 as review items. It no longer says this code breaks.
- Trigger order gaps are no longer flagged; only missing or duplicate TriggerOrder.
- Script checks for `sf` up front and exits 1 when any query failed.
- `object` matches custom objects by their Id, includes managed triggers and lists active Process Builder org-wide. `admin-sprawl` counts distinct users. `renewal` covers paid licences and frozen users.
- New skills: `renewal-prep`, `object-read`. Fuller hosted MCP setup in `org-connect`; Cursor `mcp.json` has the `auth` block.
- `scripts/summarise.py`, unit tests with saved scratch-org output, CI (shellcheck and tests).
- SECURITY, CONTRIBUTING, issue templates, sample note, FAQ and troubleshooting. Help links point to https://mindcat.ai/contact/org-stuck.

## 0.1.0
- First release: licences, flows, workflow, triggers, tests, old-code, security and limits checks, the one-page note and verdict rules.

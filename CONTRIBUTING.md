# Contributing

Thanks for helping. Two rules come first:
- **Read-only.** Every check runs SELECT queries or `sf org list limits` only. No DML, no deploys, no Apex runs, no hooks.
- **Tested queries only.** Add a query only after you have run it against a real org (a free Developer Edition is fine). Say in the PR which org type you used. Never paste org data, tokens or Consumer Keys into an issue or PR.

## Run the CI checks locally
From the repo root:

```
bash -n scripts/org-read-cli.sh
shellcheck scripts/org-read-cli.sh
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json .cursor-plugin/plugin.json .mcp.json mcp.json; do
  python3 -c 'import json, sys; json.load(open(sys.argv[1]))' "$f" && echo "ok $f"
done
```

Install shellcheck with your package manager (`brew install shellcheck`, `apt install shellcheck`) or `pip install shellcheck-py`. If you have the Claude Code CLI, also run `claude plugin validate --strict .`.

## Adding a check
1. Add a `case` to `scripts/org-read-cli.sh`, using `q` (SOQL) or `qt` (Tooling API), each ending in `|| true` through those helpers, with a `LIMIT` on any list.
2. Add its name to the script's usage line and to the check table in `skills/org-read/SKILL.md`.
3. Add wording rules (what it does not prove) to the org-read skill, and say in `skills/verdict/SKILL.md` how it can affect a verdict.
4. Add or update its row in `templates/note.md`, and a line in `CHANGELOG.md` under Unreleased.

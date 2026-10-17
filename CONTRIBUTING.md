# Contributing

Keep the plugin read-only: new checks may only run SELECT queries or `sf org list limits`.

## Run the tests
```
python3 -I -m unittest discover -s tests -v
shellcheck scripts/*.sh
claude plugin validate .
```

## Add or change a check
1. Add the query to `scripts/org-read-cli.sh` under its check name, with a `LIMIT` on any list.
2. Run it against a scratch or Developer Edition org: `bash scripts/org-read-cli.sh <alias> <check>`, and confirm `"status": 0`.
3. Add the check to the table in `skills/org-read/SKILL.md` and, if it changes an outcome, to `skills/verdict/SKILL.md`.
4. If you save its output as a test fixture, use a scratch org and remove Ids, names and file paths you don't need.

Never paste tokens, passwords or customer org data into an issue, commit or fixture.

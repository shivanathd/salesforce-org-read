"""Run: python3 -I -m unittest discover -s tests (from the plugin root)."""
import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GUARD = ROOT / "hooks" / "read_only_guard.py"
SCRIPT = ROOT / "scripts" / "org-read-cli.sh"

ALLOW = ["sf data query -q 'SELECT Id FROM Account'",
         "sf data query --query \"SELECT Id FROM User\" --result-format csv --output-file out.csv",
         "sf org list limits --target-org acme", "sf org list",
         "sf org login web --alias acme --instance-url https://test.salesforce.com", "sf --version",
         f"bash {SCRIPT} acme licences", f'bash "{SCRIPT}" acme flows', "ls -la", "git status", "npm test"]
DENY = ["sf data delete record -s Account -i 001",
        "sf data query -q x | sf data delete bulk -s Account -f -",
        "sf data query -q x`sf project deploy start`",
        "sf data query -q \"$(sf data delete record -s Account -i 001)\"",
        "sf data query -q x\nsf data delete record -s Account -i 001",
        "sf data query -q x > /etc/passwd", "sf data query -q x & sf data delete record -s A -i 1",
        "FOO=1 sf data delete record -s A -i 1", "command sf data delete record",
        "/usr/local/bin/sf data delete record", "sfdx force:data:record:delete -s A -i 1",
        "npx @salesforce/cli data delete record -s A -i 1",
        "curl -X DELETE https://x.my.salesforce.com/services/data/v62.0/sobjects/Account/001",
        "\"sf\" data delete record -s A -i 1", "s'f' data delete record", "sf\tdata delete record -s A -i 1",
        "env sf data delete record", "sf apex run -f x.apex", "sf apex run test",
        "bash /tmp/evil/scripts/org-read-cli.sh x licences", "bash -c 'sf data delete record -s A -i 1'",
        "x=sf; $x data delete record", "sf data update record -s A -i 1 -v Name=x", "sf data querydelete",
        "sf org display --verbose", f"bash {SCRIPT} acme rm", f"bash {SCRIPT} 'a b' licences",
        "sf project deploy start"]


def code(payload):
    raw = payload if isinstance(payload, str) else json.dumps(payload)
    return subprocess.run([sys.executable, "-I", str(GUARD)], input=raw, capture_output=True, text=True).returncode


class Guard(unittest.TestCase):
    def test_allowed(self):
        for c in ALLOW:
            with self.subTest(c=c):
                self.assertEqual(code({"tool_name": "Bash", "tool_input": {"command": c}}), 0)

    def test_blocked(self):
        for c in DENY:
            with self.subTest(c=c):
                self.assertEqual(code({"tool_name": "Bash", "tool_input": {"command": c}}), 2)

    def test_fails_closed(self):
        for raw in ["not json", "{}", json.dumps({"tool_name": "Bash", "tool_input": None})]:
            with self.subTest(raw=raw):
                self.assertEqual(code(raw), 2)

    def test_other_tools_pass(self):
        self.assertEqual(code({"tool_name": "Read", "tool_input": {"file_path": "x"}}), 0)


if __name__ == "__main__":
    unittest.main()

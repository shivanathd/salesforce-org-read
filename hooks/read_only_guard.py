"""PreToolUse guard: Salesforce commands may only read. Fails closed (exit 2) on anything it can't parse."""
import json
import os
import re
import shlex
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPT = str(ROOT / "scripts" / "org-read-cli.sh")
CHECKS = {"licences", "flows", "workflow", "triggers", "tests", "old-code", "security", "limits"}
SF_WORDS = re.compile(r"(?<![\w-])(sf|sfdx)(?![\w-])|@salesforce/cli|salesforce\.com|force\.com|org-read-cli")
META = re.compile(r"[|&;<>`$(){}\\\n\r]")
ALLOWED = [("data", "query"), ("org", "list"), ("apex", "get", "test"), ("apex", "list", "log"),
           ("sobject", "describe"), ("sobject", "list"), ("org", "login", "web"), ("--version",)]


def block(why):
    print(f"mindcat-org-read is read-only: {why}", file=sys.stderr)
    sys.exit(2)


try:
    data = json.load(sys.stdin)
    if data["tool_name"] != "Bash":
        sys.exit(0)
    cmd = data["tool_input"]["command"]
    if not isinstance(cmd, str):
        raise TypeError
except SystemExit:
    raise
except Exception:
    block("could not read the tool call, so it is blocked")

if not SF_WORDS.search(re.sub(r"[\"'\\]", "", cmd)):
    sys.exit(0)
if META.search(cmd):
    block("Salesforce commands must be a single plain command (no pipes, chaining, redirects or substitution)")
try:
    argv = shlex.split(cmd)
except ValueError:
    block("could not parse the command")

if argv[:1] == ["bash"] and len(argv) == 4 and os.path.realpath(argv[1]) == os.path.realpath(SCRIPT):
    if re.fullmatch(r"[\w.@-]+", argv[2]) and argv[3] in CHECKS:
        sys.exit(0)
    block("org-read-cli.sh takes an org alias and one known check")
if argv[:1] == ["sf"] and any(tuple(argv[1:1 + len(a)]) == a for a in ALLOWED):
    sys.exit(0)
block(f"'{cmd}' is not on the read-only list")

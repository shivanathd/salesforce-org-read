"""Summarise the JSON that org-read-cli.sh prints for one check.

Usage: bash org-read-cli.sh <alias> <check> | python3 -I summarise.py <check>

Prints one JSON object: per query, whether it worked, its row count (or COUNT() value),
whether it hit the 200-row cap, and the error name when it failed. A check with a failed
query is marked Unassessed (all failed) or Partial (some failed). Standard library only.
"""
import json
import sys

ROW_CAP = 200
ROW_CAPS = {"fields": 2000}


def split_documents(text):
    """Return every JSON document in text, in order (sf prints one per query)."""
    decoder = json.JSONDecoder(strict=False)
    docs, i = [], 0
    while True:
        while i < len(text) and text[i].isspace():
            i += 1
        if i >= len(text):
            return docs
        try:
            doc, i = decoder.raw_decode(text, i)
        except json.JSONDecodeError:
            # Skip a non-JSON line (for example a CLI notice) and keep going.
            nl = text.find("\n", i)
            if nl == -1:
                return docs
            i = nl + 1
            continue
        docs.append(doc)


def summarise_query(doc, cap=ROW_CAP):
    if doc.get("status") != 0:
        return {"ok": False, "error": doc.get("name") or "UnknownError"}
    result = doc.get("result")
    if isinstance(result, list):  # sf org list limits
        return {"ok": True, "rows": len(result), "capped": False}
    records = (result or {}).get("records") or []
    out = {"ok": True, "rows": (result or {}).get("totalSize", len(records))}
    if len(records) == 1 and all(k in ("attributes", "expr0") for k in records[0]):
        out["count"] = records[0].get("expr0")
    out["capped"] = out["rows"] >= cap
    return out


def summarise(check, text):
    cap = ROW_CAPS.get(check, ROW_CAP)
    queries = [summarise_query(d, cap) for d in split_documents(text) if isinstance(d, dict)]
    failed = sum(1 for q in queries if not q["ok"])
    if not queries or failed == len(queries):
        outcome = "Unassessed"
    elif failed:
        outcome = "Partial"
    else:
        outcome = "Assessed"
    return {"check": check, "outcome": outcome, "queries": queries}


def main(argv):
    check = argv[1] if len(argv) > 1 else "unknown"
    print(json.dumps(summarise(check, sys.stdin.read()), indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

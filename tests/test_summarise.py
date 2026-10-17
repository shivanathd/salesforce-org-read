"""Run from the repo root: python3 -I -m unittest discover -s tests"""
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "scripts"))

import summarise  # noqa: E402


def fixture(name):
    with open(os.path.join(HERE, "fixtures", name)) as fh:
        return fh.read()


class SummariseTest(unittest.TestCase):
    def test_single_query_assessed(self):
        s = summarise.summarise("org", fixture("org.json"))
        self.assertEqual(s["outcome"], "Assessed")
        self.assertEqual(s["queries"], [{"ok": True, "rows": 1, "capped": False}])

    def test_list_rows(self):
        s = summarise.summarise("flows", fixture("flows.json"))
        self.assertEqual(s["outcome"], "Assessed")
        self.assertEqual(s["queries"], [{"ok": True, "rows": 3, "capped": False}])

    def test_distinct_users_are_rows(self):
        s = summarise.summarise("admin-sprawl", fixture("admin-sprawl.json"))
        self.assertEqual(s["queries"], [{"ok": True, "rows": 1, "capped": False}])

    def test_two_count_queries_in_one_output(self):
        s = summarise.summarise("permission-debt", fixture("permission-debt.json"))
        self.assertEqual([q["count"] for q in s["queries"]], [1, 0])

    def test_failed_check_is_unassessed(self):
        s = summarise.summarise("org", fixture("error.json"))
        self.assertEqual(s["outcome"], "Unassessed")
        self.assertEqual(s["queries"], [{"ok": False, "error": "NamedOrgNotFoundError"}])

    def test_some_failed_is_partial(self):
        s = summarise.summarise("triggers", fixture("triggers-partial.json"))
        self.assertEqual(s["outcome"], "Partial")
        self.assertEqual([q["ok"] for q in s["queries"]], [True, False])

    def test_empty_output_is_unassessed(self):
        self.assertEqual(summarise.summarise("tests", "")["outcome"], "Unassessed")

    def test_capped_only_at_the_querys_limit(self):
        doc = '{"status": 0, "result": {"records": [], "totalSize": 200}}'
        self.assertTrue(summarise.summarise("flows", doc)["queries"][0]["capped"])  # LIMIT 200
        self.assertFalse(summarise.summarise("fields", doc)["queries"][0]["capped"])  # LIMIT 2000
        self.assertFalse(summarise.summarise("licences", doc)["queries"][0]["capped"])  # no LIMIT

    def test_limits_read_from_script(self):
        script = summarise.read_script()
        self.assertEqual(summarise.query_limits("tests", script), [5, None])
        self.assertEqual(summarise.query_limits("limits", script), [None])
        self.assertEqual(summarise.query_limits("object", script), [None, 200, 200, 200, None, 200])


if __name__ == "__main__":
    unittest.main()

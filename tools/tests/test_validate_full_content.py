"""Deep checks for the complete offline bank and campaign."""

import copy
import importlib
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))


class FullContentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        bank_path = ROOT / "game/data/banks/bank_4x4.json"
        pace_path = ROOT / "game/data/banks/bank_4x4.pace.json"
        cls.level = json.loads(bank_path.read_text(encoding="utf-8"))["ranks"]["1"][0]
        cls.pace_entry = json.loads(pace_path.read_text(encoding="utf-8"))["pacing"]["1"][0]

    def validator(self):
        try:
            return importlib.import_module("validate_full_content")
        except ModuleNotFoundError:
            self.fail("validate_full_content module is missing")

    def mini_bank(self, levels=None, pace_entries=None):
        if levels is None:
            levels = [copy.deepcopy(self.level)]
        if pace_entries is None:
            pace_entries = [copy.deepcopy(self.pace_entry) for _ in levels]
        bank = {"bankVersion": 1, "size": 4, "ranks": {"1": levels}}
        pace = {"bankVersion": 1, "size": 4, "pacing": {"1": pace_entries}}
        return bank, pace

    def test_valid_bank_and_pace_pass_deep_check(self):
        bank, pace = self.mini_bank()
        errors = self.validator().validate_full_banks(
            {4: bank}, {4: pace}, {4: {"1": 1}})
        self.assertEqual(errors, [])

    def test_target_count_and_duplicate_geometry_rejected(self):
        bank, pace = self.mini_bank()
        errors = self.validator().validate_full_banks(
            {4: bank}, {4: pace}, {4: {"1": 2}})
        self.assertTrue(any("count" in error.lower() for error in errors), errors)
        bank, pace = self.mini_bank([copy.deepcopy(self.level), copy.deepcopy(self.level)])
        errors = self.validator().validate_full_banks(
            {4: bank}, {4: pace}, {4: {"1": 2}})
        self.assertTrue(any("duplicate geometry" in error.lower() for error in errors), errors)

    def test_multiple_solutions_and_invalid_trace_rejected(self):
        bad = copy.deepcopy(self.level)
        bad["regions"] = ["ABCD"] * 4
        bank, pace = self.mini_bank([bad])
        errors = self.validator().validate_full_banks(
            {4: bank}, {4: pace}, {4: {"1": 1}})
        self.assertTrue(any("at least two" in error.lower() for error in errors), errors)

        bad = copy.deepcopy(self.level)
        bad["logicTrace"] = []
        bank, pace = self.mini_bank([bad])
        errors = self.validator().validate_full_banks(
            {4: bank}, {4: pace}, {4: {"1": 1}})
        self.assertTrue(any("trace" in error.lower() for error in errors), errors)

    def test_pace_must_match_trace(self):
        bank, pace = self.mini_bank()
        pace["pacing"]["1"][0]["rSeq"][0] = 2
        errors = self.validator().validate_full_banks(
            {4: bank}, {4: pace}, {4: {"1": 1}})
        self.assertTrue(any("rSeq" in error for error in errors), errors)

    def test_full_playlist_requires_coverage_and_demo_prefix(self):
        bank, _ = self.mini_bank()
        demo_entry = {"label": "L01", "size": 4, "rank": 1, "index": 0,
                      "difficulty": "tutorial"}
        demo = {"campaignVersion": 1, "id": "demo", "playlist": [demo_entry]}
        full = {"campaignVersion": 1, "id": "full", "playlist": [demo_entry]}
        validate = self.validator().validate_full_playlist
        self.assertEqual(validate(full, demo, {4: bank}), [])

        bank["ranks"]["1"].append(copy.deepcopy(self.level))
        errors = validate(full, demo, {4: bank})
        self.assertTrue(any("missing" in error.lower() for error in errors), errors)

        full["playlist"] = [dict(demo_entry, index=1), dict(demo_entry, label="L02")]
        errors = validate(full, demo, {4: bank})
        self.assertTrue(any("prefix" in error.lower() for error in errors), errors)

        full["playlist"] = [demo_entry, dict(demo_entry, label="L02")]
        errors = validate(full, demo, {4: bank})
        self.assertTrue(any("duplicate" in error.lower() for error in errors), errors)


if __name__ == "__main__":
    unittest.main()

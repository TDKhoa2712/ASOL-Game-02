"""Tests for convert_extracted_bank."""
import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT / "tools") not in sys.path:
    sys.path.insert(0, str(ROOT / "tools"))
if str(ROOT / "GDD" / "tools") not in sys.path:
    sys.path.insert(0, str(ROOT / "GDD" / "tools"))

from convert_extracted_bank import (
    convert_region_map,
    convert_level,
    convert_bank_file,
    convert_level_fast,
    convert_flat_bank,
    BANK_REGISTRY,
)



class TestConvertExtractedBank(unittest.TestCase):
    def test_convert_region_map_simple(self):
        region_map = [[0, 1], [1, 0]]
        self.assertEqual(convert_region_map(region_map), ["AB", "BA"])

    def test_convert_region_map_7x7(self):
        region_map = [
            [1, 1, 1, 1, 1, 1, 0],
            [1, 1, 1, 1, 0, 0, 0],
            [1, 6, 6, 1, 0, 2, 4],
            [3, 6, 4, 1, 4, 4, 4],
            [6, 6, 4, 4, 4, 6, 4],
            [6, 4, 4, 6, 5, 6, 4],
            [6, 6, 6, 6, 6, 6, 6],
        ]
        result = convert_region_map(region_map)
        self.assertEqual(len(result), 7)
        self.assertTrue(all(len(row) == 7 for row in result))
        self.assertEqual(result[0], "BBBBBBA")
        self.assertEqual(result[6], "GGGGGGG")

    def test_convert_level_fields(self):
        raw = {
            "seed": 7,
            "regionMap": [
                [3, 3, 0, 3],
                [1, 3, 3, 3],
                [3, 3, 2, 2],
                [3, 3, 3, 2],
            ],
            "solution": [2, 0, 3, 1],
            "r": 1,
            "steps": 4,
            "r1": 4,
            "r2": 0,
            "r3": 0,
            "r4": 0,
            "r5": 0,
            "_pid_h": "6c95fe9a6ddb2ce1",
            "_pid_s": [6, 7, 4, 5, 2, 3, 0, 1],
        }
        level = convert_level(raw, size=4)
        self.assertIsNotNone(level)
        self.assertEqual(level["seed"], 7)
        self.assertEqual(level["regions"], ["DDAD", "BDDD", "DDCC", "DDDC"])
        self.assertEqual(level["solution"], [2, 0, 3, 1])
        self.assertEqual(level["givens"], [])
        self.assertIsInstance(level["steps"], int)
        self.assertIsInstance(level["profile"], list)
        self.assertEqual(len(level["profile"]), 3)
        self.assertIsInstance(level["pidHash"], str)
        self.assertEqual(len(level["pidHash"]), 8)
        self.assertIsInstance(level["logicTrace"], list)
        self.assertIsInstance(level["rating"], (int, float))

    def test_convert_bank_file_produces_valid_schema(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir)
            source = {
                "1": [
                    {
                        "seed": 7,
                        "regionMap": [
                            [3, 3, 0, 3],
                            [1, 3, 3, 3],
                            [3, 3, 2, 2],
                            [3, 3, 3, 2],
                        ],
                        "solution": [2, 0, 3, 1],
                        "r": 1,
                        "steps": 4,
                        "r1": 4,
                        "r2": 0,
                        "r3": 0,
                        "r4": 0,
                        "r5": 0,
                        "_pid_h": "6c95fe9a6ddb2ce1",
                        "_pid_s": [6, 7, 4, 5, 2, 3, 0, 1],
                    }
                ],
            }
            source_path = tmp_path / "source.json"
            source_path.write_text(json.dumps(source))
            out_bank = tmp_path / "bank.json"
            out_pace = tmp_path / "pace.json"

            convert_bank_file(str(source_path), size=4, bank_output=str(out_bank), pace_output=str(out_pace))

            bank = json.loads(out_bank.read_text())
            self.assertEqual(bank["bankVersion"], 1)
            self.assertEqual(bank["size"], 4)
            self.assertIn("1", bank["ranks"])
            self.assertEqual(len(bank["ranks"]["1"]), 1)

            pace = json.loads(out_pace.read_text())
            self.assertEqual(pace["bankVersion"], 1)
            self.assertEqual(pace["size"], 4)
            self.assertIn("1", pace["pacing"])
            self.assertEqual(len(pace["pacing"]["1"]), 1)

    def test_convert_level_fallback_when_offline_solver_stuck(self):
        # A valid level that requires advanced logic
        raw = {
            "seed": 99,
            "regionMap": [
                [0, 0, 1, 1],
                [0, 0, 1, 1],
                [2, 2, 3, 3],
                [2, 2, 3, 3],
            ],
            "solution": [1, 3, 0, 2],
            "r": 5,
            "steps": 6,
            "r1": 4,
            "r2": 1,
            "r3": 1,
            "r4": 0,
            "r5": 0,
            "rating": 500,
            "_pid_h": "deadbeef",
        }
        level = convert_level(raw, size=4)
        self.assertIsNotNone(level)
        self.assertEqual(level["solution"], [1, 3, 0, 2])
        self.assertEqual(level["profile"], [4, 1, 1])
        self.assertEqual(level["steps"], 6)
        self.assertEqual(level["rating"], 500)
        self.assertEqual(level["pidHash"], "deadbeef")
        self.assertGreaterEqual(len(level["logicTrace"]), 4)

    def test_convert_level_fast(self):
        raw = {
            "seed": 42,
            "regionMap": [
                [0, 0, 1, 1],
                [0, 0, 1, 1],
                [2, 2, 3, 3],
                [2, 2, 3, 3],
            ],
            "solution": [1, 3, 0, 2],
            "r": 2,
            "steps": 4,
            "r1": 2,
            "r2": 2,
            "r3": 0,
            "_pid_h": "abcdef123456",
            "colorMap": {"A": 1},
            "shapeCategory": 5,
        }
        level = convert_level_fast(raw, size=4, extra_fields=["colorMap", "shapeCategory"])
        self.assertIsNotNone(level)
        self.assertEqual(level["seed"], 42)
        self.assertEqual(level["solution"], [1, 3, 0, 2])
        self.assertEqual(level["regions"], ["AABB", "AABB", "CCDD", "CCDD"])
        self.assertEqual(level["profile"], [2, 2, 0])
        self.assertEqual(level["pidHash"], "abcdef12")
        self.assertEqual(level["logicTrace"], [])
        self.assertEqual(level["colorMap"], {"A": 1})
        self.assertEqual(level["shapeCategory"], 5)

    def test_convert_flat_bank_schema_and_pace(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir)
            source_levels = [
                {
                    "id": "SP_01",
                    "size": 4,
                    "regionMap": [
                        [0, 0, 1, 1],
                        [0, 0, 1, 1],
                        [2, 2, 3, 3],
                        [2, 2, 3, 3],
                    ],
                    "solution": [1, 3, 0, 2],
                    "r": 1,
                    "steps": 4,
                    "r1": 4,
                    "r2": 0,
                    "_pid_h": "feedface1122",
                    "shapeCategory": 2,
                }
            ]
            source_path = tmp_path / "bankDataSP_test.json"
            source_path.write_text(json.dumps({"levels": source_levels}))
            out_bank = tmp_path / "bank_sp.json"
            out_pace = tmp_path / "bank_sp.pace.json"

            result = convert_flat_bank(
                str(source_path),
                bank_type="sp",
                output=str(out_bank),
                pace_output=str(out_pace),
                extra_fields=["shapeCategory", "id"],
                fast=True,
            )
            self.assertEqual(result["accepted"], 1)
            self.assertEqual(result["skipped"], 0)

            bank = json.loads(out_bank.read_text())
            self.assertEqual(bank["bankVersion"], 1)
            self.assertEqual(bank["type"], "sp")
            self.assertEqual(len(bank["levels"]), 1)
            self.assertEqual(bank["levels"][0]["size"], 4)
            self.assertEqual(bank["levels"][0]["rank"], 1)
            self.assertEqual(bank["levels"][0]["shapeCategory"], 2)
            self.assertEqual(bank["levels"][0]["id"], "SP_01")

            pace = json.loads(out_pace.read_text())
            self.assertEqual(pace["bankVersion"], 1)
            self.assertEqual(pace["type"], "sp")
            self.assertEqual(len(pace["levels"]), 1)
            self.assertEqual(len(pace["levels"][0]["rSeq"]), 4)
            self.assertEqual(len(pace["levels"][0]["hintCosts"]), 4)

    def test_bank_registry_completeness(self):
        expected_types = {
            "regular", "lkstyle", "gc", "onefish",
            "sp", "lk", "lk_modified", "sp_tt", "single_region", "super_hard"
        }
        self.assertTrue(expected_types.issubset(set(BANK_REGISTRY.keys())))


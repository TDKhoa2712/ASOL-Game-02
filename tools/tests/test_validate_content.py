"""Unit tests for tools/validate_content.py."""
import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT / "tools") not in sys.path:
    sys.path.insert(0, str(ROOT / "tools"))

from validate_content import validate_bank, validate_pace_against_bank, validate_playlist, validate_file


class ValidateContentTests(unittest.TestCase):
    def setUp(self):
        self.valid_level = {
            "seed": 7,
            "regions": ["CAAB", "CBBB", "CCBB", "CCDB"],
            "solution": [1, 3, 0, 2],
            "givens": [],
            "steps": 4,
            "profile": [4, 0, 0],
            "rating": 4,
            "pidHash": "6c95fe9a",
            "logicTrace": [{"rule": "S2"}] * 4
        }
        self.valid_bank = {
            "bankVersion": 1,
            "size": 4,
            "ranks": {
                "1": [self.valid_level]
            }
        }
        self.valid_pace = {
            "bankVersion": 1,
            "size": 4,
            "pacing": {
                "1": [
                    {"rSeq": [1, 1, 1, 1], "hintCosts": [1, 1, 1, 1]}
                ]
            }
        }
        self.valid_playlist = {
            "campaignVersion": 1,
            "id": "demo-30",
            "playlist": [
                {"label": "L01", "size": 4, "rank": 1, "index": 0, "difficulty": "tutorial"}
            ]
        }

    def test_valid_bank(self):
        errors = validate_bank(self.valid_bank)
        self.assertEqual(errors, [])

    def test_bank_invalid_version(self):
        bad_bank = dict(self.valid_bank, bankVersion=2)
        errors = validate_bank(bad_bank)
        self.assertTrue(any("bankVersion" in e for e in errors))

    def test_bank_invalid_geometry(self):
        bad_bank = dict(self.valid_bank)
        bad_level = dict(self.valid_level, regions=["CAAB", "CBBB"])
        bad_bank["ranks"] = {"1": [bad_level]}
        errors = validate_bank(bad_bank)
        self.assertTrue(len(errors) > 0)

    def test_bank_adjacent_solution_rejected(self):
        bad_bank = dict(self.valid_bank)
        bad_level = dict(self.valid_level, solution=[0, 1, 2, 3])
        bad_bank["ranks"] = {"1": [bad_level]}
        errors = validate_bank(bad_bank)
        self.assertTrue(len(errors) > 0)

    def test_valid_pace_against_bank(self):
        errors = validate_pace_against_bank(self.valid_pace, self.valid_bank)
        self.assertEqual(errors, [])

    def test_pace_count_mismatch(self):
        bad_pace = {
            "bankVersion": 1,
            "size": 4,
            "pacing": {"1": []}
        }
        errors = validate_pace_against_bank(bad_pace, self.valid_bank)
        self.assertTrue(any("mismatch" in e.lower() or "count" in e.lower() for e in errors))

    def test_valid_playlist(self):
        errors = validate_playlist(self.valid_playlist)
        self.assertEqual(errors, [])

    def test_playlist_duplicate_labels(self):
        bad_playlist = {
            "campaignVersion": 1,
            "id": "demo-30",
            "playlist": [
                {"label": "L01", "size": 4, "rank": 1, "index": 0, "difficulty": "tutorial"},
                {"label": "L01", "size": 4, "rank": 1, "index": 0, "difficulty": "tutorial"}
            ]
        }
        errors = validate_playlist(bad_playlist)
        self.assertTrue(any("duplicate" in e.lower() for e in errors))

    def test_playlist_duplicate_bank_reference(self):
        playlist = dict(self.valid_playlist)
        playlist["playlist"] = [
            {"label": "L01", "size": 4, "rank": 1, "index": 0, "difficulty": "tutorial"},
            {"label": "L02", "size": 4, "rank": 1, "index": 0, "difficulty": "easy"},
        ]
        errors = validate_playlist(playlist, banks={4: self.valid_bank})
        self.assertTrue(any("duplicate" in error.lower() and "reference" in error.lower()
                            for error in errors), errors)

    def test_invalid_index_reports_error_with_bank(self):
        playlist = dict(self.valid_playlist)
        playlist["playlist"] = [dict(self.valid_playlist["playlist"][0], index=None)]
        errors = validate_playlist(playlist, banks={4: self.valid_bank})
        self.assertTrue(any("invalid index" in error.lower() for error in errors), errors)

    def test_playlist_against_bank(self):
        errors = validate_playlist(self.valid_playlist, banks={4: self.valid_bank})
        self.assertEqual(errors, [])

    def test_playlist_missing_bank_index(self):
        bad_playlist = {
            "campaignVersion": 1,
            "id": "demo-30",
            "playlist": [
                {"label": "L01", "size": 4, "rank": 1, "index": 99, "difficulty": "tutorial"}
            ]
        }
        errors = validate_playlist(bad_playlist, banks={4: self.valid_bank})
        self.assertTrue(any("index" in e.lower() for e in errors))


if __name__ == "__main__":
    unittest.main()

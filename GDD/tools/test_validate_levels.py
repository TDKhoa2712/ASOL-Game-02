"""Focused contract tests for the level and S2/S3 proof validator."""

import copy
import json
import unittest
from pathlib import Path

from validate_levels import (
    canonical_regions,
    count_solutions,
    exclusion_reason,
    object_no_duplicates,
    s2_only_reaches_solution,
    validate_document,
    validate_level,
    validate_release_logic_band,
)


SAMPLE = Path(__file__).resolve().parents[1] / "data" / "levels.sample.json"


class LevelValidatorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.levels = json.loads(SAMPLE.read_text(encoding="utf-8"))["levels"]

    def level(self, index=0):
        return copy.deepcopy(self.levels[index])

    def s3_level(self):
        return copy.deepcopy(next(level for level in self.levels if level["id"] == "S301"))

    def test_fixtures_have_independent_unique_solutions_and_proof_traces(self):
        ordered, warnings = validate_document({"levels": copy.deepcopy(self.levels)})
        self.assertEqual([level["id"] for level in ordered], ["T01", "E01", "E02", "N12", "S301"])
        self.assertEqual(warnings, [])

    def test_s3_fixture_is_machine_checked(self):
        self.assertIsInstance(validate_level(self.s3_level()), str)

    def test_s3_rejects_source_not_contained_in_target(self):
        level = self.s3_level()
        level["logicTrace"][0]["target"] = {"type": "row", "id": 1}
        with self.assertRaisesRegex(ValueError, "source candidates.*contained"):
            validate_level(level)

    def test_s3_rejects_incomplete_conclusion_and_noop(self):
        level = self.s3_level()
        level["logicTrace"][0]["conclusion"]["cells"].pop()
        with self.assertRaisesRegex(ValueError, "conclusion cells"):
            validate_level(level)
        level = self.s3_level()
        level["logicTrace"].insert(1, copy.deepcopy(level["logicTrace"][0]))
        with self.assertRaisesRegex(ValueError, "new candidate"):
            validate_level(level)

    def test_s3_rejects_malformed_units_cells_and_text_key(self):
        mutations = []

        same_unit_type = self.s3_level()
        same_unit_type["logicTrace"][0]["target"] = {"type": "region", "id": "B"}
        mutations.append((same_unit_type, "different unit types"))

        duplicate_cell = self.s3_level()
        duplicate_cell["logicTrace"][0]["conclusion"]["cells"].append({"r": 0, "c": 2})
        mutations.append((duplicate_cell, "duplicate S3 conclusion cell"))

        out_of_bounds = self.s3_level()
        out_of_bounds["logicTrace"][0]["conclusion"]["cells"][0] = {"r": 4, "c": 2}
        mutations.append((out_of_bounds, "out of bounds"))

        wrong_text_key = self.s3_level()
        wrong_text_key["logicTrace"][0]["textKey"] = "hint.single.region"
        mutations.append((wrong_text_key, "S3 textKey"))

        solved_unit = self.s3_level()
        solved_unit["givens"] = [{"r": 0, "c": 1}]
        mutations.append((solved_unit, "must not already contain a cat"))

        for level, message in mutations:
            with self.subTest(message=message):
                with self.assertRaisesRegex(ValueError, message):
                    validate_level(level)

    def test_release_logic_bands(self):
        early = self.s3_level()
        early["order"] = 18
        with self.assertRaisesRegex(ValueError, "orders 1..18"):
            validate_release_logic_band(early)
        late = self.level()
        late["order"] = 19
        with self.assertRaisesRegex(ValueError, "orders 19..24"):
            validate_release_logic_band(late)
        unnecessary = self.level()
        unnecessary["order"] = 19
        unnecessary["logicTrace"].insert(0, {
            "rule": "S3",
            "source": {"type": "region", "id": "A"},
            "target": {"type": "row", "id": 0},
            "conclusion": {
                "type": "eliminate",
                "cells": [{"r": 0, "c": 0}, {"r": 0, "c": 2}, {"r": 0, "c": 3}],
            },
            "textKey": "hint.lock.intersection",
        })
        self.assertIsInstance(validate_level(unnecessary), str)
        self.assertTrue(s2_only_reaches_solution(unnecessary))
        with self.assertRaisesRegex(ValueError, "must require S3"):
            validate_release_logic_band(unnecessary)
        required = self.s3_level()
        required["order"] = 19
        self.assertFalse(s2_only_reaches_solution(required))
        validate_release_logic_band(required)

    def test_s1_witness_distinguishes_row_and_diagonal(self):
        rows = self.level()["regions"]
        self.assertEqual(exclusion_reason(rows, {0: 1}, (0, 0)),
                         {"sourceCat": (0, 1), "reason": "row"})
        self.assertEqual(exclusion_reason(rows, {0: 1}, (1, 0)),
                         {"sourceCat": (0, 1), "reason": "diagonal"})
        self.assertIsNone(exclusion_reason(rows, {0: 1}, (1, 3)))

    def test_solver_rejects_multiple_and_zero_solutions(self):
        stripes = ["AAAA", "BBBB", "CCCC", "DDDD"]
        self.assertEqual(len(count_solutions(stripes, {}, limit=2)), 2)
        self.assertEqual(count_solutions(stripes, {0: 0, 1: 1}), [])
        with self.assertRaisesRegex(ValueError, "search budget exceeded"):
            count_solutions(stripes, {}, max_nodes=0)

    def test_n12_fixture_and_n13_limit(self):
        self.assertIsInstance(validate_level(self.level(3)), str)
        level = self.level(3)
        level["size"] = 13
        with self.assertRaisesRegex(ValueError, "4 to 12"):
            validate_level(level)

    def test_rejects_wrong_declared_solution(self):
        level = self.level()
        level["solution"] = [2, 0, 3, 1]
        with self.assertRaisesRegex(ValueError, "declared solution differs"):
            validate_level(level)

    def test_rejects_disconnected_region(self):
        level = self.level()
        level["regions"][0] = "CABD"
        with self.assertRaisesRegex(ValueError, "disconnected"):
            validate_level(level)

    def test_rejects_unproved_s2_step(self):
        level = self.level()
        level["logicTrace"][0]["focus"] = {"type": "row", "id": 0}
        level["logicTrace"][0]["textKey"] = "hint.single.row"
        with self.assertRaisesRegex(ValueError, "trace step 1: focus candidates"):
            validate_level(level)

    def test_rejects_wrong_hint_key_and_old_trace_field(self):
        level = self.level()
        level["logicTrace"][0]["textKey"] = "hint.single.row"
        with self.assertRaisesRegex(ValueError, "textKey"):
            validate_level(level)
        level = self.level()
        level["logicTrace"][0]["eliminatedCells"] = []
        with self.assertRaisesRegex(ValueError, "extra.*eliminatedCells"):
            validate_level(level)

    def test_rejects_old_schema_bool_integer_and_unknown_field(self):
        for field, value, message in (
            ("schemaVersion", 3, "schemaVersion"),
            ("size", True, "size"),
            ("extra", 1, "extra"),
            ("chapter", 1, "chapter"),
        ):
            with self.subTest(field=field):
                level = self.level()
                level[field] = value
                with self.assertRaisesRegex(ValueError, message):
                    validate_level(level)

    def test_rejects_duplicate_json_keys(self):
        with self.assertRaisesRegex(ValueError, "duplicate JSON key"):
            json.loads('{"levels":[],"levels":[]}', object_pairs_hook=object_no_duplicates)

    def test_duplicate_shape_is_warning_for_fixture(self):
        first = self.level()
        second = self.level()
        second["id"] = "T02"
        second["order"] = 2
        _, warnings = validate_document({"levels": [first, second]})
        self.assertEqual(len(warnings), 1)

    def test_shape_canonicalization_handles_rotation_and_region_renaming(self):
        rows = self.level()["regions"]
        n = len(rows)
        rotated = ["".join(rows[n - 1 - c][r] for c in range(n)) for r in range(n)]
        renamed = [row.translate(str.maketrans("ABCD", "DCBA")) for row in rotated]
        self.assertEqual(canonical_regions(rows), canonical_regions(renamed))

    def test_release_gate_requires_all_24_slots(self):
        levels = copy.deepcopy(self.levels[:3])
        with self.assertRaisesRegex(ValueError, "orders 1..24"):
            validate_document({"levels": levels}, release=True)

    def test_release_gate_rejects_pre_solved_level(self):
        level = self.level()
        level["givens"] = [{"r": r, "c": c} for r, c in enumerate(level["solution"])]
        level["logicTrace"] = []
        with self.assertRaisesRegex(ValueError, "at least two playable cats"):
            validate_document({"levels": [level]}, release=True)

    def test_fixture_cannot_pass_release_gate(self):
        with self.assertRaisesRegex(ValueError, "size 4..6"):
            validate_document({"levels": copy.deepcopy(self.levels)}, release=True)


if __name__ == "__main__":
    unittest.main()

"""Executable design vectors for the future Godot gesture implementation.

This is a small reference reducer, not a test of a game runtime that does not exist yet.
QA-08..12/43..45/54..56 must later replay these vectors against the actual game.
"""

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = json.loads((ROOT / "data" / "interactions.sample.json").read_text(encoding="utf-8"))
LEVELS = json.loads((ROOT / "data" / "levels.sample.json").read_text(encoding="utf-8"))["levels"]
LEVEL = next(level for level in LEVELS if level["id"] == DATA["levelId"])
LEVEL_BY_ID = {level["id"]: level for level in LEVELS}


def key(cell):
    return f"{cell[0]},{cell[1]}"


def state(cells, cell):
    return cells.get(key(cell), "empty")


def single(cells, cell):
    before = state(cells, cell)
    if before == "empty":
        cells[key(cell)] = "x"
        return "MarkX"
    if before == "x":
        cells.pop(key(cell))
        return "ClearX"
    return None


def line_cells(start, end, cell_size):
    """Sample the segment at one logical pixel to include skipped grid cells."""
    x0, y0 = (start[1] + 0.5) * cell_size, (start[0] + 0.5) * cell_size
    x1, y1 = (end[1] + 0.5) * cell_size, (end[0] + 0.5) * cell_size
    steps = max(1, int(max(abs(x1 - x0), abs(y1 - y0))))
    result = []
    for i in range(steps + 1):
        cell = (int((y0 + (y1 - y0) * i / steps) // cell_size),
                int((x0 + (x1 - x0) * i / steps) // cell_size))
        if not result or result[-1] != cell:
            result.append(cell)
    return result


def run_case(case):
    cells = dict(case["initial"])
    actions = []
    hearts = case.get("initialHearts", 3)
    kind = case["kind"]
    cell = case.get("cell")

    if kind in ("tap", "jitter", "secondary"):
        if kind == "secondary":
            cell = case["primary"]  # secondary contact never owns the board
        if kind == "jitter" and case["distanceLogicalPx"] > DATA["touchSlopLogicalPx"]:
            single(cells, cell)
            actions.append("MarkStroke")
        else:
            action = single(cells, cell)
            if action:
                actions.append(action)
    elif kind == "double":
        if state(cells, cell) in ("empty", "x"):
            if case["intervalMs"] <= DATA["doubleTapWindowMs"]:
                # The first tap was visual preview only, never a committed X.
                if LEVEL["solution"][cell[0]] == cell[1]:
                    cells[key(cell)] = "cat"
                else:
                    cells[key(cell)] = "x_error"
                    hearts -= 1
                actions.append("TryCat")
            else:
                actions.extend((single(cells, cell), single(cells, cell)))
    elif kind == "different":
        assert case["intervalMs"] <= DATA["doubleTapWindowMs"]
        assert case["first"] != case["second"]
        actions.extend((single(cells, case["first"]), single(cells, case["second"])))
    elif kind == "second_drag":
        assert case["intervalMs"] <= DATA["doubleTapWindowMs"]
        actions.append(single(cells, cell))  # flush the first released tap
        mode = state(cells, cell)  # now X, so the second stroke clears X
        for target in line_cells(cell, case["to"], DATA["cellLogicalPx"]):
            if state(cells, target) == mode:
                single(cells, target)
        actions.append("MarkStroke")
    elif kind in ("locked", "locked_drag"):
        pass  # tap/double on the locked x_error are both no-ops
    elif kind == "flush_pending":
        actions.append(single(cells, cell))  # the first tap was already released
    elif kind == "cancel_active":
        pass  # a press/stroke still held is discarded before commit
    elif kind == "drag":
        start = case["from"]
        mode = state(cells, start)
        assert mode in ("empty", "x")
        path = line_cells(start, case["to"], DATA["cellLogicalPx"])
        if "returnTo" in case:
            path.extend(line_cells(case["to"], case["returnTo"], DATA["cellLogicalPx"]))
        visited = set()
        for target in path:
            target_key = key(target)
            if target_key in visited:
                continue
            visited.add(target_key)
            if state(cells, target) == mode:
                single(cells, target)
        actions.append("MarkStroke")
    else:
        raise AssertionError(f"unknown kind: {kind}")
    return cells, hearts, actions


def new_reference_session(initial=None):
    initial = initial or {}
    return {
        "cells": dict(initial.get("cells", {})),
        "hearts": initial.get("hearts", 3),
        "mistakeCount": initial.get("mistakeCount", 0),
        "hintCount": initial.get("hintCount", 0),
        "undoDiff": None,
        "events": [],
    }


def public_session(session):
    return {
        "cells": session["cells"],
        "hearts": session["hearts"],
        "mistakeCount": session["mistakeCount"],
        "hintCount": session["hintCount"],
        "undoAvailable": session["undoDiff"] is not None,
        "events": session["events"],
    }


def write_cell(cells, cell_key, value):
    if value == "empty":
        cells.pop(cell_key, None)
    else:
        cells[cell_key] = value


def is_given(level, cell):
    return any((given["r"], given["c"]) == cell for given in level["givens"])


def apply_session_action(level, session, action):
    action_type = action["type"]
    if action_type in ("MarkX", "ClearX"):
        cell = tuple(action["cell"])
        if is_given(level, cell):
            session["events"].append("NoOp")
            return session
        cell_key = key(cell)
        before = state(session["cells"], cell)
        required = "empty" if action_type == "MarkX" else "x"
        if before != required:
            session["events"].append("NoOp")
            return session
        after = "x" if action_type == "MarkX" else "empty"
        write_cell(session["cells"], cell_key, after)
        session["undoDiff"] = {cell_key: before}
        session["events"].append(action_type)
    elif action_type == "MarkStroke":
        mode = action["mode"]
        required, after = ("empty", "x") if mode == "mark" else ("x", "empty")
        diff = {}
        for raw_cell in action["cells"]:
            cell = tuple(raw_cell)
            if is_given(level, cell):
                continue
            cell_key = key(cell)
            before = state(session["cells"], cell)
            if before == required and cell_key not in diff:
                diff[cell_key] = before
                write_cell(session["cells"], cell_key, after)
        session["undoDiff"] = diff or None
        session["events"].append("MarkStroke" if diff else "NoOp")
    elif action_type == "UndoX":
        if session["undoDiff"] is None:
            session["events"].append("UndoUnavailable")
            return session
        for cell_key, previous in session["undoDiff"].items():
            write_cell(session["cells"], cell_key, previous)
        session["undoDiff"] = None
        session["events"].append("UndoApplied")
    elif action_type == "TryCat":
        session["undoDiff"] = None
        cell = tuple(action["cell"])
        if is_given(level, cell) or state(session["cells"], cell) not in ("empty", "x"):
            session["events"].append("NoOp")
        elif level["solution"][cell[0]] == cell[1]:
            write_cell(session["cells"], key(cell), "cat")
            session["events"].append("CatPlaced")
        else:
            write_cell(session["cells"], key(cell), "x_error")
            session["hearts"] -= 1
            session["mistakeCount"] += 1
            session["events"].append("Mistake")
    elif action_type == "Hint":
        result = action["result"]
        if result not in ("none", "evidence"):
            raise AssertionError(f"unknown Hint result: {result}")
        if session["hintCount"] != 0:
            session["events"].append("HintUnavailable")
        elif result == "none":
            session["events"].append("NoHint")
        else:
            session["hintCount"] = 1
            session["events"].append("HintShown")
    elif action_type == "BackToHome":
        session["undoDiff"] = None
        session["events"].append("ReturnedHome")
    elif action_type == "RestartLevel":
        restarted = new_reference_session()
        restarted["events"].append("Restarted")
        return restarted
    elif action_type == "Retry":
        retried = new_reference_session()
        retried["events"].append("Retried")
        return retried
    elif action_type in ("LevelWon", "LevelFailed"):
        session["undoDiff"] = None
        session["events"].append(action_type)
    elif action_type == "CloseApp":
        session["undoDiff"] = None
        session["events"].append("AppClosed")
    else:
        raise AssertionError(f"unknown session action: {action_type}")
    return session


def run_session_case(case):
    level = LEVEL_BY_ID[case.get("levelId", DATA["levelId"])]
    session = new_reference_session(case.get("initial"))
    for action in case["actions"]:
        session = apply_session_action(level, session, action)
    return public_session(session)


class InteractionContractTests(unittest.TestCase):
    def test_vectors(self):
        self.assertEqual(DATA["contractVersion"], 2)
        self.assertEqual(LEVEL["size"], 4)
        seen = set()
        for case in DATA["cases"]:
            with self.subTest(case=case["id"]):
                self.assertNotIn(case["id"], seen)
                seen.add(case["id"])
                for position, value in case["initial"].items():
                    self.assertIn(value, ("empty", "x", "x_error", "cat"))
                    row, col = map(int, position.split(","))
                    self.assertTrue(0 <= row < LEVEL["size"] and 0 <= col < LEVEL["size"])
                    if value == "cat":
                        self.assertEqual(LEVEL["solution"][row], col)
                    if value == "x_error":
                        self.assertNotEqual(LEVEL["solution"][row], col)
                self.assertEqual(case.get("initialHearts", 3), 3 - sum(
                    value == "x_error" for value in case["initial"].values()))
                if "preview" in case:
                    self.assertIn(case["preview"], ("empty", "x"))
                    before = state(case["initial"], case["cell"])
                    self.assertEqual(case["preview"], "x" if before == "empty" else "empty")
                actual = run_case(case)
                self.assertEqual(actual, (case["expected"], case["hearts"], case["actions"]))

    def test_session_vectors(self):
        self.assertEqual(DATA["contractVersion"], 2)
        seen = set()
        for case in DATA["sessionCases"]:
            with self.subTest(case=case["id"]):
                self.assertNotIn(case["id"], seen)
                seen.add(case["id"])
                self.assertEqual(run_session_case(case), case["expected"])

    def test_invalid_hint_result_is_rejected(self):
        session = new_reference_session()
        with self.assertRaisesRegex(AssertionError, "Hint result"):
            apply_session_action(LEVEL, session, {"type": "Hint", "result": "unknown"})


if __name__ == "__main__":
    unittest.main()

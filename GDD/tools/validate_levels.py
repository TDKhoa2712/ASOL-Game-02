"""Validate original Vườn Mèo levels with the Python standard library.

Usage:
    python GDD/tools/validate_levels.py GDD/data/levels.sample.json
    python GDD/tools/validate_levels.py --release path/to/campaign.json

Schema v4 supports N=4..12 and machine-checkable S2/S3 proof traces. S4/S5 are
not accepted by this validator.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from collections import deque
from pathlib import Path

LEVEL_KEYS = {
    "schemaVersion", "id", "order", "size", "regions",
    "givens", "solution", "difficulty", "tags", "logicTrace",
}
S2_STEP_KEYS = {"rule", "focus", "conclusion", "textKey"}
S3_STEP_KEYS = {"rule", "source", "target", "conclusion", "textKey"}
UNIT_KEYS = {"type", "id"}
CELL_KEYS = {"r", "c"}


def require_object(value, keys: set[str], label: str):
    if not isinstance(value, dict):
        raise ValueError(f"{label} must be an object")
    missing = keys - value.keys()
    extra = value.keys() - keys
    if missing or extra:
        raise ValueError(f"{label} fields: missing {sorted(missing)}, extra {sorted(extra)}")


def is_int(value):
    return type(value) is int  # bool is a subclass of int in Python.


def object_no_duplicates(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON key {key!r}")
        result[key] = value
    return result


def adjacent_cells(r: int, c: int, n: int):
    for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        rr, cc = r + dr, c + dc
        if 0 <= rr < n and 0 <= cc < n:
            yield rr, cc


def count_solutions(regions: list[str], givens: dict[int, int], limit: int = 2,
                    max_nodes: int = 2_000_000, max_seconds: float = 5.0):
    """Independent DFS: never reads the declared solution."""
    n = len(regions)
    found: list[tuple[int, ...]] = []
    placement: list[int] = []
    used_columns: set[int] = set()
    used_regions: set[str] = set()
    nodes = 0
    deadline = time.monotonic() + max_seconds

    def visit(r: int):
        nonlocal nodes
        nodes += 1
        if nodes > max_nodes or time.monotonic() > deadline:
            raise ValueError("solver search budget exceeded; uniqueness not proven")
        if len(found) >= limit:
            return
        if r == n:
            found.append(tuple(placement))
            return
        choices = [givens[r]] if r in givens else range(n)
        for c in choices:
            region = regions[r][c]
            if c in used_columns or region in used_regions:
                continue
            if placement and abs(c - placement[-1]) <= 1:
                continue
            placement.append(c)
            used_columns.add(c)
            used_regions.add(region)
            visit(r + 1)
            used_regions.remove(region)
            used_columns.remove(c)
            placement.pop()

    visit(0)
    return found


def validate_regions(rows: list[str], n: int):
    expected = set("ABCDEFGHIJKL"[:n])
    actual = set("".join(rows))
    if actual != expected:
        raise ValueError(f"regions must use exactly {sorted(expected)}; got {sorted(actual)}")
    for label in sorted(expected):
        cells = {(r, c) for r in range(n) for c in range(n) if rows[r][c] == label}
        seen = {next(iter(cells))}
        queue = deque(seen)
        while queue:
            r, c = queue.popleft()
            for neighbor in adjacent_cells(r, c, n):
                if neighbor in cells and neighbor not in seen:
                    seen.add(neighbor)
                    queue.append(neighbor)
        if seen != cells:
            raise ValueError(f"region {label} is disconnected")


def exclusion_reason(rows: list[str], cats: dict[int, int], cell: tuple[int, int]):
    """Return a reproducible S1 witness (source cat, relation), or None."""
    r, c = cell
    reasons = []
    for rr, cc in sorted(cats.items()):
        if r == rr:
            reasons.append((0, (rr, cc), "row"))
        if c == cc:
            reasons.append((1, (rr, cc), "column"))
        if rows[r][c] == rows[rr][cc]:
            reasons.append((2, (rr, cc), "region"))
        if abs(r - rr) == 1 and abs(c - cc) == 1:
            reasons.append((3, (rr, cc), "diagonal"))
    if not reasons:
        return None
    _, source, relation = min(reasons)
    return {"sourceCat": source, "reason": relation}


def possible_cells(rows: list[str], cats: dict[int, int], eliminated=frozenset()):
    n = len(rows)
    return {
        (r, c)
        for r in range(n) if r not in cats
        for c in range(n)
        if (r, c) not in eliminated
        and exclusion_reason(rows, cats, (r, c)) is None
    }


def focus_cells(rows: list[str], focus: dict):
    n = len(rows)
    require_object(focus, {"type", "id"}, "focus")
    kind, unit_id = focus["type"], focus["id"]
    if kind == "row" and is_int(unit_id) and 0 <= unit_id < n:
        return {(unit_id, c) for c in range(n)}
    if kind == "column" and is_int(unit_id) and 0 <= unit_id < n:
        return {(r, unit_id) for r in range(n)}
    if kind == "region" and type(unit_id) is str and unit_id in "ABCDEFGHIJKL"[:n]:
        return {(r, c) for r in range(n) for c in range(n) if rows[r][c] == unit_id}
    raise ValueError(f"invalid focus {focus!r}")


def parse_conclusion_cells(value, n: int):
    require_object(value, {"type", "cells"}, "conclusion")
    if value["type"] != "eliminate" or not isinstance(value["cells"], list):
        raise ValueError("S3 conclusion must eliminate cells")
    cells = []
    for item in value["cells"]:
        require_object(item, CELL_KEYS, "eliminated cell")
        cell = (item["r"], item["c"])
        if not all(is_int(part) and 0 <= part < n for part in cell):
            raise ValueError("eliminated cell out of bounds")
        cells.append(cell)
    if len(cells) != len(set(cells)):
        raise ValueError("duplicate S3 conclusion cell")
    return set(cells)


def validate_s3_step(rows: list[str], cats: dict[int, int], eliminated: set[tuple[int, int]], step: dict):
    require_object(step, S3_STEP_KEYS, "S3 step")
    source, target = step["source"], step["target"]
    require_object(source, UNIT_KEYS, "S3 source")
    require_object(target, UNIT_KEYS, "S3 target")
    if source["type"] == target["type"]:
        raise ValueError("S3 source and target must have different unit types")
    source_unit = focus_cells(rows, source)
    target_unit = focus_cells(rows, target)
    if any(cell in source_unit or cell in target_unit for cell in cats.items()):
        raise ValueError("S3 units must not already contain a cat")
    candidates = possible_cells(rows, cats, eliminated)
    source_candidates = candidates & source_unit
    if not source_candidates or not source_candidates <= target_unit:
        raise ValueError("S3 source candidates must be nonempty and contained in target")
    expected = (candidates & target_unit) - source_unit
    if not expected:
        raise ValueError("S3 must eliminate at least one new candidate")
    declared = parse_conclusion_cells(step["conclusion"], len(rows))
    if declared != expected:
        raise ValueError(f"S3 conclusion cells {sorted(declared)}, expected {sorted(expected)}")
    if step["textKey"] != "hint.lock.intersection":
        raise ValueError("S3 textKey must be hint.lock.intersection")
    eliminated.update(expected)


def validate_trace(level: dict, given_by_row: dict[int, int]):
    rows, n = level["regions"], level["size"]
    cats = dict(given_by_row)
    eliminated: set[tuple[int, int]] = set()
    for index, step in enumerate(level["logicTrace"], 1):
        label = f"trace step {index}"
        try:
            if not isinstance(step, dict):
                raise ValueError("step must be an object")
            if step.get("rule") == "S3":
                validate_s3_step(rows, cats, eliminated, step)
                continue
            if step.get("rule") != "S2":
                raise ValueError(f"unsupported rule {step.get('rule')!r}")
            require_object(step, S2_STEP_KEYS, label)
            focus = step["focus"]
            unit = focus_cells(rows, focus)
            kind = focus["type"]
            if step["textKey"] != f"hint.single.{kind}":
                raise ValueError("textKey does not match focus")
            target = step["conclusion"]
            require_object(target, {"type", "r", "c"}, "conclusion")
            if target["type"] != "place":
                raise ValueError("S2 conclusion must place a cat")
            r, c = target["r"], target["c"]
            if not (is_int(r) and is_int(c) and 0 <= r < n and 0 <= c < n):
                raise ValueError("target out of bounds")
            if any(cell in unit for cell in cats.items()):
                raise ValueError("focus already contains a cat")
            candidates = unit & possible_cells(rows, cats, eliminated)
            if candidates != {(r, c)}:
                raise ValueError(f"focus candidates {sorted(candidates)}, expected only {(r, c)}")
            # Every removed cell must have S1 evidence or a prior S3 proof.
            for cell in unit - candidates:
                if cell not in eliminated and exclusion_reason(rows, cats, cell) is None:
                    raise ValueError(f"missing S1/S3 witness for {cell}")
            if level["solution"][r] != c:
                raise ValueError("placement differs from solution")
            cats[r] = c
        except (TypeError, KeyError, ValueError) as exc:
            raise ValueError(f"{label}: {exc}") from exc
    if len(cats) != n:
        raise ValueError(f"trace ends with {len(cats)}/{n} cats")


def canonical_regions(rows: list[str]):
    n = len(rows)
    variants = []
    for rotation in range(4):
        for mirror in (False, True):
            transformed = [[None for _ in range(n)] for _ in range(n)]
            for r in range(n):
                for c in range(n):
                    rr, cc = r, c
                    for _ in range(rotation):
                        rr, cc = cc, n - 1 - rr
                    if mirror:
                        cc = n - 1 - cc
                    transformed[rr][cc] = rows[r][c]
            labels = {}
            normalized = []
            for row in transformed:
                for label in row:
                    if label not in labels:
                        labels[label] = chr(ord("A") + len(labels))
                    normalized.append(labels[label])
            variants.append("".join(normalized))
    return min(variants)


def validate_level(level: dict):
    require_object(level, LEVEL_KEYS, "level")
    level_id = level["id"]
    if type(level_id) is not str or not re.fullmatch(r"[A-Z0-9_-]+", level_id):
        raise ValueError("invalid id")
    if not is_int(level["schemaVersion"]) or level["schemaVersion"] != 4:
        raise ValueError("schemaVersion must be 4")
    order = level["order"]
    if not is_int(order) or order < 1:
        raise ValueError("order must be an integer >=1")
    n = level["size"]
    if not is_int(n) or not 4 <= n <= 12:
        raise ValueError("size must be an integer from 4 to 12")
    rows = level["regions"]
    if not isinstance(rows, list) or len(rows) != n or any(type(row) is not str or len(row) != n for row in rows):
        raise ValueError("regions must be N strings of length N")
    validate_regions(rows, n)
    solution = level["solution"]
    if not isinstance(solution, list) or len(solution) != n or any(not is_int(c) for c in solution) or sorted(solution) != list(range(n)):
        raise ValueError("solution must be a permutation of integer columns")
    givens = level["givens"]
    if not isinstance(givens, list):
        raise ValueError("givens must be a list")
    given_by_row = {}
    for given in givens:
        require_object(given, CELL_KEYS, "given")
        r, c = given["r"], given["c"]
        if not (is_int(r) and is_int(c) and 0 <= r < n and 0 <= c < n):
            raise ValueError("given out of bounds")
        if r in given_by_row or solution[r] != c:
            raise ValueError("duplicate or incorrect given")
        given_by_row[r] = c
    found = count_solutions(rows, given_by_row)
    if len(found) != 1:
        raise ValueError(f"expected one solution; found {'at least two' if len(found) == 2 else 'zero'}")
    if list(found[0]) != solution:
        raise ValueError(f"declared solution differs from computed solution {found[0]}")
    if type(level["difficulty"]) is not str or level["difficulty"] not in {"tutorial", "easy", "medium", "hard"}:
        raise ValueError("invalid difficulty")
    tags = level["tags"]
    if not isinstance(tags, list) or any(type(tag) is not str or not tag for tag in tags) or len(tags) != len(set(tags)):
        raise ValueError("tags must be unique nonempty strings")
    if not isinstance(level["logicTrace"], list):
        raise ValueError("logicTrace must be a list")
    validate_trace(level, given_by_row)
    return canonical_regions(rows)


def s2_only_reaches_solution(level: dict):
    rows, n = level["regions"], level["size"]
    cats = {given["r"]: given["c"] for given in level["givens"]}
    units = (
        [{"type": "row", "id": i} for i in range(n)]
        + [{"type": "column", "id": i} for i in range(n)]
        + [{"type": "region", "id": label} for label in "ABCDEFGHIJKL"[:n]]
    )
    while len(cats) < n:
        placements = set()
        candidates = possible_cells(rows, cats)
        for unit_spec in units:
            unit = focus_cells(rows, unit_spec)
            if any(cell in unit for cell in cats.items()):
                continue
            remaining = unit & candidates
            if len(remaining) == 1:
                placements.update(remaining)
        fresh = sorted((r, c) for r, c in placements if r not in cats)
        if not fresh:
            return False
        for r, c in fresh:
            if r not in cats:
                cats[r] = c
    return True


def validate_release_logic_band(level: dict):
    rules = [step.get("rule") for step in level["logicTrace"] if isinstance(step, dict)]
    if 1 <= level["order"] <= 18 and "S3" in rules:
        raise ValueError("release orders 1..18 must use only S2 trace steps")
    if 19 <= level["order"] <= 24:
        if "S3" not in rules:
            raise ValueError("release orders 19..24 require at least one S3 trace step")
        if s2_only_reaches_solution(level):
            raise ValueError("release orders 19..24 must require S3, not merely contain it")


def validate_document(data: dict, release: bool = False):
    require_object(data, {"levels"}, "root")
    levels = data["levels"]
    if not isinstance(levels, list) or not levels:
        raise ValueError("levels must be a nonempty list")
    ids, slots, shapes = set(), set(), {}
    for level in levels:
        level_id = level.get("id", "<missing id>") if isinstance(level, dict) else "<invalid level>"
        try:
            shape = validate_level(level)
            if level_id in ids:
                raise ValueError("duplicate id")
            ids.add(level_id)
            slot = level["order"]
            if slot in slots:
                raise ValueError(f"duplicate order {slot}")
            slots.add(slot)
            if release:
                if not 1 <= level["order"] <= 24:
                    raise ValueError("release order must be 1..24")
                if level["size"] > 6 or level["difficulty"] == "hard":
                    raise ValueError("release supports size 4..6 and no hard level")
                if level["size"] - len(level["givens"]) < 2:
                    raise ValueError("release needs at least two playable cats")
                validate_release_logic_band(level)
            shapes[level_id] = shape
        except (TypeError, ValueError, KeyError) as exc:
            raise ValueError(f"{level_id}: {exc}") from exc
    if release:
        required = set(range(1, 25))
        if slots != required:
            raise ValueError(f"release needs exactly orders 1..24; missing {sorted(required - slots)}")
    ordered = sorted(levels, key=lambda level: level["order"])
    warnings = []
    for index, level in enumerate(ordered):
        for previous in ordered[max(0, index - 8):index]:
            if shapes[level["id"]] == shapes[previous["id"]]:
                message = f"{level['id']}: same region geometry as {previous['id']} within 8 levels"
                if release:
                    raise ValueError(message)
                warnings.append(message)
    return ordered, warnings


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("file", type=Path)
    parser.add_argument("--release", action="store_true", help="enforce the 24-level linear MVP gate")
    args = parser.parse_args()
    try:
        data = json.loads(args.file.read_text(encoding="utf-8"), object_pairs_hook=object_no_duplicates)
        levels, warnings = validate_document(data, release=args.release)
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(f"FAIL {exc}", file=sys.stderr)
        return 1
    for level in levels:
        rules = "/".join(
            rule for rule in ("S2", "S3")
            if any(step.get("rule") == rule for step in level["logicTrace"])
        ) or "empty"
        print(f"OK   {level['id']}: {level['size']}x{level['size']}, unique solution, connected regions, {rules} trace")
    for warning in warnings:
        print(f"WARN {warning}")
    print(f"Validated {len(levels)} level(s); {len(warnings)} duplicate geometry warning(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

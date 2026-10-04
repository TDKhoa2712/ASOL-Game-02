"""Prove complete bank contents and campaign coverage before playtest.

Usage: python -B tools/validate_full_content.py --banks game/data/banks
       [--playlist game/data/campaigns/full_998.json --demo game/data/campaigns/demo_30.json]
"""

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "GDD/tools"))

from validate_levels import canonical_regions, validate_level  # noqa: E402
from validate_content import validate_bank, validate_pace_against_bank, validate_playlist  # noqa: E402

TARGET_COUNTS = {
    4: {"1": 12, "2": 10, "3": 8, "4": 3, "5": 3},
    5: {"1": 12, "2": 10, "3": 8, "4": 9, "5": 10},
    6: {"1": 199, "2": 196, "3": 193, "4": 167, "5": 158},
}


def _proof_level(level: dict, size: int, rank: str, index: int) -> dict:
    return {
        "schemaVersion": 4,
        "id": f"B{size}{rank}{index:04d}",
        "order": 31,
        "size": size,
        "regions": level["regions"],
        "givens": level["givens"],
        "solution": level["solution"],
        "difficulty": "medium",
        "tags": [],
        "logicTrace": level["logicTrace"],
    }


def validate_full_banks(banks: dict[int, dict], paces: dict[int, dict],
                        targets: dict[int, dict[str, int]]) -> list[str]:
    errors = []
    for size, counts in targets.items():
        bank, pace = banks.get(size), paces.get(size)
        if bank is None or pace is None:
            errors.append(f"Missing bank or pace for size {size}")
            continue
        structural = validate_bank(bank) + validate_pace_against_bank(pace, bank)
        if structural:
            errors.extend(f"Size {size}: {error}" for error in structural)
            continue
        ranks, pacing = bank["ranks"], pace["pacing"]
        if set(ranks) != set(counts) or set(pacing) != set(counts):
            errors.append(f"Size {size}: rank keys differ from target {sorted(counts)}")
        seen_geometry = set()
        for rank, target_count in counts.items():
            levels = ranks.get(rank, [])
            pace_entries = pacing.get(rank, [])
            if len(levels) != target_count:
                errors.append(f"Size {size} rank {rank}: count {len(levels)} != {target_count}")
            for index, level in enumerate(levels):
                label = f"Size {size} rank {rank}[{index}]"
                try:
                    proof = _proof_level(level, size, rank, index)
                    geometry = validate_level(proof)
                    if geometry in seen_geometry:
                        errors.append(f"{label}: duplicate geometry")
                    seen_geometry.add(geometry)
                except (KeyError, TypeError, ValueError) as error:
                    errors.append(f"{label}: {error}")
                    continue
                if index >= len(pace_entries):
                    continue
                trace = level["logicTrace"]
                expected = [1 if step["rule"] == "S2" else 2 for step in trace]
                actual = pace_entries[index]
                if actual.get("rSeq") != expected:
                    errors.append(f"{label}: rSeq differs from logicTrace")
                if actual.get("hintCosts") != expected:
                    errors.append(f"{label}: hintCosts differs from logicTrace")
    return errors


def validate_full_playlist(playlist: dict, demo: dict,
                           banks: dict[int, dict]) -> list[str]:
    errors = validate_playlist(playlist, banks)
    entries = playlist.get("playlist", []) if isinstance(playlist, dict) else []
    prefix = demo.get("playlist", []) if isinstance(demo, dict) else []
    if entries[:len(prefix)] != prefix:
        errors.append("Full campaign prefix differs from demo playlist")
    all_refs = {(size, int(rank), index)
                for size, bank in banks.items()
                for rank, levels in bank.get("ranks", {}).items()
                for index in range(len(levels))}
    used_refs = {(entry.get("size"), entry.get("rank"), entry.get("index"))
                 for entry in entries if isinstance(entry, dict)}
    missing = all_refs - used_refs
    if missing:
        errors.append(f"Full campaign missing {len(missing)} bank references")
    if len(entries) != len(all_refs):
        errors.append(f"Full campaign count {len(entries)} != {len(all_refs)}")
    for index, entry in enumerate(entries, 1):
        if isinstance(entry, dict) and entry.get("label") != f"L{index:02d}":
            errors.append(f"Full campaign label at order {index} is not L{index:02d}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--banks", type=Path, required=True)
    parser.add_argument("--playlist", type=Path)
    parser.add_argument("--demo", type=Path)
    args = parser.parse_args()
    if bool(args.playlist) != bool(args.demo):
        parser.error("--playlist and --demo must be supplied together")
    try:
        banks = {size: json.loads((args.banks / f"bank_{size}x{size}.json").read_text(encoding="utf-8"))
                 for size in TARGET_COUNTS}
        paces = {size: json.loads((args.banks / f"bank_{size}x{size}.pace.json").read_text(encoding="utf-8"))
                 for size in TARGET_COUNTS}
        errors = validate_full_banks(banks, paces, TARGET_COUNTS)
        if args.playlist:
            playlist = json.loads(args.playlist.read_text(encoding="utf-8"))
            demo = json.loads(args.demo.read_text(encoding="utf-8"))
            errors.extend(validate_full_playlist(playlist, demo, banks))
    except (OSError, ValueError) as error:
        errors = [str(error)]
    if errors:
        for error in errors:
            print(f"FAIL: {error}")
        return 1
    print("VALID: full banks and campaign")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

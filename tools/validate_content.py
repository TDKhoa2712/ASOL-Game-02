"""Content validator for CanDoKu level banks, pace sidecars, and campaign playlists.

Usage:
  python -B tools/validate_content.py game/data/banks/bank_4x4.json
  python -B tools/validate_content.py game/data/banks/bank_4x4.json --pace game/data/banks/bank_4x4.pace.json
  python -B tools/validate_content.py game/data/campaigns/demo_30.json --bank game/data/banks/bank_4x4.json
"""
import argparse
import json
import sys
from pathlib import Path

BANK_VERSION = 1
PACE_VERSION = 1
CAMPAIGN_VERSION = 1


def check_level_candy_rules(level: dict, size: int) -> list[str]:
    """Verify Candoku placement rules for a level."""
    errors = []
    regions = level.get("regions", [])
    solution = level.get("solution", [])
    givens = level.get("givens", [])

    if not isinstance(regions, list) or len(regions) != size:
        return [f"regions must be a list of {size} strings"]
    for r, row in enumerate(regions):
        if not isinstance(row, str) or len(row) != size:
            return [f"region row {r} must be string of length {size}"]

    if not isinstance(solution, list) or len(solution) != size:
        return [f"solution must be a list of {size} integers"]

    seen_cols = set()
    seen_regions = set()
    for r in range(size):
        c = solution[r]
        if not isinstance(c, int) or c < 0 or c >= size:
            errors.append(f"solution at row {r} has invalid column {c}")
            continue
        if c in seen_cols:
            errors.append(f"duplicate candy in column {c}")
        seen_cols.add(c)

        reg = regions[r][c]
        if reg in seen_regions:
            errors.append(f"multiple candies in region '{reg}'")
        seen_regions.add(reg)

        # Adjacency check with previous row
        if r > 0:
            prev_c = solution[r - 1]
            if abs(c - prev_c) <= 1:
                errors.append(f"adjacent candies between row {r-1} (col {prev_c}) and row {r} (col {c})")

    for i, g in enumerate(givens):
        if not isinstance(g, dict) or "r" not in g or "c" not in g:
            errors.append(f"given {i} must be dict with 'r' and 'c'")
            continue
        gr, gc = g["r"], g["c"]
        if gr < 0 or gr >= size or gc < 0 or gc >= size:
            errors.append(f"given {i} coordinates ({gr}, {gc}) out of bounds")
        elif gr < len(solution) and solution[gr] != gc:
            errors.append(f"given {i} at ({gr}, {gc}) contradicts solution ({gr}, {solution[gr]})")

    return errors


def validate_bank_level(level: dict, size: int) -> list[str]:
    """Validate a single bank level object against bank schema v1."""
    errors = []
    if not isinstance(level, dict):
        return ["Level must be a dictionary"]

    for field in ("seed", "steps", "rating"):
        if field not in level or not isinstance(level[field], (int, float)):
            errors.append(f"Missing or invalid numeric field '{field}'")

    if "profile" not in level or not isinstance(level["profile"], list) or len(level["profile"]) != 3:
        errors.append("Missing or invalid 'profile' (must be array of 3 numbers)")

    if "pidHash" not in level or not isinstance(level["pidHash"], str) or not level["pidHash"]:
        errors.append("Missing or empty 'pidHash'")

    if "logicTrace" not in level or not isinstance(level["logicTrace"], list):
        errors.append("Missing or invalid 'logicTrace' (must be a list)")

    errors.extend(check_level_candy_rules(level, size))
    return errors


def validate_bank(bank: dict) -> list[str]:
    """Validate a full bank dictionary."""
    errors = []
    if not isinstance(bank, dict):
        return ["Root JSON must be a dictionary"]

    if bank.get("bankVersion") != BANK_VERSION:
        errors.append(f"Expected bankVersion {BANK_VERSION}, got {bank.get('bankVersion')}")

    size = bank.get("size")
    if not isinstance(size, int) or size < 4 or size > 12:
        errors.append(f"Invalid size {size} (must be 4..12)")
        return errors

    ranks = bank.get("ranks")
    if not isinstance(ranks, dict):
        errors.append("Missing or invalid 'ranks' dictionary")
        return errors

    for rank_key, levels in ranks.items():
        if not isinstance(levels, list):
            errors.append(f"Rank '{rank_key}' must be a list of levels")
            continue
        for idx, lvl in enumerate(levels):
            lvl_errors = validate_bank_level(lvl, size)
            for err in lvl_errors:
                errors.append(f"Rank {rank_key}[{idx}]: {err}")

    return errors


def validate_pace_against_bank(pace: dict, bank: dict) -> list[str]:
    """Validate pace structure and verify consistency with bank data."""
    errors = []
    if not isinstance(pace, dict):
        return ["Pace root must be a dictionary"]

    if pace.get("bankVersion") != PACE_VERSION:
        errors.append(f"Pace bankVersion expected {PACE_VERSION}, got {pace.get('bankVersion')}")

    size = pace.get("size")
    if size != bank.get("size"):
        errors.append(f"Pace size {size} does not match bank size {bank.get('size')}")

    pacing = pace.get("pacing")
    if not isinstance(pacing, dict):
        errors.append("Missing or invalid 'pacing' dictionary in pace")
        return errors

    bank_ranks = bank.get("ranks", {})
    for rank_key, bank_levels in bank_ranks.items():
        if rank_key not in pacing:
            errors.append(f"Pace missing rank '{rank_key}' present in bank")
            continue
        pace_entries = pacing[rank_key]
        if not isinstance(pace_entries, list):
            errors.append(f"Pace rank '{rank_key}' must be a list")
            continue
        if len(pace_entries) != len(bank_levels):
            errors.append(
                f"Pace count {len(pace_entries)} for rank '{rank_key}' does not match bank count {len(bank_levels)}"
            )
            continue
        for idx, entry in enumerate(pace_entries):
            if not isinstance(entry, dict):
                errors.append(f"Pace rank {rank_key}[{idx}] is not a dictionary")
                continue
            r_seq = entry.get("rSeq")
            hint_costs = entry.get("hintCosts")
            if not isinstance(r_seq, list):
                errors.append(f"Pace rank {rank_key}[{idx}] missing 'rSeq' array")
            if not isinstance(hint_costs, list):
                errors.append(f"Pace rank {rank_key}[{idx}] missing 'hintCosts' array")
            if isinstance(r_seq, list) and isinstance(hint_costs, list):
                if len(r_seq) != len(hint_costs):
                    errors.append(f"Pace rank {rank_key}[{idx}] rSeq length {len(r_seq)} != hintCosts {len(hint_costs)}")

    return errors


def validate_playlist(playlist_data: dict, banks: dict[int, dict] | None = None) -> list[str]:
    """Validate campaign playlist structure and optionally check bank references."""
    errors = []
    if not isinstance(playlist_data, dict):
        return ["Playlist root must be a dictionary"]

    if playlist_data.get("campaignVersion") != CAMPAIGN_VERSION:
        errors.append(f"campaignVersion expected {CAMPAIGN_VERSION}, got {playlist_data.get('campaignVersion')}")

    if not playlist_data.get("id"):
        errors.append("Missing or empty campaign id")

    entries = playlist_data.get("playlist")
    if not isinstance(entries, list) or not entries:
        errors.append("Missing or empty playlist array")
        return errors

    seen_labels = set()
    for idx, entry in enumerate(entries):
        if not isinstance(entry, dict):
            errors.append(f"Playlist entry {idx} is not a dictionary")
            continue
        label = entry.get("label")
        if not isinstance(label, str) or not label:
            errors.append(f"Entry {idx} missing or invalid label")
        elif label in seen_labels:
            errors.append(f"Duplicate playlist label '{label}' at entry {idx}")
        else:
            seen_labels.add(label)

        size = entry.get("size")
        if not isinstance(size, int) or size < 4 or size > 6:
            errors.append(f"Entry {idx} ({label}) invalid size {size}")

        rank = entry.get("rank")
        if not isinstance(rank, int) or rank < 1:
            errors.append(f"Entry {idx} ({label}) invalid rank {rank}")

        level_index = entry.get("index")
        if not isinstance(level_index, int) or level_index < 0:
            errors.append(f"Entry {idx} ({label}) invalid index {level_index}")

        difficulty = entry.get("difficulty")
        if not isinstance(difficulty, str) or difficulty not in ("tutorial", "easy", "medium", "hard"):
            errors.append(f"Entry {idx} ({label}) invalid difficulty '{difficulty}'")

        if banks and isinstance(size, int) and size in banks:
            bank = banks[size]
            ranks = bank.get("ranks", {})
            rank_str = str(rank)
            if rank_str not in ranks:
                errors.append(f"Entry {idx} ({label}): rank {rank} not found in size {size} bank")
            else:
                bank_levels = ranks[rank_str]
                if level_index < 0 or level_index >= len(bank_levels):
                    errors.append(
                        f"Entry {idx} ({label}): index {level_index} out of range for rank {rank} (has {len(bank_levels)} levels)"
                    )

    return errors


def validate_file(target_path: Path, pace_path: Path | None = None, bank_path: Path | None = None) -> list[str]:
    """Validate file based on type and additional options."""
    if not target_path.exists():
        return [f"File not found: {target_path}"]

    try:
        with open(target_path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception as exc:
        return [f"Failed to read/parse {target_path}: {exc}"]

    # Determine file type
    if "ranks" in data:
        # Bank file
        errors = validate_bank(data)
        if pace_path:
            if not pace_path.exists():
                errors.append(f"Pace file not found: {pace_path}")
            else:
                try:
                    with open(pace_path, "r", encoding="utf-8") as f:
                        pace_data = json.load(f)
                    errors.extend(validate_pace_against_bank(pace_data, data))
                except Exception as exc:
                    errors.append(f"Failed to read pace file {pace_path}: {exc}")
        return errors

    elif "playlist" in data:
        # Campaign playlist
        banks = {}
        if bank_path:
            if not bank_path.exists():
                return [f"Bank file not found: {bank_path}"]
            try:
                with open(bank_path, "r", encoding="utf-8") as f:
                    bank_data = json.load(f)
                banks[bank_data.get("size", 4)] = bank_data
            except Exception as exc:
                return [f"Failed to read bank file {bank_path}: {exc}"]

        return validate_playlist(data, banks=banks if bank_path else None)

    return [f"Unknown content file format in {target_path}"]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", type=Path, help="Target JSON file (bank or campaign playlist)")
    parser.add_argument("--pace", type=Path, help="Pace sidecar JSON to validate against bank")
    parser.add_argument("--bank", type=Path, help="Bank JSON to validate playlist against")
    args = parser.parse_args()

    errors = validate_file(args.target, pace_path=args.pace, bank_path=args.bank)
    if errors:
        print(f"FAIL: {args.target}")
        for err in errors:
            print(f"  - {err}")
        return 1

    print(f"VALID: {args.target}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

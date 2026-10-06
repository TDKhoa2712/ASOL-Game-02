"""Convert extracted level data into bank schema v1 and pace files.

Usage:
  python -B tools/convert_extracted_bank.py --size 7
  python -B tools/convert_extracted_bank.py --all
"""
import argparse
import json
from pathlib import Path
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "GDD" / "tools"))

from level_reasoning import puzzle_key, solve  # noqa: E402
from generate_pace import generate_pace  # noqa: E402


def convert_region_map(region_map: list[list[int]]) -> list[str]:
    """Convert a 2D integer region map into uppercase letter strings."""
    return ["".join(chr(ord("A") + cell) for cell in row) for row in region_map]


def check_level_candy_rules(regions: list[str], solution: list[int], size: int) -> bool:
    """Verify Candoku placement rules for a level."""
    if len(regions) != size or len(solution) != size:
        return False
    for row in regions:
        if len(row) != size:
            return False
    if len(set(solution)) != size:
        return False

    seen_regions: set[str] = set()
    for r in range(size):
        c = solution[r]
        if not isinstance(c, int) or c < 0 or c >= size:
            return False
        reg = regions[r][c]
        if reg in seen_regions:
            return False
        seen_regions.add(reg)
        if r > 0 and abs(c - solution[r - 1]) <= 1:
            return False
    return True


def convert_level(raw: dict, size: int) -> dict | None:
    """Convert a single raw level object to game bank schema v1."""
    region_map = raw.get("regionMap")
    solution = raw.get("solution")
    if not region_map or not solution:
        return None

    regions = convert_region_map(region_map)
    if not check_level_candy_rules(regions, solution, size):
        return None

    givens: list[dict] = []
    result = solve(regions, givens)

    if result["status"] == "SOLVED":
        trace = result["trace"]
        counts = result["vector"]["ruleCounts"]
        pid_hash = puzzle_key(regions, givens)[:8]
        rating = result["D_raw"]
        if rating is None:
            rating = raw.get("r", 1) * 100
        profile = [counts.get("S2", 0), counts.get("S3", 0), 0]
        steps = len(trace)
    else:
        # Fallback trace for advanced levels requiring higher techniques (S4-S7)
        trace = list(result.get("trace", []))
        placed_rows = {
            step["conclusion"]["r"]
            for step in trace
            if step.get("rule") == "S2" and "r" in step.get("conclusion", {})
        }
        for r, c in enumerate(solution):
            if r not in placed_rows:
                trace.append({
                    "rule": "S2",
                    "focus": {"type": "row", "id": r},
                    "conclusion": {"type": "place", "r": r, "c": c},
                    "textKey": "hint.single.row",
                })
        steps = raw.get("steps", len(trace))
        r1 = raw.get("r1", size)
        r2 = raw.get("r2", 0)
        r3_plus = raw.get("r3", 0) + raw.get("r4", 0) + raw.get("r5", 0)
        profile = [r1, r2, r3_plus]
        pid_hash = raw.get("_pid_h", puzzle_key(regions, givens)[:8])
        if len(pid_hash) > 8:
            pid_hash = pid_hash[:8]
        rating = raw.get("rating")
        if rating is None:
            rating = raw.get("r", 1) * 100

    return {
        "seed": raw.get("seed", 0),
        "regions": regions,
        "solution": solution,
        "givens": givens,
        "steps": steps,
        "profile": profile,
        "rating": rating,
        "pidHash": pid_hash,
        "logicTrace": trace,
    }


def load_ranked_source(path: str) -> dict[str, list[dict]]:
    """Load source levels and group by rank (1..5)."""
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    if isinstance(data, dict) and "levels" in data:
        ranked: dict[str, list[dict]] = {}
        for lv in data["levels"]:
            r = str(lv.get("r", 1))
            ranked.setdefault(r, []).append(lv)
        return ranked

    if isinstance(data, list):
        return {"1": data}

    return {str(k): v for k, v in data.items()}


def convert_bank_file(
    source_path: str, size: int, bank_output: str, pace_output: str
) -> dict:
    """Convert an entire source file to bank and pace v1 JSON."""
    raw_ranked = load_ranked_source(source_path)

    bank = {
        "bankVersion": 1,
        "size": size,
        "ranks": {str(r): [] for r in range(1, 6)},
    }
    skipped = 0
    total = 0
    t0 = time.monotonic()

    # Process all ranks present in source, ensuring order
    rank_keys = sorted(set(list(bank["ranks"].keys()) + list(raw_ranked.keys())), key=int)
    for rank_key in rank_keys:
        if rank_key not in bank["ranks"]:
            bank["ranks"][rank_key] = []
        levels_to_convert = raw_ranked.get(rank_key, [])
        for raw_level in levels_to_convert:
            total += 1
            converted = convert_level(raw_level, size)
            if converted is None:
                skipped += 1
                continue
            bank["ranks"][rank_key].append(converted)
        count = len(bank["ranks"][rank_key])
        print(f"  Rank {rank_key}: {count} levels")

    elapsed = time.monotonic() - t0
    accepted = total - skipped
    print(
        f"  Total: {accepted}/{total} levels in {elapsed:.1f}s"
        + (f" ({skipped} skipped)" if skipped else "")
    )

    out = Path(bank_output)
    out.parent.mkdir(parents=True, exist_ok=True)
    with open(out, "w", encoding="utf-8") as f:
        json.dump(bank, f, indent=2)

    generate_pace(bank_output, pace_output)
    return {"accepted": accepted, "skipped": skipped}


SIZE_SOURCES = {
    7: "extracted_reusable/levels/bankData7x7.json",
    8: "extracted_reusable/levels/bankData8x8.json",
    9: "extracted_reusable/levels/bankData9x9.json",
    10: "extracted_reusable/levels/bankData10x10.json",
    11: "extracted_reusable/levels/bankDataGC11x11.json",
    12: "extracted_reusable/levels/bankData12x12.json",
}


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("--size", type=int, help="Board size N (7-12)")
    parser.add_argument("--source", type=str, help="Override source file path")
    parser.add_argument("--all", action="store_true", help="Convert all sizes 7-12")
    parser.add_argument(
        "--output-dir",
        type=str,
        default="game/data/banks",
        help="Output directory (default: game/data/banks)",
    )
    args = parser.parse_args()

    if not args.all and not args.size:
        parser.error("Specify --size N or --all")

    sizes = list(range(7, 13)) if args.all else [args.size]

    for size in sizes:
        source = args.source or SIZE_SOURCES.get(size)
        if not source or not Path(source).exists():
            print(f"Skipping {size}x{size}: source not found ({source})")
            continue
        bank_out = f"{args.output_dir}/bank_{size}x{size}.json"
        pace_out = f"{args.output_dir}/bank_{size}x{size}.pace.json"
        print(f"Converting {size}x{size} from {source}...")
        convert_bank_file(source, size, bank_out, pace_out)

    return 0


if __name__ == "__main__":
    sys.exit(main())

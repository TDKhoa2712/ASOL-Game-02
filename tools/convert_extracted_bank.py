"""Convert extracted level data into bank schema v1 and pace files.

Usage:
  python -B tools/convert_extracted_bank.py --type regular --all
  python -B tools/convert_extracted_bank.py --type lkstyle --all
  python -B tools/convert_extracted_bank.py --type sp --fast
  python -B tools/convert_extracted_bank.py --type all --fast
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
    """Convert a single raw level object to game bank schema v1 using full solver."""
    region_map = raw.get("regionMap")
    solution = raw.get("solution")
    if not region_map or not solution:
        return None

    if isinstance(region_map[0], list):
        regions = convert_region_map(region_map)
    else:
        regions = region_map

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

    seed_val = raw.get("seed", 0)
    if not isinstance(seed_val, (int, float)):
        seed_val = 0

    return {
        "seed": seed_val,
        "regions": regions,
        "solution": solution,
        "givens": givens,
        "steps": steps,
        "profile": profile,
        "rating": rating,
        "pidHash": pid_hash,
        "logicTrace": trace,
    }


def convert_level_fast(raw: dict, size: int, extra_fields: list[str] | None = None) -> dict | None:
    """Fast conversion using source profile and skipping offline solver."""
    region_map = raw.get("regionMap")
    solution = raw.get("solution")
    if not region_map or not solution:
        return None

    if isinstance(region_map[0], list):
        regions = convert_region_map(region_map)
    else:
        regions = region_map

    if not check_level_candy_rules(regions, solution, size):
        return None

    r1 = raw.get("r1", size)
    r2 = raw.get("r2", 0)
    r3 = raw.get("r3", 0) + raw.get("r4", 0) + raw.get("r5", 0)
    pid_hash = raw.get("_pid_h", "")
    if not pid_hash:
        givens: list[dict] = []
        pid_hash = puzzle_key(regions, givens)[:8]
    if len(pid_hash) > 8:
        pid_hash = pid_hash[:8]
    rating = raw.get("rating", raw.get("r", 1) * 100)

    seed_val = raw.get("seed", 0)
    if not isinstance(seed_val, (int, float)):
        seed_val = 0

    entry = {
        "seed": seed_val,
        "regions": regions,
        "solution": solution,
        "givens": [],
        "steps": raw.get("steps", size),
        "profile": [r1, r2, r3],
        "rating": rating,
        "pidHash": pid_hash,
        "logicTrace": [],
    }
    if extra_fields:
        for field in extra_fields:
            if field in raw:
                entry[field] = raw[field]
    return entry


def infer_size_from_raw(raw: dict) -> int:
    """Infer grid size N from raw level object."""
    if "size" in raw and isinstance(raw["size"], int):
        return raw["size"]
    if "solution" in raw and isinstance(raw["solution"], list):
        return len(raw["solution"])
    if "regionMap" in raw and isinstance(raw["regionMap"], list):
        return len(raw["regionMap"])
    return 11


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
    source_path: str,
    size: int,
    bank_output: str,
    pace_output: str,
    fast: bool = False,
    extra_fields: list[str] | None = None,
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
    fn = convert_level_fast if fast else convert_level
    fields = extra_fields or []

    rank_keys = sorted(set(list(bank["ranks"].keys()) + list(raw_ranked.keys())), key=int)
    for rank_key in rank_keys:
        if rank_key not in bank["ranks"]:
            bank["ranks"][rank_key] = []
        levels_to_convert = raw_ranked.get(rank_key, [])
        for raw_level in levels_to_convert:
            total += 1
            converted = fn(raw_level, size, fields) if fast else fn(raw_level, size)
            if converted is None:
                skipped += 1
                continue
            if not fast and fields:
                for fld in fields:
                    if fld in raw_level and fld not in converted:
                        converted[fld] = raw_level[fld]
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


def convert_flat_bank(
    source_path: str,
    bank_type: str,
    output: str,
    pace_output: str,
    extra_fields: list[str] | None = None,
    fast: bool = True,
) -> dict:
    """Convert flat/mixed bank to Variant B bank JSON and pace JSON."""
    with open(source_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    items = data if isinstance(data, list) else data.get("levels", [])

    bank = {"bankVersion": 1, "type": bank_type, "levels": []}
    skipped = 0
    fn = convert_level_fast if fast else convert_level
    fields = extra_fields or []

    for raw in items:
        size = infer_size_from_raw(raw)
        converted = fn(raw, size, fields) if fast else fn(raw, size)
        if converted is None:
            skipped += 1
            continue
        converted["size"] = size
        converted["rank"] = raw.get("r", raw.get("rank", 1))
        if not fast and fields:
            for fld in fields:
                if fld in raw and fld not in converted:
                    converted[fld] = raw[fld]
        bank["levels"].append(converted)

    out = Path(output)
    out.parent.mkdir(parents=True, exist_ok=True)
    with open(out, "w", encoding="utf-8") as f:
        json.dump(bank, f, indent=2)

    generate_pace(output, pace_output)
    print(f"Flat bank '{bank_type}': {len(bank['levels'])} levels accepted ({skipped} skipped) -> {output}")
    return {"accepted": len(bank["levels"]), "skipped": skipped}


BANK_REGISTRY = {
    # Type A: Ranked, 1 file per size
    "regular": {
        "format": "ranked",
        "sources": {
            4: "extracted_reusable/levels/bankData4x4.json",
            5: "extracted_reusable/levels/bankData5x5.json",
            6: "extracted_reusable/levels/bankData6x6.json",
            7: "extracted_reusable/levels/bankData7x7.json",
            8: "extracted_reusable/levels/bankData8x8.json",
            9: "extracted_reusable/levels/bankData9x9.json",
            10: "extracted_reusable/levels/bankData10x10.json",
            12: "extracted_reusable/levels/bankData12x12.json",
        },
        "output": "bank_{size}x{size}.json",
    },
    "lkstyle": {
        "format": "ranked",
        "sources": {
            7: "extracted_reusable/levels/bankDataLKStyle7x7.json",
            8: "extracted_reusable/levels/bankDataLKStyle8x8.json",
            9: "extracted_reusable/levels/bankDataLKStyle9x9.json",
            10: "extracted_reusable/levels/bankDataLKStyle10x10.json",
            11: "extracted_reusable/levels/bankDataLKStyle11x11.json",
            12: "extracted_reusable/levels/bankDataLKStyle12x12.json",
        },
        "output": "bank_lkstyle_{size}x{size}.json",
    },
    "gc": {
        "format": "flat_sized",
        "sources": {
            6: "extracted_reusable/levels/bankDataGC6x6.json",
            8: "extracted_reusable/levels/bankDataGC8x8.json",
            9: "extracted_reusable/levels/bankDataGC9x9.json",
            10: "extracted_reusable/levels/bankDataGC10x10.json",
            11: "extracted_reusable/levels/bankDataGC11x11.json",
            12: "extracted_reusable/levels/bankDataGC12x12.json",
        },
        "output": "bank_gc_{size}x{size}.json",
    },
    "onefish": {
        "format": "flat_sized",
        "sources": {
            7: "extracted_reusable/levels/bankDataOneFish7x7.json",
            8: "extracted_reusable/levels/bankDataOneFish8x8.json",
            9: "extracted_reusable/levels/bankDataOneFish9x9.json",
            10: "extracted_reusable/levels/bankDataOneFish10x10.json",
        },
        "output": "bank_onefish_{size}x{size}.json",
    },
    # Type B: Flat, 1 file total (mixed sizes)
    "sp": {
        "format": "flat_mixed",
        "source": "extracted_reusable/levels/bankDataSP.json",
        "output": "bank_sp.json",
        "extra_fields": ["colorMap", "pattern", "spRegion", "id"],
    },
    "lk": {
        "format": "flat_mixed",
        "source": "extracted_reusable/levels/bankDataLK.json",
        "output": "bank_lk.json",
        "extra_fields": ["id", "label", "date"],
    },
    "lk_modified": {
        "format": "flat_mixed",
        "source": "extracted_reusable/levels/bankDataLKModified.json",
        "output": "bank_lk_modified.json",
        "extra_fields": ["seq", "transform", "id", "maxR"],
    },
    "sp_tt": {
        "format": "flat_mixed",
        "source": "extracted_reusable/levels/bankDataSP_TT.json",
        "output": "bank_sp_tt.json",
        "extra_fields": ["shapeCategory", "id"],
    },
    "single_region": {
        "format": "flat_mixed",
        "source": "extracted_reusable/levels/bankDataSingleRegion.json",
        "output": "bank_single_region.json",
        "extra_fields": ["maxRegionFrac"],
    },
    "super_hard": {
        "format": "flat_mixed",
        "source": "extracted_reusable/levels/bankDataSuperHard.json",
        "output": "bank_super_hard.json",
        "extra_fields": [],
    },
}


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--type",
        type=str,
        default="all",
        help="Bank type to convert (regular, lkstyle, gc, onefish, sp, lk, lk_modified, sp_tt, single_region, super_hard, all)",
    )
    parser.add_argument("--size", type=int, help="Board size N (for sized banks)")
    parser.add_argument("--source", type=str, help="Override source file path")
    parser.add_argument("--all", action="store_true", help="Convert all sizes (for sized banks)")
    parser.add_argument("--fast", action="store_true", help="Fast path: skip solve() and use source profile directly")
    parser.add_argument("--force", action="store_true", help="Force overwrite existing bank files")
    parser.add_argument(
        "--output-dir",
        type=str,
        default="game/data/banks",
        help="Output directory (default: game/data/banks)",
    )
    args = parser.parse_args()

    types_to_run = (
        list(BANK_REGISTRY.keys())
        if args.type == "all"
        else [args.type]
    )

    for btype in types_to_run:
        if btype not in BANK_REGISTRY:
            print(f"Unknown bank type '{btype}', skipping.")
            continue

        cfg = BANK_REGISTRY[btype]
        fmt = cfg["format"]

        if fmt in ("ranked", "flat_sized"):
            sources = cfg["sources"]
            sizes = [args.size] if args.size else sorted(sources.keys())
            for size in sizes:
                source = args.source or sources.get(size)
                if not source or not Path(source).exists():
                    print(f"[{btype}] Skipping {size}x{size}: source not found ({source})")
                    continue
                filename = cfg["output"].format(size=size)
                bank_out = f"{args.output_dir}/{filename}"
                pace_filename = filename.replace(".json", ".pace.json")
                pace_out = f"{args.output_dir}/{pace_filename}"

                # Safety check: if regular bank already exists and not forced, skip to preserve calibrated campaign banks
                if btype == "regular" and Path(bank_out).exists() and not args.force:
                    print(f"[{btype}] Preserving existing {bank_out} (use --force to overwrite)")
                    continue

                print(f"[{btype}] Converting {size}x{size} from {source}...")
                convert_bank_file(
                    source,
                    size,
                    bank_out,
                    pace_out,
                    fast=args.fast,
                    extra_fields=cfg.get("extra_fields"),
                )

        elif fmt == "flat_mixed":
            source = args.source or cfg["source"]
            if not source or not Path(source).exists():
                print(f"[{btype}] Skipping: source not found ({source})")
                continue
            filename = cfg["output"]
            bank_out = f"{args.output_dir}/{filename}"
            pace_filename = filename.replace(".json", ".pace.json")
            pace_out = f"{args.output_dir}/{pace_filename}"

            if Path(bank_out).exists() and not args.force and not args.fast:
                print(f"[{btype}] Preserving existing {bank_out} (use --force to overwrite)")
                continue

            print(f"[{btype}] Converting flat bank from {source}...")
            convert_flat_bank(
                source,
                bank_type=btype,
                output=bank_out,
                pace_output=pace_out,
                extra_fields=cfg.get("extra_fields", []),
                fast=args.fast,
            )

    return 0


if __name__ == "__main__":
    sys.exit(main())

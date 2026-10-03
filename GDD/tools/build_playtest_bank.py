"""Generate 30-level playtest content for CanDoKu rebuild (Module 10).

Usage: python -B GDD/tools/build_playtest_bank.py --size 4
       python -B GDD/tools/build_playtest_bank.py --size 5 --output game/data/banks/bank_5x5.json
Exit 0: bank generation complete.
"""
import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT / "GDD/tools") not in sys.path:
    sys.path.insert(0, str(ROOT / "GDD/tools"))

from convert_to_bank import convert_to_bank
from generate_levels import candidate, exact_check
from generate_pace import generate_pace
from level_reasoning import puzzle_key, solve
from validate_levels import canonical_regions


def generate_playtest_data(size=4, seed_base=None, scratch_dir=None,
                           bank_path=None, pace_path=None, campaign_path=None):
    if seed_base is None:
        seed_base = "candoku-playtest-20261002"
    if scratch_dir is None:
        scratch_dir = ROOT / "scratch/content_gen"
    if bank_path is None:
        bank_path = ROOT / f"game/data/banks/bank_{size}x{size}.json"
    if pace_path is None:
        pace_path = ROOT / f"game/data/banks/bank_{size}x{size}.pace.json"
    if campaign_path is None:
        campaign_path = ROOT / "game/data/campaigns/demo_30.json"

    # Existing tutorial level to preserve exact compatibility for L01 (4x4 only)
    if size == 4:
        existing_l01 = {
            "seed": 7,
            "regions": ["CAAB", "CBBB", "CCBB", "CCDB"],
            "solution": [1, 3, 0, 2],
            "givens": [],
            "steps": 4,
            "profile": [4, 0, 0],
            "rating": 4,
            "pidHash": "6c95fe9a",
            "logicTrace": [
                {
                    "rule": "S2",
                    "focus": {"type": "region", "id": "D"},
                    "conclusion": {"type": "place", "r": 3, "c": 2},
                    "textKey": "hint.single.region"
                },
                {
                    "rule": "S2",
                    "focus": {"type": "region", "id": "A"},
                    "conclusion": {"type": "place", "r": 0, "c": 1},
                    "textKey": "hint.single.region"
                },
                {
                    "rule": "S2",
                    "focus": {"type": "region", "id": "B"},
                    "conclusion": {"type": "place", "r": 1, "c": 3},
                    "textKey": "hint.single.region"
                },
                {
                    "rule": "S2",
                    "focus": {"type": "region", "id": "C"},
                    "conclusion": {"type": "place", "r": 2, "c": 0},
                    "textKey": "hint.single.region"
                }
            ]
        }
        seen_geometry = {canonical_regions(existing_l01["regions"])}
        r1_levels = [existing_l01]
    else:
        seen_geometry = set()
        r1_levels = []

    r2_levels = []
    r3_levels = []

    attempt = 0
    # Target: 12 levels in R1, 10 in R2, 8 in R3
    while len(r1_levels) < 12 or len(r2_levels) < 10 or len(r3_levels) < 8:
        attempt += 1
        max_givens = 1 if len(r1_levels) < 12 and attempt % 3 == 0 else 0
        rows, givens, solution = candidate(seed_base, attempt, size, max_givens)
        shape = canonical_regions(rows)
        if shape in seen_geometry:
            continue

        exact = exact_check(rows, {g["r"]: g["c"] for g in givens}, 200000, 2)
        if exact["status"] != "UNIQUE":
            continue

        res = solve(rows, givens)
        if res["status"] != "SOLVED":
            continue

        d_raw = res["D_raw"]
        trace = res["trace"]
        rule_counts = res["vector"]["ruleCounts"]
        s2_count = rule_counts.get("S2", len(trace))
        s3_count = rule_counts.get("S3", 0)

        level_obj = {
            "seed": attempt,
            "regions": rows,
            "solution": solution,
            "givens": givens,
            "steps": len(trace),
            "profile": [s2_count, s3_count, 0],
            "rating": d_raw,
            "pidHash": puzzle_key(rows, givens)[:8],
            "logicTrace": trace,
        }

        # Classify by difficulty/rating
        if d_raw <= 10 and len(r1_levels) < 12:
            seen_geometry.add(shape)
            r1_levels.append(level_obj)
        elif 10 < d_raw <= 14 and len(r2_levels) < 10:
            seen_geometry.add(shape)
            r2_levels.append(level_obj)
        elif d_raw > 14 and len(r3_levels) < 8:
            seen_geometry.add(shape)
            r3_levels.append(level_obj)

    print(f"Generated {len(r1_levels)} R1, {len(r2_levels)} R2, {len(r3_levels)} R3 levels in {attempt} attempts")

    # Save raw temporary files in scratch
    scratch_dir = Path(scratch_dir)
    scratch_dir.mkdir(parents=True, exist_ok=True)

    r1_file = scratch_dir / "r1_raw.json"
    r2_file = scratch_dir / "r2_raw.json"
    r3_file = scratch_dir / "r3_raw.json"

    r1_file.write_text(json.dumps({"levels": r1_levels}, indent=2), encoding="utf-8")
    r2_file.write_text(json.dumps({"levels": r2_levels}, indent=2), encoding="utf-8")
    r3_file.write_text(json.dumps({"levels": r3_levels}, indent=2), encoding="utf-8")

    # Convert to bank schema v1
    bank_path = Path(bank_path)
    raw_files = [(1, str(r1_file)), (2, str(r2_file)), (3, str(r3_file))]
    convert_to_bank(raw_files, size=size, output=str(bank_path))

    # Generate pace sidecar
    generate_pace(str(bank_path), str(pace_path))

    # Create demo_30.json playlist
    playlist = []
    # L01-L02 tutorial (rank 1, index 0..1)
    playlist.append({"label": "L01", "size": size, "rank": 1, "index": 0, "difficulty": "tutorial"})
    playlist.append({"label": "L02", "size": size, "rank": 1, "index": 1, "difficulty": "tutorial"})
    # L03-L12 easy (rank 1, index 2..11)
    for i in range(2, 12):
        playlist.append({"label": f"L{i+1:02d}", "size": size, "rank": 1, "index": i, "difficulty": "easy"})
    # L13-L22 medium (rank 2, index 0..9)
    for i in range(10):
        playlist.append({"label": f"L{i+13:02d}", "size": size, "rank": 2, "index": i, "difficulty": "medium"})
    # L23-L30 medium (rank 3, index 0..7)
    for i in range(8):
        playlist.append({"label": f"L{i+23:02d}", "size": size, "rank": 3, "index": i, "difficulty": "medium"})

    campaign_data = {
        "campaignVersion": 1,
        "id": "demo-30",
        "playlist": playlist
    }
    campaign_path = Path(campaign_path)
    campaign_path.write_text(json.dumps(campaign_data, indent=2), encoding="utf-8")
    print(f"Playlist written: {campaign_path} ({len(playlist)} levels)")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--size", type=int, default=4, choices=[4, 5, 6],
                        help="Grid size N×N to generate (default: 4)")
    parser.add_argument("--seed", type=str, default=None,
                        help="Base seed string for level generation (default: candoku-playtest-20261002)")
    parser.add_argument("--input", type=Path, default=None, dest="scratch_dir",
                        metavar="DIR",
                        help="Directory for intermediate raw JSON scratch files (default: scratch/content_gen)")
    parser.add_argument("--output", type=Path, default=None,
                        help="Output bank JSON path (default: game/data/banks/bank_NxN.json)")
    parser.add_argument("--pace", type=Path, default=None,
                        help="Output pace JSON path (default: game/data/banks/bank_NxN.pace.json)")
    parser.add_argument("--campaign", type=Path, default=None,
                        help="Output campaign/playlist JSON path (default: game/data/campaigns/demo_30.json)")
    args = parser.parse_args()

    generate_playtest_data(
        size=args.size,
        seed_base=args.seed,
        scratch_dir=args.scratch_dir,
        bank_path=args.output,
        pace_path=args.pace,
        campaign_path=args.campaign,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

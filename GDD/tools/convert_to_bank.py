"""Convert raw generated levels to bank schema v1."""
import argparse
import hashlib
import json
import sys
from pathlib import Path


def compute_pid_hash(regions: list[str], givens: list[dict]) -> str:
    """Compute a deterministic hash for topology and givens."""
    content = json.dumps([regions, sorted([f"{g['r']}:{g['c']}" for g in givens])])
    return hashlib.sha256(content.encode("utf-8")).hexdigest()[:8]


def convert_level(raw: dict, rank: int) -> dict:
    """Convert single level from generator format to bank format."""
    regions = raw["regions"]
    solution = raw["solution"]
    givens = raw.get("givens", [])
    trace = raw.get("logicTrace", [])

    steps = raw.get("steps", len(trace) if trace else len(solution))
    s2_count = sum(1 for step in trace if isinstance(step, dict) and step.get("rule") == "S2")
    s3_count = sum(1 for step in trace if isinstance(step, dict) and step.get("rule") == "S3")
    default_profile = [s2_count if s2_count > 0 else steps, s3_count, 0]
    profile = raw.get("profile", default_profile)
    if not isinstance(profile, list) or len(profile) != 3:
        profile = default_profile

    pid_hash = raw.get("pidHash")
    if not pid_hash:
        pid_hash = compute_pid_hash(regions, givens)

    rating = raw.get("rating", rank * 100)

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


def convert_to_bank(raw_files: list[tuple[int, str]], size: int, output: str) -> None:
    """Merge raw files into single bank file."""
    bank = {
        "bankVersion": 1,
        "size": size,
        "ranks": {}
    }
    for rank, path in raw_files:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
            levels = data["levels"] if isinstance(data, dict) and "levels" in data else data
        bank["ranks"][str(rank)] = [convert_level(lv, rank) for lv in levels]

    out_path = Path(output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(bank, f, indent=2)
    print(f"Bank written: {output} ({sum(len(v) for v in bank['ranks'].values())} levels)")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--size", type=int, required=True, help="Board size N (e.g. 4)")
    parser.add_argument("--output", type=str, required=True, help="Output bank JSON path")
    parser.add_argument(
        "--rank-file",
        nargs=2,
        action="append",
        metavar=("RANK", "FILE"),
        help="Specify rank number and file path, e.g. --rank-file 1 r1_raw.json",
    )
    args = parser.parse_args()

    if not args.rank_file:
        parser.error("At least one --rank-file RANK FILE is required")

    raw_files = [(int(r), path) for r, path in args.rank_file]
    convert_to_bank(raw_files, args.size, args.output)
    return 0


if __name__ == "__main__":
    sys.exit(main())

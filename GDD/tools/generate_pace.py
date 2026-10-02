"""Generate pace sidecar from bank file."""
import argparse
import json
import sys
from pathlib import Path


def generate_pace(bank_path: str, output_path: str) -> None:
    with open(bank_path, "r", encoding="utf-8") as f:
        bank = json.load(f)

    pace = {
        "bankVersion": 1,
        "size": bank["size"],
        "pacing": {}
    }

    for rank_key, levels in bank["ranks"].items():
        pace["pacing"][rank_key] = []
        for level in levels:
            steps = int(level.get("steps", len(level["solution"])))
            # rSeq: extract technique level from trace steps
            trace = level.get("logicTrace", [])
            if trace and isinstance(trace, list) and isinstance(trace[0], dict):
                r_seq = [{"S2": 1, "S3": 2}.get(step.get("rule", "S2"), 1) for step in trace]
            else:
                r_seq = [1] * steps

            while len(r_seq) < steps:
                r_seq.append(1)
            r_seq = r_seq[:steps]

            # hintCosts: progressive hint clicks needed per step
            hint_costs = [max(1, r) for r in r_seq]
            pace["pacing"][rank_key].append({
                "rSeq": r_seq,
                "hintCosts": hint_costs,
            })

    out_p = Path(output_path)
    out_p.parent.mkdir(parents=True, exist_ok=True)
    with open(out_p, "w", encoding="utf-8") as f:
        json.dump(pace, f, indent=2)
    print(f"Pace written: {output_path}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("bank", type=str, help="Input bank JSON file")
    parser.add_argument("output", type=str, help="Output pace JSON file")
    args = parser.parse_args()

    generate_pace(args.bank, args.output)
    return 0


if __name__ == "__main__":
    sys.exit(main())

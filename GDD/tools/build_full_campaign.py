"""Create a complete campaign with the demo prefix and every bank tuple once."""

import argparse
import json
from pathlib import Path


def build_full_campaign(demo: dict, banks: dict[int, dict]) -> dict:
    if demo.get('campaignVersion') != 1 or not isinstance(demo.get('playlist'), list):
        raise ValueError('invalid demo campaign')
    available = {(size, int(rank), index)
                 for size, bank in banks.items()
                 for rank, levels in bank['ranks'].items()
                 for index in range(len(levels))}
    prefix = demo['playlist']
    seen = set()
    for order, entry in enumerate(prefix, 1):
        reference = (entry['size'], entry['rank'], entry['index'])
        if reference not in available or reference in seen:
            raise ValueError(f'demo entry {order} has missing or duplicate bank reference')
        if entry['label'] != f'L{order:02d}':
            raise ValueError(f'demo entry {order} has unexpected label')
        seen.add(reference)
    entries = [dict(entry) for entry in prefix]
    for size, rank, index in sorted(available - seen):
        entries.append({'label': f'L{len(entries) + 1:02d}', 'size': size,
                        'rank': rank, 'index': index,
                        'difficulty': 'easy' if rank == 1 else 'medium' if rank == 2 else 'hard'})
    return {'campaignVersion': 1, 'id': 'full-998', 'playlist': entries}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--demo', type=Path, required=True)
    parser.add_argument('--banks', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    demo = json.loads(args.demo.read_text(encoding='utf-8'))
    banks = {size: json.loads((args.banks / f'bank_{size}x{size}.json').read_text(encoding='utf-8'))
             for size in (4, 5, 6)}
    campaign = build_full_campaign(demo, banks)
    args.output.write_text(json.dumps(campaign, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'Wrote {len(campaign["playlist"])} entries: {args.output}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

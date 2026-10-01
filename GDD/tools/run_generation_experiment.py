"""Repeat the pilot profile across seeds; report failures as well as successes."""
import argparse
from collections import Counter
import json
from pathlib import Path
import statistics
import sys

from generate_levels import generate, pilot_profile, provenance
from validate_levels import validate_document


def experiment(count, excluded):
    runs, scores, attempts, rejects = [], {}, [], Counter()
    for index in range(count):
        profile = pilot_profile()
        profile['seed'] += f'-experiment-{index:03d}'
        data, report = generate(profile, excluded)
        if data['levels']:
            _, warnings = validate_document(data)
            if warnings:
                raise ValueError(warnings)
        attempts.append(report['attempts'])
        rejects.update(report['rejections'])
        runs.append({'seed': profile['seed'], 'status': report['status'], 'attempts': report['attempts'],
                     'acceptedCount': report['acceptedCount'], 'elapsedSeconds': report['elapsedSeconds'],
                     'unmetSlots': report['unmetSlots'],
                     'candidates': [{'id': r['id'], 'D_raw': r['D_raw'], 'tier': r['lowestProvenTier'],
                                     'order': r['targetProfile']['order'], 'reviewFlags': r['reviewFlags']}
                                    for r in report['levels']]})
        for record in report['levels']:
            scores.setdefault(str(record['targetProfile']['order']), []).append(record['D_raw'])
    complete = sum(r['status'] == 'COMPLETE' for r in runs)
    return {'status': 'COMPLETE' if complete == count else 'INCOMPLETE',
            'seedCount': count, 'completeBatches': complete, 'acceptedCount': sum(r['acceptedCount'] for r in runs),
            'attempts': {'min': min(attempts), 'median': statistics.median(attempts), 'max': max(attempts)},
            'ratingByOrder': {k: {'min': min(v), 'median': statistics.median(v), 'max': max(v), 'count': len(v)} for k, v in scores.items()},
            'rejections': dict(sorted(rejects.items())), 'runs': runs,
            'humanValidation': 'NOT_RUN', 'scope': 'Machine feasibility across seeds; not player difficulty calibration.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--seeds', type=int, default=20)
    parser.add_argument('--out', required=True, type=Path)
    parser.add_argument('--exclude', action='append', type=Path, default=[])
    args = parser.parse_args()
    if not 1 <= args.seeds <= 100 or args.out.exists():
        parser.error('use 1..100 seeds and a new output path')
    excluded = []
    for path in args.exclude:
        excluded.extend(json.loads(path.read_text(encoding='utf-8'))['levels'])
    result = experiment(args.seeds, excluded)
    result['source'] = provenance()
    result['command'] = [sys.executable, '-B', *sys.argv]
    result['exitCode'] = 0 if result['status'] == 'COMPLETE' else 2
    result['excludedFiles'] = [str(p) for p in args.exclude]
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f"{result['status']}: {result['completeBatches']}/{args.seeds} batches; {result['acceptedCount']} accepted")
    print(json.dumps(result['attempts']))
    print(json.dumps(result['ratingByOrder']))
    return 0 if result['status'] == 'COMPLETE' else 2


if __name__ == '__main__':
    raise SystemExit(main())

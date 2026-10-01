"""Bounded offline pilot generator. Never writes the live campaign.

Usage: python -B GDD/tools/generate_levels.py --out scratch/level-pilot
Exit 0: requested machine-validated batch complete; 2: budget/requirements unmet.
Difficulty labels remain provisional until blind human playtests.
"""
import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import itertools
import json
from pathlib import Path
import platform
import random
import statistics
import subprocess
import sys
import time

from level_reasoning import POLICIES, compact, digest, puzzle_key, solve
from validate_levels import (canonical_regions, count_solutions, object_no_duplicates,
                             validate_level, validate_release_logic_band)

VERSION = 'candoku-offline-1'
ROOT = Path(__file__).resolve().parents[2]


def pilot_profile():
    return {'profileVersion': 1, 'seed': 'candoku-pilot-20260929',
            'slots': [{'order': order, 'size': size, 'minRating': low, 'maxRating': high}
                      for order, size, low, high in
                      ((2, 4, 5, 10), (4, 4, 6, 13), (7, 5, 9, 16), (10, 5, 7, 12),
                       (14, 6, 12, 16), (18, 6, 17, 24), (19, 5, 16, 25), (22, 6, 20, 32))],
            'maxGivens': 2, 'minPlayableCandies': 2, 'maxAttempts': 5000,
            'maxWallSeconds': 120, 'exactMaxNodes': 2000000, 'exactMaxSeconds': 5}


def validate_profile(p):
    expected = set(pilot_profile())
    if not isinstance(p, dict) or set(p) != expected:
        raise ValueError('profile fields must match pilot profile v1')
    if type(p['profileVersion']) is not int or p['profileVersion'] != 1:
        raise ValueError('profileVersion must be 1')
    if not isinstance(p['seed'], str) or not p['seed']:
        raise ValueError('seed must be nonempty text')
    for key in ('maxGivens', 'maxAttempts', 'exactMaxNodes', 'minPlayableCandies'):
        if type(p[key]) is not int or p[key] < (2 if key == 'minPlayableCandies' else 0):
            raise ValueError(f'invalid {key}')
    for key in ('maxWallSeconds', 'exactMaxSeconds'):
        if type(p[key]) not in (float, int) or not 0 < p[key] < float('inf'):
            raise ValueError(f'invalid {key}')
    if not isinstance(p['slots'], list) or not p['slots']:
        raise ValueError('slots must be nonempty')
    orders = set()
    for s in p['slots']:
        if not isinstance(s, dict) or set(s) != {'order', 'size', 'minRating', 'maxRating'}:
            raise ValueError('slot requires order, size, minRating and maxRating')
        if any(type(s[k]) is not int for k in ('minRating', 'maxRating')) or not 0 <= s['minRating'] <= s['maxRating']:
            raise ValueError('invalid rating range')
        if type(s['order']) is not int or not 2 <= s['order'] <= 24 or s['order'] in orders:
            raise ValueError('pilot orders must be unique in 2..24 (tutorial needs separate review)')
        if type(s['size']) is not int or not 4 <= s['size'] <= 6:
            raise ValueError('pilot supports sizes 4..6')
        if p['minPlayableCandies'] > s['size'] or p['maxGivens'] > s['size'] - p['minPlayableCandies']:
            raise ValueError('given/playable constraints conflict')
        orders.add(s['order'])


def exact_check(rows, givens, nodes, seconds):
    try:
        found = count_solutions(rows, givens, max_nodes=nodes, max_seconds=seconds)
    except ValueError as exc:
        if 'search budget exceeded' not in str(exc):
            raise
        return {'status': 'UNKNOWN', 'reason': str(exc)}
    return {'status': ('INVALID', 'UNIQUE', 'MULTIPLE')[len(found)],
            'solution': list(found[0]) if len(found) == 1 else None}


def candidate(seed, attempt, n, max_givens):
    rng = random.Random(int(digest([VERSION, seed, attempt, n]), 16))
    # N<=6: at most 720 permutations. Uniform choice among legal base solutions.
    solutions = [p for p in itertools.permutations(range(n)) if all(abs(a-b) > 1 for a, b in zip(p, p[1:]))]
    solution = list(rng.choice(solutions))
    grid = [[None] * n for _ in range(n)]
    for r, c in enumerate(solution):
        grid[r][c] = r
    for _ in range(n*n-n):
        frontier = []
        for r in range(n):
            for c in range(n):
                if grid[r][c] is not None:
                    continue
                neighbors = set()
                for rr, cc in ((r-1, c), (r+1, c), (r, c-1), (r, c+1)):
                    if 0 <= rr < n and 0 <= cc < n and grid[rr][cc] is not None:
                        neighbors.add(grid[rr][cc])
                frontier.extend((r, c, label) for label in sorted(neighbors))
        r, c, label = rng.choice(frontier)
        grid[r][c] = label
    names = {}
    rows = [''.join(names.setdefault(label, chr(65+len(names))) for label in row) for row in grid]
    given_rows = sorted(rng.sample(range(n), rng.randrange(max_givens+1)))
    return rows, [{'r': r, 'c': solution[r]} for r in given_rows], solution


def generate(profile, excluded=()):
    validate_profile(profile)
    start = time.monotonic()
    accepted, records, rejected = [], [], Counter()
    seen = {canonical_regions(l['regions']) for l in excluded}
    attempt = 0
    for slot in profile['slots']:
        while attempt < profile['maxAttempts'] and time.monotonic()-start < profile['maxWallSeconds']:
            index = attempt
            attempt += 1
            n, order = slot['size'], slot['order']
            rows, givens, solution = candidate(profile['seed'], index, n, profile['maxGivens'])
            shape = canonical_regions(rows)
            if shape in seen:
                rejected['duplicateGeometry'] += 1
                continue
            remaining_time = profile['maxWallSeconds'] - (time.monotonic()-start)
            exact = exact_check(rows, {g['r']: g['c'] for g in givens}, profile['exactMaxNodes'],
                                min(profile['exactMaxSeconds'], max(0, remaining_time)))
            if exact['status'] != 'UNIQUE':
                rejected[exact['status']] += 1
                continue
            if exact['solution'] != solution:
                raise ValueError('generator solution differs from independent exact solver')
            basic = solve(rows, givens, allow_s3=False)
            needs_s3 = order >= 19
            if needs_s3 and basic['status'] == 'SOLVED':
                rejected['S3_NOT_REQUIRED'] += 1
                continue
            reference = solve(rows, givens) if needs_s3 else basic
            if reference['status'] != 'SOLVED':
                rejected['LOGIC_' + reference['status']] += 1
                continue
            if not slot['minRating'] <= reference['D_raw'] <= slot['maxRating']:
                rejected['RATING_RANGE'] += 1
                continue
            variants = [reference] + [solve(rows, givens, allow_s3=needs_s3, policy=p) for p in POLICIES[1:]]
            label = 'medium' if needs_s3 or reference['D_raw'] > 16 else 'easy'
            level = {'schemaVersion': 4, 'id': 'P' + puzzle_key(rows, givens)[:12].upper(),
                     'order': order, 'size': n, 'regions': rows, 'givens': givens, 'solution': solution,
                     'difficulty': label, 'tags': ['offline-pilot', 'provisional-difficulty'],
                     'logicTrace': reference['trace']}
            validate_level(level)
            validate_release_logic_band(level)
            for variant in variants:
                validate_level(dict(level, logicTrace=variant['trace']))
            scores = [v['D_raw'] for v in variants]
            vector = reference['vector']
            vector['policySpread'] = {'min': min(scores), 'median': statistics.median(scores), 'max': max(scores)}
            areas = Counter(''.join(rows))
            boundaries = sum(rows[r][c] != rows[rr][cc] for r in range(n) for c in range(n)
                             for rr, cc in ((r+1, c), (r, c+1)) if rr < n and cc < n)
            records.append({'id': level['id'], 'attemptIndex': index, 'targetProfile': slot,
                            'status': 'MACHINE_VALIDATED', 'exactStatus': exact['status'], 'proofStatus': 'SOLVED',
                            's2OnlyStatus': basic['status'], 'lowestProvenTier': 'I' if needs_s3 else 'B',
                            'ratingVersion': 'candoku-rating-0', 'evidencePolicy': 'per-cell-lowest-depth-v1',
                            'D_raw': reference['D_raw'], 'vector': vector, 'evidence': reference['evidence'],
                            'policyScores': {v['policy']: v['D_raw'] for v in variants},
                            'geometryKey': shape, 'puzzleKey': puzzle_key(rows, givens),
                            'puzzleHash': digest([n, rows, sorted(givens, key=lambda g: (g['r'], g['c'])), solution]),
                            'contentHash': digest(level),
                            'reviewFlags': [name for name, condition in (
                                ('policySpread', max(scores)-min(scores) > 4),
                                ('lateFirstPlacement', vector['firstPlacementStep'] > 3),
                                ('longEliminationRun', vector['maxEliminationRun'] > 2)) if condition],
                            'visualMetrics': {'regionAreas': dict(sorted(areas.items())), 'boundaryEdges': boundaries},
                            'measuredDifficulty': label, 'reviewedDifficulty': None,
                            'playerEvidence': {'status': 'NOT_RUN', 'sampleCount': 0}, 'uiReview': 'NOT_RUN'})
            accepted.append(level)
            seen.add(shape)
            break
        else:
            break
    return {'levels': accepted}, {'generatorVersion': VERSION, 'profile': profile,
            'prng': 'Python random.Random/MT19937', 'pythonVersion': platform.python_version(),
            'ruleCatalogVersion': 'candoku-reasoning-1', 'policyVersion': POLICIES[0],
            'status': 'COMPLETE' if len(accepted) == len(profile['slots']) else 'INCOMPLETE',
            'acceptedCount': len(accepted), 'attempts': attempt, 'rejections': dict(sorted(rejected.items())),
            'unmetSlots': profile['slots'][len(accepted):], 'elapsedSeconds': round(time.monotonic()-start, 3),
            'excludedGeometryCount': len({canonical_regions(l['regions']) for l in excluded}), 'levels': records}


def provenance():
    def git(*args):
        return subprocess.check_output(['git', *args], cwd=ROOT).decode('utf-8').strip()
    return {'revision': git('rev-parse', 'HEAD'), 'workingStatus': git('status', '--short'),
            'workingDiffSha256': hashlib.sha256(git('diff', '--binary', 'HEAD').encode('utf-8')).hexdigest(),
            'toolHashes': {str(p.relative_to(ROOT)).replace('\\', '/'): hashlib.sha256(p.read_bytes()).hexdigest()
                           for p in sorted((ROOT / 'GDD/tools').glob('*.py'))}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--profile', type=Path)
    parser.add_argument('--out', type=Path, required=True, help='new output directory (never overwritten)')
    parser.add_argument('--exclude', type=Path, action='append', default=[])
    args = parser.parse_args()
    if args.out.exists():
        parser.error('output directory already exists; select a new directory')
    profile = json.loads(args.profile.read_text(encoding='utf-8'), object_pairs_hook=object_no_duplicates) if args.profile else pilot_profile()
    excluded = []
    for path in args.exclude:
        excluded.extend(json.loads(path.read_text(encoding='utf-8'), object_pairs_hook=object_no_duplicates)['levels'])
    data, report = generate(profile, excluded)
    report['source'] = provenance()
    report['execution'] = {'command': [sys.executable, '-B', *sys.argv],
                           'utc': datetime.now(timezone.utc).isoformat(),
                           'excludedFiles': [str(p) for p in args.exclude],
                           'exitCode': 0 if report['status'] == 'COMPLETE' else 2}
    args.out.mkdir(parents=True)
    for filename, value in (('levels.json', data), ('report.json', report), ('profile.json', profile)):
        (args.out / filename).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    from pilot_report import write_reports
    write_reports(args.out, data, report)
    print(f"{report['status']}: {len(data['levels'])}/{len(profile['slots'])} levels, {report['attempts']} attempts, {report['elapsedSeconds']}s")
    print(json.dumps(report['rejections'], sort_keys=True))
    return 0 if report['status'] == 'COMPLETE' else 2


if __name__ == '__main__':
    raise SystemExit(main())

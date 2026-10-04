"""Deterministically expand an original CanDoKu bank with a resumable checkpoint."""

import argparse
import collections
import hashlib
import json
import os
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))

from bank_expansion_rules import (BANDS, level_from_proof, median_ratings,
                                  pace_from_trace, prove_candidate, rank_for,
                                  repair_five_by_five)
from generate_levels import candidate, exact_check
from level_reasoning import solve
from validate_levels import canonical_regions
from validate_full_content import TARGET_COUNTS, validate_full_banks

CHECKPOINT_VERSION = 1


def _hash(raw):
    return hashlib.sha256(raw).hexdigest()


def _json_bytes(value):
    return json.dumps(value, ensure_ascii=False, indent=2).encode('utf-8')


def _atomic_write(path, raw):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    handle, temporary = tempfile.mkstemp(prefix=path.name + '.', dir=path.parent)
    try:
        with os.fdopen(handle, 'wb') as stream:
            stream.write(raw)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def _checkpoint_identity(size, seed, targets, bank_raw, pace_raw):
    return {'version': CHECKPOINT_VERSION, 'size': size, 'seed': seed,
            'targets': targets, 'bankHash': _hash(bank_raw), 'paceHash': _hash(pace_raw)}


def _checkpoint(path, identity, next_attempt, accepted, rejected):
    state = dict(identity, nextAttempt=next_attempt, accepted=accepted,
                 rejected=dict(sorted(rejected.items())))
    _atomic_write(path, _json_bytes(state))


def _validate_inputs(size, bank, pace, targets):
    if size not in BANDS or bank.get('size') != size or pace.get('size') != size:
        raise ValueError('bank, pace and requested board size differ')
    if set(targets) != {'1', '2', '3', '4', '5'}:
        raise ValueError('targets must specify ranks 1 through 5')
    if set(bank['ranks']) - set(targets) or set(pace['pacing']) - set(targets):
        raise ValueError('unknown rank in source bank or pace')
    for rank, target in targets.items():
        old_count = len(bank['ranks'].get(rank, []))
        if type(target) is not int or target < old_count:
            raise ValueError(f'rank {rank} target {target} below old count {old_count}')
        if len(pace['pacing'].get(rank, [])) != old_count:
            raise ValueError(f'rank {rank} bank and pace counts differ')


def _finish(size, bank, pace, accepted, targets):
    bank, pace = repair_five_by_five(bank, pace)
    for rank in targets:
        bank['ranks'].setdefault(rank, [])
        pace['pacing'].setdefault(rank, [])
        for level in accepted[rank]:
            bank['ranks'][rank].append(level)
            pace['pacing'][rank].append(pace_from_trace(level['logicTrace']))
    medians = median_ratings(bank)
    values = [medians[rank] for rank in sorted(medians)]
    if values != sorted(values):
        raise ValueError(f'non-monotonic rank median difficulty: {medians}')
    errors = validate_full_banks({size: bank}, {size: pace}, {size: targets})
    if errors:
        raise ValueError('completed bank failed proof: ' + '; '.join(errors[:5]))
    return bank, pace, medians


def expand_bank(size: int, bank_path: Path, pace_path: Path,
                checkpoint_path: Path, seed: str, max_attempts: int,
                target_counts: dict[str, int]) -> dict:
    """Append only after all targets pass; budget is a cumulative attempt cap."""
    bank_path, pace_path, checkpoint_path = map(Path, (bank_path, pace_path, checkpoint_path))
    bank_raw, pace_raw = bank_path.read_bytes(), pace_path.read_bytes()
    bank, pace = json.loads(bank_raw), json.loads(pace_raw)
    targets = dict(target_counts)
    _validate_inputs(size, bank, pace, targets)
    if not seed or max_attempts < 0:
        raise ValueError('seed must be nonempty and max_attempts nonnegative')
    identity = _checkpoint_identity(size, seed, targets, bank_raw, pace_raw)
    accepted = {rank: [] for rank in targets}
    rejected = collections.Counter()
    attempt = 0
    if checkpoint_path.exists():
        state = json.loads(checkpoint_path.read_text(encoding='utf-8'))
        if any(state.get(key) != value for key, value in identity.items()):
            raise ValueError('checkpoint does not match source bank, pace, seed or targets')
        accepted = state['accepted']
        rejected.update(state['rejected'])
        attempt = state['nextAttempt']
    seen = {canonical_regions(level['regions'])
            for levels in bank['ranks'].values() for level in levels}
    seen.update(canonical_regions(level['regions'])
                for levels in accepted.values() for level in levels)
    needed = {rank: targets[rank] - len(bank['ranks'].get(rank, [])) for rank in targets}
    while attempt < max_attempts and any(len(accepted[rank]) < count for rank, count in needed.items()):
        index = attempt
        attempt += 1
        max_givens = BANDS[size][1][index % len(BANDS[size][1])]
        rows, givens, solution = candidate(seed, index, size, max_givens)
        shape = canonical_regions(rows)
        if shape in seen:
            rejected['duplicateGeometry'] += 1
            continue
        exact = exact_check(rows, {given['r']: given['c'] for given in givens}, 200000, 2)
        if exact['status'] != 'UNIQUE':
            rejected[exact['status']] += 1
            continue
        if exact['solution'] != solution:
            raise ValueError(f'attempt {index}: generator solution disagrees with exact proof')
        proof = solve(rows, givens)
        if proof['status'] != 'SOLVED':
            rejected['logic_' + proof['status']] += 1
            continue
        rank = rank_for(size, proof['D_raw'], proof['vector']['ruleCounts'].get('S3', 0))
        if rank is None or len(accepted[rank]) >= needed[rank]:
            rejected['bandFull'] += 1
            continue
        level = level_from_proof(index, rows, givens, solution, proof)
        prove_candidate(size, rank, level)
        accepted[rank].append(level)
        seen.add(shape)
        if sum(map(len, accepted.values())) % 25 == 0:
            _checkpoint(checkpoint_path, identity, attempt, accepted, rejected)
    _checkpoint(checkpoint_path, identity, attempt, accepted, rejected)
    counts = {rank: len(bank['ranks'].get(rank, [])) + len(accepted[rank]) for rank in targets}
    report = {'status': 'INCOMPLETE', 'size': size, 'seed': seed,
              'attempts': attempt, 'targetCounts': targets, 'currentCounts': counts,
              'rejections': dict(sorted(rejected.items())), 'ratingBands': BANDS[size][0],
              'sourceBankHash': identity['bankHash'], 'sourcePaceHash': identity['paceHash']}
    if counts != targets:
        return report
    finished_bank, finished_pace, medians = _finish(size, bank, pace, accepted, targets)
    bank_output, pace_output = _json_bytes(finished_bank), _json_bytes(finished_pace)
    _atomic_write(bank_path, bank_output)
    _atomic_write(pace_path, pace_output)
    report.update(status='COMPLETE', medianRatings=medians,
                  bankHash=_hash(bank_output), paceHash=_hash(pace_output))
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--size', type=int, choices=(4, 5, 6), required=True)
    parser.add_argument('--bank', type=Path, required=True)
    parser.add_argument('--pace', type=Path, required=True)
    parser.add_argument('--checkpoint', type=Path, required=True)
    parser.add_argument('--seed', required=True)
    parser.add_argument('--max-attempts', type=int, required=True)
    args = parser.parse_args()
    report = expand_bank(args.size, args.bank, args.pace, args.checkpoint,
                         args.seed, args.max_attempts, TARGET_COUNTS[args.size])
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report['status'] == 'COMPLETE' else 2


if __name__ == '__main__':
    raise SystemExit(main())

"""Difficulty bands and schema conversion for offline bank expansion."""

import copy
import statistics

from level_reasoning import puzzle_key, solve
from validate_levels import validate_level

BANDS = {
    4: ((10, 14, 19, 26), (0, 1, 0, 0)),
    5: ((10, 14, 25, 31), (0, 1, 2, 0)),
    6: ((10, 14, 24, 31), (0, 0, 1, 3)),
}


def rank_for(size, rating, s3_count):
    for rank, ceiling in enumerate(BANDS[size][0], 1):
        if rating <= ceiling:
            return str(rank)
    return '5' if s3_count else None


def level_from_proof(attempt, rows, givens, solution, proof):
    counts = proof['vector']['ruleCounts']
    trace = proof['trace']
    return {
        'seed': attempt,
        'regions': rows,
        'solution': solution,
        'givens': givens,
        'steps': len(trace),
        'profile': [counts.get('S2', 0), counts.get('S3', 0), 0],
        'rating': proof['D_raw'],
        'pidHash': puzzle_key(rows, givens)[:8],
        'logicTrace': trace,
    }


def pace_from_trace(trace):
    sequence = [1 if step['rule'] == 'S2' else 2 for step in trace]
    return {'rSeq': sequence, 'hintCosts': list(sequence)}


def repair_five_by_five(bank, pace):
    """Rebuild the 30 approved invalid traces without changing puzzle cells."""
    if bank['size'] != 5:
        return bank, pace
    bank, pace = copy.deepcopy(bank), copy.deepcopy(pace)
    for rank in ('1', '2', '3'):
        for index, level in enumerate(bank['ranks'][rank]):
            proof = solve(level['regions'], level['givens'])
            if proof['status'] != 'SOLVED':
                raise ValueError(f'5x5 rank {rank}[{index}] cannot be proved')
            level['logicTrace'] = proof['trace']
            level['steps'] = len(proof['trace'])
            counts = proof['vector']['ruleCounts']
            level['profile'] = [counts.get('S2', 0), counts.get('S3', 0), 0]
            level['rating'] = proof['D_raw']
            pace['pacing'][rank][index] = pace_from_trace(proof['trace'])
    return bank, pace


def prove_candidate(size, rank, level):
    proof = {
        'schemaVersion': 4, 'id': f'R{size}{rank}{level["pidHash"].upper()}',
        'order': 31, 'size': size, 'regions': level['regions'],
        'givens': level['givens'], 'solution': level['solution'],
        'difficulty': 'medium', 'tags': [], 'logicTrace': level['logicTrace'],
    }
    validate_level(proof)


def median_ratings(bank):
    return {rank: statistics.median([level['rating'] for level in levels])
            for rank, levels in bank['ranks'].items() if levels}

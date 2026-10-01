"""Answer-blind S2/S3 closure and measured, provisional rating-0.

No solution parameter is accepted. Proof witnesses are selected per excluded
cell by lowest dependency depth, then source coordinate. This is a reference
proof, not a globally shortest trace or minimum dependency graph.
"""
import hashlib
import json
import math

POLICIES = ('evidence-first-v1', 'coordinate-first-v1', 'reverse-coordinate-v1')


def compact(value):
    return json.dumps(value, ensure_ascii=False, separators=(',', ':'), sort_keys=True)


def digest(value):
    return hashlib.sha256(compact(value).encode('utf-8')).hexdigest()


def puzzle_key(rows, givens):
    """D4 canonical topology AND givens; independent of names and order."""
    n = len(rows)
    variants = []
    for mirror in (False, True):
        for turns in range(4):
            def transform(r, c):
                if mirror:
                    c = n - 1 - c
                for _ in range(turns):
                    r, c = c, n - 1 - r
                return r, c
            grid = [[''] * n for _ in range(n)]
            for r in range(n):
                for c in range(n):
                    rr, cc = transform(r, c)
                    grid[rr][cc] = rows[r][c]
            names = {}
            normalized = []
            for row in grid:
                normalized.append(''.join(names.setdefault(x, chr(65 + len(names))) for x in row))
            marks = sorted(transform(g['r'], g['c']) for g in givens)
            variants.append(compact([normalized, marks]))
    return hashlib.sha256(min(variants).encode('utf-8')).hexdigest()


def rating(counts, bottlenecks, depth, visible):
    if any(x is None for x in (bottlenecks, depth, visible)):
        return None
    return counts['S2'] + 4 * counts['S3'] + 2 * bottlenecks + depth + math.ceil(visible / 6)


def conflicts(rows, a, b):
    return (a[0] == b[0] or a[1] == b[1]
            or rows[a[0]][a[1]] == rows[b[0]][b[1]]
            or max(abs(a[0]-b[0]), abs(a[1]-b[1])) <= 1)


def solve(rows, givens, allow_s3=True, policy=POLICIES[0]):
    if policy not in POLICIES:
        raise ValueError('unknown proof policy')
    n = len(rows)
    board = {(r, c) for r in range(n) for c in range(n)}
    units = []
    for kind, ids in (('row', range(n)), ('column', range(n)), ('region', sorted(set(''.join(rows))))):
        for uid in ids:
            cells = {p for p in board if (p[0] == uid if kind == 'row' else p[1] == uid if kind == 'column' else rows[p[0]][p[1]] == uid)}
            units.append(({'type': kind, 'id': uid}, cells))
    placed = {(g['r'], g['c']): 0 for g in givens}
    eliminated = {}
    trace, evidence, action_counts = [], [], []
    depths = {0: 0}
    run = max_run = 0

    def witnesses(absent):
        deps, visible, premise_units = set(), set(), {}
        for cell in sorted(absent):
            options = [(depths[step], step, candy) for candy, step in placed.items() if conflicts(rows, cell, candy)]
            if cell in eliminated:
                step = eliminated[cell]
                options.append((depths[step], step, cell))
            if not options:
                raise ValueError('missing exclusion witness')
            _, step, source = min(options)
            if step:
                deps.add(step)
            visible.add(source)
            # Include the unit actually used for an S1 witness. Adjacency
            # needs the two cells, but introduces no row/column/region unit.
            if source != cell:
                unit = None
                if source[0] == cell[0]:
                    unit = {'type': 'row', 'id': cell[0]}
                elif source[1] == cell[1]:
                    unit = {'type': 'column', 'id': cell[1]}
                elif rows[source[0]][source[1]] == rows[cell[0]][cell[1]]:
                    unit = {'type': 'region', 'id': rows[cell[0]][cell[1]]}
                if unit:
                    premise_units[compact(unit)] = unit
        return deps, visible, premise_units

    def all_units(witness_units, *focus):
        combined = dict(witness_units)
        combined.update({compact(spec): spec for spec in focus})
        return [combined[key] for key in sorted(combined)]

    while len(placed) < n:
        candidates = {p for p in board if p not in eliminated and not any(conflicts(rows, p, q) for q in placed)}
        active = [(spec, cells, cells & candidates) for spec, cells in units if not cells & placed.keys()]
        if any(not remaining for _, _, remaining in active):
            status = 'INVALID'
            break
        actions = []
        for spec, cells, remaining in active:
            if len(remaining) == 1:
                cell = min(remaining)
                deps, visible, premise_units = witnesses(cells - remaining)
                step = {'rule': 'S2', 'focus': spec, 'conclusion': {'type': 'place', 'r': cell[0], 'c': cell[1]}, 'textKey': 'hint.single.' + spec['type']}
                actions.append((step, (cell,), deps, cells | visible, all_units(premise_units, spec)))
        if not actions and allow_s3:
            for source, source_cells, remaining in active:
                for target, target_cells, target_remaining in active:
                    removed = target_remaining - source_cells
                    if source['type'] == target['type'] or not remaining <= target_cells or not removed:
                        continue
                    # Reproduce the exact candidate sets required by the v4
                    # checker, including earlier exclusions in the target.
                    deps, visible, premise_units = witnesses((source_cells | target_cells) - candidates)
                    step = {'rule': 'S3', 'source': source, 'target': target, 'conclusion': {'type': 'eliminate', 'cells': [{'r': r, 'c': c} for r, c in sorted(removed)]}, 'textKey': 'hint.lock.intersection'}
                    actions.append((step, tuple(sorted(removed)), deps, source_cells | target_cells | visible, all_units(premise_units, source, target)))
        if not actions:
            status = 'STUCK'
            break
        # Deduplicate identical conclusions, retain the smallest evidence.
        actions.sort(key=lambda a: (len(a[4]), len(a[3]), -len(a[1]), compact(a[0])))
        unique = {}
        for action in actions:
            unique.setdefault(action[1], action)
        actions = list(unique.values())
        if policy != POLICIES[0]:
            actions.sort(key=lambda a: a[1], reverse=policy == POLICIES[2])
        action_counts.append(len(actions))
        step, cells, deps, visible, premise_units = actions[0]
        index = len(trace) + 1
        depths[index] = 1 + max((depths[d] for d in deps), default=0)
        trace.append(step)
        evidence.append({'step': index, 'dependsOn': sorted(deps), 'depth': depths[index],
                         'visibleCells': [list(p) for p in sorted(visible)], 'premiseUnits': premise_units})
        if step['rule'] == 'S2':
            placed[cells[0]] = index
            run = 0
        else:
            eliminated.update({p: index for p in cells})
            run += 1
            max_run = max(max_run, run)
    else:
        status = 'SOLVED'
    counts = {rule: sum(s['rule'] == rule for s in trace) for rule in ('S2', 'S3')}
    depth = max(depths.values())
    visible = max((len(e['visibleCells']) for e in evidence), default=0)
    bottlenecks = action_counts.count(1)
    vector = {'playableCount': n-len(givens), 'placedCount': counts['S2'], 'ruleCounts': counts,
              'eliminatedCount': len(eliminated), 'maxRuleTier': 'I' if counts['S3'] else 'B',
              'maxEliminationRun': max_run, 'proofDepth': depth,
              'maxPremiseUnits': max((len(e['premiseUnits']) for e in evidence), default=0),
              'maxVisibleCells': visible, 'availableActions': action_counts, 'bottleneckCount': bottlenecks,
              'firstPlacementStep': next((i+1 for i, s in enumerate(trace) if s['rule'] == 'S2'), None)}
    return {'status': status, 'trace': trace, 'evidence': evidence, 'vector': vector,
            'policy': policy, 'D_raw': rating(counts, bottlenecks, depth, visible) if status == 'SOLVED' else None}

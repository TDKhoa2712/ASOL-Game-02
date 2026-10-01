import copy
import json
import unittest
from pathlib import Path

from generate_levels import generate, pilot_profile, exact_check
from level_reasoning import solve, rating, puzzle_key
from validate_levels import validate_level, validate_release_logic_band
from unittest.mock import patch
from pilot_report import blind_sheets


class GenerationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fixtures = json.loads((Path(__file__).parents[1] / 'data/levels.sample.json').read_text(encoding='utf-8'))['levels']

    def test_solver_proves_fixtures_without_solution_input(self):
        for original in self.fixtures:
            level = copy.deepcopy(original)
            result = solve(level['regions'], level['givens'])
            self.assertEqual(result['status'], 'SOLVED', level['id'])
            level['logicTrace'] = result['trace']
            validate_level(level)
            if level['id'] == 'S301':
                self.assertEqual(solve(level['regions'], level['givens'], allow_s3=False)['status'], 'STUCK')
                self.assertGreater(result['vector']['ruleCounts']['S3'], 0)

    def test_rating_examples_and_missing_evidence(self):
        self.assertEqual(rating({'S2': 5, 'S3': 2}, 2, 4, 12), 23)
        self.assertEqual(rating({'S2': 5, 'S3': 0}, 1, 2, 6), 10)
        self.assertIsNone(rating({'S2': 5, 'S3': 0}, 1, None, 6))

    def test_exact_budget_never_becomes_unique(self):
        rows = ['AAAA', 'BBBB', 'CCCC', 'DDDD']
        self.assertEqual(exact_check(rows, {}, 0, 5)['status'], 'UNKNOWN')
        self.assertEqual(exact_check(rows, {}, 1000, 5)['status'], 'MULTIPLE')
        self.assertEqual(exact_check(rows, {0: 0, 1: 1}, 1000, 5)['status'], 'INVALID')
        one = self.fixtures[0]
        self.assertEqual(exact_check(one['regions'], {}, 1000, 5)['status'], 'UNIQUE')

    def test_puzzle_key_transforms_givens_with_regions(self):
        level = self.fixtures[1]
        rows, givens = level['regions'], level['givens']
        n = len(rows)
        rotated = [''.join(rows[n-1-c][r] for c in range(n)) for r in range(n)]
        transformed = [{'r': g['c'], 'c': n-1-g['r']} for g in givens]
        self.assertEqual(puzzle_key(rows, givens), puzzle_key(rotated, transformed))
        self.assertNotEqual(puzzle_key(rows, givens), puzzle_key(rows, []))

    def test_generation_reproducible_and_independently_valid(self):
        profile = pilot_profile()
        profile['slots'] = profile['slots'][:2]
        a, report_a = generate(profile)
        b, report_b = generate(profile)
        self.assertEqual(a, b)
        self.assertEqual(report_a['status'], 'COMPLETE')
        self.assertEqual(report_a['attempts'], report_b['attempts'])
        for level in a['levels']:
            validate_level(level)
            validate_release_logic_band(level)
        self.assertEqual(len({puzzle_key(l['regions'], l['givens']) for l in a['levels']}), 2)

    def test_incomplete_batch_reports_actual_count(self):
        profile = pilot_profile()
        profile['maxAttempts'] = 0
        data, report = generate(profile)
        self.assertEqual(data, {'levels': []})
        self.assertEqual(report['status'], 'INCOMPLETE')
        self.assertEqual(len(report['unmetSlots']), len(profile['slots']))

    def test_blind_sheets_do_not_depend_on_answers_or_rating(self):
        level = copy.deepcopy(self.fixtures[1])
        before = blind_sheets({'levels': [level]})
        level['solution'] = ['SECRET']
        level['logicTrace'] = ['SECRET']
        level['difficulty'] = 'SECRET'
        self.assertEqual(before, blind_sheets({'levels': [level]}))
        self.assertNotIn('SECRET', before)

    def test_profile_rating_filter_does_not_silently_relax(self):
        p = pilot_profile()
        p['slots'] = [dict(p['slots'][0], minRating=999, maxRating=999)]
        p['maxAttempts'] = 20
        data, report = generate(p)
        self.assertFalse(data['levels'])
        self.assertEqual(report['status'], 'INCOMPLETE')
        self.assertGreater(report['rejections']['RATING_RANGE'], 0)

    def test_invalid_profile_rejected(self):
        for change in ({'slots': []}, {'maxGivens': True}, {'maxWallSeconds': -1}):
            p = pilot_profile()
            p.update(change)
            with self.assertRaises(ValueError):
                generate(p)
        p = pilot_profile()
        p['slots'][0]['size'] = 7
        with self.assertRaises(ValueError):
            generate(p)

    def test_pilot_covers_s3_and_excludes_existing_geometry(self):
        data, report = generate(pilot_profile(), self.fixtures)
        self.assertEqual(report['status'], 'COMPLETE')
        for level, measured in zip(data['levels'], report['levels']):
            validate_level(level)
            validate_release_logic_band(level)
            self.assertEqual(measured['s2OnlyStatus'] == 'STUCK', level['order'] >= 19)
            self.assertEqual(measured['playerEvidence']['sampleCount'], 0)
            self.assertEqual(measured['vector']['placedCount'], level['size']-len(level['givens']))

    def test_budget_exhaustion_after_partial_search_is_unknown(self):
        with patch('generate_levels.count_solutions', side_effect=ValueError('solver search budget exceeded; uniqueness not proven')):
            self.assertEqual(exact_check(['AAAA'] * 4, {}, 100, 1)['status'], 'UNKNOWN')

    def test_proof_dependencies_are_sufficient_without_unrelated_steps(self):
        data, _ = generate(pilot_profile())
        from validate_levels import validate_trace
        for level in data['levels']:
            result = solve(level['regions'], level['givens'])
            for evidence in result['evidence']:
                needed = set(evidence['dependsOn'])
                queue = list(needed)
                while queue:
                    parent = queue.pop()
                    for ancestor in result['evidence'][parent-1]['dependsOn']:
                        if ancestor not in needed:
                            needed.add(ancestor)
                            queue.append(ancestor)
                # Replaying only ancestors + this step must pass each step;
                # a partial trace may fail only the final completion check.
                selected = sorted(needed | {evidence['step']})
                partial = dict(level, logicTrace=[result['trace'][i-1] for i in selected])
                try:
                    validate_trace(partial, {g['r']: g['c'] for g in level['givens']})
                except ValueError as exc:
                    self.assertIn('trace ends with', str(exc))
            independent = [e for e in result['evidence'] if not e['dependsOn']]
            self.assertTrue(all(e['depth'] == 1 for e in independent))


if __name__ == '__main__':
    unittest.main()

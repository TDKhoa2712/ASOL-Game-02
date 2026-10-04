"""Behavior tests for deterministic full-bank expansion."""

import json
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))

from expand_bank import expand_bank
from validate_levels import canonical_regions
from validate_full_content import validate_full_banks


class ExpandBankTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.original = json.loads((ROOT / 'game/data/banks/bank_4x4.json').read_text())
        self.original_pace = json.loads((ROOT / 'game/data/banks/bank_4x4.pace.json').read_text())
        for rank, count in {'1': 12, '2': 10, '3': 8, '4': 0, '5': 0}.items():
            self.original['ranks'][rank] = self.original['ranks'][rank][:count]
            self.original_pace['pacing'][rank] = self.original_pace['pacing'][rank][:count]
        self.targets = {'1': 13, '2': 10, '3': 8, '4': 0, '5': 0}

    def paths(self, name):
        folder = self.root / name
        folder.mkdir()
        bank, pace, checkpoint = (folder / 'bank.json', folder / 'pace.json', folder / 'checkpoint.json')
        bank.write_text(json.dumps(self.original), encoding='utf-8')
        pace.write_text(json.dumps(self.original_pace), encoding='utf-8')
        return bank, pace, checkpoint

    def test_resume_matches_uninterrupted_and_preserves_old_values(self):
        bank, pace, checkpoint = self.paths('resume')
        before_bank, before_pace = bank.read_bytes(), pace.read_bytes()
        first = expand_bank(4, bank, pace, checkpoint, 'test-seed', 1, self.targets)
        self.assertEqual('INCOMPLETE', first['status'])
        self.assertEqual((before_bank, before_pace), (bank.read_bytes(), pace.read_bytes()))
        resumed = expand_bank(4, bank, pace, checkpoint, 'test-seed', 3000, self.targets)
        self.assertEqual('COMPLETE', resumed['status'])
        bank2, pace2, checkpoint2 = self.paths('fresh')
        fresh = expand_bank(4, bank2, pace2, checkpoint2, 'test-seed', 3000, self.targets)
        self.assertEqual('COMPLETE', fresh['status'])
        self.assertEqual(bank.read_bytes(), bank2.read_bytes())
        self.assertEqual(pace.read_bytes(), pace2.read_bytes())
        result = json.loads(bank.read_text())
        result_pace = json.loads(pace.read_text())
        for rank in ('1', '2', '3'):
            self.assertEqual(self.original['ranks'][rank], result['ranks'][rank][:len(self.original['ranks'][rank])])
            self.assertEqual(self.original_pace['pacing'][rank], result_pace['pacing'][rank][:len(self.original_pace['pacing'][rank])])
        shapes = [canonical_regions(level['regions']) for levels in result['ranks'].values() for level in levels]
        self.assertEqual(len(shapes), len(set(shapes)))
        added = result['ranks']['1'][-1]
        self.assertEqual(len(added['logicTrace']), added['steps'])
        self.assertEqual([{'S2': 1, 'S3': 2}[step['rule']] for step in added['logicTrace']],
                         result_pace['pacing']['1'][-1]['rSeq'])

    def test_rejects_existing_target_below_count(self):
        bank, pace, checkpoint = self.paths('short')
        with self.assertRaises(ValueError):
            expand_bank(4, bank, pace, checkpoint, 'test-seed', 10,
                        dict(self.targets, **{'1': 11}))

    def test_checkpoint_rejects_changed_seed(self):
        bank, pace, checkpoint = self.paths('seed')
        expand_bank(4, bank, pace, checkpoint, 'test-seed', 1, self.targets)
        with self.assertRaises(ValueError):
            expand_bank(4, bank, pace, checkpoint, 'other-seed', 10, self.targets)

    def test_repair_five_by_five_keeps_original_puzzles(self):
        bank, pace, checkpoint = self.paths('five')
        original = json.loads((ROOT / 'game/data/banks/bank_5x5.json').read_text())
        original_pace = json.loads((ROOT / 'game/data/banks/bank_5x5.pace.json').read_text())
        for rank, count in {'1': 12, '2': 10, '3': 8, '4': 0, '5': 0}.items():
            original['ranks'][rank] = original['ranks'].get(rank, [])[:count]
            original_pace['pacing'][rank] = original_pace['pacing'].get(rank, [])[:count]
        original['ranks']['1'][0]['logicTrace'] = []
        original_pace['pacing']['1'][0] = {'rSeq': [], 'hintCosts': []}
        bank.write_text(json.dumps(original), encoding='utf-8')
        pace.write_text(json.dumps(original_pace), encoding='utf-8')
        targets = {'1': 12, '2': 10, '3': 8, '4': 0, '5': 0}
        report = expand_bank(5, bank, pace, checkpoint, 'repair-only', 0, targets)
        self.assertEqual('COMPLETE', report['status'])
        repaired, repaired_pace = json.loads(bank.read_text()), json.loads(pace.read_text())
        for rank in ('1', '2', '3'):
            for old, new in zip(original['ranks'][rank], repaired['ranks'][rank]):
                for field in ('seed', 'regions', 'solution', 'givens', 'pidHash'):
                    self.assertEqual(old[field], new[field])
        self.assertEqual([], validate_full_banks({5: repaired}, {5: repaired_pace}, {5: targets}))


if __name__ == '__main__':
    unittest.main()

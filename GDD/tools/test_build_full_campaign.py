"""Tests for complete bank-reference campaign assembly."""

import copy
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_full_campaign import build_full_campaign


class FullCampaignTests(unittest.TestCase):
    def setUp(self):
        self.demo = {'campaignVersion': 1, 'id': 'demo-30', 'playlist': [
            {'label': 'L01', 'size': 4, 'rank': 1, 'index': 0, 'difficulty': 'tutorial'},
            {'label': 'L02', 'size': 5, 'rank': 1, 'index': 0, 'difficulty': 'easy'},
        ]}
        self.banks = {
            4: {'ranks': {'1': [{'rating': 4}, {'rating': 12}], '2': [{'rating': 16}]}},
            5: {'ranks': {'1': [{'rating': 7}], '2': [{'rating': 24}]}},
        }

    def test_exact_prefix_and_full_unique_coverage(self):
        before = copy.deepcopy(self.demo)
        result = build_full_campaign(self.demo, self.banks)
        self.assertEqual(before, self.demo)
        self.assertEqual('full-998', result['id'])
        self.assertEqual(before['playlist'], result['playlist'][:2])
        self.assertEqual(['L01', 'L02', 'L03', 'L04', 'L05'],
                         [entry['label'] for entry in result['playlist']])
        self.assertEqual([(4, 1, 1), (4, 2, 0), (5, 2, 0)],
                         [(entry['size'], entry['rank'], entry['index'])
                          for entry in result['playlist'][2:]])
        self.assertEqual(result, build_full_campaign(self.demo, self.banks))

    def test_demo_reference_missing_from_bank_is_error(self):
        self.banks[5]['ranks']['1'] = []
        with self.assertRaises(ValueError):
            build_full_campaign(self.demo, self.banks)

    def test_duplicate_demo_reference_is_error(self):
        self.demo['playlist'][1].update(size=4, rank=1, index=0)
        with self.assertRaises(ValueError):
            build_full_campaign(self.demo, self.banks)


if __name__ == '__main__':
    unittest.main()

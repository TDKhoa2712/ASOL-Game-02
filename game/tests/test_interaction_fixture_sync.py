import json
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
GAME_ROOT = REPOSITORY_ROOT / "game"
GDD_ROOT = REPOSITORY_ROOT / "GDD"


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


class InteractionFixtureSyncTests(unittest.TestCase):
    def test_interaction_contract_matches_canonical_fixture(self) -> None:
        canonical = load_json(GDD_ROOT / "data" / "interactions.sample.json")
        runtime = load_json(
            GAME_ROOT / "tests" / "fixtures" / "interactions.v2.json"
        )

        self.assertEqual(runtime, canonical)

    def test_t01_matches_canonical_level(self) -> None:
        canonical_levels = load_json(
            GDD_ROOT / "data" / "levels.sample.json"
        )["levels"]
        canonical = next(level for level in canonical_levels if level["id"] == "T01")
        runtime = load_json(GAME_ROOT / "data" / "t01.json")

        self.assertEqual(runtime, canonical)


if __name__ == "__main__":
    unittest.main()

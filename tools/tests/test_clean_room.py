"""Clean-room gate: reference names and extracted_reusable imports must fail."""
import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def load():
    spec = importlib.util.spec_from_file_location("clean_room", ROOT / "tools/clean_room.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class CleanRoomTests(unittest.TestCase):
    def make_tree(self, files):
        folder = tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        root = Path(folder.name)
        for name, text in files.items():
            path = root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8")
        return root

    def test_clean_tree_has_no_violations(self):
        root = self.make_tree({"game/scripts/a.gd": "var board := 1\n",
                               "game/tests/test_a.gd": "extends SceneTree\n"})
        self.assertEqual(load().scan(root), [])

    def test_reference_name_in_scripts_is_reported(self):
        root = self.make_tree({"game/scripts/core/a.gd": "ok\nvar bus = EventBus\n"})
        found = load().scan(root)
        self.assertEqual(len(found), 1)
        self.assertIn("game/scripts/core/a.gd:2", found[0])

    def test_extracted_reusable_in_tests_is_reported(self):
        root = self.make_tree({"game/tests/test_a.gd": 'preload("res://extracted_reusable/x.gd")\n'})
        self.assertEqual(len(load().scan(root)), 1)

    def test_reference_name_in_tests_is_allowed(self):
        root = self.make_tree({"game/tests/test_a.gd": "# not an EventBus\n"})
        self.assertEqual(load().scan(root), [])

    def test_repository_is_clean(self):
        self.assertEqual(load().scan(ROOT), [])

    def test_verify_runs_clean_room_gate(self):
        spec = importlib.util.spec_from_file_location("verify", ROOT / "tools/verify.py")
        verify = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(verify)
        commands = dict(verify.build_checks(ROOT, "godot"))
        self.assertEqual(commands.get("clean-room"), [sys.executable, "-B", "tools/clean_room.py"])


if __name__ == "__main__":
    unittest.main()

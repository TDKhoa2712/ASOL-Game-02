import os
import shutil
import subprocess
import unittest
from pathlib import Path


GAME_DIR = Path(__file__).resolve().parents[1]


def godot_binary() -> str:
    configured = os.environ.get("GODOT_BIN")
    if configured:
        return configured
    discovered = shutil.which("godot")
    if discovered:
        return discovered
    raise RuntimeError("Set GODOT_BIN to the pinned Godot executable")


class RuntimeSmokeTests(unittest.TestCase):
    def test_bootstrap_scene_starts_and_exits_cleanly(self) -> None:
        result = subprocess.run(
            [
                godot_binary(),
                "--headless",
                "--path",
                str(GAME_DIR),
                "--script",
                "res://tests/test_integration.gd",
            ],
            capture_output=True,
            text=True,
            encoding="utf-8",
            timeout=60,
            check=False,
        )

        self.assertEqual(
            result.returncode,
            0,
            msg=f"Godot runtime smoke failed:\nSTDOUT:\n{result.stdout}\nSTDERR:\n{result.stderr}",
        )
        self.assertIn("INTEGRATION_PASS", result.stdout)
        self.assertNotIn("SCRIPT ERROR", result.stdout + result.stderr)
        self.assertNotIn("ERROR:", result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()

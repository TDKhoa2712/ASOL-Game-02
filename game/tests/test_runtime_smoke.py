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
                "--quit-after",
                "2",
            ],
            capture_output=True,
            text=True,
            timeout=60,
            check=False,
        )

        self.assertEqual(
            result.returncode,
            0,
            msg=f"Godot runtime smoke failed:\nSTDOUT:\n{result.stdout}\nSTDERR:\n{result.stderr}",
        )
        self.assertIn("M0_A01_BOOTSTRAP_READY", result.stdout)


if __name__ == "__main__":
    unittest.main()

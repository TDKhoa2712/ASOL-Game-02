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


class ProjectBaselineTests(unittest.TestCase):
    def test_project_loads_as_godot_4_7_project(self) -> None:
        result = subprocess.run(
            [
                godot_binary(),
                "--headless",
                "--path",
                str(GAME_DIR),
                "--script",
                "res://tests/project_settings_probe.gd",
            ],
            capture_output=True,
            text=True,
            timeout=60,
            check=False,
        )

        self.assertEqual(
            result.returncode,
            0,
            msg=f"Godot project probe failed:\nSTDOUT:\n{result.stdout}\nSTDERR:\n{result.stderr}",
        )


if __name__ == "__main__":
    unittest.main()

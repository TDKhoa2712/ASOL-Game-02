"""Export a debug APK that opens the M0-A03 rendering probe directly."""

import os
import shutil
import subprocess
from pathlib import Path


GAME = Path(__file__).resolve().parents[1]
PROJECT = GAME / "project.godot"
OUTPUT = GAME / "build/android/mobile-rendering-spike-debug.apk"
NORMAL_MAIN = b'run/main_scene="res://scenes/bootstrap.tscn"'
SPIKE_MAIN = b'run/main_scene="res://scenes/mobile_rendering_spike.tscn"'


def main() -> None:
    godot = os.environ.get("GODOT_BIN") or shutil.which("godot")
    if not godot:
        raise SystemExit("Set GODOT_BIN to the pinned Godot executable")
    original = PROJECT.read_bytes()
    if original.count(NORMAL_MAIN) != 1:
        raise SystemExit("Expected exactly one normal main scene; project was not modified")
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    try:
        PROJECT.write_bytes(original.replace(NORMAL_MAIN, SPIKE_MAIN))
        subprocess.run(
            [
                godot,
                "--headless",
                "--path",
                str(GAME),
                "--export-debug",
                "Android M0 Debug",
                str(OUTPUT),
            ],
            check=True,
        )
    finally:
        PROJECT.write_bytes(original)
    print(f"M0_A03_SPIKE_APK_SAVED: {OUTPUT}")


if __name__ == "__main__":
    main()

"""Run all headless checks, retaining evidence without package state."""
import argparse
from datetime import datetime, timezone
import hashlib
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]


def build_checks(root, godot):
    suites = sorted((root / "game/tests").glob("run_*.gd"))
    suites += sorted((root / "game/tests").glob("test_*.gd"))
    if not suites:
        raise ValueError("No Godot run_*.gd or test_*.gd suites found")
    checks = [("python:" + folder, [sys.executable, "-B", "-m", "unittest",
               "discover", folder, "-p", "test_*.py"])
              for folder in ("game/tests", "GDD/tools", "tools/tests")]
    checks += [("levels:GDD/data/levels.sample.json", [sys.executable, "-B",
                "GDD/tools/validate_levels.py", "GDD/data/levels.sample.json"])]
    checks += [("content:bank_4x4", [sys.executable, "-B", "tools/validate_content.py",
                "game/data/banks/bank_4x4.json", "--pace", "game/data/banks/bank_4x4.pace.json"])]
    checks += [("content:demo_30", [sys.executable, "-B", "tools/validate_content.py",
                "game/data/campaigns/demo_30.json", "--bank", "game/data/banks/bank_4x4.json"])]
    checks += [("godot:" + path.stem, [godot, "--headless", "--path", "game",
                "--script", "res://tests/" + path.name]) for path in suites]
    return checks


def run_checks(checks, root, log, timeout):
    passed = bool(checks)
    for name, command in checks:
        started = time.monotonic()
        log.write(f"\n## {name}\nCommand: {subprocess.list2cmdline(command)}\n")
        log.flush()
        try:
            result = subprocess.run(command, cwd=root, capture_output=True, text=True,
                                    encoding="utf-8", errors="replace", timeout=timeout)
            output = result.stdout + result.stderr
            code = result.returncode
            ok = code == 0 and not re.search(
                r"SCRIPT ERROR|^ERROR:|skipped=\d+|Ran 0 tests", output, re.MULTILINE)
        except (OSError, subprocess.TimeoutExpired) as error:
            code, ok, output = "unavailable/timeout", False, str(error)
        elapsed = time.monotonic() - started
        summary = f"{'PASS' if ok else 'FAIL'} {name} exit={code} duration={elapsed:.2f}s"
        print(summary, flush=True)
        log.write(output + "\n" + summary + "\n")
        log.flush()
        passed = passed and ok
    return passed


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT).decode("utf-8", "replace").strip()


def fingerprint():
    """Identify actual test inputs, including dirty and untracked sources."""
    paths = git("ls-files", "-z", "--cached", "--others", "--exclude-standard",
                "--", "game", "GDD", "tools").split("\0")
    digest = hashlib.sha256()
    for name in sorted(set(paths)):
        path = ROOT / name
        if name and path.is_file():
            digest.update(name.encode("utf-8") + b"\0" + path.read_bytes() + b"\0")
    return digest.hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=os.environ.get("GODOT_BIN") or shutil.which("godot"),
                        help="Executable, or GODOT_BIN, or godot on PATH")
    parser.add_argument("--timeout", type=float, default=180, help="Seconds per check")
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    folder = ROOT / "scratch/verification"
    folder.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    path = folder / f"{timestamp}.txt"
    latest = folder / "latest.txt"
    latest.write_text(f"RUNNING: {path.name}\nNo final result yet.\n", encoding="utf-8")
    started = time.monotonic()
    passed = False
    with path.open("w", encoding="utf-8") as log:
        log.write(f"UTC: {timestamp}\nPython: {sys.version}\n")
        try:
            log.write(f"Revision: {git('rev-parse', 'HEAD')}\nBranch: {git('branch', '--show-current')}\n")
            log.write(f"Working tree:\n{git('status', '--short')}\n")
            before = fingerprint()
            log.write(f"Source SHA256: {before}\n")
            if not args.godot:
                raise ValueError("Set --godot or GODOT_BIN to a Godot executable")
            binary = shutil.which(args.godot)
            if not binary:
                raise ValueError(f"Godot executable not found: {args.godot}")
            os.environ["GODOT_BIN"] = binary
            os.environ["PYTHONDONTWRITEBYTECODE"] = "1"
            version_ok = run_checks([("godot-version", [binary, "--version"])], ROOT, log, args.timeout)
            passed = run_checks(build_checks(ROOT, binary), ROOT, log, args.timeout) and version_ok
            if fingerprint() != before:
                log.write("FAIL: source inputs changed during verification; rerun on stable inputs.\n")
                passed = False
        except (OSError, ValueError, subprocess.SubprocessError) as error:
            passed = False
            log.write(f"FAIL: {error}\n")
            print(f"FAIL: {error}", flush=True)
        summary = f"{'PASS' if passed else 'FAIL'} full headless verification; duration={time.monotonic() - started:.2f}s"
        log.write(f"\n{summary}\nGUI/device acceptance: NOT RUN\n")
    shutil.copyfile(path, latest)
    print(f"{summary}\nEvidence: {path}")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())

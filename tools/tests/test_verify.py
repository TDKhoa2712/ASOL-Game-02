"""Runner regressions: a failed or incomplete check must never look green."""
import importlib.util
import io
import sys
import tempfile
import unittest
from unittest.mock import patch
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class VerifyTests(unittest.TestCase):
    def load_runner(self):
        path = ROOT / "tools/verify.py"
        self.assertTrue(path.exists(), "Verification runner is missing")
        spec = importlib.util.spec_from_file_location("verify", path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_failure_does_not_hide_following_results(self):
        runner = self.load_runner()
        log = io.StringIO()
        checks = [("bad", [sys.executable, "-c", "raise SystemExit(7)"]),
                  ("good", [sys.executable, "-c", "print('finished')"])]
        self.assertFalse(runner.run_checks(checks, ROOT, log, 10))
        self.assertIn("exit=7", log.getvalue())
        self.assertIn("finished", log.getvalue())

    def test_script_error_with_zero_exit_is_failure(self):
        runner = self.load_runner()
        self.assertFalse(runner.run_checks(
            [("godot", [sys.executable, "-c", "print('SCRIPT ERROR: broken')"])],
            ROOT, io.StringIO(), 10))

    def test_missing_executable_and_timeout_are_failures(self):
        runner = self.load_runner()
        for command, timeout in [(["missing-verify-executable-12345"], 10),
                                 ([sys.executable, "-c", "import time; time.sleep(5)"], .05)]:
            with self.subTest(command=command):
                self.assertFalse(runner.run_checks([( "check", command)], ROOT, io.StringIO(), timeout))

    def test_no_godot_suites_is_error(self):
        runner = self.load_runner()
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaises(ValueError):
                runner.build_checks(Path(folder), "godot")

    def test_all_godot_runners_are_discovered_without_capture_probes(self):
        runner = self.load_runner()
        checks = runner.build_checks(ROOT, "godot")
        actual = {command[-1] for name, command in checks if name.startswith("godot:")}
        expected = {"res://tests/" + p.name for p in (ROOT / "game/tests").glob("run_*.gd")}
        self.assertEqual(actual, expected)
        self.assertTrue(actual)

    def test_metadata_failure_after_checks_cannot_report_pass(self):
        runner = self.load_runner()
        with tempfile.TemporaryDirectory() as folder:
            temporary = Path(folder)
            with patch.object(runner, "ROOT", temporary), \
                 patch.object(runner, "git", return_value="test revision"), \
                 patch.object(runner, "fingerprint", side_effect=["before", OSError("read failed")]), \
                 patch.object(runner, "build_checks", return_value=[]), \
                 patch.object(runner, "run_checks", return_value=True), \
                 patch.object(sys, "argv", ["verify.py", "--godot", sys.executable]):
                self.assertEqual(runner.main(), 1)
            self.assertIn("FAIL full headless", (temporary / "scratch/verification/latest.txt").read_text())

    def test_zero_tests_or_skips_cannot_report_full_pass(self):
        runner = self.load_runner()
        for output in ["Ran 0 tests", "OK (skipped=1)"]:
            with self.subTest(output=output):
                self.assertFalse(runner.run_checks(
                    [("python:empty", [sys.executable, "-c", f"print({output!r})"])],
                    ROOT, io.StringIO(), 10))


if __name__ == "__main__":
    unittest.main()

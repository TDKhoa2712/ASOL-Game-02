from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from tools.agent_pipeline import PipelineError, load_package, normalize_repo_path


VALID_PACKAGE = '''+++
id = "M0-A01"
title = "Baseline"
kind = "implementation"
phase = "M0"
status = "ready"
depends_on = []
requirements = ["D-06"]
qa = ["QA-26"]
read_first = ["GDD/README.md"]
allowed_paths = ["game/**"]
deliverables = ["game/project.godot"]
out_of_scope = ["wallet"]
[[checks]]
id = "fixture"
command = ["python", "GDD/tools/validate_levels.py", "GDD/data/levels.sample.json"]
+++
# Baseline
'''


class PackageParsingTests(unittest.TestCase):
    def test_loads_valid_package(self):
        with TemporaryDirectory() as temp:
            path = Path(temp, "M0-A01.md")
            path.write_text(VALID_PACKAGE, encoding="utf-8")
            package = load_package(path)
            self.assertEqual(package.id, "M0-A01")
            self.assertEqual(package.checks[0].command[0], "python")

    def test_rejects_missing_front_matter_and_required_field(self):
        with TemporaryDirectory() as temp:
            path = Path(temp, "bad.md")
            path.write_text("# no metadata", encoding="utf-8")
            with self.assertRaisesRegex(PipelineError, "front matter"):
                load_package(path)

            path.write_text(
                VALID_PACKAGE.replace('phase = "M0"\n', ''), encoding="utf-8"
            )
            with self.assertRaisesRegex(PipelineError, "phase"):
                load_package(path)

    def test_normalizes_windows_paths_and_rejects_escape(self):
        self.assertEqual(
            normalize_repo_path(r"work\evidence\M0 A01\**"),
            "work/evidence/M0 A01/**",
        )
        for unsafe in ("../outside", "/outside", r"C:\outside"):
            with self.subTest(unsafe=unsafe):
                with self.assertRaisesRegex(PipelineError, "thoát khỏi repository"):
                    normalize_repo_path(unsafe)


if __name__ == "__main__":
    unittest.main()

from pathlib import Path
from tempfile import TemporaryDirectory
import json
import unittest

from tools.agent_pipeline import (
    PipelineError,
    doctor,
    inspect_package,
    load_document_register,
    load_package,
    load_packages,
    main,
    normalize_repo_path,
    trace_requirement,
    validate_catalog,
    validate_links,
)


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


_TEMP_DIRECTORIES: list[TemporaryDirectory[str]] = []


def package_text(
    package_id: str,
    *,
    depends_on: list[str] | None = None,
    requirements: list[str] | None = None,
    qa: list[str] | None = None,
) -> str:
    return f'''+++
id = {json.dumps(package_id)}
title = "Test package"
kind = "implementation"
phase = "M0"
status = "ready"
depends_on = {json.dumps(depends_on or [])}
requirements = {json.dumps(requirements or [])}
qa = {json.dumps(qa or [])}
read_first = ["GDD/README.md"]
allowed_paths = ["game/**"]
deliverables = ["game/project.godot"]
out_of_scope = []
+++
# Test package
'''


def make_repository(packages: dict[str, str] | None = None) -> Path:
    temporary = TemporaryDirectory()
    _TEMP_DIRECTORIES.append(temporary)
    root = Path(temporary.name)
    (root / "work" / "packages").mkdir(parents=True)
    (root / "GDD").mkdir()
    (root / "GDD" / "README.md").write_text("# GDD\n", encoding="utf-8")
    for package_id, text in (packages or {}).items():
        write_package(root, text, filename=f"{package_id}.md")
    return root


def write_package(root: Path, text: str, *, filename: str = "package.md") -> Path:
    path = root / "work" / "packages" / filename
    path.write_text(text, encoding="utf-8")
    return path


def make_registered_repository(*, requirements: str, qa: str) -> Path:
    root = make_repository()
    governance = root / "docs" / "governance"
    governance.mkdir(parents=True)
    (root / "GDD" / "README.md").write_text(requirements, encoding="utf-8")
    (governance / "qa.md").write_text(qa, encoding="utf-8")
    (governance / "README.md").write_text("# Governance\n", encoding="utf-8")
    (governance / "document-register.toml").write_text(
        '''[[documents]]
path = "GDD/README.md"
class = "GDD"
status = "CANONICAL"
owner = "design"

[[documents]]
path = "docs/governance/qa.md"
class = "QA"
status = "ACTIVE"
owner = "qa"

[[documents]]
path = "docs/governance/README.md"
class = "GOVERNANCE"
status = "ACTIVE"
owner = "tech"
''',
        encoding="utf-8",
    )
    return root


def make_valid_repository() -> Path:
    root = make_registered_repository(
        requirements="| D-06 | Engine |", qa="| QA-26 | Offline | D-06 |"
    )
    write_package(root, VALID_PACKAGE, filename="M0-A01.md")
    (root / "README.md").write_text("# Project\n", encoding="utf-8")
    return root


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


class CatalogValidationTests(unittest.TestCase):
    def test_rejects_missing_dependency_and_cycle(self):
        root = make_repository(
            {
                "A-01": package_text("A-01", depends_on=["MISSING-01"]),
                "B-01": package_text("B-01", depends_on=["C-01"]),
                "C-01": package_text("C-01", depends_on=["B-01"]),
            }
        )
        issues = validate_catalog(root, load_packages(root))
        messages = "\n".join(issue.message for issue in issues)
        self.assertIn("MISSING-01", messages)
        self.assertIn("chu trình", messages)

    def test_validates_requirement_and_qa_against_registered_authority(self):
        root = make_registered_repository(
            requirements="| D-06 | Engine |", qa="| QA-26 | Offline |"
        )
        write_package(
            root,
            package_text("M0-A01", requirements=["D-99"], qa=["QA-99"]),
        )
        issues = validate_catalog(root, load_packages(root))
        self.assertEqual(
            {issue.code for issue in issues},
            {"UNKNOWN_REQUIREMENT", "UNKNOWN_QA"},
        )

    def test_link_checker_accepts_anchor_query_and_url_encoding(self):
        root = make_registered_repository(requirements="", qa="")
        target = root / "docs" / "governance" / "file name.md"
        target.write_text("# Heading\n", encoding="utf-8")
        source = root / "docs" / "governance" / "README.md"
        source.write_text(
            "[anchor](file%20name.md#heading) [query](file%20name.md?raw=1) "
            "[web](https://example.com/a#b)",
            encoding="utf-8",
        )
        self.assertEqual(validate_links(root, load_document_register(root)), [])

    def test_trace_returns_definition_qa_and_consuming_package(self):
        root = make_registered_repository(
            requirements="| D-06 | Engine |", qa="| QA-26 | Offline | D-06 |"
        )
        write_package(
            root,
            package_text("M0-A01", requirements=["D-06"], qa=["QA-26"]),
        )
        trace = trace_requirement(root, "D-06", load_packages(root))
        self.assertIn("GDD/README.md", trace)
        self.assertIn("QA-26", trace)
        self.assertIn("M0-A01", trace)


class ReadOnlyCliTests(unittest.TestCase):
    def test_doctor_reports_cache_snapshot_and_obsolete_path(self):
        root = make_valid_repository()
        (root / "GDD/tools/__pycache__").mkdir(parents=True)
        (root / "meowdoku-clone.xml").write_text("repomix", encoding="utf-8")
        (root / "README.md").write_text("ASOL-Game-03 file:///D:/old", encoding="utf-8")
        codes = {issue.code for issue in doctor(root)}
        self.assertTrue({"CACHE_ARTIFACT", "REPOMIX_SNAPSHOT", "OBSOLETE_PATH"} <= codes)

    def test_inspect_prints_scope_dependencies_and_checks(self):
        root = make_valid_repository()
        output = inspect_package(root, "M0-A01")
        self.assertIn("D-06", output)
        self.assertIn("game/**", output)
        self.assertIn("fixture", output)

    def test_main_returns_nonzero_for_invalid_repository(self):
        root = make_valid_repository()
        (root / "meowdoku-clone.xml").write_text("repomix", encoding="utf-8")
        self.assertEqual(main(["doctor"], root=root), 1)


if __name__ == "__main__":
    unittest.main()

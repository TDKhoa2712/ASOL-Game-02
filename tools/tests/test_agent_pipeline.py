from pathlib import Path
from tempfile import TemporaryDirectory
from unittest import mock
import json
import subprocess
import unittest

from tools.agent_pipeline import (
    PipelineError,
    State,
    assert_state_base_is_ancestor,
    changed_paths,
    doctor,
    inspect_package,
    load_document_register,
    load_package,
    load_packages,
    main,
    normalize_repo_path,
    read_state,
    start_package,
    trace_requirement,
    validate_catalog,
    validate_links,
    write_state_atomic,
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


def make_git_repository() -> tuple[Path, str]:
    temporary = TemporaryDirectory()
    _TEMP_DIRECTORIES.append(temporary)
    root = Path(temporary.name)
    subprocess.run(
        ["git", "init", "-b", "main"], cwd=root, check=True, capture_output=True
    )
    subprocess.run(
        ["git", "config", "user.name", "Test User"],
        cwd=root,
        check=True,
        capture_output=True,
    )
    subprocess.run(
        ["git", "config", "user.email", "test@example.com"],
        cwd=root,
        check=True,
        capture_output=True,
    )
    (root / "init.txt").write_text("init", encoding="utf-8")
    subprocess.run(
        ["git", "add", "init.txt"], cwd=root, check=True, capture_output=True
    )
    subprocess.run(
        ["git", "commit", "-m", "initial commit"],
        cwd=root,
        check=True,
        capture_output=True,
    )
    head = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=root,
        text=True,
        check=True,
        capture_output=True,
    ).stdout.strip()
    return root, head


def commit_file(root: Path, relative_path: str, content: str) -> str:
    path = root / relative_path
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    subprocess.run(
        ["git", "add", relative_path], cwd=root, check=True, capture_output=True
    )
    subprocess.run(
        ["git", "commit", "-m", f"add {relative_path}"],
        cwd=root,
        check=True,
        capture_output=True,
    )
    return subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=root,
        text=True,
        check=True,
        capture_output=True,
    ).stdout.strip()


def make_ready_git_repository() -> Path:
    root, _ = make_git_repository()
    governance = root / "docs" / "governance"
    governance.mkdir(parents=True)
    (root / "GDD").mkdir(parents=True)
    (root / "GDD" / "README.md").write_text("| D-06 | Engine |", encoding="utf-8")
    (governance / "qa.md").write_text(
        "| QA-26 | Offline | D-06 |", encoding="utf-8"
    )
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
    (root / "work" / "packages").mkdir(parents=True)
    (root / "work" / "packages" / "M0-A01.md").write_text(
        VALID_PACKAGE, encoding="utf-8"
    )
    subprocess.run(["git", "add", "-A"], cwd=root, check=True, capture_output=True)
    subprocess.run(
        ["git", "commit", "-m", "ready setup"],
        cwd=root,
        check=True,
        capture_output=True,
    )
    return root


def make_state(
    *,
    package_id: str = "M0-A01",
    agent: str = "test-agent",
    status: str = "in_progress",
    branch: str = "work/m0-a01-test",
    base_revision: str = "0" * 40,
    started_at: str = "2026-09-22T00:00:00Z",
    updated_at: str = "2026-09-22T00:00:00Z",
    blocker_reason: str = "",
) -> State:
    return State(
        package_id=package_id,
        agent=agent,
        status=status,
        branch=branch,
        base_revision=base_revision,
        started_at=started_at,
        updated_at=updated_at,
        blocker_reason=blocker_reason,
    )


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


class LifecycleTests(unittest.TestCase):
    def test_state_write_is_atomic_when_replace_fails(self):
        root = make_valid_repository()
        state_path = root / "work/state/M0-A01.toml"
        state_path.parent.mkdir(parents=True, exist_ok=True)
        state_path.write_text('status = "in_progress"\n', encoding="utf-8")
        with mock.patch(
            "tools.agent_pipeline.os.replace", side_effect=OSError("interrupted")
        ):
            with self.assertRaises(OSError):
                write_state_atomic(state_path, make_state(status="review"))
        self.assertEqual(
            state_path.read_text(encoding="utf-8"), 'status = "in_progress"\n'
        )

    def test_changed_paths_includes_committed_modified_and_untracked_space_name(
        self,
    ):
        root, base = make_git_repository()
        commit_file(root, "committed.txt", "one")
        (root / "modified.txt").write_text("changed", encoding="utf-8")
        (root / "new file.txt").write_text("new", encoding="utf-8")
        self.assertEqual(
            changed_paths(root, base),
            {"committed.txt", "modified.txt", "new file.txt"},
        )

    def test_rejects_stale_base_revision(self):
        root, base = make_git_repository()
        state = make_state(status="in_progress", base_revision=base)
        write_state_atomic(root / "work/state/M0-A01.toml", state)
        subprocess.run(
            ["git", "checkout", "--orphan", "diverged"],
            cwd=root,
            check=True,
            capture_output=True,
        )
        commit_file(root, "outside.txt", "new head")
        with self.assertRaisesRegex(PipelineError, "base_revision"):
            assert_state_base_is_ancestor(root, read_state(root, "M0-A01"))

    def test_start_requires_agent_and_creates_state(self):
        root = make_ready_git_repository()
        self.assertEqual(
            main(["start", "M0-A01", "--agent", "agent-x"], root=root), 0
        )
        state = read_state(root, "M0-A01")
        self.assertEqual(state.agent, "agent-x")
        self.assertEqual(state.status, "in_progress")
        self.assertTrue(state.branch.startswith("work/m0-a01-"))


if __name__ == "__main__":
    unittest.main()

> HISTORICAL — Nội dung có thể đã bị GDD v0.5.0 supersede; không dùng làm requirement triển khai.

# Kế hoạch triển khai tái cấu trúc repository và agent pipeline

> **Dành cho agent thực thi:** BẮT BUỘC dùng sub-skill `superpowers:subagent-driven-development` (khuyến nghị) hoặc `superpowers:executing-plans` để thực hiện kế hoạch theo từng task. Mỗi bước dùng checkbox (`- [ ]`) để theo dõi.

**Mục tiêu:** Tái cấu trúc ASOL-Game-03 thành repository ASOL-Game-02 có thẩm quyền tài liệu rõ ràng và pipeline work package cục bộ, zero-dependency, dùng được với mọi coding agent.

**Kiến trúc:** Giữ `GDD/` làm nguồn canonical; chuyển governance, review, báo cáo và lịch sử agent sang các lớp tài liệu riêng. Một CLI Python duy nhất đọc Markdown/TOML, kiểm catalog và document register, quản lý state/handoff, chạy verification và giới hạn Git diff theo package được giao.

**Tech Stack:** Python 3.11+ standard library (`argparse`, `dataclasses`, `tomllib`, `pathlib`, `subprocess`, `unittest`), Markdown, TOML, Git và PowerShell cho bước đổi tên workspace cuối cùng.

**Spec:** `docs/archive/agent-history/superpowers/specs/2026-09-22-repository-restructure-agent-pipeline-design.md`

## Ràng buộc toàn cục

- Giữ nguyên `GDD/` và các đường dẫn canonical bên trong.
- Pipeline không được thêm dependency ngoài Python 3.11+ standard library.
- Work package dùng Markdown với TOML front matter phân cách bằng `+++`.
- Con người giao package ID; không xây chức năng tự claim công việc.
- Không thay luật gameplay, schema, tiến trình, điểm hoặc nội dung phát hành.
- Không tạo `game/` trước package M0 bootstrap Godot.
- Không dùng tài liệu archive làm requirement triển khai.
- Asset, level, tên và nội dung phải là tác phẩm gốc; không sao chép game thương mại.
- Mọi lệnh shell trong kế hoạch phải được chạy với `rtk`; mọi chỉnh sửa file thủ công dùng `apply_patch`.
- Chỉ đổi tên thư mục sang `ASOL-Game-02` sau khi mọi thay đổi, test và commit đã hoàn tất; không ghi đè target đã tồn tại.

## Trọng tâm review

1. Đường dẫn Windows dùng `\`, khác hoa/thường hoặc chứa khoảng trắng phải được chuẩn hóa về POSIX-relative trước khi so `allowed_paths`; Task 1 có test khóa hành vi này.
2. Markdown link có anchor, query hoặc URL-encoded path không được báo hỏng giả; Task 2 có test cho cả ba dạng.
3. Git diff phải thấy file committed, modified và untracked có khoảng trắng; Task 4 có test repository tạm.
4. Nếu ghi evidence/state bị gián đoạn trước `os.replace`, file hợp lệ cũ phải còn nguyên; Task 4 và Task 5 có fault-injection test.
5. State có `base_revision` cũ sau khi branch bị rebase hoặc HEAD đổi ngoài pipeline phải bị từ chối thay vì tiếp tục trên dữ liệu stale; Task 4 có test.

---

## Bản đồ file đích

### Mã pipeline

- `tools/__init__.py`: đánh dấu package Python phục vụ unit test.
- `tools/agent_pipeline.py`: model, parser, validator, Git adapter, lifecycle và CLI.
- `tools/tests/test_agent_pipeline.py`: unit/integration test bằng repository tạm.
- `tools/reports/generate_game_design_report.py`: generator báo cáo được chuyển khỏi GDD tooling.

### Entrypoint và governance

- `README.md`: bản đồ dự án cho con người.
- `AGENTS.md`: luật tối thiểu bắt buộc với mọi agent.
- `CONTRIBUTING.md`: workflow Git/package/review.
- `.gitignore`: cache, output và artifact có thể tái tạo.
- `docs/governance/README.md`: authority order và quy tắc thay đổi.
- `docs/governance/document-register.toml`: catalog tài liệu có thẩm quyền.

### Work contracts

- `work/README.md`: hướng dẫn giao và thực hiện package.
- `work/templates/package.md`: template package Markdown/TOML.
- `work/templates/handoff.md`: template bàn giao.
- `work/packages/SETUP-001.md`: hợp đồng tái cấu trúc hiện tại.
- `work/packages/M0-A01.md`: baseline Godot/toolchain ở trạng thái ready.
- `work/packages/M0-A02.md`, `M0-A03.md`, `M0-GATE.md`: backlog draft.
- `work/state/SETUP-001.toml`: state đã thực thi; hoàn tất ở Task 8.
- `work/handoffs/SETUP-001.md`: bằng chứng và bàn giao Task 8.
- `work/evidence/SETUP-001/verification.txt`: kết quả kiểm chứng cuối.

### Tài liệu được di chuyển

- `design-control/*` → `docs/governance/*`.
- `design-control/reviews/*` → `docs/reviews/*`.
- `design-reviews/*` → `docs/archive/reviews/*`.
- `docs/superpowers/*` → `docs/archive/agent-history/superpowers/*` ở cuối migration.
- `.superpowers/sdd/*` → `docs/archive/agent-history/superpowers-sdd/*`.
- Một báo cáo DOCX → `docs/reports/Bao_Cao_Y_Tuong_Va_Thiet_Ke_Game_Vuon_Meo.docx`.

---

### Task 1: Model package, TOML parser và path normalization

**Files:**
- Create: `tools/__init__.py`
- Create: `tools/agent_pipeline.py`
- Create: `tools/tests/test_agent_pipeline.py`

**Interfaces:**
- Consumes: Markdown UTF-8 có TOML front matter `+++`.
- Produces: `Issue`, `Check`, `Package`; `split_front_matter(text)`, `normalize_repo_path(value)`, `load_package(path)` và `load_packages(root)`.

- [ ] **Step 1: Viết test thất bại cho parser, schema và chuẩn hóa đường dẫn**

```python
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

            path.write_text(VALID_PACKAGE.replace('phase = "M0"\n', ''), encoding="utf-8")
            with self.assertRaisesRegex(PipelineError, "phase"):
                load_package(path)

    def test_normalizes_windows_paths_and_rejects_escape(self):
        self.assertEqual(normalize_repo_path(r"work\\evidence\\M0 A01\\**"), "work/evidence/M0 A01/**")
        for unsafe in ("../outside", "/outside", r"C:\\outside"):
            with self.subTest(unsafe=unsafe):
                with self.assertRaisesRegex(PipelineError, "thoát khỏi repository"):
                    normalize_repo_path(unsafe)
```

- [ ] **Step 2: Chạy test để xác nhận thất bại**

Run: `rtk python -m unittest tools.tests.test_agent_pipeline.PackageParsingTests -v`  
Expected: FAIL vì `tools.agent_pipeline` chưa tồn tại.

- [ ] **Step 3: Tạo model và parser tối thiểu**

```python
from __future__ import annotations

import re
import tomllib
from dataclasses import dataclass
from pathlib import Path, PurePosixPath


class PipelineError(ValueError):
    pass


@dataclass(frozen=True)
class Issue:
    code: str
    path: str
    message: str


@dataclass(frozen=True)
class Check:
    id: str
    command: tuple[str, ...]


@dataclass(frozen=True)
class Package:
    path: Path
    id: str
    title: str
    kind: str
    phase: str
    status: str
    depends_on: tuple[str, ...]
    requirements: tuple[str, ...]
    qa: tuple[str, ...]
    read_first: tuple[str, ...]
    allowed_paths: tuple[str, ...]
    deliverables: tuple[str, ...]
    out_of_scope: tuple[str, ...]
    checks: tuple[Check, ...]
    body: str


REQUIRED_FIELDS = {
    "id", "title", "kind", "phase", "status", "depends_on", "requirements",
    "qa", "read_first", "allowed_paths", "deliverables", "out_of_scope",
}
KINDS = {"implementation", "content", "research", "design-change", "governance"}
CATALOG_STATUSES = {"draft", "ready"}
PACKAGE_ID_RE = re.compile(r"^[A-Z0-9]+(?:-[A-Z0-9]+)+$")


def split_front_matter(text: str) -> tuple[dict, str]:
    normalized = text.replace("\r\n", "\n")
    if not normalized.startswith("+++\n"):
        raise PipelineError("thiếu TOML front matter mở đầu bằng +++")
    marker = normalized.find("\n+++\n", 4)
    if marker < 0:
        raise PipelineError("thiếu dấu +++ kết thúc TOML front matter")
    try:
        metadata = tomllib.loads(normalized[4:marker])
    except tomllib.TOMLDecodeError as exc:
        raise PipelineError(f"TOML không hợp lệ: {exc}") from exc
    return metadata, normalized[marker + 5:]


def normalize_repo_path(value: str) -> str:
    candidate = value.replace("\\", "/").strip()
    if candidate.startswith(("/", "//")) or re.match(r"^[A-Za-z]:/", candidate):
        raise PipelineError(f"đường dẫn thoát khỏi repository: {value!r}")
    candidate = candidate.rstrip("/")
    path = PurePosixPath(candidate)
    if not candidate or path.is_absolute() or ".." in path.parts:
        raise PipelineError(f"đường dẫn thoát khỏi repository: {value!r}")
    return path.as_posix()
```

`load_package` phải kiểm đúng tập field bắt buộc, enum, list string, `checks` là list table với `command` là list string không rỗng; chuẩn hóa `read_first`, `allowed_paths`, `deliverables`; sau đó trả `Package` bất biến. `load_packages(root)` đọc `work/packages/*.md`, từ chối ID trùng và trả `dict[str, Package]` sắp theo ID.

- [ ] **Step 4: Chạy test parser**

Run: `rtk python -m unittest tools.tests.test_agent_pipeline.PackageParsingTests -v`  
Expected: PASS 3 tests.

- [ ] **Step 5: Commit Task 1**

```text
rtk git add tools/__init__.py tools/agent_pipeline.py tools/tests/test_agent_pipeline.py
rtk git commit -m "feat: add work package parser"
```

### Task 2: Catalog, dependency graph, document register, link và trace validation

**Files:**
- Modify: `tools/agent_pipeline.py`
- Modify: `tools/tests/test_agent_pipeline.py`

**Interfaces:**
- Consumes: `dict[str, Package]`, `docs/governance/document-register.toml` và Markdown được đăng ký.
- Produces: `load_document_register(root)`, `validate_catalog(root, packages)`, `validate_links(root, documents)`, `trace_requirement(root, requirement_id, packages)`.

- [ ] **Step 1: Thêm test dependency, ID authority, link edge cases và trace**

```python
class CatalogValidationTests(unittest.TestCase):
    def test_rejects_missing_dependency_and_cycle(self):
        root = make_repository({
            "A-01": package_text("A-01", depends_on=["MISSING-01"]),
            "B-01": package_text("B-01", depends_on=["C-01"]),
            "C-01": package_text("C-01", depends_on=["B-01"]),
        })
        issues = validate_catalog(root, load_packages(root))
        messages = "\n".join(issue.message for issue in issues)
        self.assertIn("MISSING-01", messages)
        self.assertIn("chu trình", messages)

    def test_validates_requirement_and_qa_against_registered_authority(self):
        root = make_registered_repository(requirements="| D-06 | Engine |", qa="| QA-26 | Offline |")
        write_package(root, package_text("M0-A01", requirements=["D-99"], qa=["QA-99"]))
        issues = validate_catalog(root, load_packages(root))
        self.assertEqual({issue.code for issue in issues}, {"UNKNOWN_REQUIREMENT", "UNKNOWN_QA"})

    def test_link_checker_accepts_anchor_query_and_url_encoding(self):
        root = make_registered_repository(requirements="", qa="")
        target = root / "docs" / "governance" / "file name.md"
        target.write_text("# Heading\n", encoding="utf-8")
        source = root / "docs" / "governance" / "README.md"
        source.write_text(
            "[anchor](file%20name.md#heading) [query](file%20name.md?raw=1) "
            "[web](https://example.com/a#b)", encoding="utf-8"
        )
        self.assertEqual(validate_links(root, load_document_register(root)), [])

    def test_trace_returns_definition_qa_and_consuming_package(self):
        root = make_registered_repository(requirements="| D-06 | Engine |", qa="| QA-26 | Offline | D-06 |")
        write_package(root, package_text("M0-A01", requirements=["D-06"], qa=["QA-26"]))
        trace = trace_requirement(root, "D-06", load_packages(root))
        self.assertIn("GDD/README.md", trace)
        self.assertIn("QA-26", trace)
        self.assertIn("M0-A01", trace)
```

Helper test `make_repository`, `package_text`, `make_registered_repository` và `write_package` phải tạo cây tối thiểu trong `TemporaryDirectory`, dùng `Path.write_text(..., encoding="utf-8")`, không phụ thuộc repository thật.

- [ ] **Step 2: Chạy test để xác nhận thất bại**

Run: `rtk python -m unittest tools.tests.test_agent_pipeline.CatalogValidationTests -v`  
Expected: FAIL vì các hàm catalog chưa tồn tại.

- [ ] **Step 3: Triển khai document register và validator**

```python
@dataclass(frozen=True)
class Document:
    path: str
    document_class: str
    status: str
    owner: str
    superseded_by: str | None = None


ACTIVE_DOCUMENT_STATUSES = {"CANONICAL", "ACTIVE", "PROPOSED"}
REQUIREMENT_RE = re.compile(r"\b(?:D|GR|UX|LV|TECH|ART|DEC)-\d{2}\b")
QA_RE = re.compile(r"\bQA-\d{2}\b")


def load_document_register(root: Path) -> tuple[Document, ...]:
    path = root / "docs/governance/document-register.toml"
    data = tomllib.loads(path.read_text(encoding="utf-8"))
    documents = []
    for item in data.get("documents", []):
        documents.append(Document(
            path=normalize_repo_path(item["path"]),
            document_class=item["class"],
            status=item["status"],
            owner=item["owner"],
            superseded_by=item.get("superseded_by"),
        ))
    return tuple(documents)
```

`validate_catalog` phải: kiểm dependency tồn tại; DFS ba màu để phát hiện cycle và in chuỗi cycle; thu ID từ tài liệu `CANONICAL/ACTIVE`; kiểm `read_first` tồn tại; kiểm requirement/QA; từ chối `PROPOSED/POST-MVP` khi phase không phải `POST-MVP`. `validate_links` bỏ qua `http`, `https`, `mailto`, anchor thuần; dùng `urllib.parse.unquote/urlsplit`, resolve relative với thư mục file nguồn và kiểm file tồn tại. `trace_requirement` trả chuỗi ổn định gồm definition, QA có chứa ID và package sử dụng ID.

- [ ] **Step 4: Chạy test catalog**

Run: `rtk python -m unittest tools.tests.test_agent_pipeline.CatalogValidationTests -v`  
Expected: PASS 4 tests.

- [ ] **Step 5: Commit Task 2**

```text
rtk git add tools/agent_pipeline.py tools/tests/test_agent_pipeline.py
rtk git commit -m "feat: validate package catalog and document authority"
```

### Task 3: Read-only CLI — validate, doctor, list, trace và inspect

**Files:**
- Modify: `tools/agent_pipeline.py`
- Modify: `tools/tests/test_agent_pipeline.py`

**Interfaces:**
- Consumes: parser và validator Task 1–2.
- Produces: `doctor(root) -> list[Issue]`, `inspect_package(root, id) -> str`, `main(argv=None, root=None) -> int`.

- [ ] **Step 1: Viết test CLI và prohibited artifacts**

```python
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
```

- [ ] **Step 2: Chạy test để xác nhận thất bại**

Run: `rtk python -m unittest tools.tests.test_agent_pipeline.ReadOnlyCliTests -v`  
Expected: FAIL vì CLI chưa tồn tại.

- [ ] **Step 3: Triển khai CLI read-only**

```python
def repository_root() -> Path:
    return Path(__file__).resolve().parents[1]


def doctor(root: Path) -> list[Issue]:
    packages = load_packages(root)
    issues = validate_catalog(root, packages)
    documents = load_document_register(root)
    issues.extend(validate_links(root, documents))
    for path in root.rglob("*"):
        relative = path.relative_to(root).as_posix()
        if "__pycache__" in path.parts or path.suffix == ".pyc":
            issues.append(Issue("CACHE_ARTIFACT", relative, "Python cache không được nằm trong repository"))
        if path.name == "meowdoku-clone.xml":
            issues.append(Issue("REPOMIX_SNAPSHOT", relative, "Repomix snapshot phải được tái tạo ngoài repository"))
    return sorted(issues, key=lambda issue: (issue.path, issue.code, issue.message))


def main(argv: list[str] | None = None, root: Path | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    root = (root or repository_root()).resolve()
    try:
        return dispatch(args, root)
    except PipelineError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2
```

`build_parser` tạo đúng năm subcommand read-only. `dispatch` in issue dạng `CODE path: message`, trả 1 khi có issue, 0 khi hợp lệ. `list` dùng effective status nếu có state, nếu chưa có dùng package catalog status. `inspect` in authority/read list trước scope và checks.

- [ ] **Step 4: Chạy toàn bộ test CLI read-only**

Run: `rtk python -m unittest tools.tests.test_agent_pipeline.ReadOnlyCliTests -v`  
Expected: PASS 3 tests.

- [ ] **Step 5: Commit Task 3**

```text
rtk git add tools/agent_pipeline.py tools/tests/test_agent_pipeline.py
rtk git commit -m "feat: add repository doctor and inspection commands"
```

### Task 4: Git-aware lifecycle — start, state và stale protection

**Files:**
- Modify: `tools/agent_pipeline.py`
- Modify: `tools/tests/test_agent_pipeline.py`

**Interfaces:**
- Consumes: `Package`, repository root và Git executable.
- Produces: `State`, `read_state`, `write_state_atomic`, `effective_status`, `git`, `changed_paths`, `start_package`, `transition_state`.

- [ ] **Step 1: Viết test lifecycle, atomic state và Git path coverage**

```python
class LifecycleTests(unittest.TestCase):
    def test_state_write_is_atomic_when_replace_fails(self):
        root = make_valid_repository()
        state_path = root / "work/state/M0-A01.toml"
        state_path.parent.mkdir(parents=True, exist_ok=True)
        state_path.write_text('status = "in_progress"\n', encoding="utf-8")
        with mock.patch("tools.agent_pipeline.os.replace", side_effect=OSError("interrupted")):
            with self.assertRaises(OSError):
                write_state_atomic(state_path, make_state(status="review"))
        self.assertEqual(state_path.read_text(encoding="utf-8"), 'status = "in_progress"\n')

    def test_changed_paths_includes_committed_modified_and_untracked_space_name(self):
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
        commit_file(root, "outside.txt", "new head")
        with self.assertRaisesRegex(PipelineError, "base_revision"):
            assert_state_base_is_ancestor(root, read_state(root, "M0-A01"))
```

`make_git_repository` dùng `git init -b main`, cấu hình identity cục bộ, tạo baseline và luôn truyền `-c safe.directory=<root>` trong helper test.
`make_state` trả một `State` đầy đủ với package `M0-A01`, agent `test-agent`, branch `work/m0-a01-test`, timestamp UTC cố định và cho phép override `status`/`base_revision` để test không phụ thuộc đồng hồ.

- [ ] **Step 2: Chạy test để xác nhận thất bại**

Run: `rtk python -m unittest tools.tests.test_agent_pipeline.LifecycleTests -v`  
Expected: FAIL vì lifecycle API chưa tồn tại.

- [ ] **Step 3: Triển khai state và Git adapter**

```python
@dataclass(frozen=True)
class State:
    package_id: str
    agent: str
    status: str
    branch: str
    base_revision: str
    started_at: str
    updated_at: str
    blocker_reason: str = ""


TRANSITIONS = {
    "in_progress": {"blocked", "review"},
    "blocked": {"in_progress"},
    "review": {"in_progress", "done"},
    "done": set(),
}


def git(root: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    command = ["git", "-c", f"safe.directory={root.resolve().as_posix()}", *args]
    return subprocess.run(command, cwd=root, text=True, capture_output=True, check=check)


def write_state_atomic(path: Path, state: State) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(serialize_state(state), encoding="utf-8", newline="\n")
    os.replace(temporary, path)
```

`start_package` phải kiểm package `ready`, dependency effective status là `done`, working tree sạch, current branch là `main`, tạo branch `work/<lowercase-id>-<slugified-title>`, ghi HEAD làm `base_revision`, rồi atomic-write state `in_progress`. `changed_paths` hợp nhất `git diff --name-only <base>`, `git diff --name-only --cached` và untracked từ `git status --porcelain=v1 -z`; chuẩn hóa separator nhưng giữ khoảng trắng. `assert_state_base_is_ancestor` gọi `git merge-base --is-ancestor` và từ chối state stale.

- [ ] **Step 4: Chạy test lifecycle**

Run: `rtk python -m unittest tools.tests.test_agent_pipeline.LifecycleTests -v`  
Expected: PASS 3 tests.

- [ ] **Step 5: Thêm `start` vào argparse và test dispatch**

```python
def test_start_requires_agent_and_creates_state(self):
    root = make_ready_git_repository()
    self.assertEqual(main(["start", "M0-A01", "--agent", "agent-x"], root=root), 0)
    state = read_state(root, "M0-A01")
    self.assertEqual(state.agent, "agent-x")
    self.assertEqual(state.status, "in_progress")
    self.assertTrue(state.branch.startswith("work/m0-a01-"))
```

Run: `rtk python -m unittest tools.tests.test_agent_pipeline.LifecycleTests -v`  
Expected: PASS 4 tests.

- [ ] **Step 6: Commit Task 4**

```text
rtk git add tools/agent_pipeline.py tools/tests/test_agent_pipeline.py
rtk git commit -m "feat: add git-aware package lifecycle"
```

### Task 5: Verify, scope guard, evidence, handoff và accept

**Files:**
- Modify: `tools/agent_pipeline.py`
- Modify: `tools/tests/test_agent_pipeline.py`

**Interfaces:**
- Consumes: Package checks, State, `changed_paths` và handoff template.
- Produces: `path_allowed`, `verify_package`, `validate_handoff`, `handoff_package`, `accept_package`.

- [ ] **Step 1: Viết test scope, verification atomicity và handoff**

```python
class VerificationTests(unittest.TestCase):
    def test_scope_matches_normalized_glob_and_rejects_protected_path(self):
        package = package_object(allowed_paths=("game/**", "work/evidence/M0-A01/**"))
        self.assertTrue(path_allowed("game/scenes/main.tscn", package))
        self.assertFalse(path_allowed("GDD/02-luat-choi-va-trang-thai.md", package))

    def test_failed_check_does_not_replace_previous_evidence(self):
        root = make_started_repository(check_command=(sys.executable, "-c", "raise SystemExit(7)"))
        evidence = root / "work/evidence/M0-A01/verification.txt"
        evidence.parent.mkdir(parents=True, exist_ok=True)
        evidence.write_text("previous valid evidence", encoding="utf-8")
        with self.assertRaisesRegex(PipelineError, "exit 7"):
            verify_package(root, "M0-A01")
        self.assertEqual(evidence.read_text(encoding="utf-8"), "previous valid evidence")

    def test_handoff_skeleton_does_not_advance_state(self):
        root = make_started_repository()
        with self.assertRaisesRegex(PipelineError, "điền handoff"):
            handoff_package(root, "M0-A01")
        self.assertEqual(read_state(root, "M0-A01").status, "in_progress")
        self.assertTrue((root / "work/handoffs/M0-A01.md").exists())

    def test_accept_requires_review_state_and_complete_handoff(self):
        root = make_review_repository()
        accept_package(root, "M0-A01")
        self.assertEqual(read_state(root, "M0-A01").status, "done")
```

- [ ] **Step 2: Chạy test để xác nhận thất bại**

Run: `rtk python -m unittest tools.tests.test_agent_pipeline.VerificationTests -v`  
Expected: FAIL vì verification API chưa tồn tại.

- [ ] **Step 3: Triển khai scope và verification**

```python
PROTECTED_PREFIXES = ("GDD/", "docs/governance/", "AGENTS.md", "tools/agent_pipeline.py")


def path_allowed(path: str, package: Package) -> bool:
    normalized = normalize_repo_path(path)
    if package.kind == "implementation" and normalized.startswith(PROTECTED_PREFIXES):
        return False
    return any(fnmatch.fnmatchcase(normalized, pattern) for pattern in package.allowed_paths)


def run_check(root: Path, check: Check) -> tuple[int, str]:
    completed = subprocess.run(check.command, cwd=root, text=True, capture_output=True)
    output = completed.stdout + completed.stderr
    return completed.returncode, output
```

`verify_package` phải: đọc state `in_progress`; kiểm base ancestor; từ chối mọi changed path ngoài scope; chạy checks tuần tự; xây evidence có timestamp UTC, command JSON, exit code và output; chỉ `os.replace` evidence khi tất cả checks đạt. Không ghi environment. `validate_handoff` yêu cầu đúng các heading: Package, Requirements, QA, Changed files, Validation, Evidence, Remaining risks, Reviewer.

- [ ] **Step 4: Thêm CLI `verify`, `handoff`, `accept` và chạy test**

`handoff` tạo file từ `work/templates/handoff.md` nếu thiếu rồi trả code 2; nếu đầy đủ và evidence tồn tại thì chuyển state `review`. `accept` lấy reviewer từ `git config user.name`, yêu cầu state `review`, handoff hợp lệ và working tree không có thay đổi ngoài work state/handoff/evidence, sau đó chuyển `done`.

Run: `rtk python -m unittest tools.tests.test_agent_pipeline.VerificationTests -v`  
Expected: PASS 4 tests.

- [ ] **Step 5: Chạy toàn bộ pipeline unit test**

Run: `rtk python -m unittest discover tools/tests -p "test_*.py" -v`  
Expected: PASS toàn bộ test Task 1–5.

- [ ] **Step 6: Commit Task 5**

```text
rtk git add tools/agent_pipeline.py tools/tests/test_agent_pipeline.py
rtk git commit -m "feat: verify scoped work and handoffs"
```

### Task 6: Entrypoint, governance, templates và initial packages

**Files:**
- Create: `.gitignore`
- Create: `CONTRIBUTING.md`
- Modify: `README.md`
- Modify: `AGENTS.md`
- Create: `docs/governance/README.md`
- Create: `docs/governance/document-register.toml`
- Create: `work/README.md`
- Create: `work/templates/package.md`
- Create: `work/templates/handoff.md`
- Create: `work/packages/SETUP-001.md`
- Create: `work/packages/M0-A01.md`
- Create: `work/packages/M0-A02.md`
- Create: `work/packages/M0-A03.md`
- Create: `work/packages/M0-GATE.md`
- Create: `work/state/SETUP-001.toml`
- Test: `tools/tests/test_agent_pipeline.py`

**Interfaces:**
- Consumes: schema và CLI Task 1–5, GDD/08 package A/M0.
- Produces: repository contract mà `doctor`, `inspect` và agent tương lai sử dụng.

- [ ] **Step 1: Viết integration test cho seed repository contract**

```python
class RepositoryContractTests(unittest.TestCase):
    def test_seed_packages_and_entrypoints_exist(self):
        root = Path(__file__).resolve().parents[2]
        for relative in (
            "README.md", "AGENTS.md", "CONTRIBUTING.md", ".gitignore",
            "docs/governance/README.md", "docs/governance/document-register.toml",
            "work/README.md", "work/templates/package.md", "work/templates/handoff.md",
            "work/packages/SETUP-001.md", "work/packages/M0-A01.md",
            "work/packages/M0-A02.md", "work/packages/M0-A03.md", "work/packages/M0-GATE.md",
        ):
            self.assertTrue((root / relative).exists(), relative)

        packages = load_packages(root)
        self.assertEqual(packages["M0-A01"].status, "ready")
        self.assertEqual(packages["M0-A02"].status, "draft")
        self.assertEqual(packages["M0-GATE"].depends_on, ("M0-A02", "M0-A03"))
```

- [ ] **Step 2: Chạy test để xác nhận thất bại**

Run: `rtk python -m unittest tools.tests.test_agent_pipeline.RepositoryContractTests -v`  
Expected: FAIL vì entrypoint/work files chưa tồn tại.

- [ ] **Step 3: Viết entrypoint và governance docs**

`AGENTS.md` phải chứa đúng các phần: Authority, Assigned package only, Required commands, Protected changes, Original content, Handoff. `README.md` phải nêu chưa có game chạy được và trỏ tới GDD, governance, work packages. `CONTRIBUTING.md` phải có branch `work/<id>-<slug>` và quyền chuyển trạng thái.

`document-register.toml` dùng array of tables:

```toml
[[documents]]
path = "GDD/02-luat-choi-va-trang-thai.md"
class = "canonical"
status = "CANONICAL"
owner = "Game Design"

[[documents]]
path = "GDD/12-sinh-level-do-kho-va-endless.md"
class = "canonical-proposal"
status = "PROPOSED"
owner = "Puzzle Design"
```

Ở Task 6, đăng ký GDD 01–12, GDD README và `docs/governance/README.md`. Task 7 bổ sung các governance/review đã di chuyển sau khi target thực sự tồn tại. Không đăng ký archive làm nguồn requirement.

- [ ] **Step 4: Viết template và package seed bằng TOML front matter hợp lệ**

Metadata seed phải dùng chính xác bảng sau; phần body của từng package mở rộng acceptance/deliverables thành checklist nhưng không thêm scope ngoài bảng:

| ID | kind/status | depends_on | requirements | qa | allowed_paths chính |
| --- | --- | --- | --- | --- | --- |
| `SETUP-001` | `governance/ready` | `[]` | `[]` | `[]` | `.gitignore`, `README.md`, `AGENTS.md`, `CONTRIBUTING.md`, `GDD/**`, `docs/**`, `work/**`, `tools/**` |
| `M0-A01` | `implementation/ready` | `[]` | `D-06`, `TECH-13`, `TECH-19` | `QA-26`, `QA-30` | `game/**`, `work/evidence/M0-A01/**`, `work/handoffs/M0-A01.md` |
| `M0-A02` | `implementation/draft` | `M0-A01` | `GR-09`–`GR-14`, `GR-29`–`GR-33`, `TECH-03`, `TECH-14` (khai báo từng ID, không dùng range string) | `QA-08`, `QA-09`, `QA-12`, `QA-43`, `QA-44`, `QA-45`, `QA-54`, `QA-55` | `game/**`, `work/evidence/M0-A02/**`, `work/handoffs/M0-A02.md` |
| `M0-A03` | `research/draft` | `M0-A01` | `TECH-19`, `TECH-21`, `ART-01`–`ART-13` (khai báo từng ID thực sự tồn tại) | `QA-27`, `QA-30`, `QA-50` | `game/**`, `assets/**`, `work/evidence/M0-A03/**`, `work/handoffs/M0-A03.md` |
| `M0-GATE` | `governance/draft` | `M0-A02`, `M0-A03` | `D-06`, `TECH-13`, `TECH-14`, `TECH-19`, `TECH-21` | `QA-12`, `QA-26`, `QA-27`, `QA-30`, `QA-43`, `QA-44`, `QA-45`, `QA-50`, `QA-54`, `QA-55`, `QA-56` | `docs/governance/**`, `work/evidence/M0-GATE/**`, `work/handoffs/M0-GATE.md` |

Mỗi package có ít nhất một `[[checks]]`. `SETUP-001` chạy GDD validator, GDD unittest, pipeline unittest và `doctor`; các package M0 draft khai lệnh test dự kiến nhưng `start` không cho chạy trước khi được coordinator chuyển sang `ready`.

- [ ] **Step 5: Chạy integration test**

Run: `rtk python -m unittest tools.tests.test_agent_pipeline.RepositoryContractTests -v`  
Expected: PASS.

- [ ] **Step 6: Commit Task 6**

```text
rtk git add .gitignore README.md AGENTS.md CONTRIBUTING.md docs/governance work tools/tests/test_agent_pipeline.py
rtk git commit -m "docs: establish repository and work package contracts"
```

### Task 7: Migration tài liệu, artifact cleanup và link repair

**Files:**
- Move: `design-control/*` → `docs/governance/*`
- Move: `design-control/reviews/*` → `docs/reviews/*`
- Move: `design-reviews/*` → `docs/archive/reviews/*`
- Move: `.superpowers/sdd/*` → `docs/archive/agent-history/superpowers-sdd/*`
- Move: các spec/plan cũ và hiện tại trong `docs/superpowers/*` → `docs/archive/agent-history/superpowers/*`
- Move: `GDD/tools/generate_game_design_report.py` → `tools/reports/generate_game_design_report.py`
- Move: `docs/Bao_Cao_Y_Tuong_Va_Thiet_Ke_Game_Vuon_Meo.docx` → `docs/reports/Bao_Cao_Y_Tuong_Va_Thiet_Ke_Game_Vuon_Meo.docx`
- Delete: root duplicate DOCX, `meowdoku-clone.xml`, `GDD/tools/__pycache__/`
- Modify: links in `AGENTS.md`, `GDD/09-ra-soat-thiet-ke.md`, `GDD/10-nghien-cuu-quy-tac-suy-luan.md`, moved governance/review docs và archived agent history.
- Modify: `tools/reports/generate_game_design_report.py`
- Test: `tools/tests/test_agent_pipeline.py`

**Interfaces:**
- Consumes: authority structure và `doctor` Task 1–6.
- Produces: target tree sạch, link active hợp lệ, historical docs có banner.

- [ ] **Step 1: Thêm integration test yêu cầu repository thật sạch**

```python
def test_real_repository_passes_doctor(self):
    root = Path(__file__).resolve().parents[2]
    issues = doctor(root)
    self.assertEqual(issues, [], "\n".join(f"{i.code} {i.path}: {i.message}" for i in issues))
```

Run: `rtk python -m unittest tools.tests.test_agent_pipeline.RepositoryContractTests.test_real_repository_passes_doctor -v`  
Expected: FAIL với artifact/link/path hiện tại.

- [ ] **Step 2: Tạo thư mục đích và di chuyển file bằng Git-aware moves**

Thực hiện từng `git mv` với source/target cụ thể; không dùng wildcard xóa. Trước mỗi move, xác nhận target chưa tồn tại. Giữ `docs/governance/README.md` mới và hợp nhất tên file cũ `00-design-status.md`…`06-design-freeze-checklist.md` cùng thư mục, không ghi đè.

```text
rtk powershell -NoProfile -Command "New-Item -ItemType Directory -Force 'docs/reviews','docs/archive/reviews','docs/archive/agent-history/superpowers/specs','docs/archive/agent-history/superpowers/plans','docs/archive/agent-history/superpowers-sdd','docs/reports','tools/reports' | Out-Null"
rtk git mv design-control/00-design-status.md docs/governance/00-design-status.md
rtk git mv design-control/01-open-questions.md docs/governance/01-open-questions.md
rtk git mv design-control/02-decision-log.md docs/governance/02-decision-log.md
rtk git mv design-control/03-risk-register.md docs/governance/03-risk-register.md
rtk git mv design-control/04-assumptions.md docs/governance/04-assumptions.md
rtk git mv design-control/05-research-backlog.md docs/governance/05-research-backlog.md
rtk git mv design-control/06-design-freeze-checklist.md docs/governance/06-design-freeze-checklist.md
rtk git mv design-control/reviews/01-mvp-game-design-review.md docs/reviews/01-mvp-game-design-review.md
rtk git mv design-reviews/README.md docs/archive/reviews/README.md
rtk git mv design-reviews/01-danh-gia-va-kien-nghi-thiet-ke-kien-truc.md docs/archive/reviews/01-danh-gia-va-kien-nghi-thiet-ke-kien-truc.md
rtk git mv design-reviews/02-danh-gia-ban-thiet-ke-v04.md docs/archive/reviews/02-danh-gia-ban-thiet-ke-v04.md
```

Di chuyển hai historical review và README vào `docs/archive/reviews/`; thêm banner đầu file: `> HISTORICAL — Nội dung có thể đã bị GDD v0.5.0 supersede; không dùng làm requirement triển khai.`

- [ ] **Step 3: Chuyển agent history và báo cáo**

Tạo các thư mục đích rõ ràng rồi chuyển từng file đã biết; không dùng wildcard:

```text
rtk git mv docs/superpowers/specs/2026-09-21-mvp-game-design-resolution-design.md docs/archive/agent-history/superpowers/specs/2026-09-21-mvp-game-design-resolution-design.md
rtk git mv docs/superpowers/specs/2026-09-22-repository-restructure-agent-pipeline-design.md docs/archive/agent-history/superpowers/specs/2026-09-22-repository-restructure-agent-pipeline-design.md
rtk git mv docs/superpowers/plans/2026-09-21-controlled-level-generator.md docs/archive/agent-history/superpowers/plans/2026-09-21-controlled-level-generator.md
rtk git mv docs/superpowers/plans/2026-09-21-mvp-game-design-resolution.md docs/archive/agent-history/superpowers/plans/2026-09-21-mvp-game-design-resolution.md
rtk git mv docs/superpowers/plans/2026-09-22-repository-restructure-agent-pipeline.md docs/archive/agent-history/superpowers/plans/2026-09-22-repository-restructure-agent-pipeline.md
rtk git mv .superpowers/sdd/2026-09-21-mvp-game-design-resolution/progress.md docs/archive/agent-history/superpowers-sdd/2026-09-21-mvp-game-design-resolution-progress.md
rtk git mv GDD/tools/generate_game_design_report.py tools/reports/generate_game_design_report.py
rtk git mv docs/Bao_Cao_Y_Tuong_Va_Thiet_Ke_Game_Vuon_Meo.docx docs/reports/Bao_Cao_Y_Tuong_Va_Thiet_Ke_Game_Vuon_Meo.docx
```

Thêm banner `HISTORICAL` vào mọi Markdown dưới `docs/archive/agent-history/`. Sau move, cập nhật dòng `Spec:` của plan này sang đường dẫn archive mới.

Trong generator, thay default output hard-coded bằng:

```python
from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUTPUT = REPOSITORY_ROOT / "docs/reports/Bao_Cao_Y_Tuong_Va_Thiet_Ke_Game_Vuon_Meo.docx"

target_file = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else DEFAULT_OUTPUT
build_game_design_document(target_file)
```

- [ ] **Step 4: Xóa đúng artifact đã có baseline Git**

```text
rtk git rm Bao_Cao_Y_Tuong_Va_Thiet_Ke_Game_Vuon_Meo.docx
rtk git rm meowdoku-clone.xml
```

Xóa `GDD/tools/__pycache__` khỏi working tree nếu còn tồn tại; `.gitignore` ngăn tái sinh vào Git.

- [ ] **Step 5: Sửa link active và banner archive**

Các mapping bắt buộc:

```text
../design-control/            → ../docs/governance/       (từ GDD/)
../design-reviews/            → ../docs/archive/reviews/  (từ GDD/)
../design-control/reviews/    → ../docs/reviews/          (từ GDD/)
../GDD/                       → ../../GDD/                 (từ docs/governance/)
../design-reviews/            → ../archive/reviews/       (từ docs/governance/)
```

Không sửa trích dẫn lịch sử thành luật mới. Xóa `file:///...`, `Game-test`, `ASOL-Game-03` khỏi tài liệu active; archive có thể giữ văn bản trích dẫn cũ nhưng banner phải chỉ rõ không có thẩm quyền.

- [ ] **Step 6: Chạy doctor và test migration**

Run: `rtk python -m unittest tools.tests.test_agent_pipeline.RepositoryContractTests.test_real_repository_passes_doctor -v`  
Expected: PASS.

Run: `rtk python tools/agent_pipeline.py doctor`  
Expected: exit 0, in `OK: repository contract is valid`.

- [ ] **Step 7: Commit Task 7**

```text
rtk git add -A
rtk git commit -m "refactor: organize design governance and project history"
```

### Task 8: End-to-end verification, SETUP-001 handoff và restructure commit

**Files:**
- Modify: `work/state/SETUP-001.toml`
- Create: `work/evidence/SETUP-001/verification.txt`
- Create: `work/handoffs/SETUP-001.md`
- Modify: archived copy of this plan only to check completed boxes if execution policy requires it.

**Interfaces:**
- Consumes: toàn bộ repository contract và pipeline Task 1–7.
- Produces: verified handoff, state `review` rồi `done`, commit tái cấu trúc cuối.

- [ ] **Step 1: Chạy validator fixture**

Run: `rtk python GDD/tools/validate_levels.py GDD/data/levels.sample.json`  
Expected: 5 level hợp lệ, 0 duplicate geometry warning.

- [ ] **Step 2: Chạy 23 test GDD hiện có**

Run: `rtk python -m unittest discover GDD/tools -p "test_*.py" -v`  
Expected: 23 tests, OK.

- [ ] **Step 3: Chạy toàn bộ pipeline tests**

Run: `rtk python -m unittest discover tools/tests -p "test_*.py" -v`  
Expected: tất cả test Task 1–7, OK.

- [ ] **Step 4: Kiểm CLI public**

```text
rtk python tools/agent_pipeline.py doctor
rtk python tools/agent_pipeline.py inspect SETUP-001
rtk python tools/agent_pipeline.py inspect M0-A01
rtk python tools/agent_pipeline.py trace GR-16
rtk python tools/agent_pipeline.py list --status ready
```

Expected: mọi lệnh exit 0; M0-A01 xuất hiện trong list ready; trace hiển thị GR-16 và QA/package liên quan.

- [ ] **Step 5: Ghi evidence và handoff SETUP-001**

Ghi `verification.txt` bằng chính output Step 1–4, không ghi environment. Handoff phải liệt kê requirement governance của spec, toàn bộ file đổi, kết quả validation, bằng chứng, giới hạn “chưa tạo game”, và rủi ro còn lại về M0/device evidence.

- [ ] **Step 6: Chuyển SETUP-001 qua review và done**

Run: `rtk python tools/agent_pipeline.py handoff SETUP-001`  
Expected: state `review` vì handoff đã đầy đủ.

Run: `rtk python tools/agent_pipeline.py accept SETUP-001`  
Expected: state `done`, reviewer lấy từ Git user.name.

- [ ] **Step 7: Kiểm diff và commit tái cấu trúc**

Run: `rtk git diff --check`  
Expected: không có output lỗi.

Run: `rtk git status --short`  
Expected: chỉ các file evidence/state/handoff cuối chưa commit.

```text
rtk git add -A
rtk git commit -m "chore: complete repository restructure and agent pipeline"
```

- [ ] **Step 8: Chạy lại verification sau commit**

Chạy lại toàn bộ lệnh Step 1–4. Expected: cùng kết quả PASS và `git status --short` sạch, ngoại trừ `.codegraph/` đã ignore.

### Task 9: Đổi tên workspace thành ASOL-Game-02

**Files:**
- Move directory: `D:\Work\Alpaca_Solution\ASOL-Game-03` → `D:\Work\Alpaca_Solution\ASOL-Game-02`

**Interfaces:**
- Consumes: repository đã commit và clean từ Task 8.
- Produces: workspace ở đường dẫn cuối; không thực hiện thêm chỉnh sửa trong phiên cũ.

- [ ] **Step 1: Xác minh source/target tuyệt đối và working tree sạch**

Run: `rtk git status --short`  
Expected: không có output.

PowerShell preflight:

```powershell
$source = (Resolve-Path -LiteralPath 'D:\Work\Alpaca_Solution\ASOL-Game-03').Path
$target = 'D:\Work\Alpaca_Solution\ASOL-Game-02'
if ($source -ne 'D:\Work\Alpaca_Solution\ASOL-Game-03') { throw 'Unexpected source path' }
if (Test-Path -LiteralPath $target) { throw 'Target ASOL-Game-02 already exists' }
```

- [ ] **Step 2: Đổi tên bằng một PowerShell process từ thư mục cha**

```powershell
Move-Item -LiteralPath 'D:\Work\Alpaca_Solution\ASOL-Game-03' `
          -Destination 'D:\Work\Alpaca_Solution\ASOL-Game-02'
```

Lệnh cần approval ngoài sandbox vì target là sibling của writable root hiện tại. Không dùng `cmd`, glob, biến chưa resolve hoặc recursive copy/delete.

- [ ] **Step 3: Kiểm read-only từ đường dẫn mới**

```text
rtk git -C D:/Work/Alpaca_Solution/ASOL-Game-02 -c safe.directory=D:/Work/Alpaca_Solution/ASOL-Game-02 status --short
```

Expected: repository sạch.

Nếu phiên triển khai trước đó đã thêm exact global `safe.directory` cho đường dẫn cũ để sandbox hoạt động, cập nhật chính xác hai entry, không dùng wildcard:

```text
rtk git config --global --unset-all safe.directory D:/Work/Alpaca_Solution/ASOL-Game-03
rtk git config --global --add safe.directory D:/Work/Alpaca_Solution/ASOL-Game-02
```

- [ ] **Step 4: Kết thúc phiên workspace cũ**

Không ghi thêm file hay commit sau bước rename. Báo người dùng mở lại project tại `D:\Work\Alpaca_Solution\ASOL-Game-02`; mọi công việc tiếp theo bắt đầu từ workspace mới và package `M0-A01`.

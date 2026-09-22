from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import tomllib
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath
from typing import Any
from urllib.parse import unquote, urlsplit


class PipelineError(ValueError):
    """Raised when repository pipeline metadata is invalid."""


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


@dataclass(frozen=True)
class Document:
    path: str
    document_class: str
    status: str
    owner: str
    superseded_by: str | None = None


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


REQUIRED_FIELDS = {
    "id",
    "title",
    "kind",
    "phase",
    "status",
    "depends_on",
    "requirements",
    "qa",
    "read_first",
    "allowed_paths",
    "deliverables",
    "out_of_scope",
}
KINDS = {"implementation", "content", "research", "design-change", "governance"}
CATALOG_STATUSES = {"draft", "ready"}
PACKAGE_ID_RE = re.compile(r"^[A-Z0-9]+(?:-[A-Z0-9]+)+$")
ACTIVE_DOCUMENT_STATUSES = {"CANONICAL", "ACTIVE", "PROPOSED"}
REQUIREMENT_RE = re.compile(r"\b(?:D|GR|UX|LV|TECH|ART|DEC)-\d{2}\b")
QA_RE = re.compile(r"\bQA-\d{2}\b")
MARKDOWN_LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")


def split_front_matter(text: str) -> tuple[dict[str, Any], str]:
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
    return metadata, normalized[marker + 5 :]


def normalize_repo_path(value: str) -> str:
    if not isinstance(value, str):
        raise PipelineError("đường dẫn repository phải là chuỗi")
    candidate = value.replace("\\", "/").strip()
    if candidate.startswith(("/", "//")) or re.match(r"^[A-Za-z]:/", candidate):
        raise PipelineError(f"đường dẫn thoát khỏi repository: {value!r}")
    candidate = candidate.rstrip("/")
    path = PurePosixPath(candidate)
    if not candidate or path.is_absolute() or ".." in path.parts:
        raise PipelineError(f"đường dẫn thoát khỏi repository: {value!r}")
    return path.as_posix()


def _string(metadata: dict[str, Any], field: str) -> str:
    value = metadata[field]
    if not isinstance(value, str) or not value.strip():
        raise PipelineError(f"field {field!r} phải là chuỗi không rỗng")
    return value.strip()


def _string_list(metadata: dict[str, Any], field: str) -> tuple[str, ...]:
    value = metadata[field]
    if not isinstance(value, list) or any(
        not isinstance(item, str) or not item.strip() for item in value
    ):
        raise PipelineError(f"field {field!r} phải là list string")
    return tuple(item.strip() for item in value)


def _checks(metadata: dict[str, Any]) -> tuple[Check, ...]:
    raw_checks = metadata.get("checks", [])
    if not isinstance(raw_checks, list):
        raise PipelineError("field 'checks' phải là list table")

    checks: list[Check] = []
    seen_ids: set[str] = set()
    for index, raw in enumerate(raw_checks):
        if not isinstance(raw, dict) or set(raw) != {"id", "command"}:
            raise PipelineError(
                f"checks[{index}] phải chỉ có field 'id' và 'command'"
            )
        check_id = raw["id"]
        command = raw["command"]
        if not isinstance(check_id, str) or not check_id.strip():
            raise PipelineError(f"checks[{index}].id phải là chuỗi không rỗng")
        if (
            not isinstance(command, list)
            or not command
            or any(not isinstance(part, str) or not part for part in command)
        ):
            raise PipelineError(
                f"checks[{index}].command phải là list string không rỗng"
            )
        check_id = check_id.strip()
        if check_id in seen_ids:
            raise PipelineError(f"check id trùng: {check_id}")
        seen_ids.add(check_id)
        checks.append(Check(check_id, tuple(command)))
    return tuple(checks)


def load_package(path: Path) -> Package:
    metadata, body = split_front_matter(path.read_text(encoding="utf-8"))
    missing = sorted(REQUIRED_FIELDS - metadata.keys())
    if missing:
        raise PipelineError(f"thiếu field bắt buộc: {', '.join(missing)}")
    unknown = sorted(metadata.keys() - REQUIRED_FIELDS - {"checks"})
    if unknown:
        raise PipelineError(f"field không được hỗ trợ: {', '.join(unknown)}")

    package_id = _string(metadata, "id")
    if not PACKAGE_ID_RE.fullmatch(package_id):
        raise PipelineError(f"id package không hợp lệ: {package_id!r}")

    kind = _string(metadata, "kind")
    if kind not in KINDS:
        raise PipelineError(f"kind không hợp lệ: {kind!r}")
    status = _string(metadata, "status")
    if status not in CATALOG_STATUSES:
        raise PipelineError(f"status catalog không hợp lệ: {status!r}")

    return Package(
        path=path,
        id=package_id,
        title=_string(metadata, "title"),
        kind=kind,
        phase=_string(metadata, "phase"),
        status=status,
        depends_on=_string_list(metadata, "depends_on"),
        requirements=_string_list(metadata, "requirements"),
        qa=_string_list(metadata, "qa"),
        read_first=tuple(
            normalize_repo_path(item) for item in _string_list(metadata, "read_first")
        ),
        allowed_paths=tuple(
            normalize_repo_path(item)
            for item in _string_list(metadata, "allowed_paths")
        ),
        deliverables=tuple(
            normalize_repo_path(item)
            for item in _string_list(metadata, "deliverables")
        ),
        out_of_scope=_string_list(metadata, "out_of_scope"),
        checks=_checks(metadata),
        body=body,
    )


def load_packages(root: Path) -> dict[str, Package]:
    packages: dict[str, Package] = {}
    for path in sorted((root / "work" / "packages").glob("*.md")):
        package = load_package(path)
        if package.id in packages:
            raise PipelineError(f"package id trùng: {package.id}")
        packages[package.id] = package
    return dict(sorted(packages.items()))


def load_document_register(root: Path) -> tuple[Document, ...]:
    path = root / "docs" / "governance" / "document-register.toml"
    if not path.exists():
        return ()
    try:
        data = tomllib.loads(path.read_text(encoding="utf-8"))
    except tomllib.TOMLDecodeError as exc:
        raise PipelineError(f"document register TOML không hợp lệ: {exc}") from exc

    raw_documents = data.get("documents", [])
    if not isinstance(raw_documents, list):
        raise PipelineError("document register phải có [[documents]]")

    documents: list[Document] = []
    seen_paths: set[str] = set()
    for index, item in enumerate(raw_documents):
        if not isinstance(item, dict):
            raise PipelineError(f"documents[{index}] phải là table")
        missing = {"path", "class", "status", "owner"} - item.keys()
        if missing:
            raise PipelineError(
                f"documents[{index}] thiếu field: {', '.join(sorted(missing))}"
            )
        document_path = normalize_repo_path(item["path"])
        if document_path in seen_paths:
            raise PipelineError(f"document register trùng path: {document_path}")
        seen_paths.add(document_path)
        documents.append(
            Document(
                path=document_path,
                document_class=_document_string(item, "class", index),
                status=_document_string(item, "status", index).upper(),
                owner=_document_string(item, "owner", index),
                superseded_by=(
                    normalize_repo_path(item["superseded_by"])
                    if item.get("superseded_by") is not None
                    else None
                ),
            )
        )
    return tuple(documents)


def _document_string(item: dict[str, Any], field: str, index: int) -> str:
    value = item[field]
    if not isinstance(value, str) or not value.strip():
        raise PipelineError(f"documents[{index}].{field} phải là chuỗi không rỗng")
    return value.strip()


def _relative_path(root: Path, path: Path) -> str:
    try:
        return path.relative_to(root).as_posix()
    except ValueError:
        return path.as_posix()


def _authority_ids(
    root: Path, documents: tuple[Document, ...]
) -> tuple[set[str], set[str], set[str]]:
    active_requirements: set[str] = set()
    active_qa: set[str] = set()
    proposed_ids: set[str] = set()
    for document in documents:
        path = root / document.path
        if not path.is_file():
            continue
        content = path.read_text(encoding="utf-8")
        requirement_ids = set(REQUIREMENT_RE.findall(content))
        qa_ids = set(QA_RE.findall(content))
        is_post_mvp = (
            document.status == "PROPOSED"
            or document.document_class.upper() == "POST-MVP"
        )
        if is_post_mvp:
            proposed_ids.update(requirement_ids)
            proposed_ids.update(qa_ids)
        elif document.status in {"CANONICAL", "ACTIVE"}:
            active_requirements.update(requirement_ids)
            active_qa.update(qa_ids)
    return active_requirements, active_qa, proposed_ids


def validate_catalog(root: Path, packages: dict[str, Package]) -> list[Issue]:
    issues: list[Issue] = []
    documents = load_document_register(root)
    requirement_ids, qa_ids, proposed_ids = _authority_ids(root, documents)

    for package in packages.values():
        package_path = _relative_path(root, package.path)
        for dependency in package.depends_on:
            if dependency not in packages:
                issues.append(
                    Issue(
                        "MISSING_DEPENDENCY",
                        package_path,
                        f"dependency không tồn tại: {dependency}",
                    )
                )
        for read_first in package.read_first:
            if not (root / read_first).is_file():
                issues.append(
                    Issue(
                        "MISSING_READ_FIRST",
                        package_path,
                        f"read_first không tồn tại: {read_first}",
                    )
                )
        for requirement in package.requirements:
            if requirement in requirement_ids:
                continue
            if requirement in proposed_ids and package.phase != "POST-MVP":
                issues.append(
                    Issue(
                        "PROPOSED_REQUIREMENT",
                        package_path,
                        f"requirement {requirement} chỉ dành cho phase POST-MVP",
                    )
                )
            else:
                issues.append(
                    Issue(
                        "UNKNOWN_REQUIREMENT",
                        package_path,
                        f"requirement không có trong authority: {requirement}",
                    )
                )
        for qa_id in package.qa:
            if qa_id in qa_ids:
                continue
            if qa_id in proposed_ids and package.phase != "POST-MVP":
                issues.append(
                    Issue(
                        "PROPOSED_QA",
                        package_path,
                        f"QA {qa_id} chỉ dành cho phase POST-MVP",
                    )
                )
            else:
                issues.append(
                    Issue(
                        "UNKNOWN_QA",
                        package_path,
                        f"QA không có trong authority: {qa_id}",
                    )
                )

    issues.extend(_dependency_cycle_issues(root, packages))
    return sorted(issues, key=lambda issue: (issue.path, issue.code, issue.message))


def _dependency_cycle_issues(
    root: Path, packages: dict[str, Package]
) -> list[Issue]:
    colors = {package_id: 0 for package_id in packages}
    stack: list[str] = []
    reported: set[tuple[str, ...]] = set()
    issues: list[Issue] = []

    def visit(package_id: str) -> None:
        colors[package_id] = 1
        stack.append(package_id)
        for dependency in packages[package_id].depends_on:
            if dependency not in packages:
                continue
            if colors[dependency] == 0:
                visit(dependency)
            elif colors[dependency] == 1:
                start = stack.index(dependency)
                cycle = tuple(stack[start:] + [dependency])
                if cycle not in reported:
                    reported.add(cycle)
                    issues.append(
                        Issue(
                            "DEPENDENCY_CYCLE",
                            _relative_path(root, packages[package_id].path),
                            f"chu trình dependency: {' -> '.join(cycle)}",
                        )
                    )
        stack.pop()
        colors[package_id] = 2

    for package_id in sorted(packages):
        if colors[package_id] == 0:
            visit(package_id)
    return issues


def validate_links(root: Path, documents: tuple[Document, ...]) -> list[Issue]:
    issues: list[Issue] = []
    resolved_root = root.resolve()
    for document in documents:
        if document.status not in ACTIVE_DOCUMENT_STATUSES:
            continue
        source = root / document.path
        if not source.is_file():
            issues.append(
                Issue("MISSING_DOCUMENT", document.path, "tài liệu đã đăng ký không tồn tại")
            )
            continue
        content = source.read_text(encoding="utf-8")
        for match in MARKDOWN_LINK_RE.finditer(content):
            raw_target = match.group(1).strip()
            if raw_target.startswith("<") and raw_target.endswith(">"):
                raw_target = raw_target[1:-1]
            split = urlsplit(raw_target)
            if split.scheme.lower() in {"http", "https", "mailto"}:
                continue
            if not split.path:
                continue
            decoded = unquote(split.path).replace("\\", "/")
            candidate = (source.parent / decoded).resolve()
            if not candidate.is_relative_to(resolved_root):
                issues.append(
                    Issue(
                        "LINK_ESCAPE",
                        document.path,
                        f"link thoát khỏi repository: {raw_target}",
                    )
                )
            elif not candidate.exists():
                issues.append(
                    Issue(
                        "BROKEN_LINK",
                        document.path,
                        f"link không tồn tại: {raw_target}",
                    )
                )
    return sorted(issues, key=lambda issue: (issue.path, issue.code, issue.message))


def trace_requirement(
    root: Path, requirement_id: str, packages: dict[str, Package]
) -> str:
    lines: list[str] = [f"Requirement: {requirement_id}"]
    for document in load_document_register(root):
        if document.status not in ACTIVE_DOCUMENT_STATUSES:
            continue
        path = root / document.path
        if not path.is_file():
            continue
        content = path.read_text(encoding="utf-8")
        if requirement_id in content:
            lines.append(f"Definition: {document.path}")
            for qa_id in sorted(set(QA_RE.findall(content))):
                lines.append(f"QA: {qa_id} ({document.path})")
    for package in packages.values():
        if requirement_id in package.requirements:
            qa_text = ", ".join(package.qa) if package.qa else "none"
            lines.append(f"Package: {package.id} (QA: {qa_text})")
    return "\n".join(lines)


def repository_root() -> Path:
    return Path(__file__).resolve().parents[1]


def inspect_package(root: Path, package_id: str) -> str:
    packages = load_packages(root)
    if package_id not in packages:
        raise PipelineError(f"package không tồn tại: {package_id}")
    package = packages[package_id]
    lines: list[str] = [
        f"Package: {package.id} ({package.title})",
        f"Kind: {package.kind}",
        f"Phase: {package.phase}",
        f"Status: {package.status}",
        f"Depends on: {', '.join(package.depends_on) or 'none'}",
        f"Requirements: {', '.join(package.requirements) or 'none'}",
        f"QA: {', '.join(package.qa) or 'none'}",
        "Read first:",
        *(f"  - {p}" for p in package.read_first),
        "Allowed paths:",
        *(f"  - {p}" for p in package.allowed_paths),
        "Deliverables:",
        *(f"  - {p}" for p in package.deliverables),
        "Out of scope:",
        *(f"  - {p}" for p in package.out_of_scope),
        "Checks:",
        *(f"  - {check.id}: {' '.join(check.command)}" for check in package.checks),
    ]
    return "\n".join(lines)


def doctor(root: Path) -> list[Issue]:
    packages = load_packages(root)
    issues = validate_catalog(root, packages)
    documents = load_document_register(root)
    issues.extend(validate_links(root, documents))
    for path in root.rglob("*"):
        relative = _relative_path(root, path)
        if ".git" in path.parts:
            continue
        if "__pycache__" in path.parts or path.suffix == ".pyc":
            issues.append(
                Issue(
                    "CACHE_ARTIFACT",
                    relative,
                    "Python cache không được nằm trong repository",
                )
            )
        if path.name == "meowdoku-clone.xml":
            issues.append(
                Issue(
                    "REPOMIX_SNAPSHOT",
                    relative,
                    "Repomix snapshot phải được tái tạo ngoài repository",
                )
            )
        if path.is_file() and not relative.startswith(
            ("docs/archive/", ".git/", ".codegraph/")
        ):
            if path.suffix in {".md", ".toml"}:
                try:
                    content = path.read_text(encoding="utf-8")
                    if "ASOL-Game-03" in content or "file:///" in content:
                        issues.append(
                            Issue(
                                "OBSOLETE_PATH",
                                relative,
                                "chứa đường dẫn tuyệt đối hoặc định danh cũ",
                            )
                        )
                except UnicodeDecodeError:
                    pass
    return sorted(issues, key=lambda issue: (issue.path, issue.code, issue.message))


def git(root: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    command = ["git", "-c", f"safe.directory={root.resolve().as_posix()}", *args]
    return subprocess.run(
        command, cwd=root, text=True, capture_output=True, check=check
    )


def serialize_state(state: State) -> str:
    return (
        f'package_id = "{state.package_id}"\n'
        f'agent = "{state.agent}"\n'
        f'status = "{state.status}"\n'
        f'branch = "{state.branch}"\n'
        f'base_revision = "{state.base_revision}"\n'
        f'started_at = "{state.started_at}"\n'
        f'updated_at = "{state.updated_at}"\n'
        f'blocker_reason = "{state.blocker_reason}"\n'
    )


def read_state(root: Path, package_id: str) -> State:
    path = root / "work" / "state" / f"{package_id}.toml"
    if not path.is_file():
        raise PipelineError(f"state không tồn tại cho package: {package_id}")
    try:
        data = tomllib.loads(path.read_text(encoding="utf-8"))
    except tomllib.TOMLDecodeError as exc:
        raise PipelineError(f"state TOML không hợp lệ: {exc}") from exc
    return State(
        package_id=_string(data, "package_id"),
        agent=_string(data, "agent"),
        status=_string(data, "status"),
        branch=_string(data, "branch"),
        base_revision=_string(data, "base_revision"),
        started_at=_string(data, "started_at"),
        updated_at=_string(data, "updated_at"),
        blocker_reason=str(data.get("blocker_reason", "")).strip(),
    )


def write_state_atomic(path: Path, state: State) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(serialize_state(state), encoding="utf-8", newline="\n")
    os.replace(temporary, path)


def effective_status(root: Path, package: Package) -> str:
    state_path = root / "work" / "state" / f"{package.id}.toml"
    if state_path.is_file():
        try:
            state = read_state(root, package.id)
            return state.status
        except Exception:
            pass
    return package.status


def assert_state_base_is_ancestor(root: Path, state: State) -> None:
    result = git(
        root, "merge-base", "--is-ancestor", state.base_revision, "HEAD", check=False
    )
    if result.returncode != 0:
        raise PipelineError(
            f"base_revision {state.base_revision} không còn là ancestor của HEAD (branch có thể bị rebase hoặc đổi ngoài pipeline)"
        )


def changed_paths(root: Path, base_revision: str) -> set[str]:
    result_paths: set[str] = set()

    diff_head = git(root, "diff", "--name-only", base_revision, check=False)
    if diff_head.returncode == 0 and diff_head.stdout:
        for line in diff_head.stdout.splitlines():
            line_str = line.strip()
            if line_str:
                result_paths.add(line_str.replace("\\", "/"))

    diff_cached = git(root, "diff", "--name-only", "--cached", check=False)
    if diff_cached.returncode == 0 and diff_cached.stdout:
        for line in diff_cached.stdout.splitlines():
            line_str = line.strip()
            if line_str:
                result_paths.add(line_str.replace("\\", "/"))

    status_proc = git(root, "status", "--porcelain=v1", "-z", check=False)
    if status_proc.returncode == 0 and status_proc.stdout:
        raw_entries = [entry for entry in status_proc.stdout.split("\0") if entry]
        i = 0
        while i < len(raw_entries):
            entry = raw_entries[i]
            code = entry[:2]
            path_part = entry[3:]
            if code[0] in {"R", "C"} or code[1] in {"R", "C"}:
                i += 1
                if i < len(raw_entries):
                    result_paths.add(raw_entries[i].replace("\\", "/"))
            if path_part:
                result_paths.add(path_part.replace("\\", "/"))
            i += 1

    return result_paths


def start_package(root: Path, package_id: str, agent: str) -> State:
    packages = load_packages(root)
    if package_id not in packages:
        raise PipelineError(f"package không tồn tại: {package_id}")
    package = packages[package_id]
    if package.status != "ready":
        raise PipelineError(
            f"chỉ có thể start package ở trạng thái 'ready', hiện tại là: {package.status}"
        )

    for dep in package.depends_on:
        if dep not in packages:
            raise PipelineError(f"dependency không tồn tại: {dep}")
        dep_status = effective_status(root, packages[dep])
        if dep_status != "done":
            raise PipelineError(
                f"dependency {dep} chưa hoàn tất (trạng thái: {dep_status})"
            )

    status_proc = git(root, "status", "--porcelain=v1", check=False)
    if status_proc.stdout.strip():
        raise PipelineError(
            "working tree không sạch, vui lòng commit hoặc stash trước khi start"
        )

    branch_proc = git(root, "branch", "--show-current", check=False)
    current_branch = branch_proc.stdout.strip()

    slug = re.sub(r"[^a-z0-9]+", "-", package.title.lower()).strip("-")
    target_branch = f"work/{package.id.lower()}-{slug}"

    if current_branch != target_branch:
        switch_proc = git(root, "checkout", "-b", target_branch, check=False)
        if switch_proc.returncode != 0:
            git(root, "checkout", target_branch)

    head_proc = git(root, "rev-parse", "HEAD")
    head_revision = head_proc.stdout.strip()

    now_iso = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    state = State(
        package_id=package.id,
        agent=agent,
        status="in_progress",
        branch=target_branch,
        base_revision=head_revision,
        started_at=now_iso,
        updated_at=now_iso,
        blocker_reason="",
    )
    write_state_atomic(root / "work" / "state" / f"{package.id}.toml", state)
    return state


def transition_state(
    root: Path, package_id: str, new_status: str, *, blocker_reason: str = ""
) -> State:
    state = read_state(root, package_id)
    allowed = TRANSITIONS.get(state.status, set())
    if new_status not in allowed:
        raise PipelineError(
            f"không thể chuyển trạng thái từ {state.status} sang {new_status}"
        )
    now_iso = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    new_state = State(
        package_id=state.package_id,
        agent=state.agent,
        status=new_status,
        branch=state.branch,
        base_revision=state.base_revision,
        started_at=state.started_at,
        updated_at=now_iso,
        blocker_reason=blocker_reason if new_status == "blocked" else "",
    )
    write_state_atomic(root / "work" / "state" / f"{package_id}.toml", new_state)
    return new_state


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="agent_pipeline", description="Repository agent pipeline CLI"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("validate", help="Validate catalog and links")
    subparsers.add_parser("doctor", help="Run repository health checks")

    list_parser = subparsers.add_parser("list", help="List work packages")
    list_parser.add_argument(
        "--status", help="Filter packages by status", default=None
    )

    trace_parser = subparsers.add_parser(
        "trace", help="Trace requirement definition and usages"
    )
    trace_parser.add_argument("requirement_id", help="Requirement ID to trace")

    inspect_parser = subparsers.add_parser("inspect", help="Inspect package contract")
    inspect_parser.add_argument("package_id", help="Package ID to inspect")

    start_parser = subparsers.add_parser("start", help="Start work package")
    start_parser.add_argument("package_id", help="Package ID to start")
    start_parser.add_argument("--agent", required=True, help="Agent name")

    return parser


def _print(text: str = "", file: Any = None) -> None:
    target = file or sys.stdout
    try:
        print(text, file=target)
    except UnicodeEncodeError:
        buffer = getattr(target, "buffer", None)
        if buffer is not None:
            buffer.write((text + "\n").encode("utf-8", errors="replace"))
        else:
            print(
                text.encode("ascii", errors="backslashreplace").decode("ascii"),
                file=target,
            )


def dispatch(args: argparse.Namespace, root: Path) -> int:
    if args.command == "validate":
        packages = load_packages(root)
        issues = validate_catalog(root, packages)
        documents = load_document_register(root)
        issues.extend(validate_links(root, documents))
        if issues:
            for issue in issues:
                _print(f"{issue.code} {issue.path}: {issue.message}")
            return 1
        _print("OK: validation passed")
        return 0

    if args.command == "doctor":
        issues = doctor(root)
        if issues:
            for issue in issues:
                _print(f"{issue.code} {issue.path}: {issue.message}")
            return 1
        _print("OK: repository contract is valid")
        return 0

    if args.command == "list":
        packages = load_packages(root)
        for package in packages.values():
            status = effective_status(root, package)
            if args.status and status != args.status:
                continue
            _print(f"{package.id:10} {status:12} {package.kind:15} {package.title}")
        return 0

    if args.command == "trace":
        packages = load_packages(root)
        _print(trace_requirement(root, args.requirement_id, packages))
        return 0

    if args.command == "inspect":
        _print(inspect_package(root, args.package_id))
        return 0

    if args.command == "start":
        state = start_package(root, args.package_id, args.agent)
        _print(f"OK: started {state.package_id} on branch {state.branch}")
        return 0

    raise PipelineError(f"subcommand không được hỗ trợ: {args.command}")


def main(argv: list[str] | None = None, root: Path | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    root_path = (root or repository_root()).resolve()
    try:
        return dispatch(args, root_path)
    except PipelineError as exc:
        _print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())

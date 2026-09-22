from __future__ import annotations

import re
import tomllib
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Any


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

"""Verify that the M1 build deferral does not bypass acceptance gates."""

import tomllib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
PACKAGES = ROOT / "work" / "packages"
BUILD_IDS = ("M1-A01", "M1-A02", "M1-A03", "M1-A04", "M1-A05", "M1-A06", "M1-C01")


def dependencies(package_id: str) -> set[str]:
    source = (PACKAGES / f"{package_id}.md").read_text(encoding="utf-8")
    metadata = tomllib.loads(source.split("+++", 2)[1])
    return set(metadata["depends_on"])


def main() -> None:
    assert {"M0-A02", "M0-REPLAN"} <= dependencies("M0-DEFER")
    for package_id in BUILD_IDS:
        direct = dependencies(package_id)
        assert "M0-DEFER" in direct, package_id
        assert "M0-GATE" not in direct, package_id
    assert "M0-A03" in dependencies("M0-GATE")
    gate = dependencies("M1-GATE")
    assert "M0-GATE" in gate
    assert set(BUILD_IDS) <= gate
    print("M0_DEFER_DEPENDENCIES_PASS")


if __name__ == "__main__":
    main()

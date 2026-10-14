"""Clean-room gate: no reference identifiers in game scripts, no extracted_reusable imports."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
REFERENCE_NAMES = re.compile(
    r"EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager"
    r"|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter"
    r"|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku")
EXTRACTED = re.compile(r"extracted_reusable")
RULES = [("game/scripts", REFERENCE_NAMES), ("game/scripts", EXTRACTED), ("game/tests", EXTRACTED)]


def scan(root):
    """Return 'path:line: text' for every violation under root."""
    found = []
    for folder, pattern in RULES:
        for path in sorted((root / folder).rglob("*")):
            if not path.is_file() or path.suffix in (".uid", ".import"):
                continue
            lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
            for number, line in enumerate(lines, 1):
                if pattern.search(line):
                    found.append(f"{path.relative_to(root).as_posix()}:{number}: {line.strip()}")
    return found


def main():
    found = scan(ROOT)
    for line in found:
        print(line)
    print(f"{'FAIL' if found else 'PASS'} clean-room: {len(found)} violation(s)")
    return 1 if found else 0


if __name__ == "__main__":
    raise SystemExit(main())

"""Generate content and bank coverage report for Endless mode.

Reports:
- Total bank files, types, levels per bank.
- Coverage by size (4x4 through 12x12).
- Coverage by bank type (ranked and flat).
- Pace sidecar coverage.
- Config tiers and pool source statuses.
"""
from pathlib import Path
import json
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[1]
BANKS_DIR = ROOT / "game/data/banks"
CONFIG_FILE = ROOT / "game/data/endless_config.json"


def scan_banks():
    banks = {}
    pace_files = {}

    for path in sorted(BANKS_DIR.glob("*.json")):
        if path.name.endswith(".pace.json"):
            base_name = path.name[:-len(".pace.json")]
            pace_files[base_name] = path
        else:
            base_name = path.stem
            banks[base_name] = path

    bank_stats = []
    total_levels = 0

    for name, path in banks.items():
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except Exception as e:
            bank_stats.append({"name": name, "error": str(e), "levels": 0})
            continue

        levels_count = 0
        variant = "unknown"
        sizes = set()

        if "ranks" in data:
            variant = "ranked"
            sizes.add(data.get("size", 0))
            for r_levels in data["ranks"].values():
                levels_count += len(r_levels)
        elif "levels" in data:
            variant = f"flat ({data.get('type', 'generic')})"
            levels_count = len(data["levels"])
            for lvl in data["levels"]:
                if "size" in lvl:
                    sizes.add(lvl["size"])

        has_pace = name in pace_files
        total_levels += levels_count
        bank_stats.append({
            "name": name,
            "variant": variant,
            "sizes": sorted(sizes),
            "levels": levels_count,
            "has_pace": has_pace
        })

    return bank_stats, total_levels, pace_files


def generate_report():
    print("=" * 70)
    print("           CANDOKU ENDLESS MODE CONTENT COVERAGE REPORT")
    print("=" * 70)

    bank_stats, total_levels, pace_files = scan_banks()

    print(f"\n[1] BANKS INVENTORY (Directory: {BANKS_DIR.relative_to(ROOT)})")
    print("-" * 70)
    print(f"{'Bank Name':<28} | {'Type':<16} | {'Sizes':<12} | {'Levels':<7} | {'Pace'}")
    print("-" * 70)
    for b in bank_stats:
        sizes_str = ",".join(str(s) for s in b["sizes"])
        pace_str = "YES" if b["has_pace"] else "NO"
        print(f"{b['name']:<28} | {b['variant']:<16} | {sizes_str:<12} | {b['levels']:<7} | {pace_str}")

    print("-" * 70)
    print(f"Total Bank Files : {len(bank_stats)}")
    print(f"Total Levels     : {total_levels:,}")
    print(f"Pace Sidecars    : {len(pace_files)} / {len(bank_stats)} banks covered")

    print("\n[2] ENDLESS CONFIG STATUS")
    print("-" * 70)
    if CONFIG_FILE.exists():
        cfg = json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
        print(f"Config Version : {cfg.get('configVersion', 'N/A')}")
        print("Tiers:")
        for t_name, t_info in cfg.get("tiers", {}).items():
            en = "ENABLED" if t_info.get("enabled", False) else "DISABLED"
            print(f"  - {t_name:<18}: {en:<9} ({t_info.get('comment', '')})")
        print("Pool Sources:")
        for p_name, p_info in cfg.get("pool_sources", {}).items():
            en = "ENABLED" if p_info.get("enabled", False) else "DISABLED"
            extra = f" [inject_every={p_info.get('inject_every')}]" if "inject_every" in p_info else ""
            print(f"  - {p_name:<18}: {en:<9}{extra} ({p_info.get('comment', '')})")
    else:
        print("Config file not found!")

    print("\n" + "=" * 70)
    print("                   COVERAGE REPORT COMPLETE")
    print("=" * 70)


if __name__ == "__main__":
    generate_report()

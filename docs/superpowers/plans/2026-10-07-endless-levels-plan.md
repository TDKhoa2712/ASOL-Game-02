# Endless Levels — Implementation Plan

**Date:** 2026-10-07 (v4)
**Spec:** [endless-levels-design.md](../specs/2026-10-07-endless-levels-design.md)
**Base branch:** `dev`

---

## Phase Overview

| Phase | Branch | Mô tả | Estimate |
|-------|--------|-------|----------|
| P1 | `feat/endless-content` | Convert ALL 9 bank types + extend BankReader | 2-3 ngày |
| P2 | `feat/endless-core` | Core pipeline: registry, providers, cursors, DDA, config | 3-4 ngày |
| P3 | `feat/endless-integration` | Campaign runtime + Title Screen + UI | 2 ngày |
| P4 | `feat/endless-qa` | Integration tests + gate | 1 ngày |

**Tổng: 8-10 ngày** — P1 và P2 có thể chạy song song.

---

## Hiện trạng Content Pipeline

### Tool có sẵn

`tools/convert_extracted_bank.py` hiện chỉ convert **Regular banks 7-12**. Core logic:
- `convert_level(raw, size)`: `regionMap` (int[][]) → `regions` (string[]), gọi `solve()` để tạo trace/rating
- `load_ranked_source(path)`: xử lý ranked dict hoặc flat `{levels:[...]}`
- `convert_bank_file(source, size, bank_out, pace_out)`: orchestrator

### Source data (extracted_reusable/levels/) — 3 nhóm schema

| Nhóm | Format | Banks | Levels | Đặc điểm |
|------|--------|-------|--------|-----------|
| **A: Ranked** | `{"1":[…],"2":[…]}` | Regular 4-12, LKStyle 7-12 | ~16k | Rank key = dict key. Converter hiện tại xử lý được |
| **B: Flat sized** | `{"levels":[…]}` mỗi entry cùng size | GC 6-12, OneFish 7-10, SuperHard | ~6.7k | Rank trong field `r` per-entry. Size từ filename |
| **C: Flat mixed-size** | `{"levels":[…]}` hoặc `[…]`, mỗi entry có `size` | SP, LK, LKModified, SP_TT, SingleRegion | ~7k | `size` per-entry (mixed). Có fields riêng: `shapeCategory`, `id`, `label`, `date` |

### Output schema cần 2 variants

**Variant A — Ranked by size** (1 file per size):
```json
{"bankVersion": 1, "size": 8, "ranks": {"1": [...], "2": [...]}}
```
Dùng cho: Regular, LKStyle, GC, OneFish.

**Variant B — Flat indexed** (1 file cho tất cả sizes):
```json
{"bankVersion": 1, "type": "sp", "levels": [
  {"size": 7, "rank": 2, "shapeCategory": 3, "regions": [...], ...}
]}
```
Dùng cho: SP, LK, LKModified, SP_TT, SingleRegion, SuperHard.

### Vấn đề kỹ thuật

| # | Vấn đề | Giải pháp |
|---|--------|-----------|
| 1 | `solve()` chậm cho 6000+ SingleRegion levels | Fast path: nếu source đã có `r1-r5` profile → dùng trực tiếp, skip `solve()`. Chỉ gọi `solve()` khi cần trace cho hints |
| 2 | SP/LK/LKModified thiếu `seed` | Dùng `id` hoặc `0` |
| 3 | SP có `colorMap`, `pattern`, `spRegion` | Preserve trong output schema (provider cần) |
| 4 | SP_TT có `shapeCategory` (1-6) | Preserve — SpTtProvider cần để cycling |
| 5 | SingleRegion có `_source_file` | Drop — không cần trong output |
| 6 | LK là flat list `[…]` (không phải dict) | `load_ranked_source()` đã handle: returns `{"1": data}` |
| 7 | Regular 4-6 chưa convert | Thêm vào SIZE_SOURCES |

---

## Phase 1: Bank Content Conversion

**Branch:** `feat/endless-content`
**Goal:** Convert toàn bộ 9 bank types, extend BankReader.

### Task 1.1: Refactor convert_extracted_bank.py

**File:** `tools/convert_extracted_bank.py` (modify)

Thay đổi:
- Rename `SIZE_SOURCES` → dùng `BANK_REGISTRY` dict mới tổ chức theo type
- `convert_level()` thêm fast path: nếu có `r1-r5` → build profile trực tiếp, skip `solve()`
- Thêm `convert_flat_bank()` cho Variant B output (mixed-size, preserve extra fields)
- Thêm CLI: `--type regular|lkstyle|gc|sp|lk|lk_mod|sp_tt|single_region|onefish|super_hard|all`
- Thêm `--fast` flag: skip `solve()`, dùng source profile trực tiếp (cho bulk convert)

```python
BANK_REGISTRY = {
    # Type A: Ranked, 1 file per size
    "regular": {
        "format": "ranked",
        "sources": {
            4: "extracted_reusable/levels/bankData4x4.json",
            5: "extracted_reusable/levels/bankData5x5.json",
            6: "extracted_reusable/levels/bankData6x6.json",
            7: "extracted_reusable/levels/bankData7x7.json",
            8: "extracted_reusable/levels/bankData8x8.json",
            9: "extracted_reusable/levels/bankData9x9.json",
            10: "extracted_reusable/levels/bankData10x10.json",
            12: "extracted_reusable/levels/bankData12x12.json",
        },
        "output": "bank_{size}x{size}.json",
    },
    "lkstyle": {
        "format": "ranked",
        "sources": {
            7: "extracted_reusable/levels/bankDataLKStyle7x7.json",
            8: "extracted_reusable/levels/bankDataLKStyle8x8.json",
            9: "extracted_reusable/levels/bankDataLKStyle9x9.json",
            10: "extracted_reusable/levels/bankDataLKStyle10x10.json",
            11: "extracted_reusable/levels/bankDataLKStyle11x11.json",
            12: "extracted_reusable/levels/bankDataLKStyle12x12.json",
        },
        "output": "bank_lkstyle_{size}x{size}.json",
    },
    "gc": {
        "format": "flat_sized",
        "sources": {
            6: "extracted_reusable/levels/bankDataGC6x6.json",
            8: "extracted_reusable/levels/bankDataGC8x8.json",
            9: "extracted_reusable/levels/bankDataGC9x9.json",
            10: "extracted_reusable/levels/bankDataGC10x10.json",
            11: "extracted_reusable/levels/bankDataGC11x11.json",
            12: "extracted_reusable/levels/bankDataGC12x12.json",
        },
        "output": "bank_gc_{size}x{size}.json",
    },
    "onefish": {
        "format": "flat_sized",
        "sources": {
            7: "extracted_reusable/levels/bankDataOneFish7x7.json",
            8: "extracted_reusable/levels/bankDataOneFish8x8.json",
            9: "extracted_reusable/levels/bankDataOneFish9x9.json",
            10: "extracted_reusable/levels/bankDataOneFish10x10.json",
        },
        "output": "bank_onefish_{size}x{size}.json",
    },
    # Type B: Flat, 1 file total (mixed sizes)
    "sp": {
        "format": "flat_mixed",
        "source": "extracted_reusable/levels/bankDataSP.json",
        "output": "bank_sp.json",
        "extra_fields": ["colorMap", "pattern", "spRegion", "id"],
    },
    "lk": {
        "format": "flat_mixed",
        "source": "extracted_reusable/levels/bankDataLK.json",
        "output": "bank_lk.json",
        "extra_fields": ["id", "label", "date"],
    },
    "lk_modified": {
        "format": "flat_mixed",
        "source": "extracted_reusable/levels/bankDataLKModified.json",
        "output": "bank_lk_modified.json",
        "extra_fields": ["seq", "transform", "id"],
    },
    "sp_tt": {
        "format": "flat_mixed",
        "source": "extracted_reusable/levels/bankDataSP_TT.json",
        "output": "bank_sp_tt.json",
        "extra_fields": ["shapeCategory", "id"],
    },
    "single_region": {
        "format": "flat_mixed",
        "source": "extracted_reusable/levels/bankDataSingleRegion.json",
        "output": "bank_single_region.json",
        "extra_fields": ["maxRegionFrac"],
    },
    "super_hard": {
        "format": "flat_mixed",
        "source": "extracted_reusable/levels/bankDataSuperHard.json",
        "output": "bank_super_hard.json",
        "extra_fields": [],
    },
}
```

### Task 1.2: Thêm convert_level_fast()

Cho levels đã có profile (`r1-r5`, `_pid_h`), build output trực tiếp mà không gọi `solve()`:

```python
def convert_level_fast(raw: dict, size: int, extra_fields: list[str] = []) -> dict | None:
    region_map = raw.get("regionMap")
    solution = raw.get("solution")
    if not region_map or not solution:
        return None
    if isinstance(region_map[0], list):  # int[][] → string[]
        regions = convert_region_map(region_map)
    else:
        regions = region_map  # already string[]

    if not check_level_candy_rules(regions, solution, size):
        return None

    r1 = raw.get("r1", size)
    r2 = raw.get("r2", 0)
    r3 = raw.get("r3", 0) + raw.get("r4", 0) + raw.get("r5", 0)
    pid_hash = raw.get("_pid_h", "")
    if not pid_hash:
        pid_hash = puzzle_key(regions, [])[:8]
    if len(pid_hash) > 8:
        pid_hash = pid_hash[:8]
    rating = raw.get("rating", raw.get("r", 1) * 100)

    entry = {
        "seed": raw.get("seed", 0),
        "regions": regions,
        "solution": solution,
        "givens": [],
        "steps": raw.get("steps", size),
        "profile": [r1, r2, r3],
        "rating": rating,
        "pidHash": pid_hash,
        "logicTrace": [],  # empty — will generate at runtime if needed
    }
    for field in extra_fields:
        if field in raw:
            entry[field] = raw[field]
    return entry
```

**Lưu ý:** `logicTrace` trống cho fast path. Trace chỉ cần khi runtime solver chạy hints — solver sẽ tự tạo trace khi player dùng hint.

### Task 1.3: Thêm convert_flat_bank()

Cho Variant B banks (flat, mixed-size):

```python
def convert_flat_bank(
    source_path: str, bank_type: str, output: str,
    extra_fields: list[str], fast: bool = True
) -> dict:
    with open(source_path) as f:
        data = json.load(f)
    items = data if isinstance(data, list) else data.get("levels", [])

    bank = {"bankVersion": 1, "type": bank_type, "levels": []}
    skipped = 0
    for raw in items:
        size = raw.get("size", infer_size_from_regionMap(raw))
        fn = convert_level_fast if fast else convert_level
        converted = fn(raw, size, extra_fields if fast else [])
        if converted is None:
            skipped += 1
            continue
        converted["size"] = size
        converted["rank"] = raw.get("r", 1)
        bank["levels"].append(converted)

    Path(output).parent.mkdir(parents=True, exist_ok=True)
    with open(output, "w", encoding="utf-8") as f:
        json.dump(bank, f, indent=2)
    return {"accepted": len(bank["levels"]), "skipped": skipped}
```

### Task 1.4: Run conversion — ALL banks

```bash
# Ranked banks (with solve for trace)
rtk python -B tools/convert_extracted_bank.py --type regular --all
rtk python -B tools/convert_extracted_bank.py --type lkstyle --all
rtk python -B tools/convert_extracted_bank.py --type gc --all
rtk python -B tools/convert_extracted_bank.py --type onefish --all

# Flat banks (fast — skip solve, ~30k levels)
rtk python -B tools/convert_extracted_bank.py --type sp --fast
rtk python -B tools/convert_extracted_bank.py --type lk --fast
rtk python -B tools/convert_extracted_bank.py --type lk_modified --fast
rtk python -B tools/convert_extracted_bank.py --type sp_tt --fast
rtk python -B tools/convert_extracted_bank.py --type single_region --fast
rtk python -B tools/convert_extracted_bank.py --type super_hard --fast
```

Expected output files:
```
game/data/banks/
├── bank_4x4.json ... bank_12x12.json          (Regular, 9 files)
├── bank_4x4.pace.json ... bank_12x12.pace.json
├── bank_lkstyle_7x7.json ... 12x12.json       (LKStyle, 6 files)
├── bank_gc_6x6.json ... 12x12.json             (GC, 6 files)
├── bank_onefish_7x7.json ... 10x10.json        (OneFish, 4 files)
├── bank_sp.json                                 (SP, 57 levels)
├── bank_lk.json                                 (LK, 169 levels)
├── bank_lk_modified.json                        (LKModified, 169 levels)
├── bank_sp_tt.json                              (SP_TT, 432 levels)
├── bank_single_region.json                      (SingleRegion, 6196 levels)
└── bank_super_hard.json                         (SuperHard, 275 levels)
```

### Task 1.5: Extend BankReader

**File:** `game/scripts/content/bank_reader.gd` (modify)
**Test:** `game/tests/test_bank_reader.gd` (extend)

Thêm methods per bank type:

```gdscript
# Ranked banks (same pattern as existing get_levels)
func get_lkstyle_levels(size: int, rank: int, tier: String) -> Array
func get_gc_levels(size: int, rank: int) -> Array
func get_onefish_levels(size: int, rank: int) -> Array

# Flat banks (new: load once, filter by size/rank at query time)
func get_sp_level(index: int) -> Dictionary
func get_lk_level(index: int) -> Dictionary
func get_lk_mod_levels(size: int, rank: int, strict: bool) -> Array
func get_sp_tt_levels(category: int, size: int, rank: int) -> Array
func get_single_region_levels(size: int, rank: int) -> Array
func get_super_hard_levels() -> Array
```

Flat banks cần internal index per (size, rank) — built once on first load.

### Task 1.6: Extend validate_content.py

Extend validator cho Variant B schema. Validate all converted banks.

### Task 1.7: Tests cho convert pipeline

**File:** `tools/tests/test_convert_extracted_bank.py` (extend)

- Test `convert_level_fast()` fields
- Test `convert_flat_bank()` output schema
- Test round-trip: source → convert → validate passes
- Test `BANK_REGISTRY` completeness

**Acceptance:** All banks converted and validated. BankReader loads all types.

---

## Phase 2: Core Selection Pipeline

**Branch:** `feat/endless-core`
**Depends on:** P1 merged (BankReader extension)
**Có thể bắt đầu song song** với P1 (dùng mock bank data, wire real data khi P1 done)

### Task 2.1: EndlessConfig + endless_config.json

**Files:**
- `game/scripts/endless/endless_config.gd`
- `game/data/endless_config.json`

**Test:** `game/tests/test_endless_config.gd`

Per spec §4.

### Task 2.2: EndlessProgress

**File:** `game/scripts/endless/endless_progress.gd`
**Test:** `game/tests/test_endless_progress.gd`

Schema v3, all cursor types, FIFO dedup, DualSlotStore integration.

### Task 2.3: Context modules

**Files:** `select_context.gd`, `size_schedule.gd`, `strategy_modifier.gd`
**Test:** `game/tests/test_context_modules.gd`

### Task 2.4: Pool Registry

**Files:** `pool_source.gd`, `pool_builder.gd`, `pool_picker.gd`
**Test:** `game/tests/test_pool_registry.gd`

Generic PoolSource + PoolBuilder (register/build) + PoolPicker (injection + sequential).

### Task 2.5: Cursors

**Files:** `bank_cursor.gd`, `main_cursor.gd`, `super_hard_cursor.gd`
**Test:** `game/tests/test_cursors.gd`

### Task 2.6: Delivery

**Files:** `puzzle_dedup.gd`, `level_validator.gd`
**Test:** `game/tests/test_delivery.gd`

### Task 2.7: Providers (Tier 1 + 2)

**Files:** `special_provider.gd`, `super_hard_provider.gd`, `single_region_provider.gd`, `sp_tt_provider.gd`, `onefish_provider.gd`
**Test:** `game/tests/test_providers.gd`

Each checks config toggle. Separate cursors for single_region, sp_tt, onefish.

### Task 2.8: SettlementHandler (DDA)

**File:** `settlement_handler.gd`
**Test:** `game/tests/test_settlement.gd`

### Task 2.9: ControlStrategy + LevelSelector

**Files:** `selection_strategy.gd`, `control_strategy.gd`, `level_selector.gd`
**Test:** `game/tests/test_level_selector.gd`

Full 4-tier decision + 7-phase relaxation.

**Acceptance:** Full pipeline end-to-end. All tests pass headless.

---

## Phase 3: Integration + UI

**Branch:** `feat/endless-integration`
**Depends on:** P1 + P2 merged

### Task 3.1: campaign_runtime.gd — mode dispatch

- `_mode: StringName` — `&"campaign"` / `&"endless"`
- `start_endless()`, mode dispatch in `start_level()`, `on_level_won()`, `on_level_lost()`

### Task 3.2: title_screen.gd — Endless button

### Task 3.3: nav_controller.gd — route

### Task 3.4: progress_manager.gd — schema v3

### Task 3.5: Result screens — endless UI

### Task 3.6: app_shell.gd — wire

**Acceptance:** Title → Endless → Play → Win → Next → repeat. Campaign unchanged.

---

## Phase 4: QA + Gate

**Branch:** `feat/endless-qa`
**Depends on:** P3 merged

### Task 4.1: Integration test — 100 consecutive selects
### Task 4.2: Feature toggle test — disable/enable each
### Task 4.3: DDA test — win/loss streaks
### Task 4.4: Coverage report (`tools/endless_coverage_report.py`)
### Task 4.5: Full gate

```bash
rtk python -B tools/verify.py --godot <executable>
rtk proxy rg -n "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/
rtk proxy rg -n "extracted_reusable" game/scripts/ game/tests/
```

**Acceptance:** All tests pass. Gate clean.

---

## Agent Execution Notes

### Per-Phase Workflow

1. `git checkout dev && git pull`
2. `git checkout -b <branch>`
3. TDD: test → fail → implement → pass
4. Commit: `feat(endless): add pool_registry`
5. Full gate trước bàn giao

### Clean-Room Rule

- ✅ Dùng bank **data** từ extracted_reusable (convert sang schema riêng)
- ✅ Tham khảo **hành vi** (cursor cycling, relaxation, DDA)
- ❌ KHÔNG copy code, class names, enum names verbatim
- Gate: `rg "(EventBus|EventName|GameState|SaveStore|...)" game/scripts/` = no matches

### Key References

- **Spec:** `docs/superpowers/specs/2026-10-07-endless-levels-design.md`
- **Convert tool:** `tools/convert_extracted_bank.py`
- **Bank sources:** `extracted_reusable/levels/`
- **Existing bank reader:** `game/scripts/content/bank_reader.gd`
- **extracted_reusable selector:** `extracted_reusable/scripts/gameplay/selector/`

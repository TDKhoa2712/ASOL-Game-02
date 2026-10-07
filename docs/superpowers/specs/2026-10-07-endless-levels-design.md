# Endless Levels — Design Specification

**Date:** 2026-10-07
**Status:** Draft v3
**Scope:** Bank-based endless level system cho CanDoKu, adapted từ extracted_reusable

---

## 1. Mục tiêu

Game có 2 chế độ chơi chính:
- **Campaign:** Playlist cố định (tutorial + curated levels)
- **Endless:** Levels vô hạn từ pre-authored banks, với DDA adjustment

Endless là mode riêng biệt, truy cập trực tiếp từ Title Screen. Không yêu cầu hoàn thành Campaign.

### Yêu cầu chính

- **Content source:** Pre-authored banks — convert từ extracted_reusable/levels (đã có sẵn 100%)
- **Board sizes:** N = 4–12
- **Solver range:** S2–S7 (runtime solver cho hints)
- **Delivery time:** < 1 giây
- **9 loại bank** tổ chức thành **4 tầng cung ứng**
- **Pool Registry pattern** — thêm bank mới = 1 registration call
- **Feature toggles** — bật/tắt từng bank type qua config file
- **DDA settlement** — điều chỉnh độ khó theo hiệu suất player
- 8x transform cycling, 7-phase relaxation, puzzle deduplication

### KHÔNG bao gồm (R1)

- A/B test framework phức tạp (game offline, không cần multi-strategy)
- Runtime procedural generation
- Remote config server, analytics, IAP, ads, leaderboard

---

## 2. Tổng quan 9 loại Bank

| # | Bank Type | Source Files | Sizes | Vai trò | Tầng |
|---|-----------|-------------|-------|---------|------|
| 1 | **Regular** | `bankData{N}x{N}.json` | 4–12 | Xương sống — main pool | Tier 3 |
| 2 | **LKStyle** | `bankDataLKStyle{N}x{N}.json` | 7–12 | Vùng zigzac/phân mảnh | Tier 3 |
| 3 | **GC** | `bankDataGC{N}x{N}.json` | 6, 8–12 | Cụm khối lớn | Tier 3 |
| 4 | **SP (Special)** | `bankDataSP.json` | mixed | Milestones (bài tuyển chọn) | Tier 1 |
| 5 | **LK + LKModified** | `bankDataLK.json`, `bankDataLKModified.json` | mixed | LK milestones + inject mỗi 4 bài | Tier 1 + Tier 3 |
| 6 | **SP_TT (Topology)** | `bankDataSP_TT.json` | mixed | 6 nhóm hình đối xứng | Tier 2 |
| 7 | **SingleRegion** | `bankDataSingleRegion.json` | mixed | Bài dễ, DDA hỗ trợ player yếu | Tier 2 |
| 8 | **OneFish** | `bankDataOneFish{N}x{N}.json` | 7–10 | Chế độ Tử thần (1 lỗi = thua) | Tier 2 |
| 9 | **SuperHard** | `bankDataSuperHard.json` | 11 fixed | Bài cực khó | Tier 2 |

Tất cả đã có sẵn trong `extracted_reusable/levels/`. Convert sang schema v1 bằng `tools/convert_extracted_bank.py` mở rộng.

---

## 3. Kiến trúc 4-Tier Supply

```
Level N requested
│
├─ Tier 1: MILESTONE INTERCEPT
│  ├─ SpecialProvider: levels 10,20,30,...,100,123,456 → bank_sp
│  └─ LK milestones: levels 200,250,314 → bank_lk
│  (bị bỏ qua nếu level cũng là super_hard)
│
├─ Tier 2: DYNAMIC/SPECIAL INTERCEPT
│  ├─ SuperHard: levels %10==5 từ 35+ → bank_super_hard (11×11 cố định)
│  ├─ SingleRegion: DDA trigger khi player thua nhiều → bank_single_region
│  ├─ SpTt: 6 shape categories xoay vòng → bank_sp_tt
│  └─ OneFish: chế độ Tử thần riêng biệt → bank_onefish_{N}
│
├─ Tier 3: MAIN POOL ASSEMBLY (Pool Registry)
│  ├─ Regular (priority 0, sequential)
│  ├─ LKStyle (priority 1, sequential, size ≥ 7)
│  ├─ GC (priority 2, sequential, conditional)
│  ├─ LKModified (priority 10, inject every 4)
│  └─ [Future: Holiday, Seasonal, Community...]
│
└─ Tier 4: PICK + TRANSFORM + DEDUP
   ├─ PoolPicker: generic, iterate registered sources
   ├─ BankCursor: transform cycling (8x D4)
   └─ PuzzleDedup: FIFO 50 recent pidHashes
```

### Decision Priority

```
1. SuperHard? (level >= 35 && level % 10 == 5)  → SuperHard bank
2. Milestone? (level in SPECIAL_LEVELS dict)      → SP/LK bank
3. DDA intervention?                              → SingleRegion / SpTt
4. Normal: Main Pool Assembly                     → Registry sources
5. Pool exhausted: 7-phase relaxation             → loosen constraints
```

---

## 4. Feature Toggles

### 4.1 Config File

**File:** `game/data/endless_config.json` (editable, human-readable)

```json
{
  "configVersion": 1,

  "tiers": {
    "milestone": {
      "enabled": true,
      "comment": "Bài đặc biệt cho levels mốc (10, 20, 30...)"
    },
    "super_hard": {
      "enabled": true,
      "min_level": 35,
      "phase": 5,
      "period": 10,
      "comment": "Bài cực khó mỗi 10 levels (đuôi 5)"
    },
    "single_region_supp": {
      "enabled": true,
      "comment": "Bài hỗ trợ DDA khi player gặp khó"
    },
    "sp_tt": {
      "enabled": false,
      "comment": "6 nhóm hình đối xứng — bật khi có content"
    },
    "onefish": {
      "enabled": false,
      "comment": "Chế độ Tử thần — bật khi có content và UI"
    }
  },

  "pool_sources": {
    "regular":     {"enabled": true,  "comment": "Bank chính"},
    "lkstyle":     {"enabled": true,  "comment": "Phong cách LK, size >= 7"},
    "gc":          {"enabled": true,  "comment": "Grid Connected, conditional"},
    "lk_modified": {"enabled": true,  "inject_every": 4, "comment": "Cross-size, inject mỗi 4 bài"}
  },

  "difficulty": {
    "initial_strategy": 3,
    "comment": "Strategy mặc định (1-7). DDA sẽ điều chỉnh tự động"
  }
}
```

### 4.2 EndlessConfig (runtime)

```gdscript
class_name EndlessConfig extends RefCounted

var milestone_enabled: bool = true
var super_hard_enabled: bool = true
var super_hard_min_level: int = 35
var super_hard_phase: int = 5
var super_hard_period: int = 10
var single_region_supp_enabled: bool = true
var sp_tt_enabled: bool = false
var onefish_enabled: bool = false

var pool_source_config: Dictionary = {}
var initial_strategy: int = 3

static func load(path: String) -> EndlessConfig: ...
static func default_config() -> EndlessConfig: ...

func is_pool_enabled(source_id: StringName) -> bool:
    var cfg = pool_source_config.get(str(source_id), {})
    return cfg.get("enabled", false)

func get_inject_every(source_id: StringName) -> int:
    var cfg = pool_source_config.get(str(source_id), {})
    return cfg.get("inject_every", 0)
```

### 4.3 Cách bật/tắt

**Designer/QA:** Edit `game/data/endless_config.json` trực tiếp.
**Developer:** Thêm bank mới: tạo bank JSON → thêm entry vào config → register trong PoolBuilder (1 dòng).

---

## 5. Pool Registry Pattern

### 5.1 PoolSource — data object

```gdscript
class_name PoolSource extends RefCounted

var source_id: StringName     # &"regular", &"lkstyle", ...
var priority: int = 0         # pick order: lower = earlier
var inject_every: int = 0     # 0 = sequential, 4 = inject every 4
var apply_transform: bool = true
var levels: Array = []
```

### 5.2 PoolBuilder — register and assemble

```gdscript
class_name PoolBuilder extends RefCounted

var _sources: Array[PoolSource] = []

func register(source: PoolSource) -> void:
    _sources.append(source)
    _sources.sort_custom(func(a, b): return a.priority < b.priority)

func build(bank: BankReader, config: EndlessConfig,
           size: int, rank: int, tier: String, ...) -> Array[PoolSource]:
    _sources.clear()
    # Register enabled sources from config
    # Regular, LKStyle (size>=7), GC (conditional), LKModified (inject)
    # Dynamic/future sources from config
    return _sources
```

### 5.3 PoolPicker — generic, source-agnostic

```gdscript
class_name PoolPicker

static func pick_at(sources: Array[PoolSource], pos: Dictionary) -> Dictionary:
    # 1. Check injection sources (inject_every > 0)
    # 2. Sequential sources by priority
    return entry  # includes _source, _apply_transform metadata
```

### 5.4 MainCursor — generic injection tracking

```gdscript
class_name MainCursor extends BankCursor

var _inject_counters: Dictionary = {}  # source_id → {idx, since}

func advance(entry: Dictionary) -> void:
    var source_id = entry.get("_source", &"regular")
    # Injection source: advance its cursor, reset since counters
    # Sequential source: advance main idx, increment since counters

func budget() -> int:
    return total_levels * 8  # TRANSFORM_COUNT
```

---

## 6. Tier 1: Milestone Provider

```gdscript
class_name SpecialProvider extends RefCounted

const MILESTONES := {
    10: {source = &"sp", index = 0},
    20: {source = &"sp", index = 1},
    # ...
    200: {source = &"lk", index = 0},
    250: {source = &"lk", index = 1},
    314: {source = &"lk", index = 2},
}

func is_available(level_num: int, is_super_hard: bool) -> bool:
    if not _config.milestone_enabled: return false
    if is_super_hard: return false
    return level_num in MILESTONES
```

---

## 7. Tier 2: Dynamic/Special Providers

### 7.1 SuperHardProvider

Schedule: `level >= min_level && level % period == phase`. Fixed size=11, computed position, deterministic.

### 7.2 SingleRegionSuppProvider

DDA-triggered when player struggling. Separate cursor. Puzzles with exactly 1 single-cell region.

### 7.3 SpTtProvider (Topology)

6 categories, round-robin cycling. Per-category transform restrictions.

### 7.4 OneFishProvider (Permadeath)

Separate progress. Isolated DDA. 1-life mode.

---

## 8. Selection Strategy + DDA

### 8.1 Strategy — Simplified for Offline

Không dùng A/B framework. Một strategy duy nhất (ControlStrategy) với DDA adjustment:

```gdscript
class_name ControlStrategy extends SelectionStrategy

func select(request: Dictionary) -> Dictionary:
    var ctx = SelectContext.new()
    ctx.level_num = request.level_num
    ctx.size = SizeSchedule.get_size(ctx.level_num)

    # --- TIER 1: Super Hard ---
    if _super_hard.is_super_hard(ctx.level_num):
        return _select_super_hard(ctx)

    # --- TIER 1: Milestone ---
    if _special.is_available(ctx.level_num, false):
        return _special.get_entry(ctx.level_num)

    # Strategy/rank resolution (from DDA state)
    _resolve_rank_and_tier(ctx)

    # --- TIER 3: Main Pool ---
    var sources = _pool_builder.build(...)
    var cursor = MainCursor.new(...)

    # --- TIER 4: Selection loop ---
    var entry = _selection_loop(ctx, sources, cursor)

    # --- TIER 2: DDA fallback ---
    if entry.is_empty() and _single_region.is_available():
        entry = _single_region.next_entry(ctx.size, ctx.rank, 0, _progress)

    return entry
```

### 8.2 DDA Settlement

After win/loss, adjust strategy value:
- **Win streak** → increase strategy (harder)
- **Loss streak** → decrease strategy (easier)
- **Tool used** → freeze difficulty
- Strategy value maps to rank selection: higher strategy = higher ranks more often

```gdscript
class_name SettlementHandler extends RefCounted

func on_level_complete(result: Dictionary, progress: EndlessProgress, config: EndlessConfig):
    var current = progress.get_strategy()
    if result.won:
        if result.hints_used == 0 and result.time < result.par_time:
            current = mini(current + 1, 7)  # promote
    else:
        current = maxi(current - 1, 1)  # demote
    progress.set_strategy(current)
```

---

## 9. 7-Phase Relaxation

| Phase | Action |
|-------|--------|
| 1 | Disable dispersion filter |
| 2 | Remove single-region limit |
| 3 | Drop tier constraint |
| 4 | Try lower ranks (rank-1 → 1) |
| 5 | Try higher ranks (rank+1 → max) |
| 6 | Any size nearby (±1) |
| 7 | Return empty → DDA fallback or failure |

---

## 10. Size Schedule

```gdscript
const SIZES_TUTORIAL := [4, 4, 4, 5, 5, 5, 6, 6, 6, 6]
const SIZES_TRANSITION := [7, 7, 8, 8, 9, 9, 10, 10, 11, 12]
const SIZES_CYCLE := [8, 10, 10, 9, 10, 10, 9, 10, 10, 10]

static func get_size(level_num: int) -> int:
    if level_num < 1: return 0
    if level_num <= 10: return SIZES_TUTORIAL[level_num - 1]
    if level_num <= 20: return SIZES_TRANSITION[level_num - 11]
    return SIZES_CYCLE[(level_num - 21) % 10]
```

---

## 11. Puzzle Deduplication

FIFO 50 recent pidHashes. Fast path via precomputed `_pid_h` + `_pid_s` suffix array.

---

## 12. Entry Point — Endless Mode

### 12.1 Title Screen

Endless là mode riêng, truy cập trực tiếp:

```
┌─────────────────┐
│    CanDoKu      │
│                 │
│  [ Campaign ]   │  ← Playlist levels
│  [ Endless  ]   │  ← Vào ngay, không gate
│  [ Settings ]   │
└─────────────────┘
```

- **Campaign:** Chơi theo playlist cố định
- **Endless:** Chơi vô hạn, bắt đầu từ level 1 (endless riêng)
- Sau khi xong Campaign → gợi ý chuyển sang Endless (không bắt buộc)

### 12.2 Endless-specific UI

- Level counter: "Level 42"
- Streak display: current streak
- Win → "Next" (luôn)
- Loss → "Retry" + "Menu"
- OneFish loss → "Game Over" + score

### 12.3 Progress riêng biệt

Endless progress tách biệt hoàn toàn khỏi Campaign progress:
- `endless.levelNum` riêng
- `endless.strategy` riêng (DDA state)
- `endless.cursors` riêng
- `endless.stats` (totalPlayed, longestStreak, bestBySize)

---

## 13. Integration với Existing Code

### 13.1 campaign_runtime.gd — thêm mode dispatch

- `_mode: StringName` — `&"campaign"` hoặc `&"endless"`
- `start_endless()` — init endless_selector, set mode
- `start_level()` — dispatch theo mode
- `on_level_won()` — settlement khi endless

### 13.2 title_screen.gd — thêm nút Endless

### 13.3 nav_controller.gd — thêm route ENDLESS

### 13.4 progress_manager.gd — schema v2 → v3

Thêm `endless` block riêng biệt (không ảnh hưởng campaign data).

---

## 14. Content Pipeline

### 14.1 Source Data — 3 nhóm schema

| Nhóm | Source Format | Banks | Total Levels |
|------|-------------|-------|-------------|
| **A: Ranked dict** | `{"1":[…],"2":[…]}` — rank là key | Regular 4-12, LKStyle 7-12 | ~16k |
| **B: Flat sized** | `{"levels":[…]}` — cùng size, rank trong `r` | GC 6-12, OneFish 7-10, SuperHard | ~6.7k |
| **C: Flat mixed-size** | `{"levels":[…]}` — `size` per-entry, mixed | SP, LK, LKModified, SP_TT, SingleRegion | ~7k |

Mỗi entry đều có `regionMap` (int[][]), `solution`, `_pid_h`, `r` (rank), `r1-r5` (profile).
Một số bank có fields riêng: SP (`colorMap`, `pattern`, `spRegion`), SP_TT (`shapeCategory`), LK (`date`, `label`).

### 14.2 Output Schema — 2 variants

**Variant A — Ranked by size** (1 file per size, dùng cho Regular/LKStyle/GC/OneFish):
```json
{"bankVersion": 1, "size": 8, "ranks": {"1": [...], "2": [...]}}
```

**Variant B — Flat indexed** (1 file total, dùng cho SP/LK/LKModified/SP_TT/SingleRegion/SuperHard):
```json
{"bankVersion": 1, "type": "sp", "levels": [
  {"size": 7, "rank": 2, "shapeCategory": 3, "regions": [...], ...}
]}
```
Flat banks giữ `size` và `rank` per-entry. Fields riêng (shapeCategory, id, colorMap...) preserve.

### 14.3 Convert Tool

Mở rộng `tools/convert_extracted_bank.py`:
- `BANK_REGISTRY` dict tổ chức theo type, chứa source paths + output pattern + format + extra fields
- `convert_level_fast()`: dùng `r1-r5` profile trực tiếp, skip `solve()` — cho bulk convert (~30k levels)
- `convert_flat_bank()`: cho Variant B output
- CLI: `--type <bank_type>` + `--fast` flag

### 14.4 BankReader Extension

Thêm methods cho mỗi bank type — lazy load, cached per key.
Flat banks cần internal index `{size}_{rank}` → built once on first load.

---

## 15. Module Map

```
game/scripts/endless/
├── level_selector.gd                 # Entry point
├── endless_config.gd                 # Feature toggles + config loader
├── endless_progress.gd               # All cursor + stats persistence
│
├── strategy/
│   ├── selection_strategy.gd         # Base class
│   └── control_strategy.gd           # 4-tier decision + DDA
│
├── provider/
│   ├── special_provider.gd           # Milestone intercept (SP/LK)
│   ├── super_hard_provider.gd        # Super hard (11×11)
│   ├── single_region_provider.gd     # DDA support
│   ├── sp_tt_provider.gd             # Topology shape cycling
│   └── onefish_provider.gd           # Permadeath mode
│
├── pool/
│   ├── pool_source.gd                # Data class
│   ├── pool_builder.gd               # Register + assemble
│   └── pool_picker.gd                # Generic pick
│
├── context/
│   ├── select_context.gd
│   ├── size_schedule.gd
│   └── strategy_modifier.gd
│
├── cursor/
│   ├── bank_cursor.gd                # Base + factory
│   ├── main_cursor.gd                # Generic inject tracking
│   └── super_hard_cursor.gd          # Fixed, computed pos
│
├── delivery/
│   ├── puzzle_dedup.gd
│   └── level_validator.gd
│
└── settlement/
    └── settlement_handler.gd         # DDA adjustment

game/data/
├── endless_config.json               # Feature toggles
└── banks/                            # Converted from extracted_reusable
```

**Tổng: ~20 files GDScript, mỗi file ≤ 200 LOC.**

---

## 16. Testing Strategy

### Unit Tests

| Module | Key Cases |
|--------|-----------|
| EndlessConfig | Load, defaults, toggle on/off |
| PoolSource + PoolBuilder | Register, build, dynamic sources |
| PoolPicker | Injection, sequential, boundary |
| MainCursor | Inject_counters, rollover, transform |
| All providers | Config toggle, separate cursors |
| SettlementHandler | Win/loss → strategy adjust |
| SizeSchedule | Tutorial, transition, cycle |
| PuzzleDedup | FIFO eviction, duplicate detection |

### Integration Tests

- Full 4-tier decision: milestone → super_hard → DDA → main pool
- Feature toggle: disable provider → normal flow
- 100 consecutive selects → no crash, valid entries
- Convert pipeline: all bank files validate

---

## 17. Constraints

### In Scope (R1)

- Full 4-tier supply architecture
- Pool Registry with dynamic registration
- Feature toggles via endless_config.json
- 9 bank types (convert from extracted_reusable)
- DDA settlement (simple strategy adjustment)
- Endless as standalone mode (Title Screen)
- 8x transforms, dedup, relaxation

### Out of Scope

- A/B test framework (offline game — 1 strategy đủ)
- Runtime procedural generation (R2+)
- Remote config, analytics, IAP, ads
- Bank content generation (convert có sẵn, không sinh mới)

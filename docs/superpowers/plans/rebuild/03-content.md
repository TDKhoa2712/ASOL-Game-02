# Module 3: Content — Bank Loading, Pace & Level Processing

> **Phụ thuộc:** Module 1 (Core) cho `CandyRules.verify_level()`
> **Tham khảo:** `extracted_reusable/scripts/bank/` (4 files), `extracted_reusable/levels/bankData*.json` + `bankData*.pace.json`, `gameplay/core/level_generator.gd`

## Tổng quan

Module Content đọc, validate và xử lý level data theo kiến trúc **Bank + Pace + Transform**.

Reference có multi-bank system (BankData + LevelBankIO + BankSorter, XOR encryption, AB sorting, 5 cursor classes) phục vụ hàng trăm levels với A/B test. Rebuild giữ cơ chế bank rank-based và pace sidecar nhưng bỏ encryption, AB sorting, multi-source banks.

### Kiến trúc level data

```
game/data/
├── banks/
│   ├── bank_4x4.json          # Level bank 4×4 theo rank
│   ├── bank_4x4.pace.json     # Pace sidecar (hint costs)
│   ├── bank_5x5.json
│   ├── bank_5x5.pace.json
│   ├── bank_6x6.json
│   └── bank_6x6.pace.json
└── campaigns/
    └── demo_30.json            # Playlist tham chiếu vào banks
```

### Schema: Bank file (`bank_{N}x{N}.json`)

> **Lưu ý:** Bank levels là superset của GDD level v4. Bank-only fields (`seed`, `steps`, `profile`, `rating`, `pidHash`) là pipeline metadata. `bank_reader.get_level()` trả level v4 fields cho gameplay consumers; bank-only fields chỉ dùng trong pipeline.

```json
{
  "bankVersion": 1,
  "size": 4,
  "ranks": {
    "1": [
      {
        "seed": 7,
        "regions": ["DDAC", "BCDD", "DDCD", "DDDC"],
        "solution": [1, 3, 0, 2],
        "givens": [],
        "steps": 4,
        "profile": [4, 0, 0],
        "rating": 4,
        "pidHash": "6c95fe9a",
        "logicTrace": [
          {"rule": "S2", "focus": {"type": "region", "id": "A"}, "conclusion": {"type": "place", "r": 0, "c": 2}, "textKey": "hint.single.region"}
        ]
      }
    ],
    "2": [...],
    "3": [...]
  }
}
```

| Field | Type | Nguồn | Mục đích |
|-------|------|-------|----------|
| `seed` | int | Reference | Generator seed, unique ID |
| `regions` | string[] | CanDoKu | String encoding compact ("DDAC" thay [[3,3,0,2]]) |
| `solution` | int[] | CanDoKu | `solution[row] = col` (permutation) |
| `givens` | [{r,c}] | CanDoKu | Pre-placed candies |
| `steps` | int | Reference | Total solver steps |
| `profile` | int[3] | Merged | `[s2_count, s3_count, 0]` — step counts per technique |
| `rating` | int | Reference | Numeric difficulty score |
| `pidHash` | string | Reference | Puzzle identity hash for dedup |
| `logicTrace` | array | CanDoKu | Machine-verifiable proof chain (S2/S3 steps) |

### Schema: Pace sidecar (`bank_{N}x{N}.pace.json`)

```json
{
  "bankVersion": 1,
  "size": 4,
  "pacing": {
    "1": [
      {
        "rSeq": [1, 1, 1, 1],
        "hintCosts": [1, 1, 1, 1]
      }
    ],
    "2": [
      {
        "rSeq": [2, 1, 1, 1],
        "hintCosts": [2, 1, 1, 1]
      }
    ]
  }
}
```

| Field | Type | Mục đích |
|-------|------|----------|
| `rSeq` | int[] | Nhịp độ logic mỗi bước (rank của technique tại bước đó) |
| `hintCosts` | int[] | Số hint clicks cần cho mỗi bước (calibrate hint economy) |

**Không có `g1`..`g4`** — bỏ A/B test scoring.

Pace entries 1:1 positional với bank entries (validated at load time).

### Schema: Campaign playlist (`demo_30.json`)

```json
{
  "campaignVersion": 1,
  "id": "demo-30",
  "playlist": [
    {"size": 4, "rank": 1, "index": 0, "label": "L01", "difficulty": "tutorial"},
    {"size": 4, "rank": 1, "index": 2, "label": "L02", "difficulty": "tutorial"},
    {"size": 4, "rank": 2, "index": 0, "label": "L03", "difficulty": "easy"},
    {"size": 5, "rank": 1, "index": 0, "label": "L04", "difficulty": "easy"},
    {"size": 5, "rank": 2, "index": 1, "label": "L05", "difficulty": "medium"}
  ]
}
```

Campaign **không chứa level data** — chỉ tham chiếu (size, rank, index) vào bank.

---

## File 1: `game/scripts/content/bank_reader.gd`

**Trách nhiệm:** Load, cache và query level banks theo size + rank.

**Tham khảo hành vi từ:** `bank/model/level_bank_io.gd` (load JSON) + `bank/model/bank_data.gd` (cache + query)

```gdscript
# bank_reader.gd
extends RefCounted

const LevelValidator = preload("res://scripts/content/level_validator.gd")

const BANK_DIR := "res://data/banks/"
const BANK_VERSION := 1

var _cache: Dictionary = {}   # "4_1" → Array of level dicts

# --- Public API ---

func load_bank(size: int) -> Dictionary
    # Returns {ok: bool, errors: Array[String]}
    # Reads bank_{size}x{size}.json, validates bankVersion + structure
    # Caches levels by composite key "{size}_{rank}"

func get_levels(size: int, rank: int) -> Array
    # Returns cached level array for (size, rank). Empty if not loaded.

func get_level(size: int, rank: int, index: int) -> Dictionary
    # Returns single level dict. {} if out of bounds.

func level_count(size: int, rank: int) -> int
    # Returns number of levels in (size, rank) bucket.

func total_count(size: int) -> int
    # Returns total levels across all ranks for a size.

func available_sizes() -> Array[int]
    # Returns sizes that have been loaded.

func clear_cache() -> void

# --- Internal ---

func _bank_path(size: int) -> String
    return BANK_DIR + "bank_%dx%d.json" % [size, size]

func _parse_bank(path: String) -> Dictionary
    # Read JSON, validate bankVersion, parse ranks dict

func _validate_bank(data: Dictionary, size: int) -> Array[String]
    # Check bankVersion, size matches, each rank array valid
    # Delegate per-level validation to LevelValidator
```

**Khác biệt với reference:**
- Tên: `BankReader` thay `BankData` + `LevelBankIO`
- 1 file thay 3 (IO + Data + Sorter)
- Không XOR encryption
- Không multi-source banks (regular + lkstyle + gc)
- Không AB sorting — levels returned in bank order
- Instance-based (RefCounted), not static singleton
- String regions + logicTrace (CanDoKu schema)

---

## File 2: `game/scripts/content/pace_reader.gd`

**Trách nhiệm:** Load pace sidecar, validate 1:1 with bank, query hint costs.

**Tham khảo hành vi từ:** `bank/model/bank_data.gd` → `get_pace_entry()`

```gdscript
# pace_reader.gd
extends RefCounted

const BANK_DIR := "res://data/banks/"

var _cache: Dictionary = {}   # "4_1" → Array of pace entries

# --- Public API ---

func load_pace(size: int) -> Dictionary
    # Returns {ok: bool, errors: Array[String]}
    # Reads bank_{size}x{size}.pace.json
    # Validates bankVersion, size, pacing structure

func get_pace(size: int, rank: int, index: int) -> Dictionary
    # Returns {rSeq: int[], hintCosts: int[]} or {} if missing

func validate_against_bank(bank: BankReader, size: int) -> Array[String]
    # Check 1:1 positional correspondence:
    # pace[rank].size() == bank.level_count(size, rank) for each rank

func clear_cache() -> void

# --- Internal ---

func _pace_path(size: int) -> String
    return BANK_DIR + "bank_%dx%d.pace.json" % [size, size]
```

**Khác biệt với reference:**
- Tách riêng thành file (reference nhúng trong BankData)
- Không g1-g4 A/B scores
- `validate_against_bank()` explicit (reference check implicit in load)

---

## File 3: `game/scripts/content/level_validator.gd`

> **Phân công validation:** M01 `candy_rules.verify_level()` kiểm tra structural (size, regions, solution, adjacency, zone uniqueness). M03 `level_validator.check()` kiểm tra full schema v4 (bao gồm trace, givens validation, id format). `check_bank_level()` thêm bank-specific fields.

**Trách nhiệm:** Schema validation cho individual level entries.

**Tham khảo hành vi từ:** `validate_levels.py` (Python) → GDScript port

```gdscript
# level_validator.gd
extends RefCounted

const CandyRules = preload("res://scripts/core/candy_rules.gd")

# --- Public API ---

static func check(level: Dictionary) -> Dictionary
    # Returns {ok: bool, errors: Array[String]}
    # Validates: required fields, types, size range, regions format,
    # solution bounds, givens valid, logicTrace optional

static func check_bank_level(level: Dictionary) -> Dictionary
    # Validates bank-specific fields: seed, steps, profile, rating, pidHash

static func check_id(level_id: String) -> bool
    # ID must match [A-Z0-9_-]+ pattern

# --- Validation steps ---

static func _check_schema(level: Dictionary) -> Array[String]
    # Required: regions, solution, givens
    # Bank fields: seed, steps, profile, rating, pidHash
    # Optional: logicTrace

static func _check_geometry(level: Dictionary) -> Array[String]
    # size 4-12, regions NxN strings, solution N entries, each 0..N-1

static func _check_rules(level: Dictionary) -> Array[String]
    # Delegates to CandyRules.verify_level() for full rule check
```

---

## File 4: `game/scripts/content/board_transform.gd`

**Trách nhiệm:** Apply rotation/mirror transforms to level data. ×8 transforms nhân content.

**Tham khảo hành vi từ:** `gameplay/selector/cursor/main_bank_cursor.gd` → `transform` counter

```gdscript
# board_transform.gd
extends RefCounted

enum Transform {
    IDENTITY,       # 0: original
    ROTATE_90,      # 1: rotate 90° CW
    ROTATE_180,     # 2: rotate 180°
    ROTATE_270,     # 3: rotate 270° CW
    MIRROR_H,       # 4: mirror horizontal
    MIRROR_H_R90,   # 5: mirror + rotate 90°
    MIRROR_H_R180,  # 6: mirror + rotate 180°
    MIRROR_H_R270,  # 7: mirror + rotate 270°
}

const TRANSFORM_COUNT := 8

# --- Public API ---

static func apply(level: Dictionary, t: int) -> Dictionary
    # Returns a NEW level dict with regions/solution/givens/logicTrace
    # transformed. Original untouched.
    # t must be 0..7 (modulo TRANSFORM_COUNT)

static func transform_regions(regions: Array, n: int, t: int) -> Array
    # Apply geometric transform to region string array
    # Returns new Array of strings

static func transform_solution(solution: Array, regions_before: Array, regions_after: Array, n: int) -> Array
    # Remap solution to match transformed regions
    # solution[row] = col → solution'[row'] = col'

static func transform_cell(r: int, c: int, n: int, t: int) -> Array
    # Returns [r', c'] after transform

static func transform_givens(givens: Array, n: int, t: int) -> Array
    # Apply transform to each given {r, c}

# --- Internal ---

static func _rotate_90(r: int, c: int, n: int) -> Array
    return [c, n - 1 - r]

static func _mirror_h(r: int, c: int, n: int) -> Array
    return [r, n - 1 - c]

static func _compose(r: int, c: int, n: int, t: int) -> Array
    # Compose mirror + rotation based on transform index
    var rr := r
    var cc := c
    if t >= 4:
        var m := _mirror_h(rr, cc, n)
        rr = m[0]; cc = m[1]
    var rot := t % 4
    for i in rot:
        var p := _rotate_90(rr, cc, n)
        rr = p[0]; cc = p[1]
    return [rr, cc]
```

**Khác biệt với reference:**
- Tách riêng file thay nhúng trong cursor
- `apply()` trả level dict mới (functional, không mutate)
- Works with string regions (CanDoKu encoding)
- `Transform` enum thay implicit int counter
- Không cần seed-based transform selection

**Ý nghĩa scale:** Bank 36 levels × 8 transforms = 288 plays chỉ cho 4×4. Across sizes: hàng nghìn plays từ vài trăm bank entries.

---

## File 5: `game/scripts/content/region_painter.gd`

**Trách nhiệm:** Gán màu cho regions sao cho regions kề nhau khác biệt tối đa.

**Tham khảo hành vi từ:** `gameplay/core/level_generator.gd` (LAB distance graph coloring)

```gdscript
# region_painter.gd
extends RefCounted

# --- Public API ---

static func assign_colors(size: int, zones: Array, palette: Array[Color]) -> Dictionary
    # Returns {zone_label: Color} — greedy graph coloring maximizing LAB distance
    # Input: zones is Array of strings (e.g. ["AABB", "ABBB", ...])

static func precompute_grid(size: int, zones: Array) -> Array
    # Returns NxN Array of zone label strings

# --- Color science ---

static func lab_distance(a: Color, b: Color) -> float
    # CIE76 Delta-E distance

static func to_lab(c: Color) -> Array
    # sRGB → linear → XYZ (D65) → LAB

# --- Internal ---

static func _build_adjacency(size: int, grid: Array) -> Dictionary
static func _linearize(v: float) -> float
static func _lab_transfer(t: float) -> float
```

(Unchanged from previous plan — region painting is orthogonal to bank architecture.)

---

## Tests

### `game/tests/test_bank_reader.gd`

```gdscript
extends SceneTree

const BankReader = preload("res://scripts/content/bank_reader.gd")
const PaceReader = preload("res://scripts/content/pace_reader.gd")
const LevelValidator = preload("res://scripts/content/level_validator.gd")
const BoardTransform = preload("res://scripts/content/board_transform.gd")
const RegionPainter = preload("res://scripts/content/region_painter.gd")

var _fails: Array[String] = []

func _init() -> void:
    _test_validate_good_level()
    _test_reject_bad_size()
    _test_reject_bad_solution()
    _test_load_bank_4x4()
    _test_pace_1to1()
    _test_transform_identity()
    _test_transform_rotate90()
    _test_transform_all_8_unique()
    _test_region_painter_colors()
    _test_lab_distance()
    if _fails.is_empty():
        print("CONTENT_PASS")
        quit(0)
    else:
        for f in _fails: printerr(f)
        quit(1)

func _test_validate_good_level() -> void:
    var result := LevelValidator.check(_sample_bank_level())
    _assert(result["ok"], "valid level passes")

func _test_reject_bad_size() -> void:
    var level := _sample_bank_level()
    level["regions"] = ["AAB"]  # size 3
    var result := LevelValidator.check(level)
    _assert(not result["ok"], "size 3 rejected")

func _test_reject_bad_solution() -> void:
    var level := _sample_bank_level()
    level["solution"] = [1, 1, 0, 2]  # duplicate column
    var result := LevelValidator.check(level)
    _assert(not result["ok"], "duplicate column rejected")

func _test_load_bank_4x4() -> void:
    var reader := BankReader.new()
    var result := reader.load_bank(4)
    _assert(result["ok"], "bank 4x4 loads")
    _assert(reader.level_count(4, 1) > 0, "rank 1 has levels")
    _assert(reader.total_count(4) > 0, "total levels > 0")
    var level := reader.get_level(4, 1, 0)
    _assert(level.has("regions"), "level has regions")
    _assert(level["regions"][0] is String, "regions are strings")

func _test_pace_1to1() -> void:
    var bank := BankReader.new()
    bank.load_bank(4)
    var pace := PaceReader.new()
    pace.load_pace(4)
    var errors := pace.validate_against_bank(bank, 4)
    _assert(errors.is_empty(), "pace matches bank: %s" % str(errors))

func _test_transform_identity() -> void:
    var level := _sample_bank_level()
    var t := BoardTransform.apply(level, BoardTransform.Transform.IDENTITY)
    _assert(t["regions"] == level["regions"], "identity preserves regions")
    _assert(t["solution"] == level["solution"], "identity preserves solution")

func _test_transform_rotate90() -> void:
    var regions := ["AB", "CD"]
    var rotated := BoardTransform.transform_regions(regions, 2, BoardTransform.Transform.ROTATE_90)
    # After 90° CW rotation of 2x2: row0 becomes last col, etc.
    _assert(rotated[0] == "CA", "rotate90 row0")
    _assert(rotated[1] == "DB", "rotate90 row1")

func _test_transform_all_8_unique() -> void:
    var level := _sample_bank_level()
    var seen: Array[String] = []
    for t in 8:
        var transformed := BoardTransform.apply(level, t)
        var key := "".join(transformed["regions"])
        _assert(key not in seen, "transform %d unique" % t)
        seen.append(key)

func _test_region_painter_colors() -> void:
    var zones := ["AABB", "ABBB", "CCBB", "CCDB"]
    var palette: Array[Color] = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.CYAN]
    var colors := RegionPainter.assign_colors(4, zones, palette)
    _assert(colors.size() == 4, "4 zones get colors")
    _assert(colors.get("A") != colors.get("B"), "A and B different")

func _test_lab_distance() -> void:
    var d := RegionPainter.lab_distance(Color.RED, Color.BLUE)
    _assert(d > 50.0, "red-blue far in LAB")
    var d2 := RegionPainter.lab_distance(Color.RED, Color.RED)
    _assert(d2 < 0.01, "same color zero distance")

func _sample_bank_level() -> Dictionary:
    return {
        "seed": 1,
        "regions": ["AABB", "ABBB", "CCBB", "CCDB"],
        "solution": [1, 3, 0, 2], "givens": [],
        "steps": 4, "profile": [4, 0, 0], "rating": 4,
        "pidHash": "test1234",
        "logicTrace": []
    }

func _assert(cond: bool, label: String) -> void:
    if not cond:
        _fails.append("FAIL: " + label)
```

---

## Checklist thực hiện

- [ ] Tạo thư mục `game/scripts/content/`
- [ ] Tạo thư mục `game/data/banks/` và `game/data/campaigns/`
- [ ] Viết `level_validator.gd`
- [ ] Viết `board_transform.gd` (×8 rotation/mirror)
- [ ] Viết test `test_bank_reader.gd` (fail)
- [ ] Viết `bank_reader.gd`
- [ ] Viết `pace_reader.gd`
- [ ] Viết `region_painter.gd` (LAB distance + graph coloring)
- [ ] Tạo bank data mẫu: `bank_4x4.json`, `bank_4x4.pace.json` (convert từ campaign_m1.json)
- [ ] Tạo campaign playlist: `demo_30.json` (placeholder 4 entries)
- [ ] Chạy test → pass
- [ ] Commit: `feat(content): add bank reader, pace reader, transforms and region painter`

# Module 1: Core — Domain Logic

> **Phụ thuộc:** Không. Module đầu tiên, nền tảng cho tất cả module khác.
> **Tham khảo:** `extracted_reusable/scripts/gameplay/core/`, `gameplay/model/cell_state.gd`, `gameplay/core/hint_engine.gd`

## Tổng quan

Module Core chứa toàn bộ luật puzzle CanDoKu: trạng thái ô, phát hiện vi phạm, kiểm tra thắng/thua, hệ thống gợi ý, auto-mark. Tất cả đều là static functions, không phụ thuộc UI hay Godot scene.

---

## File 1: `game/scripts/core/cell_model.gd`

**Trách nhiệm:** Định nghĩa trạng thái ô và helper methods.

**Tham khảo hành vi từ:** `gameplay/model/cell_state.gd` (7 states, helpers)

**Thiết kế mới:**
- 6 states: BLANK, MARK, CANDY, WRONG, GIVEN, LOCKED (thêm GIVEN + LOCKED từ reference)
- GIVEN: candy cho trước, immutable, visual khác
- LOCKED: system auto-mark sau khi đặt candy, player không thể xóa
- Tên enum và values hoàn toàn mới

```gdscript
# cell_model.gd
extends RefCounted

enum CellKind {
    BLANK = 0,      # Ô trống, chưa đánh dấu
    MARK = 1,       # Player đánh X (xóa được)
    CANDY = 2,      # Candy đặt đúng
    WRONG = 3,      # Candy đặt sai (hiện X đỏ)
    GIVEN = 4,      # Candy cho trước (from givens, immutable)
    LOCKED = 5,     # System auto-mark sau candy (player không xóa được)
}

static func is_empty(kind: int) -> bool:
    return kind == CellKind.BLANK

static func is_placed(kind: int) -> bool:
    return kind == CellKind.CANDY or kind == CellKind.GIVEN

static func is_candy(kind: int) -> bool:
    return kind == CellKind.CANDY or kind == CellKind.GIVEN

static func is_cross(kind: int) -> bool:
    return kind == CellKind.MARK or kind == CellKind.WRONG or kind == CellKind.LOCKED

static func is_locked(kind: int) -> bool:
    return kind == CellKind.GIVEN or kind == CellKind.LOCKED

static func is_available(kind: int) -> bool:
    # Can player interact with this cell?
    return kind == CellKind.BLANK or kind == CellKind.MARK

static func label(kind: int) -> String:
    match kind:
        CellKind.BLANK: return "blank"
        CellKind.MARK: return "mark"
        CellKind.CANDY: return "candy"
        CellKind.WRONG: return "wrong"
        CellKind.GIVEN: return "given"
        CellKind.LOCKED: return "locked"
    return "unknown"
```

**Khác biệt với reference:**
- 6 states thay 7 (bỏ DRAFT_CROSS, DRAFT_CAT — không cần cho playtest)
- Tên: CellKind thay CellState, BLANK thay EMPTY, WRONG thay ERROR, LOCKED thay LOCKED_MARK
- Thêm GIVEN (reference dùng implicit check, không có state riêng)
- `is_available()` — player chỉ interact được với BLANK/MARK
- `is_locked()` — GIVEN + LOCKED đều immutable
- `is_candy()` — cả CANDY và GIVEN đều là candy (cho solver)

---

## File 2: `game/scripts/core/candy_rules.gd`

**Trách nhiệm:** Luật puzzle — phát hiện vi phạm, auto-mark, kiểm tra thắng/thua, tính điểm.

**Tham khảo hành vi từ:** `gameplay/core/queendoku_core.gd`, `hint_engine.gd` → auto-mark logic

**Thiết kế mới:**

```gdscript
# candy_rules.gd
extends RefCounted

const CellModel = preload("res://scripts/core/cell_model.gd")

enum Clash { NONE, SAME_ROW, SAME_COL, SAME_ZONE, TOUCHING }

const CLASH_RANK := [Clash.SAME_ROW, Clash.SAME_COL, Clash.SAME_ZONE, Clash.TOUCHING]

# --- Grid helpers ---

static func grid_key(row: int, col: int) -> String
static func in_range(level: Dictionary, row: int, col: int) -> bool
static func is_preset(level: Dictionary, row: int, col: int) -> bool
static func zone_of(level: Dictionary, row: int, col: int) -> String
static func cell_kind(level: Dictionary, cells: Dictionary, row: int, col: int) -> String

# --- Clash detection ---

static func detect_clash(level: Dictionary, a: Array, b: Array) -> int
    # Returns Clash enum: SAME_ROW, SAME_COL, SAME_ZONE, TOUCHING, or NONE

static func find_all_clashes(level: Dictionary, cells: Dictionary) -> Array

static func worst_clash_for(level: Dictionary, cells: Dictionary, target: Array) -> Dictionary

# --- Auto-mark (NEW — from reference R1 Mark) ---

static func compute_auto_marks(level: Dictionary, cells: Dictionary, candy_row: int, candy_col: int) -> Array
    # After placing candy at (candy_row, candy_col), returns list of cells
    # to auto-mark as LOCKED: same row, same col, same zone, diagonal neighbors.
    # Only marks cells that are currently BLANK.
    # Returns Array of [row, col] pairs.

static func compute_all_auto_marks(level: Dictionary, cells: Dictionary) -> Array
    # For ALL placed candies, compute which blank cells should be LOCKED.
    # Used when restoring session or after undo to recompute locks.

# --- Game actions ---

static func attempt_candy(level: Dictionary, cells: Dictionary, lives: int, errors: int, target: Array) -> Dictionary
    # Main game action. Returns:
    # {cells, lives, errors, outcome, events, clash_label, auto_marks: Array}
    # auto_marks: cells that should be set to LOCKED after this action

# --- Scoring ---

static func tally(correct_count: int, error_count: int) -> int
static func correct_count(level: Dictionary, cells: Dictionary) -> int

# --- Validation ---

static func verify_level(level: Dictionary) -> bool
```

**Khác biệt với reference:**
- **compute_auto_marks()** — NEW. Sau khi đặt candy, tính tất cả ô cần lock (same row/col/zone/diagonal). Reference nhúng trong R1 Mark của hint_engine; chúng ta tách thành API riêng.
- **attempt_candy() trả auto_marks** — caller (PlaySession) dùng để apply LOCKED states
- Tên: `Clash` thay `Violation`, `auto_marks` thay `r1_mark`

---

## File 3: `game/scripts/core/board_solver.gd`

**Trách nhiệm:** Hint engine — tìm gợi ý cho người chơi, hỗ trợ progressive reveal với hintCosts.

**Tham khảo hành vi từ:** `gameplay/core/hint_engine.gd` (1257 dòng, R1-R5, stateless static)

**Phạm vi playtest:** 3 chiến thuật (S1, S2, S3 — tương đương R1, R2, R3)

**Thiết kế mới:**

```gdscript
# board_solver.gd
extends RefCounted

const CellModel = preload("res://scripts/core/cell_model.gd")
const CandyRules = preload("res://scripts/core/candy_rules.gd")

enum Technique { ELIMINATION, SINGLE_CANDIDATE, ZONE_LINE }

# --- Public API ---

static func next_hint(board: Array, size: int, zones: Array, solution: Array) -> Dictionary
    # Tries techniques in order: elimination → single_candidate → zone_line
    # Returns {
    #   found: bool,
    #   technique: int,
    #   cell: Array,           # [row, col] of target cell
    #   zone: String,          # zone label (for progressive reveal step 1)
    #   unit_type: String,     # "zone"|"row"|"col" (which unit to highlight)
    #   unit_id: Variant,      # zone label or row/col index
    #   explanation: String,
    # }

static func progressive_hint(board: Array, size: int, zones: Array, solution: Array, click: int, max_clicks: int) -> Dictionary
    # Progressive reveal based on hint economy (from pace hintCosts).
    # click 1: highlight unit (zone/row/col)
    # click 2+: narrow to specific cell
    # Returns {stage: "unit"|"cell"|"place", highlight: Array, text: String}

static func solve_sequence(size: int, zones: Array, solution: Array) -> Array[int]
    # Returns technique level used for each solution cell placement

static func compute_cell_ranks(board: Array, size: int, zones: Array, solution: Array) -> Dictionary
    # Returns {grid_key: rank} — difficulty rank per unsolved cell
    # rank 1 = S1 reachable, 2 = needs S2, 3 = needs S3

# --- Techniques ---

static func _try_elimination(board: Array, size: int, zones: Array) -> Dictionary
    # S1: Find cells that can be marked X around placed candies

static func _try_single_candidate(board: Array, size: int, zones: Array, solution: Array) -> Dictionary
    # S2: Find zone/row/col with only one possible candy position
    # Returns unit_type + unit_id for progressive reveal

static func _try_zone_line(board: Array, size: int, zones: Array) -> Dictionary
    # S3: If all candidates for a zone lie in one row/col,
    # eliminate other candidates in that row/col

# --- Helpers ---

static func _candidates_in_zone(board: Array, size: int, zones: Array, zone_label: String) -> Array
static func _candidates_in_row(board: Array, size: int, zones: Array, row: int) -> Array
static func _candidates_in_col(board: Array, size: int, zones: Array, col: int) -> Array
static func _is_candidate(board: Array, size: int, zones: Array, row: int, col: int) -> bool
static func _can_place(board: Array, size: int, zones: Array, row: int, col: int) -> bool
    # Core constraint check: cell empty, no candy in row/col/zone, no adjacent candy
```

**Khác biệt với reference:**
- 3 techniques thay 5+ (bỏ R4 subset, R5 chain)
- **progressive_hint()** — NEW. Dùng hintCosts từ pace để reveal dần. Reference không có API này trực tiếp; hint_engine cung cấp building blocks mà caller tự compose.
- **compute_cell_ranks()** — Từ reference `compute_cell_ranks()`, gán difficulty mỗi ô
- `_can_place()` — Từ reference, core constraint check reused bởi tất cả techniques
- `next_hint` trả `unit_type`/`unit_id` cho progressive reveal (step 1: highlight unit)
- Tên: `Technique` thay implicit, `ELIMINATION`/`SINGLE_CANDIDATE`/`ZONE_LINE` thay `R1`/`R2`/`R3`
- Stateless static (giống reference)

---

## Tests

### `game/tests/test_candy_rules.gd`

```gdscript
extends SceneTree

const CellModel = preload("res://scripts/core/cell_model.gd")
const CandyRules = preload("res://scripts/core/candy_rules.gd")

var _fails: Array[String] = []

func _init() -> void:
    _test_cell_model()
    _test_cell_model_given_locked()
    _test_grid_key()
    _test_detect_clash()
    _test_find_all_clashes()
    _test_attempt_candy_correct()
    _test_attempt_candy_wrong()
    _test_attempt_candy_win()
    _test_attempt_candy_last_life()
    _test_auto_marks()
    _test_auto_marks_skip_locked()
    _test_tally()
    _test_verify_level()
    if _fails.is_empty():
        print("CORE_CANDY_RULES_PASS")
        quit(0)
    else:
        for f in _fails: printerr(f)
        quit(1)

func _test_cell_model() -> void:
    _assert(CellModel.is_empty(CellModel.CellKind.BLANK), "blank is empty")
    _assert(not CellModel.is_empty(CellModel.CellKind.CANDY), "candy not empty")
    _assert(CellModel.is_placed(CellModel.CellKind.CANDY), "candy is placed")
    _assert(CellModel.is_placed(CellModel.CellKind.GIVEN), "given is placed")
    _assert(CellModel.label(CellModel.CellKind.WRONG) == "wrong", "wrong label")

func _test_cell_model_given_locked() -> void:
    _assert(CellModel.is_locked(CellModel.CellKind.GIVEN), "given is locked")
    _assert(CellModel.is_locked(CellModel.CellKind.LOCKED), "locked is locked")
    _assert(not CellModel.is_available(CellModel.CellKind.GIVEN), "given not available")
    _assert(not CellModel.is_available(CellModel.CellKind.LOCKED), "locked not available")
    _assert(CellModel.is_available(CellModel.CellKind.BLANK), "blank is available")
    _assert(CellModel.is_available(CellModel.CellKind.MARK), "mark is available")
    _assert(CellModel.is_cross(CellModel.CellKind.LOCKED), "locked is cross")
    _assert(CellModel.is_candy(CellModel.CellKind.GIVEN), "given is candy")

func _test_grid_key() -> void:
    _assert(CandyRules.grid_key(2, 3) == "2,3", "grid key format")

func _test_detect_clash() -> void:
    var level := _make_level_4x4()
    _assert(CandyRules.detect_clash(level, [0, 0], [0, 2]) == CandyRules.Clash.SAME_ROW, "same row")
    _assert(CandyRules.detect_clash(level, [0, 0], [2, 0]) == CandyRules.Clash.SAME_COL, "same col")
    _assert(CandyRules.detect_clash(level, [0, 0], [1, 1]) == CandyRules.Clash.TOUCHING, "diagonal touching")
    _assert(CandyRules.detect_clash(level, [0, 0], [2, 2]) == CandyRules.Clash.NONE, "no clash")

func _test_find_all_clashes() -> void:
    var level := _make_level_4x4()
    var cells := {"0,1": "candy", "0,3": "candy"}
    var clashes := CandyRules.find_all_clashes(level, cells)
    _assert(clashes.size() == 2, "two cells in clash")

func _test_attempt_candy_correct() -> void:
    var level := _make_level_4x4()
    var result := CandyRules.attempt_candy(level, {}, 3, 0, [0, 1])
    _assert(result["events"].has("CandyFound"), "correct placement event")
    _assert(result["outcome"] == "Playing", "still playing")
    _assert(result["auto_marks"].size() > 0, "auto marks generated")

func _test_attempt_candy_wrong() -> void:
    var level := _make_level_4x4()
    var result := CandyRules.attempt_candy(level, {}, 3, 0, [0, 0])
    _assert(result["events"].has("Mistake"), "wrong placement event")
    _assert(result["lives"] == 2, "lost a life")

func _test_attempt_candy_win() -> void:
    var level := _make_level_4x4()
    var cells := {}
    for row in range(4):
        if row < 3:
            cells[CandyRules.grid_key(row, int(level["solution"][row]))] = "candy"
    var result := CandyRules.attempt_candy(level, cells, 3, 0, [3, int(level["solution"][3])])
    _assert(result["outcome"] == "Won", "level won")

func _test_attempt_candy_last_life() -> void:
    var level := _make_level_4x4()
    var result := CandyRules.attempt_candy(level, {}, 1, 2, [0, 0])
    _assert(result["outcome"] == "Lost", "game over on last life")

func _test_auto_marks() -> void:
    var level := _make_level_4x4()
    var cells := {}
    var marks := CandyRules.compute_auto_marks(level, cells, 0, 1)
    # After placing at (0,1), should mark: same row (0,0), (0,2), (0,3),
    # same col (1,1), (2,1), (3,1), diagonal (1,0), (1,2), same zone cells
    _assert(marks.size() > 0, "auto marks not empty")
    # Row 0 other cells should be marked
    _assert([0, 0] in marks, "row 0 col 0 marked")
    _assert([0, 2] in marks, "row 0 col 2 marked")

func _test_auto_marks_skip_locked() -> void:
    var level := _make_level_4x4()
    var cells := {CandyRules.grid_key(0, 0): "locked"}
    var marks := CandyRules.compute_auto_marks(level, cells, 0, 1)
    # (0,0) already locked, should not be in marks
    _assert([0, 0] not in marks, "already locked cell skipped")

func _test_tally() -> void:
    _assert(CandyRules.tally(4, 0) == 400, "perfect score")
    _assert(CandyRules.tally(4, 2) == 350, "score with errors")
    _assert(CandyRules.tally(0, 10) == 0, "no negative score")

func _test_verify_level() -> void:
    _assert(CandyRules.verify_level(_make_level_4x4()), "valid level passes")

func _make_level_4x4() -> Dictionary:
    return {
        "size": 4,
        "regions": ["AABB", "ABBB", "CCBB", "CCDB"],
        "solution": [1, 3, 0, 2],
        "givens": []
    }

func _assert(condition: bool, label: String) -> void:
    if not condition:
        _fails.append("FAIL: " + label)
```

### `game/tests/test_board_solver.gd`

```gdscript
extends SceneTree

const BoardSolver = preload("res://scripts/core/board_solver.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")

var _fails: Array[String] = []

func _init() -> void:
    _test_next_hint_empty_board()
    _test_next_hint_after_placement()
    _test_next_hint_returns_unit_info()
    _test_progressive_hint_stages()
    _test_solve_sequence()
    _test_compute_cell_ranks()
    if _fails.is_empty():
        print("CORE_BOARD_SOLVER_PASS")
        quit(0)
    else:
        for f in _fails: printerr(f)
        quit(1)

func _test_next_hint_empty_board() -> void:
    var board := _empty_board(4)
    var zones := ["AABB", "ABBB", "CCBB", "CCDB"]
    var solution := [1, 3, 0, 2]
    var hint := BoardSolver.next_hint(board, 4, zones, solution)
    _assert(hint["found"], "hint found on empty board")

func _test_next_hint_after_placement() -> void:
    var board := _empty_board(4)
    board[0][1] = CellModel.CellKind.CANDY
    var zones := ["AABB", "ABBB", "CCBB", "CCDB"]
    var solution := [1, 3, 0, 2]
    var hint := BoardSolver.next_hint(board, 4, zones, solution)
    _assert(hint["found"], "hint after placement")

func _test_next_hint_returns_unit_info() -> void:
    var board := _empty_board(4)
    var zones := ["AABB", "ABBB", "CCBB", "CCDB"]
    var solution := [1, 3, 0, 2]
    var hint := BoardSolver.next_hint(board, 4, zones, solution)
    _assert(hint.has("unit_type"), "hint has unit_type")
    _assert(hint["unit_type"] in ["zone", "row", "col"], "valid unit_type")

func _test_progressive_hint_stages() -> void:
    var board := _empty_board(4)
    var zones := ["AABB", "ABBB", "CCBB", "CCDB"]
    var solution := [1, 3, 0, 2]
    var h1 := BoardSolver.progressive_hint(board, 4, zones, solution, 1, 2)
    _assert(h1["stage"] == "unit", "first click shows unit")
    var h2 := BoardSolver.progressive_hint(board, 4, zones, solution, 2, 2)
    _assert(h2["stage"] == "cell" or h2["stage"] == "place", "second click shows cell")

func _test_solve_sequence() -> void:
    var zones := ["AABB", "ABBB", "CCBB", "CCDB"]
    var solution := [1, 3, 0, 2]
    var seq := BoardSolver.solve_sequence(4, zones, solution)
    _assert(seq.size() == 4, "sequence has 4 steps")

func _test_compute_cell_ranks() -> void:
    var board := _empty_board(4)
    var zones := ["AABB", "ABBB", "CCBB", "CCDB"]
    var solution := [1, 3, 0, 2]
    var ranks := BoardSolver.compute_cell_ranks(board, 4, zones, solution)
    _assert(ranks.size() > 0, "ranks computed")

func _empty_board(size: int) -> Array:
    var board: Array = []
    for r in range(size):
        var row: Array = []
        for c in range(size):
            row.append(CellModel.CellKind.BLANK)
        board.append(row)
    return board

func _assert(condition: bool, label: String) -> void:
    if not condition:
        _fails.append("FAIL: " + label)
```

---

## Checklist thực hiện

- [ ] Tạo thư mục `game/scripts/core/`
- [ ] Viết `cell_model.gd` — CellKind enum (6 states) + helpers
- [ ] Viết test `test_candy_rules.gd` (fail trước)
- [ ] Viết `candy_rules.gd` — clash detection, auto_marks, attempt_candy, verify_level
- [ ] Chạy test → pass
- [ ] Viết test `test_board_solver.gd` (fail trước)
- [ ] Viết `board_solver.gd` — next_hint, progressive_hint, compute_cell_ranks
- [ ] Chạy test → pass
- [ ] Commit: `feat(core): add puzzle rules with auto-mark and progressive hint solver`

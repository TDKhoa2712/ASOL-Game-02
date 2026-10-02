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

**Trách nhiệm:** Luật puzzle — kiểm tra đặt candy (solution-based), phát hiện vi phạm (giải thích lý do), auto-mark, thắng/thua, tính điểm.

**Tham khảo hành vi từ:** `gameplay/core/queendoku_core.gd`, `hint_engine.gd` → auto-mark logic

**Board data type:** `board: Array` — NxN 2D Array, mỗi phần tử là `CellKind` int. Truy cập: `board[row][col]`.

**Thiết kế mới:**

```gdscript
# candy_rules.gd
extends RefCounted

const CellModel = preload("res://scripts/core/cell_model.gd")

enum Clash { NONE, SAME_ROW, SAME_COL, SAME_ZONE, TOUCHING }

# --- Grid helpers ---

static func zone_of(regions: Array, row: int, col: int) -> String
static func can_place(board: Array, regions: Array, row: int, col: int) -> bool
    # Core constraint: cell available, no candy in row/col/zone, no adjacent candy

# --- Clash detection (for explaining mistakes, NOT for validation) ---

static func detect_clash(regions: Array, board: Array, a: Array, b: Array) -> int
    # Returns Clash enum — used for mistake explanation only

# --- Auto-mark (from reference R1 Mark) ---

static func compute_auto_marks(board: Array, regions: Array, candy_row: int, candy_col: int) -> Array
    # After placing candy, returns [row, col] pairs to set LOCKED:
    # same row, same col, same zone, diagonal neighbors.
    # Only BLANK cells.

static func compute_all_auto_marks(board: Array, regions: Array) -> Array
    # For ALL placed candies, compute locks. Used for session restore / undo recompute.

# --- Game actions ---

static func attempt_candy(board: Array, regions: Array, solution: Array,
        hearts: int, mistake_count: int, row: int, col: int) -> Dictionary
    # Validation: solution[row] == col (GDD GR-15)
    # Returns:
    # {board: Array, hearts: int, mistake_count: int, phase: String,
    #  events: Array, reason: String, auto_marks: Array}
    # phase: "active" | "won" | "failed"
    # reason: Clash label khi sai (từ detect_clash), "" khi đúng
    # auto_marks: [row, col] pairs set to LOCKED

# --- Scoring ---

static func tally(correct_count: int, mistake_count: int) -> int
static func correct_count(board: Array) -> int

# --- Validation ---

static func verify_level(level: Dictionary) -> bool
    # Structural: size, regions, solution, adjacency, zone uniqueness
```

**Khác biệt với reference:**
- **Board = 2D Array** thay Dictionary cells — `board[row][col]` trực tiếp
- **attempt_candy() dùng `solution[row]==col`** để validate — detect_clash chỉ giải thích lý do
- **Terminology:** `hearts`/`mistake_count`/`phase:"failed"` (GDD terms)
- **compute_auto_marks()** — tách từ R1 Mark trong hint_engine thành API riêng
- **can_place()** — public, reused bởi solver
- Tên: `Clash` thay `Violation`, `reason` thay `clash_label`

---

## File 3: `game/scripts/core/board_solver.gd`

**Trách nhiệm:** Hint engine — tìm gợi ý cho người chơi, hỗ trợ progressive reveal với hintCosts.

**Tham khảo hành vi từ:** `gameplay/core/hint_engine.gd` (1257 dòng, R1-R5, stateless static)

**Phạm vi playtest:** 3 chiến thuật S1/S2/S3. Board data: `board: Array` (NxN 2D CellKind int).

**Technique mapping (Reference → GDD):**

| GDD | Reference | Mô tả | Playtest |
|---|---|---|---|
| S1 | R1 Mark | Loại trừ: row/col/zone/diagonal từ candy đã biết | ✓ (auto-mark) |
| S2 | R1 Placement | Naked single: 1 ứng viên trong unit | ✓ |
| S3 | R2 (4 modes) | Lock intersection: zone→row, zone→col, row→zone, col→zone | ✓ |

**Solve loop pattern (from reference):**
```
repeat:
    S1: auto-mark all known candy → update candidates P
    S2: find naked single in any row/col/zone → place candy, loop
    S3: find lock intersection (4 modes) → eliminate cells, loop
    if none: STUCK
until all candy placed or STUCK
```
Key: **S1 mark luôn chạy trước mỗi vòng** — đảm bảo maximum constraint propagation.

**S3 — 4 sub-modes (from reference R2):**
- S3a (zone→row): P(zone) ⊆ row → loại ô khác zone trong row
- S3b (zone→col): P(zone) ⊆ col → loại ô khác zone trong col
- S3c (row→zone): P(row) ⊆ zone → loại ô zone ở row khác
- S3d (col→zone): P(col) ⊆ zone → loại ô zone ở col khác

**Thiết kế mới:**

```gdscript
# board_solver.gd
extends RefCounted

const CellModel = preload("res://scripts/core/cell_model.gd")
const CandyRules = preload("res://scripts/core/candy_rules.gd")

enum Technique { ELIMINATION, SINGLE_CANDIDATE, LOCK_INTERSECTION }

# --- Public API ---

static func next_hint(board: Array, size: int, regions: Array, solution: Array) -> Dictionary
    # Rebuild K from givens + found candy (ignore X/x_error per GDD)
    # Run S1 to build candidates P
    # Try S2 → if found, return hint
    # Try S3 (4 modes) → if found, apply elimination and try S2 again
    # Returns {
    #   found: bool,
    #   technique: int,        # Technique enum
    #   cell: Array,           # [row, col] of target cell
    #   unit_type: String,     # "zone"|"row"|"col" (for progressive reveal)
    #   unit_id: Variant,      # zone label or row/col index
    #   explanation: String,
    # }
    # NOTE: solver reasons from board state only; solution NOT used for target choice

static func progressive_hint(board: Array, size: int, regions: Array,
        solution: Array, max_clicks: int) -> Dictionary
    # Progressive reveal based on hint economy (from pace hintCosts).
    # max_clicks determines reveal depth:
    #   1: highlight unit (zone/row/col)
    #   2+: narrow to specific cell
    # Returns {stage: "unit"|"cell"|"place", highlight: Array, text: String}

static func solve_sequence(size: int, regions: Array, solution: Array) -> Array[int]
    # Full solve from empty board using solve loop pattern.
    # Returns Array of technique levels used for each cell placement.

static func compute_cell_ranks(size: int, regions: Array, solution: Array,
        givens: Array) -> Array
    # From reference compute_cell_ranks pattern:
    # Start empty board with givens placed, solve loop tracking current_max.
    # Each S2 placement records rank = current_max, then reset to 1.
    # Unsolved cells get fallback rank 4.
    # Returns NxN Array — ranks[row][col] = rank int (0 for given/solved, 1-4 for difficulty)

# --- Techniques (private) ---

static func _apply_elimination(board: Array, size: int, regions: Array) -> Array
    # S1: compute all cells to mark from placed candies. Returns marked [row, col] pairs.

static func _try_single_candidate(board: Array, size: int, regions: Array) -> Dictionary
    # S2: Find zone/row/col with only one possible candy position.
    # Returns {found, cell, unit_type, unit_id}

static func _try_lock_intersection(board: Array, size: int, regions: Array) -> Dictionary
    # S3: 4 sub-modes (zone→row, zone→col, row→zone, col→zone).
    # If all candidates for source unit lie in intersection with target unit,
    # eliminate non-intersection candidates from target unit.
    # Returns {found, eliminated: Array, mode: String}

# --- Helpers ---

static func _candidates_in_zone(board: Array, size: int, regions: Array, zone_label: String) -> Array
static func _candidates_in_row(board: Array, size: int, row: int) -> Array
static func _candidates_in_col(board: Array, size: int, col: int) -> Array
static func _is_candidate(board: Array, size: int, regions: Array, row: int, col: int) -> bool
```

**Khác biệt với reference:**
- 3 techniques thay 5+ (bỏ R3/R4 subset, R5 chain — future S4/S5)
- **Technique enum:** `LOCK_INTERSECTION` thay `ZONE_LINE` (chính xác hơn, có 4 modes)
- **solve loop pattern:** S1→S2→S3→repeat, S1 luôn chạy đầu (từ reference)
- **S3 có 4 sub-modes** (zone→row, zone→col, row→zone, col→zone) — từ reference R2
- **compute_cell_ranks()** trả NxN Array thay Dictionary (consistent với board data type)
- **progressive_hint()** dùng `max_clicks: int` thay Array
- **next_hint** reasons from board only; `solution` chỉ dùng cho safety assert
- **_apply_elimination** trả Array thay bool (cho auto-mark downstream)
- Params dùng `regions` thay `zones` (GDD term)
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
    _test_detect_clash()
    _test_can_place()
    _test_attempt_candy_correct()
    _test_attempt_candy_wrong()
    _test_attempt_candy_win()
    _test_attempt_candy_last_heart()
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
    _assert(not CellModel.is_empty(CellModel.CellKind.MARK), "mark not empty")
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

func _test_detect_clash() -> void:
    var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
    var board := _empty_board(4)
    board[0][0] = CellModel.CellKind.CANDY
    board[0][2] = CellModel.CellKind.CANDY
    _assert(CandyRules.detect_clash(regions, board, [0, 0], [0, 2]) == CandyRules.Clash.SAME_ROW, "same row")
    board = _empty_board(4)
    board[0][0] = CellModel.CellKind.CANDY
    _assert(CandyRules.detect_clash(regions, board, [0, 0], [2, 0]) == CandyRules.Clash.SAME_COL, "same col")
    _assert(CandyRules.detect_clash(regions, board, [0, 0], [1, 1]) == CandyRules.Clash.TOUCHING, "diagonal")
    _assert(CandyRules.detect_clash(regions, board, [0, 0], [2, 2]) == CandyRules.Clash.NONE, "no clash")

func _test_can_place() -> void:
    var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
    var board := _empty_board(4)
    _assert(CandyRules.can_place(board, regions, 0, 1), "empty cell can place")
    board[0][1] = CellModel.CellKind.CANDY
    _assert(not CandyRules.can_place(board, regions, 0, 2), "same row blocked")
    _assert(not CandyRules.can_place(board, regions, 1, 1), "same col blocked")
    _assert(not CandyRules.can_place(board, regions, 1, 0), "adjacent blocked")

func _test_attempt_candy_correct() -> void:
    var level := _make_level_4x4()
    var board := _empty_board(4)
    # solution[0] == 1, so placing at (0, 1) is correct
    var result := CandyRules.attempt_candy(board, level["regions"], level["solution"], 3, 0, 0, 1)
    _assert("CandyFound" in str(result["events"]), "correct placement event")
    _assert(result["phase"] == "active", "still active")
    _assert(result["auto_marks"].size() > 0, "auto marks generated")

func _test_attempt_candy_wrong() -> void:
    var level := _make_level_4x4()
    var board := _empty_board(4)
    # solution[0] == 1, so placing at (0, 0) is wrong
    var result := CandyRules.attempt_candy(board, level["regions"], level["solution"], 3, 0, 0, 0)
    _assert("Mistake" in str(result["events"]), "wrong placement event")
    _assert(result["hearts"] == 2, "lost a heart")
    _assert(result["reason"] != "", "has reason")

func _test_attempt_candy_win() -> void:
    var level := _make_level_4x4()
    var board := _empty_board(4)
    for row in range(3):
        board[row][level["solution"][row]] = CellModel.CellKind.CANDY
    var result := CandyRules.attempt_candy(board, level["regions"], level["solution"], 3, 0, 3, level["solution"][3])
    _assert(result["phase"] == "won", "level won")

func _test_attempt_candy_last_heart() -> void:
    var level := _make_level_4x4()
    var board := _empty_board(4)
    # solution[0] == 1, placing at (0, 0) is wrong with 1 heart left
    var result := CandyRules.attempt_candy(board, level["regions"], level["solution"], 1, 2, 0, 0)
    _assert(result["phase"] == "failed", "game over on last heart")

func _test_auto_marks() -> void:
    var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
    var board := _empty_board(4)
    board[0][1] = CellModel.CellKind.CANDY
    var marks := CandyRules.compute_auto_marks(board, regions, 0, 1)
    _assert(marks.size() > 0, "auto marks not empty")
    _assert([0, 0] in marks, "row 0 col 0 marked")
    _assert([0, 2] in marks, "row 0 col 2 marked")
    _assert([1, 1] in marks, "same col marked")

func _test_auto_marks_skip_locked() -> void:
    var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
    var board := _empty_board(4)
    board[0][0] = CellModel.CellKind.LOCKED
    board[0][1] = CellModel.CellKind.CANDY
    var marks := CandyRules.compute_auto_marks(board, regions, 0, 1)
    _assert([0, 0] not in marks, "already locked cell skipped")

func _test_tally() -> void:
    _assert(CandyRules.tally(4, 0) == 400, "perfect score")
    _assert(CandyRules.tally(4, 2) == 350, "score with mistakes")
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
    _test_lock_intersection()
    if _fails.is_empty():
        print("CORE_BOARD_SOLVER_PASS")
        quit(0)
    else:
        for f in _fails: printerr(f)
        quit(1)

func _test_next_hint_empty_board() -> void:
    var board := _empty_board(4)
    var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
    var solution := [1, 3, 0, 2]
    var hint := BoardSolver.next_hint(board, 4, regions, solution)
    _assert(hint["found"], "hint found on empty board")

func _test_next_hint_after_placement() -> void:
    var board := _empty_board(4)
    board[0][1] = CellModel.CellKind.CANDY
    var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
    var solution := [1, 3, 0, 2]
    var hint := BoardSolver.next_hint(board, 4, regions, solution)
    _assert(hint["found"], "hint after placement")

func _test_next_hint_returns_unit_info() -> void:
    var board := _empty_board(4)
    var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
    var solution := [1, 3, 0, 2]
    var hint := BoardSolver.next_hint(board, 4, regions, solution)
    _assert(hint.has("unit_type"), "hint has unit_type")
    _assert(hint["unit_type"] in ["zone", "row", "col"], "valid unit_type")

func _test_progressive_hint_stages() -> void:
    var board := _empty_board(4)
    var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
    var solution := [1, 3, 0, 2]
    var h1 := BoardSolver.progressive_hint(board, 4, regions, solution, 1)
    _assert(h1["stage"] == "unit", "first click shows unit")
    var h2 := BoardSolver.progressive_hint(board, 4, regions, solution, 2)
    _assert(h2["stage"] == "cell" or h2["stage"] == "place", "second click narrows")

func _test_solve_sequence() -> void:
    var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
    var solution := [1, 3, 0, 2]
    var seq := BoardSolver.solve_sequence(4, regions, solution)
    _assert(seq.size() == 4, "sequence has 4 steps")
    for rank in seq:
        _assert(rank >= 1 and rank <= 3, "rank in S1-S3 range")

func _test_compute_cell_ranks() -> void:
    var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
    var solution := [1, 3, 0, 2]
    var ranks := BoardSolver.compute_cell_ranks(4, regions, solution, [])
    _assert(ranks.size() == 4, "ranks has 4 rows")
    _assert(ranks[0].size() == 4, "ranks row has 4 cols")
    # Each solution cell should have a rank 1-4
    for row in range(4):
        _assert(ranks[row][solution[row]] >= 1, "solution cell has rank")

func _test_lock_intersection() -> void:
    # S3 test: set up board where lock intersection can eliminate
    var board := _empty_board(4)
    var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
    var result := BoardSolver._try_lock_intersection(board, 4, regions)
    # On empty 4x4 board, S3 may or may not find eliminations depending on geometry
    _assert(result.has("found"), "lock intersection returns found key")

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
- [ ] Viết `candy_rules.gd` — solution-based TryCandy, detect_clash (giải thích), auto_marks, can_place, verify_level. Board = 2D Array.
- [ ] Chạy test → pass
- [ ] Viết test `test_board_solver.gd` (fail trước)
- [ ] Viết `board_solver.gd` — solve loop (S1→S2→S3→repeat), next_hint, progressive_hint, compute_cell_ranks (NxN Array), S3 4 sub-modes
- [ ] Chạy test → pass
- [ ] Commit: `feat(m01): add puzzle rules with auto-mark and progressive hint solver`

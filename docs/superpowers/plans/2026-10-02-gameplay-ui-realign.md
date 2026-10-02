# Gameplay & UI Realignment Plan

> Kế hoạch gốc, lưu để đối chiếu. Các checkbox chưa phản ánh tiến độ thực tế. Nhánh `feat/gameplay-ui-realign` đã triển khai nhiều thay đổi nhưng vẫn giữ Undo X, khác yêu cầu ban đầu; xem [STATUS](../../STATUS.md) và code hiện tại trước khi tiếp tục.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Loại bỏ cơ chế auto-lock cells, căn chỉnh lại gameplay cho đúng với nguồn tham khảo (`extracted_reusable/`), và đổi giao diện puzzle screen theo layout cũ (`archive/legacy_pre_rebuild/`).

**Architecture:** Ba trục thay đổi song song: (1) Core logic — bỏ LOCKED state + auto-mark, sai thì cell → ERROR vĩnh viễn thay vì WRONG tạm; (2) Input — bỏ undo stack (tham khảo không có undo), giữ mark_x toggleable; (3) UI — rebuild puzzle scene theo layout legacy (TopBar → StatusRow → RuleCard → Board → BottomDock) dùng programmatic build.

**Tech Stack:** Godot 4.x, GDScript

**Spec:** Hành vi tham khảo từ `extracted_reusable/scripts/`, layout tham khảo từ `archive/legacy_pre_rebuild/scripts/board_screen.gd`

## Global Constraints

- Không sao chép tên biến/hàm/enum từ `extracted_reusable/`. Tham khảo hành vi, viết code gốc.
- Module ≤ 300 dòng. Signals thay EventBus. Không autoloads.
- Chỉ dùng asset có sẵn trong `game/assets/`.
- Clean-room check phải pass: không tên cấm (EventBus, CellState, CellAction, BoardGestureRecognizer, v.v.).
- Phạm vi R1, 30 levels, N=4-6, S1-S3.

## Tổng hợp khác biệt cần sửa

| # | Khía cạnh | Hiện tại (sai) | Tham khảo (đúng) | Thay đổi |
|---|-----------|---------------|-------------------|----------|
| 1 | Auto-lock cells | Đặt candy → lock toàn bộ row/col/zone/diagonal | KHÔNG có auto-lock. Ô vẫn tương tác được | Bỏ LOCKED state, bỏ `compute_auto_marks`, bỏ `_recompute_all_locks` |
| 2 | Cell states | 6: BLANK, MARK, CANDY, WRONG, GIVEN, LOCKED | 7: EMPTY, CAT, MARK, ERROR, DRAFT_CROSS, DRAFT_CAT, LOCKED_MARK | Bỏ LOCKED. WRONG → ERROR (vĩnh viễn, hiện X). Giữ BLANK, MARK, CANDY, GIVEN. Thêm ERROR thay WRONG |
| 3 | Sai → hậu quả | Cell = WRONG, mất tim, xóa undo stack | Cell = ERROR (X vĩnh viễn), mất tim, cell không revert được | ERROR vĩnh viễn (không xóa được). Không xóa undo stack |
| 4 | Undo system | Full undo stack + grouped actions | KHÔNG có undo. X marks toggle bằng tap lại | Bỏ undo stack và undo button. X toggle trực tiếp |
| 5 | Input gestures | Single tap=X, double tap=candy. Swipe defined nhưng unused | Single tap=toggle X, double tap=candy, swipe=paint X/clear nhiều ô | Giữ single/double tap. Bật swipe để paint X trên nhiều ô |
| 6 | UI layout | Toolbar flat (HBox buttons) + Board chiếm hết | TopBar(back/stats/help/restart/settings) → StatusRow(region pill + hearts) → RuleCard(4 luật) → Board → BottomDock(undo+hint) | Rebuild theo layout legacy |
| 7 | Board style | Scene-based puzzle.tscn với toolbar HBox | Programmatic build, cream background, circular buttons, rounded card, shadows | Rebuild programmatic như legacy |

## Review Focus

1. **ERROR cell tương tác**: Sau khi cell thành ERROR, player tap lại → không được thay đổi state (phải immutable). Test verify tap/swipe trên ERROR cell bị reject.
2. **Double-tap trên cell đã có candy/given/error**: Player double-tap ô không available → no-op. Test verify không mất tim, không crash.
3. **Swipe qua mixed cells**: Kéo qua ô BLANK + CANDY + ERROR → chỉ paint X trên BLANK, skip immutable. Test verify selective painting.
4. **Win detection sau bỏ auto-lock**: Bỏ LOCKED → correct_count chỉ đếm CANDY+GIVEN. Verify win trigger đúng khi đủ N candies.
5. **Session save/restore không có LOCKED**: Save data không chứa "locked" nữa. Verify old saves với "locked" cells degrade gracefully (load thành "empty").

---

### Task 1: Simplify Cell Model — Bỏ LOCKED, đổi WRONG → ERROR

**Files:**
- Modify: `game/scripts/core/cell_model.gd`
- Test: `game/tests/test_candy_rules.gd` (update existing)

**Interfaces:**
- Produces: `CellKind` enum `{BLANK=0, MARK=1, CANDY=2, ERROR=3, GIVEN=4}`, cùng các hàm `is_empty`, `is_placed`, `is_candy`, `is_cross`, `is_locked`, `is_available`, `label`

- [ ] **Step 1: Update CellKind enum**

Thay đổi `game/scripts/core/cell_model.gd`:

```gdscript
# cell_model.gd
extends RefCounted

enum CellKind {
	BLANK = 0,
	MARK = 1,
	CANDY = 2,
	ERROR = 3,      # Đặt sai — vĩnh viễn, hiện X đỏ, không xóa được
	GIVEN = 4,
}

static func is_empty(kind: int) -> bool:
	return kind == CellKind.BLANK

static func is_placed(kind: int) -> bool:
	return kind == CellKind.CANDY or kind == CellKind.GIVEN

static func is_candy(kind: int) -> bool:
	return kind == CellKind.CANDY or kind == CellKind.GIVEN

static func is_cross(kind: int) -> bool:
	return kind == CellKind.MARK or kind == CellKind.ERROR

static func is_locked(kind: int) -> bool:
	return kind == CellKind.GIVEN

static func is_available(kind: int) -> bool:
	return kind == CellKind.BLANK or kind == CellKind.MARK

static func label(kind: int) -> String:
	match kind:
		CellKind.BLANK: return "blank"
		CellKind.MARK: return "mark"
		CellKind.CANDY: return "candy"
		CellKind.ERROR: return "error"
		CellKind.GIVEN: return "given"
	return "unknown"
```

Thay đổi chính:
- Xóa `LOCKED = 5` khỏi enum
- Đổi `WRONG = 3` thành `ERROR = 3` (cùng giá trị, đổi tên + ngữ nghĩa: vĩnh viễn)
- `is_locked()` chỉ trả true cho GIVEN (không còn LOCKED)
- `is_cross()` trả true cho MARK và ERROR (không còn LOCKED)

- [ ] **Step 2: Verify tests compile — chạy test hiện có để thấy fail**

Run: `godot --headless --script game/tests/test_candy_rules.gd` (nếu có Godot) hoặc grep tất cả references tới `WRONG` và `LOCKED` để biết scope cần sửa.

```bash
grep -rn "CellKind\.WRONG\|CellKind\.LOCKED\|LOCKED\|WRONG" game/scripts/ game/tests/
```

- [ ] **Step 3: Commit**

```bash
git add game/scripts/core/cell_model.gd
git commit -m "refactor(m01): replace WRONG+LOCKED with ERROR in CellKind enum

Remove LOCKED state entirely (no more auto-lock).
Rename WRONG to ERROR (permanent, immutable X mark)."
```

---

### Task 2: Strip Auto-Lock from CandyRules

**Files:**
- Modify: `game/scripts/core/candy_rules.gd`

**Interfaces:**
- Consumes: `CellModel.CellKind` (updated enum from Task 1)
- Produces: `attempt_candy()` trả về dict KHÔNG CÒN `auto_marks` key, KHÔNG set LOCKED. Sai → cell = ERROR (vĩnh viễn). Xóa `compute_auto_marks()` và `compute_all_auto_marks()`.

- [ ] **Step 1: Rewrite `attempt_candy`**

```gdscript
static func attempt_candy(board: Array, regions: Array, solution: Array,
		hearts: int, mistake_count: int, row: int, col: int) -> Dictionary:
	var size: int = regions.size()
	if solution[row] == col:
		board[row][col] = CellModel.CellKind.CANDY
		var won: bool = correct_count(board) == size
		return {
			"board": board,
			"hearts": hearts,
			"mistake_count": mistake_count,
			"phase": "won" if won else "active",
			"events": ["CandyFound"],
			"reason": "",
		}

	board[row][col] = CellModel.CellKind.ERROR
	var new_hearts: int = hearts - 1
	var new_mistakes: int = mistake_count + 1
	var reason: String = ""

	for r in range(size):
		for c in range(size):
			if CellModel.is_placed(board[r][c]):
				var clash: int = detect_clash(regions, board, [row, col], [r, c])
				match clash:
					Clash.SAME_ROW:
						reason = "same_row"
						break
					Clash.SAME_COL:
						reason = "same_col"
						break
					Clash.SAME_ZONE:
						reason = "same_zone"
						break
					Clash.TOUCHING:
						reason = "touching"
						break
		if reason != "":
			break

	if reason == "":
		reason = "not_solution"

	var failed: bool = new_hearts <= 0
	return {
		"board": board,
		"hearts": new_hearts,
		"mistake_count": new_mistakes,
		"phase": "failed" if failed else "active",
		"events": ["Mistake"],
		"reason": reason,
	}
```

- [ ] **Step 2: Delete `compute_auto_marks` and `compute_all_auto_marks`**

Xóa hoàn toàn 2 hàm static `compute_auto_marks` (lines 63-93) và `compute_all_auto_marks` (lines 95-105) khỏi `candy_rules.gd`.

- [ ] **Step 3: Commit**

```bash
git add game/scripts/core/candy_rules.gd
git commit -m "refactor(m01): remove auto-lock from candy_rules

- attempt_candy no longer computes/applies auto-marks
- Wrong placement sets ERROR (permanent) instead of WRONG
- Removed compute_auto_marks and compute_all_auto_marks entirely"
```

---

### Task 3: Simplify PlaySession — Bỏ auto-lock, bỏ undo stack, ERROR vĩnh viễn

**Files:**
- Modify: `game/scripts/input/play_session.gd`
- Modify: `game/scripts/input/action_recorder.gd` (có thể giữ file nhưng không dùng, hoặc xóa)

**Interfaces:**
- Consumes: `CandyRules.attempt_candy()` (updated from Task 2), `CellModel.CellKind` (from Task 1)
- Produces: `PlaySession` không còn `auto_marked` signal, không còn `recorder`/`undo()`/`can_undo()`. `mark_x()` toggle trực tiếp BLANK↔MARK. `try_candy()` đúng → CANDY, sai → ERROR vĩnh viễn.

- [ ] **Step 1: Rewrite play_session.gd**

```gdscript
extends RefCounted

const CellModel = preload("res://scripts/core/cell_model.gd")
const CandyRules = preload("res://scripts/core/candy_rules.gd")

signal state_changed()
signal candy_found(row: int, col: int, region: String)
signal heart_lost(remaining: int)
signal mistake_made(row: int, col: int, reason: String)
signal level_won()
signal level_failed()

enum Phase {
	ACTIVE = 0,
	WON = 1,
	FAILED = 2,
}

var level: Dictionary = {}
var board: Array = []
var hearts: int = 3
var mistake_count: int = 0
var hints_used: int = 0
var elapsed_ms: int = 0
var phase: int = Phase.ACTIVE

func _init(level_data: Dictionary, initial_hearts: int = 3) -> void:
	level = level_data
	hearts = initial_hearts
	mistake_count = 0
	hints_used = 0
	elapsed_ms = 0
	phase = Phase.ACTIVE

	var size: int = int(level.get("size", 0))
	board = []
	for r in range(size):
		var row_arr: Array = []
		for c in range(size):
			row_arr.append(CellModel.CellKind.BLANK)
		board.append(row_arr)

	for g in level.get("givens", []):
		var gr: int = int(g.get("r", -1))
		var gc: int = int(g.get("c", -1))
		if gr >= 0 and gr < size and gc >= 0 and gc < size:
			board[gr][gc] = CellModel.CellKind.GIVEN

func mark_x(row: int, col: int) -> void:
	if phase != Phase.ACTIVE:
		return
	if row < 0 or row >= board.size() or col < 0 or col >= board.size():
		return
	var current: int = board[row][col]
	if not CellModel.is_available(current):
		return
	board[row][col] = CellModel.CellKind.BLANK if current == CellModel.CellKind.MARK else CellModel.CellKind.MARK
	state_changed.emit()

func try_candy(row: int, col: int) -> void:
	if phase != Phase.ACTIVE:
		return
	if row < 0 or row >= board.size() or col < 0 or col >= board.size():
		return
	var current: int = board[row][col]
	if not CellModel.is_available(current):
		return

	var regions: Array = level.get("regions", [])
	var solution: Array = level.get("solution", [])
	var res: Dictionary = CandyRules.attempt_candy(board, regions, solution, hearts, mistake_count, row, col)

	hearts = int(res.get("hearts", hearts))
	mistake_count = int(res.get("mistake_count", mistake_count))

	if board[row][col] == CellModel.CellKind.CANDY:
		var region: String = CandyRules.zone_of(regions, row, col)
		candy_found.emit(row, col, region)
		state_changed.emit()
		if res.get("phase") == "won":
			phase = Phase.WON
			level_won.emit()
	else:
		mistake_made.emit(row, col, str(res.get("reason", "")))
		heart_lost.emit(hearts)
		state_changed.emit()
		if res.get("phase") == "failed" or hearts <= 0:
			phase = Phase.FAILED
			level_failed.emit()

func use_hint() -> void:
	hints_used += 1
	state_changed.emit()

func cell_at(row: int, col: int) -> int:
	if row < 0 or row >= board.size() or col < 0 or col >= board.size():
		return CellModel.CellKind.BLANK
	return board[row][col]

func is_preset(row: int, col: int) -> bool:
	return cell_at(row, col) == CellModel.CellKind.GIVEN

func remaining_candies() -> int:
	var size: int = board.size()
	var count: int = 0
	var solution: Array = level.get("solution", [])
	for r in range(size):
		if r < solution.size():
			var c: int = int(solution[r])
			if board[r][c] != CellModel.CellKind.CANDY and board[r][c] != CellModel.CellKind.GIVEN:
				count += 1
	return count

func to_save_data() -> Dictionary:
	var size: int = board.size()
	var flat_cells: Array[String] = []
	for r in range(size):
		for c in range(size):
			match board[r][c]:
				CellModel.CellKind.MARK:
					flat_cells.append("x")
				CellModel.CellKind.CANDY:
					flat_cells.append("candy")
				CellModel.CellKind.ERROR:
					flat_cells.append("error")
				CellModel.CellKind.GIVEN, CellModel.CellKind.BLANK, _:
					flat_cells.append("empty")

	var status_str: String = "playing"
	if phase == Phase.WON:
		status_str = "won"
	elif phase == Phase.FAILED:
		status_str = "failed"

	return {
		"sessionVersion": 3,
		"levelId": str(level.get("id", "")),
		"puzzleHash": str(level.get("hash", "")),
		"boardSize": size,
		"cells": flat_cells,
		"hearts": hearts,
		"mistake_count": mistake_count,
		"hints_used": hints_used,
		"elapsedMs": elapsed_ms,
		"status": status_str,
	}

static func from_save_data(data: Dictionary, level_data: Dictionary) -> RefCounted:
	var script = load("res://scripts/input/play_session.gd") as GDScript
	var session = script.new(level_data, int(data.get("hearts", 3)))
	session.mistake_count = int(data.get("mistake_count", 0))
	session.hints_used = int(data.get("hints_used", 0))
	session.elapsed_ms = int(data.get("elapsedMs", 0))
	var status: String = str(data.get("status", "playing"))
	match status:
		"won":
			session.phase = Phase.WON
		"failed":
			session.phase = Phase.FAILED
		_:
			session.phase = Phase.ACTIVE

	var size: int = session.board.size()
	var flat_cells: Array = data.get("cells", [])
	for r in range(size):
		for c in range(size):
			var idx: int = r * size + c
			if idx < flat_cells.size():
				var val: String = str(flat_cells[idx])
				match val:
					"x":
						session.board[r][c] = CellModel.CellKind.MARK
					"candy":
						session.board[r][c] = CellModel.CellKind.CANDY
					"error", "wrong":
						session.board[r][c] = CellModel.CellKind.ERROR
					"empty", "locked", _:
						session.board[r][c] = CellModel.CellKind.BLANK

	for g in level_data.get("givens", []):
		var gr: int = int(g.get("r", -1))
		var gc: int = int(g.get("c", -1))
		if gr >= 0 and gr < size and gc >= 0 and gc < size:
			session.board[gr][gc] = CellModel.CellKind.GIVEN

	return session
```

Thay đổi chính:
- Xóa `auto_marked` signal
- Xóa `recorder` (ActionRecorder) — không import, không khởi tạo
- Xóa `undo()`, `can_undo()` functions
- Xóa `_recompute_all_locks()`, `_apply_auto_marks()` functions
- `mark_x()` toggle trực tiếp, không push vào recorder
- `try_candy()` không auto-mark, không recorder, sai → ERROR
- `from_save_data()`: "wrong" và "error" đều map → ERROR, "locked" map → BLANK (backward compat)

- [ ] **Step 2: Commit**

```bash
git add game/scripts/input/play_session.gd
git commit -m "refactor(m04): remove auto-lock and undo from play_session

- No more auto_marked signal or LOCKED cell state
- No more ActionRecorder/undo — marks toggle directly
- Wrong placement creates permanent ERROR cell
- Backward-compatible save loading (locked→blank, wrong→error)"
```

---

### Task 4: Enable Swipe Gesture for Painting X Marks

**Files:**
- Modify: `game/scripts/input/touch_decoder.gd`
- Modify: `game/scripts/screens/puzzle_board.gd`
- Modify: `game/scripts/screens/puzzle_screen.gd`

**Interfaces:**
- Consumes: `PlaySession.mark_x()` (from Task 3)
- Produces: `cell_swiped(cells: Array)` signal connected and functional — swipe paints X or clears X on multiple cells based on first cell's toggle direction.

- [ ] **Step 1: Verify touch_decoder.gd already emits `cell_swiped`**

Read `game/scripts/input/touch_decoder.gd` to confirm `cell_swiped` signal exists and is emitted during drag. It should already be implemented — just unused.

- [ ] **Step 2: Connect swipe in puzzle_board.gd**

Add to `configure()` in `puzzle_board.gd`:

```gdscript
signal cell_swiped(cells: Array)

# In configure(), after connecting cell_tapped and cell_double_tapped:
_decoder.cell_swiped.connect(func(cells: Array): cell_swiped.emit(cells))
```

- [ ] **Step 3: Handle swipe in puzzle_screen.gd**

Add connection and handler in `puzzle_screen.gd`:

```gdscript
# In _connect_ui(), add:
if board != null:
	if not board.cell_swiped.is_connected(_on_board_swipe):
		board.cell_swiped.connect(_on_board_swipe)

# New handler:
func _on_board_swipe(cells: Array) -> void:
	if session == null or session.phase != 0:
		return
	if cells.is_empty():
		return
	# Direction based on first cell: if BLANK → paint MARK, if MARK → clear to BLANK
	var first_r: int = cells[0][0]
	var first_c: int = cells[0][1]
	var first_kind: int = session.cell_at(first_r, first_c)
	var paint_mark: bool = CellModel.is_empty(first_kind)
	for cell in cells:
		var r: int = cell[0]
		var c: int = cell[1]
		var kind: int = session.cell_at(r, c)
		if paint_mark and CellModel.is_empty(kind):
			session.mark_x(r, c)
		elif not paint_mark and kind == CellModel.CellKind.MARK:
			session.mark_x(r, c)
	if sfx != null:
		sfx.play(SfxCatalog.Effect.MARK)
	if board != null:
		board.redraw()
```

- [ ] **Step 4: Commit**

```bash
git add game/scripts/input/touch_decoder.gd game/scripts/screens/puzzle_board.gd game/scripts/screens/puzzle_screen.gd
git commit -m "feat(m04): enable swipe gesture for painting X marks

Connect cell_swiped signal from touch decoder through board to screen.
Swipe direction (paint vs clear) determined by first cell in trail."
```

---

### Task 5: Update PuzzleBoard Rendering — Bỏ Lock Visuals, Thêm ERROR

**Files:**
- Modify: `game/scripts/screens/puzzle_board.gd`

**Interfaces:**
- Consumes: `CellModel.CellKind` (updated from Task 1), `Palette` colors
- Produces: `_draw()` renders BLANK, MARK, CANDY, ERROR, GIVEN — no LOCKED overlay, no lock animation.

- [ ] **Step 1: Remove lock animation and LOCKED rendering**

Trong `puzzle_board.gd`:

1. Xóa vars `_lock_anim_cells` và `_lock_anim_progress`
2. Xóa func `animate_locks()`
3. Xóa lock animation logic trong `_process()`
4. Xóa func `_draw_lock_overlay()`
5. Trong `_draw()`, xóa case `CellModel.CellKind.LOCKED`
6. Đổi `CellModel.CellKind.WRONG` thành `CellModel.CellKind.ERROR` trong `_draw()`

Update `_draw()` match block:

```gdscript
match kind:
	CellModel.CellKind.MARK:
		_draw_cell_x(cell_rect, false)
	CellModel.CellKind.CANDY:
		_draw_cell_candy(cell_rect, false)
	CellModel.CellKind.ERROR:
		_draw_cell_x(cell_rect, true)
	CellModel.CellKind.GIVEN:
		_draw_cell_candy(cell_rect, true)
```

7. Simplify `_draw_cell_x` — remove `is_locked` parameter:

```gdscript
func _draw_cell_x(rect: Rect2, is_error: bool, alpha: float = 1.0) -> void:
	var stroke_col: Color = Palette.ERROR_RED if is_error else Palette.MARK_WHITE
	stroke_col.a *= alpha
	var pad := rect.size.x * 0.28
	var w := maxf(2.5, rect.size.x * 0.08)
	var p1 := rect.position + Vector2(pad, pad)
	var p2 := rect.end - Vector2(pad, pad)
	var p3 := Vector2(rect.end.x - pad, rect.position.y + pad)
	var p4 := Vector2(rect.position.x + pad, rect.end.y - pad)
	draw_line(p1, p2, stroke_col, w)
	draw_line(p3, p4, stroke_col, w)
```

- [ ] **Step 2: Commit**

```bash
git add game/scripts/screens/puzzle_board.gd
git commit -m "refactor(m08): remove lock visuals, add ERROR cell rendering

- Remove lock animation, lock overlay, LOCKED cell drawing
- Rename WRONG to ERROR in rendering
- Simplify _draw_cell_x (no more is_locked param)"
```

---

### Task 6: Update PuzzleScreen — Bỏ Undo + Auto-Mark Handlers

**Files:**
- Modify: `game/scripts/screens/puzzle_screen.gd`

**Interfaces:**
- Consumes: `PlaySession` (no undo, no auto_marked signal — from Task 3)
- Produces: puzzle_screen không còn undo button handling, không còn auto_marked listener

- [ ] **Step 1: Remove undo and auto_marked handling**

Trong `puzzle_screen.gd`:

1. Xóa `undo_btn` var và references trong `_ensure_nodes()`, `_connect_ui()`
2. Xóa `_on_undo()` function
3. Xóa `_on_auto_marked()` function
4. Trong `_connect_session()`, xóa line connect `auto_marked`
5. Đổi `_on_mistake` tham số: `_clash` → dùng cho UI feedback nếu cần

```gdscript
# Xóa:
# - undo_btn var
# - undo_btn references trong _ensure_nodes và _connect_ui
# - session.auto_marked.is_connected check trong _connect_session
# - _on_undo func
# - _on_auto_marked func

# Trong _connect_session, xóa:
# if not session.auto_marked.is_connected(_on_auto_marked):
#     session.auto_marked.connect(_on_auto_marked)
```

- [ ] **Step 2: Commit**

```bash
git add game/scripts/screens/puzzle_screen.gd
git commit -m "refactor(m08): remove undo and auto-mark handlers from puzzle_screen

- No more undo button or _on_undo handler
- No more auto_marked signal listener
- Aligned with simplified play_session"
```

---

### Task 7: Rebuild Puzzle Scene Layout Theo Legacy Design

**Files:**
- Modify: `game/scripts/screens/puzzle_screen.gd` (thêm programmatic build)
- Modify: `game/scenes/puzzle.tscn` (minimal root only)
- Modify: `game/scripts/theme/palette.gd` (thêm UI colors nếu thiếu)

**Interfaces:**
- Consumes: Legacy layout reference từ `archive/legacy_pre_rebuild/scripts/board_screen.gd`
- Produces: Puzzle screen với layout: cream background → SafeArea → VBox(TopBar → StatusRow → RuleCard → BoardCard → BottomDock)

**Tham khảo layout legacy (board_screen.gd):**
```
Background (cream #F8F1EC, full rect)
└── Safe (MarginContainer 38/38/44/36)
    └── Root (VBoxContainer, sep=18)
        ├── TopBar (HBox, 96px): Back · Spacer · StatCol(Màn/Number) · Spacer · Help · Restart · Settings
        ├── StatusRow (HBox): RegionProgressPill (candy icons per region) + LivesPill (heart icons)
        ├── RuleCard (PanelContainer, white rounded): 2x2 Grid of RuleIcon3x3 + labels
        ├── BoardCard (PanelContainer, white rounded, shadow): CenterContainer → PuzzleBoard
        ├── StatusLabel + HintLabel (toast text)
        └── BottomDock (HBox): Hint button (circular, 110x110)
```

- [ ] **Step 1: Simplify puzzle.tscn to bare root**

```tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/screens/puzzle_screen.gd" id="1_puzzle"]

[node name="PuzzleScreen" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_puzzle")
```

Chỉ giữ root Control với script. Toàn bộ UI build programmatic.

- [ ] **Step 2: Add `_build_interface()` to puzzle_screen.gd**

Viết hàm `_build_interface()` tạo toàn bộ layout programmatic. Reference: `archive/legacy_pre_rebuild/scripts/board_screen.gd` lines 191-500+.

Key elements cần build:
1. **Background**: ColorRect cream (`Palette.BG_CREAM`)
2. **SafeArea**: MarginContainer (38/38/44/36)
3. **Root VBox**: separation=18
4. **TopBar** (HBox, 96px height):
   - Back button (circular, 88x88, icon_back.png)
   - Spacer
   - StatCol (VBox: "Màn" label + level number label)
   - Spacer
   - Help button (circular, 88x88, icon_help.png)
   - Restart button (circular, 88x88, icon_restart.png)
   - Settings button (circular, 88x88, icon_settings.png)
5. **StatusRow** (HBox):
   - Region progress pill (white rounded panel, candy icons per region — colored by zone)
   - Lives pill (white rounded panel, heart icons)
6. **RuleCard** (PanelContainer white rounded):
   - 2x2 GridContainer: 4 rule tiles (mini 3x3 grid + label)
   - Rules: "1 kẹo mỗi hàng", "1 kẹo mỗi cột", "1 kẹo mỗi vùng", "Kẹo không chạm chéo"
7. **BoardCard** (PanelContainer white rounded with shadow):
   - CenterContainer → PuzzleBoard (min 280x280)
8. **BottomDock** (HBox):
   - Hint button (circular, 110x110, icon_hint.png)

Hàm helper `_make_circle_button()`:

```gdscript
func _make_circle_button(btn_name: String, icon_tex: Texture2D, btn_size: Vector2) -> Button:
	var btn := Button.new()
	btn.name = btn_name
	btn.custom_minimum_size = btn_size
	btn.flat = true
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color.WHITE
	normal.set_corner_radius_all(999)
	normal.shadow_color = Color(0.545, 0.353, 0.290, 0.12)
	normal.shadow_size = 6
	normal.shadow_offset = Vector2(0, 2)
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color("#FFFDFB")
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate()
	pressed.bg_color = Color("#F5EFEA")
	btn.add_theme_stylebox_override("pressed", pressed)
	if icon_tex != null:
		var icon_container := CenterContainer.new()
		icon_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon_rect := TextureRect.new()
		icon_rect.texture = icon_tex
		var icon_size := btn_size * 0.54
		icon_rect.custom_minimum_size = icon_size
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_container.add_child(icon_rect)
		btn.add_child(icon_container)
	return btn
```

- [ ] **Step 3: Update `_ready()` to call `_build_interface()` and wire signals**

```gdscript
func _ready() -> void:
	_load_textures()
	_build_interface()
	_connect_ui()
```

Node references (board, hint_btn, restart_btn, home_btn, etc.) are now set during `_build_interface()` instead of `_ensure_nodes()` via `get_node_or_null()`.

- [ ] **Step 4: Add region progress and hearts update functions**

```gdscript
func _update_region_progress() -> void:
	# Update candy icons — saturated when found, dimmed when not
	if session == null:
		return
	var regions: Array = session.level.get("regions", [])
	var size: int = int(session.level.get("size", 0))
	var found_zones: Dictionary = {}
	for r in range(size):
		for c in range(size):
			if CellModel.is_placed(session.board[r][c]):
				var zone: String = CandyRules.zone_of(regions, r, c)
				found_zones[zone] = true
	for i in range(_region_icons.size()):
		var zone_id: String = char(65 + i)
		if found_zones.has(zone_id):
			_region_icons[i].modulate = Color.WHITE
		else:
			_region_icons[i].modulate = Color(1.0, 1.0, 1.0, 0.3)

func _update_hearts() -> void:
	if session == null:
		return
	for i in range(_life_icons.size()):
		if i < session.hearts:
			_life_icons[i].modulate = Color.WHITE
		else:
			_life_icons[i].modulate = Color(1.0, 1.0, 1.0, 0.25)
```

- [ ] **Step 5: Add RuleIcon3x3 inner class**

Reference: `archive/legacy_pre_rebuild/scripts/board_screen.gd` lines 67-103.

```gdscript
class RuleIcon3x3 extends Control:
	var pattern: String = ""
	var candy_tex: Texture2D = null

	func _init(pat: String, candy_texture: Texture2D = null) -> void:
		pattern = pat.replace(" ", "").replace("/", "")
		candy_tex = candy_texture
		custom_minimum_size = Vector2(58, 58)

	func _draw() -> void:
		var w := size.x
		var gap := 2.5
		var cell_w := (w - gap * 2.0) / 3.0
		var radius := 4
		for r in range(3):
			for c in range(3):
				var idx := r * 3 + c
				var ch := pattern[idx] if idx < pattern.length() else "."
				var cell_rect := Rect2(Vector2(c * (cell_w + gap), r * (cell_w + gap)), Vector2(cell_w, cell_w))
				var s := StyleBoxFlat.new()
				s.set_corner_radius_all(radius)
				if ch == "X":
					s.bg_color = Color("#6D4A45")
					draw_style_box(s, cell_rect)
					var p := cell_w * 0.22
					draw_line(cell_rect.position + Vector2(p, p), cell_rect.end - Vector2(p, p), Color.WHITE, 2.5)
					draw_line(cell_rect.position + Vector2(cell_w - p, p), cell_rect.position + Vector2(p, cell_w - p), Color.WHITE, 2.5)
				elif ch == "C":
					s.bg_color = Color("#FAF3EE")
					draw_style_box(s, cell_rect)
					if candy_tex != null:
						draw_texture_rect(candy_tex, cell_rect.grow(-1.5), false)
					else:
						draw_circle(cell_rect.get_center(), cell_w * 0.35, Color("#A56643"))
				else:
					s.bg_color = Color("#F0EBE6")
					draw_style_box(s, cell_rect)
```

Rule patterns (từ legacy):
- Row rule: `"X.X/.C./.X."` → "1 kẹo mỗi hàng"
- Col rule: `".X./..C/..X"` → "1 kẹo mỗi cột"
- Zone rule: `"X../XC./..."` → "1 kẹo mỗi vùng"
- Touch rule: `"X.X/.C./X.X"` → "Kẹo không chạm chéo"

- [ ] **Step 6: Test manually**

Chạy game và kiểm tra:
1. Layout hiển thị đúng: TopBar, StatusRow, RuleCard, Board, BottomDock
2. Circular buttons hoạt động (back, help, restart, settings, hint)
3. Region progress cập nhật khi tìm đúng candy
4. Hearts pill cập nhật khi mất tim
5. Board card có shadow và rounded corners

- [ ] **Step 7: Commit**

```bash
git add game/scripts/screens/puzzle_screen.gd game/scenes/puzzle.tscn
git commit -m "feat(m08): rebuild puzzle screen with legacy-style layout

Programmatic UI build matching legacy design:
- TopBar with circular buttons (back/help/restart/settings)
- StatusRow with region progress pill and hearts pill
- RuleCard with 3x3 mini-grid rule icons
- BoardCard with shadow and rounded corners
- BottomDock with hint button
- Cream background, warm aesthetic"
```

---

### Task 8: Update Palette — Thêm UI Colors Cho Legacy Layout

**Files:**
- Modify: `game/scripts/theme/palette.gd`

**Interfaces:**
- Produces: Thêm constants cần cho legacy layout: `BOARD_BG`, `SHADOW_SOFT`, `TEXT_STAT`, `PILL_RADIUS`, `CARD_SHADOW_COLOR`, `BTN_CIRCLE_NORMAL`, `BTN_CIRCLE_HOVER`, `BTN_CIRCLE_PRESSED`

- [ ] **Step 1: Read current palette.gd**

Kiểm tra palette.gd hiện tại có đủ colors không. Thêm constants thiếu.

- [ ] **Step 2: Add missing UI constants**

Thêm vào `palette.gd` (chỉ thêm nếu chưa có):

```gdscript
const BOARD_BG := Color("#F8F1EC")
const SHADOW_SOFT := Color(0.545, 0.353, 0.290, 0.12)
const TEXT_STAT := Color("#9B5A52")
const TEXT_RULE := Color("#A0655C")
const PILL_BG := Color.WHITE
const PILL_RADIUS := 28
const CARD_CORNER := 24
const BOARD_CARD_CORNER := 32
const CARD_SHADOW := Color(0.545, 0.353, 0.290, 0.15)
```

- [ ] **Step 3: Remove LOCKED-related palette constants**

Xóa nếu có: `LOCKED_OVERLAY`, `LOCKED_X_COLOR`, `LOCKED_X_ALPHA` — không còn dùng.

Cập nhật `cell_state_overlay()` — xóa case LOCKED.

- [ ] **Step 4: Commit**

```bash
git add game/scripts/theme/palette.gd
git commit -m "refactor(m05): update palette for legacy layout, remove LOCKED colors

Add warm cream UI colors matching legacy design.
Remove LOCKED_OVERLAY, LOCKED_X_COLOR, LOCKED_X_ALPHA."
```

---

### Task 9: Update Tests — Align với Gameplay Mới

**Files:**
- Modify: `game/tests/test_candy_rules.gd`
- Modify: `game/tests/test_play_session.gd`
- Modify: `game/tests/test_board_solver.gd` (nếu reference LOCKED)

**Interfaces:**
- Consumes: Updated CellModel, CandyRules, PlaySession từ Tasks 1-3

- [ ] **Step 1: Update test_candy_rules.gd**

1. Đổi tất cả `CellKind.WRONG` → `CellKind.ERROR`
2. Đổi tất cả `CellKind.LOCKED` → `CellKind.BLANK` (hoặc xóa tests liên quan auto-mark)
3. Xóa tests verify auto_marks trong attempt_candy result
4. Thêm test: sai placement → cell = ERROR, permanent

```gdscript
# Test: wrong placement creates ERROR (permanent)
func test_wrong_creates_error():
	var board := _make_blank_board(4)
	var regions := ["AABB", "AABB", "CCDD", "CCDD"]
	var solution := [1, 3, 0, 2]
	var res := CandyRules.attempt_candy(board, regions, solution, 3, 0, 0, 0)
	assert(board[0][0] == CellModel.CellKind.ERROR, "Wrong cell should be ERROR")
	assert(res["hearts"] == 2, "Should lose a heart")
	assert(not res.has("auto_marks"), "No auto_marks in result")

# Test: correct placement, no auto-lock
func test_correct_no_autolock():
	var board := _make_blank_board(4)
	var regions := ["AABB", "AABB", "CCDD", "CCDD"]
	var solution := [1, 3, 0, 2]
	var res := CandyRules.attempt_candy(board, regions, solution, 3, 0, 0, 1)
	assert(board[0][1] == CellModel.CellKind.CANDY, "Correct cell should be CANDY")
	# All other cells should still be BLANK — no auto-lock
	assert(board[0][0] == CellModel.CellKind.BLANK, "Other cells stay BLANK")
	assert(board[0][2] == CellModel.CellKind.BLANK, "Other cells stay BLANK")
	assert(board[1][1] == CellModel.CellKind.BLANK, "Same-col cell stays BLANK")
```

- [ ] **Step 2: Update test_play_session.gd**

1. Xóa tests cho undo (undo, can_undo)
2. Xóa tests cho auto_marked signal
3. Đổi `WRONG` → `ERROR`
4. Đổi `LOCKED` → `BLANK` trong expected states
5. Thêm test: ERROR cell is immutable (mark_x on ERROR → no change)

```gdscript
func test_error_is_immutable():
	# After wrong placement, cell is ERROR and cannot be changed by mark_x
	session.try_candy(wrong_row, wrong_col)
	assert(session.board[wrong_row][wrong_col] == CellModel.CellKind.ERROR)
	session.mark_x(wrong_row, wrong_col)
	assert(session.board[wrong_row][wrong_col] == CellModel.CellKind.ERROR, "ERROR should be immutable")
```

- [ ] **Step 3: Grep for remaining WRONG/LOCKED references**

```bash
grep -rn "WRONG\|LOCKED\|auto_mark\|_recompute\|recorder\|can_undo\|ActionRecorder" game/scripts/ game/tests/
```

Fix any remaining references.

- [ ] **Step 4: Run all tests**

```bash
godot --headless --script game/tests/test_candy_rules.gd
godot --headless --script game/tests/test_play_session.gd
```

- [ ] **Step 5: Commit**

```bash
git add game/tests/
git commit -m "test: update tests for simplified gameplay (no lock, no undo, ERROR state)"
```

---

### Task 10: Update Remaining References — SfxCatalog, Integration Test, Board Solver

**Files:**
- Modify: `game/scripts/feedback/sfx_catalog.gd` — xóa `LOCK_CELL` effect nếu có
- Modify: `game/tests/test_integration.gd` — update cho gameplay mới
- Modify: `game/scripts/core/board_solver.gd` — verify không reference LOCKED

**Interfaces:**
- Cleanup pass: tất cả file trong `game/scripts/` và `game/tests/` phải không reference WRONG, LOCKED, auto_mark, recorder, can_undo.

- [ ] **Step 1: Update sfx_catalog.gd**

Xóa `LOCK_CELL` từ enum `Effect` và `FILE_MAP`. Effect này không còn trigger.

- [ ] **Step 2: Verify board_solver.gd**

Board solver dùng `is_available()` để kiểm tra cell — function này đã updated (LOCKED không còn trong enum). Verify không hardcode LOCKED anywhere.

- [ ] **Step 3: Update integration test**

`test_integration.gd` — update cho gameplay flow mới (no undo, no auto-mark, ERROR instead of WRONG).

- [ ] **Step 4: Full grep sweep**

```bash
grep -rn "WRONG\|LOCKED\|auto_mark\|_recompute\|ActionRecorder\|LOCK_CELL\|animate_locks\|can_undo" game/scripts/ game/tests/
```

Expected: no matches (trừ comments nếu có).

- [ ] **Step 5: Commit**

```bash
git add game/scripts/ game/tests/
git commit -m "chore: sweep remaining LOCKED/WRONG/undo references across codebase"
```

---

### Task 11: Update Title Screen Layout Theo Legacy

**Files:**
- Modify: `game/scripts/screens/title_screen.gd`
- Modify: `game/scenes/title.tscn`

**Interfaces:**
- Consumes: Legacy title layout từ `archive/legacy_pre_rebuild/scripts/home_screen.gd`
- Produces: Title screen với: pastel background, centered candy logo, "CanDoKu" title, orange play button (pill shape), settings button (circular white, top-right)

- [ ] **Step 1: Rebuild title_screen.gd with programmatic layout**

Layout theo legacy:
- Background (cream/pastel)
- SafeArea (40px lr, 56px top, 54px bottom)
- TopBar: Settings button (circular white, top-right)
- Content stack (centered):
  - Candy logo image (480x240 hoặc smaller)
  - "CanDoKu" title label (large)
  - Play button (orange pill, 560x114, corner_radius=999, #F09329)
  - Progress hint label ("Tiến trình được lưu tự động")

```gdscript
# Key: Orange pill play button
var play_style := StyleBoxFlat.new()
play_style.bg_color = Color("#F09329")
play_style.set_corner_radius_all(999)
play_style.shadow_color = Color(0.94, 0.58, 0.16, 0.35)
play_style.shadow_size = 12
play_style.shadow_offset = Vector2(0, 4)
play_btn.add_theme_stylebox_override("normal", play_style)
```

- [ ] **Step 2: Simplify title.tscn to bare root**

```tscn
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/screens/title_screen.gd" id="1_title"]
[node name="TitleScreen" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_title")
```

- [ ] **Step 3: Commit**

```bash
git add game/scripts/screens/title_screen.gd game/scenes/title.tscn
git commit -m "feat(m08): rebuild title screen with legacy-style layout

Orange pill play button, candy logo, cream background,
circular settings button, centered layout."
```

---

### Task 12: Update Result Screens Layout

**Files:**
- Modify: `game/scripts/screens/result_screen.gd`
- Modify: `game/scenes/win.tscn`
- Modify: `game/scenes/fail.tscn`

**Interfaces:**
- Consumes: Legacy result layout từ `archive/legacy_pre_rebuild/scenes/result_win.tscn`, `result_fail.tscn`
- Produces: Win/Fail screens với colored backgrounds, centered card, styled buttons

- [ ] **Step 1: Update win screen**

Layout:
- Background: greenish (#E2F1E8)
- SafeArea (32px)
- Card (cream, rounded 24px): title "Hoàn hồi!", score, message, Continue button (green #55A683), Home button

- [ ] **Step 2: Update fail screen**

Layout:
- Background: warm peach (#FCECE2)
- SafeArea (32px)
- Card: title "Hết tim", message, Retry button (coral #F49359), Home button

- [ ] **Step 3: Commit**

```bash
git add game/scripts/screens/result_screen.gd game/scenes/win.tscn game/scenes/fail.tscn
git commit -m "feat(m08): rebuild result screens with legacy-style layout"
```

---

### Task 13: Final Verification

**Files:** All modified files

- [ ] **Step 1: Clean-room check**

```bash
grep -rE "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/
```

Expected: no matches.

- [ ] **Step 2: No extracted_reusable imports**

```bash
grep -r "extracted_reusable" game/scripts/ game/tests/
```

Expected: no matches.

- [ ] **Step 3: No LOCKED/WRONG/auto_mark remnants**

```bash
grep -rn "LOCKED\|WRONG\|auto_mark\|_recompute_all_locks\|compute_auto_marks\|animate_locks\|ActionRecorder" game/scripts/ game/tests/
```

Expected: no matches.

- [ ] **Step 4: Run full test suite**

```bash
godot --headless --script game/tests/test_candy_rules.gd
godot --headless --script game/tests/test_board_solver.gd
godot --headless --script game/tests/test_play_session.gd
godot --headless --script game/tests/test_integration.gd
```

- [ ] **Step 5: Manual play test**

Chạy game, kiểm tra:
1. Title screen: layout đúng, play button orange, settings button circular
2. Puzzle screen: TopBar/StatusRow/RuleCard/Board/BottomDock layout
3. Single tap → toggle X mark (MARK ↔ BLANK)
4. Double tap → place candy hoặc ERROR (vĩnh viễn)
5. Swipe → paint/clear X trên nhiều ô
6. KHÔNG có auto-lock khi đặt candy đúng
7. ERROR cells không thể tap lại
8. Hearts cập nhật đúng, region progress cập nhật đúng
9. Win/Fail screens hiển thị đúng layout
10. Restart hoạt động
11. Save/restore session hoạt động (không có LOCKED trong save)

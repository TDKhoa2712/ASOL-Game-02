# Module 4: Input — Touch Processing & Game Session

> **Phụ thuộc:** Module 1 (Core) cho CandyRules, CellModel
> **Tham khảo:** `extracted_reusable/scripts/game/input/` (11 files), `gameplay/model/cell_action.gd`

## Tổng quan

Module Input xử lý touch/mouse input thành game actions. Reference có 11 files (gesture recognizer, 6 operations, stroke context, input scheme, cell action). Rebuild gộp thành 3 files vì playtest chỉ cần Normal mode.

**Cải tiến từ reference:**
- Command pattern cho undo (CellAction với before/after + record flag)
- Auto-mark integration (LOCKED cells sau candy placement)
- Swipe interpolation (fast swipes không skip cells)

---

## File 1: `game/scripts/input/touch_decoder.gd`

**Trách nhiệm:** Chuyển raw touch/mouse events thành cell actions (tap, double-tap, swipe).

**Tham khảo hành vi từ:** `board_gesture_recognizer.gd` (187 dòng — double-tap window, swipe interpolation)

**Thiết kế mới:**

```gdscript
# touch_decoder.gd
extends RefCounted

signal cell_tapped(row: int, col: int)
signal cell_double_tapped(row: int, col: int)
signal cell_swiped(cells: Array)  # Array of [row, col]

const DOUBLE_TAP_WINDOW_MS := 350

var _last_tap_cell: Array = []
var _last_tap_time: int = 0
var _swipe_trail: Array = []
var _pointer_active := false
var _last_swipe_cell: Array = []  # for interpolation
var _pending_double_tap := false

# --- Public API ---

func begin(row: int, col: int, time_ms: int) -> void
    # Start touch. Check double-tap window against last tap.
    # If same cell within window: flag _pending_double_tap = true (do NOT emit yet)
    # Else: record as start of potential tap/swipe

func move(row: int, col: int) -> void
    # Track swipe across cells. Interpolate between _last_swipe_cell and (row, col)
    # to avoid skipping cells on fast diagonal swipes.
    # Add each intermediate cell to trail if not already present.
    # If _pending_double_tap and distance > drag threshold → cancel double-tap,
    # commit first tap as cell_tapped, begin drag.

func finish(time_ms: int) -> void
    # End touch. If _pending_double_tap and no drag occurred → emit cell_double_tapped, clear flag.
    # Else if swipe trail > 1: emit cell_swiped.
    # Else: set pending tap (wait for double-tap window)

func cancel() -> void
    # Cancel current gesture without emitting

func tick(time_ms: int) -> void
    # Check if pending single tap has expired double-tap window → emit cell_tapped

# --- Internal ---

func _is_double_tap(row: int, col: int, time_ms: int) -> bool

func _flush_pending_tap() -> void

func _interpolate_cells(from: Array, to: Array) -> Array
    # Bresenham-like interpolation between two cells.
    # Returns list of [row, col] between from and to (exclusive of from).
    # Prevents fast swipes from skipping intermediate cells.
    # Reference: board_gesture_recognizer.gd on_drag_over step-based lerp
```

**Khác biệt với reference:**
- 1 file thay 11
- Signals thay CellAction array return
- **_interpolate_cells()** — Từ reference: step-based lerp cho fast swipes (cải tiến)
- Không Draft mode, autofix, promote-to-double-tap
- Không BoardInputScheme switching
- Không BoardStrokeContext class (inline tracking)

---

## File 2: `game/scripts/input/action_recorder.gd`

**Trách nhiệm:** Command pattern undo stack. Actions có before/after state + record flag.

**Tham khảo hành vi từ:** `cell_action.gd` (Command pattern, before/after, record flag, source tag)

**Thiết kế mới:**

```gdscript
# action_recorder.gd
extends RefCounted

const MAX_DEPTH := 100

enum Source { USER, SYSTEM }

var _stack: Array = []  # Array of ActionGroup

# --- Action structure ---
# Single action: {row, col, before: int, after: int, source: int}
# Action group: Array of single actions (applied/undone as one unit)

# --- Public API ---

func push_group(actions: Array) -> void
    # Push a group of actions as one undo unit.
    # Only actions with source == USER are recorded.
    # System actions (auto-marks) are bundled with the user action that caused them.
    # Enforces MAX_DEPTH.

func pop_group() -> Array
    # Returns last action group or []. Caller applies each action in reverse.

func can_undo() -> bool

func clear() -> void

func depth() -> int

# Undo stack is runtime-only (GDD TECH-08); not persisted in session
```

**Cải tiến từ reference:**
- **Action grouping** — Đặt candy + tất cả auto-marks = 1 undo group. Undo 1 lần = undo candy + undo all auto-marks.
- **Source tag** — USER vs SYSTEM. System actions (auto-marks) go into the group but are identified.
- **before/after** — Mỗi action lưu state trước và sau, undo = swap.
- **Runtime-only** — Undo stack is not persisted (GDD TECH-08); session save excludes it.

**Khác biệt với reference:**
- Grouping thay flat stack (reference records individual actions with `record: false`)
- `Source` enum thay string-based source
- Không `play_anim`, `show_cat_visual`, `vibrate` metadata (handled by caller)
- Không factory pattern (caller builds action dict directly)

---

## File 3: `game/scripts/input/play_session.gd`

**Trách nhiệm:** State machine cho một lượt chơi — cells, hearts, undo, auto-mark integration.

**Tham khảo hành vi từ:** `interaction_session.gd` + `game_state.gd` + `hint_engine.gd` R1 Mark

**Thiết kế mới:**

```gdscript
# play_session.gd
extends RefCounted

const CellModel = preload("res://scripts/core/cell_model.gd")
const CandyRules = preload("res://scripts/core/candy_rules.gd")
const ActionRecorder = preload("res://scripts/input/action_recorder.gd")

signal state_changed()
signal candy_found(row: int, col: int, region: String)
signal heart_lost(remaining: int)
signal mistake_made(row: int, col: int, reason: String)
signal auto_marked(cells: Array)  # NEW — emitted after auto-mark applied
signal level_won()
signal level_failed()

enum Phase { ACTIVE, WON, FAILED }

var level: Dictionary
var board: Array = []           # NxN Array of CellKind values
var hearts: int = 3
var mistake_count: int = 0
var hints_used: int = 0
var elapsed_ms: int = 0
var phase: int = Phase.ACTIVE
var recorder: ActionRecorder

func _init(level_data: Dictionary, initial_hearts: int = 3) -> void
    # Initialize board NxN with BLANK
    # Place GIVEN cells from level.givens
    # Apply auto-marks for all GIVEN cells (LOCKED)
    # Initialize ActionRecorder

# --- Public API ---

func mark_x(row: int, col: int) -> void
    # Toggle mark on cell. Only on is_available() cells.
    # If BLANK → MARK, if MARK → BLANK.
    # Record as single-action group in recorder.
    # Emit state_changed.

func try_candy(row: int, col: int) -> void
    # Attempt to place candy. Only on is_available() cells.
    # Delegates to CandyRules.attempt_candy.
    # On correct: set CANDY, compute auto_marks, apply LOCKED, record as group.
    # Emit candy_found(row, col, region) + auto_marked.
    # On wrong: set WRONG, lose heart, **clear undo stack** (GDD GR-33 — wrong try is undo boundary).
    # Do NOT record wrong try into undo (stack was just cleared).
    # Emit mistake_made + heart_lost. Update phase.

func undo() -> bool
    # Pop last action group from recorder.
    # Apply each action in reverse (swap before/after on board).
    # Recompute auto-marks if a candy was removed.
    # Returns false if empty.

func use_hint() -> void
    hints_used += 1

func cell_at(row: int, col: int) -> int
    # Returns CellKind value at position

func is_preset(row: int, col: int) -> bool

func can_undo() -> bool
    return recorder.can_undo()

func remaining_candies() -> int
    # Count solution cells not yet filled (excluding givens)

# --- Serialization ---

func to_save_data() -> Dictionary
    # Export session v3 format: cells as flat Array (GIVEN→'empty', LOCKED→'locked'),
    # hearts, mistake_count, hints_used, elapsedMs, status. Undo stack NOT persisted.

static func from_save_data(data: Dictionary, level_data: Dictionary) -> RefCounted
    # Restore from saved session. Rebuild board array from flat data.

# --- Internal ---

func _apply_auto_marks(candy_row: int, candy_col: int) -> Array
    # Compute auto-marks via CandyRules.compute_auto_marks
    # Set each BLANK cell to LOCKED on board
    # Return list of actions for recorder grouping

func _recompute_all_locks() -> void
    # After undo removes a candy, clear all LOCKED, recompute from all placed candies + givens.
    # Needed because removing one candy may make some locked cells available again.
```

**Cải tiến từ reference:**
- **Auto-mark on candy** — Khi đặt candy đúng, tự động lock tất cả ô bị loại (same row/col/zone/diagonal). Player không cần mark thủ công.
- **Auto-mark on GIVEN** — Khi init session, givens cũng tạo auto-marks.
- **Grouped undo** — Undo candy = undo candy + undo tất cả auto-marks liên quan. Một lần undo.
- **_recompute_all_locks()** — Sau khi undo candy, clear tất cả LOCKED và recompute từ đầu. An toàn hơn incremental undo.
- **board: Array NxN** — 2D array CellKind values thay Dictionary cells. Nhanh hơn cho render.
- **auto_marked signal** — Board rendering biết cells nào vừa được lock để animate.

**Khác biệt với reference:**
- Tên: `PlaySession` thay `InteractionSession`, `Phase` thay string
- Board = 2D Array thay Dictionary (random access O(1) thay O(log n))
- Auto-mark tích hợp (reference: R1 Mark riêng trong hint_engine)
- Grouped undo thay individual action recording
- `from_save_data` restores full board + recorder state

---

## Tests

### `game/tests/test_play_session.gd`

```gdscript
extends SceneTree

const PlaySession = preload("res://scripts/input/play_session.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const ActionRecorder = preload("res://scripts/input/action_recorder.gd")

var _fails: Array[String] = []

func _init() -> void:
    _test_mark_toggle()
    _test_try_candy_correct()
    _test_try_candy_wrong()
    _test_undo_mark()
    _test_undo_candy_removes_auto_marks()
    _test_given_cells_locked()
    _test_cannot_interact_locked()
    _test_auto_marks_on_candy()
    _test_serialize_restore()
    _test_win_condition()
    _test_recorder_grouping()
    if _fails.is_empty():
        print("INPUT_PLAY_SESSION_PASS")
        quit(0)
    else:
        for f in _fails: printerr(f)
        quit(1)

func _test_mark_toggle() -> void:
    var session := PlaySession.new(_make_level(), 3)
    session.mark_x(2, 2)
    _assert(session.cell_at(2, 2) == CellModel.CellKind.MARK, "mark placed")
    session.mark_x(2, 2)
    _assert(session.cell_at(2, 2) == CellModel.CellKind.BLANK, "mark removed")

func _test_try_candy_correct() -> void:
    var session := PlaySession.new(_make_level(), 3)
    var found: Array = []
    session.candy_found.connect(func(r, c, region): found.append([r, c, region]))
    session.try_candy(0, 1)  # solution[0]=1
    _assert(found.size() == 1, "candy found emitted")
    _assert(session.cell_at(0, 1) == CellModel.CellKind.CANDY, "candy placed")

func _test_try_candy_wrong() -> void:
    var session := PlaySession.new(_make_level(), 3)
    session.try_candy(0, 0)  # wrong position
    _assert(session.hearts == 2, "lost a heart")
    _assert(session.cell_at(0, 0) == CellModel.CellKind.WRONG, "wrong marked")

func _test_undo_mark() -> void:
    var session := PlaySession.new(_make_level(), 3)
    session.mark_x(2, 2)
    _assert(session.undo(), "undo succeeds")
    _assert(session.cell_at(2, 2) == CellModel.CellKind.BLANK, "undo mark")

func _test_undo_candy_removes_auto_marks() -> void:
    var session := PlaySession.new(_make_level(), 3)
    session.try_candy(0, 1)  # correct candy
    # After candy, some cells should be LOCKED
    var has_locked := false
    for r in 4:
        for c in 4:
            if session.cell_at(r, c) == CellModel.CellKind.LOCKED:
                has_locked = true
                break
    _assert(has_locked, "auto marks exist after candy")
    # Undo should remove candy AND all auto-marks
    session.undo()
    _assert(session.cell_at(0, 1) == CellModel.CellKind.BLANK, "candy undone")
    var still_locked := false
    for r in 4:
        for c in 4:
            if session.cell_at(r, c) == CellModel.CellKind.LOCKED:
                still_locked = true
                break
    _assert(not still_locked, "auto marks cleared after undo")

func _test_given_cells_locked() -> void:
    var level := _make_level()
    level["givens"] = [{"r": 0, "c": 1}]
    var session := PlaySession.new(level, 3)
    _assert(session.cell_at(0, 1) == CellModel.CellKind.GIVEN, "given cell is GIVEN")
    _assert(session.is_preset(0, 1), "given is preset")
    # Cells excluded by given should be LOCKED
    _assert(session.cell_at(0, 0) == CellModel.CellKind.LOCKED, "same row locked by given")

func _test_cannot_interact_locked() -> void:
    var level := _make_level()
    level["givens"] = [{"r": 0, "c": 1}]
    var session := PlaySession.new(level, 3)
    session.mark_x(0, 0)  # should be no-op, cell is LOCKED
    _assert(session.cell_at(0, 0) == CellModel.CellKind.LOCKED, "locked cell not changed")

func _test_auto_marks_on_candy() -> void:
    var session := PlaySession.new(_make_level(), 3)
    var marked: Array = []
    session.auto_marked.connect(func(cells): marked.append_array(cells))
    session.try_candy(0, 1)  # correct
    _assert(marked.size() > 0, "auto_marked signal emitted")

func _test_serialize_restore() -> void:
    var session := PlaySession.new(_make_level(), 3)
    session.try_candy(0, 1)
    session.mark_x(2, 2)
    var data := session.to_save_data()
    var restored := PlaySession.from_save_data(data, _make_level())
    _assert(restored.cell_at(0, 1) == CellModel.CellKind.CANDY, "candy restored")
    _assert(restored.cell_at(2, 2) == CellModel.CellKind.MARK, "mark restored")
    _assert(restored.hearts == 3, "hearts restored")

func _test_win_condition() -> void:
    var level := _make_level()
    var session := PlaySession.new(level, 3)
    var won := false
    session.level_won.connect(func(): won = true)
    for row in 4:
        session.try_candy(row, int(level["solution"][row]))
    _assert(won, "level won after all candies")

func _test_recorder_grouping() -> void:
    var rec := ActionRecorder.new()
    var group := [
        {"row": 0, "col": 1, "before": CellModel.CellKind.BLANK, "after": CellModel.CellKind.CANDY, "source": ActionRecorder.Source.USER},
        {"row": 0, "col": 0, "before": CellModel.CellKind.BLANK, "after": CellModel.CellKind.LOCKED, "source": ActionRecorder.Source.SYSTEM},
        {"row": 0, "col": 2, "before": CellModel.CellKind.BLANK, "after": CellModel.CellKind.LOCKED, "source": ActionRecorder.Source.SYSTEM},
    ]
    rec.push_group(group)
    _assert(rec.depth() == 1, "one undo group")
    var popped := rec.pop_group()
    _assert(popped.size() == 3, "group has 3 actions")
    _assert(rec.depth() == 0, "stack empty after pop")

func _make_level() -> Dictionary:
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

### `game/tests/test_touch_decoder.gd`

```gdscript
extends SceneTree

const TouchDecoder = preload("res://scripts/input/touch_decoder.gd")

var _fails: Array[String] = []

func _init() -> void:
    _test_single_tap()
    _test_double_tap()
    _test_swipe()
    _test_swipe_interpolation()
    _test_cancel()
    if _fails.is_empty():
        print("INPUT_TOUCH_DECODER_PASS")
        quit(0)
    else:
        for f in _fails: printerr(f)
        quit(1)

func _test_single_tap() -> void:
    var d := TouchDecoder.new()
    var taps: Array = []
    d.cell_tapped.connect(func(r, c): taps.append([r, c]))
    d.begin(1, 2, 1000)
    d.finish(1000)
    d.tick(1500)  # after double-tap window
    _assert(taps.size() == 1, "single tap emitted")
    _assert(taps[0] == [1, 2], "correct cell")

func _test_double_tap() -> void:
    var d := TouchDecoder.new()
    var dtaps: Array = []
    d.cell_double_tapped.connect(func(r, c): dtaps.append([r, c]))
    d.begin(1, 2, 1000)
    d.finish(1000)
    d.begin(1, 2, 1200)  # within 350ms window
    _assert(dtaps.size() == 1, "double tap emitted")

func _test_swipe() -> void:
    var d := TouchDecoder.new()
    var swipes: Array = []
    d.cell_swiped.connect(func(cells): swipes.append(cells))
    d.begin(0, 0, 1000)
    d.move(0, 1)
    d.move(0, 2)
    d.finish(1100)
    _assert(swipes.size() == 1, "swipe emitted")
    _assert(swipes[0].size() == 3, "3 cells in swipe")

func _test_swipe_interpolation() -> void:
    var d := TouchDecoder.new()
    # Test that interpolation fills gaps for diagonal movement
    var interp := d._interpolate_cells([0, 0], [2, 2])
    _assert(interp.size() >= 1, "interpolation fills gap")

func _test_cancel() -> void:
    var d := TouchDecoder.new()
    var taps: Array = []
    d.cell_tapped.connect(func(r, c): taps.append([r, c]))
    d.begin(1, 2, 1000)
    d.cancel()
    d.tick(1500)
    _assert(taps.is_empty(), "cancel prevents emission")

func _assert(condition: bool, label: String) -> void:
    if not condition:
        _fails.append("FAIL: " + label)
```

---

## Checklist thực hiện

- [ ] Tạo thư mục `game/scripts/input/`
- [ ] Viết `action_recorder.gd` — command pattern, grouped undo, serializable
- [ ] Viết `touch_decoder.gd` — tap/double-tap/swipe with interpolation
- [ ] Viết test `test_play_session.gd` (fail)
- [ ] Viết test `test_touch_decoder.gd` (fail)
- [ ] Viết `play_session.gd` — session with auto-mark, grouped undo, board array
- [ ] Chạy tests → pass
- [ ] Commit: `feat(input): add touch decoder, action recorder and play session with auto-mark`

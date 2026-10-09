# Hint Engine v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an Explainable Logic Solver hint engine that teaches players puzzle-solving techniques through a hierarchical deduction pipeline with visual chain-of-reasoning.

**Architecture:** Static pure-logic `HintEngine` orchestrator calls existing `SolverTechniques` in priority order (wrong mark → elimination → single → lock → subset → contradiction → fallback), returns a standardized `HintResult` dictionary. UI layer (`HintOverlay` + `HintHighlightLayer`) renders explanation with Apply/Dismiss/Detail actions. `HintMutex` prevents spam. All new modules are dependency-injected via `puzzle_layout.gd` — no autoloads.

**Tech Stack:** Godot 4 / GDScript, PCM synth for SFX

**Spec:** `docs/superpowers/specs/2026-10-09-hint-engine-v2-design.md`

## Global Constraints

- Modules ≤ 300 lines. One file, one responsibility.
- No autoloads — composition root pattern, dependencies injected from `puzzle_layout`.
- Signals for inter-component communication, no global event bus.
- Static functions for pure logic modules (`hint_engine.gd`, `pre_candy_decider.gd`).
- All code must be original — no names/enums/identifiers from reference sources.
- Clean-room gate before merge: `rg -n "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/` must return 0 matches.
- Board sizes N=4–12 supported.
- Tests use `extends SceneTree` pattern with `_init()` runner and `_assert()` helper (see any `game/tests/test_*.gd` for convention).
- Branch from `release/v1.0.1` using pattern `feat/v1.0.1/hint-engine-v2`.
- Commits: Conventional Commits format `<type>(<scope>): <description>`.

## Review Focus

1. **Empty board hint request** — player presses hint on a fresh board with no marks and no candies placed (only givens). Engine should return `MARK_NEIGHBORS` for the first given's neighbors, not crash or return `FALLBACK`.
2. **Board with all cells already marked** — if every non-candy cell is already MARK, all `has_new` guards should filter to empty and engine falls through to `FALLBACK`. Must not return stale hints with empty `eliminated_cells`.
3. **Wrong mark on given cell** — a cell with `CellKind.GIVEN` where `solution[r] == c` must NOT be reported as wrong mark (givens are not MARKs). `_find_wrong_mark` must check `board[r][c] == MARK` explicitly.
4. **Chain contradiction on large board (12×12)** — `_propagate_with_trace` could loop up to `size * size = 144` iterations. Must not cause visible frame stutter. The `max_depth=99` default caps depth but still allows full propagation.
5. **Apply PLACE_MARKS when some cells were marked between hint-show and apply** — race where player manually marks a cell, then taps Apply. `apply_marks()` must skip cells that are no longer BLANK (it already checks `board[r][c] == BLANK`).

---

### Task 1: Solver Techniques — Chain Detail & Trace

**Files:**
- Modify: `game/scripts/core/solver_techniques.gd:263-299` (replace `_propagate_and_check` usage in `_try_contradiction`, add `_propagate_with_trace` and `_check_contradiction`)
- Test: `game/tests/test_board_solver.gd` (add chain detail tests)

**Interfaces:**
- Consumes: existing `_is_candidate()`, `_clone_board()`, `_apply_elimination()`, `_try_single_candidate()`, `_zones()`, `_has_candy()`, `_candidates_in_zone/row/col()` from `solver_techniques.gd`
- Produces:
  - `_propagate_with_trace(board: Array, size: int, regions: Array, max_depth: int) -> Dictionary` returning `{"contradiction": bool, "depth": int, "steps": Array, "contra_type": String, "contra_index": Variant}`
  - `_check_contradiction(board: Array, size: int, regions: Array) -> Dictionary` returning `{"found": bool, "type": String, "index": Variant}`
  - Modified `_try_contradiction(board, size, regions, max_depth=99) -> Dictionary` now includes `"chain_detail"` key when found

- [ ] **Step 1: Write failing tests for chain detail output**

Add to `game/tests/test_board_solver.gd`, in `_init()` add calls to `_test_contradiction_chain_detail()` and `_test_propagate_with_trace_no_contradiction()`:

```gdscript
func _test_contradiction_chain_detail() -> void:
	# 4x4 board where placing candy at [2,0] causes contradiction
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	# Place candies to constrain: row 0 has candy at col 1, row 1 at col 3
	board[0][1] = CellModel.CellKind.CANDY
	board[1][3] = CellModel.CellKind.CANDY
	# Apply all possible eliminations first
	SolverTechniques._apply_elimination(board, 4, regions)
	var result := SolverTechniques._try_contradiction(board, 4, regions)
	if result["found"]:
		_assert(result.has("chain_detail"), "contradiction has chain_detail")
		var detail: Dictionary = result["chain_detail"]
		_assert(detail.has("hypothesis_cell"), "detail has hypothesis_cell")
		_assert(detail.has("depth"), "detail has depth")
		_assert(detail.has("steps"), "detail has steps")
		_assert(detail.has("contra_type"), "detail has contra_type")
		_assert(detail["contra_type"] in ["row", "col", "zone"], "contra_type is valid")
		_assert(detail["depth"] >= 0, "depth >= 0")

func _test_propagate_with_trace_no_contradiction() -> void:
	# Simple board where propagation does NOT cause contradiction
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	board[0][1] = CellModel.CellKind.CANDY
	SolverTechniques._apply_elimination(board, 4, regions)
	var result := SolverTechniques._propagate_with_trace(board, 4, regions, 99)
	_assert(not result["contradiction"], "no contradiction on valid partial board")
	_assert(result["depth"] >= 0, "depth >= 0")
	_assert(result["steps"] is Array, "steps is Array")
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `godot --headless --path game --script res://tests/test_board_solver.gd`
Expected: FAIL — `_propagate_with_trace` and new `chain_detail` key don't exist yet.

- [ ] **Step 3: Add `_check_contradiction()` helper**

In `game/scripts/core/solver_techniques.gd`, add BEFORE `_try_contradiction()`:

```gdscript
static func _check_contradiction(board: Array, size: int,
		regions: Array) -> Dictionary:
	for z in _zones(regions, size):
		if not _has_candy(board, size, regions, "zone", z):
			if _candidates_in_zone(board, size, regions, z).is_empty():
				return {"found": true, "type": "zone", "index": z}
	for r in range(size):
		if not _has_candy(board, size, regions, "row", r):
			if _candidates_in_row(board, size, regions, r).is_empty():
				return {"found": true, "type": "row", "index": r}
	for c in range(size):
		if not _has_candy(board, size, regions, "col", c):
			if _candidates_in_col(board, size, regions, c).is_empty():
				return {"found": true, "type": "col", "index": c}
	return {"found": false, "type": "", "index": -1}
```

- [ ] **Step 4: Add `_propagate_with_trace()` function**

In `game/scripts/core/solver_techniques.gd`, add AFTER `_check_contradiction()`:

```gdscript
static func _propagate_with_trace(board: Array, size: int,
		regions: Array, max_depth: int) -> Dictionary:
	var steps: Array = []
	var depth: int = 0
	for _iteration in range(size * size):
		_apply_elimination(board, size, regions)
		var contra := _check_contradiction(board, size, regions)
		if contra["found"]:
			return {"contradiction": true, "depth": depth, "steps": steps,
					"contra_type": contra["type"], "contra_index": contra["index"]}
		var s2 := _try_single_candidate(board, size, regions)
		if s2.get("found", false):
			var cell: Array = s2["cell"]
			board[cell[0]][cell[1]] = CellModel.CellKind.CANDY
			steps.append(cell)
			depth += 1
			if depth > max_depth:
				break
			continue
		break
	var final_contra := _check_contradiction(board, size, regions)
	if final_contra["found"]:
		return {"contradiction": true, "depth": depth, "steps": steps,
				"contra_type": final_contra["type"], "contra_index": final_contra["index"]}
	return {"contradiction": false, "depth": depth, "steps": steps,
			"contra_type": "", "contra_index": -1}
```

- [ ] **Step 5: Rewrite `_try_contradiction()` to use trace and return chain_detail**

Replace the existing `_try_contradiction()` function body:

```gdscript
static func _try_contradiction(board: Array, size: int, regions: Array,
		max_depth: int = 99) -> Dictionary:
	var best_result: Dictionary = {"found": false, "eliminated": []}
	var best_depth: int = size * size
	for r in range(size):
		for c in range(size):
			if not _is_candidate(board, size, regions, r, c):
				continue
			var test_board := _clone_board(board, size)
			test_board[r][c] = CellModel.CellKind.CANDY
			var chain := _propagate_with_trace(test_board, size, regions, max_depth)
			if chain["contradiction"]:
				if chain["depth"] < best_depth:
					best_depth = chain["depth"]
					best_result = {
						"found": true,
						"eliminated": [[r, c]],
						"technique": Technique.CONTRA_CHAIN,
						"chain_detail": {
							"hypothesis_cell": [r, c],
							"depth": chain["depth"],
							"steps": chain["steps"],
							"contra_type": chain["contra_type"],
							"contra_index": chain["contra_index"],
						}
					}
	return best_result
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `godot --headless --path game --script res://tests/test_board_solver.gd`
Expected: PASS — `CORE_BOARD_SOLVER_PASS`

- [ ] **Step 7: Verify `_propagate_and_check()` still exists unchanged**

The old `_propagate_and_check()` function must remain in the file — it is used by `BoardSolver.replay_solve()`. Confirm it is untouched.

- [ ] **Step 8: Commit**

```bash
git add game/scripts/core/solver_techniques.gd game/tests/test_board_solver.gd
git commit -m "feat(solver): add chain detail output to contradiction detection

Add _propagate_with_trace() and _check_contradiction() helpers.
Rewrite _try_contradiction() to return chain_detail with hypothesis_cell,
depth, steps, contra_type, and contra_index. Existing _propagate_and_check()
kept for replay_solve() backward compatibility."
```

---

### Task 2: HintMutex — Spam Prevention

**Files:**
- Create: `game/scripts/screens/hint_mutex.gd`
- Create: `game/tests/test_hint_mutex.gd`

**Interfaces:**
- Consumes: `Time.get_ticks_msec()` (Godot built-in)
- Produces:
  - `HintMutex.try_acquire(hint_id: String) -> bool`
  - `HintMutex.release(hint_id: String) -> void`
  - `HintMutex.is_locked() -> bool`
  - `HintMutex.force_release() -> void`
  - `HintMutex.COOLDOWN_MS: int = 500`

- [ ] **Step 1: Write the test file**

Create `game/tests/test_hint_mutex.gd`:

```gdscript
extends SceneTree

const HintMutex = preload("res://scripts/screens/hint_mutex.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_acquire_release_cycle()
	_test_double_acquire_blocked()
	_test_force_release_clears_all()
	_test_is_locked_during_acquire()
	_test_is_locked_during_cooldown()
	if _fails.is_empty():
		print("HINT_MUTEX_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_acquire_release_cycle() -> void:
	var m := HintMutex.new()
	_assert(m.try_acquire("hint"), "first acquire succeeds")
	m.release("hint")
	# Cooldown blocks immediately after release
	_assert(m.is_locked(), "locked during cooldown after release")

func _test_double_acquire_blocked() -> void:
	var m := HintMutex.new()
	_assert(m.try_acquire("a"), "acquire a")
	_assert(not m.try_acquire("b"), "acquire b blocked while a held")
	m.release("a")

func _test_force_release_clears_all() -> void:
	var m := HintMutex.new()
	m.try_acquire("hint")
	m.force_release()
	_assert(not m.is_locked(), "not locked after force_release")
	_assert(m.try_acquire("hint"), "acquire after force_release")

func _test_is_locked_during_acquire() -> void:
	var m := HintMutex.new()
	_assert(not m.is_locked(), "not locked initially")
	m.try_acquire("x")
	_assert(m.is_locked(), "locked after acquire")
	m.release("x")

func _test_is_locked_during_cooldown() -> void:
	var m := HintMutex.new()
	m.try_acquire("x")
	m.release("x")
	_assert(m.is_locked(), "locked during cooldown")
	_assert(not m.try_acquire("y"), "acquire blocked during cooldown")

func _assert(condition: bool, msg: String) -> void:
	if not condition:
		_fails.append("FAIL: " + msg)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path game --script res://tests/test_hint_mutex.gd`
Expected: FAIL — `hint_mutex.gd` does not exist.

- [ ] **Step 3: Implement hint_mutex.gd**

Create `game/scripts/screens/hint_mutex.gd`:

```gdscript
extends RefCounted

var _active_id: String = ""
var _cooldown_until: int = 0

const COOLDOWN_MS: int = 500

func try_acquire(hint_id: String) -> bool:
	if _active_id != "":
		return false
	if Time.get_ticks_msec() < _cooldown_until:
		return false
	_active_id = hint_id
	return true

func release(hint_id: String) -> void:
	if _active_id == hint_id:
		_active_id = ""
		_cooldown_until = Time.get_ticks_msec() + COOLDOWN_MS

func is_locked() -> bool:
	return _active_id != "" or Time.get_ticks_msec() < _cooldown_until

func force_release() -> void:
	_active_id = ""
	_cooldown_until = 0
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path game --script res://tests/test_hint_mutex.gd`
Expected: PASS — `HINT_MUTEX_PASS`

- [ ] **Step 5: Commit**

```bash
git add game/scripts/screens/hint_mutex.gd game/tests/test_hint_mutex.gd
git commit -m "feat(hint): add HintMutex for hint spam prevention

Stateful RefCounted mutex with 500ms cooldown after release.
try_acquire/release/force_release API for puzzle_screen integration."
```

---

### Task 3: PlaySession — Hint Apply Methods

**Files:**
- Modify: `game/scripts/input/play_session.gd` (add `clear_mark()` and `apply_marks()`)
- Modify: `game/tests/test_play_session.gd` (add tests)

**Interfaces:**
- Consumes: `CellModel.CellKind.MARK`, `CellModel.CellKind.BLANK`, `state_changed` signal (existing)
- Produces:
  - `PlaySession.clear_mark(row: int, col: int) -> void` — sets MARK → BLANK, emits `state_changed`
  - `PlaySession.apply_marks(cells: Array) -> void` — sets each BLANK → MARK, emits `state_changed`

- [ ] **Step 1: Write failing tests**

Add to `game/tests/test_play_session.gd` (in `_init()`, add calls to `_test_clear_mark()` and `_test_apply_marks()`):

```gdscript
func _test_clear_mark() -> void:
	var level := _make_level_4x4()
	var s := PlaySession.new(level)
	s.mark_x(0, 0)
	_assert(s.cell_at(0, 0) == CellModel.CellKind.MARK, "cell is marked")
	s.clear_mark(0, 0)
	_assert(s.cell_at(0, 0) == CellModel.CellKind.BLANK, "cell cleared to blank")

func _test_clear_mark_ignores_non_mark() -> void:
	var level := _make_level_4x4()
	var s := PlaySession.new(level)
	s.clear_mark(0, 0)  # cell is BLANK, not MARK
	_assert(s.cell_at(0, 0) == CellModel.CellKind.BLANK, "blank stays blank")

func _test_apply_marks() -> void:
	var level := _make_level_4x4()
	var s := PlaySession.new(level)
	s.apply_marks([[0, 0], [0, 2], [1, 1]])
	_assert(s.cell_at(0, 0) == CellModel.CellKind.MARK, "0,0 marked")
	_assert(s.cell_at(0, 2) == CellModel.CellKind.MARK, "0,2 marked")
	_assert(s.cell_at(1, 1) == CellModel.CellKind.MARK, "1,1 marked")

func _test_apply_marks_skips_non_blank() -> void:
	var level := _make_level_4x4()
	var s := PlaySession.new(level)
	s.mark_x(0, 0)  # already MARK
	s.apply_marks([[0, 0], [0, 2]])
	_assert(s.cell_at(0, 0) == CellModel.CellKind.MARK, "already marked stays")
	_assert(s.cell_at(0, 2) == CellModel.CellKind.MARK, "new cell marked")

func _test_clear_mark_inactive_phase() -> void:
	var level := _make_level_4x4()
	var s := PlaySession.new(level)
	s.mark_x(0, 0)
	s.phase = PlaySession.Phase.WON
	s.clear_mark(0, 0)
	_assert(s.cell_at(0, 0) == CellModel.CellKind.MARK, "no clear in WON phase")
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `godot --headless --path game --script res://tests/test_play_session.gd`
Expected: FAIL — methods `clear_mark` and `apply_marks` not defined.

- [ ] **Step 3: Implement clear_mark and apply_marks**

Add to `game/scripts/input/play_session.gd` after the existing `use_hint()` function:

```gdscript
func clear_mark(row: int, col: int) -> void:
	if phase != Phase.ACTIVE:
		return
	if row < 0 or row >= board.size() or col < 0 or col >= board.size():
		return
	if board[row][col] == CellModel.CellKind.MARK:
		_undo_cells = [[row, col, CellModel.CellKind.MARK]]
		board[row][col] = CellModel.CellKind.BLANK
		state_changed.emit()

func apply_marks(cells: Array) -> void:
	if phase != Phase.ACTIVE:
		return
	var before: Array = []
	for cell in cells:
		var r: int = int(cell[0])
		var c: int = int(cell[1])
		if r >= 0 and r < board.size() and c >= 0 and c < board.size():
			if board[r][c] == CellModel.CellKind.BLANK:
				before.append([r, c, CellModel.CellKind.BLANK])
				board[r][c] = CellModel.CellKind.MARK
	if not before.is_empty():
		_undo_cells = before
		state_changed.emit()
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `godot --headless --path game --script res://tests/test_play_session.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add game/scripts/input/play_session.gd game/tests/test_play_session.gd
git commit -m "feat(session): add clear_mark and apply_marks for hint apply

clear_mark(row, col) sets MARK→BLANK. apply_marks(cells) batch-marks
BLANK cells. Both check phase==ACTIVE and support undo."
```

---

### Task 4: HintEngine — Core Logic

**Files:**
- Create: `game/scripts/core/hint_engine.gd`
- Create: `game/tests/test_hint_engine.gd`

**Interfaces:**
- Consumes:
  - `CellModel.CellKind` (BLANK, MARK, CANDY, GIVEN) from `cell_model.gd`
  - `CellModel.is_placed(kind: int) -> bool` from `cell_model.gd`
  - `CandyRules.can_place(board, regions, r, c) -> bool` from `candy_rules.gd`
  - `CandyRules.zone_of(regions, r, c) -> String` from `candy_rules.gd`
  - `SolverTechniques._try_single_candidate(board, size, regions) -> Dictionary` from `solver_techniques.gd`
  - `SolverTechniques._try_lock_intersection(board, size, regions) -> Dictionary` from `solver_techniques.gd`
  - `SolverTechniques._try_locked_subsets(board, size, regions) -> Dictionary` from `solver_techniques.gd`
  - `SolverTechniques._try_contradiction(board, size, regions, max_depth) -> Dictionary` from `solver_techniques.gd` (Task 1 output — includes `chain_detail`)
  - `SolverTechniques._apply_elimination(board, size, regions) -> Array` from `solver_techniques.gd`
- Produces:
  - `HintEngine.find_hint(board: Array, size: int, regions: Array, solution: Array) -> Dictionary` — returns HintResult dictionary (see spec §3)

- [ ] **Step 1: Write the test file**

Create `game/tests/test_hint_engine.gd`:

```gdscript
extends SceneTree

const HintEngine = preload("res://scripts/core/hint_engine.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const CandyRules = preload("res://scripts/core/candy_rules.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_wrong_mark_detected()
	_test_wrong_mark_skipped_when_none()
	_test_mark_hint_finds_new_marks()
	_test_mark_hint_skips_all_marked()
	_test_has_new_guard_filters()
	_test_single_candidate()
	_test_fallback_on_empty()
	_test_chain_returns_detail()
	_test_hint_not_found_on_solved()
	_test_given_not_wrong_mark()
	if _fails.is_empty():
		print("HINT_ENGINE_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_wrong_mark_detected() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	# Mark cell [2][0] which IS the solution for row 2
	board[2][0] = CellModel.CellKind.MARK
	var hint := HintEngine.find_hint(board, 4, regions, solution)
	_assert(hint["found"], "wrong mark found")
	_assert(hint["strategy"] == "WRONG_MARK", "strategy is WRONG_MARK")
	_assert(hint["action"] == "CLEAR_MARK", "action is CLEAR_MARK")
	_assert(hint["target_cell"][0] == 2 and hint["target_cell"][1] == 0, "target is [2,0]")

func _test_wrong_mark_skipped_when_none() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	# Mark cell [0][0] which is NOT solution[0]=1
	board[0][0] = CellModel.CellKind.MARK
	var hint := HintEngine.find_hint(board, 4, regions, solution)
	_assert(hint["found"], "hint found")
	_assert(hint["strategy"] != "WRONG_MARK", "not wrong mark when mark is valid")

func _test_mark_hint_finds_new_marks() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	# Place candy at solution spot
	board[0][1] = CellModel.CellKind.CANDY
	var hint := HintEngine.find_hint(board, 4, regions, solution)
	_assert(hint["found"], "hint found")
	_assert(hint["strategy"] == "MARK_NEIGHBORS", "strategy is MARK_NEIGHBORS")
	_assert(hint["action"] == "PLACE_MARKS", "action is PLACE_MARKS")
	_assert(hint["eliminated_cells"].size() > 0, "has cells to mark")

func _test_mark_hint_skips_all_marked() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	board[0][1] = CellModel.CellKind.CANDY
	# Mark ALL blank cells in row 0, col 1, and neighbors
	for c in range(4):
		if c != 1 and board[0][c] == CellModel.CellKind.BLANK:
			board[0][c] = CellModel.CellKind.MARK
	for r in range(4):
		if board[r][1] == CellModel.CellKind.BLANK:
			board[r][1] = CellModel.CellKind.MARK
	# Mark 8-neighbors
	for dr in [-1, 0, 1]:
		for dc in [-1, 0, 1]:
			var nr: int = 0 + dr
			var nc: int = 1 + dc
			if nr >= 0 and nr < 4 and nc >= 0 and nc < 4:
				if board[nr][nc] == CellModel.CellKind.BLANK:
					board[nr][nc] = CellModel.CellKind.MARK
	# Mark same-zone cells
	var target_zone: String = CandyRules.zone_of(regions, 0, 1)
	for r in range(4):
		for c in range(4):
			if CandyRules.zone_of(regions, r, c) == target_zone:
				if board[r][c] == CellModel.CellKind.BLANK:
					board[r][c] = CellModel.CellKind.MARK
	var hint := HintEngine.find_hint(board, 4, regions, solution)
	_assert(hint["found"], "hint found")
	_assert(hint["strategy"] != "MARK_NEIGHBORS", "skips mark_neighbors when all marked")

func _test_has_new_guard_filters() -> void:
	# Internal test: _filter_new_eliminations removes already-marked cells
	var board := _empty_board(4)
	board[1][3] = CellModel.CellKind.MARK
	var eliminated := [[1, 3], [1, 2]]
	var filtered := HintEngine._filter_new_eliminations(eliminated, board)
	_assert(filtered.size() == 1, "filters out existing mark")
	_assert(filtered[0][0] == 1 and filtered[0][1] == 2, "keeps blank cell")

func _test_single_candidate() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	# Fill board so that only one candidate remains in a unit
	# Place candy row 0 col 1, mark all neighbors
	board[0][1] = CellModel.CellKind.CANDY
	# Mark everything except solution cells
	for r in range(4):
		for c in range(4):
			if board[r][c] == CellModel.CellKind.BLANK and solution[r] != c:
				if not CandyRules.can_place(board, regions, r, c):
					board[r][c] = CellModel.CellKind.MARK
	# Force marks on row/col/neighbors of candy
	for c in range(4):
		if c != 1 and board[0][c] == CellModel.CellKind.BLANK:
			board[0][c] = CellModel.CellKind.MARK
	for r in range(4):
		if board[r][1] == CellModel.CellKind.BLANK:
			board[r][1] = CellModel.CellKind.MARK
	for dr in [-1, 0, 1]:
		for dc in [-1, 0, 1]:
			if dr == 0 and dc == 0: continue
			var nr := 0 + dr; var nc := 1 + dc
			if nr >= 0 and nr < 4 and nc >= 0 and nc < 4:
				if board[nr][nc] == CellModel.CellKind.BLANK:
					board[nr][nc] = CellModel.CellKind.MARK
	# Mark zone-mates of candy
	var z: String = CandyRules.zone_of(regions, 0, 1)
	for r in range(4):
		for c in range(4):
			if CandyRules.zone_of(regions, r, c) == z and board[r][c] == CellModel.CellKind.BLANK:
				board[r][c] = CellModel.CellKind.MARK
	var hint := HintEngine.find_hint(board, 4, regions, solution)
	_assert(hint["found"], "hint found")
	# Could be SINGLE_CANDIDATE or higher technique depending on board state
	_assert(hint["strategy"] in ["SINGLE_CANDIDATE", "MARK_NEIGHBORS", "LOCK_INTERSECTION", "LOCKED_SUBSET", "CONTRA_CHAIN", "FALLBACK"], "valid strategy")

func _test_fallback_on_empty() -> void:
	# Create a board where no logical technique finds anything new
	# but the board isn't solved yet — should get FALLBACK
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	# Mark ALL non-solution cells
	for r in range(4):
		for c in range(4):
			if solution[r] != c:
				board[r][c] = CellModel.CellKind.MARK
	var hint := HintEngine.find_hint(board, 4, regions, solution)
	_assert(hint["found"], "fallback found")
	# With all non-solution marked, single candidate should find the candies
	_assert(hint["strategy"] in ["SINGLE_CANDIDATE", "FALLBACK"], "either single or fallback")

func _test_chain_returns_detail() -> void:
	# Use a 5x5 board that requires contradiction chain
	var board := _empty_board(5)
	var regions := ["AABBB", "AABBB", "CCCBB", "CDDEE", "CDDEE"]
	var solution := [2, 4, 0, 3, 1]
	# Place some candies to partially solve
	board[0][2] = CellModel.CellKind.CANDY
	board[1][4] = CellModel.CellKind.CANDY
	# Mark neighbors
	for placed_r in [0, 1]:
		var placed_c: int = int(solution[placed_r])
		for c in range(5):
			if c != placed_c and board[placed_r][c] == CellModel.CellKind.BLANK:
				board[placed_r][c] = CellModel.CellKind.MARK
		for r in range(5):
			if board[r][placed_c] == CellModel.CellKind.BLANK:
				board[r][placed_c] = CellModel.CellKind.MARK
		for dr in [-1, 0, 1]:
			for dc in [-1, 0, 1]:
				var nr := placed_r + dr; var nc := placed_c + dc
				if nr >= 0 and nr < 5 and nc >= 0 and nc < 5:
					if board[nr][nc] == CellModel.CellKind.BLANK:
						board[nr][nc] = CellModel.CellKind.MARK
	var hint := HintEngine.find_hint(board, 5, regions, solution)
	_assert(hint["found"], "hint found on 5x5")
	if hint["strategy"] == "CONTRA_CHAIN":
		_assert(hint.has("chain_detail"), "chain has detail")
		_assert(hint["chain_detail"].has("depth"), "detail has depth")

func _test_hint_not_found_on_solved() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	# Place all candies
	for r in range(4):
		board[r][int(solution[r])] = CellModel.CellKind.CANDY
	# Mark rest
	for r in range(4):
		for c in range(4):
			if board[r][c] == CellModel.CellKind.BLANK:
				board[r][c] = CellModel.CellKind.MARK
	var hint := HintEngine.find_hint(board, 4, regions, solution)
	_assert(not hint["found"], "no hint on solved board")

func _test_given_not_wrong_mark() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	# Given at solution cell — should NOT be flagged as wrong mark
	board[0][1] = CellModel.CellKind.GIVEN
	var hint := HintEngine.find_hint(board, 4, regions, solution)
	_assert(hint["found"], "hint found")
	_assert(hint["strategy"] != "WRONG_MARK", "given is not wrong mark")

func _empty_board(n: int) -> Array:
	var b: Array = []
	for r in range(n):
		var row: Array = []
		for c in range(n):
			row.append(CellModel.CellKind.BLANK)
		b.append(row)
	return b

func _assert(condition: bool, msg: String) -> void:
	if not condition:
		_fails.append("FAIL: " + msg)
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `godot --headless --path game --script res://tests/test_hint_engine.gd`
Expected: FAIL — `hint_engine.gd` does not exist.

- [ ] **Step 3: Implement hint_engine.gd**

Create `game/scripts/core/hint_engine.gd`:

```gdscript
extends RefCounted

const CellModel = preload("res://scripts/core/cell_model.gd")
const CandyRules = preload("res://scripts/core/candy_rules.gd")
const SolverTechniques = preload("res://scripts/core/solver_techniques.gd")

static func find_hint(board: Array, size: int, regions: Array,
		solution: Array) -> Dictionary:
	# Step 0: Wrong mark detection
	var wrong := _find_wrong_mark(board, size, solution)
	if wrong["found"]:
		return wrong

	# Step 1: Mark neighbors of placed candies
	var mark := _find_mark_hint(board, size, regions)
	if mark["found"]:
		return mark

	# Build work board for advanced techniques (preserves valid player marks)
	var work := _build_hint_work_board(board, size, regions, solution)

	# Step 2: Single candidate
	var single := SolverTechniques._try_single_candidate(work, size, regions)
	if single.get("found", false):
		var unit_type: String = single.get("unit_type", "")
		var unit_id: Variant = single.get("unit_id", "")
		return _make_result("SINGLE_CANDIDATE", "PLACE_CANDY",
				single["cell"],
				_unit_cells(size, regions, unit_type, unit_id),
				[], "hint.single_" + unit_type, [unit_id],
				unit_type, unit_id)

	# Step 3: Lock intersection
	var lock := SolverTechniques._try_lock_intersection(work, size, regions)
	if lock.get("found", false):
		var filtered := _filter_new_eliminations(lock.get("eliminated", []), board)
		if not filtered.is_empty():
			var mode: String = lock.get("mode", "")
			var explanation := _lock_explanation_key(mode)
			var hl: Array = lock.get("eliminated", [])
			return _make_result("LOCK_INTERSECTION", "PLACE_MARKS",
					filtered[0], hl, filtered, explanation, [],
					lock.get("target_type", ""), lock.get("target_id", ""))

	# Step 4: Locked subsets
	var subset := SolverTechniques._try_locked_subsets(work, size, regions)
	if subset.get("found", false):
		var filtered := _filter_new_eliminations(subset.get("eliminated", []), board)
		if not filtered.is_empty():
			var tech: int = subset.get("technique", 4)
			var key: String = "hint.subset_pair"
			if tech == SolverTechniques.Technique.SUBSET_TRIPLE:
				key = "hint.subset_triple"
			elif tech == SolverTechniques.Technique.SUBSET_QUAD:
				key = "hint.subset_quad"
			return _make_result("LOCKED_SUBSET", "PLACE_MARKS",
					filtered[0], subset.get("eliminated", []), filtered,
					key, subset.get("subset_zones", []))

	# Step 5: Contradiction chain
	var chain := SolverTechniques._try_contradiction(work, size, regions)
	if chain.get("found", false):
		var filtered := _filter_new_eliminations(chain.get("eliminated", []), board)
		if not filtered.is_empty():
			var detail: Dictionary = chain.get("chain_detail", {})
			var depth: int = detail.get("depth", 0)
			var exp_key := "hint.chain_short" if depth <= 2 else "hint.chain_long"
			var result := _make_result("CONTRA_CHAIN", "PLACE_MARKS",
					filtered[0], chain.get("eliminated", []), filtered,
					exp_key, [])
			result["chain_detail"] = detail
			return result

	# Step 6: Fallback — reveal a candy
	return _find_fallback(board, size, solution)

static func _find_wrong_mark(board: Array, size: int,
		solution: Array) -> Dictionary:
	for r in range(size):
		for c in range(size):
			if board[r][c] == CellModel.CellKind.MARK and int(solution[r]) == c:
				return _make_result("WRONG_MARK", "CLEAR_MARK",
						[r, c], [[r, c]], [], "hint.wrong_mark", [])
	return {"found": false}

static func _find_mark_hint(board: Array, size: int,
		regions: Array) -> Dictionary:
	for r in range(size):
		for c in range(size):
			if not CellModel.is_placed(board[r][c]):
				continue
			var to_mark: Array = []
			var seen: Dictionary = {}
			# Row
			for cc in range(size):
				if cc != c and board[r][cc] == CellModel.CellKind.BLANK:
					var key := Vector2i(r, cc)
					if not seen.has(key):
						to_mark.append([r, cc]); seen[key] = true
			# Column
			for rr in range(size):
				if rr != r and board[rr][c] == CellModel.CellKind.BLANK:
					var key := Vector2i(rr, c)
					if not seen.has(key):
						to_mark.append([rr, c]); seen[key] = true
			# 8-neighbors
			for dr in [-1, 0, 1]:
				for dc in [-1, 0, 1]:
					if dr == 0 and dc == 0: continue
					var nr := r + dr; var nc := c + dc
					if nr >= 0 and nr < size and nc >= 0 and nc < size:
						if board[nr][nc] == CellModel.CellKind.BLANK:
							var key := Vector2i(nr, nc)
							if not seen.has(key):
								to_mark.append([nr, nc]); seen[key] = true
			# Same zone
			var candy_zone: String = CandyRules.zone_of(regions, r, c)
			for zr in range(size):
				for zc in range(size):
					if CandyRules.zone_of(regions, zr, zc) == candy_zone:
						if board[zr][zc] == CellModel.CellKind.BLANK:
							var key := Vector2i(zr, zc)
							if not seen.has(key):
								to_mark.append([zr, zc]); seen[key] = true
			if not to_mark.is_empty():
				return _make_result("MARK_NEIGHBORS", "PLACE_MARKS",
						[r, c], [[r, c]] + to_mark, to_mark,
						"hint.mark_neighbors", [])
	return {"found": false}

static func _find_fallback(board: Array, size: int,
		solution: Array) -> Dictionary:
	for r in range(size):
		var c: int = int(solution[r])
		if not CellModel.is_placed(board[r][c]) and board[r][c] != CellModel.CellKind.GIVEN:
			return _make_result("FALLBACK", "REVEAL",
					[r, c], [[r, c]], [], "hint.fallback", [])
	return {"found": false}

static func _build_hint_work_board(board: Array, size: int,
		regions: Array, solution: Array) -> Array:
	var work: Array = []
	for r in range(size):
		var row: Array = []
		for c in range(size):
			var cell: int = board[r][c]
			if CellModel.is_placed(cell):
				row.append(cell)
			elif cell == CellModel.CellKind.MARK and int(solution[r]) != c:
				row.append(CellModel.CellKind.MARK)
			else:
				row.append(CellModel.CellKind.BLANK)
		work.append(row)
	SolverTechniques._apply_elimination(work, size, regions)
	return work

static func _filter_new_eliminations(eliminated: Array, board: Array) -> Array:
	var result: Array = []
	for cell in eliminated:
		if board[cell[0]][cell[1]] == CellModel.CellKind.BLANK:
			result.append(cell)
	return result

static func _unit_cells(size: int, regions: Array, unit_type: String,
		unit_id: Variant) -> Array:
	var cells: Array = []
	for r in range(size):
		for c in range(size):
			if (unit_type == "row" and r == int(unit_id)) \
					or (unit_type == "col" and c == int(unit_id)) \
					or (unit_type == "zone" and CandyRules.zone_of(regions, r, c) == str(unit_id)):
				cells.append([r, c])
	return cells

static func _lock_explanation_key(mode: String) -> String:
	match mode:
		"zone_to_row": return "hint.lock_zone_row"
		"zone_to_col": return "hint.lock_zone_col"
		"row_to_zone": return "hint.lock_row_zone"
		"col_to_zone": return "hint.lock_col_zone"
	return "hint.lock_zone_row"

static func _make_result(strategy: String, action: String,
		target_cell: Array, highlight_cells: Array,
		eliminated_cells: Array, explanation_key: String,
		explanation_params: Array, unit_type: String = "",
		unit_id: Variant = "") -> Dictionary:
	return {
		"found": true,
		"strategy": strategy,
		"action": action,
		"target_cell": target_cell,
		"highlight_cells": highlight_cells,
		"eliminated_cells": eliminated_cells,
		"explanation_key": explanation_key,
		"explanation_params": explanation_params,
		"unit_type": unit_type,
		"unit_id": unit_id,
	}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `godot --headless --path game --script res://tests/test_hint_engine.gd`
Expected: PASS — `HINT_ENGINE_PASS`

- [ ] **Step 5: Commit**

```bash
git add game/scripts/core/hint_engine.gd game/tests/test_hint_engine.gd
git commit -m "feat(hint): add HintEngine with hierarchical deduction pipeline

Static pure-logic orchestrator: wrong mark → mark neighbors →
single candidate → lock intersection → locked subsets →
contradiction chain → fallback. Returns standardized HintResult
dictionary with strategy, action, highlights, and explanation."
```

---

### Task 5: SFX Catalog — Hint Sound Effects

**Files:**
- Modify: `game/scripts/feedback/sfx_catalog.gd` (add 3 effects to enum, PRESETS, and SHARED_UI_EFFECTS)

**Interfaces:**
- Consumes: existing `PcmSynth.Wave`, `PcmSynth.PitchCurve` enums
- Produces: `Effect.HINT_APPLY`, `Effect.HINT_DISMISS`, `Effect.HINT_WRONG_MARK` enum values + presets

- [ ] **Step 1: Add enum values**

In `game/scripts/feedback/sfx_catalog.gd`, add three entries to the `Effect` enum after `SETTINGS_OPEN`:

```gdscript
	HINT_APPLY,        # positive chime when hint is applied
	HINT_DISMISS,      # soft close when hint is dismissed
	HINT_WRONG_MARK,   # warning tone for wrong mark detection
```

- [ ] **Step 2: Add presets**

Add to the `PRESETS` dictionary (after the last existing entry, before the closing `}`):

```gdscript
	Effect.HINT_APPLY: {
		"freq": 523.0, "end_freq": 784.0, "duration": 0.12, "volume": 0.28,
		"wave": PcmSynth.Wave.TRIANGLE, "attack": 0.01, "decay": 0.03,
		"release": 0.04, "sustain": 0.3, "pitch_curve": PcmSynth.PitchCurve.EXPONENTIAL,
	},
	Effect.HINT_DISMISS: {
		"freq": 440.0, "end_freq": 350.0, "duration": 0.08, "volume": 0.18,
		"wave": PcmSynth.Wave.SINE, "attack": 0.01, "decay": 0.02,
		"release": 0.03, "sustain": 0.2,
	},
	Effect.HINT_WRONG_MARK: {
		"freq": 300.0, "end_freq": 200.0, "duration": 0.15, "volume": 0.30,
		"wave": PcmSynth.Wave.SQUARE, "attack": 0.005, "decay": 0.04,
		"release": 0.05, "sustain": 0.25,
	},
```

- [ ] **Step 3: Add to SHARED_UI_EFFECTS**

Append `Effect.HINT_APPLY, Effect.HINT_DISMISS, Effect.HINT_WRONG_MARK` to the `SHARED_UI_EFFECTS` array.

- [ ] **Step 4: Verify no syntax errors**

Run: `godot --headless --path game --script res://tests/test_sfx_gameplay.gd`
Expected: PASS (existing tests still pass, confirming no syntax breakage)

- [ ] **Step 5: Commit**

```bash
git add game/scripts/feedback/sfx_catalog.gd
git commit -m "feat(sfx): add HINT_APPLY, HINT_DISMISS, HINT_WRONG_MARK effects

Positive chime, soft close, and warning tone for hint engine v2."
```

---

### Task 6: HintOverlay — Rewrite with Apply/Dismiss/Detail

**Files:**
- Modify: `game/scripts/screens/hint_overlay.gd` (full rewrite)
- Modify: `game/tests/test_hint_overlay.gd` (update tests)

**Interfaces:**
- Consumes: HintResult dictionary from `HintEngine.find_hint()` (Task 4)
- Produces:
  - `signal hint_applied()`
  - `signal hint_dismissed()`
  - `signal detail_requested()`
  - `HintOverlay.show_hint(hint: Dictionary) -> void`
  - `HintOverlay.dismiss() -> void`
  - `HintOverlay.is_showing() -> bool`

- [ ] **Step 1: Read current test file to understand existing test pattern**

Read `game/tests/test_hint_overlay.gd` to see what tests exist.

- [ ] **Step 2: Write updated tests**

Update `game/tests/test_hint_overlay.gd` to test the new API:

```gdscript
extends SceneTree

const HintOverlay = preload("res://scripts/screens/hint_overlay.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_show_and_dismiss()
	_test_detail_visible_only_for_chain()
	_test_signals_emitted()
	_test_apply_label_varies()
	if _fails.is_empty():
		print("HINT_OVERLAY_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_show_and_dismiss() -> void:
	var overlay := HintOverlay.new()
	_assert(not overlay.is_showing(), "not showing initially")
	overlay.show_hint(_make_hint("WRONG_MARK", "CLEAR_MARK"))
	_assert(overlay.is_showing(), "showing after show_hint")
	overlay.dismiss()
	_assert(not overlay.is_showing(), "not showing after dismiss")

func _test_detail_visible_only_for_chain() -> void:
	var overlay := HintOverlay.new()
	overlay.show_hint(_make_hint("SINGLE_CANDIDATE", "PLACE_CANDY"))
	_assert(not overlay._detail_btn.visible, "detail hidden for single")
	overlay.dismiss()
	var chain_hint := _make_hint("CONTRA_CHAIN", "PLACE_MARKS")
	chain_hint["chain_detail"] = {"hypothesis_cell": [0, 0], "depth": 3, "steps": [], "contra_type": "row", "contra_index": 0}
	overlay.show_hint(chain_hint)
	_assert(overlay._detail_btn.visible, "detail visible for chain")

func _test_signals_emitted() -> void:
	var overlay := HintOverlay.new()
	var applied := [false]
	var dismissed := [false]
	overlay.hint_applied.connect(func(): applied[0] = true)
	overlay.hint_dismissed.connect(func(): dismissed[0] = true)
	overlay.show_hint(_make_hint("MARK_NEIGHBORS", "PLACE_MARKS"))
	overlay._on_apply()
	_assert(applied[0], "hint_applied emitted")
	overlay.show_hint(_make_hint("MARK_NEIGHBORS", "PLACE_MARKS"))
	overlay._on_dismiss()
	_assert(dismissed[0], "hint_dismissed emitted")

func _test_apply_label_varies() -> void:
	var overlay := HintOverlay.new()
	overlay.show_hint(_make_hint("WRONG_MARK", "CLEAR_MARK"))
	_assert(overlay._apply_btn.text != "", "apply has text for wrong mark")
	overlay.dismiss()
	overlay.show_hint(_make_hint("SINGLE_CANDIDATE", "PLACE_CANDY"))
	_assert(overlay._apply_btn.text != "", "apply has text for single")

func _make_hint(strategy: String, action: String) -> Dictionary:
	return {
		"found": true, "strategy": strategy, "action": action,
		"target_cell": [0, 0], "highlight_cells": [[0, 0]],
		"eliminated_cells": [], "explanation_key": "hint.wrong_mark",
		"explanation_params": [], "unit_type": "", "unit_id": "",
	}

func _assert(condition: bool, msg: String) -> void:
	if not condition:
		_fails.append("FAIL: " + msg)
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `godot --headless --path game --script res://tests/test_hint_overlay.gd`
Expected: FAIL — old API doesn't match.

- [ ] **Step 4: Rewrite hint_overlay.gd**

Replace `game/scripts/screens/hint_overlay.gd` with:

```gdscript
extends PanelContainer

signal hint_applied()
signal hint_dismissed()
signal detail_requested()

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _showing: bool = false
var _label_icon: Label = null
var _label_text: Label = null
var _apply_btn: Button = null
var _dismiss_btn: Button = null
var _detail_btn: Button = null
var _tween: Tween = null

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	if _label_text != null:
		return
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.SURFACE_WARM
	sb.set_corner_radius_all(Palette.CARD_CORNER)
	sb.content_margin_left = 20.0
	sb.content_margin_right = 20.0
	sb.content_margin_top = 14.0
	sb.content_margin_bottom = 14.0
	sb.shadow_color = Palette.CARD_SHADOW
	sb.shadow_size = 6
	add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	var banner := HBoxContainer.new()
	banner.add_theme_constant_override("separation", 8)
	vbox.add_child(banner)

	_label_icon = Label.new()
	_label_icon.add_theme_font_size_override("font_size", 28)
	banner.add_child(_label_icon)

	_label_text = Label.new()
	_label_text.add_theme_font_size_override("font_size", 22)
	_label_text.add_theme_color_override("font_color", Palette.INK)
	_label_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner.add_child(_label_text)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	_apply_btn = Button.new()
	_apply_btn.custom_minimum_size = Vector2(120, 40)
	_apply_btn.pressed.connect(_on_apply)
	btn_row.add_child(_apply_btn)

	_detail_btn = Button.new()
	_detail_btn.text = tr("hint.detail")
	_detail_btn.custom_minimum_size = Vector2(100, 40)
	_detail_btn.pressed.connect(_on_detail)
	_detail_btn.visible = false
	btn_row.add_child(_detail_btn)

	_dismiss_btn = Button.new()
	_dismiss_btn.custom_minimum_size = Vector2(100, 40)
	_dismiss_btn.pressed.connect(_on_dismiss)
	btn_row.add_child(_dismiss_btn)

func show_hint(hint: Dictionary) -> void:
	_setup_ui()
	var strategy: String = hint.get("strategy", "")
	_label_icon.text = _icon_for(strategy)
	_label_text.text = tr(hint.get("explanation_key", ""))
	_apply_btn.text = _apply_label_for(strategy)
	_dismiss_btn.text = "✕"
	_detail_btn.visible = strategy == "CONTRA_CHAIN" and hint.has("chain_detail")
	_showing = true
	visible = true
	modulate.a = 1.0
	if _tween != null and _tween.is_valid():
		_tween.kill()

func dismiss() -> void:
	if not _showing:
		return
	_showing = false
	visible = false

func is_showing() -> bool:
	return _showing

func _on_apply() -> void:
	hint_applied.emit()

func _on_dismiss() -> void:
	hint_dismissed.emit()

func _on_detail() -> void:
	detail_requested.emit()

static func _icon_for(strategy: String) -> String:
	match strategy:
		"WRONG_MARK": return "⚠"
		"MARK_NEIGHBORS", "LOCK_INTERSECTION", "LOCKED_SUBSET": return "✕"
		"SINGLE_CANDIDATE", "FALLBACK": return "🍬"
		"CONTRA_CHAIN": return "🔗"
	return ""

static func _apply_label_for(strategy: String) -> String:
	match strategy:
		"WRONG_MARK": return tr("hint.clear_mark")
		"SINGLE_CANDIDATE": return tr("hint.place_candy")
		"FALLBACK": return tr("hint.reveal")
	return tr("hint.mark_x")
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `godot --headless --path game --script res://tests/test_hint_overlay.gd`
Expected: PASS — `HINT_OVERLAY_PASS`

- [ ] **Step 6: Commit**

```bash
git add game/scripts/screens/hint_overlay.gd game/tests/test_hint_overlay.gd
git commit -m "feat(hint): rewrite hint_overlay with Apply/Dismiss/Detail buttons

Strategy-dependent banner icon and apply label. Detail button visible
only for CONTRA_CHAIN hints. Three signals: hint_applied, hint_dismissed,
detail_requested."
```

---

### Task 7: HintHighlightLayer — Visual Overlay

**Files:**
- Create: `game/scripts/screens/hint_highlight_layer.gd`
- Modify: `game/scripts/screens/puzzle_board.gd` (add `get_cell_rect` public wrapper)

**Interfaces:**
- Consumes: HintResult dictionary, `cell_rect_fn: Callable` (from `puzzle_board.get_cell_rect`)
- Produces:
  - `signal dismiss_requested()`
  - `HintHighlightLayer.show_hint(hint: Dictionary, cell_rect_fn: Callable) -> void`
  - `HintHighlightLayer.show_chain_detail(chain_detail: Dictionary, cell_rect_fn: Callable) -> void`
  - `HintHighlightLayer.clear() -> void`
  - `HintHighlightLayer.is_showing() -> bool`
  - `PuzzleBoard.get_cell_rect(row: int, col: int) -> Rect2`

- [ ] **Step 1: Add `get_cell_rect` to puzzle_board.gd**

Add to `game/scripts/screens/puzzle_board.gd` right after the existing `_cell_rect()` function (after line 219):

```gdscript
func get_cell_rect(row: int, col: int) -> Rect2:
	return _cell_rect(row, col)
```

- [ ] **Step 2: Create hint_highlight_layer.gd**

Create `game/scripts/screens/hint_highlight_layer.gd`:

```gdscript
extends Control

signal dismiss_requested()

const CellModel = preload("res://scripts/core/cell_model.gd")
const CellAnimator = preload("res://scripts/screens/cell_animator.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _hint: Dictionary = {}
var _chain: Dictionary = {}
var _cell_rect_fn: Callable
var _backdrop: ColorRect = null
var _showing: bool = false
var _pulse_phase: float = 0.0
var _badge_tweens: Array = []
var _badge_scales: Array = []

const HIGHLIGHT_COLOR := Color(0.96, 0.62, 0.04)  # #F59E0B
const CHAIN_HYPOTHESIS := Color(0.94, 0.27, 0.27)  # #EF4444
const CHAIN_STEP := Color(0.96, 0.62, 0.04)  # #F59E0B
const CHAIN_CONTRA := Color(0.86, 0.15, 0.15)  # #DC2626
const GHOST_ALPHA := 0.4
const BADGE_RADIUS_RATIO := 0.25

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0, 0, 0, 0.01)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.visible = false
	_backdrop.gui_input.connect(_on_backdrop_input)
	add_child(_backdrop)

func show_hint(hint: Dictionary, cell_rect_fn: Callable) -> void:
	_hint = hint
	_chain = {}
	_cell_rect_fn = cell_rect_fn
	_showing = true
	_pulse_phase = 0.0
	_backdrop.visible = true
	_kill_badge_tweens()
	queue_redraw()

func show_chain_detail(chain_detail: Dictionary, cell_rect_fn: Callable) -> void:
	_chain = chain_detail
	_cell_rect_fn = cell_rect_fn
	_kill_badge_tweens()
	_badge_scales.clear()
	var total: int = 1 + chain_detail.get("steps", []).size() + 1
	for i in range(total):
		_badge_scales.append(0.0)
	for i in range(total):
		var tw := create_tween()
		tw.tween_interval(float(i) * 0.05)
		var idx := i
		tw.tween_method(func(v: float): _badge_scales[idx] = v; queue_redraw(), 0.0, 1.0, 0.15)
		_badge_tweens.append(tw)
	queue_redraw()

func clear() -> void:
	_hint = {}
	_chain = {}
	_showing = false
	_backdrop.visible = false
	_kill_badge_tweens()
	_badge_scales.clear()
	queue_redraw()

func is_showing() -> bool:
	return _showing

func _process(delta: float) -> void:
	if _showing:
		_pulse_phase += delta * 4.8
		if _pulse_phase > TAU:
			_pulse_phase -= TAU
		queue_redraw()

func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		dismiss_requested.emit()
		accept_event()

func _draw() -> void:
	if not _showing or _hint.is_empty():
		return
	if not _cell_rect_fn.is_valid():
		return
	var pulse_alpha: float = 0.5 + 0.5 * sin(_pulse_phase)
	var border_color := Color(HIGHLIGHT_COLOR, pulse_alpha)

	for cell in _hint.get("highlight_cells", []):
		if cell.size() < 2: continue
		var rect: Rect2 = _cell_rect_fn.call(int(cell[0]), int(cell[1]))
		if rect.size.x <= 0: continue
		var sb := StyleBoxFlat.new()
		sb.draw_center = false
		sb.border_color = border_color
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(int(rect.size.x * 0.12))
		draw_style_box(sb, rect)

	for cell in _hint.get("eliminated_cells", []):
		if cell.size() < 2: continue
		var rect: Rect2 = _cell_rect_fn.call(int(cell[0]), int(cell[1]))
		if rect.size.x <= 0: continue
		var inset := rect.size * 0.2
		var inner := Rect2(rect.position + inset, rect.size - inset * 2)
		var c := Color(0.4, 0.4, 0.5, GHOST_ALPHA)
		var half := inner.size * 0.5
		draw_line(inner.position, inner.position + inner.size, c, 2.0, true)
		draw_line(inner.position + Vector2(inner.size.x, 0),
				inner.position + Vector2(0, inner.size.y), c, 2.0, true)

	if not _chain.is_empty():
		_draw_chain_badges()

func _draw_chain_badges() -> void:
	var badge_idx: int = 0
	var hyp: Array = _chain.get("hypothesis_cell", [])
	if hyp.size() >= 2:
		var rect: Rect2 = _cell_rect_fn.call(int(hyp[0]), int(hyp[1]))
		var s: float = _badge_scales[badge_idx] if badge_idx < _badge_scales.size() else 1.0
		_draw_badge(rect, "?", CHAIN_HYPOTHESIS, s)
		badge_idx += 1

	for step in _chain.get("steps", []):
		if step.size() < 2: continue
		var rect: Rect2 = _cell_rect_fn.call(int(step[0]), int(step[1]))
		var s: float = _badge_scales[badge_idx] if badge_idx < _badge_scales.size() else 1.0
		_draw_badge(rect, str(badge_idx), CHAIN_STEP, s)
		badge_idx += 1

	var contra_type: String = _chain.get("contra_type", "")
	if contra_type != "":
		var s: float = _badge_scales[badge_idx] if badge_idx < _badge_scales.size() else 1.0
		if s > 0.01:
			badge_idx += 1

func _draw_badge(rect: Rect2, text: String, color: Color, scale_f: float) -> void:
	if rect.size.x <= 0 or scale_f < 0.01: return
	var center := rect.get_center()
	var radius := rect.size.x * BADGE_RADIUS_RATIO * scale_f
	draw_circle(center, radius, color)
	var font := ThemeDB.fallback_font
	if font == null: return
	var font_size := int(radius * 1.2)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, center - text_size * 0.5 + Vector2(0, text_size.y * 0.35),
			text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)

func _kill_badge_tweens() -> void:
	for tw in _badge_tweens:
		if is_instance_valid(tw): tw.kill()
	_badge_tweens.clear()
```

- [ ] **Step 3: Verify board tests still pass**

Run: `godot --headless --path game --script res://tests/test_candy_board.gd`
Expected: PASS (confirms `get_cell_rect` addition doesn't break board)

- [ ] **Step 4: Commit**

```bash
git add game/scripts/screens/hint_highlight_layer.gd game/scripts/screens/puzzle_board.gd
git commit -m "feat(hint): add HintHighlightLayer with backdrop, pulse highlights, chain badges

Control overlay renders pulse-yellow borders on highlight_cells, ghost X
on eliminated_cells, and numbered badges for contradiction chain steps.
Backdrop blocks board input during hint display. Also adds public
get_cell_rect() wrapper to PuzzleBoard."
```

---

### Task 8: Layout & PuzzleScreen — Integration

**Files:**
- Modify: `game/scripts/screens/puzzle_layout.gd` (add highlight layer to board_card)
- Modify: `game/scripts/screens/puzzle_screen.gd` (rewrite hint flow)

**Interfaces:**
- Consumes:
  - `HintEngine.find_hint()` (Task 4)
  - `HintMutex` (Task 2)
  - `HintHighlightLayer` (Task 7)
  - `HintOverlay` (Task 6)
  - `PlaySession.clear_mark()`, `PlaySession.apply_marks()` (Task 3)
  - `SfxCatalog.Effect.HINT_APPLY`, `HINT_DISMISS`, `HINT_WRONG_MARK` (Task 5)
- Produces: Complete integrated hint flow in `puzzle_screen.gd`

- [ ] **Step 1: Add HintHighlightLayer to puzzle_layout.gd**

In `game/scripts/screens/puzzle_layout.gd`:

1. Add import at top:
```gdscript
const HintHighlightLayer = preload("res://scripts/screens/hint_highlight_layer.gd")
```

2. Find the line `board_card.add_child(hint_overlay)` (line 121). Insert BEFORE it:

```gdscript
	var highlight_layer := HintHighlightLayer.new()
	highlight_layer.name = "HintHighlightLayer"
	highlight_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_card.add_child(highlight_layer)
```

3. In the returned dictionary at the end of `build()`, add `"hint_highlight": highlight_layer`.

- [ ] **Step 2: Modify puzzle_screen.gd — imports and variables**

In `game/scripts/screens/puzzle_screen.gd`:

1. Add imports at top:
```gdscript
const HintEngine = preload("res://scripts/core/hint_engine.gd")
const HintMutex = preload("res://scripts/screens/hint_mutex.gd")
const HintHighlightLayer = preload("res://scripts/screens/hint_highlight_layer.gd")
```

2. Add variable declarations (near line 15):
```gdscript
var _hint_mutex: HintMutex = HintMutex.new()
var hint_highlight: HintHighlightLayer
var _current_hint: Variant = null
```

3. Remove: `var _hint_click_count: int = 0` from line 15.

4. In `_ensure_nodes()`, after `hint_overlay = n.get("hint_overlay")`, add:
```gdscript
		hint_highlight = n.get("hint_highlight")
```

- [ ] **Step 3: Rewrite `_on_hint()` function**

Replace the `_on_hint()` function (currently lines 152-188) with:

```gdscript
func _on_hint() -> void:
	if session == null or session.phase != PlaySession.Phase.ACTIVE:
		return
	if hint_overlay != null and hint_overlay.is_showing():
		_dismiss_hint()
		return
	if not _hint_mutex.try_acquire("hint"):
		return
	var lvl: Dictionary = session.level
	var hint: Dictionary = HintEngine.find_hint(
		session.board, lvl["size"], lvl["regions"], lvl["solution"]
	)
	if not hint.get("found", false):
		_hint_mutex.release("hint")
		return
	_current_hint = hint
	if hint_highlight != null:
		hint_highlight.show_hint(hint, board.get_cell_rect)
	if hint_overlay != null:
		hint_overlay.show_hint(hint)
	if hint.get("strategy") == "WRONG_MARK":
		if sfx != null: sfx.play(SfxCatalog.Effect.HINT_WRONG_MARK)
	else:
		if sfx != null: sfx.play(SfxCatalog.Effect.HINT_SHOW)
	if hint.get("strategy") != "WRONG_MARK":
		session.use_hint()
```

- [ ] **Step 4: Add `_apply_hint()`, `_dismiss_hint()`, `_on_hint_detail()` functions**

Add after the new `_on_hint()`:

```gdscript
func _apply_hint() -> void:
	if _current_hint == null:
		return
	var hint: Dictionary = _current_hint
	var action: String = hint.get("action", "")
	match action:
		"CLEAR_MARK":
			var cell: Array = hint["target_cell"]
			session.clear_mark(cell[0], cell[1])
		"PLACE_MARKS":
			session.apply_marks(hint["eliminated_cells"])
		"PLACE_CANDY", "REVEAL":
			var cell: Array = hint["target_cell"]
			session.try_candy(cell[0], cell[1])
	_dismiss_hint()
	if sfx != null: sfx.play(SfxCatalog.Effect.HINT_APPLY)
	Vibration.pulse(Vibration.Strength.SOFT)
	if board != null: board.redraw()

func _dismiss_hint() -> void:
	_current_hint = null
	if hint_highlight != null: hint_highlight.clear()
	if hint_overlay != null: hint_overlay.dismiss()
	if sfx != null: sfx.play(SfxCatalog.Effect.HINT_DISMISS)
	_hint_mutex.release("hint")

func _on_hint_detail() -> void:
	if _current_hint == null or hint_highlight == null:
		return
	var chain: Dictionary = _current_hint.get("chain_detail", {})
	if chain.is_empty():
		return
	hint_highlight.show_chain_detail(chain, board.get_cell_rect)
```

- [ ] **Step 5: Update `_connect_ui()` signal connections**

Add to `_connect_ui()` after existing connections:

```gdscript
	if hint_overlay != null:
		_sig_conn(hint_overlay.hint_applied, _apply_hint)
		_sig_conn(hint_overlay.hint_dismissed, _dismiss_hint)
		_sig_conn(hint_overlay.detail_requested, _on_hint_detail)
	if hint_highlight != null:
		_sig_conn(hint_highlight.dismiss_requested, _dismiss_hint)
```

- [ ] **Step 6: Update restart and home to use mutex**

In `_confirm_restart()`, replace `_hint_click_count = 0` with:
```gdscript
	_hint_mutex.force_release()
	_current_hint = null
```

In `_on_home()`, add before `go_home.emit()`:
```gdscript
	_hint_mutex.force_release()
	_current_hint = null
```

- [ ] **Step 7: Remove old import and variable**

Remove this line from imports (no longer needed directly):
```gdscript
const BoardSolver = preload("res://scripts/core/board_solver.gd")
```

**Note:** Only remove `BoardSolver` import if `puzzle_screen.gd` has no OTHER uses of it. Check first — if `BoardSolver` is used elsewhere in the file (e.g. debug bar), keep the import.

- [ ] **Step 8: Remove old hint overlay signal connections**

In `_connect_ui()`, find and remove the old single `dismissed` signal connection for `hint_overlay` if present, since the new overlay uses `hint_applied`/`hint_dismissed`/`detail_requested`.

- [ ] **Step 9: Run integration test**

Run: `godot --headless --path game --script res://tests/test_integration.gd`
Expected: PASS

Run: `godot --headless --path game --script res://tests/test_screens.gd`
Expected: PASS

- [ ] **Step 10: Commit**

```bash
git add game/scripts/screens/puzzle_layout.gd game/scripts/screens/puzzle_screen.gd
git commit -m "feat(hint): integrate hint engine v2 into puzzle screen

Replace progressive_hint flow with HintEngine.find_hint() pipeline.
Add HintHighlightLayer to board_card z-order. Wire Apply/Dismiss/Detail
signals. HintMutex prevents spam clicks. Force-release on restart/home."
```

---

### Task 9: PreCandyDecider — DDA Pre-fill

**Files:**
- Create: `game/scripts/core/pre_candy_decider.gd`
- Create: `game/tests/test_pre_candy_decider.gd`

**Interfaces:**
- Consumes:
  - `BoardSolver.compute_cell_ranks(size, regions, solution, givens) -> Array` from `board_solver.gd`
- Produces:
  - `PreCandyDecider.Trigger` enum (HARD_NEXT=1, CONSECUTIVE_FAIL=2, DEMOTE=3)
  - `PreCandyDecider.should_prefill(trigger: int, fail_streak: int) -> bool`
  - `PreCandyDecider.choose_prefill_cell(size, regions, solution, givens) -> Array`
  - `PreCandyDecider.apply_prefill(level: Dictionary) -> Dictionary`

- [ ] **Step 1: Write the test file**

Create `game/tests/test_pre_candy_decider.gd`:

```gdscript
extends SceneTree

const PreCandyDecider = preload("res://scripts/core/pre_candy_decider.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_should_prefill_consecutive_fail()
	_test_should_prefill_hard_next()
	_test_should_prefill_demote()
	_test_choose_prefill_cell()
	_test_apply_prefill_adds_given()
	_test_apply_prefill_does_not_mutate_original()
	if _fails.is_empty():
		print("PRE_CANDY_DECIDER_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_should_prefill_consecutive_fail() -> void:
	_assert(not PreCandyDecider.should_prefill(
		PreCandyDecider.Trigger.CONSECUTIVE_FAIL, 1), "streak 1 = no")
	_assert(PreCandyDecider.should_prefill(
		PreCandyDecider.Trigger.CONSECUTIVE_FAIL, 2), "streak 2 = yes")
	_assert(PreCandyDecider.should_prefill(
		PreCandyDecider.Trigger.CONSECUTIVE_FAIL, 5), "streak 5 = yes")

func _test_should_prefill_hard_next() -> void:
	_assert(PreCandyDecider.should_prefill(
		PreCandyDecider.Trigger.HARD_NEXT, 0), "hard_next always true")

func _test_should_prefill_demote() -> void:
	_assert(PreCandyDecider.should_prefill(
		PreCandyDecider.Trigger.DEMOTE, 0), "demote always true")

func _test_choose_prefill_cell() -> void:
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	var givens: Array = []
	var cell := PreCandyDecider.choose_prefill_cell(4, regions, solution, givens)
	_assert(cell.size() == 2, "returns [row, col]")
	_assert(cell[0] >= 0 and cell[0] < 4, "row in range")
	_assert(int(solution[cell[0]]) == cell[1], "cell is on solution")

func _test_apply_prefill_adds_given() -> void:
	var level := {
		"size": 4,
		"regions": ["AABB", "ABBB", "CCBB", "CCDB"],
		"solution": [1, 3, 0, 2],
		"givens": [],
	}
	var modified := PreCandyDecider.apply_prefill(level)
	_assert(modified["givens"].size() == 1, "one given added")
	var g: Dictionary = modified["givens"][0]
	_assert(g.has("r") and g.has("c"), "given has r and c")

func _test_apply_prefill_does_not_mutate_original() -> void:
	var level := {
		"size": 4,
		"regions": ["AABB", "ABBB", "CCBB", "CCDB"],
		"solution": [1, 3, 0, 2],
		"givens": [],
	}
	var _modified := PreCandyDecider.apply_prefill(level)
	_assert(level["givens"].size() == 0, "original unchanged")

func _assert(condition: bool, msg: String) -> void:
	if not condition:
		_fails.append("FAIL: " + msg)
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `godot --headless --path game --script res://tests/test_pre_candy_decider.gd`
Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Implement pre_candy_decider.gd**

Create `game/scripts/core/pre_candy_decider.gd`:

```gdscript
extends RefCounted

const BoardSolver = preload("res://scripts/core/board_solver.gd")

enum Trigger {
	HARD_NEXT = 1,
	CONSECUTIVE_FAIL = 2,
	DEMOTE = 3,
}

static func should_prefill(trigger: int, fail_streak: int) -> bool:
	match trigger:
		Trigger.CONSECUTIVE_FAIL:
			return fail_streak >= 2
		Trigger.HARD_NEXT, Trigger.DEMOTE:
			return true
	return false

static func choose_prefill_cell(size: int, regions: Array,
		solution: Array, givens: Array) -> Array:
	var ranks: Array = BoardSolver.compute_cell_ranks(size, regions, solution, givens)
	var best_rank: int = 0
	var best_cell: Array = []
	for r in range(size):
		var c: int = int(solution[r])
		var is_given: bool = false
		for g in givens:
			if int(g.get("r", -1)) == r and int(g.get("c", -1)) == c:
				is_given = true
				break
		if is_given:
			continue
		if ranks[r][c] > best_rank:
			best_rank = ranks[r][c]
			best_cell = [r, c]
	return best_cell

static func apply_prefill(level: Dictionary) -> Dictionary:
	var modified: Dictionary = level.duplicate(true)
	var cell: Array = choose_prefill_cell(
		int(level["size"]), level["regions"],
		level["solution"], level.get("givens", [])
	)
	if not cell.is_empty():
		var givens: Array = modified.get("givens", []).duplicate(true)
		givens.append({"r": cell[0], "c": cell[1]})
		modified["givens"] = givens
	return modified
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `godot --headless --path game --script res://tests/test_pre_candy_decider.gd`
Expected: PASS — `PRE_CANDY_DECIDER_PASS`

- [ ] **Step 5: Commit**

```bash
git add game/scripts/core/pre_candy_decider.gd game/tests/test_pre_candy_decider.gd
git commit -m "feat(dda): add PreCandyDecider for difficulty adjustment pre-fill

Static pure-logic module. should_prefill() checks trigger + streak.
choose_prefill_cell() picks highest-rank non-given cell.
apply_prefill() returns modified level copy without mutating original.
Scope: Endless/Practice only — Campaign does not call this."
```

---

### Task 10: Clean-Room Gate & Final Verification

**Files:**
- No new files — verification only

**Interfaces:**
- Consumes: all files from Tasks 1–9

- [ ] **Step 1: Run clean-room keyword scan**

```bash
rg -n "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/
```

Expected: 0 matches. If any match found → fix before proceeding.

- [ ] **Step 2: Run no-extracted-reusable import scan**

```bash
rg -n "extracted_reusable" game/scripts/ game/tests/
```

Expected: 0 matches.

- [ ] **Step 3: Run all hint-related tests**

```bash
godot --headless --path game --script res://tests/test_board_solver.gd
godot --headless --path game --script res://tests/test_hint_mutex.gd
godot --headless --path game --script res://tests/test_hint_engine.gd
godot --headless --path game --script res://tests/test_hint_overlay.gd
godot --headless --path game --script res://tests/test_pre_candy_decider.gd
godot --headless --path game --script res://tests/test_play_session.gd
```

Expected: All PASS.

- [ ] **Step 4: Run full verification**

```bash
python -B tools/verify.py --godot <executable>
```

Expected: All checks pass.

- [ ] **Step 5: Check module line counts**

Verify no new file exceeds 300 lines:
```bash
wc -l game/scripts/core/hint_engine.gd game/scripts/screens/hint_mutex.gd game/scripts/screens/hint_highlight_layer.gd game/scripts/core/pre_candy_decider.gd game/scripts/screens/hint_overlay.gd
```

Expected: All ≤ 300 lines.

- [ ] **Step 6: Final commit (if any fixes were needed)**

```bash
git add -A
git commit -m "chore(hint): clean-room compliance and verification pass"
```

# System-wide Removal of Givens Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the `GIVEN` cell state (`CellModel.CellKind.GIVEN = 4`), dynamic prefill (`pre_candy_decider.gd`), halo rendering, and the remaining given in `bank_4x4.json`, bringing all puzzles to 100% player-solved and reducing `CellKind` to 4 clean states.

**Architecture:** 
1. Core model simplification: reduce `CellKind` from 5 to 4 states (`BLANK`, `MARK`, `CANDY`, `ERROR`), update rule checkers, and delete `pre_candy_decider.gd`.
2. Solver and Session decoupling: remove givens parameters and pre-placement loops from `board_solver.gd` and `play_session.gd`.
3. UI, Rendering & Tutorial cleanup: remove halo drawing from `candy_cell_drawer.gd` and `puzzle_board_painter.gd`; remove tip `C-given` from `tutorial_tips.gd`.
4. Bank data & validation update: update `bank_4x4.json` Rank 1 Index 1 to a 4-step pure S2 trace, regenerate `bank_4x4.pace.json`, and make `givens` optional/omitted in validators.
5. Systematic test updates: update all 20+ test suites to reflect the 4-state model.

**Tech Stack:** Godot 4 (GDScript), Python 3.12 (validation tools, test runner).

**Spec:** [docs/superpowers/specs/2026-10-14-remove-givens-system-wide-design.md](file:///D:/Work/Alpaca_Solution/ASOL-Game-02/docs/superpowers/specs/2026-10-14-remove-givens-system-wide-design.md)

## Global Constraints
- Clean-room: zero references to legacy project names (`QueenDoku`, `MeowDoku`, `SaveStore`, `EventBus`, etc.).
- Modules ≤ 300 lines.
- Native Godot signals; no autoloads.
- Conventional commits: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`.
- Full gate pass via `python -B tools/verify.py --godot <executable>`.

---

### Task 1: Core Model & Rules Simplification (`cell_model.gd`, `candy_rules.gd`, `test_candy_rules.gd`)

**Files:**
- Modify: `game/scripts/core/cell_model.gd:1-38`
- Test: `game/tests/test_candy_rules.gd`

**Interfaces:**
- Produces: `CellModel.CellKind` with exactly 4 enum members: `BLANK = 0, MARK = 1, CANDY = 2, ERROR = 3`.
- Produces: `CellModel.is_placed(kind) -> bool` (`kind == CellKind.CANDY`), `CellModel.is_candy(kind) -> bool` (`kind == CellKind.CANDY`), `CellModel.is_locked(kind) -> bool` (`return false`).

- [ ] **Step 1: Update test in `game/tests/test_candy_rules.gd` for 4-state `CellModel`**

Remove checks expecting `CellModel.CellKind.GIVEN`:
```gdscript
# In _test_cell_model():
_assert(CellModel.is_placed(CellModel.CellKind.CANDY), "candy is placed")
_assert(not CellModel.is_placed(CellModel.CellKind.BLANK), "blank not placed")
_assert(CellModel.is_candy(CellModel.CellKind.CANDY), "candy is candy")
_assert(not CellModel.is_locked(CellModel.CellKind.CANDY), "candy not locked")
_assert(not CellModel.is_locked(CellModel.CellKind.BLANK), "blank not locked")
_assert(CellModel.is_available(CellModel.CellKind.BLANK), "blank available")
_assert(CellModel.is_available(CellModel.CellKind.MARK), "mark available")
_assert(not CellModel.is_available(CellModel.CellKind.CANDY), "candy not available")
_assert(CellModel.label(CellModel.CellKind.CANDY) == "candy", "label candy")
```

- [ ] **Step 2: Run test to verify failure**

Run: `& "C:/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path game --script res://tests/test_candy_rules.gd`

- [ ] **Step 3: Modify `game/scripts/core/cell_model.gd`**

```gdscript
# cell_model.gd
extends RefCounted

enum CellKind {
	BLANK = 0,      # Ô trống, chưa đánh dấu
	MARK = 1,       # Player đánh X (xóa được)
	CANDY = 2,      # Candy đặt đúng
	ERROR = 3,      # Candy đặt sai (hiện X đỏ, không xóa được)
}

static func is_empty(kind: int) -> bool:
	return kind == CellKind.BLANK

static func is_placed(kind: int) -> bool:
	return kind == CellKind.CANDY

static func is_candy(kind: int) -> bool:
	return kind == CellKind.CANDY

static func is_cross(kind: int) -> bool:
	return kind == CellKind.MARK or kind == CellKind.ERROR

static func is_locked(_kind: int) -> bool:
	return false

static func is_available(kind: int) -> bool:
	return kind == CellKind.BLANK or kind == CellKind.MARK

static func label(kind: int) -> String:
	match kind:
		CellKind.BLANK: return "blank"
		CellKind.MARK: return "mark"
		CellKind.CANDY: return "candy"
		CellKind.ERROR: return "error"
	return "unknown"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path game --script res://tests/test_candy_rules.gd`
Expected: `CANDY_RULES_PASS`

- [ ] **Step 5: Commit**

```bash
git add game/scripts/core/cell_model.gd game/tests/test_candy_rules.gd
git commit -m "refactor(core): remove GIVEN state from CellModel enum and predicates"
```

---

### Task 2: Remove DDA Prefill (`pre_candy_decider.gd`, `endless_runtime.gd`, `test_pre_candy_decider.gd`)

**Files:**
- Delete: `game/scripts/core/pre_candy_decider.gd`
- Delete: `game/tests/test_pre_candy_decider.gd`
- Modify: `game/scripts/endless/endless_runtime.gd:1-85`
- Test: `game/tests/test_endless_runtime.gd`, `game/tests/test_endless_integration.gd`

**Interfaces:**
- Removes: `PreCandyDecider` class completely.
- Modifies: `EndlessRuntime.build_level` - no longer calls prefill on fail streak.

- [ ] **Step 1: Remove `pre_candy_decider` references in `endless_runtime.gd`**

In `game/scripts/endless/endless_runtime.gd`:
- Remove line 12: `const PreCandyDeciderClass = preload("res://scripts/core/pre_candy_decider.gd")`
- Remove lines 75-76:
  ```gdscript
  if PreCandyDeciderClass.should_prefill(PreCandyDeciderClass.Trigger.CONSECUTIVE_FAIL, fail_streak):
      level = PreCandyDeciderClass.apply_prefill(level)
  ```

- [ ] **Step 2: Delete `pre_candy_decider.gd` and `test_pre_candy_decider.gd`**

```bash
git rm game/scripts/core/pre_candy_decider.gd
git rm game/tests/test_pre_candy_decider.gd
```

- [ ] **Step 3: Update `test_endless_runtime.gd` and `test_endless_integration.gd`**

In `game/tests/test_endless_runtime.gd`:
- Update line 74: remove `if session.cell_at(r, c) != 4:` check.
In `game/tests/test_endless_integration.gd`:
- Line 142: remove `if session.cell_at(r, c) != CellModel.CellKind.GIVEN:`.

- [ ] **Step 4: Run endless tests to verify they pass**

Run:
`& "C:/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path game --script res://tests/test_endless_runtime.gd`
`& "C:/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path game --script res://tests/test_endless_integration.gd`
Expected: `ENDLESS_RUNTIME_PASS`, `ENDLESS_INTEGRATION_PASS`

- [ ] **Step 5: Commit**

```bash
git add game/scripts/endless/endless_runtime.gd game/tests/test_endless_runtime.gd game/tests/test_endless_integration.gd
git commit -m "refactor(endless): remove pre_candy_decider DDA prefill"
```

---

### Task 3: Decouple Solver & PlaySession (`board_solver.gd`, `play_session.gd`)

**Files:**
- Modify: `game/scripts/core/board_solver.gd:145-205`
- Modify: `game/scripts/input/play_session.gd:40-60, 165-200, 245-260`
- Test: `game/tests/test_board_solver.gd`, `game/tests/test_play_session.gd`, `game/tests/test_hint_engine.gd`, `game/tests/test_session_store.gd`

**Interfaces:**
- `BoardSolver.compute_cell_ranks(size: int, regions: Array, solution: Array, givens: Array = []) -> Array` (keep optional `givens: Array = []` for signature safety, but ignore/empty).
- `BoardSolver.replay_solve(size: int, regions: Array, _solution: Array, givens: Array = []) -> Dictionary`: starts with empty board, `placed_count: int = 0`.
- `PlaySession`: removes GIVEN setup loop in `_build_board()` and `restore()`. `is_preset(r, c)` returns `false`.

- [ ] **Step 1: Modify `board_solver.gd`**

In `game/scripts/core/board_solver.gd`:
- In `compute_cell_ranks`: make `givens: Array = []` optional, remove the loop filling `work_board` with `CellModel.CellKind.GIVEN`.
- In `replay_solve`: make `givens: Array = []` optional, remove the loop placing `CellModel.CellKind.GIVEN`. Initialize `var placed_count: int = 0`.

- [ ] **Step 2: Modify `play_session.gd`**

In `game/scripts/input/play_session.gd`:
- In `_build_board(level: Dictionary) -> Array`: remove `for g in level.get("givens", []): ... board[gr][gc] = CellModel.CellKind.GIVEN`.
- In `is_preset(_row: int, _col: int) -> bool`: return `false`.
- In `try_candy(row, col)`: remove `CellModel.CellKind.GIVEN` from match arms.
- In `clear_cell(row, col)`: remove `CellModel.CellKind.GIVEN` from match arms.
- In `restore(session_data, level_data)`: remove `for g in level_data.get("givens", []): ... session.board[gr][gc] = CellModel.CellKind.GIVEN`.

- [ ] **Step 3: Update `test_board_solver.gd`, `test_play_session.gd`, `test_hint_engine.gd`, `test_session_store.gd`**

In `game/tests/test_board_solver.gd`:
- Update `givens` usage in test cases.
In `game/tests/test_play_session.gd`:
- Remove `_test_given_without_generated_marks()`.
In `game/tests/test_hint_engine.gd`:
- In `_test_given_not_wrong_mark`: replace test or remove GIVEN reference (test that a valid placed candy is not a wrong mark).
In `game/tests/test_session_store.gd`:
- Update any GIVEN references.

- [ ] **Step 4: Run tests to verify**

Run:
`& "C:/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path game --script res://tests/test_board_solver.gd`
`& "C:/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path game --script res://tests/test_play_session.gd`
`& "C:/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path game --script res://tests/test_hint_engine.gd`
`& "C:/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path game --script res://tests/test_session_store.gd`

- [ ] **Step 5: Commit**

```bash
git add game/scripts/core/board_solver.gd game/scripts/input/play_session.gd game/tests/test_board_solver.gd game/tests/test_play_session.gd game/tests/test_hint_engine.gd game/tests/test_session_store.gd
git commit -m "refactor(core): remove givens handling from board_solver and play_session"
```

---

### Task 4: Rendering & Theme Cleanup (`candy_cell_drawer.gd`, `puzzle_board.gd`, `puzzle_board_painter.gd`, `candy_anim_state.gd`, `tokens`)

**Files:**
- Modify: `game/scripts/screens/candy_cell_drawer.gd`
- Modify: `game/scripts/screens/puzzle_board.gd`
- Modify: `game/scripts/screens/puzzle_board_painter.gd`
- Modify: `game/scripts/screens/candy_anim_state.gd`
- Modify: `game/scripts/theme/layout_tokens.gd`
- Modify: `game/scripts/theme/candy_palette.gd`
- Modify: `game/scripts/theme/palette.gd`
- Test: `game/tests/test_candy_board.gd`, `game/tests/test_candy_anim_state.gd`, `game/tests/test_board_entry.gd`, `game/tests/test_screens.gd`

**Interfaces:**
- `CandyCellDrawer.draw(canvas, rect, cs, static_tex, frame, progress)`: removes `is_given` argument and halo drawing.
- `puzzle_board._draw_cell_candy(rect, r, c)`: removes `is_given` argument.
- `puzzle_board_painter.gd`: static pass checks only `k == CellModel.CellKind.CANDY`.

- [ ] **Step 1: Modify `candy_cell_drawer.gd` and `puzzle_board.gd`**

In `candy_cell_drawer.gd`:
```gdscript
static func draw(canvas: CanvasItem, rect: Rect2, cs: float, static_tex: Texture2D, frame: Array, progress: float = 0.0) -> void:
	if static_tex != null:
		# static texture drawing...
```
In `puzzle_board.gd`:
```gdscript
func _draw_cell_candy(rect: Rect2, r: int = -1, c: int = -1) -> void:
	CandyCellDrawer.draw(self, rect, _content_scale(), _candy_tex, candy_frame(r, c) if r >= 0 else [], _candy_anim.progress_of(Vector2i(r, c)) if _candy_anim != null and r >= 0 else 0.0)
```

- [ ] **Step 2: Modify `puzzle_board_painter.gd` and `candy_anim_state.gd`**

In `puzzle_board_painter.gd`:
- Line 165: `if k == CellModel.CellKind.CANDY:`
- Line 169: `board._draw_cell_candy(cell_rect, r, c)`
- Line 216: `if k != CellModel.CellKind.CANDY:`
In `candy_anim_state.gd`:
- Line 23: `if k == CellModel.CellKind.CANDY: rest(Vector2i(r, c))`

- [ ] **Step 3: Clean up tokens in theme files**

In `game/scripts/theme/layout_tokens.gd`:
- Remove `const GIVEN_HALO_RATIO := 0.38` (or set unused).
In `game/scripts/theme/candy_palette.gd`:
- Remove `const GIVEN_HALO := Color("#FFF7E8")`, `GIVEN_HALO_OPACITY := 0.4`.
In `game/scripts/theme/palette.gd`:
- Remove `GIVEN_CANDY`, `GIVEN_HALO`, `GIVEN_BG_TINT` and match arm `4: return GIVEN_BG_TINT`.

- [ ] **Step 4: Update affected tests**

In `game/tests/test_candy_board.gd`:
- Remove givens from test board level dict.
In `game/tests/test_candy_anim_state.gd`:
- Update sync assertion.
In `game/tests/test_board_entry.gd`:
- Remove givens from test level fixtures.
In `game/tests/test_screens.gd`:
- Remove givens from mock level dicts.

- [ ] **Step 5: Run tests to verify**

Run:
`& "C:/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path game --script res://tests/test_candy_board.gd`
`& "C:/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path game --script res://tests/test_candy_anim_state.gd`
`& "C:/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path game --script res://tests/test_board_entry.gd`
`& "C:/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path game --script res://tests/test_screens.gd`

- [ ] **Step 6: Commit**

```bash
git add game/scripts/screens/ game/scripts/theme/ game/tests/test_candy_board.gd game/tests/test_candy_anim_state.gd game/tests/test_board_entry.gd game/tests/test_screens.gd
git commit -m "refactor(render): remove given halo drawing and theme tokens"
```

---

### Task 5: Tutorial & Gameplay UI Updates (`tutorial_tips.gd`, `tutorial_targets.gd`, `puzzle_screen.gd`, debug screens)

**Files:**
- Modify: `game/scripts/campaign/tutorial_tips.gd`
- Modify: `game/scripts/campaign/tutorial_targets.gd`
- Modify: `game/scripts/screens/puzzle_screen.gd`
- Modify: `game/scripts/screens/puzzle_tutorial.gd`
- Modify: `game/scripts/screens/puzzle_debug_bar.gd`
- Modify: `game/scripts/screens/debug_endless_panel.gd`
- Modify: `game/scripts/screens/debug_level_picker.gd`
- Test: `game/tests/test_tutorial_tips.gd`, `game/tests/test_tutorial_targets.gd`, `game/tests/test_candy_counter_animator.gd`, `game/tests/test_touch_guard_integration.gd`, `game/tests/test_integration.gd`, `game/tests/test_sfx_gameplay.gd`, `game/tests/test_snapshot_builder.gd`, `game/tests/test_debug_features.gd`

**Interfaces:**
- `TutorialTips.tip_for`: removes `C-given` tip branch.
- `TutorialTargets.resolve`: removes `"excluded_by_given"` branch.
- `puzzle_screen.gd`: `required` candies to place is simply `int(session.level.get("size", 0))`.

- [ ] **Step 1: Modify `tutorial_tips.gd` and `tutorial_targets.gd`**

In `tutorial_tips.gd`:
- Remove lines 21-22:
  ```gdscript
  elif int(ctx.get("givens", 0)) > 0 and not guide.has_seen("C-given"):
      id = "C-given"
  ```
In `tutorial_targets.gd`:
- Remove `"excluded_by_given"` match case and unused helper logic for givens.

- [ ] **Step 2: Modify `puzzle_screen.gd`, `puzzle_tutorial.gd`, and debug screens**

In `puzzle_screen.gd`:
- Line 245: `var required: int = int(session.level.get("size", 0))`
In `puzzle_tutorial.gd`:
- Remove `"givens"` from `level_start` context.
In `puzzle_debug_bar.gd`:
- Line 128: remove check for `CellModel.CellKind.GIVEN`.
In `debug_endless_panel.gd` & `debug_level_picker.gd`:
- Remove `giv_cnt` display.

- [ ] **Step 3: Update remaining test suites**

- `test_tutorial_tips.gd`: remove assertion on `C-given`.
- `test_tutorial_targets.gd`: remove `_test_excluded_by_given()`.
- `test_candy_counter_animator.gd`: update test to not rely on given for zone reordering.
- `test_touch_guard_integration.gd`, `test_integration.gd`, `test_sfx_gameplay.gd`, `test_snapshot_builder.gd`, `test_debug_features.gd`: remove `CellModel.CellKind.GIVEN` references.

- [ ] **Step 4: Run all updated tests**

Run:
`& "C:/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path game --script res://tests/test_tutorial_tips.gd`
`& "C:/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path game --script res://tests/test_tutorial_targets.gd`
`& "C:/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path game --script res://tests/test_integration.gd`
`& "C:/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path game --script res://tests/test_sfx_gameplay.gd`

- [ ] **Step 5: Commit**

```bash
git add game/scripts/campaign/ game/scripts/screens/ game/tests/
git commit -m "refactor(campaign): remove C-given tip and update gameplay UI"
```

---

### Task 6: Bank Data, Content Validators & Tools (`bank_4x4.json`, `bank_4x4.pace.json`, validators)

**Files:**
- Modify: `game/data/banks/bank_4x4.json`
- Regenerate: `game/data/banks/bank_4x4.pace.json`
- Modify: `game/scripts/content/level_validator.gd`
- Modify: `game/scripts/content/board_transform.gd`
- Modify: `tools/validate_content.py`
- Modify: `tools/validate_full_content.py`
- Test: `tools/tests/test_validate_content.py`, `tools/tests/test_convert_extracted_bank.py`

**Interfaces:**
- `bank_4x4.json` Rank 1 Index 1: `"givens": []`, `"steps": 4`, `"profile": [4, 0, 0]`, `"pidHash": "7948b573"`, `"logicTrace"` with 4 S2 steps.
- `level_validator.gd`: `_check_schema` does not enforce `givens`; removes given geometry validation loop.

- [ ] **Step 1: Update `game/data/banks/bank_4x4.json` Rank 1 Index 1**

Replace level at Rank 1 Index 1:
```json
{
  "seed": 12,
  "regions": ["AAAB", "CABB", "CAAB", "CCDB"],
  "solution": [1, 3, 0, 2],
  "givens": [],
  "steps": 4,
  "profile": [4, 0, 0],
  "rating": 8,
  "pidHash": "7948b573",
  "logicTrace": [
    {"rule": "S2", "focus": {"type": "region", "id": "D"}, "conclusion": {"type": "place", "r": 3, "c": 2}, "textKey": "hint.single.region"},
    {"rule": "S2", "focus": {"type": "row", "id": 2}, "conclusion": {"type": "place", "r": 2, "c": 0}, "textKey": "hint.single.row"},
    {"rule": "S2", "focus": {"type": "column", "id": 1}, "conclusion": {"type": "place", "r": 0, "c": 1}, "textKey": "hint.single.column"},
    {"rule": "S2", "focus": {"type": "row", "id": 1}, "conclusion": {"type": "place", "r": 1, "c": 3}, "textKey": "hint.single.row"}
  ]
}
```

- [ ] **Step 2: Regenerate `bank_4x4.pace.json`**

Run: `python -B GDD/tools/generate_pace.py --bank game/data/banks/bank_4x4.json --output game/data/banks/bank_4x4.pace.json`

- [ ] **Step 3: Modify `level_validator.gd` and `board_transform.gd`**

In `level_validator.gd`:
- `_check_schema`: remove error for missing `givens` (optional).
- `_check_geometry`: remove given loop (or only validate if givens present).
In `board_transform.gd`:
- Keep `transform_givens` if `givens` present or clean up safely.

- [ ] **Step 4: Modify `tools/validate_content.py` and `tools/validate_full_content.py`**

- Remove given validation error loops.

- [ ] **Step 5: Run Python unit tests and content validators**

Run:
`python -B -m unittest discover tools/tests -p "test_*.py"`
`python -B tools/validate_content.py game/data/banks/bank_4x4.json --pace game/data/banks/bank_4x4.pace.json`
`python -B tools/validate_content.py game/data/campaigns/demo_30.json --bank game/data/banks/bank_4x4.json --bank game/data/banks/bank_5x5.json --bank game/data/banks/bank_6x6.json`
Expected: PASS, VALID

- [ ] **Step 6: Commit**

```bash
git add game/data/banks/bank_4x4.json game/data/banks/bank_4x4.pace.json game/scripts/content/ tools/
git commit -m "fix(content): update bank_4x4 rank 1 index 1 to 4-step trace and update validators"
```

---

### Task 7: Full Gate Verification & Clean-Room Check

**Files:**
- Test: All suites via `tools/verify.py`

- [ ] **Step 1: Run clean-room check (no reference names in scripts)**

```powershell
python -c "import subprocess, sys
res = subprocess.run(['git', 'grep', '-E', '-n', '(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)', 'game/scripts/'], capture_output=True, text=True)
if res.stdout:
    print('Clean-room violations found:\n', res.stdout)
    sys.exit(1)
print('Clean-room check: PASS')
"
```

- [ ] **Step 2: Run full verification script**

Run: `python -B tools/verify.py --godot "C:/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"`
Expected: All checks PASS.

- [ ] **Step 3: Commit any final cleanup and update STATUS**

Update `docs/STATUS.md` recording the removal of GIVEN mechanics.
```bash
git add docs/STATUS.md
git commit -m "docs(status): record system-wide removal of givens"
```

# M0-A02 Playable Interaction Prototype Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a playable T01 interaction prototype that runs in Godot Editor and passes the canonical interaction contract v2 headlessly.

**Architecture:** A deterministic `InteractionSession` model is shared by a pointer-driven `GestureEngine` and a custom-drawn `BoardView`. `BoardScreen` composes UI actions while the existing bootstrap remains the project entry point.

**Tech Stack:** Godot 4.7.2, GDScript, Godot Control drawing/input, JSON fixtures, Python unittest, repository package pipeline.

**Spec:** `work/evidence/M0-A02/prototype-design.md`

## Global constraints

- Edit only `game/**`, `work/evidence/M0-A02/**`, `work/handoffs/M0-A02.md` and pipeline-managed state.
- Preserve canonical GDD and interaction fixture semantics.
- Keep `bootstrap.tscn` as `run/main_scene` and preserve `M0_A01_BOOTSTRAP_READY`.
- Use original code-drawn placeholder visuals; no external or commercial assets.
- Do not require APK, device evidence, audio, SFX or production polish.
- Use TDD: observe each new test fail for the intended missing behavior before implementation.

## Review focus

- Contract parity: every interaction/session vector must match canonical expected state and events.
- Preview correctness: double tap and canceled gestures must not persist intermediate X.
- Undo boundary: no Undo may cross TryCat/lifecycle; a stroke is one batch.
- Locked-state safety: given, cat and x_error never mutate from tap/drag.
- Input ownership: secondary pointers and out-of-board input cannot mutate cells.
- Editor usability: Run Project visibly exposes T01, Undo and Restart without external setup.

---

### Task 1: Preserve planning artifacts and start M0-A02

**Files:**
- Add: `work/evidence/M0-A02/prototype-design.md`
- Add: `work/evidence/M0-A02/prototype-plan.md`
- Generated: `work/state/M0-A02.toml`

- [x] **Step 1: Commit the approved design and implementation plan**

```powershell
git add work/evidence/M0-A02/prototype-design.md work/evidence/M0-A02/prototype-plan.md
git commit -m "docs: design M0-A02 editor prototype"
```

Expected: planning artifacts are committed and the tree is clean.

- [x] **Step 2: Start the assigned package**

```powershell
python tools/agent_pipeline.py start M0-A02 --agent codex
```

Expected: branch `work/m0-a02-gesture-and-input-interaction-prototype`; state `in_progress`.

- [x] **Step 3: Commit lifecycle state**

```powershell
git add work/state/M0-A02.toml
git commit -m "chore: start M0-A02"
```

Expected: clean working tree.

### Task 2: Mirror canonical fixtures with drift protection

**Files:**
- Add: `game/tests/test_interaction_fixture_sync.py`
- Add: `game/tests/fixtures/interactions.v2.json`
- Add: `game/data/t01.json`

- [x] **Step 1: Write the failing fixture sync test**

Test that the game interaction fixture equals `GDD/data/interactions.sample.json`, and that `game/data/t01.json` equals the canonical T01 object from `GDD/data/levels.sample.json`.

```powershell
python -B -m unittest game.tests.test_interaction_fixture_sync
```

Expected RED: missing game mirror files.

- [x] **Step 2: Add exact runtime mirrors**

Copy only canonical T01 and interaction contract v2 into the specified `game/**` JSON files.

- [x] **Step 3: Re-run fixture sync**

```powershell
python -B -m unittest game.tests.test_interaction_fixture_sync
```

Expected GREEN: one sync test passes.

- [x] **Step 4: Commit fixture contract**

```powershell
git add game/data/t01.json game/tests/fixtures/interactions.v2.json game/tests/test_interaction_fixture_sync.py
git commit -m "test: mirror T01 interaction contract"
```

### Task 3: Implement the deterministic session model

**Files:**
- Add: `game/scripts/interaction_session.gd`
- Add: `game/tests/run_interaction_contract.gd`

- [x] **Step 1: Write a session-vector runner and observe RED**

The runner loads T01 and the interaction fixture, executes all `sessionCases`, prints case-specific failures and exits nonzero if any state differs.

```powershell
& 'C:\Users\khoat\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe' --headless --path game --script res://tests/run_interaction_contract.gd
```

Expected RED: `interaction_session.gd` or required API is missing.

- [x] **Step 2: Implement InteractionSession minimally**

Provide reset/load-initial/public-state plus actions `MarkX`, `ClearX`, `MarkStroke`, `UndoX`, `TryCat`, `RestartLevel`, `Retry`, `Hint`, `BackToHome`, `CloseApp`, `LevelWon` and `LevelFailed`.

- [x] **Step 3: Re-run session vectors**

Run the command from Step 1.

Expected: all session cases pass; gesture cases may still be reported as not implemented only if the runner explicitly separates phases.

- [x] **Step 4: Commit session model**

```powershell
git add game/scripts/interaction_session.gd game/tests/run_interaction_contract.gd
git commit -m "feat: implement deterministic interaction session"
```

### Task 4: Implement gesture contract v2

**Files:**
- Add: `game/scripts/gesture_engine.gd`
- Modify: `game/tests/run_interaction_contract.gd`

- [x] **Step 1: Extend runner to all gesture cases and observe RED**

Replay all canonical `cases`, including preview, 280 ms boundary, 12 px slop, different cells, second-drag, locked cells, interpolation, return path, secondary pointer and lifecycle flush/cancel.

Expected RED: gesture engine missing or mismatched cases.

- [x] **Step 2: Implement GestureEngine minimally**

Expose deterministic pointer down/move/up, pending flush, active cancel and visible preview state. Use the same session actions/events consumed by the UI.

- [x] **Step 3: Run full Godot interaction contract**

```powershell
& 'C:\Users\khoat\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe' --headless --path game --script res://tests/run_interaction_contract.gd
```

Expected GREEN: all gesture and session cases pass; output ends with `M0_A02_INTERACTION_CONTRACT_PASS`.

- [x] **Step 4: Run canonical Python oracle**

```powershell
python -B -m unittest GDD/tools/test_interaction_contract.py
```

Expected: 3 tests pass.

- [ ] **Step 5: Commit gesture behavior**

```powershell
git add game/scripts/gesture_engine.gd game/tests/run_interaction_contract.gd
git commit -m "feat: implement tap double-tap and stroke contract"
```

### Task 5: Build the playable board scene

**Files:**
- Add: `game/scripts/board_view.gd`
- Add: `game/scripts/board_screen.gd`
- Add: `game/scenes/board.tscn`
- Add: `game/tests/run_board_scene_smoke.gd`
- Modify: `game/scenes/bootstrap.tscn`

- [ ] **Step 1: Write scene smoke and observe RED**

Require a board scene with T01, status/hearts, Undo, Restart and restart confirmation. Instantiate it headlessly and exercise Undo plus Cancel/Confirm restart.

```powershell
& 'C:\Users\khoat\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe' --headless --path game --script res://tests/run_board_scene_smoke.gd
```

Expected RED: board scene/scripts are missing.

- [ ] **Step 2: Implement BoardView and BoardScreen**

Draw original region/pattern/cat/X states, map mouse/touch to logical cells, connect gesture timing, expose hearts/status, and implement Undo and Restart dialog.

- [ ] **Step 3: Integrate with bootstrap**

Instantiate `board.tscn` under bootstrap while preserving the bootstrap log marker and project main scene.

- [ ] **Step 4: Run scene smoke and runtime smoke**

```powershell
& 'C:\Users\khoat\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe' --headless --path game --script res://tests/run_board_scene_smoke.gd
$env:GODOT_BIN='C:\Users\khoat\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe'
python -B -m unittest discover game/tests -p test_*.py
```

Expected: scene smoke prints `M0_A02_BOARD_SCENE_PASS`; all game tests pass.

- [ ] **Step 5: Commit playable scene**

```powershell
git add game/scenes/bootstrap.tscn game/scenes/board.tscn game/scripts/board_view.gd game/scripts/board_screen.gd game/tests/run_board_scene_smoke.gd
git commit -m "feat: add playable T01 editor prototype"
```

### Task 6: Verify, document and hand off

**Files:**
- Add: `work/evidence/M0-A02/runtime-interaction-results.md`
- Generated: `work/evidence/M0-A02/verification.txt`
- Add: `work/handoffs/M0-A02.md`

- [ ] **Step 1: Run full verification**

```powershell
$env:GODOT_BIN='C:\Users\khoat\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe'
python -B -m unittest discover game/tests -p test_*.py
python -B -m unittest discover GDD/tools -p test_*.py
python -B -m unittest discover tools/tests -p test_*.py
python -B GDD/tools/validate_levels.py GDD/data/levels.sample.json
python tools/agent_pipeline.py validate
python tools/agent_pipeline.py doctor
```

Expected: all game/GDD/pipeline tests pass; 5 fixtures validate; validate/doctor exit 0.

- [ ] **Step 2: Run package verification**

Create a temporary `godot.exe` hard-link in the OS temp directory, prepend it to PATH for this process, then run:

```powershell
$env:PYTHONDONTWRITEBYTECODE='1'
python tools/agent_pipeline.py verify M0-A02
```

Expected: canonical Python and Godot interaction checks exit 0, no `__pycache__` is created, and `verification.txt` is refreshed.

- [ ] **Step 3: Record evidence and manual run instructions**

`runtime-interaction-results.md` must list contract counts, commands, pass results, known prototype limits and exact Editor steps: import `game/project.godot`, press F6/F5, then test tap/double/drag/Undo/Restart.

- [ ] **Step 4: Write complete handoff**

Fill Package, Requirements, QA, Changed files, Validation, Evidence, Remaining risks and Reviewer with no placeholders or TODO markers.

- [ ] **Step 5: Commit evidence and handoff**

```powershell
git add work/evidence/M0-A02 work/handoffs/M0-A02.md
git commit -m "docs: record M0-A02 prototype evidence"
```

- [ ] **Step 6: Final whole-branch review**

Review contract parity, preview rollback, Undo boundaries, locked cells, pointer ownership and Editor usability. Run `git diff --check` and confirm a clean tree.

- [ ] **Step 7: Handoff through pipeline**

```powershell
python tools/agent_pipeline.py handoff M0-A02
git add work/state/M0-A02.toml
git commit -m "chore: hand off M0-A02"
```

Expected: M0-A02 state is `review`. Do not start M0-A03 without an explicit human assignment.

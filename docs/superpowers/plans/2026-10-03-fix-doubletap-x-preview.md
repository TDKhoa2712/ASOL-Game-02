# Fix Double-Tap X Preview Flash — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate the X mark flash that appears on the cell when double-tapping to place candy.

**Architecture:** The preview system in `touch_decoder.gd` currently emits a cell preview on every touch-down. `puzzle_board.gd` renders that preview as an X mark. For double-taps this causes a visible X flash before the candy appears. The fix removes the touch-down preview emission so previews only start during drag (swipe), which is the only gesture that needs real-time preview per GDD GR-29.

**Tech Stack:** Godot 4.7 / GDScript

**Spec:** `GDD/02-luat-choi-va-trang-thai.md` — GR-29 specifies "giữ chạm rồi kéo → đánh X tức thì trên ô đầu": instant X on the first cell is a swipe (drag) behavior, not a touch-down behavior. Single tap (GR-11 row for empty→X) and double-tap (GR-12 row for candy placement) have no instant-preview requirement.

## Global Constraints

- Godot 4.7.2, GDScript only.
- Module ≤ 300 lines, one file one responsibility.
- No autoloads, no EventBus, signals only.
- Clean-room: no names from `extracted_reusable/`.
- Godot executable: `"D:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"`
- Branch from current `fix/region-painter-unique-colors` (which already contains a partial fix for this issue).

## Review Focus

1. **Swipe starting from a blank cell must still show X instantly on the first cell once drag begins** — `move()` emits the trail including the first cell; verify trail content includes the origin cell.
2. **Single tap X commit timing unchanged at 350ms** — the actual `mark_x` call is delayed by the double-tap window; removing the preview does not change this latency; verify `_test_single_tap` timing is unchanged.
3. **Second-touch drag (tap then drag on same cell)** — the first tap commits, then the drag emits swipe; preview must show during the drag phase; verify via `_test_second_touch_drag`.
4. **Cancel during pending tap must not leave stale preview** — `cancel()` already emits `preview_changed([])`, unaffected by this change.
5. **App focus loss during pending tap** — `_notification(FOCUS_OUT)` calls `flush_pending()` which calls `_commit_pending()` which emits `preview_changed([])`; unaffected.

---

### Task 1: Remove touch-down preview and update tests

**Files:**
- Modify: `game/scripts/input/touch_decoder.gd:29-31`
- Modify: `game/tests/test_touch_decoder.gd:51-61,75-84`

**Interfaces:**
- Consumes: nothing new
- Produces: `touch_decoder.begin()` no longer emits `preview_changed`; `preview_changed` is only emitted by `move()`, `finish()`, `cancel()`, and `_commit_pending()`

- [ ] **Step 1: Update `_test_double_tap_no_preview_leak` — write the failing test first**

Open `game/tests/test_touch_decoder.gd`. Replace `_test_double_tap_no_preview_leak` (lines 51–61) with:

```gdscript
func _test_double_tap_no_preview_leak() -> void:
	var d := TouchDecoder.new()
	var previews: Array = []
	d.preview_changed.connect(func(cells): previews.append(cells.duplicate(true)))
	d.begin(2, 3, 1000)
	_assert(previews.is_empty(), "touch-down emits no preview")
	d.finish(1010)
	_assert(previews.is_empty() or previews.back().is_empty(), "pending tap has no preview")
	d.begin(2, 3, 1200)
	d.finish(1220)
	_assert(previews.back().is_empty(), "double tap completes with cleared preview")
```

- [ ] **Step 2: Update `_test_live_preview` — swipe preview starts on move, not begin**

Replace `_test_live_preview` (lines 75–84) with:

```gdscript
func _test_live_preview() -> void:
	var d := TouchDecoder.new()
	var previews: Array = []
	d.preview_changed.connect(func(cells): previews.append(cells.duplicate(true)))
	d.begin(0, 0, 1000)
	_assert(previews.is_empty(), "touch-down emits no preview")
	d.move(0, 2)
	_assert(previews.back() == [[0, 0], [0, 1], [0, 2]], "drag previews full path including origin")
	d.finish(1100)
	_assert(previews.back().is_empty(), "committed swipe clears preview")
```

- [ ] **Step 3: Run tests to verify they fail**

Run:
```bash
"D:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --headless --path game --script res://tests/test_touch_decoder.gd
```

Expected: FAIL — `_test_double_tap_no_preview_leak` fails at "touch-down emits no preview" because `begin()` still emits `preview_changed`. `_test_live_preview` fails at "touch-down emits no preview" for the same reason.

- [ ] **Step 4: Remove preview emission from `begin()`**

Open `game/scripts/input/touch_decoder.gd`. Replace lines 29–31:

```gdscript
	_swipe_trail = [[row, col]]
	_last_swipe_cell = [row, col]
	preview_changed.emit(_swipe_trail.duplicate())
```

With:

```gdscript
	_swipe_trail = [[row, col]]
	_last_swipe_cell = [row, col]
```

This removes the only `preview_changed` emission from `begin()`. The trail is still initialized so `move()` will include the origin cell when emitting preview during drag.

- [ ] **Step 5: Run tests to verify they pass**

Run:
```bash
"D:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --headless --path game --script res://tests/test_touch_decoder.gd
```

Expected: `INPUT_TOUCH_DECODER_PASS`

- [ ] **Step 6: Run adjacent test suites to check for regressions**

Run:
```bash
"D:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --headless --path game --script res://tests/test_colorblind.gd
```

Expected: `COLORBLIND_PASS`

Run:
```bash
"D:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --headless --path game --script res://tests/test_play_session.gd
```

Expected: pass (the play_session tests exercise `mark_x` and `try_candy` directly, not through touch_decoder, so they are unaffected).

- [ ] **Step 7: Run clean-room gate**

```bash
rg -n "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/
```

Expected: no matches.

```bash
rg -n "extracted_reusable" game/scripts/ game/tests/
```

Expected: no matches.

- [ ] **Step 8: Commit**

```bash
git add game/scripts/input/touch_decoder.gd game/tests/test_touch_decoder.gd
git commit -m "fix(input): remove touch-down X preview to eliminate double-tap flash

begin() no longer emits preview_changed — preview only appears during
drag (move()), matching GDD GR-29 which specifies instant X on swipe,
not on touch-down. Double-tapping to place candy no longer flashes X.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

### Verification summary

| Gesture | Before fix | After fix |
|---------|-----------|-----------|
| Single tap blank | X preview on touch-down → X commit at 350ms | No preview → X commit at 350ms |
| Double tap blank | X preview flash ~80ms → candy | No flash → candy directly |
| Swipe from blank | X preview on touch-down → trail preview on drag | Trail preview starts on drag (includes origin cell) |
| Swipe from X | Clear preview on touch-down → trail preview | Trail preview starts on drag |

### Trade-off

Single tap loses the instant X preview (~350ms of visual anticipation before commit). The actual state change timing is unchanged. This matches GDD GR-29 which reserves "instant" feedback for swipe gestures only. If instant single-tap feedback is desired later, a neutral touch indicator (e.g., subtle press highlight) can be added as a separate enhancement without reintroducing the X preview.

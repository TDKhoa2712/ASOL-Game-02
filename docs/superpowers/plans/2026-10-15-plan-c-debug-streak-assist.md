# Plan C — Debug Streak/Assist Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give debug builds an injectable fake day, a "Streak/Assist" tab in the debug picker (day jumps, cycle/streak edits, stock edits, screen previews) and a session-only "debug levels count toward streak" switch.

**Architecture:** A plain `DayClock` instance (no autoload) is created in `app_shell` and injected into `AssistInventory`, which uses it everywhere it used `AssistRules.today()`. Pure data edits live in a static `AssistDebugOps`; a new `DebugStreakPanel` (4th picker tab) calls them through a single `AssistInventory.replace_data()`. Previews instantiate Plan B scenes as a throw-away overlay with fake dicts and never touch the inventory.

**Tech Stack:** Godot 4 / GDScript, headless SceneTree tests.

**Spec:** `docs/superpowers/specs/2026-10-15-streak-screens-debug-design.md` (§3.4, Q8, Q10, Q12)

## Global Constraints

- No autoloads; dependencies injected from `app_shell` (composition root). Signals, not a global bus.
- Every module ≤ 300 lines. `game/scripts/screens/app_shell.gd` is at exactly 300 lines now: this plan may only edit existing lines there, never add lines.
- Debug UI exists only when `OS.is_debug_build()`.
- Q12: fake date offset and the "debug levels count" switch live only in the session — never written to save. Previews use fake data and must not change the real save.
- Q10: branch `feat/v1.0.1/debug-streak-assist` from `feat/v1.0.1/assist-inventory`, merge back into it.
- TDD: test first, see it fail, implement, see it pass.
- Prerequisites: Plans B and A merged into `feat/v1.0.1/assist-inventory`. Interfaces used exactly: `NavController.Screen.STREAK`, `STREAK_ACTIVATE`, `STREAK_GIFT`; `screens/streak_screen.gd`; `screens/streak_activate_screen.gd` `setup(view: Dictionary)` + `signal continued`; `screens/streak_gift_screen.gd` `setup(reward: Dictionary)` (`{"hint","place"}`) + `signal continued`; view dict keys `{count, best, kept_today, at_risk, cycle_done}`.
- Where this plan calls `inventory.on_round_finished()`, read it as "the round-finished recording method introduced by Plan A (see the plan-a file)". If Plan A renamed it, use Plan A's name everywhere below; the toggle is designed at the `is_custom` check in `puzzle_assist_controller.gd`, not inside that method.

## Review Focus

1. Fake day moved forward, then "về ngày thật" — `today()` must equal `Time.get_date_string_from_system()` again and the streak view must reflect the real day (no stale offset).
2. Month/year boundary on +1 / +2 (e.g. `2026-12-31` +1 → `2027-01-01`, `2028-02-28` +1 → `2028-02-29`) — must produce a valid `YYYY-MM-DD` that `AssistRules.day_gap` accepts.
3. "Set cycle 0–6" then finishing a round on the same fake day must still advance (cycle edit sets `lastStreakDate` to yesterday), and value outside 0–6 is clamped.
4. Opening a preview and closing it leaves `assists.json` byte-identical (no write through preview).
5. Toggle off (default) → finishing a debug/custom level does not change streak; toggle on → it does; new `AssistInventory` instance (simulating restart) has toggle off again.

---

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `game/scripts/state/day_clock.gd` | Create | Session date source: `today()`, `offset_days`, `shift_date()` |
| `game/scripts/state/assist_debug_ops.gd` | Create | Static pure edits: set cycle, reset streak, reset stock, nudge stock |
| `game/scripts/state/assist_inventory.gd` | Modify | `clock` injection, `replace_data()`, session flag `debug_counts_custom` |
| `game/scripts/screens/debug_streak_panel.gd` | Create | Picker tab UI wiring buttons to clock/ops/inventory |
| `game/scripts/screens/debug_streak_preview.gd` | Create | Fake-data overlay for STREAK / STREAK_ACTIVATE / STREAK_GIFT |
| `game/scripts/screens/debug_level_picker.gd` | Modify | 4th tab "Streak/Assist", `setup(..., assists)` |
| `game/scripts/screens/title_screen.gd` | Modify | pass `assists` to `debug_picker.setup` |
| `game/scripts/screens/puzzle_assist_controller.gd` | Modify | `streak_source` + toggle at the `is_custom` check |
| `game/scripts/screens/puzzle_screen.gd` | Modify | line 80: set `assist_ctl.streak_source = assists` |
| `game/scripts/screens/app_shell.gd` | Modify (no new lines) | preload `DayClock`, inject on line 56 |
| `game/tests/test_day_clock.gd` | Create | clock + ops + inventory injection |
| `game/tests/test_debug_streak_panel.gd` | Create | panel buttons, preview no-write, toggle |
| `game/tests/test_assist_inventory.gd` | Modify | `replace_data`, clock fallback |

---

### Task 0: Branch

- [ ] **Step 1: Preflight and branch**

```bash
rtk git status --short
rtk git checkout feat/v1.0.1/assist-inventory
rtk git log --oneline -15   # confirm Plan A and Plan B merge commits are present; stop and report if not
rtk git checkout -b feat/v1.0.1/debug-streak-assist
```

Do not stage the pre-existing modified `.import` / `project.godot` / `.gitignore` files.

---

### Task 1: DayClock

**Files:**
- Create: `game/scripts/state/day_clock.gd`
- Test: `game/tests/test_day_clock.gd`

**Interfaces:**
- Produces: `DayClock` (`extends RefCounted`, `class_name` not used — preload it): `var offset_days: int = 0`; `func today() -> String`; `func advance(days: int) -> void`; `func reset() -> void`; `func is_faked() -> bool`; `static func shift_date(date: String, days: int) -> String`.

- [ ] **Step 1: Write the failing test**

```gdscript
# game/tests/test_day_clock.gd
extends SceneTree

const DayClock = preload("res://scripts/state/day_clock.gd")
var failures: Array[String] = []

func check(c: bool, m: String) -> void:
	if not c: failures.append(m)

func _init() -> void:
	var real := Time.get_date_string_from_system()
	var clock := DayClock.new()
	check(clock.today() == real and not clock.is_faked(), "default is real date")
	clock.advance(1)
	check(clock.offset_days == 1 and clock.today() == DayClock.shift_date(real, 1), "+1 day")
	clock.advance(2)
	check(clock.offset_days == 3 and clock.is_faked(), "+2 day skip")
	clock.reset()
	check(clock.today() == real and clock.offset_days == 0, "reset to real")
	check(DayClock.shift_date("2026-12-31", 1) == "2027-01-01", "year boundary")
	check(DayClock.shift_date("2028-02-28", 1) == "2028-02-29", "leap day")
	check(DayClock.shift_date("2026-10-15", -1) == "2026-10-14", "yesterday")
	check(DayClock.new().offset_days == 0, "new instance not faked (session-only)")
	_finish("DAY_CLOCK_PASS")

func _finish(tag: String) -> void:
	if failures.is_empty():
		print(tag); quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)
```

- [ ] **Step 2: Run, expect FAIL** (preload missing)

Run: `rtk godot --headless --path game --script res://tests/test_day_clock.gd`

- [ ] **Step 3: Implement**

```gdscript
# game/scripts/state/day_clock.gd
# Session-only date source; debug tools shift it, nothing persists it.
extends RefCounted

var offset_days: int = 0

func today() -> String:
	return shift_date(Time.get_date_string_from_system(), offset_days)

func advance(days: int) -> void:
	offset_days += days

func reset() -> void:
	offset_days = 0

func is_faked() -> bool:
	return offset_days != 0

static func shift_date(date: String, days: int) -> String:
	var unix := Time.get_unix_time_from_datetime_string(date + "T12:00:00")
	return Time.get_date_string_from_unix_time(unix + days * 86400)
```

(Noon anchor avoids any DST/rounding edge; `AssistRules.day_gap` rounds the same way.)

- [ ] **Step 4: Run, expect `DAY_CLOCK_PASS`**

- [ ] **Step 5: Commit**

```bash
rtk git add game/scripts/state/day_clock.gd game/tests/test_day_clock.gd
rtk git commit -m "feat(debug): add session day clock"
```

---

### Task 2: Inject clock into AssistInventory + debug ops

**Files:**
- Create: `game/scripts/state/assist_debug_ops.gd`
- Modify: `game/scripts/state/assist_inventory.gd`
- Modify: `game/scripts/screens/app_shell.gd:9,56` (edit lines in place, no new lines)
- Test: `game/tests/test_day_clock.gd` (extend), `game/tests/test_assist_inventory.gd` (extend)

**Interfaces:**
- Consumes: `DayClock` from Task 1; `AssistRules.new_data()`, `sanitize()`, `add()`, `streak_view()`, `CYCLE_DAYS`, `START`.
- Produces:
  - `AssistInventory.clock: Variant = null` (a DayClock; null → real date)
  - `AssistInventory.debug_counts_custom: bool = false` (never written to save)
  - `AssistInventory.today() -> String`
  - `AssistInventory.replace_data(next: Dictionary) -> void` (sanitizes, commits, emits `changed` for hint and place)
  - `AssistDebugOps.set_cycle(data: Dictionary, pos: int, today: String) -> Dictionary`
  - `AssistDebugOps.reset_streak(data: Dictionary) -> Dictionary`
  - `AssistDebugOps.reset_stock(data: Dictionary) -> Dictionary`
  - `AssistDebugOps.nudge(data: Dictionary, kind: String, delta: int) -> Dictionary`

- [ ] **Step 1: Write failing tests** — append to `_init()` of `test_day_clock.gd` before `_finish`:

```gdscript
	var Inv = load("res://scripts/state/assist_inventory.gd")
	var Ops = load("res://scripts/state/assist_debug_ops.gd")
	var dir := OS.get_user_data_dir().path_join("day_clock_%s" % Time.get_ticks_usec())
	var inv = Inv.new(dir)
	var c2 := DayClock.new()
	inv.clock = c2
	inv.on_round_finished()
	check(inv.data.lastStreakDate == c2.today(), "inventory uses injected clock")
	c2.advance(1)
	check(inv.streak_view().at_risk and not inv.streak_view().kept_today, "+1 day puts streak at risk")
	inv.on_round_finished()
	check(int(inv.data.totalStreak) == 2, "next fake day extends streak")
	c2.advance(2)
	check(inv.streak_view().count == 0, "skipped day drops view to 0")
	inv.replace_data(Ops.set_cycle(inv.data, 6, inv.today()))
	check(int(inv.data.streakDays) == 6 and inv.data.lastStreakDate == DayClock.shift_date(inv.today(), -1), "cycle 6, yesterday")
	var before_hint := inv.count("hint")
	var reward: Dictionary = inv.on_round_finished()
	check(reward.has("hint") and inv.count("hint") >= before_hint, "day 7 pays reward after set_cycle")
	inv.replace_data(Ops.set_cycle(inv.data, 99, inv.today()))
	check(int(inv.data.streakDays) == 6, "cycle clamped to 6")
	inv.replace_data(Ops.reset_streak(inv.data))
	check(int(inv.data.totalStreak) == 0 and inv.data.lastStreakDate == "" and int(inv.data.streakDays) == 0, "reset streak")
	inv.replace_data(Ops.nudge(inv.data, "place", 1))
	inv.replace_data(Ops.nudge(inv.data, "hint", -1))
	inv.replace_data(Ops.reset_stock(inv.data))
	check(inv.count("hint") == 3 and inv.count("place") == 1, "reset stock to START")
	inv.debug_counts_custom = true
	check(not Inv.new(dir).debug_counts_custom, "toggle not persisted")
	check(Inv.new(dir).clock == null, "clock not persisted")
	inv._store.remove_all()
```

Append to `test_assist_inventory.gd` before the PASS check:

```gdscript
	var rdir := dir + "_replace"
	var r_inv := Inventory.new(rdir)
	var seen: Array = []
	r_inv.changed.connect(func(k, c): seen.append(k))
	r_inv.replace_data({"hint": 999, "place": -4})
	check(r_inv.count("hint") == 10 and r_inv.count("place") == 0, "replace_data sanitizes")
	check(seen == ["hint", "place"], "replace_data emits both kinds")
	check(Inventory.new(rdir).count("hint") == 10, "replace_data persists")
	check(r_inv.today() == Time.get_date_string_from_system(), "no clock -> real date")
	r_inv._store.remove_all()
```

- [ ] **Step 2: Run both, expect FAIL**

Run: `rtk godot --headless --path game --script res://tests/test_day_clock.gd` and `... res://tests/test_assist_inventory.gd`

- [ ] **Step 3: Implement ops**

```gdscript
# game/scripts/state/assist_debug_ops.gd
# Pure debug edits of assist/streak data; callers commit via AssistInventory.replace_data.
extends RefCounted

const AssistRules = preload("res://scripts/state/assist_rules.gd")
const DayClock = preload("res://scripts/state/day_clock.gd")

static func set_cycle(data: Dictionary, pos: int, today: String) -> Dictionary:
	var next := data.duplicate(true)
	var p := clampi(pos, 0, AssistRules.CYCLE_DAYS - 1)
	next.streakDays = p
	next.totalStreak = maxi(int(next.get("totalStreak", 0)), p)
	next.bestStreak = maxi(int(next.get("bestStreak", 0)), int(next.totalStreak))
	next.lastStreakDate = DayClock.shift_date(today, -1) if p > 0 else ""
	return next

static func reset_streak(data: Dictionary) -> Dictionary:
	var next := data.duplicate(true)
	next.streakDays = 0
	next.totalStreak = 0
	next.lastStreakDate = ""
	next.usedHint = 0
	next.usedPlace = 0
	return next

static func reset_stock(data: Dictionary) -> Dictionary:
	var next := data.duplicate(true)
	for kind in AssistRules.KINDS:
		next[kind] = int(AssistRules.START[kind])
	return next

static func nudge(data: Dictionary, kind: String, delta: int) -> Dictionary:
	var next := data.duplicate(true)
	next[kind] = clampi(int(next.get(kind, 0)) + delta, 0, AssistRules.CAP)
	return next
```

Note: `reset_streak` keeps `bestStreak` (spec Q11: record is the highest ever reached).

- [ ] **Step 4: Modify `assist_inventory.gd`**

Add after `var _store: DualSlotStore`:

```gdscript
var clock: Variant = null  # DayClock injected by app_shell; null -> real date
var debug_counts_custom: bool = false  # session-only debug switch, never saved
```

Replace the two `today if today != "" else AssistRules.today()` expressions with `today if today != "" else today()` — careful: the parameter is also named `today`, so rename the parameter to `date` in both `on_round_finished` and `streak_view` (keep default `""`): `AssistRules.record_win(data, date if date != "" else today())`. Then add:

```gdscript
func today() -> String:
	return clock.today() if clock != null else AssistRules.today()

func replace_data(next: Dictionary) -> void:
	_commit(AssistRules.sanitize(next), AssistRules.KINDS)
```

If Plan A changed the round-finished recording method's body, apply the same `today()` substitution there.

- [ ] **Step 5: Modify `app_shell.gd` without adding lines**

Line 9 — append to the existing line: `; const DayClock = preload("res://scripts/state/day_clock.gd")`

Line 56 becomes:

```gdscript
	if assists == null: assists = AssistInventory.new(profile_dir); assists.clock = DayClock.new(); assists.save_failed.connect(_on_save_failed)
```

Check: `wc -l game/scripts/screens/app_shell.gd` still prints 300.

- [ ] **Step 6: Run both suites, expect `DAY_CLOCK_PASS` and `ASSIST_INVENTORY_PASS`**; also `test_assist_rules.gd`, `test_assist_flow.gd`, `test_streak_ui.gd`.

- [ ] **Step 7: Commit**

```bash
rtk git add game/scripts/state/assist_debug_ops.gd game/scripts/state/assist_inventory.gd game/scripts/screens/app_shell.gd game/tests/test_day_clock.gd game/tests/test_assist_inventory.gd
rtk git commit -m "feat(debug): inject day clock into assist inventory and add debug ops"
```

---

### Task 3: "Debug levels count toward streak" at the is_custom check

**Files:**
- Modify: `game/scripts/screens/puzzle_assist_controller.gd:51-55`
- Modify: `game/scripts/screens/puzzle_screen.gd:80`
- Test: `game/tests/test_debug_streak_panel.gd` (create; toggle section)

**Interfaces:**
- Consumes: `AssistInventory.debug_counts_custom`.
- Produces: `PuzzleAssistController.streak_source: Variant = null` — the inventory used only for streak recording, set even when `inventory` is null for custom levels.

- [ ] **Step 1: Write failing test**

```gdscript
# game/tests/test_debug_streak_panel.gd
extends SceneTree

const Inv = preload("res://scripts/state/assist_inventory.gd")
const DayClock = preload("res://scripts/state/day_clock.gd")
const Ctl = preload("res://scripts/screens/puzzle_assist_controller.gd")
var failures: Array[String] = []

func check(c: bool, m: String) -> void:
	if not c: failures.append(m)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var dir := OS.get_user_data_dir().path_join("dbg_streak_%s" % Time.get_ticks_usec())
	var inv := Inv.new(dir); inv.clock = DayClock.new()
	var ctl := Ctl.new(); root.add_child(ctl)
	ctl.bind(null, null)          # puzzle_screen binds null for custom levels
	ctl.streak_source = inv
	var fake_session := RefCounted.new()
	ctl.on_round_finished(fake_session, true)
	check(int(inv.data.totalStreak) == 0, "custom level ignored by default")
	inv.debug_counts_custom = true
	ctl.on_round_finished(fake_session, true)
	check(int(inv.data.totalStreak) == 1, "custom level counts when toggled")
	_panel_tests(inv)
	inv._store.remove_all()
	if failures.is_empty():
		print("DEBUG_STREAK_PANEL_PASS"); quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func _panel_tests(_inv) -> void:
	pass  # filled in Task 4
```

Before writing, read `puzzle_assist_controller.gd` `extends`/`_init`: if it is not a Node, replace `root.add_child(ctl)` with nothing; if `on_round_finished` touches `session.phase` or `_screen`, pass a real `PlaySession` as used in `test_streak_burst.gd` instead of `RefCounted.new()`.

- [ ] **Step 2: Run, expect FAIL** (`streak_source` missing)

Run: `rtk godot --headless --path game --script res://tests/test_debug_streak_panel.gd`

- [ ] **Step 3: Implement** in `puzzle_assist_controller.gd`: add `var streak_source: Variant = null` next to `inventory`, and replace the guard of `on_round_finished`:

```gdscript
func on_round_finished(session: Variant, is_custom: bool) -> Dictionary:
	var inv: Variant = streak_source if streak_source != null else inventory
	if inv == null or session == null or (is_custom and not inv.debug_counts_custom):
		return {}
	burst_played = false
	var reward: Dictionary = inv.on_round_finished()
```

(use `inv` for the rest of the body where it used `inventory`). In `puzzle_screen.gd:80`, append on the same line after the `bind(...)` call: `; assist_ctl.streak_source = assists` (still inside the `if board != null:` one-liner — move it so it runs regardless: put it as the first statement of that line only if the line structure allows; otherwise add one line after line 80, `puzzle_screen.gd` must stay ≤ 300 lines).

- [ ] **Step 4: Run, expect `DEBUG_STREAK_PANEL_PASS`**; rerun `test_streak_burst.gd`, `test_assist_flow.gd`, `test_assist_ui.gd`.

- [ ] **Step 5: Commit**

```bash
rtk git add game/scripts/screens/puzzle_assist_controller.gd game/scripts/screens/puzzle_screen.gd game/tests/test_debug_streak_panel.gd
rtk git commit -m "feat(debug): let debug levels count toward streak when toggled"
```

---

### Task 4: Preview overlay + Streak/Assist panel

**Files:**
- Create: `game/scripts/screens/debug_streak_preview.gd`
- Create: `game/scripts/screens/debug_streak_panel.gd`
- Test: `game/tests/test_debug_streak_panel.gd` (replace `_panel_tests`)

**Interfaces:**
- Consumes: `DayClock`, `AssistDebugOps`, `AssistInventory.{clock, today(), replace_data(), streak_view(), count(), debug_counts_custom}`; Plan B scenes via `AppShell.SCENE_MAP` keys for `NavController.Screen.STREAK`, `STREAK_ACTIVATE`, `STREAK_GIFT` (open `app_shell.gd` after Plan B merges and copy the three exact key strings into `PREVIEW_KEYS` below; expected `"streak"`, `"streak_activate"`, `"streak_gift"`).
- Produces:
  - `DebugStreakPreview.FAKE_VIEW: Dictionary`, `FAKE_REWARD: Dictionary`, `static func open(host: Control, screen: int) -> Control` (returns the overlay, which frees itself on `continued` or tap)
  - `DebugStreakPanel extends VBoxContainer`: `signal changed()`; `func setup(assists: Variant) -> void`; `func date_text() -> String`; button nodes named `PlusDay`, `SkipDay`, `RealDay`, `CycleSpin`, `CycleApply`, `ResetStreak`, `HintPlus`, `HintMinus`, `PlacePlus`, `PlaceMinus`, `ResetStock`, `PreviewStreak`, `PreviewActivate`, `PreviewGift`, `CountToggle`, label `DateLabel`.

- [ ] **Step 1: Write failing tests** — replace `_panel_tests` in `test_debug_streak_panel.gd`:

```gdscript
func _panel_tests(inv) -> void:
	const Panel = preload("res://scripts/screens/debug_streak_panel.gd")
	inv.debug_counts_custom = false
	var p := Panel.new(); root.add_child(p); p.setup(inv)
	var real := Time.get_date_string_from_system()
	check(p.get_node("%DateLabel").text.contains(real), "shows real date")
	p.get_node("%PlusDay").emit_signal("pressed")
	check(inv.clock.offset_days == 1 and p.get_node("%DateLabel").text.contains(inv.today()), "+1 day shown")
	p.get_node("%SkipDay").emit_signal("pressed")
	check(inv.clock.offset_days == 3, "skip = +2")
	p.get_node("%RealDay").emit_signal("pressed")
	check(inv.clock.offset_days == 0, "back to real")
	p.get_node("%CycleSpin").value = 4
	p.get_node("%CycleApply").emit_signal("pressed")
	check(int(inv.data.streakDays) == 4, "cycle set")
	p.get_node("%ResetStreak").emit_signal("pressed")
	check(int(inv.data.totalStreak) == 0, "streak reset")
	var h := inv.count("hint")
	p.get_node("%HintPlus").emit_signal("pressed")
	check(inv.count("hint") == mini(h + 1, 10), "hint +1")
	p.get_node("%PlaceMinus").emit_signal("pressed")
	p.get_node("%ResetStock").emit_signal("pressed")
	check(inv.count("hint") == 3 and inv.count("place") == 1, "stock reset")
	check(not p.get_node("%CountToggle").button_pressed, "toggle default off")
	p.get_node("%CountToggle").button_pressed = true
	check(inv.debug_counts_custom, "toggle writes session flag")
	# previews never write save
	var path := inv._store.primary_path() if inv._store.has_method("primary_path") else ""
	var snapshot := JSON.stringify(inv.data)
	var file_before := FileAccess.get_file_as_string(path) if path != "" else ""
	for name in ["PreviewStreak", "PreviewActivate", "PreviewGift"]:
		p.get_node("%" + name).emit_signal("pressed")
		var overlay: Node = p.get_tree().root.get_node_or_null("DebugStreakPreview")
		check(overlay != null, name + " opens overlay")
		if overlay != null: overlay.queue_free(); await process_frame
	check(JSON.stringify(inv.data) == snapshot, "preview leaves data untouched")
	if path != "": check(FileAccess.get_file_as_string(path) == file_before, "file unchanged")
	p.queue_free()
```

Replace the `path` lines with whatever `DualSlotStore` exposes for its file path (read `state/dual_slot_store.gd`); the required assertion is that the slot file content before and after the previews is identical. Make `_run` `await _panel_tests(inv)`.

- [ ] **Step 2: Run, expect FAIL**

- [ ] **Step 3: Implement preview**

```gdscript
# game/scripts/screens/debug_streak_preview.gd
# Debug-only overlay showing streak screens with fake data; never touches the inventory.
extends RefCounted

const AppShell = preload("res://scripts/screens/app_shell.gd")
const NavController = preload("res://scripts/<path-of>/nav_controller.gd")  # copy the path app_shell.gd preloads
const FAKE_VIEW := {"count": 12, "best": 20, "kept_today": false, "at_risk": true, "cycle_done": 5}
const FAKE_REWARD := {"hint": 2, "place": 1}
const PREVIEW_KEYS := {"streak": "streak", "activate": "streak_activate", "gift": "streak_gift"}

static func key_for(screen: int) -> String:
	match screen:
		NavController.Screen.STREAK: return PREVIEW_KEYS.streak
		NavController.Screen.STREAK_ACTIVATE: return PREVIEW_KEYS.activate
		NavController.Screen.STREAK_GIFT: return PREVIEW_KEYS.gift
	return ""

static func open(host: Control, screen: int) -> Control:
	var path: String = AppShell.SCENE_MAP.get(key_for(screen), "")
	if path == "" or not ResourceLoader.exists(path): return null
	var node := (load(path) as PackedScene).instantiate() as Control
	node.name = "DebugStreakPreview"
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if screen == NavController.Screen.STREAK_GIFT: node.call("setup", FAKE_REWARD)
	elif node.has_method("setup"): node.call("setup", FAKE_VIEW)
	if node.has_signal("continued"): node.connect("continued", node.queue_free)
	node.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT: node.queue_free())
	host.get_tree().root.add_child(node)
	return node
```

Never set `assists` on the preview node. For STREAK, check `streak_screen.gd` after Plan B: if its `setup` takes something other than the view dict, pass the fake view through whatever field it reads (still no inventory); if it reads `assists.streak_view()`, give it a stub object `{streak_view = func(): FAKE_VIEW}`-style RefCounted defined in this file — never the real inventory. If `streak_screen` has no `continued`, give it a "Đóng" button added by this helper that calls `queue_free`.

- [ ] **Step 4: Implement panel** (keep ≤ 300 lines)

```gdscript
# game/scripts/screens/debug_streak_panel.gd
# Debug picker tab: fake date, streak/cycle edits, assist stock, previews, count toggle.
extends VBoxContainer

signal changed()

const Palette = preload("res://scripts/theme/palette.gd")
const Ops = preload("res://scripts/state/assist_debug_ops.gd")
const DayClock = preload("res://scripts/state/day_clock.gd")
const Preview = preload("res://scripts/screens/debug_streak_preview.gd")
const NavController = preload("res://scripts/<path-of>/nav_controller.gd")  # same path as app_shell

var _inv: Variant = null
var _date_lbl: Label
var _stock_lbl: Label
var _cycle_spin: SpinBox
var _toggle: CheckButton

func _init() -> void:
	add_theme_constant_override("separation", 10)
	_build_ui()

func setup(assists: Variant) -> void:
	_inv = assists
	if _inv != null and _inv.clock == null: _inv.clock = DayClock.new()
	_toggle.set_pressed_no_signal(_inv != null and _inv.debug_counts_custom)
	_refresh()

func date_text() -> String:
	if _inv == null: return "Ngày: —"
	var tag := " (giả, %+d)" % _inv.clock.offset_days if _inv.clock.is_faked() else " (thật)"
	return "Ngày: " + _inv.today() + tag

func _build_ui() -> void:
	_date_lbl = _label("DateLabel")
	var day := _row()
	_btn(day, "PlusDay", "+1 ngày", func(): _shift(1))
	_btn(day, "SkipDay", "Bỏ lỡ 1 ngày (+2)", func(): _shift(2))
	_btn(day, "RealDay", "Về ngày thật", func(): if _inv != null: _inv.clock.reset(); _refresh())
	var cyc := _row()
	_cycle_spin = SpinBox.new(); _cycle_spin.name = "CycleSpin"; _cycle_spin.unique_name_in_owner = true
	_cycle_spin.min_value = 0; _cycle_spin.max_value = 6; cyc.add_child(_cycle_spin)
	_btn(cyc, "CycleApply", "Đặt vị trí chu kỳ", func(): _apply(Ops.set_cycle(_inv.data, int(_cycle_spin.value), _inv.today())))
	_btn(cyc, "ResetStreak", "Reset chuỗi", func(): _apply(Ops.reset_streak(_inv.data)))
	_stock_lbl = _label("StockLabel")
	var stock := _row()
	_btn(stock, "HintPlus", "+ hint", func(): _apply(Ops.nudge(_inv.data, "hint", 1)))
	_btn(stock, "HintMinus", "− hint", func(): _apply(Ops.nudge(_inv.data, "hint", -1)))
	_btn(stock, "PlacePlus", "+ place", func(): _apply(Ops.nudge(_inv.data, "place", 1)))
	_btn(stock, "PlaceMinus", "− place", func(): _apply(Ops.nudge(_inv.data, "place", -1)))
	_btn(stock, "ResetStock", "Reset kho", func(): _apply(Ops.reset_stock(_inv.data)))
	var prev := _row()
	_btn(prev, "PreviewStreak", "Xem màn Chuỗi", func(): Preview.open(self, NavController.Screen.STREAK))
	_btn(prev, "PreviewActivate", "Xem Kích hoạt", func(): Preview.open(self, NavController.Screen.STREAK_ACTIVATE))
	_btn(prev, "PreviewGift", "Xem Nhận quà", func(): Preview.open(self, NavController.Screen.STREAK_GIFT))
	_toggle = CheckButton.new(); _toggle.name = "CountToggle"; _toggle.unique_name_in_owner = true
	_toggle.text = "Level debug tính chuỗi (chỉ phiên này)"; _toggle.add_theme_font_size_override("font_size", 24)
	_toggle.toggled.connect(func(on: bool): if _inv != null: _inv.debug_counts_custom = on)
	add_child(_toggle)

func _shift(days: int) -> void:
	if _inv == null: return
	_inv.clock.advance(days); _refresh()

func _apply(next: Dictionary) -> void:
	if _inv == null: return
	_inv.replace_data(next); _refresh()

func _refresh() -> void:
	_date_lbl.text = date_text()
	if _inv != null:
		var v: Dictionary = _inv.streak_view()
		_stock_lbl.text = "Chuỗi %d (kỷ lục %d), chu kỳ %d/7 — hint %d, place %d" % [v.count, v.best, v.cycle_done, _inv.count("hint"), _inv.count("place")]
	changed.emit()

func _label(n: String) -> Label:
	var l := Label.new(); l.name = n; l.unique_name_in_owner = true
	l.add_theme_font_size_override("font_size", 24); l.add_theme_color_override("font_color", Palette.INK)
	add_child(l); return l

func _row() -> HBoxContainer:
	var r := HBoxContainer.new(); r.add_theme_constant_override("separation", 8); add_child(r); return r

func _btn(parent: Container, n: String, text: String, cb: Callable) -> Button:
	var b := Button.new(); b.name = n; b.unique_name_in_owner = true; b.text = text
	b.custom_minimum_size.y = 56; b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb); parent.add_child(b); return b
```

Note `unique_name_in_owner` requires `owner = self` on each child for `%Name` lookup; set `b.owner = self` / `l.owner = self` after `add_child`, or have the test use `p.find_child("PlusDay", true, false)` instead of `%`. Pick one and use it consistently in test and code.

- [ ] **Step 5: Run, expect `DEBUG_STREAK_PANEL_PASS`**

- [ ] **Step 6: Commit**

```bash
rtk git add game/scripts/screens/debug_streak_preview.gd game/scripts/screens/debug_streak_panel.gd game/tests/test_debug_streak_panel.gd
rtk git commit -m "feat(debug): add streak/assist debug panel and fake-data previews"
```

---

### Task 5: Wire the tab into the debug picker

**Files:**
- Modify: `game/scripts/screens/debug_level_picker.gd` (setup signature, tab row at line 143, `_switch_mode` at 207)
- Modify: `game/scripts/screens/title_screen.gd:191`
- Test: `game/tests/test_debug_level_picker.gd` (extend)

**Interfaces:**
- Consumes: `DebugStreakPanel.setup(assists)`.
- Produces: `DebugLevelPicker.setup(bank, playlist := [], endless_rt = null, campaign_rt = null, assists: Variant = null)`; mode `3` = Streak/Assist; `_streak_panel: DebugStreakPanel`.

- [ ] **Step 1: Write failing test** — append to `_run_tests` in `test_debug_level_picker.gd` before the result print:

```gdscript
	var sdir := OS.get_user_data_dir().path_join("picker_streak_%s" % Time.get_ticks_usec())
	var s_inv = load("res://scripts/state/assist_inventory.gd").new(sdir)
	picker.setup(bank, [], null, null, s_inv)
	picker._switch_mode(3)
	_assert(picker._streak_panel != null and picker._streak_panel.visible, "streak tab visible in mode 3")
	_assert(not picker._playlist_container.visible and not picker._endless_panel.visible, "other tabs hidden")
	_assert(not picker._play_btn.visible, "play button hidden on streak tab")
	picker._switch_mode(0)
	_assert(not picker._streak_panel.visible and picker._play_btn.visible, "back to playlist")
	s_inv._store.remove_all()
```

- [ ] **Step 2: Run, expect FAIL**

Run: `rtk godot --headless --path game --script res://tests/test_debug_level_picker.gd`

- [ ] **Step 3: Implement**

- Preload: `const DebugStreakPanel = preload("res://scripts/screens/debug_streak_panel.gd")`; `var _streak_panel: DebugStreakPanel; var _tab_streak_btn: Button`.
- `setup(...)`: add trailing `assists: Variant = null` and `if _streak_panel != null: _streak_panel.setup(assists)`.
- Line 143: append `; _tab_streak_btn = _tab_btn("Streak/Assist", 3, tabs)`.
- After the endless panel block: `_streak_panel = DebugStreakPanel.new(); _streak_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL; _streak_panel.visible = false; root_vbox.add_child(_streak_panel)`.
- `_switch_mode`: add `_streak_panel.visible = (_mode == 3); _play_btn.visible = (_mode != 3)` to the first line's assignments (and hide the info panel if it is stored in a member; otherwise leave it).
- Confirm file stays ≤ 300 lines (`wc -l`).
- `title_screen.gd:191`: `debug_picker.setup(b, pl, endless_rt, rt, assists)`; also refresh the streak chip when the panel changes: in the `if OS.is_debug_build()` block add `debug_picker._streak_panel.changed.connect(func(): if streak_chip != null: streak_chip.bind(assists))` only if `streak_chip.bind` is idempotent (check `streak_chip` script); otherwise skip — title refreshes on next visit.

- [ ] **Step 4: Run `test_debug_level_picker.gd`, `test_debug_features.gd`, `test_screens.gd`, `test_debug_streak_panel.gd`** — all PASS.

- [ ] **Step 5: Commit**

```bash
rtk git add game/scripts/screens/debug_level_picker.gd game/scripts/screens/title_screen.gd game/tests/test_debug_level_picker.gd
rtk git commit -m "feat(debug): add Streak/Assist tab to debug picker"
```

---

### Task 6: Gate, STATUS, merge

- [ ] **Step 1: Line budget** — `wc -l` every modified/created script; all ≤ 300, `app_shell.gd` exactly 300.

- [ ] **Step 2: Gate**

```bash
rtk python -B tools/clean_room.py
rtk python -B tools/verify.py --godot <godot-executable>
```

Expected: all PASS except the verifier's known negative self-tests. Log saved under `scratch/verification/`; note its filename and the revision.

- [ ] **Step 3: STATUS** — in `docs/STATUS.md` add an entry for Plan C: what landed (DayClock injected from app_shell, Streak/Assist debug tab, previews with fake data, session-only toggle), verification revision + log path + result, limit: "headless only; no device QA of the debug tab". Only record what the log shows.

```bash
rtk git add docs/STATUS.md
rtk git commit -m "docs(status): record debug streak/assist plan C"
```

- [ ] **Step 4: Merge back** (only with merge permission for this branch)

```bash
rtk git checkout feat/v1.0.1/assist-inventory
rtk git merge --no-ff feat/v1.0.1/debug-streak-assist -m "merge: debug streak/assist (plan C)"
rtk godot --headless --path game --script res://tests/test_debug_streak_panel.gd
```

Do not push unless asked.

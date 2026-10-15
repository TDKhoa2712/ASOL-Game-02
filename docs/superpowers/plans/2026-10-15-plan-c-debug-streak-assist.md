# Plan C — Debug Streak/Assist Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give debug builds an injectable fake day, a "Streak/Assist" tab in the debug picker (day jumps, cycle/streak edits, stock edits, screen previews) and a session-only "debug levels count toward streak" switch.

**Architecture:** A plain `DayClock` instance (no autoload) is created in `app_shell` and injected into `AssistInventory`, which uses it everywhere it used `AssistRules.today()`. Every production caller passes no date, so the whole app (Home chip, Streak screen, round recording, activate/gift flow) follows the one clock. Pure data edits live in a static `AssistDebugOps`; a new `DebugStreakPanel` (4th picker tab) calls them through a single `AssistInventory.replace_data()`. Previews build the Plan A/B scenes through `ScreenRouter` as a throw-away overlay with fake dicts and never touch the inventory.

**Tech Stack:** Godot 4 / GDScript, headless SceneTree tests.

**Spec:** `docs/superpowers/specs/2026-10-15-streak-screens-debug-design.md` (§3.4, Q8, Q10, Q12)

## Global Constraints

- No autoloads; dependencies injected from `app_shell` (composition root). Signals, not a global bus.
- Every module ≤ 300 lines; one statement per line — never join statements/declarations onto shared lines to save space. After Plans B and A, `app_shell.gd` is at 291 lines; this plan adds 3 (→ 294). `puzzle_screen.gd` is at 300: this plan only edits its line 80 in place (no new statement).
- Debug UI exists only when `OS.is_debug_build()`.
- Q12: fake date offset and the "debug levels count" switch live only in the session — never written to save. Previews use fake data and must not change the real save.
- Q10: branch `feat/v1.0.1/debug-streak-assist` from `feat/v1.0.1/assist-inventory`, merge back with `git merge --no-ff` into it. Do not push.
- Order: Plans B and A merged first; Plan D2 (if it touches `debug_level_picker.gd`, `debug_endless_panel.gd`, `debug_reset_bar.gd` or `app_shell.gd`) merged before this plan starts.
- TDD: test first, see it fail, implement, see it pass.
- Commits: Conventional Commits ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Stage only listed files; never the pre-existing modified `.import` / `project.godot` / `.gitignore`.
- Interfaces from Plans B/A, used exactly (stop and report a blocker if any differs on the branch):
  - `AssistInventory.on_round_finished(today: String = "") -> Dictionary` returning `{"extended": bool, "view": Dictionary, "reward": Dictionary}` (`reward` = `{"hint": int, "place": int}` on day 7, else `{}`); `AssistInventory.streak_view(today: String = "") -> Dictionary` with keys `{count, best, kept_today, at_risk, cycle_done}`. There is no `streak_extended` signal.
  - `PuzzleAssistController.on_round_finished(session: Variant, is_custom: bool) -> Dictionary` and `var round_result: Dictionary` (`game/scripts/screens/puzzle_assist_controller.gd`, `extends RefCounted`).
  - `game/scripts/campaign/streak_flow.gd` (`StreakFlow.start(source, final_screen)`, `next()`), read by `app_shell._on_level_done` from `cur_sc.get("assist_ctl")`.
  - `game/scripts/campaign/nav_controller.gd`: `enum Screen { TITLE, PUZZLE, WIN, FAIL, STREAK, STREAK_ACTIVATE, STREAK_GIFT }`, `SCREEN_NAMES` values `"streak"`, `"streak_activate"`, `"streak_gift"`.
  - `game/scripts/campaign/screen_router.gd` (`ScreenRouter`): `SCENE_MAP` keys `"streak"`, `"streak_activate"`, `"streak_gift"` (equal to the `SCREEN_NAMES` values), `static func instantiate(screen_name: String) -> Control`.
  - `screens/streak_screen.gd`: `setup(inv: Variant, today: String = "")`, `show_view(view: Dictionary)`, `signal back_pressed`, `count_label`, `flame` (`lit`).
  - `screens/streak_activate_screen.gd`: `setup(view: Dictionary)`, `signal continued()`. `screens/streak_gift_screen.gd`: `setup(reward: Dictionary)` (`{"hint","place"}`), `signal continued()`.
  - `screens/streak_chip.gd`: `bind(inv)`, `refresh(today: String = "")`, `count_label`.
- Save files: `AssistInventory.new(profile_dir)` uses `DualSlotStore.new(profile_dir, "assists")`, i.e. `<profile_dir>/assists.a.json`, `<profile_dir>/assists.b.json`, flag `<profile_dir>/assists.flag` (legacy read-only `<profile_dir>/assists.json`). In the app `profile_dir` is `user://profile`.
- Today flow: `DayClock` is the single date source. `AssistInventory.current_day()` returns `clock.today()` (or `AssistRules.today()` without a clock) and is the default whenever a `today` argument is `""`. Production callers (`streak_chip.refresh()`, `app_shell` → `streak_screen.setup(assists)`, `PuzzleAssistController.on_round_finished` → `inventory.on_round_finished()`, and Plan A's `StreakFlow` which only reads the returned `view`) pass no date; explicit dates are only for tests. Task 2 pins this with a test.

## Review Focus

1. Fake day moved forward, then "về ngày thật" — `current_day()` must equal `Time.get_date_string_from_system()` again and the streak view must reflect the real day (no stale offset).
2. Month/year boundary on +1 / +2 (e.g. `2026-12-31` +1 → `2027-01-01`, `2028-02-28` +1 → `2028-02-29`) — must produce a valid `YYYY-MM-DD` that `AssistRules.day_gap` accepts.
3. "Set cycle 0–6" then finishing a round on the same fake day must still advance (cycle edit sets `lastStreakDate` to yesterday), and value outside 0–6 is clamped.
4. Opening a preview and closing it leaves `assists.a.json`, `assists.b.json` and `assists.flag` byte-identical (no write through preview).
5. Toggle off (default) → finishing a debug/custom level does not change streak; toggle on → it does (and `app_shell` then shows the activate step); new `AssistInventory` instance (simulating restart) has toggle off again.
6. Home chip and Streak screen follow the fake day (Task 2 callers test).

---

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `game/scripts/state/day_clock.gd` | Create | Session date source: `today()`, `offset_days`, `shift_date()` |
| `game/scripts/state/assist_debug_ops.gd` | Create | Static pure edits: set cycle, reset streak, reset stock, nudge stock |
| `game/scripts/state/assist_inventory.gd` | Modify | `clock` injection, `current_day()`, `replace_data()`, session flag `debug_counts_custom` |
| `game/scripts/screens/debug_streak_panel.gd` | Create | Picker tab UI wiring buttons to clock/ops/inventory |
| `game/scripts/screens/debug_streak_preview.gd` | Create | Fake-data overlay for STREAK / STREAK_ACTIVATE / STREAK_GIFT |
| `game/scripts/screens/debug_level_picker.gd` | Modify | 4th tab "Streak/Assist", `setup(..., assists)` |
| `game/scripts/screens/title_screen.gd` | Modify | pass `assists` to `debug_picker.setup`, refresh chip on panel change |
| `game/scripts/screens/puzzle_assist_controller.gd` | Modify | `streak_source` + toggle at the `is_custom` check |
| `game/scripts/screens/puzzle_screen.gd` | Modify (line 80 in place) | pass `assists` as streak source to `assist_ctl.bind` |
| `game/scripts/screens/app_shell.gd` | Modify (+3 lines) | preload `DayClock`, own `day_clock`, inject into `assists` |
| `game/tests/test_day_clock.gd` | Create | clock + ops + inventory injection + callers |
| `game/tests/test_debug_streak_panel.gd` | Create | panel buttons, preview no-write, toggle |
| `game/tests/test_assist_inventory.gd` | Modify | `replace_data`, clock fallback |
| `game/tests/test_debug_level_picker.gd` | Modify | Streak/Assist tab |

---

### Task 0: Branch

- [ ] **Step 1: Preflight and branch**

```bash
rtk git status --short
rtk git checkout feat/v1.0.1/assist-inventory
rtk git log --oneline -15   # Plan B, Plan A (and D2 if it ran) merge commits must be present; stop and report if not
ls game/scripts/campaign/screen_router.gd game/scripts/campaign/streak_flow.gd game/scripts/screens/streak_screen.gd game/scripts/screens/streak_activate_screen.gd game/scripts/screens/streak_gift_screen.gd
grep -n "STREAK_GIFT" game/scripts/campaign/nav_controller.gd
rtk git checkout -b feat/v1.0.1/debug-streak-assist
```

Do not stage the pre-existing modified `.import` / `project.godot` / `.gitignore` files.

---

### Task 1: DayClock

**Files:**
- Create: `game/scripts/state/day_clock.gd`
- Test: `game/tests/test_day_clock.gd`

**Interfaces:**
- Produces: `DayClock` (`extends RefCounted`, no `class_name` — preload it): `var offset_days: int = 0`; `func today() -> String`; `func advance(days: int) -> void`; `func reset() -> void`; `func is_faked() -> bool`; `static func shift_date(date: String, days: int) -> String`.

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
rtk git commit -m "feat(debug): add session day clock" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Inject clock into AssistInventory, debug ops, callers

**Files:**
- Create: `game/scripts/state/assist_debug_ops.gd`
- Modify: `game/scripts/state/assist_inventory.gd`
- Modify: `game/scripts/screens/app_shell.gd` (const block, var block, `_ready`: +3 lines)
- Test: `game/tests/test_day_clock.gd` (extend), `game/tests/test_assist_inventory.gd` (extend)

**Interfaces:**
- Consumes: `DayClock` from Task 1; `AssistRules.new_data()`, `sanitize()`, `streak_view()`, `CYCLE_DAYS`, `KINDS`, `START`, `CAP`.
- Produces:
  - `AssistInventory.clock: Variant = null` (a DayClock; null → real date)
  - `AssistInventory.debug_counts_custom: bool = false` (never written to save)
  - `AssistInventory.current_day() -> String` (named so it does not clash with the `today` parameters)
  - `AssistInventory.replace_data(next: Dictionary) -> void` (sanitizes, commits, emits `changed` for hint and place)
  - `AssistDebugOps.set_cycle(data: Dictionary, pos: int, today: String) -> Dictionary`
  - `AssistDebugOps.reset_streak(data: Dictionary) -> Dictionary`
  - `AssistDebugOps.reset_stock(data: Dictionary) -> Dictionary`
  - `AssistDebugOps.nudge(data: Dictionary, kind: String, delta: int) -> Dictionary`
  - `AppShell.day_clock` (the one `DayClock` of the session), injected into `assists.clock`.

- [ ] **Step 1: Write failing tests** — append to `_init()` of `test_day_clock.gd` before `_finish`:

```gdscript
	var Inv = load("res://scripts/state/assist_inventory.gd")
	var Ops = load("res://scripts/state/assist_debug_ops.gd")
	var dir := OS.get_user_data_dir().path_join("day_clock_%s" % Time.get_ticks_usec())
	var inv = Inv.new(dir)
	var c2 := DayClock.new()
	inv.clock = c2
	var first: Dictionary = inv.on_round_finished()
	check(first.extended and inv.data.lastStreakDate == c2.today(), "inventory uses injected clock")
	c2.advance(1)
	check(inv.streak_view().at_risk and not inv.streak_view().kept_today, "+1 day puts streak at risk")
	var second: Dictionary = inv.on_round_finished()
	check(second.extended and int(inv.data.totalStreak) == 2 and second.view.count == 2, "next fake day extends streak")
	_check_callers(inv)
	c2.advance(2)
	check(inv.streak_view().count == 0, "skipped day drops view to 0")
	inv.replace_data(Ops.set_cycle(inv.data, 6, inv.current_day()))
	check(int(inv.data.streakDays) == 6 and inv.data.lastStreakDate == DayClock.shift_date(inv.current_day(), -1), "cycle 6, yesterday")
	var before_hint: int = inv.count("hint")
	var week: Dictionary = inv.on_round_finished()
	check(week.extended and week.reward.has("hint") and inv.count("hint") >= before_hint, "day 7 pays reward after set_cycle")
	inv.replace_data(Ops.set_cycle(inv.data, 99, inv.current_day()))
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

and add this function to `test_day_clock.gd` (the state at call time: streak 2, kept on fake day +1; on the real day `lastStreakDate` is in the future, so a caller that ignored the clock would show 0):

```gdscript
func _check_callers(inv) -> void:
	var screen: Control = (load("res://scenes/streak.tscn") as PackedScene).instantiate()
	root.add_child(screen)
	screen.setup(inv)
	check(screen.count_label.text == "2" and screen.flame.lit, "streak screen follows the clock")
	var chip: Button = load("res://scripts/screens/streak_chip.gd").new()
	root.add_child(chip)
	chip.bind(inv)
	check(chip.count_label.text == "2" and chip.flame.lit, "home chip follows the clock")
	screen.free(); chip.free()
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
	check(r_inv.current_day() == Time.get_date_string_from_system(), "no clock -> real date")
	r_inv._store.remove_all()
```

- [ ] **Step 2: Run both, expect FAIL**

Run: `rtk godot --headless --path game --script res://tests/test_day_clock.gd` and `rtk godot --headless --path game --script res://tests/test_assist_inventory.gd`

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

In Plan A's `on_round_finished`, replace

```gdscript
	var day := today if today != "" else AssistRules.today()
```

with

```gdscript
	var day := today if today != "" else current_day()
```

and replace `streak_view` with

```gdscript
func streak_view(today: String = "") -> Dictionary:
	return AssistRules.streak_view(data, today if today != "" else current_day())
```

Then add:

```gdscript
func current_day() -> String:
	return clock.today() if clock != null else AssistRules.today()

func replace_data(next: Dictionary) -> void:
	_commit(AssistRules.sanitize(next), AssistRules.KINDS)
```

Run: `rtk grep -n "AssistRules.today()" game/scripts/state/assist_inventory.gd`
Expected: only the line inside `current_day()`.

- [ ] **Step 5: Modify `app_shell.gd` (one statement per line)**

1. After the line that preloads `AssistInventory` (line 9) add:

```gdscript
const DayClock = preload("res://scripts/state/day_clock.gd")
```

2. After `var streak_flow := StreakFlow.new()` (Plan A) add:

```gdscript
var day_clock := DayClock.new()
```

3. In `_ready`, directly after the line `if assists == null: assists = AssistInventory.new(profile_dir); assists.save_failed.connect(_on_save_failed)` add:

```gdscript
	if assists.clock == null: assists.clock = day_clock
```

(Tests that pre-seed `shell.assists` also get the shell clock; its offset is 0, so they see the real date.)

Run: `wc -l game/scripts/screens/app_shell.gd`
Expected: `294`.

- [ ] **Step 6: Run** — expect `DAY_CLOCK_PASS` and `ASSIST_INVENTORY_PASS`; also run `test_assist_rules.gd`, `test_assist_flow.gd`, `test_streak_ui.gd`, `test_streak_screen.gd`, `test_streak_activation.gd`, `test_integration.gd` (all PASS).

- [ ] **Step 7: Commit**

```bash
rtk git add game/scripts/state/assist_debug_ops.gd game/scripts/state/assist_inventory.gd game/scripts/screens/app_shell.gd game/tests/test_day_clock.gd game/tests/test_assist_inventory.gd
rtk git commit -m "feat(debug): inject day clock into assist inventory and add debug ops" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: "Debug levels count toward streak" at the is_custom check

**Files:**
- Modify: `game/scripts/screens/puzzle_assist_controller.gd` (`bind`, `on_round_finished`)
- Modify: `game/scripts/screens/puzzle_screen.gd:80` (edit in place, no new statement)
- Test: `game/tests/test_debug_streak_panel.gd` (create; toggle section)

**Interfaces:**
- Consumes: `AssistInventory.debug_counts_custom`; Plan A's `PuzzleAssistController.on_round_finished(session, is_custom)` / `round_result`.
- Produces: `PuzzleAssistController.streak_source: Variant = null` — the inventory used only for streak recording, set even when `inventory` is null for custom levels; `PuzzleAssistController.bind(inv: Variant, coordinator: Variant, streak_inv: Variant = null)`.

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
	var ctl := Ctl.new()          # RefCounted, not a Node
	ctl.bind(null, null, inv)     # puzzle_screen binds no stock for custom levels, but passes the streak source
	var fake_session := RefCounted.new()
	var off: Dictionary = ctl.on_round_finished(fake_session, true)
	check(off.is_empty() and ctl.round_result.is_empty() and int(inv.data.totalStreak) == 0, "custom level ignored by default")
	inv.debug_counts_custom = true
	var on: Dictionary = ctl.on_round_finished(fake_session, true)
	check(on.extended and ctl.round_result == on and int(inv.data.totalStreak) == 1, "custom level counts when toggled")
	inv.debug_counts_custom = false
	await _panel_tests(inv, dir)
	inv._store.remove_all()
	if failures.is_empty():
		print("DEBUG_STREAK_PANEL_PASS"); quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func _panel_tests(_inv, _dir: String) -> void:
	await process_frame  # filled in Task 4
```

(`on_round_finished` only null-checks `session`, so a bare `RefCounted` is enough.)

- [ ] **Step 2: Run, expect FAIL** (`bind` takes 2 arguments / `streak_source` missing)

Run: `rtk godot --headless --path game --script res://tests/test_debug_streak_panel.gd`

- [ ] **Step 3: Implement** in `puzzle_assist_controller.gd`: below `var round_result: Dictionary = {}` add

```gdscript
var streak_source: Variant = null  # inventory that records the streak; set even for custom levels
```

change the first two lines of `bind` to

```gdscript
func bind(inv: Variant, coordinator: Variant, streak_inv: Variant = null) -> void:
	inventory = inv
	streak_source = streak_inv if streak_inv != null else inv
```

(the rest of `bind` is unchanged) and replace `on_round_finished` with

```gdscript
# Records the finished round; returns {extended, view, reward} for the streak screens, {} when skipped.
# Custom/debug levels are skipped unless the session-only debug switch is on.
func on_round_finished(session: Variant, is_custom: bool) -> Dictionary:
	round_result = {}
	var inv: Variant = streak_source if streak_source != null else inventory
	if inv == null or session == null or (is_custom and not inv.debug_counts_custom):
		return round_result
	round_result = inv.on_round_finished()
	return round_result
```

In `puzzle_screen.gd` line 80, edit the existing `assist_ctl.bind(...)` call in place (add the third argument only):

```gdscript
	if board != null: combo.bind(board, sfx); assist_ctl.bind(null if _is_custom else assists, hint_coordinator, assists)
```

Run: `wc -l game/scripts/screens/puzzle_screen.gd` → `300`.

- [ ] **Step 4: Run, expect `DEBUG_STREAK_PANEL_PASS`**; rerun `test_assist_flow.gd`, `test_assist_ui.gd`, `test_streak_activation.gd`, `test_integration.gd`.

- [ ] **Step 5: Commit**

```bash
rtk git add game/scripts/screens/puzzle_assist_controller.gd game/scripts/screens/puzzle_screen.gd game/tests/test_debug_streak_panel.gd
rtk git commit -m "feat(debug): let debug levels count toward streak when toggled" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Preview overlay + Streak/Assist panel

**Files:**
- Create: `game/scripts/screens/debug_streak_preview.gd`
- Create: `game/scripts/screens/debug_streak_panel.gd`
- Test: `game/tests/test_debug_streak_panel.gd` (replace `_panel_tests`)

**Interfaces:**
- Consumes: `DayClock`, `AssistDebugOps`, `AssistInventory.{clock, current_day(), replace_data(), streak_view(), count(), data, debug_counts_custom}`; `ScreenRouter.instantiate(name)`; `NavController.SCREEN_NAMES` (`res://scripts/campaign/nav_controller.gd`); `streak_screen.show_view(view)` + `back_pressed`; activate `setup(view)` / gift `setup(reward)` + `continued`.
- Produces:
  - `DebugStreakPreview.FAKE_VIEW: Dictionary`, `FAKE_REWARD: Dictionary`, `static func open(host: Control, screen: int) -> Control` (returns the overlay named `DebugStreakPreview`, which frees itself on `continued` / `back_pressed` or right click)
  - `DebugStreakPanel extends VBoxContainer`: `signal changed()`; `func setup(assists: Variant) -> void`; `func date_text() -> String`; child nodes (looked up with `find_child(name, true, false)`) `DateLabel`, `StockLabel`, `PlusDay`, `SkipDay`, `RealDay`, `CycleSpin`, `CycleApply`, `ResetStreak`, `HintPlus`, `HintMinus`, `PlacePlus`, `PlaceMinus`, `ResetStock`, `PreviewStreak`, `PreviewActivate`, `PreviewGift`, `CountToggle`.

- [ ] **Step 1: Write failing tests** — replace `_panel_tests` in `test_debug_streak_panel.gd`:

```gdscript
const SLOT_FILES := ["assists.a.json", "assists.b.json", "assists.flag"]

func _n(p: Node, node_name: String) -> Node:
	return p.find_child(node_name, true, false)

func _panel_tests(inv, dir: String) -> void:
	var Panel = load("res://scripts/screens/debug_streak_panel.gd")
	var p = Panel.new(); root.add_child(p); p.setup(inv)
	var real := Time.get_date_string_from_system()
	check(_n(p, "DateLabel").text.contains(real), "shows real date")
	_n(p, "PlusDay").pressed.emit()
	check(inv.clock.offset_days == 1 and _n(p, "DateLabel").text.contains(inv.current_day()), "+1 day shown")
	_n(p, "SkipDay").pressed.emit()
	check(inv.clock.offset_days == 3, "skip = +2")
	_n(p, "RealDay").pressed.emit()
	check(inv.clock.offset_days == 0 and inv.current_day() == real, "back to real")
	_n(p, "CycleSpin").value = 4
	_n(p, "CycleApply").pressed.emit()
	check(int(inv.data.streakDays) == 4, "cycle set")
	_n(p, "ResetStreak").pressed.emit()
	check(int(inv.data.totalStreak) == 0, "streak reset")
	var h: int = inv.count("hint")
	_n(p, "HintPlus").pressed.emit()
	check(inv.count("hint") == mini(h + 1, 10), "hint +1")
	_n(p, "PlaceMinus").pressed.emit()
	_n(p, "ResetStock").pressed.emit()
	check(inv.count("hint") == 3 and inv.count("place") == 1, "stock reset")
	check(not _n(p, "CountToggle").button_pressed, "toggle default off")
	_n(p, "CountToggle").button_pressed = true
	check(inv.debug_counts_custom, "toggle writes session flag")
	# previews never write save: slot files byte-identical before/after
	var snapshot := JSON.stringify(inv.data)
	var before := {}
	for f in SLOT_FILES: before[f] = FileAccess.get_file_as_string(dir.path_join(f))
	for btn in ["PreviewStreak", "PreviewActivate", "PreviewGift"]:
		_n(p, btn).pressed.emit()
		var overlay: Node = root.get_node_or_null("DebugStreakPreview")
		check(overlay != null, btn + " opens overlay")
		if overlay != null:
			check(overlay.get("assists") == null, btn + " has no inventory")
			overlay.queue_free()
		await process_frame
	check(JSON.stringify(inv.data) == snapshot, "preview leaves data untouched")
	for f in SLOT_FILES:
		check(FileAccess.get_file_as_string(dir.path_join(f)) == before[f], "file unchanged: " + f)
	p.queue_free()
	await process_frame
```

- [ ] **Step 2: Run, expect FAIL** (`debug_streak_panel.gd` missing)

Run: `rtk godot --headless --path game --script res://tests/test_debug_streak_panel.gd`

- [ ] **Step 3: Implement preview**

```gdscript
# game/scripts/screens/debug_streak_preview.gd
# Debug-only overlay showing streak screens with fake data; never touches the inventory.
extends RefCounted

const NavController = preload("res://scripts/campaign/nav_controller.gd")
const ScreenRouter = preload("res://scripts/campaign/screen_router.gd")
const FAKE_VIEW := {"count": 12, "best": 20, "kept_today": false, "at_risk": true, "cycle_done": 5}
const FAKE_REWARD := {"hint": 2, "place": 1}

static func open(host: Control, screen: int) -> Control:
	if not screen in [NavController.Screen.STREAK, NavController.Screen.STREAK_ACTIVATE, NavController.Screen.STREAK_GIFT]:
		return null
	var node := ScreenRouter.instantiate(NavController.SCREEN_NAMES[screen])
	if node == null:
		return null
	node.name = "DebugStreakPreview"
	match screen:
		NavController.Screen.STREAK:
			node.call("show_view", FAKE_VIEW)  # never setup(): that would read the real inventory
			node.connect("back_pressed", node.queue_free)
		NavController.Screen.STREAK_ACTIVATE:
			node.call("setup", FAKE_VIEW)
			node.connect("continued", node.queue_free)
		NavController.Screen.STREAK_GIFT:
			node.call("setup", FAKE_REWARD)
			node.connect("continued", node.queue_free)
	node.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
			node.queue_free())
	host.get_tree().root.add_child(node)
	return node
```

Never set `assists` on the preview node.

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
const NavController = preload("res://scripts/campaign/nav_controller.gd")

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
	if _inv != null and _inv.clock == null:
		_inv.clock = DayClock.new()
	_toggle.set_pressed_no_signal(_inv != null and _inv.debug_counts_custom)
	_refresh()

func date_text() -> String:
	if _inv == null:
		return "Ngày: —"
	var tag := " (giả, %+d)" % _inv.clock.offset_days if _inv.clock.is_faked() else " (thật)"
	return "Ngày: " + _inv.current_day() + tag

func _build_ui() -> void:
	_date_lbl = _label("DateLabel")
	var day := _row()
	_btn(day, "PlusDay", "+1 ngày", func(): _shift(1))
	_btn(day, "SkipDay", "Bỏ lỡ 1 ngày (+2)", func(): _shift(2))
	_btn(day, "RealDay", "Về ngày thật", _real_day)
	var cyc := _row()
	_cycle_spin = SpinBox.new()
	_cycle_spin.name = "CycleSpin"
	_cycle_spin.min_value = 0
	_cycle_spin.max_value = 6
	cyc.add_child(_cycle_spin)
	_btn(cyc, "CycleApply", "Đặt vị trí chu kỳ", func(): _edit(func(d): return Ops.set_cycle(d, int(_cycle_spin.value), _inv.current_day())))
	_btn(cyc, "ResetStreak", "Reset chuỗi", func(): _edit(func(d): return Ops.reset_streak(d)))
	_stock_lbl = _label("StockLabel")
	var stock := _row()
	_btn(stock, "HintPlus", "+ hint", func(): _edit(func(d): return Ops.nudge(d, "hint", 1)))
	_btn(stock, "HintMinus", "− hint", func(): _edit(func(d): return Ops.nudge(d, "hint", -1)))
	_btn(stock, "PlacePlus", "+ place", func(): _edit(func(d): return Ops.nudge(d, "place", 1)))
	_btn(stock, "PlaceMinus", "− place", func(): _edit(func(d): return Ops.nudge(d, "place", -1)))
	_btn(stock, "ResetStock", "Reset kho", func(): _edit(func(d): return Ops.reset_stock(d)))
	var prev := _row()
	_btn(prev, "PreviewStreak", "Xem màn Chuỗi", func(): Preview.open(self, NavController.Screen.STREAK))
	_btn(prev, "PreviewActivate", "Xem Kích hoạt", func(): Preview.open(self, NavController.Screen.STREAK_ACTIVATE))
	_btn(prev, "PreviewGift", "Xem Nhận quà", func(): Preview.open(self, NavController.Screen.STREAK_GIFT))
	_toggle = CheckButton.new()
	_toggle.name = "CountToggle"
	_toggle.text = "Level debug tính chuỗi (chỉ phiên này)"
	_toggle.add_theme_font_size_override("font_size", 24)
	_toggle.toggled.connect(_on_toggle)
	add_child(_toggle)

func _shift(days: int) -> void:
	if _inv == null:
		return
	_inv.clock.advance(days)
	_refresh()

func _real_day() -> void:
	if _inv == null:
		return
	_inv.clock.reset()
	_refresh()

func _edit(op: Callable) -> void:
	if _inv == null:
		return
	_inv.replace_data(op.call(_inv.data))
	_refresh()

func _on_toggle(on: bool) -> void:
	if _inv != null:
		_inv.debug_counts_custom = on

func _refresh() -> void:
	_date_lbl.text = date_text()
	if _inv != null:
		var v: Dictionary = _inv.streak_view()
		_stock_lbl.text = "Chuỗi %d (kỷ lục %d), chu kỳ %d/7 — hint %d, place %d" % [v.count, v.best, v.cycle_done, _inv.count("hint"), _inv.count("place")]
	changed.emit()

func _label(n: String) -> Label:
	var l := Label.new()
	l.name = n
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", Palette.INK)
	add_child(l)
	return l

func _row() -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 8)
	add_child(r)
	return r

func _btn(parent: Container, n: String, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.name = n
	b.text = text
	b.custom_minimum_size.y = 56
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b
```

The `—`/`−` glyphs: if Plan D1 reports them as missing from the game font (S12), use `-` instead.

- [ ] **Step 5: Run, expect `DEBUG_STREAK_PANEL_PASS`**

- [ ] **Step 6: Commit**

```bash
rtk git add game/scripts/screens/debug_streak_preview.gd game/scripts/screens/debug_streak_panel.gd game/tests/test_debug_streak_panel.gd
rtk git commit -m "feat(debug): add streak/assist debug panel and fake-data previews" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Wire the tab into the debug picker

**Files:**
- Modify: `game/scripts/screens/debug_level_picker.gd` (member vars, `setup`, `_build_ui` tab row and panel, `_switch_mode`)
- Modify: `game/scripts/screens/title_screen.gd` (debug picker block in `_build`/`_ready` where `debug_picker.progress_reset.connect` is, and the `debug_picker.setup(...)` call)
- Test: `game/tests/test_debug_level_picker.gd` (extend)

**Interfaces:**
- Consumes: `DebugStreakPanel.setup(assists)`, `signal changed`; `streak_chip.refresh()` (idempotent: re-reads `inventory.streak_view()`).
- Produces: `DebugLevelPicker.setup(bank: BankReader, playlist: Array = [], endless_rt: Variant = null, campaign_rt: Variant = null, assists: Variant = null)`; mode `3` = Streak/Assist; `_streak_panel` (a `DebugStreakPanel`), `_tab_streak_btn: Button`.

- [ ] **Step 1: Write failing test** — append to `_run_tests` in `test_debug_level_picker.gd` before the result print (`picker` and `bank` are the suite's existing locals):

```gdscript
	var sdir := OS.get_user_data_dir().path_join("picker_streak_%s" % Time.get_ticks_usec())
	var s_inv = load("res://scripts/state/assist_inventory.gd").new(sdir)
	picker.setup(bank, [], null, null, s_inv)
	picker._switch_mode(3)
	_assert(picker._streak_panel != null and picker._streak_panel.visible, "streak tab visible in mode 3")
	_assert(not picker._playlist_container.visible and not picker._bank_container.visible and not picker._endless_panel.visible, "other tabs hidden")
	_assert(not picker._play_btn.visible, "play button hidden on streak tab")
	_assert(picker._streak_panel.find_child("DateLabel", true, false).text.contains(s_inv.current_day()), "panel bound to inventory")
	picker._switch_mode(0)
	_assert(not picker._streak_panel.visible and picker._play_btn.visible, "back to playlist")
	s_inv._store.remove_all()
```

- [ ] **Step 2: Run, expect FAIL**

Run: `rtk godot --headless --path game --script res://tests/test_debug_level_picker.gd`

- [ ] **Step 3: Implement** (one statement per line in new code)

`debug_level_picker.gd`:
- After `const DebugResetBar = preload(...)` add `const DebugStreakPanel = preload("res://scripts/screens/debug_streak_panel.gd")`.
- After the `var _play_btn: Button; var _close_btn: Button` line add two lines:

```gdscript
var _streak_panel: DebugStreakPanel
var _tab_streak_btn: Button
```

- `setup`: change the signature to `func setup(bank: BankReader, playlist: Array = [], endless_rt: Variant = null, campaign_rt: Variant = null, assists: Variant = null) -> void:` and add after the `_reset_bar` line:

```gdscript
	if _streak_panel != null: _streak_panel.setup(assists)
```

- `_build_ui`: after the existing tab-button line (`_tab_playlist_btn = ...; _tab_endless_btn = _tab_btn("Vô tận (Endless)", 2, tabs)`) add:

```gdscript
	_tab_streak_btn = _tab_btn("Streak/Assist", 3, tabs)
```

and after the `); root_vbox.add_child(_endless_panel)` line add:

```gdscript
	_streak_panel = DebugStreakPanel.new()
	_streak_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_streak_panel.visible = false
	root_vbox.add_child(_streak_panel)
```

- `_switch_mode`: after its first line add:

```gdscript
	_streak_panel.visible = (_mode == 3)
	_play_btn.visible = (_mode != 3)
```

Run: `wc -l game/scripts/screens/debug_level_picker.gd` → ≤ 300 (256 + 10 = 266 if D2 did not change it).

`title_screen.gd`:
- After `debug_picker.progress_reset.connect(func(_m): _update_ui())` add this line (refreshes the Home chip when the panel edits data or the fake day):

```gdscript
		debug_picker._streak_panel.changed.connect(func(): if streak_chip != null: streak_chip.refresh())
```

- Change `debug_picker.setup(b, pl, endless_rt, rt)` to `debug_picker.setup(b, pl, endless_rt, rt, assists)`.

Run: `wc -l game/scripts/screens/title_screen.gd` → 292 (291 after Plan B, +1).

- [ ] **Step 4: Run** `test_debug_level_picker.gd`, `test_debug_features.gd`, `test_screens.gd`, `test_debug_streak_panel.gd`, `test_streak_ui.gd` — all PASS.

- [ ] **Step 5: Commit**

```bash
rtk git add game/scripts/screens/debug_level_picker.gd game/scripts/screens/title_screen.gd game/tests/test_debug_level_picker.gd
rtk git commit -m "feat(debug): add Streak/Assist tab to debug picker" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Gate, STATUS, merge

- [ ] **Step 1: Line budget** — `wc -l` every modified/created script; all ≤ 300 (`app_shell.gd` 294, `puzzle_screen.gd` 300).

- [ ] **Step 2: Gate**

```bash
rtk python -B tools/clean_room.py
rtk python -B tools/verify.py --godot <godot-executable>
```

Expected: all PASS except the verifier's known negative self-tests. Log saved under `scratch/verification/`; note its filename and the revision (`rtk git rev-parse --short HEAD`).

- [ ] **Step 3: STATUS** — in `docs/STATUS.md` add an entry for Plan C: what landed (DayClock injected from app_shell, Streak/Assist debug tab, previews with fake data, session-only toggle), verification revision + log path + result, limit: "headless only; no device QA of the debug tab". Only record what the log shows.

```bash
rtk git add docs/STATUS.md
rtk git commit -m "docs(status): record debug streak/assist plan C" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 4: Merge back** (only with merge permission for this branch)

```bash
rtk git checkout feat/v1.0.1/assist-inventory
rtk git merge --no-ff feat/v1.0.1/debug-streak-assist -m "merge: debug streak/assist (plan C)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
rtk godot --headless --path game --script res://tests/test_debug_streak_panel.gd
```

If `checkout` is refused because of uncommitted unrelated files, stop and report — do not stash, reset or commit them. Do not push unless asked.

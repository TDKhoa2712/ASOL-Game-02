# Plan B — Streak Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Home streak popup (`streak_sheet`) with a full Streak screen (title, back, flame + count, 7-day cycle strip with a gift box slot, "Kỷ lục" line), reachable from the Home flame chip.

**Architecture:** Two reusable view components (`StreakCycleStrip`, `GiftBoxView`) built in code like the existing `streak_sheet`, composed by a new `streak_screen.gd` loaded through `scenes/streak.tscn`. Task 0 first extracts scene lookup/instantiation out of `app_shell.gd` (exactly 300 lines today) into `game/scripts/campaign/screen_router.gd` (pure refactor), so every later screen is registered in `ScreenRouter.SCENE_MAP` instead of compressing `app_shell` lines. `NavController` gains `Screen.STREAK`; `app_shell` wires `title_screen.streak_pressed` / `streak_screen.back_pressed` with signals (no autoload). Data comes only from `AssistRules.streak_view`, which already zeroes the count when the streak is broken (gap ≥ 2) — this plan pins that with tests.

**Tech Stack:** Godot 4 / GDScript, headless SceneTree test scripts, CSV translations (`game/locale/strings.csv`), Python gate tools.

**Spec:** `docs/superpowers/specs/2026-10-15-streak-screens-debug-design.md` (§3.1, §3.2, Q5, Q6, Q7, Q11)

## Global Constraints

- Branch `feat/v1.0.1/streak-screen` created FROM `feat/v1.0.1/assist-inventory` (Task 0); merged back with `git merge --no-ff` into `feat/v1.0.1/assist-inventory` only (Q10). Never into `release/*`, `dev` or `main`. Do not push.
- No autoloads; Godot signals; dependencies injected from `app_shell` (AGENTS.md §4).
- Every `.gd` module ≤ 300 lines. `app_shell.gd` is at exactly 300 and `title_screen.gd` at 289 today — check `wc -l` after each edit. Never join statements/declarations onto shared lines to save space: new scenes go into `ScreenRouter.SCENE_MAP` (Task 0); if a file would pass 300, extract a helper instead.
- Scene keys (fixed across Plans A/B/C): `"streak"` (this plan), `"streak_activate"`, `"streak_gift"` (Plan A). They equal `NavController.SCREEN_NAMES` values.
- Clean-room: original code, names and assets only; the gift placeholder is an original SVG under `game/assets/ui/streak/`.
- Fixed interface names (other plans depend on them, do not rename):
  - `screens/streak_cycle_strip.gd` `class_name StreakCycleStrip`, `func show_view(view: Dictionary) -> void`, `func fill_today_animated() -> void`.
  - `screens/gift_box_view.gd` `class_name GiftBoxView`, `func play_idle() -> void`, `func play_open() -> void`, `signal opened`. Single swap point for the owner's future animation.
  - `NavController.Screen.STREAK` (enum order `TITLE, PUZZLE, WIN, FAIL, STREAK`; Plan A appends `STREAK_ACTIVATE, STREAK_GIFT`), scene `scenes/streak.tscn`, script `screens/streak_screen.gd` with `setup(inv: Variant, today: String = "")` and `show_view(view: Dictionary)`.
  - `campaign/screen_router.gd` (preloaded as `ScreenRouter`): `const SCENE_MAP`, `static func scene_path(screen_name: String) -> String`, `static func instantiate(screen_name: String) -> Control`, `static func clear(host: Node) -> void`.
  - `today` convention: production callers pass no date (`""`); `AssistInventory` resolves the day itself (today `AssistRules.today()`, after Plan C its injected `DayClock`). Explicit dates are only for tests.
- Q5: the "frame" is the 7 day cells of the cycle (done / today / remaining).
- Q6: Streak screen = title on top, back button, 7-cell strip, gift box at the end of the strip. No "Còn … ngày" / "Hôm nay đã …" lines; remove `streak.left`, `streak.kept` and the similar status keys.
- Q7: the gift box is a replaceable placeholder (one scene/slot).
- Q11: when the streak is lost (missed ≥ 1 day, i.e. gap ≥ 2) the shown count is 0 immediately (chip and screen); the "Kỷ lục: N" line is always shown with the best value ever reached.
- TDD: write the failing test, run it, implement, run it, commit. Test command: `godot --headless --path game --script res://tests/test_<x>.gd` (prefix with `rtk`).
- After changing `strings.csv`, reimport translations: `godot --headless --path game --import` and commit the regenerated `game/locale/strings.*.translation`.
- Commit messages: Conventional Commits, ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Stage only files listed in the task; the working tree already has unrelated modified `.import` files, `.gitignore`, `project.godot` — never stage them.

## Review Focus

1. Streak broken by a long gap (e.g. 30 days since `lastStreakDate`) — chip and screen show 0, best line still shows the old best (test in Task 1).
2. Fresh profile (no `lastStreakDate`) opening the Streak screen — count 0, all 7 cells "todo", "today" marker on cell 0, best 0, no crash (test in Task 3).
3. Day 7 of the cycle (`cycle_done == 7`, kept today) — all 7 cells done including the gift cell; no out-of-range "today" index (test in Task 2).
4. `app_shell` with `assists == null` reaching STREAK — screen must render zeros, not crash (test in Task 3: `setup(null)`).
5. Back from the Streak screen goes to Home and the chip is still bound/visible (test in Task 4).
6. Router refactor is behaviour-neutral: options overlay, `_rebuild_current_screen`, result SFX and every existing screen test pass unchanged (Task 0).

---

### Task 0: Branch and extract screen routing from `app_shell`

`app_shell.gd` is at exactly 300 lines. Scene lookup, loading, full-rect anchoring and host clearing move to `game/scripts/campaign/screen_router.gd` (static, stateless). The per-screen signal/`setup` wiring stays in `app_shell._instantiate_screen` (it needs the shell's runtimes, callbacks and `_last_won_*` state). Pure refactor: no behaviour change.

**Files:**
- Create: `game/scripts/campaign/screen_router.gd`
- Modify: `game/scripts/screens/app_shell.gd` (`SCENE_MAP` block lines 22-29, `_swap_screen` lines 86-88, `_instantiate_screen` lines 95-101, `_show_options_overlay` lines 234-240, const block line 12)
- Test: `game/tests/test_screen_router.gd`

**Interfaces:**
- Produces: `ScreenRouter` (`extends RefCounted`, no `class_name`; preload it):
  - `const SCENE_MAP := {"title", "puzzle", "win", "fail", "options"}` → `res://scenes/<name>.tscn` (same values as today's `AppShell.SCENE_MAP`). Plans B/A add `"streak"`, `"streak_activate"`, `"streak_gift"` here.
  - `static func scene_path(screen_name: String) -> String` (`""` if unknown).
  - `static func instantiate(screen_name: String) -> Control` — `null` if unknown, missing or not a `Control`; otherwise the instance with `PRESET_FULL_RECT` anchors. Not added to any parent.
  - `static func clear(host: Node) -> void` — frees and detaches every child; no-op on `null`.
- `AppShell.SCENE_MAP` is removed (no caller outside `app_shell.gd`: `rtk grep -rn "SCENE_MAP" game` shows only app_shell before this task).

- [ ] **Step 1: Branch**

```bash
rtk git checkout feat/v1.0.1/assist-inventory
rtk git status --short          # unrelated .import / .gitignore / project.godot edits stay unstaged
rtk git checkout -b feat/v1.0.1/streak-screen
```

- [ ] **Step 2: Write the failing test** `game/tests/test_screen_router.gd`

```gdscript
extends SceneTree

const ScreenRouter = preload("res://scripts/campaign/screen_router.gd")
const AppShell = preload("res://scripts/screens/app_shell.gd")
var failures: Array[String] = []

func _init() -> void:
	for key in ["title", "puzzle", "win", "fail", "options"]:
		check(ScreenRouter.scene_path(key) == "res://scenes/%s.tscn" % key, "path for " + key)
	check(ScreenRouter.scene_path("nope") == "", "unknown key has no path")
	check(ScreenRouter.instantiate("nope") == null, "unknown key builds nothing")

	var fail_screen := ScreenRouter.instantiate("fail")
	check(fail_screen != null and fail_screen.get_parent() == null, "fail scene built, not parented")
	if fail_screen != null:
		check(fail_screen.anchor_right == 1.0 and fail_screen.anchor_bottom == 1.0, "full-rect anchors")
		fail_screen.free()

	var host := Control.new()
	root.add_child(host)
	host.add_child(Control.new()); host.add_child(Control.new())
	ScreenRouter.clear(host)
	check(host.get_child_count() == 0, "clear detaches all children")
	ScreenRouter.clear(null)
	host.queue_free()

	check(not AppShell.get_script_constant_map().has("SCENE_MAP"), "scene map lives only in the router")

	if failures.is_empty():
		print("SCREEN_ROUTER_PASS"); quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)
```

- [ ] **Step 3: Run to verify it fails**

Run: `rtk godot --headless --path game --script res://tests/test_screen_router.gd`
Expected: FAIL — `screen_router.gd` not found.

- [ ] **Step 4: Implement** `game/scripts/campaign/screen_router.gd`

```gdscript
# Screen name -> scene lookup and instantiation; per-screen wiring stays in app_shell.
extends RefCounted

const SCENE_MAP := {
	"title": "res://scenes/title.tscn",
	"puzzle": "res://scenes/puzzle.tscn",
	"win": "res://scenes/win.tscn",
	"fail": "res://scenes/fail.tscn",
	"options": "res://scenes/options.tscn",
}

static func scene_path(screen_name: String) -> String:
	return SCENE_MAP.get(screen_name, "")

static func instantiate(screen_name: String) -> Control:
	var path := scene_path(screen_name)
	if path == "" or not ResourceLoader.exists(path):
		return null
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var screen := packed.instantiate() as Control
	if screen != null:
		screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return screen

static func clear(host: Node) -> void:
	if host == null:
		return
	for child in host.get_children():
		child.queue_free()
		host.remove_child(child)
```

- [ ] **Step 5: Use the router in `app_shell.gd`**

1. After `const NavController = preload("res://scripts/campaign/nav_controller.gd")` add its own line:

```gdscript
const ScreenRouter = preload("res://scripts/campaign/screen_router.gd")
```

2. Delete the whole `const SCENE_MAP := { ... }` block and the blank line after it.

3. In `_swap_screen`, replace

```gdscript
	if screen_host != null:
		for child in screen_host.get_children():
			child.queue_free(); screen_host.remove_child(child)
```

with

```gdscript
	ScreenRouter.clear(screen_host)
```

4. In `_instantiate_screen`, replace the first seven lines (from `var scene_path: String = SCENE_MAP.get(to_name, "")` through `screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)`) with

```gdscript
	var screen := ScreenRouter.instantiate(to_name)
	if screen == null: return
```

5. In `_show_options_overlay`, replace the seven lines from `var p: String = SCENE_MAP.get("options", "")` through `_options_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)` with

```gdscript
	_options_overlay = ScreenRouter.instantiate("options")
	if _options_overlay == null: return
```

Run: `wc -l game/scripts/screens/app_shell.gd`
Expected: `281` (19 lines of headroom for Plans B, A, C).

- [ ] **Step 6: Run to verify it passes and nothing regressed**

Run each; expected PASS marker / exit 0:
- `rtk godot --headless --path game --script res://tests/test_screen_router.gd` → `SCREEN_ROUTER_PASS`
- `rtk godot --headless --path game --script res://tests/test_integration.gd` → `INTEGRATION_PASS`
- `rtk godot --headless --path game --script res://tests/test_settings_apply.gd`
- `rtk godot --headless --path game --script res://tests/test_screens.gd`
- `rtk godot --headless --path game --script res://tests/test_streak_ui.gd`

- [ ] **Step 7: Commit**

```bash
rtk git add game/scripts/campaign/screen_router.gd game/scripts/screens/app_shell.gd game/tests/test_screen_router.gd
# plus game/scripts/campaign/screen_router.gd.uid / game/tests/test_screen_router.gd.uid if Godot generated them
rtk git commit -m "refactor(shell): extract screen routing into screen_router

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 1: Pin "broken streak shows 0" in `AssistRules.streak_view` and the chip

`streak_view` already sets `count = 0` unless the gap is 0 or 1. This task pins it (characterization tests). If any new check fails, fix `streak_view` so `alive := gap == 0 or gap == 1` and `count`/`cycle_done` are 0 otherwise.

**Files:**
- Modify: `game/tests/test_assist_rules.gd` (after the `"view broken streak"` check, ~line 96)
- Modify (only if a check fails): `game/scripts/state/assist_rules.gd:74-83`

**Interfaces:**
- Consumes: `AssistRules.streak_view(data: Dictionary, today_date: String) -> Dictionary` with keys `count, best, kept_today, at_risk, cycle_done`.
- Produces: same contract, now pinned: gap ≥ 2 → `count == 0`, `cycle_done == 0`, `at_risk == false`, `best` unchanged.

- [ ] **Step 1: Write the tests**

Insert after the line `check(v.count == 0 and not v.at_risk and v.cycle_done == 0 and v.best == 9, "view broken streak")`:

```gdscript
	v = Rules.streak_view(cur, "2026-05-11")  # gap 2 = missed exactly one day
	check(v.count == 0 and v.cycle_done == 0 and not v.kept_today and v.best == 9, "gap 2 zeroes count (Q11)")
	v = Rules.streak_view(cur, "2026-06-08")  # gap 30
	check(v.count == 0 and not v.at_risk and v.best == 9, "long gap zeroes count, keeps best")
	var broken := cur.duplicate(true)
	broken.lastStreakDate = "not-a-date"
	check(Rules.streak_view(broken, "2026-05-09").count == 0, "corrupt last date shows 0")
```

- [ ] **Step 2: Run**

Run: `rtk godot --headless --path game --script res://tests/test_assist_rules.gd`
Expected: PASS (current code already zeroes). If it FAILS, apply Step 3; otherwise skip to Step 4.

- [ ] **Step 3: Fix (only if Step 2 failed)**

Ensure `streak_view` in `game/scripts/state/assist_rules.gd` reads:

```gdscript
static func streak_view(data: Dictionary, today_date: String) -> Dictionary:
	var last: String = data.get("lastStreakDate", "")
	var gap := day_gap(last, today_date) if last != "" else INVALID_GAP
	var alive := gap == 0 or gap == 1
	var count := int(data.get("totalStreak", 0)) if alive else 0
	var cycle := int(data.get("streakDays", 0)) if alive else 0
	if gap == 0 and cycle == 0 and count > 0:
		cycle = CYCLE_DAYS  # today's win completed the pack
	return {"count": count, "best": int(data.get("bestStreak", 0)), "kept_today": gap == 0,
		"at_risk": count > 0 and gap != 0, "cycle_done": cycle}
```

Re-run Step 2's command; expected PASS.

- [ ] **Step 4: Chip test for the broken streak**

In `game/tests/test_streak_ui.gd` this is covered in Task 4 (the file is rewritten there). Nothing to do here.

- [ ] **Step 5: Commit**

```bash
rtk git add game/tests/test_assist_rules.gd
# add game/scripts/state/assist_rules.gd only if Step 3 changed it
rtk git commit -m "test(streak): pin zero count after a missed day

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: `GiftBoxView` and `StreakCycleStrip`

**Files:**
- Create: `game/assets/ui/streak/gift_box.svg` (original placeholder art)
- Create: `game/scripts/screens/gift_box_view.gd`
- Create: `game/scenes/components/gift_box_view.tscn`
- Create: `game/scripts/screens/streak_cycle_strip.gd`
- Test: `game/tests/test_streak_strip.gd`

**Interfaces:**
- Consumes: `FlameFx` (`res://scripts/screens/flame_fx.gd`, `new(side: float, embers: int)`, `set_lit(bool)`), `LayoutTokens.motion_enabled`.
- Produces:
  - `class_name GiftBoxView extends Control` — `signal opened`, `func play_idle() -> void`, `func play_open() -> void`, `var is_open: bool`, `const SCENE := "res://scenes/components/gift_box_view.tscn"`, `static func create() -> GiftBoxView` (instantiates the scene: the one swap point).
  - `class_name StreakCycleStrip extends HBoxContainer` — `const DAYS := 7`, `var cells: Array[PanelContainer]`, `var gift_box: GiftBoxView`, `func show_view(view: Dictionary) -> void`, `func cell_state(i: int) -> String` returning `"done" | "today" | "todo"`, `func today_index() -> int` (-1 if none), `func fill_today_animated() -> void` (turns the `"today"` cell into `"done"`, with a pop tween when motion is on; no-op if there is no today cell).
  - Cell rules from `view` (`cycle_done = d`, `kept_today = k`): `i < d` → `"done"`; `not k and i == d and d < 7` → `"today"`; else `"todo"`. Cell 6 also hosts `gift_box`.

- [ ] **Step 1: Write the failing test** `game/tests/test_streak_strip.gd`

```gdscript
extends SceneTree

const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const Strip = preload("res://scripts/screens/streak_cycle_strip.gd")
const Gift = preload("res://scripts/screens/gift_box_view.gd")
var failures: Array[String] = []

func _init() -> void:
	LayoutTokens.motion_enabled = false
	var strip: StreakCycleStrip = Strip.new()
	root.add_child(strip)
	check(strip.cells.size() == 7, "seven cells")
	check(strip.gift_box is GiftBoxView, "gift box lives in the strip")
	check(strip.gift_box.get_parent() != null and strip.cells[6].is_ancestor_of(strip.gift_box), "gift in last cell")

	strip.show_view({"count": 0, "cycle_done": 0, "kept_today": false})
	check(_states(strip) == ["today", "todo", "todo", "todo", "todo", "todo", "todo"], "fresh profile")
	strip.show_view({"count": 3, "cycle_done": 2, "kept_today": false})
	check(_states(strip) == ["done", "done", "today", "todo", "todo", "todo", "todo"], "at risk: next cell is today")
	check(strip.today_index() == 2, "today index")
	strip.fill_today_animated()
	check(strip.cell_state(2) == "done" and strip.today_index() == -1, "fill today marks it done")
	strip.fill_today_animated()
	check(strip.cell_state(3) == "todo", "second fill is a no-op")
	strip.show_view({"count": 3, "cycle_done": 3, "kept_today": true})
	check(_states(strip) == ["done", "done", "done", "todo", "todo", "todo", "todo"], "kept today")
	strip.show_view({"count": 7, "cycle_done": 7, "kept_today": true})
	check(_states(strip).count("done") == 7 and strip.today_index() == -1, "gift day fills all")
	strip.show_view({"count": 6, "cycle_done": 6, "kept_today": false})
	check(strip.cell_state(6) == "today", "day 7 pending is today")
	strip.show_view({})
	check(_states(strip)[0] == "today", "empty view is safe")

	var box: GiftBoxView = Gift.create()
	root.add_child(box)
	var got := [false]
	box.opened.connect(func(): got[0] = true)
	box.play_idle()
	check(not box.is_open, "idle is closed")
	box.play_open()
	check(got[0] and box.is_open, "open emits opened (no motion)")

	strip.queue_free(); box.queue_free()
	if failures.is_empty():
		print("STREAK_STRIP_PASS"); quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func _states(strip: StreakCycleStrip) -> Array:
	var out := []
	for i in 7: out.append(strip.cell_state(i))
	return out

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)
```

- [ ] **Step 2: Run to verify it fails**

Run: `rtk godot --headless --path game --script res://tests/test_streak_strip.gd`
Expected: FAIL — parse error, `streak_cycle_strip.gd` not found.

- [ ] **Step 3: Create the placeholder art** `game/assets/ui/streak/gift_box.svg`

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
  <rect x="14" y="54" width="100" height="62" rx="10" fill="#FF8FB1"/>
  <rect x="8" y="38" width="112" height="24" rx="8" fill="#FF6F9A"/>
  <rect x="56" y="38" width="16" height="78" fill="#FFD84A"/>
  <path d="M64 38 C48 14 28 22 38 36 Z" fill="#FFD84A"/>
  <path d="M64 38 C80 14 100 22 90 36 Z" fill="#FFD84A"/>
</svg>
```

Then run `rtk godot --headless --path game --import` so the `.svg.import` file is generated.

- [ ] **Step 4: Implement** `game/scripts/screens/gift_box_view.gd`

```gdscript
# Gift box slot. Placeholder art now; the final animation replaces this scene's content only.
class_name GiftBoxView
extends Control

signal opened

const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const SCENE := "res://scenes/components/gift_box_view.tscn"
const ART := "res://assets/ui/streak/gift_box.svg"

var is_open := false
var art: TextureRect
var _tween: Tween = null

static func create() -> GiftBoxView:
	return (load(SCENE) as PackedScene).instantiate() as GiftBoxView

func _init() -> void:
	name = "GiftBoxView"
	custom_minimum_size = Vector2(56, 56)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	art = TextureRect.new()
	if ResourceLoader.exists(ART): art.texture = load(ART) as Texture2D
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)

func play_idle() -> void:
	_stop()
	is_open = false
	art.modulate = Color.WHITE
	art.scale = Vector2.ONE
	if not LayoutTokens.motion_enabled or not is_inside_tree():
		return
	art.pivot_offset = custom_minimum_size * 0.5
	_tween = create_tween().set_loops()
	_tween.tween_property(art, "rotation", 0.08, 0.6).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(art, "rotation", -0.08, 0.6).set_trans(Tween.TRANS_SINE)

func play_open() -> void:
	_stop()
	if not LayoutTokens.motion_enabled or not is_inside_tree():
		_finish_open()
		return
	art.pivot_offset = custom_minimum_size * 0.5
	_tween = create_tween()
	_tween.tween_property(art, "scale", Vector2(1.3, 1.3), 0.25).set_trans(Tween.TRANS_BACK)
	_tween.tween_property(art, "modulate:a", 0.0, 0.2)
	_tween.finished.connect(_finish_open)

func _finish_open() -> void:
	is_open = true
	opened.emit()

func _stop() -> void:
	if _tween != null:
		_tween.kill(); _tween = null
	art.rotation = 0.0
```

`game/scenes/components/gift_box_view.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/screens/gift_box_view.gd" id="1_gift"]

[node name="GiftBoxView" type="Control"]
custom_minimum_size = Vector2(56, 56)
layout_mode = 3
mouse_filter = 2
script = ExtResource("1_gift")
```

- [ ] **Step 5: Implement** `game/scripts/screens/streak_cycle_strip.gd`

```gdscript
# Seven day cells of the streak cycle (done / today / todo); the last cell holds the gift box.
class_name StreakCycleStrip
extends HBoxContainer

const FlameFx = preload("res://scripts/screens/flame_fx.gd")
const GiftBoxScript = preload("res://scripts/screens/gift_box_view.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const DAYS := 7
const DONE_BG := Color("#FFE3CC")
const TODAY_BG := Color("#FFF6D6")
const TODO_BG := Color("#EFEDEA")
const TODAY_RING := Color("#FF7A1A")

var cells: Array[PanelContainer] = []
var gift_box: GiftBoxView
var _states: Array[String] = []

func _init() -> void:
	name = "StreakCycleStrip"
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 10)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in DAYS:
		var cell := PanelContainer.new()
		cell.name = "Day%d" % (i + 1)
		cell.custom_minimum_size = Vector2(72, 72)
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(36)
		cell.add_theme_stylebox_override("panel", sb)
		var center := CenterContainer.new()
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(center)
		if i == DAYS - 1:
			gift_box = GiftBoxScript.create()
			center.add_child(gift_box)
		else:
			center.add_child(FlameFx.new(40, 0))
		cells.append(cell)
		_states.append("todo")
		add_child(cell)
	show_view({})

func show_view(view: Dictionary) -> void:
	var done := clampi(int(view.get("cycle_done", 0)), 0, DAYS)
	var kept: bool = view.get("kept_today", false)
	for i in DAYS:
		var state := "todo"
		if i < done: state = "done"
		elif not kept and i == done: state = "today"
		_apply(i, state)

func cell_state(i: int) -> String:
	return _states[i] if i >= 0 and i < DAYS else ""

func today_index() -> int:
	return _states.find("today")

func fill_today_animated() -> void:
	var i := today_index()
	if i < 0:
		return
	_apply(i, "done")
	if not LayoutTokens.motion_enabled or not is_inside_tree():
		return
	var cell := cells[i]
	cell.pivot_offset = cell.custom_minimum_size * 0.5
	cell.scale = Vector2(0.6, 0.6)
	create_tween().tween_property(cell, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)

func _apply(i: int, state: String) -> void:
	_states[i] = state
	var cell := cells[i]
	cell.set_meta("state", state)
	var sb := cell.get_theme_stylebox("panel") as StyleBoxFlat
	sb.bg_color = DONE_BG if state == "done" else TODAY_BG if state == "today" else TODO_BG
	sb.border_color = TODAY_RING
	sb.set_border_width_all(4 if state == "today" else 0)
	var icon: Control = cell.get_child(0).get_child(0)
	if icon == gift_box:
		gift_box.modulate = Color.WHITE if state == "done" else Color(1, 1, 1, 0.75)
	else:
		icon.call("set_lit", state == "done")
```

- [ ] **Step 6: Run to verify it passes**

Run: `rtk godot --headless --path game --script res://tests/test_streak_strip.gd`
Expected: `STREAK_STRIP_PASS`, exit 0.

- [ ] **Step 7: Commit**

```bash
rtk git add game/assets/ui/streak/gift_box.svg game/assets/ui/streak/gift_box.svg.import game/scripts/screens/gift_box_view.gd game/scenes/components/gift_box_view.tscn game/scripts/screens/streak_cycle_strip.gd game/tests/test_streak_strip.gd
rtk git commit -m "feat(streak): add cycle strip and gift box slot

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: `StreakScreen` and `streak.tscn`

**Files:**
- Create: `game/scripts/screens/streak_screen.gd`
- Create: `game/scenes/streak.tscn`
- Modify: `game/locale/strings.csv` (add `streak.title`), then reimport translations
- Test: `game/tests/test_streak_screen.gd`

**Interfaces:**
- Consumes: `StreakCycleStrip` (Task 2), `FlameFx`, `AssistInventory.streak_view(today: String = "") -> Dictionary`, locale keys `streak.title` (new), `streak.days`, `streak.best` (`"Kỷ lục: %d ngày"`), `settings.back`.
- Produces: `streak_screen.gd` (root of `scenes/streak.tscn`, node name `StreakScreen`): `signal back_pressed`, `var assists: Variant`, `func setup(inv: Variant, today: String = "") -> void`, `func show_view(view: Dictionary) -> void` (Plan C preview uses this with fake data), nodes/vars `title_label: Label`, `back_btn: Button`, `flame: Control`, `count_label: Label`, `days_label: Label`, `strip: StreakCycleStrip`, `gift_box: GiftBoxView` (= `strip.gift_box`), `best_label: Label`.

- [ ] **Step 1: Write the failing test** `game/tests/test_streak_screen.gd`

```gdscript
extends SceneTree

const Inventory = preload("res://scripts/state/assist_inventory.gd")
const Rules = preload("res://scripts/state/assist_rules.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
var failures: Array[String] = []

func _init() -> void:
	LayoutTokens.motion_enabled = false
	var dir := OS.get_user_data_dir().path_join("streak_screen_%s" % Time.get_ticks_usec())
	var inv := Inventory.new(dir)
	for day in range(1, 4): inv.on_round_finished("2026-05-%02d" % day)

	var screen: Control = (load("res://scenes/streak.tscn") as PackedScene).instantiate()
	root.add_child(screen)
	screen.setup(inv, "2026-05-03")
	check(screen.name == "StreakScreen", "scene root name")
	check(screen.title_label.text == screen.tr("streak.title"), "title")
	check(screen.count_label.text == "3" and screen.flame.lit, "count and lit flame")
	check(screen.strip.cell_state(2) == "done" and screen.strip.today_index() == -1, "strip kept today")
	check(screen.gift_box == screen.strip.gift_box, "gift box at the end of the strip")
	check(screen.best_label.visible and screen.best_label.text == screen.tr("streak.best") % 3, "best line")
	var back := [false]
	screen.back_pressed.connect(func(): back[0] = true)
	screen.back_btn.pressed.emit()
	check(back[0], "back emits back_pressed")

	screen.setup(inv, "2026-05-04")
	check(screen.count_label.text == "3" and not screen.flame.lit, "next day: grey, count kept")
	check(screen.strip.today_index() == 3, "next day: today cell")
	screen.setup(inv, "2026-05-06")
	check(screen.count_label.text == "0", "missed a day: count 0 (Q11)")
	check(screen.best_label.text == screen.tr("streak.best") % 3, "missed a day: best kept")

	screen.setup(null)
	check(screen.count_label.text == "0" and screen.strip.today_index() == 0, "no inventory renders zeros")
	check(screen.best_label.text == screen.tr("streak.best") % 0, "no inventory best 0")

	for key in ["streak.left", "streak.kept", "streak.at_risk", "streak.start", "streak.gift_got"]:
		check(screen.tr(key) == key, "removed key %s" % key)
	check(not ResourceLoader.exists("res://scripts/screens/streak_sheet.gd"), "streak_sheet removed")

	screen.queue_free()
	inv._store.remove_all()
	if failures.is_empty():
		print("STREAK_SCREEN_PASS"); quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)
```

Note: the last two checks (removed keys, removed `streak_sheet`) stay failing until Task 4; that is expected here.

- [ ] **Step 2: Run to verify it fails**

Run: `rtk godot --headless --path game --script res://tests/test_streak_screen.gd`
Expected: FAIL — `res://scenes/streak.tscn` missing.

- [ ] **Step 3: Add the title key**

Add this row to `game/locale/strings.csv` directly above the `streak.days` row:

```
streak.title,Streak,連続記録,Chuỗi ngày,Rangkaian,Sequência,Racha,연속 기록
```

Run: `rtk godot --headless --path game --import`
Expected: `game/locale/strings.*.translation` regenerated.

- [ ] **Step 4: Implement** `game/scripts/screens/streak_screen.gd`

```gdscript
# Streak screen: title, back, flame + day count, 7-day cycle strip with gift box, best line.
extends Control

signal back_pressed

const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const FlameFx = preload("res://scripts/screens/flame_fx.gd")
const StripScript = preload("res://scripts/screens/streak_cycle_strip.gd")
const BG := Color("#FFF4E0")
const INK := Color("#23365E")
const ON_COLOR := Color("#FF7A1A")

var assists: Variant = null
var title_label: Label
var back_btn: Button
var flame: Control
var count_label: Label
var days_label: Label
var strip: StreakCycleStrip
var gift_box: GiftBoxView
var best_label: Label

func _init() -> void:
	name = "StreakScreen"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 20)
	add_child(col)
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 96)
	col.add_child(header)
	back_btn = Button.new()
	back_btn.name = "BackBtn"
	back_btn.custom_minimum_size = Vector2(84, 84)
	back_btn.text = "←"
	back_btn.pressed.connect(func(): back_pressed.emit())
	header.add_child(back_btn)
	title_label = _label(44, FontTokens.heading())
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	header.add_child(Control.new())  # balances the back button so the title stays centred
	header.get_child(2).custom_minimum_size = Vector2(84, 84)
	flame = FlameFx.new(200, 18)
	col.add_child(_centered(flame))
	count_label = _label(120, FontTokens.heading()); col.add_child(count_label)
	days_label = _label(32, FontTokens.body_bold()); col.add_child(days_label)
	strip = StripScript.new()
	gift_box = strip.gift_box
	col.add_child(_centered(strip))
	best_label = _label(30, FontTokens.body_bold()); col.add_child(best_label)

func setup(inv: Variant, today: String = "") -> void:
	assists = inv
	show_view(inv.streak_view(today) if inv != null else {})

func show_view(view: Dictionary) -> void:
	var kept: bool = view.get("kept_today", false)
	title_label.text = tr("streak.title")
	back_btn.tooltip_text = tr("settings.back")
	flame.set_lit(kept)
	count_label.text = str(int(view.get("count", 0)))
	count_label.add_theme_color_override("font_color", ON_COLOR if kept else INK)
	days_label.text = tr("streak.days")
	best_label.text = tr("streak.best") % int(view.get("best", 0))
	best_label.visible = true
	strip.show_view(view)
	gift_box.play_idle()

func _centered(child: Control) -> CenterContainer:
	var c := CenterContainer.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(child)
	return c

func _label(font_size: int, font: Font) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", INK)
	if font != null: l.add_theme_font_override("font", font)
	return l
```

`game/scenes/streak.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/screens/streak_screen.gd" id="1_streak"]

[node name="StreakScreen" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_streak")
```

- [ ] **Step 5: Run**

Run: `rtk godot --headless --path game --script res://tests/test_streak_screen.gd`
Expected: only `removed key streak.left` … `removed key streak.gift_got` and `streak_sheet removed` fail (cleared in Task 4). Every other check passes.

- [ ] **Step 6: Commit**

```bash
rtk git add game/scripts/screens/streak_screen.gd game/scenes/streak.tscn game/tests/test_streak_screen.gd game/locale/strings.csv game/locale/strings.*.translation
rtk git commit -m "feat(streak): add streak screen with cycle strip and best line

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Navigation — chip opens STREAK, back returns Home; remove `streak_sheet`

**Files:**
- Modify: `game/scripts/campaign/nav_controller.gd`
- Modify: `game/scripts/campaign/screen_router.gd` (`SCENE_MAP`: add `"streak"`)
- Modify: `game/scripts/screens/app_shell.gd` (`_instantiate_screen`: title branch + new `"streak"` branch)
- Modify: `game/scripts/screens/title_screen.gd:4-7` (signal), `:146` (chip wiring)
- Modify: `game/scripts/screens/streak_chip.gd`
- Delete: `game/scripts/screens/streak_sheet.gd` (and `streak_sheet.gd.uid` if present)
- Modify: `game/locale/strings.csv` (delete rows `streak.left`, `streak.kept`, `streak.at_risk`, `streak.start`, `streak.gift_got`), reimport
- Rewrite: `game/tests/test_streak_ui.gd`
- Modify: `game/tests/test_campaign_runtime.gd` (~line 163, add route checks)

**Interfaces:**
- Consumes: `scenes/streak.tscn` / `streak_screen.gd` (`setup(inv, today = "")`, `signal back_pressed`) from Task 3; `ScreenRouter` from Task 0.
- Produces: `NavController.Screen.STREAK` (appended after `FAIL`; Plan A appends `STREAK_ACTIVATE`/`STREAK_GIFT` after it), `SCREEN_NAMES[STREAK] == "streak"`, routes `TITLE → STREAK`, `STREAK → TITLE`; `title_screen` `signal streak_pressed()`; `streak_chip` exposes `ON_COLOR`/`OFF_COLOR` constants itself and no longer has `sheet`.

- [ ] **Step 1: Write the failing tests**

Replace `game/tests/test_streak_ui.gd` entirely:

```gdscript
extends SceneTree

const Inventory = preload("res://scripts/state/assist_inventory.gd")
const Rules = preload("res://scripts/state/assist_rules.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const AppShell = preload("res://scripts/screens/app_shell.gd")
const NavController = preload("res://scripts/campaign/nav_controller.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	LayoutTokens.motion_enabled = false
	var today := Rules.today()
	var yesterday := Time.get_date_string_from_unix_time(Rules._unix(today) - 86400)
	var three_ago := Time.get_date_string_from_unix_time(Rules._unix(today) - 3 * 86400)
	var dir := OS.get_user_data_dir().path_join("streak_ui_%s" % Time.get_ticks_usec())
	var inv := Inventory.new(dir)
	inv.on_round_finished(yesterday)  # streak 1, not kept today -> at risk

	var title: Control = (load("res://scenes/title.tscn") as PackedScene).instantiate()
	title.assists = inv
	root.add_child(title)
	title.setup(null)
	var chip: Button = title.streak_chip
	check(chip != null and chip.visible, "chip on home")
	check(chip.get_parent() is CenterContainer, "chip centered horizontally")
	check(chip.count_label.text == "1", "chip shows count")
	check(not chip.flame.lit, "grey before today's play")
	check(chip.at_risk, "at risk flagged")
	check(not "sheet" in chip, "chip has no popup sheet")
	var asked := [0]
	title.streak_pressed.connect(func(): asked[0] += 1)
	chip.pressed.emit()
	check(asked[0] == 1, "chip tap asks for the streak screen")

	inv.on_round_finished(today)
	chip.refresh()
	check(chip.count_label.text == "2" and chip.flame.lit, "lit after today's play")
	check(not chip.at_risk, "not at risk once kept")

	var lapsed := Inventory.new(dir + "_lapsed")
	lapsed.on_round_finished(three_ago)
	chip.bind(lapsed)
	check(chip.count_label.text == "0" and not chip.at_risk, "missed day: chip shows 0 (Q11)")
	lapsed._store.remove_all()

	var bare: Control = (load("res://scenes/title.tscn") as PackedScene).instantiate()
	root.add_child(bare)
	bare.setup(null)
	check(not bare.streak_chip.visible, "chip hidden without stock")
	title.queue_free(); bare.queue_free()
	inv._store.remove_all()

	await _test_shell_route(dir + "_shell")
	if failures.is_empty():
		print("STREAK_UI_PASS"); quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func _test_shell_route(pdir: String) -> void:
	DirAccess.make_dir_recursive_absolute(pdir)
	var shell: AppShell = load("res://scenes/main.tscn").instantiate()
	shell.profile_dir = pdir
	root.add_child(shell)
	await process_frame
	var home: Control = shell.screen_host.get_child(0)
	home.streak_chip.pressed.emit()
	await process_frame
	check(shell.nav.current() == NavController.Screen.STREAK, "chip navigates to STREAK")
	var screen: Control = shell.screen_host.get_child(0)
	check(screen.name == "StreakScreen", "streak screen shown")
	check(screen.assists == shell.assists, "streak screen gets the shell inventory")
	screen.back_btn.pressed.emit()
	await process_frame
	check(shell.nav.current() == NavController.Screen.TITLE, "back returns home")
	var again: Control = shell.screen_host.get_child(0)
	check(again.name == "TitleScreen" and again.streak_chip.visible, "home chip still bound after back")
	shell.queue_free()
	await process_frame

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)
```

In `game/tests/test_campaign_runtime.gd`, right after `_check(nav.go_to(NavController.Screen.PUZZLE), "title to puzzle")` add:

```gdscript
	var nav2 := NavController.new()
	_check(nav2.go_to(NavController.Screen.STREAK) and nav2.current_name() == "streak", "title to streak")
	_check(not nav2.go_to(NavController.Screen.PUZZLE), "streak cannot jump to puzzle")
	_check(nav2.go_to(NavController.Screen.TITLE), "streak back to title")
```

- [ ] **Step 2: Run to verify they fail**

Run: `rtk godot --headless --path game --script res://tests/test_streak_ui.gd`
Expected: FAIL (`streak_pressed` not a signal / `Screen.STREAK` not found).
Run: `rtk godot --headless --path game --script res://tests/test_campaign_runtime.gd`
Expected: FAIL (`STREAK` not found).

- [ ] **Step 3: NavController**

`game/scripts/campaign/nav_controller.gd` — replace the enum, names and routes:

```gdscript
enum Screen { TITLE, PUZZLE, WIN, FAIL, STREAK }

const SCREEN_NAMES := {
	Screen.TITLE: "title", Screen.PUZZLE: "puzzle", Screen.WIN: "win",
	Screen.FAIL: "fail", Screen.STREAK: "streak",
}
const ROUTES := {
	Screen.TITLE: [Screen.PUZZLE, Screen.STREAK],
	Screen.PUZZLE: [Screen.WIN, Screen.FAIL, Screen.TITLE],
	Screen.WIN: [Screen.PUZZLE, Screen.TITLE],
	Screen.FAIL: [Screen.PUZZLE, Screen.TITLE],
	Screen.STREAK: [Screen.TITLE],
}
```

- [ ] **Step 4: Chip and title**

`game/scripts/screens/streak_chip.gd`:
- Delete `const StreakSheet = preload(...)`, `var sheet: StreakSheet = null`, the two lines `chip.sheet = StreakSheet.new()` / `screen.add_child(chip.sheet)` in `attach`, the `pressed.connect(_on_pressed)` line in `_init`, and the whole `_on_pressed` function.
- Replace the colour constants with literals:

```gdscript
const ON_COLOR := Color("#FF7A1A")
const OFF_COLOR := Color("#B9B4AC")
```

- Update the header comment to `# Home streak chip: flame + day count; grey until today's play, pulses when at risk. Tap → streak screen (wired by title_screen).`
- `attach(screen, safe)` keeps its signature (the `screen` arg becomes unused; rename to `_screen`).

`game/scripts/screens/title_screen.gd`:
- Add `signal streak_pressed()` after `signal options_pressed()`.
- Replace line `streak_chip = StreakChip.attach(self, safe)` with:

```gdscript
	streak_chip = StreakChip.attach(self, safe)
	streak_chip.pressed.connect(func(): streak_pressed.emit())
```

- [ ] **Step 5: Router entry and app_shell wiring (stay ≤ 300 lines, one statement per line)**

In `game/scripts/campaign/screen_router.gd`, add as the last entry of `SCENE_MAP`:

```gdscript
	"streak": "res://scenes/streak.tscn",
```

Extend `game/tests/test_screen_router.gd`: change the key loop to `for key in ["title", "puzzle", "win", "fail", "options", "streak"]:`.

In the `"title":` branch of `_instantiate_screen`, after the `options_pressed` line add:

```gdscript
			if screen.has_signal("streak_pressed"): screen.connect("streak_pressed", func(): nav.go_to(NavController.Screen.STREAK))
```

After the `"fail":` branch add:

```gdscript
		"streak":
			if screen.has_signal("back_pressed"): screen.connect("back_pressed", func(): nav.go_to(NavController.Screen.TITLE))
			if screen.has_method("setup"): screen.call("setup", assists)
```

(`setup` gets no date: the inventory resolves today itself, and after Plan C through its `DayClock`.)

Run: `wc -l game/scripts/screens/app_shell.gd game/scripts/screens/title_screen.gd`
Expected: app_shell 285, title_screen 291.

- [ ] **Step 6: Remove the sheet and dead keys**

```bash
rtk git rm game/scripts/screens/streak_sheet.gd
rtk git rm --ignore-unmatch game/scripts/screens/streak_sheet.gd.uid
```

Delete the five rows starting `streak.left,`, `streak.kept,`, `streak.at_risk,`, `streak.start,`, `streak.gift_got,` from `game/locale/strings.csv`. Then confirm nothing references them:

Run: `rtk grep -rn "streak_sheet\|StreakSheet\|streak\.left\|streak\.kept\|streak\.at_risk\|streak\.start\|streak\.gift_got" game/scripts game/tests game/scenes`
Expected: no output.

Run: `rtk godot --headless --path game --import`

- [ ] **Step 7: Run to verify they pass**

Run each; expected PASS markers / exit 0:
- `rtk godot --headless --path game --script res://tests/test_streak_ui.gd` → `STREAK_UI_PASS`
- `rtk godot --headless --path game --script res://tests/test_streak_screen.gd` → `STREAK_SCREEN_PASS`
- `rtk godot --headless --path game --script res://tests/test_streak_strip.gd` → `STREAK_STRIP_PASS`
- `rtk godot --headless --path game --script res://tests/test_campaign_runtime.gd`
- `rtk godot --headless --path game --script res://tests/test_integration.gd` → `INTEGRATION_PASS`
- `rtk godot --headless --path game --script res://tests/test_screens.gd`

- [ ] **Step 8: Commit**

```bash
rtk git add game/scripts/campaign/nav_controller.gd game/scripts/campaign/screen_router.gd game/tests/test_screen_router.gd game/scripts/screens/app_shell.gd game/scripts/screens/title_screen.gd game/scripts/screens/streak_chip.gd game/locale/strings.csv game/locale/strings.*.translation game/tests/test_streak_ui.gd game/tests/test_campaign_runtime.gd
rtk git commit -m "feat(streak): open streak screen from home chip and drop the popup sheet

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Gate, STATUS, merge back

**Files:**
- Modify: `docs/STATUS.md` (section "Kho trợ giúp và streak")

- [ ] **Step 1: Clean-room**

Run: `rtk python -B tools/clean_room.py`
Expected: exit 0.

- [ ] **Step 2: Full verify**

Run: `rtk python -B tools/verify.py --godot <godot executable>`
Expected: every `godot:test_*` line PASS (including `test_screen_router`, `test_streak_strip`, `test_streak_screen`, `test_streak_ui`). Note the log path under `scratch/verification/` and the revision (`rtk git rev-parse --short HEAD`). If a failure is unrelated to this plan (e.g. a pre-existing one recorded in STATUS), record it verbatim; do not fix it here.

- [ ] **Step 3: Module size check**

Run: `wc -l game/scripts/screens/*.gd game/scripts/campaign/*.gd | sort -n | tail -5`
Expected: no file above 300.

- [ ] **Step 4: Update STATUS**

In `docs/STATUS.md`, section `## Kho trợ giúp và streak (2026-10-14, ...)`, replace the line `- Home có viên lửa chuỗi ở giữa phía trên, bảng chuỗi và hiệu ứng +1 (RST-031).` with:

```markdown
- Home có viên lửa chuỗi ở giữa phía trên; nhấn mở **màn Chuỗi** riêng (`scenes/streak.tscn`): title, nút back, lửa + số ngày, dải 7 ô (`StreakCycleStrip`), hộp quà placeholder (`GiftBoxView`, chờ animation chủ dự án), dòng "Kỷ lục". Đã gỡ popup `streak_sheet` và các câu trạng thái. Mất chuỗi (lỡ ≥1 ngày) hiển thị 0 ngay (Plan B, `feat/v1.0.1/streak-screen`).
- Kiểm chứng Plan B: `test_streak_strip`, `test_streak_screen`, `test_streak_ui`, full verify rev `<rev từ Step 2>` (log `<đường dẫn log từ Step 2>`). Còn mở: QA giao diện/thiết bị màn Chuỗi; animation hộp quà thật.
```

Fill the two angle-bracket values with the actual revision and log path from Step 2 (do not leave the brackets).

```bash
rtk git add docs/STATUS.md
rtk git commit -m "docs(status): record streak screen plan B

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 5: Merge into the parent branch**

```bash
rtk git status --short          # only the pre-existing unrelated changes may remain
rtk git checkout feat/v1.0.1/assist-inventory
rtk git merge --no-ff feat/v1.0.1/streak-screen -m "merge: streak screen (plan B) into assist-inventory

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
rtk godot --headless --path game --script res://tests/test_streak_ui.gd
```

Expected: merge succeeds; `STREAK_UI_PASS`. If `checkout` is refused because of uncommitted unrelated files, stop and report — do not stash, reset or commit them. Do not push unless the owner asks.

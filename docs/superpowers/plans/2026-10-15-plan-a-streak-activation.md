# Plan A — Streak Activation and Gift Screens Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** After the first finished (won or lost, non-custom) round of the day, show a full-screen "streak activated" step, then (on day 7) a "gift received" step, then the original Win/Fail screen with unchanged setup args; remove the on-board `StreakBurst` and the `assist.reward` toast.

**Architecture:** `AssistInventory.on_round_finished` returns a result dictionary `{extended, view, reward}`. `PuzzleAssistController` keeps it in `round_result` (so the 300-line `puzzle_screen.gd` is not touched). A new pure helper `StreakFlow` (`game/scripts/campaign/streak_flow.gd`, RefCounted, owned by `app_shell`) turns that result plus the final screen (WIN/FAIL) into a queue of nav targets; `app_shell` walks the queue on each screen's `continued` signal. The two scenes are registered in `ScreenRouter.SCENE_MAP` (Plan B Task 0), not in `app_shell`. Two new screens (`streak_activate_screen.gd`, `streak_gift_screen.gd`) only render the data passed to `setup()` and never touch save, so Plan C can preview them with fake data.

**Tech Stack:** Godot 4, GDScript, headless SceneTree test scripts (`godot --headless --path game --script res://tests/test_<x>.gd`), `tools/verify.py`, `tools/clean_room.py`.

**Spec:** `docs/superpowers/specs/2026-10-15-streak-screens-debug-design.md` (§3.3, Q1–Q4)

## Global Constraints

- Branch `feat/v1.0.1/streak-activation` created FROM `feat/v1.0.1/assist-inventory`; merge back with `git merge --no-ff` into `feat/v1.0.1/assist-inventory` only (Q10). Do not push.
- PREREQUISITE: Plan B is merged into `feat/v1.0.1/assist-inventory`. Use exactly: `class_name StreakCycleStrip` (`res://scripts/screens/streak_cycle_strip.gd`, `extends HBoxContainer`, create with `StreakCycleStrip.new()`: `show_view(view: Dictionary)`, `fill_today_animated()`), `class_name GiftBoxView` (`res://scripts/screens/gift_box_view.gd`, create ONLY with `GiftBoxView.create()` — the single swap point: `play_idle()`, `play_open()`, `signal opened`), `NavController.Screen.STREAK` (`res://scripts/campaign/nav_controller.gd`), `ScreenRouter` (`res://scripts/campaign/screen_router.gd`, `SCENE_MAP`). Refer to the two views by their global class names; do not add `const StreakCycleStrip = preload(...)` / `const GiftBoxView = preload(...)` (shadows the global class). If any of these is missing, stop and report a blocker; do not re-implement them.
- No autoloads; Godot signals only; composition root is `app_shell.gd`.
- Every module ≤ 300 lines. After Plan B `app_shell.gd` is at 285 and `puzzle_screen.gd` at 300 — check `wc -l` after every edit. Never join statements/declarations onto shared lines to save space; this plan does not edit `puzzle_screen.gd`.
- Scene keys / nav names (fixed across Plans A/B/C): `"streak"` (Plan B), `"streak_activate"`, `"streak_gift"` (this plan). Enum order: `TITLE, PUZZLE, WIN, FAIL, STREAK, STREAK_ACTIVATE, STREAK_GIFT`.
- Clean-room: original names, text and visuals only; `tools/clean_room.py` must pass.
- TDD: failing test first, then implementation.
- Q2: every finished round (won or lost) counts (RST-032); custom/debug/tutorial levels are excluded (RST-030).
- Q3: remove `streak_burst.gd` and toast `assist.reward`.
- Q4: day 7 shows a separate gift screen between Activate and Win/Fail, showing hint/place received.
- `streak_activate_screen.gd` / `streak_gift_screen.gd` must not read or write save; they depend only on `setup()` arguments.
- Stage only files listed in each task; never `git add -A` (the working tree has unrelated `.import`, `.gitignore`, `project.godot` edits).

## Review Focus

1. Restored round (`hold == false` re-entry of a won/failed session) must not re-show Activate — expected: straight to Win/Fail. Pinned in Task 4 test.
2. Second finished round on the same day — expected: no Activate, straight to Win/Fail. Pinned in Task 2 and Task 4 tests.
3. Day-7 reward clipped by `CAP` to 0 for one kind (e.g. hint already 10) — expected: gift screen still shows, with `+0` for that kind, never negative. Pinned in Task 3 test.
4. Debug-picker level (`_debug_mode`) finishing — expected: no Activate (custom), Win/Fail as before. Pinned in Task 4 test.
5. Win screen after the detour must still receive the original args (label, elapsed, hearts, next-level preview, `is_last`). Pinned in Task 4 test (label + hearts checked on WIN after Continue).

---

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `game/scripts/state/assist_inventory.gd` | Modify | `on_round_finished` returns `{extended, view, reward}`; drop `streak_extended` signal |
| `game/scripts/campaign/streak_flow.gd` | Create | Pure queue: result + final screen → ordered nav targets |
| `game/scripts/campaign/nav_controller.gd` | Modify | Add `STREAK_ACTIVATE`, `STREAK_GIFT` + routes |
| `game/scripts/screens/streak_activate_screen.gd` + `game/scenes/streak_activate.tscn` | Create | Flame lights, today cell fills, Continue |
| `game/scripts/screens/streak_gift_screen.gd` + `game/scenes/streak_gift.tscn` | Create | Gift box opens, +hint/+place, Continue |
| `game/scripts/screens/puzzle_assist_controller.gd` | Modify | Return and keep `round_result`, no burst, no toast |
| `game/scripts/campaign/screen_router.gd` | Modify | `SCENE_MAP` += `streak_activate`, `streak_gift` |
| `game/scripts/screens/app_shell.gd` | Modify | Route through `StreakFlow` |
| `game/tests/test_screen_router.gd` | Modify | New keys |
| `game/scripts/screens/streak_burst.gd`, `game/tests/test_streak_burst.gd` | Delete | Replaced (Q3) |
| `game/locale/strings.csv` | Modify | New keys, remove `assist.reward` |
| `game/tests/test_streak_activation.gd` | Create | Flow + screens tests |
| `game/tests/test_assist_inventory.gd`, `test_assist_flow.gd`, `test_integration.gd` | Modify | New return shape and flow |
| `docs/DECISIONS.md`, `docs/STATUS.md` | Modify | RST-031/032 + status |

---

### Task 0: Branch

- [ ] **Step 1: Preflight and branch**

```bash
rtk git checkout feat/v1.0.1/assist-inventory
rtk git status --short          # unrelated edits stay unstaged; do not reset them
rtk git log --oneline -5        # confirm Plan B merge commit is present
ls game/scripts/screens/streak_cycle_strip.gd game/scripts/screens/gift_box_view.gd game/scripts/campaign/screen_router.gd
grep -n "STREAK" game/scripts/campaign/nav_controller.gd
rtk git checkout -b feat/v1.0.1/streak-activation
```

Expected: the three files exist and `Screen.STREAK` is present. Otherwise stop: blocker "Plan B not merged".

---

### Task 1: Inventory round result

**Files:**
- Modify: `game/scripts/state/assist_inventory.gd` (`on_round_finished`, remove `signal streak_extended`)
- Test: `game/tests/test_assist_inventory.gd`

**Interfaces:**
- Produces: `AssistInventory.on_round_finished(today: String = "") -> Dictionary` returning
  `{"extended": bool, "view": Dictionary, "reward": Dictionary}`.
  `view` = `AssistRules.streak_view(data, today)` after recording (keys `count`, `best`, `kept_today`, `at_risk`, `cycle_done`). `reward` = `{"hint": int, "place": int}` on day 7, `{}` otherwise. When not extended (same day / clock went back): `extended == false`, `reward == {}`, `view` is still the current view.

- [ ] **Step 1: Write the failing test** — in `test_assist_inventory.gd` replace the line `check(reloaded.on_round_finished("2026-10-01").is_empty(), "day 1 no reward")` with:

```gdscript
	var first: Dictionary = reloaded.on_round_finished("2026-10-01")
	check(first.extended and first.reward.is_empty(), "day 1 extends, no reward")
	check(first.view.count == 1 and first.view.kept_today, "day 1 view")
```

and replace the block from `var totals: Array = []` through `check(totals == [1, 1], ...)` with:

```gdscript
	var a: Dictionary = s_inv.on_round_finished("2026-06-01")
	var b: Dictionary = s_inv.on_round_finished("2026-06-01")
	var c: Dictionary = s_inv.on_round_finished("2026-06-03")
	check(a.extended and not b.extended and c.extended, "restart from 1 extends; same day does not")
	check(b.reward.is_empty() and b.view.count == 1, "same day result keeps view")
	# Day 7 reward, clipped at CAP for hint
	var wdir := dir + "_week"
	var w_inv := Inventory.new(wdir)
	w_inv.data.streakDays = 6; w_inv.data.totalStreak = 6; w_inv.data.lastStreakDate = "2026-06-06"
	w_inv.data.hint = 10
	var week: Dictionary = w_inv.on_round_finished("2026-06-07")
	check(week.extended and week.reward == {"hint": 0, "place": 2}, "day 7 reward clipped, never negative")
	check(week.view.cycle_done == 7 and week.view.count == 7, "day 7 view shows full pack")
	check(not w_inv.has_signal("streak_extended"), "burst signal removed")
	w_inv._store.remove_all()
```

- [ ] **Step 2: Run to verify it fails**

Run: `rtk godot --headless --path game --script res://tests/test_assist_inventory.gd`
Expected: FAIL (`Invalid access to property 'extended'` or the check labels printed).

- [ ] **Step 3: Implement** — in `assist_inventory.gd` delete `signal streak_extended(total: int)` and replace `on_round_finished`:

```gdscript
# Any finished round (won or lost) keeps the streak; future modes call this too.
# Returns {extended, view, reward}; reward is {hint, place} on day 7, else {}.
func on_round_finished(today: String = "") -> Dictionary:
	var day := today if today != "" else AssistRules.today()
	var res := AssistRules.record_win(data, day)
	var extended: bool = res.data != data
	if extended:
		_commit(res.data, res.reward.keys())
	return {"extended": extended, "view": AssistRules.streak_view(data, day), "reward": res.reward}
```

- [ ] **Step 4: Run to verify it passes**

Run: `rtk godot --headless --path game --script res://tests/test_assist_inventory.gd`
Expected: `ASSIST_INVENTORY_PASS`. (`test_assist_flow` / `test_streak_burst` may now fail; fixed in Task 4.)

- [ ] **Step 5: Commit**

```bash
rtk git add game/scripts/state/assist_inventory.gd game/tests/test_assist_inventory.gd
rtk git commit -m "feat(streak): return round result from inventory" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: StreakFlow queue and nav routes

**Files:**
- Create: `game/scripts/campaign/streak_flow.gd`
- Modify: `game/scripts/campaign/nav_controller.gd`
- Test: `game/tests/test_streak_activation.gd` (create; Task 3 extends it)

**Interfaces:**
- Consumes: Task 1 result dictionary.
- Produces:
  - `NavController.Screen.STREAK_ACTIVATE`, `NavController.Screen.STREAK_GIFT`, names `"streak_activate"`, `"streak_gift"`.
  - `StreakFlow.start(source: Variant, final_screen: int) -> int` — `source` is the finished puzzle screen's `assist_ctl` (a `PuzzleAssistController`; reads `source.get("round_result")`, tolerates `null` or missing) or a result `Dictionary`; returns the first nav target. `StreakFlow.next() -> int` pops the next target (returns `final_screen` when queue empty). Vars `view: Dictionary`, `reward: Dictionary` hold data for the screens.

- [ ] **Step 1: Write the failing test** — create `game/tests/test_streak_activation.gd`:

```gdscript
extends SceneTree

const NavController = preload("res://scripts/campaign/nav_controller.gd")
const StreakFlow = preload("res://scripts/campaign/streak_flow.gd")
const S = NavController.Screen
const VIEW := {"count": 3, "best": 5, "kept_today": true, "at_risk": false, "cycle_done": 3}
var failures: Array[String] = []

func _initialize() -> void:
	_test_flow()
	_test_routes()
	await _test_screens()
	if failures.is_empty():
		print("STREAK_ACTIVATION_PASS")
		quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func _test_flow() -> void:
	var flow := StreakFlow.new()
	check(flow.start({}, S.WIN) == S.WIN, "empty result goes straight to result screen")
	check(flow.start(null, S.FAIL) == S.FAIL, "null source tolerated")
	check(flow.start({"extended": false, "view": VIEW, "reward": {}}, S.WIN) == S.WIN, "same day: no activate")
	check(flow.start({"extended": true, "view": VIEW, "reward": {}}, S.FAIL) == S.STREAK_ACTIVATE, "first round: activate")
	check(flow.view == VIEW and flow.next() == S.FAIL, "activate then fail")
	var gift := {"hint": 2, "place": 3}
	check(flow.start({"extended": true, "view": VIEW, "reward": gift}, S.WIN) == S.STREAK_ACTIVATE, "day 7 starts with activate")
	check(flow.next() == S.STREAK_GIFT and flow.reward == gift, "then gift")
	check(flow.next() == S.WIN and flow.next() == S.WIN, "then win; empty queue stays on result")
	var holder := Node.new(); holder.set_meta("unused", 1)
	check(flow.start(holder, S.WIN) == S.WIN, "source without round_result")
	holder.free()

func _test_routes() -> void:
	var nav := NavController.new()
	check(nav.go_to(S.PUZZLE) and nav.go_to(S.STREAK_ACTIVATE), "puzzle -> activate")
	check(nav.current_name() == "streak_activate", "activate name")
	check(nav.go_to(S.STREAK_GIFT) and nav.current_name() == "streak_gift", "activate -> gift")
	check(nav.go_to(S.WIN), "gift -> win")
	nav = NavController.new(); nav.go_to(S.PUZZLE); nav.go_to(S.STREAK_ACTIVATE)
	check(nav.go_to(S.FAIL), "activate -> fail")
	nav = NavController.new()
	check(not nav.go_to(S.STREAK_ACTIVATE), "title cannot open activate")

func _test_screens() -> void:
	pass  # filled in Task 3

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)
```

- [ ] **Step 2: Run to verify it fails**

Run: `rtk godot --headless --path game --script res://tests/test_streak_activation.gd`
Expected: FAIL — parse error, `streak_flow.gd` not found / `STREAK_ACTIVATE` not in enum.

- [ ] **Step 3: Implement** — create `game/scripts/campaign/streak_flow.gd`:

```gdscript
# Orders the streak steps shown between a finished round and its result screen.
extends RefCounted

const NavController = preload("res://scripts/campaign/nav_controller.gd")

var view: Dictionary = {}
var reward: Dictionary = {}
var _queue: Array[int] = []
var _final: int = NavController.Screen.WIN

# source: the finished screen's PuzzleAssistController (exposes round_result) or a result Dictionary.
func start(source: Variant, final_screen: int) -> int:
	var result: Variant = source
	if source is Object:
		result = (source as Object).get("round_result")
	if not result is Dictionary:
		result = {}
	_final = final_screen
	_queue.clear()
	view = result.get("view", {})
	reward = result.get("reward", {})
	if bool(result.get("extended", false)):
		_queue.append(NavController.Screen.STREAK_ACTIVATE)
		if not reward.is_empty():
			_queue.append(NavController.Screen.STREAK_GIFT)
	_queue.append(final_screen)
	return next()

func next() -> int:
	return _queue.pop_front() if not _queue.is_empty() else _final
```

In `nav_controller.gd` (after Plan B, the enum already ends with `STREAK`), replace the enum, `SCREEN_NAMES` and `ROUTES` with (Plan B's `STREAK` entries unchanged; `PUZZLE` may now route to `STREAK_ACTIVATE`):

```gdscript
enum Screen { TITLE, PUZZLE, WIN, FAIL, STREAK, STREAK_ACTIVATE, STREAK_GIFT }

const SCREEN_NAMES := {
	Screen.TITLE: "title", Screen.PUZZLE: "puzzle", Screen.WIN: "win",
	Screen.FAIL: "fail", Screen.STREAK: "streak",
	Screen.STREAK_ACTIVATE: "streak_activate", Screen.STREAK_GIFT: "streak_gift",
}
const ROUTES := {
	Screen.TITLE: [Screen.PUZZLE, Screen.STREAK],
	Screen.PUZZLE: [Screen.WIN, Screen.FAIL, Screen.TITLE, Screen.STREAK_ACTIVATE],
	Screen.WIN: [Screen.PUZZLE, Screen.TITLE],
	Screen.FAIL: [Screen.PUZZLE, Screen.TITLE],
	Screen.STREAK: [Screen.TITLE],
	Screen.STREAK_ACTIVATE: [Screen.STREAK_GIFT, Screen.WIN, Screen.FAIL],
	Screen.STREAK_GIFT: [Screen.WIN, Screen.FAIL],
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `rtk godot --headless --path game --script res://tests/test_streak_activation.gd`
Expected: `STREAK_ACTIVATION_PASS`

- [ ] **Step 5: Commit**

```bash
rtk git add game/scripts/campaign/streak_flow.gd game/scripts/campaign/nav_controller.gd game/tests/test_streak_activation.gd
rtk git commit -m "feat(streak): queue activate and gift steps before result" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Activate and Gift screens

**Files:**
- Create: `game/scripts/screens/streak_activate_screen.gd`, `game/scenes/streak_activate.tscn`
- Create: `game/scripts/screens/streak_gift_screen.gd`, `game/scenes/streak_gift.tscn`
- Modify: `game/locale/strings.csv` (add keys)
- Test: `game/tests/test_streak_activation.gd` (`_test_screens`)

**Interfaces:**
- Consumes: `StreakCycleStrip.show_view(view)`, `fill_today_animated()`; `GiftBoxView.play_idle()`, `play_open()`, `signal opened` (Plan B); `FlameFx.new(side, embers)`, `set_lit(on)`.
- Produces (Plan C previews these with fake data):
  - `streak_activate_screen.gd`: `signal continued()`, `setup(view: Dictionary) -> void`, nodes `count_label: Label`, `strip`, `flame`, `continue_btn: Button`.
  - `streak_gift_screen.gd`: `signal continued()`, `setup(reward: Dictionary) -> void` (`{"hint": int, "place": int}`), nodes `gift`, `hint_label: Label`, `place_label: Label`, `continue_btn: Button`.
  - Locale keys `streak.activate_title`, `streak.gift_title`, `streak.gift_hint`, `streak.gift_place`, `common.continue`.

- [ ] **Step 1: Write the failing test** — replace `_test_screens` in `test_streak_activation.gd` and add the preloads at the top:

```gdscript
const ActivateScreen = preload("res://scripts/screens/streak_activate_screen.gd")
const GiftScreen = preload("res://scripts/screens/streak_gift_screen.gd")
```

```gdscript
func _test_screens() -> void:
	await process_frame
	var act := ActivateScreen.new()
	root.add_child(act)
	act.setup(VIEW)
	check(act.count_label.text == "3", "activate shows streak count")
	check(act.flame.lit, "activate lights the flame")
	var hits := [0]
	act.continued.connect(func(): hits[0] += 1)
	act.continue_btn.pressed.emit()
	check(hits[0] == 1, "activate continue emits once")
	act.queue_free()
	var gift := GiftScreen.new()
	root.add_child(gift)
	gift.setup({"hint": 0, "place": 4})
	check(gift.hint_label.text == tr("streak.gift_hint") % 0, "gift shows +0 hint")
	check(gift.place_label.text == tr("streak.gift_place") % 4, "gift shows +4 place")
	var g_hits := [0]
	gift.continued.connect(func(): g_hits[0] += 1)
	gift.continue_btn.pressed.emit()
	check(g_hits[0] == 1, "gift continue emits once")
	gift.queue_free()
	# No save access: neither script references a store/inventory
	for p in ["res://scripts/screens/streak_activate_screen.gd", "res://scripts/screens/streak_gift_screen.gd"]:
		var src := FileAccess.get_file_as_string(p)
		check(not src.contains("assist_inventory") and not src.contains("dual_slot_store"), "no save access in " + p)
```

- [ ] **Step 2: Run to verify it fails**

Run: `rtk godot --headless --path game --script res://tests/test_streak_activation.gd`
Expected: FAIL — preload of `streak_activate_screen.gd` not found.

- [ ] **Step 3: Implement** — `game/scripts/screens/streak_activate_screen.gd`:

```gdscript
# Full-screen step after the first finished round of the day: the flame lights, today's cell fills.
# Renders only what setup() receives; never reads or writes save (debug previews reuse it).
extends Control

const FlameFx = preload("res://scripts/screens/flame_fx.gd")

signal continued()

var view: Dictionary = {}
var title_label: Label
var count_label: Label
var flame: FlameFx
var strip: StreakCycleStrip
var continue_btn: Button

func setup(v: Dictionary) -> void:
	view = v.duplicate(true)
	_ensure_nodes()
	count_label.text = str(int(view.get("count", 0)))
	flame.set_lit(true)
	strip.show_view(view)
	strip.call_deferred("fill_today_animated")

func _ready() -> void:
	_ensure_nodes()

func _ensure_nodes() -> void:
	if continue_btn != null:
		return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#FFF6E8"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	add_child(box)
	title_label = Label.new(); title_label.text = tr("streak.activate_title")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 40)
	box.add_child(title_label)
	flame = FlameFx.new(160.0, 12)
	flame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(flame)
	count_label = Label.new(); count_label.text = "0"
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 64)
	box.add_child(count_label)
	strip = StreakCycleStrip.new()
	strip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(strip)
	continue_btn = Button.new(); continue_btn.text = tr("common.continue")
	continue_btn.custom_minimum_size = Vector2(280, 72)
	continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_btn.pressed.connect(func(): continued.emit())
	box.add_child(continue_btn)
```

`game/scripts/screens/streak_gift_screen.gd`:

```gdscript
# Day-7 step: the gift box opens and shows the hints/candy drops added to the stock.
# Renders only what setup() receives; never reads or writes save (debug previews reuse it).
extends Control

signal continued()

var reward: Dictionary = {}
var title_label: Label
var gift: GiftBoxView
var hint_label: Label
var place_label: Label
var continue_btn: Button

func setup(r: Dictionary) -> void:
	reward = r.duplicate(true)
	_ensure_nodes()
	hint_label.text = tr("streak.gift_hint") % maxi(0, int(reward.get("hint", 0)))
	place_label.text = tr("streak.gift_place") % maxi(0, int(reward.get("place", 0)))
	gift.play_idle()
	gift.call_deferred("play_open")

func _ready() -> void:
	_ensure_nodes()

func _ensure_nodes() -> void:
	if continue_btn != null:
		return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#FFF6E8"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	add_child(box)
	title_label = _label(box, tr("streak.gift_title"), 40)
	gift = GiftBoxView.create()
	gift.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(gift)
	hint_label = _label(box, "", 32)
	place_label = _label(box, "", 32)
	continue_btn = Button.new(); continue_btn.text = tr("common.continue")
	continue_btn.custom_minimum_size = Vector2(280, 72)
	continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_btn.pressed.connect(func(): continued.emit())
	box.add_child(continue_btn)

func _label(parent: Control, text: String, font_size: int) -> Label:
	var l := Label.new(); l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	parent.add_child(l)
	return l
```

`game/scenes/streak_activate.tscn` (same shape as `fail.tscn`):

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/screens/streak_activate_screen.gd" id="1_streak"]

[node name="StreakActivateScreen" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_streak")
```

`game/scenes/streak_gift.tscn`: identical, with path `res://scripts/screens/streak_gift_screen.gd` and node name `StreakGiftScreen`.

Append to `game/locale/strings.csv` (columns `key,en,ja,vi,id,pt_BR,es,ko`):

```
common.continue,Continue,つづける,Tiếp tục,Lanjut,Continuar,Continuar,계속
streak.activate_title,Streak lit!,連続記録スタート！,Chuỗi đã bừng sáng!,Rentetan menyala!,Sequência acesa!,¡Racha encendida!,연속 기록 점화!
streak.gift_title,Weekly gift!,今週のギフト！,Quà tuần này!,Hadiah mingguan!,Presente da semana!,¡Regalo semanal!,이번 주 선물!
streak.gift_hint,+%d hints,ヒント+%d,+%d gợi ý,+%d petunjuk,+%d dicas,+%d pistas,힌트 +%d
streak.gift_place,+%d candy drops,キャンディ配置+%d,+%d đặt kẹo,+%d taruh permen,+%d doces extras,+%d caramelos extra,사탕 놓기 +%d
```

Then reimport translations: `rtk godot --headless --path game --import` (regenerates `game/locale/strings.*.translation`, which are committed — same as Plan B).

- [ ] **Step 4: Run to verify it passes**

Run: `rtk godot --headless --path game --script res://tests/test_streak_activation.gd` then `rtk godot --headless --path game --script res://tests/test_localization.gd`
Expected: `STREAK_ACTIVATION_PASS`; localization suite passes.

- [ ] **Step 5: Commit**

```bash
rtk git add game/scripts/screens/streak_activate_screen.gd game/scripts/screens/streak_gift_screen.gd game/scenes/streak_activate.tscn game/scenes/streak_gift.tscn game/locale/strings.csv game/locale/strings.*.translation game/tests/test_streak_activation.gd
# plus the new *.gd.uid files if Godot created them for these scripts
rtk git commit -m "feat(streak): add activate and gift screens" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Wire flow into puzzle and app shell; remove burst and toast

**Files:**
- Modify: `game/scripts/screens/puzzle_assist_controller.gd`
- Modify: `game/scripts/campaign/screen_router.gd` (`SCENE_MAP`), `game/tests/test_screen_router.gd`
- Modify: `game/scripts/screens/app_shell.gd` (const block, var block, `_instantiate_screen`, `_on_level_done`)
- Not modified: `game/scripts/screens/puzzle_screen.gd` (300 lines; its existing `assist_ctl.on_round_finished(session, _is_custom)` calls stay as they are)
- Delete: `game/scripts/screens/streak_burst.gd` (+ `.uid`), `game/tests/test_streak_burst.gd`
- Modify: `game/locale/strings.csv` (remove `assist.reward`)
- Test: `game/tests/test_assist_flow.gd`, `game/tests/test_integration.gd`

**Interfaces:**
- Consumes: `AssistInventory.on_round_finished() -> {extended, view, reward}` (Task 1); `StreakFlow.start/next`, `view`, `reward` (Task 2); screens' `setup` + `continued` (Task 3).
- Produces: `PuzzleAssistController.round_result: Dictionary` (result of the last recorded round on this screen, `{}` when skipped or never recorded); `PuzzleAssistController.on_round_finished(session: Variant, is_custom: bool) -> Dictionary` stores and returns the Task 1 result (or `{}`); `AppShell.streak_flow` (a `StreakFlow`).

- [ ] **Step 1: Write the failing tests**

In `test_assist_flow.gd`: replace `check(screen.get_node_or_null("StreakBurst") == null, "custom win shows no burst")` with

```gdscript
	check(screen.assist_ctl.round_result.is_empty(), "custom win records no streak result")
```

and after `check(inv2.data.streakDays == 1, "resume won twice records once")` add

```gdscript
	check(screen2.assist_ctl.on_round_finished(screen2.session, false).extended == false, "same day result not extended")
	check(not FileAccess.file_exists("res://scripts/screens/streak_burst.gd"), "burst removed")
```

and after `check(inv3.data.totalStreak == 0, "restored finished round is not counted again")` add

```gdscript
	check(screen3.assist_ctl.round_result.is_empty(), "restored round has no result to show")
```

and after `check(inv3.data.totalStreak == 1, "failed round counts for streak")` add

```gdscript
	check(screen3.assist_ctl.round_result.extended, "failed round result is extended")
```

In `test_integration.gd`, `_test_screen_flow_win_and_progression`: replace

```gdscript
	_assert(shell.nav.current() == NavController.Screen.WIN, "nav moved to WIN screen")
```

with

```gdscript
	_assert(shell.nav.current() == NavController.Screen.STREAK_ACTIVATE, "first round of the day opens activate")
	var activate = shell.screen_host.get_child(0)
	_assert(activate.name == "StreakActivateScreen" and activate.count_label.text == "1", "activate shows day 1")
	activate.continue_btn.pressed.emit()
	_assert(shell.nav.current() == NavController.Screen.WIN, "continue leads to WIN screen")
```

(the later "nav moved to WIN screen for campaign complete" stays: L02 is the same day, so no activate). After `_assert(shell._last_won_level == "L01", ...)` add

```gdscript
	_assert(int(win_screen.get("_hearts_left")) == shell._last_won_hearts, "win keeps original hearts arg")
```

(`win_screen.gd` stores the hearts argument of `setup` in `_hearts_left`.)

In `_test_screen_flow_fail_and_retry`: replace

```gdscript
	_assert(shell.nav.current() == NavController.Screen.FAIL, "nav moved to FAIL screen")
```

with

```gdscript
	_assert(shell.nav.current() == NavController.Screen.STREAK_ACTIVATE, "lost first round also activates")
	shell.screen_host.get_child(0).continue_btn.pressed.emit()
	_assert(shell.nav.current() == NavController.Screen.FAIL, "nav moved to FAIL screen")
```

Add a new test function to `test_integration.gd` and call it from the runner list next to the other `await _test_...()` calls:

```gdscript
func _test_streak_day_seven_gift() -> void:
	var pdir := _create_test_profile("streak_gift")
	var shell: AppShell = load("res://scenes/main.tscn").instantiate()
	shell.profile_dir = pdir
	shell.assists = load("res://scripts/state/assist_inventory.gd").new(pdir)
	var yesterday := Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()) - 86400)
	shell.assists.data.streakDays = 6; shell.assists.data.totalStreak = 6; shell.assists.data.lastStreakDate = yesterday
	root.add_child(shell)
	await process_frame
	shell.screen_host.get_child(0)._on_play()
	var session: PlaySession = shell.runtime.current_session
	var solution: Array = session.level["solution"]
	for r in range(solution.size()):
		session.try_candy(r, int(solution[r]))
	_assert(shell.nav.current() == NavController.Screen.STREAK_ACTIVATE, "day 7: activate first")
	shell.screen_host.get_child(0).continue_btn.pressed.emit()
	_assert(shell.nav.current() == NavController.Screen.STREAK_GIFT, "day 7: gift second")
	var gift = shell.screen_host.get_child(0)
	_assert(gift.name == "StreakGiftScreen" and gift.reward.has("hint"), "gift got reward")
	gift.continue_btn.pressed.emit()
	_assert(shell.nav.current() == NavController.Screen.WIN, "day 7: win last")
	_assert(shell._last_won_level == "L01", "win label unchanged after detour")
	# Debug-picker level: custom, never activates
	shell._on_debug_level_selected(session.level.duplicate(true), "L01")
	var dsess: PlaySession = shell.runtime.current_session if shell.screen_host.get_child(0).get("session") == null else shell.screen_host.get_child(0).session
	for r in range(solution.size()):
		dsess.try_candy(r, int(solution[r]))
	_assert(shell.nav.current() == NavController.Screen.WIN, "debug level skips activate")
	root.remove_child(shell)
	shell.free()
	_clean_dir(pdir)
```

Note: `app_shell._ready` creates `assists` only when `null`, so the pre-seeded inventory is used.

- [ ] **Step 2: Run to verify they fail**

Run:
```
rtk godot --headless --path game --script res://tests/test_assist_flow.gd
rtk godot --headless --path game --script res://tests/test_integration.gd
```
Expected: FAIL (`round_result` missing; nav goes straight to WIN/FAIL).

- [ ] **Step 3: Implement**

`puzzle_assist_controller.gd`: delete the `StreakBurst` preload, `var burst_played`, the two `streak_extended` connect lines in `bind`, and `_on_streak_extended`. Update the header comment to `# Binds the assist stock to the puzzle dock: badges, place-candy, empty popup; records finished rounds.` Below `var inventory: Variant = null` add:

```gdscript
var round_result: Dictionary = {}  # last recorded round on this screen; read by app_shell's StreakFlow
```

Replace `on_round_finished`:

```gdscript
# Records the finished round; returns {extended, view, reward} for the streak screens, {} when skipped.
func on_round_finished(session: Variant, is_custom: bool) -> Dictionary:
	round_result = {}
	if inventory == null or is_custom or session == null:
		return round_result
	round_result = inventory.on_round_finished()
	return round_result
```

`puzzle_screen.gd` is not edited: its `if hold: assist_ctl.on_round_finished(session, _is_custom)` calls already skip restored rounds, so `assist_ctl.round_result` stays `{}` for them (the screen, and its controller, is re-instantiated per level).

`game/scripts/campaign/screen_router.gd`: add after the `"streak"` entry of `SCENE_MAP`:

```gdscript
	"streak_activate": "res://scenes/streak_activate.tscn",
	"streak_gift": "res://scenes/streak_gift.tscn",
```

`game/tests/test_screen_router.gd`: change the key loop to `for key in ["title", "puzzle", "win", "fail", "options", "streak", "streak_activate", "streak_gift"]:`.

`app_shell.gd` (one statement per line; must stay ≤ 300):
1. After `const ScreenRouter = preload("res://scripts/campaign/screen_router.gd")` add:

```gdscript
const StreakFlow = preload("res://scripts/campaign/streak_flow.gd")
```

2. After `var _options_overlay: Control = null` add:

```gdscript
var streak_flow := StreakFlow.new()
```

3. In `_instantiate_screen` `match to_name:` add before `"win":`

```gdscript
		"streak_activate", "streak_gift":
			if screen.has_method("setup"): screen.call("setup", streak_flow.view if to_name == "streak_activate" else streak_flow.reward)
			if screen.has_signal("continued"): screen.connect("continued", func(): nav.go_to(streak_flow.next()))
```

4. In `_on_level_done` (where `cur_sc` is already the finished puzzle screen) add, directly after the `var sess = ...` line:

```gdscript
	var streak_src: Variant = cur_sc.get("assist_ctl") if cur_sc != null else null
```

and replace the three result jumps (edit the existing lines in place):
   - debug branch: `nav.go_to(streak_flow.start(streak_src, NavController.Screen.WIN if won else NavController.Screen.FAIL))`
   - won branch: `nav.go_to(streak_flow.start(streak_src, NavController.Screen.WIN))`
   - lost branch: `nav.go_to(streak_flow.start(streak_src, NavController.Screen.FAIL))`

The Win/Fail setup args are read from `_last_won_*` / `_next_level_*` fields set before these calls and untouched by the detour, so they are unchanged. The result SFX stays tied to entering `win`/`fail`.

Run `wc -l game/scripts/screens/app_shell.gd game/scripts/screens/puzzle_screen.gd`
Expected: app_shell 291, puzzle_screen 300 (unchanged).

Remove burst and toast:

```bash
rtk git rm game/scripts/screens/streak_burst.gd game/tests/test_streak_burst.gd
rtk git rm --ignore-unmatch game/scripts/screens/streak_burst.gd.uid
```

Delete the `assist.reward,...` line from `game/locale/strings.csv` and re-run `rtk godot --headless --path game --import`. Confirm no references remain:

```bash
grep -rn "StreakBurst\|streak_burst\|assist.reward\|streak_extended\|burst_played" game --include=*.gd --include=*.tscn --include=*.csv
```
Expected: no output.

- [ ] **Step 4: Run to verify they pass**

```
rtk godot --headless --path game --script res://tests/test_assist_flow.gd
rtk godot --headless --path game --script res://tests/test_assist_inventory.gd
rtk godot --headless --path game --script res://tests/test_streak_activation.gd
rtk godot --headless --path game --script res://tests/test_integration.gd
rtk godot --headless --path game --script res://tests/test_screens.gd
rtk godot --headless --path game --script res://tests/test_localization.gd
rtk godot --headless --path game --script res://tests/test_screen_router.gd
```
Expected: each prints its PASS marker, exit 0.

- [ ] **Step 5: Commit**

```bash
rtk git add game/scripts/screens/puzzle_assist_controller.gd game/scripts/campaign/screen_router.gd game/tests/test_screen_router.gd game/scripts/screens/app_shell.gd game/locale/strings.csv game/locale/strings.*.translation game/tests/test_assist_flow.gd game/tests/test_integration.gd
# the git rm deletions are already staged
rtk git commit -m "feat(streak)!: show activate and gift screens before the result" -m "BREAKING CHANGE: AssistInventory.on_round_finished returns {extended, view, reward}; streak_extended signal and StreakBurst removed." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Decisions, gate, status, merge

**Files:**
- Modify: `docs/DECISIONS.md` (RST-031, RST-032)
- Modify: `docs/STATUS.md` (section "Kho trợ giúp và streak")

- [ ] **Step 1: Update DECISIONS** — in RST-032 replace the bullet `- **Burst +1:** ...` with:

```markdown
- **Kích hoạt chuỗi (sửa 2026-10-15, đặc tả [streak screens](superpowers/specs/2026-10-15-streak-screens-debug-design.md) §3.3):** bàn kết thúc đầu tiên trong ngày (thắng hoặc thua, không tính level custom/debug/tutorial) mở màn Kích hoạt chuỗi (lửa sáng, ô hôm nay được điền, nút Tiếp tục) → ngày 7: màn Nhận quà (hộp quà mở, +hint/+đặt kẹo) → Win/Fail như cũ. Bỏ burst +1 trên bàn.
```

In RST-031 replace `- **Hiệu ứng +1** trên bàn chơi ở lần thắng đầu tiên trong ngày; toast gói 7 ngày hiện sau.` with:

```markdown
- **Hiệu ứng ngày mới:** thay bằng màn Kích hoạt chuỗi và màn Nhận quà ngày 7 (RST-032, 2026-10-15); bỏ toast gói 7 ngày.
```

- [ ] **Step 2: Gate**

```bash
rtk python -B tools/clean_room.py
rtk python -B tools/verify.py --godot <godot-executable>
```
Expected: clean-room PASS; verify ends with full PASS. Save the log under `scratch/verification/` (verify.py writes it) and note its file name and the HEAD revision (`rtk git rev-parse --short HEAD`). If any line fails, fix within scope or record a blocker per AGENTS.md §6 — do not merge.

- [ ] **Step 3: Update STATUS** — in `docs/STATUS.md` section "Kho trợ giúp và streak", replace the line about "lửa 3 lớp có tàn và burst +1 (RST-032)" with:

```markdown
- Chuỗi tính khi một bàn kết thúc (thắng hoặc thua); lửa 3 lớp có tàn (RST-032). Bàn đầu tiên trong ngày mở màn Kích hoạt chuỗi, ngày 7 thêm màn Nhận quà, rồi Win/Fail (`feat/v1.0.1/streak-activation`, Plan A). Burst +1 và toast `assist.reward` đã gỡ.
```

and add after the "Kiểm chứng" bullet:

```markdown
- Plan A kiểm chứng: `test_streak_activation`, `test_assist_flow`, `test_assist_inventory`, `test_integration`; full verify rev `<short-rev>` (`scratch/verification/<log-file>`). Chưa QA giao diện/thiết bị cho màn Kích hoạt và Nhận quà; hộp quà vẫn là placeholder (Q7).
```

Fill `<short-rev>` and `<log-file>` with the actual values from Step 2 (never invent them).

- [ ] **Step 4: Commit docs**

```bash
rtk git add docs/DECISIONS.md docs/STATUS.md
rtk git commit -m "docs(streak): record activation and gift screens" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 5: Merge back**

```bash
rtk git checkout feat/v1.0.1/assist-inventory
rtk git merge --no-ff feat/v1.0.1/streak-activation -m "merge: streak activation plan A" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
rtk godot --headless --path game --script res://tests/test_streak_activation.gd
rtk godot --headless --path game --script res://tests/test_integration.gd
```
Expected: clean merge, both suites PASS. Do not push unless the owner asks.

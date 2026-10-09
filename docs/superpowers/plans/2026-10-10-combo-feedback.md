# Combo Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reward consecutive player-placed correct candies with a 12-tier voice cue and an animated word-art popup.

**Architecture:** A pure `ComboTracker` counts the streak; `ComboFeedback` (RefCounted) owns the tracker, one reusable `ComboPopup` node on the board and the sfx call; `puzzle_screen.gd` only forwards events to it. Word art is pre-baked offline by a Pillow script into one atlas PNG with a fixed 2×6 grid, so the runtime computes rects without parsing JSON.

**Tech Stack:** Godot 4.7 / GDScript, Python 3.12 + Pillow 12 (offline tool only).

**Spec:** `docs/superpowers/specs/2026-10-10-combo-feedback-design.md`

**Godot:** `GODOT="/c/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"` — all commands run from the worktree root `D:/Work/Alpaca_Solution/ASOL-Game-02-combo`.

## Global Constraints

- Streak +1 per player-placed correct candy; displayed level = `min(streak, 12)`.
- Mistake → 0. Hint button pressed → 0. Hint-placed candy → 0 and does not count. Mark/unmark/undo → unchanged. New level / restart / resume → 0.
- Combo voice replaces `CANDY_YES` for every counted placement (level 1 included); hint-placed candy keeps `CANDY_YES`.
- No node, texture or stream creation during play: 12 streams loaded in `SfxPlayer._ready`, one atlas preloaded, popup + particles created once per board.
- Reduced motion (`LayoutTokens.motion_enabled == false`): no pop, no rotation, no lift, no particles — show then fade.
- Files ≤ 300 lines; no autoloads; no names from the clean-room list (AGENTS.md §3); word art is original (Nunito Bold, OFL).
- Words: NICE!, GREAT!, SWEET!, AWESOME!, EXCELLENT!, AMAZING!, DELICIOUS!, INCREDIBLE!, FANTASTIC!, DIVINE!, UNSTOPPABLE!, LEGENDARY!

## Review Focus

- Two correct placements within 0.9 s → second word replaces the first cleanly (no stacked sprites, no stale tween). Test: Task 4 `_test_restart_mid_tween`.
- Candy in row 0 or the last column → popup stays inside the board. Test: Task 5 `_test_popup_clamped_to_board`.
- Hint-placed candy → streak resets, `CANDY_YES` plays, no popup. Test: Task 5 `_test_hint_candy_resets`.
- Restart mid-combo → next placement is NICE again. Test: Task 5 `_test_reset_restarts_at_one`.
- Reduced motion → popup appears at full scale with zero rotation. Test: Task 4 `_test_reduced_motion_no_pop`.

---

### Task 1: ComboTracker

**Files:**
- Create: `game/scripts/feedback/combo_tracker.gd`
- Test: `game/tests/test_combo_tracker.gd`

**Interfaces:**
- Produces: `ComboTracker.MAX_LEVEL: int = 12`, `var streak: int`, `on_correct() -> int`, `reset() -> void`.

- [ ] **Step 1: Write the failing test** — `game/tests/test_combo_tracker.gd`

```gdscript
extends SceneTree

const ComboTracker = preload("res://scripts/feedback/combo_tracker.gd")

var _fails: Array[String] = []

func _init() -> void:
	var tracker := ComboTracker.new()
	_assert(tracker.streak == 0, "starts at zero")
	_assert(tracker.on_correct() == 1, "first correct is level 1")
	_assert(tracker.on_correct() == 2, "second correct is level 2")
	tracker.reset()
	_assert(tracker.streak == 0, "reset clears streak")
	_assert(tracker.on_correct() == 1, "after reset back to level 1")
	for i in range(14): tracker.on_correct()
	_assert(tracker.streak == 15, "streak keeps counting past 12")
	_assert(tracker.on_correct() == ComboTracker.MAX_LEVEL, "level clamps to 12")
	if _fails.is_empty():
		print("COMBO_TRACKER_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)
```

- [ ] **Step 2: Run, expect FAIL** (preload error, file missing)

Run: `"$GODOT" --headless --path game --script res://tests/test_combo_tracker.gd`

- [ ] **Step 3: Implement** — `game/scripts/feedback/combo_tracker.gd`

```gdscript
# combo_tracker.gd — counts consecutive player-placed correct candies.
extends RefCounted

const MAX_LEVEL := 12

var streak: int = 0

func on_correct() -> int:
	streak += 1
	return mini(streak, MAX_LEVEL)

func reset() -> void:
	streak = 0
```

- [ ] **Step 4: Run, expect `COMBO_TRACKER_PASS`**
- [ ] **Step 5: Commit**

```bash
git add game/scripts/feedback/combo_tracker.gd game/tests/test_combo_tracker.gd
git commit -m "feat(feedback): add combo streak tracker"
```

---

### Task 2: Combo voice effects

**Files:**
- Modify: `game/scripts/feedback/sfx_catalog.gd` (enum `Effect`, `PRESETS`, new `combo_effect`)
- Add: `game/assets/audio/sfx/sfx-combo/*.ogg` + `.ogg.import` (already copied into the worktree, untracked)
- Test: `game/tests/test_feedback.gd`

**Interfaces:**
- Produces: `SfxCatalog.Effect.COMBO_1 … COMBO_12` (consecutive), `SfxCatalog.combo_effect(level: int) -> int` (clamps level to 1..12).

- [ ] **Step 1: Write the failing test** — in `test_feedback.gd` add `_test_combo_effects()` to `_run()` after `_test_catalog_complete()`:

```gdscript
func _test_combo_effects() -> void:
	_assert(SfxCatalog.combo_effect(1) == SfxCatalog.Effect.COMBO_1, "combo 1 maps to COMBO_1")
	_assert(SfxCatalog.combo_effect(12) == SfxCatalog.Effect.COMBO_12, "combo 12 maps to COMBO_12")
	_assert(SfxCatalog.combo_effect(40) == SfxCatalog.Effect.COMBO_12, "combo clamps high")
	_assert(SfxCatalog.combo_effect(0) == SfxCatalog.Effect.COMBO_1, "combo clamps low")
	for level in range(1, 13):
		var preset: Dictionary = SfxCatalog.PRESETS.get(SfxCatalog.combo_effect(level), {})
		_assert(preset.get("type", "") == "file", "combo %d is a file preset" % level)
		_assert(ResourceLoader.exists(str(preset.get("path", ""))), "combo %d audio exists" % level)
```

- [ ] **Step 2: Run, expect FAIL** — `"$GODOT" --headless --path game --script res://tests/test_feedback.gd`
- [ ] **Step 3: Implement** — append to the `Effect` enum after `HINT_WRONG_MARK,`:

```gdscript
	COMBO_1, COMBO_2, COMBO_3, COMBO_4, COMBO_5, COMBO_6,     # combo voice, levels 1–6
	COMBO_7, COMBO_8, COMBO_9, COMBO_10, COMBO_11, COMBO_12,  # combo voice, levels 7–12
```

Add above `PRESETS`:

```gdscript
const COMBO_DIR := "res://assets/audio/sfx/sfx-combo/"
```

Add inside `PRESETS` (before its closing `}`):

```gdscript
	Effect.COMBO_1: {"type": "file", "path": COMBO_DIR + "1-nice.ogg"},
	Effect.COMBO_2: {"type": "file", "path": COMBO_DIR + "2-great.ogg"},
	Effect.COMBO_3: {"type": "file", "path": COMBO_DIR + "3-sweet.ogg"},
	Effect.COMBO_4: {"type": "file", "path": COMBO_DIR + "4-awesome.ogg"},
	Effect.COMBO_5: {"type": "file", "path": COMBO_DIR + "5-excellent.ogg"},
	Effect.COMBO_6: {"type": "file", "path": COMBO_DIR + "6-amazing.ogg"},
	Effect.COMBO_7: {"type": "file", "path": COMBO_DIR + "7-delicious.ogg"},
	Effect.COMBO_8: {"type": "file", "path": COMBO_DIR + "8-incredible.ogg"},
	Effect.COMBO_9: {"type": "file", "path": COMBO_DIR + "9-fantastic.ogg"},
	Effect.COMBO_10: {"type": "file", "path": COMBO_DIR + "10-devine.ogg"},
	Effect.COMBO_11: {"type": "file", "path": COMBO_DIR + "11-unstoppable.ogg"},
	Effect.COMBO_12: {"type": "file", "path": COMBO_DIR + "12-legendary.ogg"},
```

Append at end of file:

```gdscript
static func combo_effect(level: int) -> int:
	return Effect.COMBO_1 + clampi(level, 1, 12) - 1
```

`SfxPlayer._ready` already loads `"type": "file"` presets once; no change there.

- [ ] **Step 4: Run, expect `FEEDBACK_PASS`**; also run `test_sfx_tuner.gd` if present (it iterates effects).
- [ ] **Step 5: Commit**

```bash
git add game/scripts/feedback/sfx_catalog.gd game/tests/test_feedback.gd game/assets/audio/sfx/sfx-combo
git commit -m "feat(feedback): add 12-level combo voice effects"
```

---

### Task 3: Combo word-art atlas tool

**Files:**
- Create: `tools/build_combo_atlas.py`
- Create: `tools/tests/test_build_combo_atlas.py`
- Generate: `game/assets/ui/combo/combo_atlas.png`, `game/assets/ui/combo/combo_atlas.json`, `combo_atlas.png.import`

**Interfaces:**
- Produces: atlas 1024×768 RGBA, frame 512×128, 2 columns × 6 rows; level `n` (1-based) at `x = ((n-1) % 2) * 512`, `y = ((n-1) // 2) * 128`. JSON: `{"frame": [512, 128], "cols": 2, "words": {"1": "NICE!", …}}`.

- [ ] **Step 1: Write the failing test** — `tools/tests/test_build_combo_atlas.py`

```python
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import build_combo_atlas as atlas  # noqa: E402


class TestComboAtlas(unittest.TestCase):
    def test_twelve_words(self):
        self.assertEqual(len(atlas.WORDS), 12)
        self.assertEqual(atlas.WORDS[0], "NICE!")
        self.assertEqual(atlas.WORDS[11], "LEGENDARY!")

    def test_frame_rects_in_bounds_and_distinct(self):
        rects = [atlas.frame_rect(n) for n in range(1, 13)]
        self.assertEqual(len(set(rects)), 12)
        for x, y, w, h in rects:
            self.assertLessEqual(x + w, atlas.ATLAS_SIZE[0])
            self.assertLessEqual(y + h, atlas.ATLAS_SIZE[1])

    def test_render_has_ink_in_every_frame(self):
        image = atlas.render()
        self.assertEqual(image.size, atlas.ATLAS_SIZE)
        for n in range(1, 13):
            x, y, w, h = atlas.frame_rect(n)
            self.assertIsNotNone(image.crop((x, y, x + w, y + h)).getbbox(), f"frame {n} empty")

    def test_committed_atlas_matches_layout(self):
        self.assertEqual(atlas.check(), [])


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run, expect FAIL** — `python -B -m unittest tools/tests/test_build_combo_atlas.py`
- [ ] **Step 3: Implement** — `tools/build_combo_atlas.py`

```python
"""Offline tool: bakes the combo word art into one atlas PNG for the game.

Run: python -B tools/build_combo_atlas.py [--check]
"""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
FONT = ROOT / "game/assets/fonts/Nunito-Bold.ttf"
OUT_DIR = ROOT / "game/assets/ui/combo"
OUT_PNG = OUT_DIR / "combo_atlas.png"
OUT_JSON = OUT_DIR / "combo_atlas.json"
WORDS = ["NICE!", "GREAT!", "SWEET!", "AWESOME!", "EXCELLENT!", "AMAZING!",
         "DELICIOUS!", "INCREDIBLE!", "FANTASTIC!", "DIVINE!", "UNSTOPPABLE!", "LEGENDARY!"]
FRAME = (512, 128)
COLS = 2
ATLAS_SIZE = (FRAME[0] * COLS, FRAME[1] * (len(WORDS) // COLS))
MAX_TEXT_W = 470
MAX_FONT = 92
STROKE = 9
OUTLINE = (74, 32, 22, 255)
SHADOW = (40, 14, 10, 150)
# (top, bottom) fill per tier: 1–4 candy pink, 5–8 orange sherbet, 9–12 gold.
TIERS = [((255, 226, 238), (255, 110, 170)),
         ((255, 236, 140), (255, 120, 60)),
         ((255, 250, 190), (240, 170, 0))]


def frame_rect(level):
    index = level - 1
    return ((index % COLS) * FRAME[0], (index // COLS) * FRAME[1], FRAME[0], FRAME[1])


def _font_for(word):
    size = MAX_FONT
    while size > 24:
        font = ImageFont.truetype(str(FONT), size)
        left, _, right, _ = font.getbbox(word, stroke_width=STROKE)
        if right - left <= MAX_TEXT_W:
            return font
        size -= 2
    return ImageFont.truetype(str(FONT), size)


def _gradient(top, bottom):
    strip = Image.new("RGBA", (1, FRAME[1]))
    for y in range(FRAME[1]):
        t = y / (FRAME[1] - 1)
        strip.putpixel((0, y), tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)) + (255,))
    return strip.resize(FRAME)


def render_word(level):
    word = WORDS[level - 1]
    font = _font_for(word)
    center = (FRAME[0] // 2, FRAME[1] // 2 - 4)
    frame = Image.new("RGBA", FRAME, (0, 0, 0, 0))
    shadow = Image.new("RGBA", FRAME, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).text((center[0], center[1] + 6), word, font=font, anchor="mm",
                                fill=SHADOW, stroke_width=STROKE, stroke_fill=SHADOW)
    frame.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(2)))
    ImageDraw.Draw(frame).text(center, word, font=font, anchor="mm", fill=OUTLINE,
                               stroke_width=STROKE, stroke_fill=OUTLINE)
    mask = Image.new("L", FRAME, 0)
    ImageDraw.Draw(mask).text(center, word, font=font, anchor="mm", fill=255)
    top, bottom = TIERS[(level - 1) // 4]
    frame.paste(_gradient(top, bottom), (0, 0), mask)
    return frame


def render():
    image = Image.new("RGBA", ATLAS_SIZE, (0, 0, 0, 0))
    for level in range(1, len(WORDS) + 1):
        x, y, _, _ = frame_rect(level)
        image.alpha_composite(render_word(level), (x, y))
    return image


def manifest():
    return {"frame": list(FRAME), "cols": COLS,
            "words": {str(i + 1): word for i, word in enumerate(WORDS)}}


def check():
    errors = []
    if not OUT_PNG.exists() or not OUT_JSON.exists():
        return ["combo atlas missing; run tools/build_combo_atlas.py"]
    with Image.open(OUT_PNG) as image:
        if image.size != ATLAS_SIZE:
            errors.append(f"atlas size {image.size} != {ATLAS_SIZE}")
    if json.loads(OUT_JSON.read_text(encoding="utf-8")) != manifest():
        errors.append("combo_atlas.json out of date")
    return errors


def main():
    if "--check" in sys.argv:
        errors = check()
        for error in errors:
            print(error, file=sys.stderr)
        return 1 if errors else 0
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    render().save(OUT_PNG, optimize=True)
    OUT_JSON.write_text(json.dumps(manifest(), indent=2) + "\n", encoding="utf-8")
    print(f"wrote {OUT_PNG.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 4: Generate and import**

```bash
python -B tools/build_combo_atlas.py
"$GODOT" --headless --path game --import
```

Open `game/assets/ui/combo/combo_atlas.png` and look at it (Read tool) — 12 legible words, three colour tiers.

- [ ] **Step 5: Run, expect 4 tests OK** — `python -B -m unittest tools/tests/test_build_combo_atlas.py`
- [ ] **Step 6: Commit**

```bash
git add tools/build_combo_atlas.py tools/tests/test_build_combo_atlas.py game/assets/ui/combo
git commit -m "feat(assets): bake combo word-art atlas"
```

---

### Task 4: ComboPopup node

**Files:**
- Create: `game/scripts/screens/combo_popup.gd`
- Test: `game/tests/test_combo_popup.gd`

**Interfaces:**
- Consumes: atlas layout from Task 3 (frame 512×128, 2 cols).
- Produces: `ComboPopup.FRAME: Vector2`, `static frame_rect(level: int) -> Rect2`, `show_combo(level: int, at: Vector2, base_scale: float) -> void`, `hide_combo() -> void`, `is_showing() -> bool`, `current_level() -> int`, `sprite() -> Sprite2D`.

- [ ] **Step 1: Write the failing test** — `game/tests/test_combo_popup.gd`

```gdscript
extends SceneTree

const ComboPopup = preload("res://scripts/screens/combo_popup.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _fails: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_frame_rects()
	_test_show_selects_word()
	_test_restart_mid_tween()
	_test_reduced_motion_no_pop()
	await _test_hides_after_animation()
	if _fails.is_empty():
		print("COMBO_POPUP_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _make() -> ComboPopup:
	var popup := ComboPopup.new()
	root.add_child(popup)
	return popup

func _test_frame_rects() -> void:
	_assert(ComboPopup.frame_rect(1) == Rect2(0, 0, 512, 128), "level 1 rect")
	_assert(ComboPopup.frame_rect(4) == Rect2(512, 128, 512, 128), "level 4 rect")
	_assert(ComboPopup.frame_rect(12) == Rect2(512, 640, 512, 128), "level 12 rect")
	_assert(ComboPopup.frame_rect(99) == ComboPopup.frame_rect(12), "rect clamps")

func _test_show_selects_word() -> void:
	var popup := _make()
	_assert(not popup.is_showing(), "hidden before first combo")
	popup.show_combo(3, Vector2(200, 100), 1.0)
	_assert(popup.is_showing(), "visible after show")
	_assert(popup.sprite().region_rect == ComboPopup.frame_rect(3), "shows level 3 word")
	_assert(popup.position == Vector2(200, 100), "placed at anchor")
	popup.queue_free()

func _test_restart_mid_tween() -> void:
	var popup := _make()
	var children := popup.get_child_count()
	popup.show_combo(1, Vector2.ZERO, 1.0)
	popup.show_combo(2, Vector2(10, 10), 1.0)
	_assert(popup.get_child_count() == children, "no extra nodes per combo")
	_assert(popup.current_level() == 2, "latest combo wins")
	_assert(popup.sprite().modulate.a == 1.0, "restart resets fade")
	popup.queue_free()

func _test_reduced_motion_no_pop() -> void:
	var popup := _make()
	LayoutTokens.set_motion(false)
	popup.show_combo(10, Vector2.ZERO, 0.8)
	_assert(popup.sprite().scale == Vector2.ONE * 0.8, "full scale immediately")
	_assert(popup.sprite().rotation == 0.0, "no tilt")
	LayoutTokens.set_motion(true)
	popup.queue_free()

func _test_hides_after_animation() -> void:
	var popup := _make()
	popup.show_combo(9, Vector2.ZERO, 1.0)
	var start := Time.get_ticks_msec()
	while popup.is_showing() and Time.get_ticks_msec() - start < 2000:
		await process_frame
	_assert(not popup.is_showing(), "hides after animation")
	popup.queue_free()

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)
```

- [ ] **Step 2: Run, expect FAIL** — `"$GODOT" --headless --path game --script res://tests/test_combo_popup.gd`
- [ ] **Step 3: Implement** — `game/scripts/screens/combo_popup.gd`

```gdscript
# combo_popup.gd — one reusable sprite that pops the combo word art over the board.
extends Node2D

const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const ATLAS: Texture2D = preload("res://assets/ui/combo/combo_atlas.png")
const FRAME := Vector2(512, 128)
const COLS := 2
const MAX_LEVEL := 12
const SPARKLE_LEVEL := 9
const LIFT := 40.0
const TILT_DEG := 6.0

var _sprite: Sprite2D
var _sparkles: CPUParticles2D
var _tween: Tween
var _level: int = 0

func _init() -> void:
	z_index = 20
	_sprite = Sprite2D.new()
	_sprite.texture = ATLAS
	_sprite.region_enabled = true
	_sprite.visible = false
	add_child(_sprite)
	_sparkles = CPUParticles2D.new()
	_sparkles.emitting = false
	_sparkles.one_shot = true
	_sparkles.amount = 12
	_sparkles.lifetime = 0.6
	_sparkles.explosiveness = 1.0
	_sparkles.direction = Vector2.UP
	_sparkles.spread = 180.0
	_sparkles.initial_velocity_min = 120.0
	_sparkles.initial_velocity_max = 220.0
	_sparkles.gravity = Vector2(0, 320)
	_sparkles.scale_amount_min = 4.0
	_sparkles.scale_amount_max = 8.0
	_sparkles.color = Color(1.0, 0.86, 0.35)
	add_child(_sparkles)

static func frame_rect(level: int) -> Rect2:
	var index := clampi(level, 1, MAX_LEVEL) - 1
	return Rect2(Vector2(index % COLS, index / COLS) * FRAME, FRAME)

func sprite() -> Sprite2D: return _sprite
func current_level() -> int: return _level
func is_showing() -> bool: return _sprite.visible

func show_combo(level: int, at: Vector2, base_scale: float) -> void:
	if _tween != null: _tween.kill()
	_level = level
	position = at
	_sprite.region_rect = frame_rect(level)
	_sprite.position = Vector2.ZERO
	_sprite.modulate.a = 1.0
	_sprite.rotation = 0.0
	_sprite.scale = Vector2.ONE * base_scale
	_sprite.visible = true
	_tween = create_tween()
	if LayoutTokens.motion_enabled:
		_sprite.scale = Vector2.ONE * base_scale * 0.3
		_sprite.rotation = deg_to_rad(TILT_DEG if level % 2 == 1 else -TILT_DEG)
		_tween.tween_property(_sprite, "scale", Vector2.ONE * base_scale * 1.15, 0.14) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween.parallel().tween_property(_sprite, "rotation", 0.0, 0.2)
		_tween.tween_property(_sprite, "scale", Vector2.ONE * base_scale, 0.08)
		_tween.tween_interval(0.33)
		_tween.tween_property(_sprite, "position:y", -LIFT, 0.35).set_ease(Tween.EASE_IN)
		_tween.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.35)
		if level >= SPARKLE_LEVEL: _sparkles.restart()
	else:
		_tween.tween_interval(0.5)
		_tween.tween_property(_sprite, "modulate:a", 0.0, 0.3)
	_tween.tween_callback(hide_combo)

func hide_combo() -> void:
	if _tween != null and _tween.is_valid(): _tween.kill()
	_tween = null
	_sprite.visible = false
	_sparkles.emitting = false
```

- [ ] **Step 4: Run, expect `COMBO_POPUP_PASS`**
- [ ] **Step 5: Commit**

```bash
git add game/scripts/screens/combo_popup.gd game/tests/test_combo_popup.gd
git commit -m "feat(screens): add reusable combo word popup"
```

---

### Task 5: Wire combo into the puzzle screen

**Files:**
- Create: `game/scripts/screens/combo_feedback.gd`
- Modify: `game/scripts/screens/puzzle_hint_coordinator.gd` (`apply_hint`, new `is_applying`)
- Modify: `game/scripts/screens/puzzle_screen.gd` (`setup`, `_on_candy_found`, `_on_mistake`, `_on_hint`, `_confirm_restart`)
- Test: `game/tests/test_combo_feedback.gd`
- Docs: `docs/DECISIONS.md`, `docs/STATUS.md`

**Interfaces:**
- Consumes: `ComboTracker` (Task 1), `SfxCatalog.combo_effect` (Task 2), `ComboPopup` (Task 4), board `get_cell_rect(row, col) -> Rect2` and `size`.
- Produces: `ComboFeedback.bind(board: Control, sfx: Variant)`, `reset()`, `on_candy(row: int, col: int, from_hint: bool) -> int`; `PuzzleHintCoordinator.is_applying() -> bool`.

- [ ] **Step 1: Write the failing test** — `game/tests/test_combo_feedback.gd`

```gdscript
extends SceneTree

const ComboFeedback = preload("res://scripts/screens/combo_feedback.gd")
const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")

class FakeBoard extends Control:
	func get_cell_rect(row: int, col: int) -> Rect2:
		return Rect2(col * 100, row * 100, 100, 100)

class FakeSfx extends RefCounted:
	var played: Array = []
	func play(effect: int, _force: bool = false) -> void: played.append(effect)

var _fails: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_streak_plays_voice_and_popup()
	_test_hint_candy_resets()
	_test_reset_restarts_at_one()
	_test_popup_clamped_to_board()
	if _fails.is_empty():
		print("COMBO_FEEDBACK_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _make() -> Array:
	var board := FakeBoard.new()
	board.size = Vector2(600, 600)
	root.add_child(board)
	var sfx := FakeSfx.new()
	var combo := ComboFeedback.new()
	combo.bind(board, sfx)
	return [combo, sfx, board]

func _test_streak_plays_voice_and_popup() -> void:
	var parts := _make(); var combo = parts[0]; var sfx = parts[1]
	_assert(combo.on_candy(2, 2, false) == 1, "first is level 1")
	_assert(combo.on_candy(3, 3, false) == 2, "second is level 2")
	_assert(sfx.played == [SfxCatalog.Effect.COMBO_1, SfxCatalog.Effect.COMBO_2], "voices replace CANDY_YES")
	_assert(combo.popup.is_showing() and combo.popup.current_level() == 2, "popup shows level 2")
	parts[2].queue_free()

func _test_hint_candy_resets() -> void:
	var parts := _make(); var combo = parts[0]; var sfx = parts[1]
	combo.on_candy(1, 1, false)
	combo.popup.hide_combo()
	_assert(combo.on_candy(2, 2, true) == 0, "hint candy is not a combo")
	_assert(sfx.played.back() == SfxCatalog.Effect.CANDY_YES, "hint candy keeps CANDY_YES")
	_assert(not combo.popup.is_showing(), "no popup for hint candy")
	_assert(combo.on_candy(3, 3, false) == 1, "streak restarted after hint")
	parts[2].queue_free()

func _test_reset_restarts_at_one() -> void:
	var parts := _make(); var combo = parts[0]
	combo.on_candy(0, 1, false); combo.on_candy(1, 3, false)
	combo.reset()
	_assert(not combo.popup.is_showing(), "reset hides popup")
	_assert(combo.on_candy(2, 0, false) == 1, "after reset back to NICE")
	parts[2].queue_free()

func _test_popup_clamped_to_board() -> void:
	var parts := _make(); var combo = parts[0]
	combo.on_candy(0, 5, false)
	var half: Vector2 = combo.popup.sprite().region_rect.size * combo.popup.sprite().scale * 0.5
	_assert(combo.popup.position.x + half.x <= 600.0 + 0.01, "right edge inside board")
	_assert(combo.popup.position.y - half.y >= -0.01, "top edge inside board")
	combo.on_candy(0, 0, false)
	_assert(combo.popup.position.x - half.x >= -0.01, "left edge inside board")
	parts[2].queue_free()

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)
```

- [ ] **Step 2: Run, expect FAIL** — `"$GODOT" --headless --path game --script res://tests/test_combo_feedback.gd`
- [ ] **Step 3: Implement** — `game/scripts/screens/combo_feedback.gd`

```gdscript
# combo_feedback.gd — joins the combo streak to its voice cue and word-art popup.
extends RefCounted

const ComboTracker = preload("res://scripts/feedback/combo_tracker.gd")
const ComboPopup = preload("res://scripts/screens/combo_popup.gd")
const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")
const WIDTH_SHARE := 0.8 # word art spans at most this share of the board width
const RISE := 0.4 # popup centre sits this many cell heights above the cell top

var tracker := ComboTracker.new()
var popup: ComboPopup
var _board: Control
var _sfx: Variant

func bind(board: Control, sfx: Variant) -> void:
	_sfx = sfx
	if board == _board: return
	_board = board
	popup = ComboPopup.new()
	board.add_child(popup)

func reset() -> void:
	tracker.reset()
	if popup != null: popup.hide_combo()

# Returns the combo level shown, or 0 when the candy came from a hint.
func on_candy(row: int, col: int, from_hint: bool) -> int:
	if from_hint:
		reset()
		if _sfx != null: _sfx.play(SfxCatalog.Effect.CANDY_YES)
		return 0
	var level := tracker.on_correct()
	if _sfx != null: _sfx.play(SfxCatalog.combo_effect(level))
	if popup != null and _board != null:
		var width := _board.size.x
		var base_scale := minf(1.0, width * WIDTH_SHARE / ComboPopup.FRAME.x)
		var half := ComboPopup.FRAME * base_scale * 0.5
		var cell: Rect2 = _board.get_cell_rect(row, col)
		var at := Vector2(clampf(cell.get_center().x, half.x, maxf(half.x, width - half.x)),
			maxf(cell.position.y - cell.size.y * RISE, half.y))
		popup.show_combo(level, at, base_scale)
	return level
```

In `puzzle_hint_coordinator.gd` add a member near the other `var`s and wrap the candy placement in `apply_hint`:

```gdscript
var _applying: bool = false
func is_applying() -> bool: return _applying
```

```gdscript
			"PLACE_CANDY", "REVEAL":
				var cell: Array = hint["target_cell"]
				_applying = true
				target_session.try_candy(cell[0], cell[1])
				_applying = false
```

In `puzzle_screen.gd`:

```gdscript
const ComboFeedback = preload("res://scripts/screens/combo_feedback.gd")
var combo := ComboFeedback.new()
```

In `setup`, after `_ensure_nodes()`: `if board != null: combo.bind(board, sfx)` then `combo.reset()`.
In `_confirm_restart`, after `hint_coordinator.force_release()`: `combo.reset()`.
In `_on_hint`, after the null check: `combo.reset()`.
In `_on_mistake`, first line: `combo.reset()`.
In `_on_candy_found` replace `sfx.play(SfxCatalog.Effect.CANDY_YES)` with:

```gdscript
	var from_hint := hint_coordinator.is_applying()
	combo.on_candy(row, col, from_hint)
	if sfx != null:
```

so the block reads `combo.on_candy(...)` then `if sfx != null:` followed by the existing progress-milestone lines (without the `CANDY_YES` line). Keep `puzzle_screen.gd` ≤ 300 lines.

- [ ] **Step 4: Run, expect `COMBO_FEEDBACK_PASS`**; then rerun `test_screens.gd`, `test_integration.gd`, `test_feedback.gd`.
- [ ] **Step 5: Docs** — append to `docs/DECISIONS.md` (follow its existing entry format):
  "2026-10-10 — Combo: +1 per player-placed correct candy, 12 voiced tiers (cap 12); resets on mistake, hint use, hint-placed candy, new level/restart/resume. Voice replaces CANDY_YES. Word art baked by `tools/build_combo_atlas.py`."
  In `docs/STATUS.md` add a line under current work: combo feedback implemented on `feat/v1.0.1/combo-feedback`, headless gate result, device QA pending.
- [ ] **Step 6: Full gate**

```bash
rtk proxy rg -n "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/
rtk proxy rg -n "extracted_reusable" game/scripts/ game/tests/
python -B tools/build_combo_atlas.py --check
rtk python -B tools/verify.py --godot "$GODOT"
```

Expected: no rg matches, check exit 0, verify all PASS.

- [ ] **Step 7: Commit**

```bash
git add game/scripts/screens/combo_feedback.gd game/scripts/screens/puzzle_hint_coordinator.gd game/scripts/screens/puzzle_screen.gd game/tests/test_combo_feedback.gd docs/DECISIONS.md docs/STATUS.md
git commit -m "feat(screens): play combo voice and word art on consecutive correct candies"
```

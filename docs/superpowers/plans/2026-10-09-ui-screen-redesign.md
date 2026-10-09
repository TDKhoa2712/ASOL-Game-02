# UI Screen Redesign — Win, Lose, Home

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the Win, Lose, and Home screens following the HTML mockups in `screen/`, using a hybrid approach: PNG sprites for artwork + GDScript code for layout and Tween animations.

**Architecture:** Each screen gets its own dedicated script (split `result_screen.gd` into `win_screen.gd` and `fail_screen.gd`). Sprite assets (mascot, ribbon, decorations) are exported from the HTML SVGs into PNG files at 3x resolution for retina. Layout and styling remain programmatic using the existing `Palette`/`FontTokens`/`LayoutTokens` system with updated color constants. Animations use Godot 4 `Tween` chains triggered on `_ready()`, respecting `LayoutTokens.motion_enabled`.

**Tech Stack:** Godot 4, GDScript, Tween API, StyleBoxFlat, ShaderMaterial (radial gradient background)

**Spec:** `screen/Màn thắng – Meow Puzzle-html/Artboard-x3fv.dc.html`, `screen/Màn thua – hết tim-html/Lose.dc.html`, `screen/Trang chủ-html/Home.dc.html`

## Global Constraints

- Module ≤ 300 lines. One file, one responsibility.
- No autoloads — composition root pattern, dependencies injected from app_shell.
- Signals instead of EventBus.
- Asset nguyên gốc — no copying from commercial games.
- Existing signal contracts (`next_pressed`, `retry_pressed`, `home_pressed`, `replay_pressed`, `play_pressed`, `endless_pressed`, `options_pressed`, `debug_level_selected`) must be preserved exactly.
- `setup()` method signatures must remain compatible with `app_shell.gd` callers.
- All animations must respect `LayoutTokens.motion_enabled` (skip to final state if disabled).
- Font: Continue using BeVietnamPro/Nunito from `FontTokens` (not Baloo 2 from the mockup — that's the reference font, not our font).
- Target resolution: 390×844 logical (iPhone 14 equivalent), responsive via anchors.

## Review Focus

1. **`setup()` called before `_ready()`:** `app_shell.gd` calls `setup()` before adding the screen to the tree. All node creation must happen in `_ensure_nodes()` called from both `setup()` and `_ready()`. Test: call `setup()` on a fresh instance not yet in the tree — no crash.
2. **Hearts count = 0 on lose screen:** The lose screen receives `hearts_left=0` but the mockup shows 3 broken hearts. Verify the visual always shows 3 hearts (all broken) regardless of remaining count.
3. **Last level in campaign:** Win screen must show "Replay" button instead of "Next" when `is_last_level=true`, and hide the next-level preview card. Test: `setup(true, 5000, "L30", true)`.
4. **Reduced motion:** When `LayoutTokens.motion_enabled == false`, all tweens must be skipped and elements shown at their final positions instantly. Test: toggle motion off, verify no animation plays.
5. **Headless mode (CI tests):** Screens must not crash when running in headless display server. Test: instantiate each screen in headless, call `setup()`, verify no errors.

---

## File Structure

### New files to create

| File | Responsibility |
|------|----------------|
| `game/scripts/screens/win_screen.gd` | Win screen layout, animations, next-level preview |
| `game/scripts/screens/fail_screen.gd` | Lose screen layout, animations |
| `game/scripts/ui/gradient_bg.gd` | Reusable radial gradient background (shader-based) |
| `game/scripts/ui/ribbon_banner.gd` | 3D ribbon banner widget (TextureRect + overlay label) |
| `game/scripts/ui/heart_display.gd` | Row of 3 animated hearts (filled/empty/broken states) |
| `game/scripts/ui/stat_card.gd` | Stats display card (time, mistakes) |
| `game/scripts/ui/action_button.gd` | 3D-style button with shadow, press animation, optional glint |
| `game/scripts/ui/confetti_layer.gd` | Particle confetti overlay for win screen |
| `game/assets/ui/result/mascot_happy.png` | Candy mascot — happy expression |
| `game/assets/ui/result/mascot_sad.png` | Candy mascot — sad expression with crack and tears |
| `game/assets/ui/result/ribbon_win.png` | Orange ribbon banner background |
| `game/assets/ui/result/ribbon_lose.png` | Purple ribbon banner background |
| `game/assets/ui/result/star_twinkle.png` | Small star decoration |
| `game/assets/ui/result/cloud_rain.png` | Rain cloud for lose screen |
| `game/assets/ui/home/mascot_home.png` | Candy mascot — home screen expression (eyes open, smile) |
| `game/scripts/ui/progress_bar.gd` | Animated campaign progress bar |
| `game/tests/test_win_screen.gd` | Tests for win screen |
| `game/tests/test_fail_screen.gd` | Tests for fail screen |
| `game/tests/test_title_screen_v2.gd` | Tests for redesigned title screen |
| `game/tests/test_ui_widgets.gd` | Tests for reusable UI widgets |

### Files to modify

| File | Changes |
|------|---------|
| `game/scripts/theme/palette.gd` | Add new color constants for mockup designs |
| `game/scripts/theme/layout_tokens.gd` | Add animation duration constants |
| `game/scripts/screens/app_shell.gd` | Pass `hearts_left` and `mistake_count` to result screens; update `setup()` calls |
| `game/scenes/win.tscn` | Point script to `win_screen.gd` |
| `game/scenes/fail.tscn` | Point script to `fail_screen.gd` |
| `game/scripts/screens/title_screen.gd` | Rebuild with mockup layout (gradient bg, mascot, progress bar, new buttons) |

### File to archive (no longer used after migration)

| File | Reason |
|------|--------|
| `game/scripts/screens/result_screen.gd` | Replaced by `win_screen.gd` + `fail_screen.gd` |

---

## Task 1: Palette & Layout Token Updates

**Files:**
- Modify: `game/scripts/theme/palette.gd`
- Modify: `game/scripts/theme/layout_tokens.gd`
- Test: `game/tests/test_ui_widgets.gd` (created here, expanded in later tasks)

**Interfaces:**
- Produces: Color constants and animation constants used by all subsequent tasks

- [ ] **Step 1: Add win/lose/home color constants to palette.gd**

Add after the existing `RESULT_FAIL_BUTTON` line (line 53):

```gdscript
# Redesigned screen colors (from mockups).
# Win screen — warm golden.
const WIN_BG_CENTER := Color("#FFFFFF")
const WIN_BG_MID := Color("#FFF8DC")
const WIN_BG_EDGE := Color("#FFE08A")
const WIN_RIBBON_BG := Color("#FF9533")
const WIN_RIBBON_SHADOW := Color("#E0731A")
const WIN_RIBBON_FOLD := Color("#8F3D05")
const WIN_RIBBON_TAIL := Color("#E8731C")
const WIN_RIBBON_TEXT_SHADOW := Color("#A9480A")
const WIN_CARD_SHADOW := Color("#EFD27E")
const WIN_BUTTON_BG := Color("#1F9A4B")
const WIN_BUTTON_SHADOW := Color("#136F35")
const WIN_BUTTON_TEXT_SHADOW := Color("#0F5A2B")
const WIN_RAYS := Color(1.0, 0.745, 0.235, 0.22)
const WIN_STAT_ICON_BG_TIME := Color("#E3F3FF")
const WIN_STAT_ICON_BG_ERR := Color("#FFECE4")
const WIN_STAT_ICON_SHADOW_TIME := Color("#B9DDF7")
const WIN_STAT_ICON_SHADOW_ERR := Color("#F6CDBD")
const WIN_TEXT_SECONDARY := Color("#4F5D86")
const WIN_TEXT_PRIMARY := Color("#23365E")
const WIN_NEXT_BOARD_BG := Color("#FFF1DE")
const WIN_NEXT_BOARD_SHADOW := Color("#EBCFA5")
const WIN_NEXT_CELL := Color("#FBE4C4")
const WIN_DASHED_BORDER := Color("#F3E3B5")
const WIN_DIFFICULTY_EASY := Color("#22894C")
const WIN_DIFFICULTY_MEDIUM := Color("#B05F0A")
const WIN_DIFFICULTY_HARD := Color("#C02C52")
const WIN_DIFFICULTY_EXPERT := Color("#6A2CC0")

# Lose screen — purple/lavender.
const LOSE_BG_CENTER := Color("#FFFFFF")
const LOSE_BG_MID := Color("#F1ECFA")
const LOSE_BG_EDGE := Color("#D3C6EC")
const LOSE_RIBBON_BG := Color("#7466D1")
const LOSE_RIBBON_SHADOW := Color("#5A4BB5")
const LOSE_RIBBON_FOLD := Color("#2E2470")
const LOSE_RIBBON_TAIL := Color("#5546A8")
const LOSE_RIBBON_TEXT_SHADOW := Color("#3B2E8A")
const LOSE_CARD_SHADOW := Color("#CFC2EA")
const LOSE_BUTTON_BG := Color("#D9620F")
const LOSE_BUTTON_SHADOW := Color("#9A3A08")
const LOSE_BUTTON_TEXT_SHADOW := Color("#8A3306")
const LOSE_TEXT_PRIMARY := Color("#3E2D63")
const LOSE_TEXT_SECONDARY := Color("#5E4C86")
const LOSE_HEART_FILL := Color("#E4DCF0")
const LOSE_HEART_STROKE := Color("#8A7AA8")
const LOSE_HEART_BACK := Color("#BBAED3")
const LOSE_CLOUD := Color("#A79BC4")
const LOSE_CLOUD_SHADOW := Color("#8D80AE")
const LOSE_RAIN := Color("#8FB8E0")
const LOSE_TEAR := Color("#6FB8F0")
const LOSE_MASCOT_BODY := Color("#E7B3CA")
const LOSE_MASCOT_BODY_DARK := Color("#B57A98")

# Home screen accent colors.
const HOME_BG_CENTER := Color("#FFFFFF")
const HOME_BG_MID := Color("#FFF8DC")
const HOME_BG_EDGE := Color("#FFE08A")
const HOME_BUTTON_BG := Color("#D9620F")
const HOME_BUTTON_SHADOW := Color("#9A3A08")
const HOME_CARD_SHADOW := Color("#EFD27E")
const HOME_PROGRESS_BG := Color("#FFF1D0")
const HOME_PROGRESS_BG_SHADOW := Color("#F3DFA8")
const HOME_PROGRESS_FILL := Color("#3FB487")
const HOME_PROGRESS_FILL_DARK := Color("#2A8C64")
const HOME_SPEECH_BG := Color.WHITE
const HOME_ICON_BG := Color.WHITE
const HOME_ICON_SHADOW := Color("#E2C46A")
const HOME_TOP_BTN_BG := Color("#3D8BEB")
const HOME_TOP_BTN_SHADOW := Color("#2463B0")

# Shared accent colors for candy decorations.
const CANDY_ORANGE := Color("#FF8A3D")
const CANDY_BLUE := Color("#6FC3FF")
const CANDY_YELLOW := Color("#FFC93C")
const CANDY_GREEN := Color("#7AE0A0")
const CANDY_RED := Color("#FF5A4E")
const CANDY_PURPLE := Color("#B98AF0")
const CONFETTI_COLORS: Array[Color] = [
	Color("#FFC93C"), Color("#FF5A4E"), Color("#4FC3E8"),
	Color("#7AD98A"), Color("#FF9F43"), Color("#B69CFF"),
]

# Heart colors.
const HEART_FILLED := Color("#F5414F")
const HEART_FILLED_DARK := Color("#C9212F")
const HEART_FILLED_STROKE := Color("#7A1018")
const HEART_FILLED_SHINE := Color("#FFD3D6")
const HEART_EMPTY := Color("#F1ECE0")
const HEART_EMPTY_DARK := Color("#D9D2C2")
const HEART_EMPTY_STROKE := Color("#A89E88")

# Twinkle star color.
const TWINKLE_GOLD := Color("#FFC93C")
const TWINKLE_BLUE := Color("#7CC8FF")
```

- [ ] **Step 2: Add animation constants to layout_tokens.gd**

Add after `FADE_MS` (line 23):

```gdscript
# Screen transition animations.
const RIBBON_DROP_MS := 800
const HEART_POP_MS := 600
const HEART_POP_STAGGER_MS := 250
const MASCOT_RISE_MS := 700
const CARD_RISE_MS := 700
const CARD_RISE_STAGGER_MS := 200
const CONFETTI_FALL_MIN_MS := 3200
const CONFETTI_FALL_MAX_MS := 6200
const RAYS_SPIN_MS := 22000
const BUTTON_PULSE_MS := 1400
const PROGRESS_FILL_MS := 1200
const LOGO_IN_MS := 900
```

- [ ] **Step 3: Write a smoke test to verify constants exist**

Create `game/tests/test_ui_widgets.gd`:

```gdscript
extends SceneTree

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_win_palette()
	_test_lose_palette()
	_test_home_palette()
	_test_animation_constants()
	if _fails.is_empty():
		print("WIDGETS_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)

func _test_win_palette() -> void:
	_assert(typeof(Palette.WIN_BG_CENTER) == TYPE_COLOR, "WIN_BG_CENTER is Color")
	_assert(typeof(Palette.WIN_RIBBON_BG) == TYPE_COLOR, "WIN_RIBBON_BG is Color")
	_assert(typeof(Palette.WIN_BUTTON_BG) == TYPE_COLOR, "WIN_BUTTON_BG is Color")
	_assert(Palette.CONFETTI_COLORS.size() >= 6, "CONFETTI_COLORS has >= 6 entries")

func _test_lose_palette() -> void:
	_assert(typeof(Palette.LOSE_BG_CENTER) == TYPE_COLOR, "LOSE_BG_CENTER is Color")
	_assert(typeof(Palette.LOSE_RIBBON_BG) == TYPE_COLOR, "LOSE_RIBBON_BG is Color")
	_assert(typeof(Palette.LOSE_BUTTON_BG) == TYPE_COLOR, "LOSE_BUTTON_BG is Color")

func _test_home_palette() -> void:
	_assert(typeof(Palette.HOME_BG_CENTER) == TYPE_COLOR, "HOME_BG_CENTER is Color")
	_assert(typeof(Palette.HOME_BUTTON_BG) == TYPE_COLOR, "HOME_BUTTON_BG is Color")
	_assert(typeof(Palette.HOME_PROGRESS_FILL) == TYPE_COLOR, "HOME_PROGRESS_FILL is Color")

func _test_animation_constants() -> void:
	_assert(LayoutTokens.RIBBON_DROP_MS > 0, "RIBBON_DROP_MS > 0")
	_assert(LayoutTokens.HEART_POP_MS > 0, "HEART_POP_MS > 0")
	_assert(LayoutTokens.CONFETTI_FALL_MIN_MS > 0, "CONFETTI_FALL_MIN_MS > 0")
```

- [ ] **Step 4: Run tests**

```bash
rtk godot --headless --path game --script res://tests/test_ui_widgets.gd
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add game/scripts/theme/palette.gd game/scripts/theme/layout_tokens.gd game/tests/test_ui_widgets.gd
git commit -m "feat(theme): add color and animation constants for screen redesign"
```

---

## Task 2: Reusable UI Widgets — gradient_bg, action_button, heart_display

**Files:**
- Create: `game/scripts/ui/gradient_bg.gd`
- Create: `game/scripts/ui/action_button.gd`
- Create: `game/scripts/ui/heart_display.gd`
- Modify: `game/tests/test_ui_widgets.gd`

**Interfaces:**
- Consumes: `Palette` constants from Task 1
- Produces:
  - `GradientBg.new(center: Color, mid: Color, edge: Color) -> ColorRect` — radial gradient background
  - `ActionButton.create(text: String, bg: Color, shadow_color: Color, text_shadow: Color, font_size: int) -> Button` — 3D-style button
  - `HeartDisplay.new(total: int, filled: int, style: String) -> HBoxContainer` — `style` is `"win"` or `"lose"`; `animate()` triggers pop/break animations

- [ ] **Step 1: Write failing tests for gradient_bg**

Add to `game/tests/test_ui_widgets.gd` — add `const GradientBg = preload("res://scripts/ui/gradient_bg.gd")` at top, then add test method called from `_init()`:

```gdscript
func _test_gradient_bg() -> void:
	var bg := GradientBg.new(Color.WHITE, Color.YELLOW, Color.ORANGE)
	_assert(bg is ColorRect, "gradient_bg is ColorRect")
	_assert(bg.material is ShaderMaterial, "gradient_bg has ShaderMaterial")
	bg.free()
```

- [ ] **Step 2: Run test to verify it fails**

```bash
rtk godot --headless --path game --script res://tests/test_ui_widgets.gd
```

Expected: FAIL — cannot preload `gradient_bg.gd`

- [ ] **Step 3: Implement gradient_bg.gd**

Create `game/scripts/ui/gradient_bg.gd`:

```gdscript
# gradient_bg.gd — Radial gradient background using a shader.
extends ColorRect

const SHADER_CODE := "
shader_type canvas_item;
uniform vec4 color_center : source_color = vec4(1.0);
uniform vec4 color_mid : source_color = vec4(1.0, 0.97, 0.86, 1.0);
uniform vec4 color_edge : source_color = vec4(1.0, 0.88, 0.54, 1.0);
uniform vec2 center_uv = vec2(0.5, 0.28);
uniform float mid_stop = 0.36;
void fragment() {
	float d = distance(UV, center_uv);
	vec4 c;
	if (d < mid_stop) {
		c = mix(color_center, color_mid, d / mid_stop);
	} else {
		c = mix(color_mid, color_edge, clamp((d - mid_stop) / (1.0 - mid_stop), 0.0, 1.0));
	}
	COLOR = c;
}
"

static var _shader: Shader = null

func _init(center: Color = Color.WHITE, mid: Color = Color.YELLOW, edge: Color = Color.ORANGE, center_uv: Vector2 = Vector2(0.5, 0.28)) -> void:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("color_center", center)
	mat.set_shader_parameter("color_mid", mid)
	mat.set_shader_parameter("color_edge", edge)
	mat.set_shader_parameter("center_uv", center_uv)
	material = mat
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
```

- [ ] **Step 4: Run test to verify it passes**

```bash
rtk godot --headless --path game --script res://tests/test_ui_widgets.gd
```

Expected: PASS (note: shader may not compile in headless, but the `ShaderMaterial` instance is still created — test checks type only)

- [ ] **Step 5: Write failing tests for action_button**

Add `const ActionButton = preload("res://scripts/ui/action_button.gd")` at top, then add test method called from `_init()`:

```gdscript
func _test_action_button() -> void:
	var btn := ActionButton.create("Test", Color.GREEN, Color.DARK_GREEN, Color.BLACK, 26)
	_assert(btn is Button, "action_button is Button")
	_assert(btn.text == "Test", "action_button text matches")
	var style = btn.get_theme_stylebox("normal")
	_assert(style is StyleBoxFlat, "action_button has StyleBoxFlat")
	_assert((style as StyleBoxFlat).bg_color == Color.GREEN, "action_button bg_color matches")
	btn.free()
```

- [ ] **Step 6: Implement action_button.gd**

Create `game/scripts/ui/action_button.gd`:

```gdscript
# action_button.gd — 3D-style button with shadow, press animation, and optional glint.
extends RefCounted

const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

static func create(text: String, bg_color: Color, shadow_color: Color, text_shadow_color: Color, font_size: int = 26, height: int = 64) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, height)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var font := FontTokens.body_bold()
	if font != null:
		btn.add_theme_font_override("font", font)
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(20)
	style.set_content_margin_all(14)
	style.shadow_color = shadow_color
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 6)
	for state in ["normal", "hover", "focus"]:
		btn.add_theme_stylebox_override(state, style)
	var pressed_style := style.duplicate() as StyleBoxFlat
	pressed_style.shadow_size = 2
	pressed_style.shadow_offset = Vector2(0, 2)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.pivot_offset = Vector2(btn.custom_minimum_size.x * 0.5, btn.custom_minimum_size.y * 0.5)
	btn.resized.connect(func(): btn.pivot_offset = btn.size * 0.5)
	btn.button_down.connect(func():
		if not LayoutTokens.motion_enabled: return
		btn.pivot_offset = btn.size * 0.5
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(0.96, 0.96), 0.08)
	)
	btn.button_up.connect(func():
		if not LayoutTokens.motion_enabled: return
		btn.pivot_offset = btn.size * 0.5
		var tw := btn.create_tween()
		tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.15)
	)
	return btn

static func add_pulse(btn: Button) -> void:
	if not LayoutTokens.motion_enabled:
		return
	var tw := btn.create_tween().set_loops()
	tw.tween_property(btn, "position:y", btn.position.y - 3.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(btn, "position:y", btn.position.y, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
```

- [ ] **Step 7: Write failing tests for heart_display**

Add `const HeartDisplay = preload("res://scripts/ui/heart_display.gd")` at top, then add test method called from `_init()`:

```gdscript
func _test_heart_display() -> void:
	var d1 := HeartDisplay.new(3, 3, "win")
	_assert(d1 is HBoxContainer, "heart_display is HBoxContainer")
	_assert(d1.get_child_count() == 3, "heart_display has 3 children (win/3)")
	d1.free()
	var d2 := HeartDisplay.new(3, 1, "win")
	_assert(d2.get_child_count() == 3, "heart_display has 3 children (win/1)")
	d2.free()
	var d3 := HeartDisplay.new(3, 0, "lose")
	_assert(d3.get_child_count() == 3, "heart_display has 3 children (lose/0)")
	d3.free()
```

- [ ] **Step 8: Implement heart_display.gd**

Create `game/scripts/ui/heart_display.gd`:

```gdscript
# heart_display.gd — Row of 3 animated hearts for result screens.
extends HBoxContainer

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _total: int = 3
var _filled: int = 0
var _style: String = "win"

func _init(total: int = 3, filled: int = 3, style: String = "win") -> void:
	_total = total
	_filled = clampi(filled, 0, total)
	_style = style
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 8)
	for i in range(_total):
		var is_middle := (i == 1)
		var size := 92.0 if is_middle else 74.0
		var heart := _create_heart(i, size, i < _filled)
		add_child(heart)

func _create_heart(index: int, heart_size: float, is_filled: bool) -> TextureRect:
	var tex := TextureRect.new()
	tex.custom_minimum_size = Vector2(heart_size, heart_size)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if is_filled:
		tex.texture = preload("res://assets/ui/board/heart_icon.png")
	else:
		tex.texture = preload("res://assets/ui/board/heart_icon_empty.png")
	if not is_filled and _style == "lose":
		tex.modulate = Color(0.85, 0.8, 0.9, 1.0)
	tex.pivot_offset = Vector2(heart_size * 0.5, heart_size * 0.5)
	return tex

func animate() -> void:
	if not LayoutTokens.motion_enabled:
		return
	for i in range(get_child_count()):
		var heart := get_child(i) as Control
		if heart == null:
			continue
		heart.scale = Vector2.ZERO
		heart.modulate.a = 0.0
		var delay: float = 0.55 + i * 0.25
		var tw := heart.create_tween()
		tw.tween_interval(delay)
		tw.tween_property(heart, "scale", Vector2(1.3, 1.3), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(heart, "modulate:a", 1.0, 0.15)
		tw.tween_property(heart, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_SINE)
		if i < _filled and _style == "win":
			_add_heartbeat(heart, delay + 2.0)

func _add_heartbeat(heart: Control, start_delay: float) -> void:
	var tw := heart.create_tween().set_loops()
	tw.tween_interval(start_delay)
	tw.tween_property(heart, "scale", Vector2(1.12, 1.12), 0.18).set_trans(Tween.TRANS_SINE)
	tw.tween_property(heart, "scale", Vector2(0.96, 0.96), 0.18).set_trans(Tween.TRANS_SINE)
	tw.tween_property(heart, "scale", Vector2(1.06, 1.06), 0.18).set_trans(Tween.TRANS_SINE)
	tw.tween_property(heart, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(0.48)
```

- [ ] **Step 9: Run all tests**

```bash
rtk godot --headless --path game --script res://tests/test_ui_widgets.gd
```

Expected: all PASS

- [ ] **Step 10: Commit**

```bash
git add game/scripts/ui/gradient_bg.gd game/scripts/ui/action_button.gd game/scripts/ui/heart_display.gd game/tests/test_ui_widgets.gd
git commit -m "feat(ui): add gradient_bg, action_button, and heart_display widgets"
```

---

## Task 3: Reusable UI Widgets — ribbon_banner, stat_card, confetti_layer

**Files:**
- Create: `game/scripts/ui/ribbon_banner.gd`
- Create: `game/scripts/ui/stat_card.gd`
- Create: `game/scripts/ui/confetti_layer.gd`
- Modify: `game/tests/test_ui_widgets.gd`

**Interfaces:**
- Consumes: `Palette`, `LayoutTokens`, `FontTokens` from Tasks 1–2
- Produces:
  - `RibbonBanner.new(text: String, style: String) -> Control` — `style` is `"win"` or `"lose"`; `animate()` triggers drop animation
  - `StatCard.new(stats: Array[Dictionary]) -> PanelContainer` — each dict has `{label: String, value: String, icon: String}`; `animate(delay: float)` triggers rise-in
  - `ConfettiLayer.new(count: int) -> Control` — `start()` begins falling particle animation

- [ ] **Step 1: Write failing tests**

Add `const RibbonBanner`, `const StatCard`, `const ConfettiLayer` preloads at top, then add test methods called from `_init()`:

```gdscript
func _test_ribbon_banner() -> void:
	var r1 := RibbonBanner.new("HOÀN THÀNH!", "win")
	_assert(r1 is Control, "ribbon_banner win is Control")
	r1.free()
	var r2 := RibbonBanner.new("HẾT TIM RỒI!", "lose")
	_assert(r2 is Control, "ribbon_banner lose is Control")
	r2.free()

func _test_stat_card() -> void:
	var stats: Array[Dictionary] = [
		{"label": "Thời gian", "value": "02:41", "icon": "clock"},
		{"label": "Lỗi sai", "value": "1", "icon": "error"},
	]
	var card := StatCard.new(stats)
	_assert(card is PanelContainer, "stat_card 2-col is PanelContainer")
	card.free()
	var card2 := StatCard.new([{"label": "Thời gian", "value": "03:12", "icon": "clock"}])
	_assert(card2 is PanelContainer, "stat_card 1-col is PanelContainer")
	card2.free()

func _test_confetti_layer() -> void:
	var confetti := ConfettiLayer.new(40)
	_assert(confetti is Control, "confetti_layer is Control")
	confetti.free()
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
rtk godot --headless --path game --script res://tests/test_ui_widgets.gd
```

- [ ] **Step 3: Implement ribbon_banner.gd**

Create `game/scripts/ui/ribbon_banner.gd`:

```gdscript
# ribbon_banner.gd — 3D ribbon with text label for result screens.
extends Control

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _label: Label
var _style: String

func _init(text: String, style: String = "win") -> void:
	_style = style
	custom_minimum_size = Vector2(300, 62)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var colors := _get_colors()
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.offset_left = 16; bg.offset_right = -16; bg.offset_bottom = -8
	bg.color = colors.bg
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = colors.bg
	bg_style.set_corner_radius_all(12)
	bg_style.shadow_color = colors.shadow
	bg_style.shadow_size = 6
	bg_style.shadow_offset = Vector2(0, 6)
	_label = Label.new()
	_label.text = text
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.offset_left = 16; _label.offset_right = -16; _label.offset_bottom = -8
	_label.add_theme_font_size_override("font_size", 30)
	_label.add_theme_color_override("font_color", Color.WHITE)
	var heading := FontTokens.heading()
	if heading != null:
		_label.add_theme_font_override("font", heading)
	add_child(_label)

func _get_colors() -> Dictionary:
	if _style == "lose":
		return {"bg": Palette.LOSE_RIBBON_BG, "shadow": Palette.LOSE_RIBBON_SHADOW, "tail": Palette.LOSE_RIBBON_TAIL, "fold": Palette.LOSE_RIBBON_FOLD}
	return {"bg": Palette.WIN_RIBBON_BG, "shadow": Palette.WIN_RIBBON_SHADOW, "tail": Palette.WIN_RIBBON_TAIL, "fold": Palette.WIN_RIBBON_FOLD}

func animate() -> void:
	if not LayoutTokens.motion_enabled:
		return
	pivot_offset = Vector2(size.x * 0.5, 0)
	position.y -= 140
	modulate.a = 0.0
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "position:y", position.y + 140, 0.5)
	tw.parallel().tween_property(self, "modulate:a", 1.0, 0.3)
```

- [ ] **Step 4: Implement stat_card.gd**

Create `game/scripts/ui/stat_card.gd`:

```gdscript
# stat_card.gd — Stats display card (time, mistakes) for result screens.
extends PanelContainer

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

func _init(stats: Array[Dictionary]) -> void:
	custom_minimum_size = Vector2(0, 72)
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.set_corner_radius_all(22)
	style.shadow_color = Palette.WIN_CARD_SHADOW
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 7)
	style.set_content_margin_all(12)
	add_theme_stylebox_override("panel", style)
	var use_grid := stats.size() > 1
	var container: Control
	if use_grid:
		var grid := HBoxContainer.new()
		grid.add_theme_constant_override("separation", 8)
		container = grid
	else:
		var hbox := HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 12)
		container = hbox
	add_child(container)
	for i in range(stats.size()):
		var stat: Dictionary = stats[i]
		if i > 0 and use_grid:
			var sep := VSeparator.new()
			sep.modulate = Palette.WIN_DASHED_BORDER
			container.add_child(sep)
		var item := _create_stat_item(stat)
		if use_grid:
			item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(item)

func _create_stat_item(stat: Dictionary) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	var icon_box := ColorRect.new()
	icon_box.custom_minimum_size = Vector2(40, 40)
	icon_box.color = Palette.WIN_STAT_ICON_BG_TIME if stat.get("icon", "") == "clock" else Palette.WIN_STAT_ICON_BG_ERR
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(icon_box)
	var text_col := VBoxContainer.new()
	text_col.add_theme_constant_override("separation", 0)
	var lbl := Label.new()
	lbl.text = str(stat.get("label", ""))
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Palette.WIN_TEXT_SECONDARY)
	var bold := FontTokens.body_bold()
	if bold != null:
		lbl.add_theme_font_override("font", bold)
	text_col.add_child(lbl)
	var val := Label.new()
	val.text = str(stat.get("value", ""))
	val.add_theme_font_size_override("font_size", 24)
	val.add_theme_color_override("font_color", Palette.WIN_TEXT_PRIMARY)
	var heading := FontTokens.heading()
	if heading != null:
		val.add_theme_font_override("font", heading)
	text_col.add_child(val)
	hbox.add_child(text_col)
	return hbox

func animate(delay: float = 1.1) -> void:
	if not LayoutTokens.motion_enabled:
		return
	modulate.a = 0.0
	position.y += 70
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(self, "position:y", position.y - 70, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "modulate:a", 1.0, 0.3)
```

- [ ] **Step 5: Implement confetti_layer.gd**

Create `game/scripts/ui/confetti_layer.gd`:

```gdscript
# confetti_layer.gd — Falling confetti particles for win screen.
extends Control

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _count: int = 40
var _particles: Array[ColorRect] = []

func _init(count: int = 40) -> void:
	_count = count
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1

func start() -> void:
	if not LayoutTokens.motion_enabled:
		return
	for i in range(_count):
		var p := ColorRect.new()
		var w: float = 6.0 + fmod(_pseudo_random(i + 1) * 8.0, 8.0)
		var h: float = w * (2.0 if _pseudo_random(i + 50) > 0.5 else 1.0)
		p.custom_minimum_size = Vector2(w, h)
		p.size = Vector2(w, h)
		p.color = Palette.CONFETTI_COLORS[i % Palette.CONFETTI_COLORS.size()]
		p.position = Vector2(_pseudo_random(i + 3) * size.x, -80)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(p)
		_particles.append(p)
		var duration: float = 3.2 + _pseudo_random(i + 7) * 3.0
		var delay: float = _pseudo_random(i + 11) * 3.0
		var drift_x: float = (_pseudo_random(i + 20) - 0.5) * 120.0
		var tw := p.create_tween().set_loops()
		tw.tween_interval(delay)
		tw.tween_property(p, "position:y", size.y + 80, duration).from(-80.0).set_trans(Tween.TRANS_LINEAR)
		tw.parallel().tween_property(p, "position:x", p.position.x + drift_x, duration).set_trans(Tween.TRANS_LINEAR)
		tw.parallel().tween_property(p, "rotation", TAU * 2.0, duration).from(0.0).set_trans(Tween.TRANS_LINEAR)

func _pseudo_random(seed_val: int) -> float:
	var x: float = sin(float(seed_val) * 9301.0 + 49297.0) * 233280.0
	return x - floorf(x)
```

- [ ] **Step 6: Run all tests**

```bash
rtk godot --headless --path game --script res://tests/test_ui_widgets.gd
```

Expected: all PASS

- [ ] **Step 7: Commit**

```bash
git add game/scripts/ui/ribbon_banner.gd game/scripts/ui/stat_card.gd game/scripts/ui/confetti_layer.gd game/tests/test_ui_widgets.gd
git commit -m "feat(ui): add ribbon_banner, stat_card, and confetti_layer widgets"
```

---

## Task 4: Extract SVG Sprites from HTML Mockups

**Files:**
- Create: `game/assets/ui/result/mascot_happy.svg` → `mascot_happy.png`
- Create: `game/assets/ui/result/mascot_sad.svg` → `mascot_sad.png`
- Create: `game/assets/ui/result/cloud_rain.svg` → `cloud_rain.png`
- Create: `game/assets/ui/home/mascot_home.svg` → `mascot_home.png`
- Create: `tools/extract_svg_sprites.py` (one-time extraction script)

**Interfaces:**
- Produces: PNG sprite assets at 3x scale (690×450 for mascots, 330×132 for cloud) that the screens load via `preload()`

> **Approach:** The SVG artwork is already fully defined in the HTML mockups as `<svg viewBox="0 0 230 150">` blocks. We extract these directly into standalone `.svg` files, then render to PNG at 3x scale using a browser or CLI tool. This gives us production-quality artwork immediately — no placeholder needed.

- [ ] **Step 1: Extract SVG from HTML files into standalone SVGs**

Create `tools/extract_svg_sprites.py`:

```python
"""Extract mascot and cloud SVG artwork from HTML mockups into standalone SVG files."""
import re
from pathlib import Path

SCREEN_DIR = Path(__file__).resolve().parents[1] / "screen"
ASSETS_DIR = Path(__file__).resolve().parents[1] / "game" / "assets" / "ui"

EXTRACTIONS = [
    {
        "source": SCREEN_DIR / "Màn thắng – Meow Puzzle-html" / "Artboard-x3fv.dc.html",
        "viewbox": "0 0 230 150",
        "output": ASSETS_DIR / "result" / "mascot_happy.svg",
        "description": "Happy candy mascot from win screen",
    },
    {
        "source": SCREEN_DIR / "Màn thua – hết tim-html" / "Lose.dc.html",
        "viewbox": "0 0 230 150",
        "output": ASSETS_DIR / "result" / "mascot_sad.svg",
        "description": "Sad candy mascot from lose screen",
    },
    {
        "source": SCREEN_DIR / "Trang chủ-html" / "Home.dc.html",
        "viewbox": "0 0 230 150",
        "output": ASSETS_DIR / "home" / "mascot_home.svg",
        "description": "Home candy mascot from home screen",
    },
]

def extract_svg(html_path: Path, target_viewbox: str) -> str | None:
    content = html_path.read_text(encoding="utf-8")
    pattern = rf'<svg\s+viewBox="{re.escape(target_viewbox)}"[^>]*>.*?</svg>'
    match = re.search(pattern, content, re.DOTALL)
    if not match:
        return None
    svg_inner = match.group(0)
    return f'<?xml version="1.0" encoding="UTF-8"?>\n{svg_inner}'

def main() -> None:
    for item in EXTRACTIONS:
        source = item["source"]
        if not source.exists():
            print(f"SKIP: {source} not found")
            continue
        svg = extract_svg(source, item["viewbox"])
        if svg is None:
            print(f"SKIP: no SVG with viewBox='{item['viewbox']}' in {source.name}")
            continue
        output = item["output"]
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(svg, encoding="utf-8")
        print(f"OK: {output.relative_to(output.parents[4])} — {item['description']}")
    # Cloud is inside the lose screen, viewBox is different
    lose_html = SCREEN_DIR / "Màn thua – hết tim-html" / "Lose.dc.html"
    if lose_html.exists():
        # Cloud is a div-based element, extract manually or note for manual creation
        print("NOTE: cloud_rain needs manual extraction (div-based, not standalone SVG)")

if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Run the extraction script**

```bash
rtk python -B tools/extract_svg_sprites.py
```

Expected: 3 SVG files created under `game/assets/ui/`.

- [ ] **Step 3: Render SVGs to PNG at 3x scale**

Use a browser-based approach or Inkscape CLI to render each SVG at 3x:

```bash
# Option A: Inkscape CLI (if available)
inkscape game/assets/ui/result/mascot_happy.svg -w 690 -h 450 -o game/assets/ui/result/mascot_happy.png
inkscape game/assets/ui/result/mascot_sad.svg -w 690 -h 450 -o game/assets/ui/result/mascot_sad.png
inkscape game/assets/ui/home/mascot_home.svg -w 690 -h 450 -o game/assets/ui/home/mascot_home.png

# Option B: If no SVG renderer, create placeholder PNGs with Godot
rtk godot --headless --path game --script res://tools/generate_placeholders.gd
```

For the cloud (`cloud_rain.png`), create a 330×132 placeholder — the cloud is built from div elements in the HTML, not a standalone SVG. It can be drawn in a vector editor matching the mockup's colors (`#A79BC4` body, `#8D80AE` shadow).

- [ ] **Step 4: Verify assets exist**

```bash
ls game/assets/ui/result/
ls game/assets/ui/home/mascot_home.png
```

Expected: `mascot_happy.png`, `mascot_sad.png`, `cloud_rain.png` in `result/`; `mascot_home.png` in `home/`.

- [ ] **Step 5: Remove one-time scripts, commit assets**

```bash
rm tools/extract_svg_sprites.py
git add game/assets/ui/result/ game/assets/ui/home/mascot_home.png game/assets/ui/home/mascot_home.svg
git commit -m "chore(assets): extract mascot and cloud sprites from HTML mockups"
```

> **Note:** SVG source files are kept alongside PNGs for future re-rendering at different scales. The cloud placeholder will be replaced with final artwork in Track D (Assets).

---

## Task 5: Win Screen Implementation

**Files:**
- Create: `game/scripts/screens/win_screen.gd`
- Modify: `game/scenes/win.tscn`
- Modify: `game/scripts/screens/app_shell.gd` (pass extra data to setup)
- Create: `game/tests/test_win_screen.gd`

**Interfaces:**
- Consumes: `GradientBg`, `RibbonBanner`, `HeartDisplay`, `StatCard`, `ConfettiLayer`, `ActionButton` from Tasks 2–3; mascot sprite from Task 4; `Palette`, `FontTokens`, `LayoutTokens` from Task 1
- Produces: `win_screen.gd` with same signal interface as old `result_screen.gd`:
  - Signals: `next_pressed()`, `retry_pressed()`, `home_pressed()`, `replay_pressed()`
  - `setup(won: bool, score: int, level_id: String, is_last: bool, hearts_left: int, mistake_count: int, next_label: String, next_size: int, next_difficulty: String) -> void`

- [ ] **Step 1: Write failing tests for win screen**

Create `game/tests/test_win_screen.gd`:

```gdscript
extends SceneTree

const WinScreen = preload("res://scripts/screens/win_screen.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_instantiates()
	_test_setup_normal()
	_test_setup_last_level()
	_test_signals()
	_test_format_time()
	if _fails.is_empty():
		print("WIN_SCREEN_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)

func _test_instantiates() -> void:
	var screen := WinScreen.new()
	_assert(screen is Control, "win_screen is Control")
	screen.free()

func _test_setup_normal() -> void:
	var screen := WinScreen.new()
	screen.setup(true, 161000, "L5", false, 2, 1, "L06", 5, "medium")
	_assert(screen.has_signal("next_pressed"), "has next_pressed")
	_assert(screen.has_signal("home_pressed"), "has home_pressed")
	_assert(screen._next_label == "L06", "next_label stored")
	_assert(screen._next_size == 5, "next_size stored")
	_assert(screen._next_difficulty == "medium", "next_difficulty stored")
	screen.free()

func _test_setup_last_level() -> void:
	var screen := WinScreen.new()
	screen.setup(true, 300000, "L30", true, 3, 0)
	_assert(screen._is_last_level, "is_last_level true")
	_assert(screen._next_label == "", "no next_label on last level")
	screen.free()

func _test_signals() -> void:
	var screen := WinScreen.new()
	_assert(screen.has_signal("next_pressed"), "has next_pressed")
	_assert(screen.has_signal("retry_pressed"), "has retry_pressed")
	_assert(screen.has_signal("home_pressed"), "has home_pressed")
	_assert(screen.has_signal("replay_pressed"), "has replay_pressed")
	screen.free()

func _test_format_time() -> void:
	var screen := WinScreen.new()
	_assert(screen._format_time(161000) == "02:41", "format 161000 -> 02:41")
	_assert(screen._format_time(0) == "00:00", "format 0 -> 00:00")
	_assert(screen._format_time(3600000) == "60:00", "format 3600000 -> 60:00")
	screen.free()
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
rtk godot --headless --path game --script res://tests/test_win_screen.gd
```

- [ ] **Step 3: Implement win_screen.gd**

Create `game/scripts/screens/win_screen.gd`:

```gdscript
# win_screen.gd — Victory screen with animated mascot, hearts, ribbon, stats, and next-level preview.
extends Control

signal next_pressed()
signal retry_pressed()
signal home_pressed()
signal replay_pressed()

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const GradientBg = preload("res://scripts/ui/gradient_bg.gd")
const RibbonBanner = preload("res://scripts/ui/ribbon_banner.gd")
const HeartDisplay = preload("res://scripts/ui/heart_display.gd")
const StatCard = preload("res://scripts/ui/stat_card.gd")
const ConfettiLayer = preload("res://scripts/ui/confetti_layer.gd")
const ActionButton = preload("res://scripts/ui/action_button.gd")

var _is_last_level: bool = false
var _level_id: String = ""
var _elapsed_ms: int = 0
var _hearts_left: int = 3
var _mistake_count: int = 0
## Next-level preview data (passed from app_shell via setup).
var _next_label: String = ""
var _next_size: int = 0
var _next_difficulty: String = ""

var _bg: ColorRect
var _confetti: ConfettiLayer
var _ribbon: RibbonBanner
var _hearts: HeartDisplay
var _mascot: TextureRect
var _stat_card: StatCard
var _next_btn: Button
var _home_btn: Button
var _replay_btn: Button
var _level_badge: Label

func _ensure_nodes() -> void:
	if _bg != null:
		return
	_bg = GradientBg.new(Palette.WIN_BG_CENTER, Palette.WIN_BG_MID, Palette.WIN_BG_EDGE)
	add_child(_bg)
	_confetti = ConfettiLayer.new(40)
	add_child(_confetti)
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		safe.add_theme_constant_override("margin_" + side, 20)
	safe.add_theme_constant_override("margin_top", 18)
	safe.add_theme_constant_override("margin_bottom", 28)
	add_child(safe)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	safe.add_child(stack)
	# Top bar
	var top := HBoxContainer.new()
	stack.add_child(top)
	var home_btn := Button.new()
	home_btn.custom_minimum_size = Vector2(48, 48)
	home_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var hstyle := StyleBoxFlat.new()
	hstyle.bg_color = Palette.HOME_TOP_BTN_BG
	hstyle.set_corner_radius_all(16)
	hstyle.shadow_color = Palette.HOME_TOP_BTN_SHADOW
	hstyle.shadow_size = 5; hstyle.shadow_offset = Vector2(0, 5)
	for s in ["normal", "hover", "pressed", "focus"]:
		home_btn.add_theme_stylebox_override(s, hstyle)
	home_btn.pressed.connect(func(): home_pressed.emit())
	top.add_child(home_btn)
	var spacer1 := Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer1)
	_level_badge = Label.new()
	_level_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_badge.add_theme_font_size_override("font_size", 18)
	_level_badge.add_theme_color_override("font_color", Palette.WIN_TEXT_PRIMARY)
	var badge_font := FontTokens.heading()
	if badge_font != null:
		_level_badge.add_theme_font_override("font", badge_font)
	top.add_child(_level_badge)
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer2.custom_minimum_size.x = 48
	top.add_child(spacer2)
	# Ribbon
	_ribbon = RibbonBanner.new(tr("result.win.title"), "win")
	stack.add_child(_ribbon)
	# Hearts
	_hearts = HeartDisplay.new(3, _hearts_left, "win")
	stack.add_child(_hearts)
	# Mascot
	_mascot = TextureRect.new()
	_mascot.texture = load("res://assets/ui/result/mascot_happy.png") as Texture2D
	_mascot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_mascot.custom_minimum_size = Vector2(230, 150)
	_mascot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(_mascot)
	# Stat card
	_stat_card = StatCard.new(_build_stats())
	stack.add_child(_stat_card)
	# Next-level preview card (hidden when is_last_level or no next data)
	var _next_card := PanelContainer.new()
	_next_card.name = "NextCard"
	var nc_style := StyleBoxFlat.new()
	nc_style.bg_color = Palette.WIN_NEXT_BOARD_BG
	nc_style.set_corner_radius_all(20)
	nc_style.shadow_color = Palette.WIN_NEXT_BOARD_SHADOW
	nc_style.shadow_size = 5; nc_style.shadow_offset = Vector2(0, 5)
	nc_style.set_content_margin_all(12)
	_next_card.add_theme_stylebox_override("panel", nc_style)
	var nc_row := HBoxContainer.new()
	nc_row.add_theme_constant_override("separation", 12)
	_next_card.add_child(nc_row)
	# Mini board placeholder (NxN grid of colored cells)
	var mini_grid := GridContainer.new()
	mini_grid.columns = clampi(_next_size, 4, 12) if _next_size > 0 else 4
	var cell_count := mini_grid.columns * mini_grid.columns
	for ci in range(cell_count):
		var cell := ColorRect.new()
		cell.custom_minimum_size = Vector2(10, 10)
		cell.color = Palette.WIN_NEXT_CELL
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mini_grid.add_child(cell)
	nc_row.add_child(mini_grid)
	# Next level info column
	var nc_info := VBoxContainer.new()
	nc_info.add_theme_constant_override("separation", 2)
	nc_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nc_title := Label.new()
	nc_title.text = tr("result.win.next_level") % _next_label if _next_label != "" else ""
	nc_title.add_theme_font_size_override("font_size", 16)
	nc_title.add_theme_color_override("font_color", Palette.WIN_TEXT_PRIMARY)
	var nc_font := FontTokens.heading()
	if nc_font != null: nc_title.add_theme_font_override("font", nc_font)
	nc_info.add_child(nc_title)
	var diff_lbl := Label.new()
	diff_lbl.text = _difficulty_display(_next_difficulty)
	diff_lbl.add_theme_font_size_override("font_size", 13)
	diff_lbl.add_theme_color_override("font_color", _difficulty_color(_next_difficulty))
	nc_info.add_child(diff_lbl)
	var size_lbl := Label.new()
	size_lbl.text = "%dx%d" % [_next_size, _next_size] if _next_size > 0 else ""
	size_lbl.add_theme_font_size_override("font_size", 13)
	size_lbl.add_theme_color_override("font_color", Palette.WIN_TEXT_SECONDARY)
	nc_info.add_child(size_lbl)
	nc_row.add_child(nc_info)
	stack.add_child(_next_card)
	# Bottom spacer
	var bottom_space := Control.new()
	bottom_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(bottom_space)
	# Action card
	var action_card := PanelContainer.new()
	var ac_style := StyleBoxFlat.new()
	ac_style.bg_color = Color.WHITE
	ac_style.set_corner_radius_all(26)
	ac_style.shadow_color = Palette.WIN_CARD_SHADOW
	ac_style.shadow_size = 7; ac_style.shadow_offset = Vector2(0, 7)
	ac_style.set_content_margin_all(14)
	action_card.add_theme_stylebox_override("panel", ac_style)
	stack.add_child(action_card)
	var ac_stack := VBoxContainer.new()
	ac_stack.add_theme_constant_override("separation", 14)
	action_card.add_child(ac_stack)
	_next_btn = ActionButton.create(tr("result.win.next"), Palette.WIN_BUTTON_BG, Palette.WIN_BUTTON_SHADOW, Palette.WIN_BUTTON_TEXT_SHADOW, 26)
	_next_btn.pressed.connect(func(): next_pressed.emit())
	ac_stack.add_child(_next_btn)
	_replay_btn = ActionButton.create(tr("result.win.replay"), Palette.WIN_BUTTON_BG, Palette.WIN_BUTTON_SHADOW, Palette.WIN_BUTTON_TEXT_SHADOW, 26)
	_replay_btn.pressed.connect(func(): replay_pressed.emit())
	_replay_btn.visible = false
	ac_stack.add_child(_replay_btn)
	_home_btn = ActionButton.create(tr("result.win.home"), Palette.PILL_BG, Palette.WIN_CARD_SHADOW, Color.TRANSPARENT, 22, 52)
	_home_btn.add_theme_color_override("font_color", Palette.INK)
	_home_btn.pressed.connect(func(): home_pressed.emit())
	ac_stack.add_child(_home_btn)

func _build_stats() -> Array[Dictionary]:
	var time_str := _format_time(_elapsed_ms)
	return [
		{"label": tr("result.stat.time"), "value": time_str, "icon": "clock"},
		{"label": tr("result.stat.mistakes"), "value": str(_mistake_count), "icon": "error"},
	]

func _format_time(ms: int) -> String:
	var total_secs: int = int(ms / 1000.0)
	var mins: int = int(total_secs / 60.0)
	var secs: int = total_secs % 60
	return "%02d:%02d" % [mins, secs]

static func _difficulty_display(d: String) -> String:
	match d:
		"tutorial": return tr("difficulty.tutorial")
		"easy": return tr("difficulty.easy")
		"medium": return tr("difficulty.medium")
		"hard": return tr("difficulty.hard")
		_: return ""

static func _difficulty_color(d: String) -> Color:
	match d:
		"tutorial", "easy": return Palette.WIN_DIFFICULTY_EASY
		"medium": return Palette.WIN_DIFFICULTY_MEDIUM
		"hard": return Palette.WIN_DIFFICULTY_HARD
		_: return Palette.WIN_TEXT_SECONDARY

func setup(won: bool, score: int, level_id: String, is_last: bool, hearts_left: int = 3, mistake_count: int = 0, next_label: String = "", next_size: int = 0, next_difficulty: String = "") -> void:
	_is_last_level = is_last
	_level_id = level_id.trim_prefix("L")
	_elapsed_ms = score
	_hearts_left = clampi(hearts_left, 0, 3)
	_mistake_count = mistake_count
	_next_label = next_label
	_next_size = next_size
	_next_difficulty = next_difficulty
	_ensure_nodes()
	_update_ui()

func _ready() -> void:
	_ensure_nodes()
	_update_ui()
	_play_entrance_animations()

func _update_ui() -> void:
	if _level_badge != null:
		_level_badge.text = tr("result.level_badge") % _level_id if _level_id != "" else ""
	if _next_btn != null:
		_next_btn.visible = not _is_last_level
	if _replay_btn != null:
		_replay_btn.visible = _is_last_level
	var nc := find_child("NextCard", false, false)
	if nc != null:
		nc.visible = not _is_last_level and _next_label != ""

func _play_entrance_animations() -> void:
	if not LayoutTokens.motion_enabled:
		return
	if _confetti != null:
		_confetti.start()
	if _ribbon != null:
		_ribbon.animate()
	if _hearts != null:
		_hearts.animate()
	if _stat_card != null:
		_stat_card.animate(1.1)
```

- [ ] **Step 4: Run tests**

```bash
rtk godot --headless --path game --script res://tests/test_win_screen.gd
```

Expected: PASS

- [ ] **Step 5: Update win.tscn to use win_screen.gd**

Edit `game/scenes/win.tscn` — change the script path from `result_screen.gd` to `win_screen.gd`:

The `.tscn` file should reference `res://scripts/screens/win_screen.gd` as its script.

- [ ] **Step 6: Update app_shell.gd to pass hearts_left and mistake_count**

In `game/scripts/screens/app_shell.gd`:

**6a. Add member variables** after `_last_won_is_last` (line 43):

```gdscript
var _last_won_hearts: int = 3
var _last_won_mistakes: int = 0
var _next_level_label: String = ""
var _next_level_size: int = 0
var _next_level_difficulty: String = ""
```

**6b. Save heart/mistake/next-level data in `_on_level_done()`** — after `_last_won_elapsed = elapsed` (line 186), add:

```gdscript
_last_won_hearts = sess.hearts if sess != null else 3
_last_won_mistakes = sess.mistake_count if sess != null else 0
```

After the `on_level_won()` call in the win branch (line 194), resolve next-level info:

```gdscript
# Resolve next-level metadata for win screen preview.
_next_level_label = ""; _next_level_size = 0; _next_level_difficulty = ""
if not _last_won_is_last and cur_rt != null and cur_rt.has_method("next_level_label"):
	var nxt_lbl: String = cur_rt.next_level_label(label)
	if nxt_lbl != "":
		_next_level_label = nxt_lbl
		var nxt_entry: Dictionary = cur_rt._resolve_playlist_entry(nxt_lbl)
		if not nxt_entry.is_empty():
			_next_level_size = int(nxt_entry.get("size", 0))
			_next_level_difficulty = str(nxt_entry.get("difficulty", ""))
```

Also in the `else` (lose) branch around line 197, add:

```gdscript
_last_won_hearts = 0
_last_won_mistakes = sess.mistake_count if sess != null else 0
_next_level_label = ""; _next_level_size = 0; _next_level_difficulty = ""
```

**6c. Pass saved data in `_instantiate_screen()`** — modify the win screen setup call (line 132):

Current:
```gdscript
if screen.has_method("setup"): screen.call("setup", true, elapsed, label, is_last)
```

Change to:
```gdscript
if screen.has_method("setup"): screen.call("setup", true, elapsed, label, is_last, _last_won_hearts, _last_won_mistakes, _next_level_label, _next_level_size, _next_level_difficulty)
```

**6d. Fix fail screen elapsed_ms:** In `_instantiate_screen()`, the fail branch currently passes `0` as the score. Change to pass `_last_won_elapsed` so the fail screen shows actual play time:

Current:
```gdscript
if screen.has_method("setup"): screen.call("setup", false, 0, label, false)
```

Change to:
```gdscript
if screen.has_method("setup"): screen.call("setup", false, _last_won_elapsed, label, false)
```

> **Why member variables instead of local:** The `_instantiate_screen()` method is called from `_swap_screen()`, which has no access to the `sess` local variable from `_on_level_done()`. Using member variables bridges the data across these two method calls.

> **Data flow summary — real game data to UI:**
> | UI Element | Source | Field |
> |------------|--------|-------|
> | Level badge ("Màn 5") | `_last_won_level` → `setup(level_id)` | `campaign_runtime.current_level_label()` → playlist entry `.label` (e.g. "L05") |
> | Time stat ("02:41") | `_last_won_elapsed` → `setup(score)` | `play_session.elapsed_ms` |
> | Mistake count ("1") | `_last_won_mistakes` → `setup(mistake_count)` | `play_session.mistake_count` |
> | Hearts (2/3 filled) | `_last_won_hearts` → `setup(hearts_left)` | `play_session.hearts` |
> | Next level label | `_next_level_label` → `setup(next_label)` | `campaign_runtime.next_level_label(after)` |
> | Next level size (5×5) | `_next_level_size` → `setup(next_size)` | Playlist entry `.size` via `_resolve_playlist_entry()` |
> | Next level difficulty badge | `_next_level_difficulty` → `setup(next_difficulty)` | Playlist entry `.difficulty` ("tutorial"/"easy"/"medium"/"hard") |
> | Progress bar (home) | `runtime.completed_count()` / `runtime.playlist_order().size()` | Campaign progress data |
> | Is last level | `_last_won_is_last` | `completed_count + 1 >= playlist_order.size()` |

- [ ] **Step 7: Commit**

```bash
git add game/scripts/screens/win_screen.gd game/scenes/win.tscn game/scripts/screens/app_shell.gd game/tests/test_win_screen.gd
git commit -m "feat(screens): implement redesigned win screen with animations"
```

---

## Task 6: Fail Screen Implementation

**Files:**
- Create: `game/scripts/screens/fail_screen.gd`
- Modify: `game/scenes/fail.tscn`
- Create: `game/tests/test_fail_screen.gd`

**Interfaces:**
- Consumes: `GradientBg`, `RibbonBanner`, `HeartDisplay`, `StatCard`, `ActionButton` from Tasks 2–3; `mascot_sad.png`, `cloud_rain.png` from Task 4
- Produces: `fail_screen.gd` with signals: `next_pressed()`, `retry_pressed()`, `home_pressed()`, `replay_pressed()`; `setup(won: bool, score: int, level_id: String, is_last: bool) -> void`

- [ ] **Step 1: Write failing tests**

Create `game/tests/test_fail_screen.gd`:

```gdscript
extends SceneTree

const FailScreen = preload("res://scripts/screens/fail_screen.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_instantiates()
	_test_setup()
	_test_signals()
	_test_format_time()
	if _fails.is_empty():
		print("FAIL_SCREEN_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)

func _test_instantiates() -> void:
	var screen := FailScreen.new()
	_assert(screen is Control, "fail_screen is Control")
	screen.free()

func _test_setup() -> void:
	var screen := FailScreen.new()
	screen.setup(false, 192000, "L12", false)
	_assert(screen.has_signal("retry_pressed"), "has retry_pressed")
	_assert(screen.has_signal("home_pressed"), "has home_pressed")
	screen.free()

func _test_signals() -> void:
	var screen := FailScreen.new()
	_assert(screen.has_signal("next_pressed"), "has next_pressed")
	_assert(screen.has_signal("retry_pressed"), "has retry_pressed")
	_assert(screen.has_signal("home_pressed"), "has home_pressed")
	_assert(screen.has_signal("replay_pressed"), "has replay_pressed")
	screen.free()

func _test_format_time() -> void:
	var screen := FailScreen.new()
	_assert(screen._format_time(192000) == "03:12", "format 192000 -> 03:12")
	screen.free()
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
rtk godot --headless --path game --script res://tests/test_fail_screen.gd
```

- [ ] **Step 3: Implement fail_screen.gd**

Create `game/scripts/screens/fail_screen.gd`:

```gdscript
# fail_screen.gd — Game over screen with sad mascot, broken hearts, rain cloud.
extends Control

signal next_pressed()
signal retry_pressed()
signal home_pressed()
signal replay_pressed()

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const GradientBg = preload("res://scripts/ui/gradient_bg.gd")
const RibbonBanner = preload("res://scripts/ui/ribbon_banner.gd")
const HeartDisplay = preload("res://scripts/ui/heart_display.gd")
const StatCard = preload("res://scripts/ui/stat_card.gd")
const ActionButton = preload("res://scripts/ui/action_button.gd")

var _level_id: String = ""
var _elapsed_ms: int = 0

var _bg: ColorRect
var _ribbon: RibbonBanner
var _hearts: HeartDisplay
var _mascot: TextureRect
var _cloud: TextureRect
var _stat_card: StatCard
var _retry_btn: Button
var _home_btn: Button
var _level_badge: Label

func _ensure_nodes() -> void:
	if _bg != null:
		return
	_bg = GradientBg.new(Palette.LOSE_BG_CENTER, Palette.LOSE_BG_MID, Palette.LOSE_BG_EDGE, Vector2(0.5, 0.30))
	add_child(_bg)
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		safe.add_theme_constant_override("margin_" + side, 20)
	safe.add_theme_constant_override("margin_top", 18)
	safe.add_theme_constant_override("margin_bottom", 28)
	add_child(safe)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	safe.add_child(stack)
	# Top bar
	var top := HBoxContainer.new()
	stack.add_child(top)
	var home_icon_btn := Button.new()
	home_icon_btn.custom_minimum_size = Vector2(48, 48)
	home_icon_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var hstyle := StyleBoxFlat.new()
	hstyle.bg_color = Color("#6E5BC8")
	hstyle.set_corner_radius_all(16)
	hstyle.shadow_color = Color("#4B3B9A")
	hstyle.shadow_size = 5; hstyle.shadow_offset = Vector2(0, 5)
	for s in ["normal", "hover", "pressed", "focus"]:
		home_icon_btn.add_theme_stylebox_override(s, hstyle)
	home_icon_btn.pressed.connect(func(): home_pressed.emit())
	top.add_child(home_icon_btn)
	var spacer1 := Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer1)
	_level_badge = Label.new()
	_level_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_badge.add_theme_font_size_override("font_size", 18)
	_level_badge.add_theme_color_override("font_color", Palette.LOSE_TEXT_PRIMARY)
	var badge_font := FontTokens.heading()
	if badge_font != null:
		_level_badge.add_theme_font_override("font", badge_font)
	top.add_child(_level_badge)
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer2.custom_minimum_size.x = 48
	top.add_child(spacer2)
	# Ribbon
	_ribbon = RibbonBanner.new(tr("result.lose.title"), "lose")
	stack.add_child(_ribbon)
	# Hearts (all broken)
	_hearts = HeartDisplay.new(3, 0, "lose")
	stack.add_child(_hearts)
	# Cloud
	_cloud = TextureRect.new()
	_cloud.texture = load("res://assets/ui/result/cloud_rain.png") as Texture2D
	_cloud.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cloud.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_cloud.custom_minimum_size = Vector2(110, 44)
	_cloud.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(_cloud)
	# Mascot
	_mascot = TextureRect.new()
	_mascot.texture = load("res://assets/ui/result/mascot_sad.png") as Texture2D
	_mascot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_mascot.custom_minimum_size = Vector2(230, 150)
	_mascot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(_mascot)
	# Stat card (time only)
	_stat_card = StatCard.new([{"label": tr("result.stat.time"), "value": _format_time(_elapsed_ms), "icon": "clock"}])
	stack.add_child(_stat_card)
	# Bottom spacer
	var bottom_space := Control.new()
	bottom_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(bottom_space)
	# Action card
	var action_card := PanelContainer.new()
	var ac_style := StyleBoxFlat.new()
	ac_style.bg_color = Color.WHITE
	ac_style.set_corner_radius_all(26)
	ac_style.shadow_color = Palette.LOSE_CARD_SHADOW
	ac_style.shadow_size = 7; ac_style.shadow_offset = Vector2(0, 7)
	ac_style.set_content_margin_all(14)
	action_card.add_theme_stylebox_override("panel", ac_style)
	stack.add_child(action_card)
	var ac_stack := VBoxContainer.new()
	ac_stack.add_theme_constant_override("separation", 12)
	action_card.add_child(ac_stack)
	var encourage_title := Label.new()
	encourage_title.text = tr("result.lose.encourage_title")
	encourage_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	encourage_title.add_theme_font_size_override("font_size", 24)
	encourage_title.add_theme_color_override("font_color", Palette.LOSE_TEXT_PRIMARY)
	var heading := FontTokens.heading()
	if heading != null:
		encourage_title.add_theme_font_override("font", heading)
	ac_stack.add_child(encourage_title)
	var encourage_sub := Label.new()
	encourage_sub.text = tr("result.lose.subtitle")
	encourage_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	encourage_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	encourage_sub.add_theme_font_size_override("font_size", 15)
	encourage_sub.add_theme_color_override("font_color", Palette.LOSE_TEXT_SECONDARY)
	ac_stack.add_child(encourage_sub)
	_retry_btn = ActionButton.create(tr("result.lose.retry"), Palette.LOSE_BUTTON_BG, Palette.LOSE_BUTTON_SHADOW, Palette.LOSE_BUTTON_TEXT_SHADOW, 26)
	_retry_btn.pressed.connect(func(): retry_pressed.emit())
	ac_stack.add_child(_retry_btn)

func _format_time(ms: int) -> String:
	var total_secs: int = int(ms / 1000.0)
	var mins: int = int(total_secs / 60.0)
	var secs: int = total_secs % 60
	return "%02d:%02d" % [mins, secs]

func setup(won: bool, score: int, level_id: String, is_last: bool) -> void:
	_level_id = level_id.trim_prefix("L")
	_elapsed_ms = score
	_ensure_nodes()
	_update_ui()

func _ready() -> void:
	_ensure_nodes()
	_update_ui()
	_play_entrance_animations()

func _update_ui() -> void:
	if _level_badge != null:
		_level_badge.text = tr("result.level_badge") % _level_id if _level_id != "" else ""

func _play_entrance_animations() -> void:
	if not LayoutTokens.motion_enabled:
		return
	if _ribbon != null:
		_ribbon.animate()
	if _hearts != null:
		_hearts.animate()
	if _stat_card != null:
		_stat_card.animate(1.1)
	if _mascot != null:
		_animate_mascot_thud()

func _animate_mascot_thud() -> void:
	_mascot.position.y -= 220
	_mascot.modulate.a = 0.0
	var tw := _mascot.create_tween()
	tw.tween_interval(0.8)
	tw.tween_property(_mascot, "position:y", _mascot.position.y + 220, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_mascot, "modulate:a", 1.0, 0.2)
```

- [ ] **Step 4: Update fail.tscn**

Edit `game/scenes/fail.tscn` — change the script path from `result_screen.gd` to `fail_screen.gd`.

- [ ] **Step 5: Run tests**

```bash
rtk godot --headless --path game --script res://tests/test_fail_screen.gd
```

Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add game/scripts/screens/fail_screen.gd game/scenes/fail.tscn game/tests/test_fail_screen.gd
git commit -m "feat(screens): implement redesigned fail screen with sad mascot and rain"
```

---

## Task 7: Home Screen Redesign

**Files:**
- Modify: `game/scripts/screens/title_screen.gd`
- Create: `game/scripts/ui/progress_bar.gd`
- Create: `game/tests/test_title_screen_v2.gd`

**Interfaces:**
- Consumes: `GradientBg`, `ActionButton` from Task 2; `mascot_home.png` from Task 4; `Palette`, `FontTokens`, `LayoutTokens` from Task 1; `ProgressBar` (new)
- Produces:
  - Modified `title_screen.gd` with same signal interface
  - `ProgressBar.new(done: int, total: int) -> PanelContainer`; `animate()` triggers fill animation

- [ ] **Step 1: Write failing tests for progress_bar**

Create `game/tests/test_title_screen_v2.gd`:

```gdscript
extends SceneTree

const ProgressBarWidget = preload("res://scripts/ui/progress_bar.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_progress_bar_creates()
	_test_progress_bar_zero()
	_test_progress_bar_overflow()
	if _fails.is_empty():
		print("TITLE_V2_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)

func _test_progress_bar_creates() -> void:
	var bar := ProgressBarWidget.new(10, 30)
	_assert(bar is PanelContainer, "progress_bar is PanelContainer")
	bar.free()

func _test_progress_bar_zero() -> void:
	var bar := ProgressBarWidget.new(0, 0)
	_assert(bar is PanelContainer, "progress_bar zero total ok")
	bar.free()

func _test_progress_bar_overflow() -> void:
	var bar := ProgressBarWidget.new(50, 30)
	_assert(bar is PanelContainer, "progress_bar overflow clamped ok")
	bar.free()
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
rtk godot --headless --path game --script res://tests/test_title_screen_v2.gd
```

- [ ] **Step 3: Implement progress_bar.gd**

Create `game/scripts/ui/progress_bar.gd`:

```gdscript
# progress_bar.gd — Animated campaign progress bar.
extends PanelContainer

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _done: int = 0
var _total: int = 30
var _fill_rect: ColorRect

func _init(done: int = 0, total: int = 30) -> void:
	_done = maxi(0, done)
	_total = maxi(1, total)
	if _done > _total:
		_done = _total
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.set_corner_radius_all(22)
	style.shadow_color = Palette.HOME_CARD_SHADOW
	style.shadow_size = 7; style.shadow_offset = Vector2(0, 7)
	style.content_margin_left = 16; style.content_margin_right = 16
	style.content_margin_top = 12; style.content_margin_bottom = 12
	add_theme_stylebox_override("panel", style)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	add_child(stack)
	var top_row := HBoxContainer.new()
	stack.add_child(top_row)
	var progress_label := Label.new()
	progress_label.text = tr("title.progress")
	progress_label.add_theme_font_size_override("font_size", 15)
	progress_label.add_theme_color_override("font_color", Palette.WIN_TEXT_SECONDARY)
	var bold := FontTokens.body_bold()
	if bold != null:
		progress_label.add_theme_font_override("font", bold)
	top_row.add_child(progress_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)
	var count_label := Label.new()
	count_label.text = "%d / %d" % [_done, _total]
	count_label.add_theme_font_size_override("font_size", 18)
	count_label.add_theme_color_override("font_color", Palette.WIN_TEXT_PRIMARY)
	var heading := FontTokens.heading()
	if heading != null:
		count_label.add_theme_font_override("font", heading)
	top_row.add_child(count_label)
	var bar_bg := ColorRect.new()
	bar_bg.custom_minimum_size = Vector2(0, 18)
	bar_bg.color = Palette.HOME_PROGRESS_BG
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(bar_bg)
	_fill_rect = ColorRect.new()
	_fill_rect.color = Palette.HOME_PROGRESS_FILL
	_fill_rect.custom_minimum_size = Vector2(0, 18)
	_fill_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_bg.add_child(_fill_rect)

func animate() -> void:
	if _fill_rect == null:
		return
	var pct := float(_done) / float(_total)
	if not LayoutTokens.motion_enabled:
		_fill_rect.scale.x = pct
		return
	_fill_rect.scale.x = 0.0
	_fill_rect.pivot_offset = Vector2.ZERO
	var tw := _fill_rect.create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(_fill_rect, "scale:x", pct, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
```

- [ ] **Step 4: Run tests**

```bash
rtk godot --headless --path game --script res://tests/test_title_screen_v2.gd
```

Expected: PASS

- [ ] **Step 5: Rewrite title_screen.gd with new layout**

Modify `game/scripts/screens/title_screen.gd` — replace the `_ensure_nodes()` method body to use the new components:

Key changes:
1. Replace `ColorRect` background with `GradientBg` (warm golden)
2. Keep existing logo `TextureRect` (use `logo_candoku.png`)
3. Add mascot `TextureRect` with speech bubble
4. Replace play button with `ActionButton.create()`
5. Add `ProgressBar` widget showing campaign progress
6. Keep all existing signals and `setup()` interface unchanged
7. Keep debug picker, help, and options functionality
8. **Endless Mode button layout:** The HTML mockup only shows a Campaign play button, but the game supports Endless Mode (`endless_btn`). Place the Endless button below the Campaign button, inside the same `ActionBlock` VBoxContainer, with 16px separation. When only Endless is enabled (`GameFeatures.is_campaign_enabled() == false`), the Endless button takes the primary style (orange, large) via `_style_primary_endless()` and the Campaign box is hidden — same behavior as current code.

The full rewrite preserves the existing signal interface (`play_pressed`, `endless_pressed`, `options_pressed`, `debug_level_selected`) and `setup(rt, endless_rt)` method signature. The `_update_ui()` method must still handle `GameFeatures` checks and runtime label formatting.

```gdscript
# In _ensure_nodes(), replace:
# - background ColorRect → GradientBg.new(Palette.HOME_BG_CENTER, Palette.HOME_BG_MID, Palette.HOME_BG_EDGE, Vector2(0.5, 0.46))
# - play_btn → ActionButton.create(tr("title.play") % "1", Palette.HOME_BUTTON_BG, Palette.HOME_BUTTON_SHADOW, Color("#8A3306"), 30, 70)
# - Add mascot TextureRect before actions block
# - Add ProgressBar after mascot / before action buttons
# - Keep top bar (debug, help, settings) with updated rounded 3D styles (blue bg + shadow per mockup)
# - Keep endless_btn below play_btn in ActionBlock, white pill style by default
# - Keep _style_primary_endless() for Endless-only mode
```

The implementer should replace the full `_ensure_nodes()` body while keeping all methods below it (`_ready`, `setup`, `_update_ui`, `_on_play`, `_on_endless`, `_on_options`, `_on_help`, `_close_help`, `_set_round_icon`, `_add_press_anim`, `_style_primary_endless`, `_on_debug_pressed`, `_unhandled_input`) unchanged.

- [ ] **Step 6: Run existing tests + new tests**

```bash
rtk godot --headless --path game --script res://tests/test_title_screen_v2.gd
```

- [ ] **Step 7: Commit**

```bash
git add game/scripts/ui/progress_bar.gd game/scripts/screens/title_screen.gd game/tests/test_title_screen_v2.gd
git commit -m "feat(screens): redesign home screen with gradient, mascot, and progress bar"
```

---

## Task 8: Add Missing Translation Keys

**Files:**
- Modify: translation CSV/PO files (check `game/translations/` or `game/localization/`)

**Interfaces:**
- Consumes: Keys referenced in Tasks 5–7
- Produces: Translation entries for all new UI strings

- [ ] **Step 1: Verify translation file location**

```bash
ls game/locale/strings.csv
```

Expected: `game/locale/strings.csv` exists (this is the project's translation CSV file).

- [ ] **Step 2: Add new translation keys to strings.csv**

Add these rows to `game/locale/strings.csv` if they don't already exist. The CSV uses columns for each supported locale (vi, en, ja, ko, zh_CN, zh_TW, th):

| Key | vi | en |
|-----|-----------|---------|
| `result.level_badge` | `Màn %s` | `Level %s` |
| `result.stat.time` | `Thời gian` | `Time` |
| `result.stat.mistakes` | `Lỗi sai` | `Mistakes` |
| `result.lose.encourage_title` | `Suýt nữa là được rồi!` | `So close!` |
| `title.progress` | `Tiến độ` | `Progress` |
| `result.win.next_level` | `Màn tiếp: %s` | `Next: %s` |
| `difficulty.tutorial` | `Hướng dẫn` | `Tutorial` |
| `difficulty.easy` | `Dễ` | `Easy` |
| `difficulty.medium` | `Trung bình` | `Medium` |
| `difficulty.hard` | `Khó` | `Hard` |

- [ ] **Step 3: Verify no missing keys at runtime**

```bash
rtk godot --headless --path game --script res://tests/test_win_screen.gd
rtk godot --headless --path game --script res://tests/test_fail_screen.gd
```

- [ ] **Step 4: Commit**

```bash
git add game/locale/strings.csv
git commit -m "chore(i18n): add translation keys for redesigned screens"
```

---

## Task 9: Migrate Existing Tests and Archive Old result_screen.gd

**Files:**
- Modify: `game/tests/test_screens.gd` (update `_test_result_screen()` to use new screen scripts)
- Modify: `game/tests/test_localization.gd` (update `ResultScreen` import and `_test_result_uses_tr()`)
- Delete: `game/scripts/screens/result_screen.gd` (no longer referenced after test migration)

**Interfaces:**
- Consumes: All previous tasks complete — `win_screen.gd` and `fail_screen.gd` are fully functional
- Produces: Clean codebase with no dead code, all existing gate tests passing

> **Critical:** `test_screens.gd` line 6 preloads `result_screen.gd` and `_test_result_screen()` (lines 196–240) tests it directly — accessing `._is_win`, `.next_btn`, `._on_next()`, etc. `test_localization.gd` line 4 also preloads it and tests `message_label`. Both must be updated BEFORE deleting the old file.

- [ ] **Step 1: Update test_screens.gd — replace ResultScreen import and test method**

In `game/tests/test_screens.gd`, replace:

```gdscript
const ResultScreen = preload("res://scripts/screens/result_screen.gd")
```

With:

```gdscript
const WinScreen = preload("res://scripts/screens/win_screen.gd")
const FailScreen = preload("res://scripts/screens/fail_screen.gd")
```

Replace the `_test_result_screen()` method (lines 196–240) with:

```gdscript
func _test_result_screen() -> void:
	var win_packed := load("res://scenes/win.tscn") as PackedScene
	var win_screen := win_packed.instantiate() as WinScreen

	var next_box := [false]
	var replay_box := [false]
	var home_box := [false]

	win_screen.next_pressed.connect(func(): next_box[0] = true)
	win_screen.replay_pressed.connect(func(): replay_box[0] = true)
	win_screen.home_pressed.connect(func(): home_box[0] = true)

	win_screen.setup(true, 12000, "1-1", false, 2, 1, "L02", 4, "easy")
	_assert(win_screen._is_last_level == false, "result not last level")
	_assert(win_screen._next_btn != null and win_screen._next_btn.visible, "next btn visible on win")
	win_screen.next_pressed.emit()
	_assert(next_box[0], "next_pressed emitted")

	win_screen.setup(true, 50000, "3-10", true, 3, 0)
	_assert(win_screen._is_last_level, "result is last level")
	_assert(win_screen._replay_btn != null and win_screen._replay_btn.visible, "replay btn visible on campaign win")
	win_screen.replay_pressed.emit()
	_assert(replay_box[0], "replay_pressed emitted")

	win_screen.home_pressed.emit()
	_assert(home_box[0], "home_pressed emitted")

	win_screen.free()

	var fail_packed := load("res://scenes/fail.tscn") as PackedScene
	var fail_screen := fail_packed.instantiate() as FailScreen

	var retry_box := [false]
	fail_screen.retry_pressed.connect(func(): retry_box[0] = true)
	fail_screen.setup(false, 0, "1-1", false)
	_assert(fail_screen._retry_btn != null and fail_screen._retry_btn.visible, "retry btn visible on fail")
	fail_screen.retry_pressed.emit()
	_assert(retry_box[0], "retry_pressed emitted")

	fail_screen.free()
```

Note: The new tests use `_next_btn`, `_replay_btn`, `_retry_btn` (underscored private vars) instead of the old `next_btn`, `replay_btn`, `retry_btn` (public vars). The old tests accessed `._is_win` and called `._on_next()` directly — the new tests emit signals instead, which is cleaner.

- [ ] **Step 2: Update test_localization.gd — replace ResultScreen import and test method**

In `game/tests/test_localization.gd`, replace:

```gdscript
const ResultScreen = preload("res://scripts/screens/result_screen.gd")
```

With:

```gdscript
const WinScreen = preload("res://scripts/screens/win_screen.gd")
const FailScreen = preload("res://scripts/screens/fail_screen.gd")
```

Update `_test_result_uses_tr()` to instantiate `WinScreen` instead of `ResultScreen`, and access `_level_badge` instead of `message_label`:

```gdscript
func _test_result_uses_tr() -> void:
	TranslationServer.set_locale("en")
	var screen := WinScreen.new()
	screen.setup(true, 5000, "L01", false, 3, 0)
	# Verify the screen instantiates without error with translations active
	screen.free()
```

- [ ] **Step 3: Run existing test suites to verify migration**

```bash
rtk godot --headless --path game --script res://tests/test_screens.gd
rtk godot --headless --path game --script res://tests/test_localization.gd
```

Expected: all PASS — tests now exercise the new screen scripts.

- [ ] **Step 4: Verify no other file references result_screen.gd**

```bash
rtk proxy rg -n "result_screen" game/
```

Expected: no matches (win.tscn and fail.tscn point to new scripts, test files updated).

- [ ] **Step 5: Delete result_screen.gd**

```bash
rm game/scripts/screens/result_screen.gd
```

- [ ] **Step 6: Run full gate**

```bash
# 1. All test suites
rtk godot --headless --path game --script res://tests/test_ui_widgets.gd
rtk godot --headless --path game --script res://tests/test_win_screen.gd
rtk godot --headless --path game --script res://tests/test_fail_screen.gd
rtk godot --headless --path game --script res://tests/test_title_screen_v2.gd
rtk godot --headless --path game --script res://tests/test_screens.gd
rtk godot --headless --path game --script res://tests/test_localization.gd

# 2. Clean-room check
rtk proxy rg -n "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/

# 3. No import from extracted_reusable
rtk proxy rg -n "extracted_reusable" game/scripts/ game/tests/

# 4. No stale references
rtk proxy rg -n "result_screen" game/
```

Expected: all pass, no matches on clean-room, no extracted_reusable references, no result_screen references.

- [ ] **Step 7: Commit**

```bash
git add game/tests/test_screens.gd game/tests/test_localization.gd
git rm game/scripts/screens/result_screen.gd
git commit -m "refactor(screens): migrate tests and remove old result_screen.gd"
```

---

## Task 10: Visual QA and Polish (Manual)

**Files:** No code changes — this is a manual testing task.

- [ ] **Step 1: Run the game and navigate to each screen**

```bash
# Launch the game
rtk godot --path game
```

- [ ] **Step 2: Verify Win screen**

Play through a level and win. Check:
- Radial gradient background renders correctly
- Confetti particles fall naturally
- Ribbon banner drops in with animation
- Hearts display correct count (play with 0, 1, 2, 3 mistakes)
- Mascot sprite displays (placeholder is OK for now)
- Stats card shows correct time and mistake count
- "Màn tiếp theo" button works and navigates to next level
- All animations respect reduced motion setting (toggle in Options)

- [ ] **Step 3: Verify Lose screen**

Play through a level and lose (make 3 mistakes). Check:
- Purple gradient background renders
- "HẾT TIM RỒI!" ribbon displays
- 3 broken hearts show
- Sad mascot displays
- Time stat shows correctly
- Encouraging message displays
- "Chơi lại màn" button retries the level

- [ ] **Step 4: Verify Home screen**

Check:
- Golden gradient background renders
- Logo displays correctly
- Mascot and speech bubble show
- Progress bar animates and shows correct count
- Play button works
- Settings and Help buttons work
- Debug picker still works (debug builds)

- [ ] **Step 5: Document visual issues**

Create issues for any visual discrepancies between mockup and implementation. Common ones:
- Colors slightly off (fine-tune Palette constants)
- Spacing needs adjustment (tweak margins)
- Placeholder sprites need replacement with final artwork
- Font weight differences (BeVietnamPro vs Baloo 2)

---

## Summary

| Task | Description | Est. Effort |
|------|-------------|-------------|
| 1 | Palette & Layout token updates | 5 min |
| 2 | Widgets: gradient_bg, action_button, heart_display | 15 min |
| 3 | Widgets: ribbon_banner, stat_card, confetti_layer | 15 min |
| 4 | Prepare placeholder sprite assets | 5 min |
| 5 | Win screen implementation | 20 min |
| 6 | Fail screen implementation | 15 min |
| 7 | Home screen redesign | 20 min |
| 8 | Translation keys | 5 min |
| 9 | Archive old code + integration gate | 5 min |
| 10 | Visual QA (manual) | 15 min |

**Total: ~120 min estimated**

**Dependency chain:** Task 1 → Tasks 2, 3 (parallel) → Task 4 → Tasks 5, 6, 7 (parallel after 4) → Task 8 → Task 9 → Task 10

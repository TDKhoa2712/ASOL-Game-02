# Candoku Visual Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Nâng cấp animation quality và visual polish cho Win, Lose, Title screens dựa trên candoku prototype — focusing trên 7 gaps cụ thể (hearts split, rain particles, ribbon drop, confetti upgrade, 3D buttons, entrance animations, tween helpers).

**Architecture:** Game đã có đầy đủ layout và components (win_screen.gd, fail_screen.gd, title_screen.gd, candy_character.gd, và toàn bộ UI widgets). Plan này chỉ upgrade animation quality và thêm visual effects còn thiếu. Mọi thay đổi respect LayoutTokens.motion_enabled và headless compatibility.

**Tech Stack:** Godot 4, GDScript, Tween API, CPUParticles2D, StyleBoxFlat

**Spec:** `docs/superpowers/specs/2026-10-09-candoku-visual-polish-spec.md`

## Global Constraints

- Module ≤ 300 dòng. Một file, một trách nhiệm.
- Không autoloads — composition root pattern, dependencies injected từ app_shell.
- Signals thay EventBus.
- Giữ nguyên signal contracts (`next_pressed`, `retry_pressed`, `home_pressed`, `replay_pressed`, `play_pressed`, `endless_pressed`, `options_pressed`, `debug_level_selected`).
- `setup()` method signatures phải tương thích với `app_shell.gd` callers.
- Tất cả animations phải respect `LayoutTokens.motion_enabled` (skip to final state nếu disabled).
- Font: BeVietnamPro/Nunito từ FontTokens (không dùng Baloo 2).
- Target resolution: 390×844 logical, responsive via anchors.
- Phải pass headless mode (CI): không crash khi `DisplayServer.get_name() == "headless"`.
- Chỉ stage/commit file thuộc phạm vi. Giữ nguyên sửa đổi có sẵn.

## Review Focus

1. **motion_enabled = false:** Tất cả animations mới phải skip gracefully — elements hiển thị ở final state, không tween. Test: set `LayoutTokens.motion_enabled = false`, instantiate mỗi screen, verify không animation chạy.
2. **Headless display server:** CPUParticles2D và draw calls mới không được crash headless. Test: chạy `--headless`, instantiate fail_screen + win_screen, verify no errors.
3. **Heart break timing vs screen transition:** Heart break animation (1.3s) phải hoàn thành trước khi lose screen chuyển đi. Verify `_play_entrance_animations()` không bị interrupted.
4. **Confetti fallback:** Nếu CPUParticles2D không khả dụng (headless), confetti phải degrade gracefully thay vì crash.
5. **Button pressed state depth:** 3D button depth pressed phải visually "lún xuống" đúng — `expand_margin_top` bù cho `border_width_bottom` giảm, tránh layout jump.

---

## File Structure

### Files to create

| File | Responsibility |
|------|----------------|
| `game/scripts/ui/tween_helpers.gd` | Shared animation utilities: rise_in, pulse, bob — DRY across screens |
| `game/scripts/ui/rain_layer.gd` | CPUParticles2D rain effect for lose screen |
| `game/assets/ui/result/raindrop.svg` | Raindrop particle texture (nếu chưa có) |
| `game/assets/ui/result/square_confetti.svg` | Square confetti particle texture |
| `game/assets/ui/result/heart_half_l.svg` | Left half of broken heart |
| `game/assets/ui/result/heart_half_r.svg` | Right half of broken heart |

### Files to modify

| File | Changes |
|------|---------|
| `game/scripts/ui/tween_helpers.gd` | New: shared animation utilities |
| `game/scripts/ui/heart_display.gd` | Add `animate_break()` with split-and-fall animation |
| `game/scripts/ui/ribbon_banner.gd` | Update `animate()` to drop-from-top + optional tilt |
| `game/scripts/ui/confetti_layer.gd` | Refactor to CPUParticles2D with headless fallback |
| `game/scripts/ui/action_button.gd` | Switch from shadow to border_width_bottom for 3D depth |
| `game/scripts/screens/fail_screen.gd` | Add rain particles, use new heart break animation |
| `game/scripts/screens/win_screen.gd` | Use tween_helpers, updated ribbon animation |
| `game/scripts/screens/title_screen.gd` | Add coordinated entrance animation sequence |

---

## Task 1: Tween Helpers — Shared Animation Utilities

**Files:**
- Create: `game/scripts/ui/tween_helpers.gd`
- Test: verify in headless — no crash, motion_enabled=false skips all

**Interfaces:**
- Produces: `TweenHelpers.rise_in(node: Control, delay: float, dist: float) -> void`, `TweenHelpers.pulse(node: Control, delay: float) -> void`, `TweenHelpers.bob(node: Control, amount: float, period: float, rot_deg: float) -> void`

- [ ] **Step 1: Create `game/scripts/ui/tween_helpers.gd`**

```gdscript
# tween_helpers.gd — Shared animation utilities for screen transitions.
extends RefCounted

const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

## Fade in + slide up from below.
static func rise_in(node: Control, delay: float, dist: float = 60.0) -> void:
	if not LayoutTokens.motion_enabled:
		return
	node.modulate.a = 0.0
	var start_y := node.position.y
	node.position.y = start_y + dist
	var tw := node.create_tween()
	tw.tween_interval(delay)
	tw.tween_property(node, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(node, "position:y", start_y, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Gentle scale pulse loop for primary buttons.
static func pulse(node: Control, delay: float = 1.8) -> void:
	if not LayoutTokens.motion_enabled:
		return
	node.pivot_offset = node.size / 2.0
	var tw := node.create_tween().set_loops()
	tw.tween_interval(maxf(delay, 0.01))
	tw.tween_property(node, "scale", Vector2(1.03, 1.03), 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)

## Float up/down with optional rotation.
static func bob(node: Control, amount: float = 8.0, period: float = 3.2, rot_deg: float = 0.0) -> void:
	if not LayoutTokens.motion_enabled:
		return
	node.pivot_offset = node.size / 2.0
	var base := node.position.y
	var tw := node.create_tween().set_loops()
	tw.tween_property(node, "position:y", base - amount, period / 2.0).set_trans(Tween.TRANS_SINE)
	if rot_deg != 0.0:
		tw.parallel().tween_property(node, "rotation_degrees", rot_deg, period / 2.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "position:y", base, period / 2.0).set_trans(Tween.TRANS_SINE)
	if rot_deg != 0.0:
		tw.parallel().tween_property(node, "rotation_degrees", -rot_deg, period / 2.0).set_trans(Tween.TRANS_SINE)
```

- [ ] **Step 2: Verify file ≤ 300 lines và syntax đúng**

Run: `rtk godot --headless --path game --quit`
Expected: No parse errors for tween_helpers.gd

- [ ] **Step 3: Commit**

```bash
git add game/scripts/ui/tween_helpers.gd
git commit -m "feat(ui): add tween_helpers.gd — shared rise_in, pulse, bob utilities"
```

---

## Task 2: Ribbon Banner — Drop-from-Top Animation

**Files:**
- Modify: `game/scripts/ui/ribbon_banner.gd` (method `animate()`)
- Test: instantiate RibbonBanner, call animate(), verify visual

**Interfaces:**
- Consumes: `LayoutTokens.motion_enabled`
- Produces: updated `RibbonBanner.animate(tilt_deg: float = 0.0)` — optional tilt for lose screen

- [ ] **Step 1: Read current `ribbon_banner.gd:animate()` method (lines 441-450)**

Current implementation scales from 0.7 + fade in. Replace with drop-from-top.

- [ ] **Step 2: Update `animate()` in `ribbon_banner.gd`**

Replace the existing `animate()` method:

```gdscript
func animate(tilt_deg: float = 0.0) -> void:
	if not LayoutTokens.motion_enabled:
		return
	pivot_offset = Vector2(custom_minimum_size.x * 0.5, custom_minimum_size.y * 0.5)
	var base_y := position.y
	position.y = base_y - 140.0
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(self, "position:y", base_y, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if tilt_deg != 0.0:
		tw.tween_property(self, "rotation_degrees", tilt_deg, 0.4).set_trans(Tween.TRANS_SINE)
```

- [ ] **Step 3: Update callers — `fail_screen.gd` passes tilt**

In `fail_screen.gd:_play_entrance_animations()`, change:
```gdscript
# Before:
if ribbon != null: ribbon.animate()
# After:
if ribbon != null: ribbon.animate(-3.0)
```

`win_screen.gd` keeps calling `ribbon.animate()` (no tilt, default 0.0).

- [ ] **Step 4: Verify no regression**

Run: `rtk godot --headless --path game --quit`
Expected: No errors. Ribbon's `animate()` signature is backward-compatible (tilt defaults to 0.0).

- [ ] **Step 5: Commit**

```bash
git add game/scripts/ui/ribbon_banner.gd game/scripts/screens/fail_screen.gd
git commit -m "feat(ui): ribbon drops from top with optional tilt for lose screen"
```

---

## Task 3: Heart Display — Split-and-Fall Break Animation

**Files:**
- Modify: `game/scripts/ui/heart_display.gd`
- Create: `game/assets/ui/result/heart_half_l.svg` (nếu chưa có)
- Create: `game/assets/ui/result/heart_half_r.svg` (nếu chưa có)

**Interfaces:**
- Consumes: `LayoutTokens.motion_enabled`
- Produces: `HeartDisplay.animate_break()` — tách đôi và rơi cho lose screen

- [ ] **Step 1: Check if heart half SVGs exist**

Run: `ls game/assets/ui/result/heart_half*` và `ls game/assets/ui/board/heart_half*`

Nếu chưa có, tạo 2 SVG files:
- `heart_half_l.svg` — nửa trái của heart (mirror line ở giữa)
- `heart_half_r.svg` — nửa phải

Nếu không có SVG tool, sử dụng `heart_broken.svg` hiện có với draw-based splitting thay vì texture (vẽ 2 nửa bằng `_draw()`).

- [ ] **Step 2: Add `animate_break()` method to `heart_display.gd`**

Thêm method sau vào `heart_display.gd`:

```gdscript
func animate_break() -> void:
	if not LayoutTokens.motion_enabled:
		return
	for i in range(get_child_count()):
		var heart := get_child(i) as Control
		if heart == null:
			continue
		heart.scale = Vector2.ZERO
		heart.modulate.a = 0.0
		var delay: float = 0.5 + i * 0.25
		var tw := heart.create_tween()
		tw.tween_interval(delay)
		tw.tween_property(heart, "modulate:a", 1.0, 0.3)
		tw.parallel().tween_property(heart, "scale", Vector2.ONE, 0.3)
		# After appearing, split apart
		tw.tween_interval(0.4)
		tw.tween_callback(_split_heart.bind(heart))

func _split_heart(heart: Control) -> void:
	var tex_node: TextureRect = heart.get_child(0) if heart.get_child_count() > 0 else null
	if tex_node == null:
		return
	tex_node.visible = false
	var hs := heart.custom_minimum_size
	for side in ["l", "r"]:
		var half := TextureRect.new()
		half.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		half.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		half.custom_minimum_size = hs
		half.size = hs
		half.pivot_offset = Vector2(hs.x * 0.5, hs.y)
		if ResourceLoader.exists("res://assets/ui/result/heart_half_%s.svg" % side):
			half.texture = load("res://assets/ui/result/heart_half_%s.svg" % side)
		else:
			half.texture = tex_node.texture
			half.clip_contents = true
			if side == "l":
				half.size.x = hs.x * 0.5
			else:
				half.position.x = hs.x * 0.5
				half.size.x = hs.x * 0.5
		heart.add_child(half)
		var dir := -1.0 if side == "l" else 1.0
		var tw := half.create_tween()
		tw.tween_property(half, "scale", Vector2(1.25, 1.25), 0.12)
		tw.tween_property(half, "rotation_degrees", 30.0 * dir, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(half, "position", half.position + Vector2(9.0 * dir, 48.0), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(half, "modulate:a", 0.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(half.queue_free)
```

- [ ] **Step 3: Update `fail_screen.gd` to use `animate_break()`**

In `fail_screen.gd:_play_entrance_animations()`, change:
```gdscript
# Before:
if _hearts != null: _hearts.animate()
# After:
if _hearts != null: _hearts.animate_break()
```

- [ ] **Step 4: Verify in headless**

Run: `rtk godot --headless --path game --quit`
Expected: No errors. `animate_break()` guard checks `motion_enabled`.

- [ ] **Step 5: Commit**

```bash
git add game/scripts/ui/heart_display.gd game/scripts/screens/fail_screen.gd
git commit -m "feat(ui): heart break animation — split-and-fall for lose screen"
```

---

## Task 4: Rain Layer — CPUParticles2D Rain for Lose Screen

**Files:**
- Create: `game/scripts/ui/rain_layer.gd`
- Modify: `game/scripts/screens/fail_screen.gd` (add rain under cloud)

**Interfaces:**
- Consumes: `LayoutTokens.motion_enabled`
- Produces: `RainLayer` — Node2D with CPUParticles2D rain effect

- [ ] **Step 1: Check for raindrop texture**

Run: `ls game/assets/ui/result/raindrop*`

Nếu chưa có, tạo `raindrop.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" width="8" height="16" viewBox="0 0 8 16">
  <ellipse cx="4" cy="10" rx="3.5" ry="5.5" fill="#8FB8E0"/>
  <path d="M4 0 C4 0 7.5 6 7.5 10" fill="none" stroke="#8FB8E0" stroke-width="1"/>
</svg>
```

- [ ] **Step 2: Create `game/scripts/ui/rain_layer.gd`**

```gdscript
# rain_layer.gd — CPUParticles2D rain under a cloud for lose screen.
extends Node2D

const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _particles: CPUParticles2D

func _init(spread_width: float = 84.0) -> void:
	_particles = CPUParticles2D.new()
	_particles.amount = 14
	_particles.lifetime = 0.9
	_particles.emitting = LayoutTokens.motion_enabled
	if ResourceLoader.exists("res://assets/ui/result/raindrop.svg"):
		_particles.texture = load("res://assets/ui/result/raindrop.svg")
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = Vector2(spread_width * 0.5, 2.0)
	_particles.direction = Vector2(0, 1)
	_particles.spread = 0.0
	_particles.gravity = Vector2.ZERO
	_particles.initial_velocity_min = 220.0
	_particles.initial_velocity_max = 260.0
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	fade.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	_particles.color_ramp = fade
	add_child(_particles)

func start() -> void:
	if LayoutTokens.motion_enabled:
		_particles.emitting = true

func stop() -> void:
	_particles.emitting = false
```

- [ ] **Step 3: Add rain to `fail_screen.gd`**

In `fail_screen.gd:_ensure_nodes()`, after the cloud TextureRect:

```gdscript
var RainLayer = preload("res://scripts/ui/rain_layer.gd")
var rain := RainLayer.new(84.0)
rain.position = Vector2(240, 100)  # centered under cloud
_mascot_host.add_child(rain)
```

Và trong `_play_entrance_animations()`:
```gdscript
# Rain starts with animations
var rain_node := _mascot_host.get_node_or_null("@RainLayer@...") # hoặc lưu reference
```

Thực tế, lưu reference `_rain` trong class vars và gọi `_rain.start()` trong entrance animations.

- [ ] **Step 4: Verify headless**

Run: `rtk godot --headless --path game --quit`
Expected: No crash. CPUParticles2D gracefully does nothing in headless.

- [ ] **Step 5: Commit**

```bash
git add game/scripts/ui/rain_layer.gd game/scripts/screens/fail_screen.gd
git commit -m "feat(ui): add rain particles under cloud on lose screen"
```

---

## Task 5: Confetti — CPUParticles2D Upgrade

**Files:**
- Modify: `game/scripts/ui/confetti_layer.gd`
- Create: `game/assets/ui/result/square_confetti.svg` (nếu chưa có)

**Interfaces:**
- Consumes: `Palette.CONFETTI_COLORS`, `LayoutTokens.motion_enabled`
- Produces: same `ConfettiLayer.new(count)`, `ConfettiLayer.start()` API

- [ ] **Step 1: Check for square texture**

Run: `ls game/assets/ui/result/square*`

Nếu chưa có, tạo `square_confetti.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 12 12">
  <rect width="12" height="12" rx="1" fill="white"/>
</svg>
```

- [ ] **Step 2: Rewrite `confetti_layer.gd` with CPUParticles2D**

```gdscript
# confetti_layer.gd — Falling confetti particles for win screen.
extends Control

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _particles: CPUParticles2D
var _count: int = 40

func _init(count: int = 40) -> void:
	_count = count
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1

func start() -> void:
	if not LayoutTokens.motion_enabled:
		return
	if _particles != null:
		_particles.restart()
		return
	_particles = CPUParticles2D.new()
	_particles.amount = _count
	_particles.lifetime = 5.0
	_particles.preprocess = 1.0
	_particles.emitting = true
	if ResourceLoader.exists("res://assets/ui/result/square_confetti.svg"):
		_particles.texture = load("res://assets/ui/result/square_confetti.svg")
	var sw := size.x if size.x > 0 else 780.0
	_particles.position = Vector2(sw * 0.5, -30.0)
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = Vector2(sw * 0.5, 10.0)
	_particles.direction = Vector2(0, 1)
	_particles.spread = 25.0
	_particles.gravity = Vector2(0, 160)
	_particles.initial_velocity_min = 120.0
	_particles.initial_velocity_max = 260.0
	_particles.angular_velocity_min = -420.0
	_particles.angular_velocity_max = 420.0
	_particles.angle_min = 0.0
	_particles.angle_max = 360.0
	_particles.scale_amount_min = 1.2
	_particles.scale_amount_max = 2.6
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray(Palette.CONFETTI_COLORS)
	var step := 1.0 / float(Palette.CONFETTI_COLORS.size() - 1)
	var offsets: PackedFloat32Array = []
	for i in range(Palette.CONFETTI_COLORS.size()):
		offsets.append(float(i) * step)
	ramp.offsets = offsets
	ramp.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	_particles.color_initial_ramp = ramp
	add_child(_particles)
```

- [ ] **Step 3: Verify backward compatibility**

`win_screen.gd` calls `_confetti.start()` — API unchanged.

Run: `rtk godot --headless --path game --quit`
Expected: No errors. CPUParticles2D does nothing in headless.

- [ ] **Step 4: Commit**

```bash
git add game/scripts/ui/confetti_layer.gd
git commit -m "refactor(ui): confetti uses CPUParticles2D for sharper visual"
```

---

## Task 6: Action Buttons — 3D Depth with border_width_bottom

**Files:**
- Modify: `game/scripts/ui/action_button.gd`

**Interfaces:**
- Produces: same `ActionButton.create()` API, visual improvement only

- [ ] **Step 1: Update `action_button.gd:create()` — replace shadow with border depth**

In the `create()` static method, replace the style block:

```gdscript
static func create(text: String, bg_color: Color, shadow_color: Color, text_shadow_color: Color, font_size: int = 34, height: int = 90, depth: int = 8) -> Button:
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
	style.set_corner_radius_all(24)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	style.border_width_bottom = depth
	style.border_color = shadow_color

	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = bg_color.lightened(0.06)

	var pressed := style.duplicate() as StyleBoxFlat
	pressed.border_width_bottom = 1
	pressed.expand_margin_top = float(-(depth - 1))
	pressed.content_margin_top = 16 + float(depth - 1)

	for state in ["normal", "focus"]:
		btn.add_theme_stylebox_override(state, style)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("hover_pressed", pressed)

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
```

**Note:** Thêm `depth: int = 8` parameter với default value — backward compatible.

- [ ] **Step 2: Verify all callers**

Search for `ActionButton.create(` calls:
- `win_screen.gd` — passes 6 args (text, bg, shadow, text_shadow, font_size, height) → depth defaults to 8 ✅
- `fail_screen.gd` — same pattern ✅
- `title_screen.gd` — same pattern ✅

Run: `rtk godot --headless --path game --quit`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add game/scripts/ui/action_button.gd
git commit -m "feat(ui): 3D depth buttons with border_width_bottom instead of shadow"
```

---

## Task 7: Title Screen — Coordinated Entrance Animation

**Files:**
- Modify: `game/scripts/screens/title_screen.gd`

**Interfaces:**
- Consumes: `TweenHelpers.rise_in`, `TweenHelpers.pulse`, `TweenHelpers.bob` from Task 1
- Preserves: all existing signals and `setup()` signature

- [ ] **Step 1: Add TweenHelpers const at top of title_screen.gd**

```gdscript
const TweenHelpers = preload("res://scripts/ui/tween_helpers.gd")
```

- [ ] **Step 2: Add `_animate_entrance()` method**

Add to `title_screen.gd`:

```gdscript
func _animate_entrance() -> void:
	if not LayoutTokens.motion_enabled:
		return
	# 1. Logo drop + bounce
	var logo: Control = $SafeArea/Frame/HeroBlock/CandyLogo if has_node("SafeArea/Frame/HeroBlock/CandyLogo") else null
	if logo == null:
		for c in get_children():
			logo = _find_child_by_name(c, "CandyLogo")
			if logo != null: break
	if logo != null:
		logo.pivot_offset = logo.size / 2.0
		logo.scale = Vector2(0.6, 0.6)
		logo.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(logo, "modulate:a", 1.0, 0.2)
		tw.parallel().tween_property(logo, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func(): TweenHelpers.bob(logo, 8.0, 3.2))

	# 2. Speech bubble pop (delay 1.2s)
	if _hero_mascot != null and _hero_mascot._bubble != null:
		var bubble: Control = _hero_mascot._bubble
		bubble.pivot_offset = Vector2(bubble.size.x / 2.0, bubble.size.y)
		bubble.scale = Vector2.ZERO
		var btw := create_tween()
		btw.tween_interval(1.2)
		btw.tween_property(bubble, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 3. Mascot drop_in (delay 0.4s)
	if _hero_mascot != null and _hero_mascot.mascot != null:
		_hero_mascot.mascot.drop_in(0.4)

	# 4. Progress card rise_in (delay 0.8s)
	if _progress_bar != null:
		TweenHelpers.rise_in(_progress_bar, 0.8)

	# 5. Play button rise_in (delay 1.0s) + pulse (delay 1.9s)
	if play_btn != null:
		TweenHelpers.rise_in(play_btn, 1.0)
		get_tree().create_timer(1.9).timeout.connect(func():
			if is_instance_valid(play_btn):
				TweenHelpers.pulse(play_btn, 0.0)
		)
```

- [ ] **Step 3: Call `_animate_entrance()` from `_ready()`**

In `title_screen.gd:_ready()`, add after `_update_ui()`:

```gdscript
_animate_entrance()
```

- [ ] **Step 4: Helper to find named child**

Nếu cần, thêm:
```gdscript
func _find_child_by_name(node: Node, n: String) -> Control:
	if node.name == n and node is Control:
		return node as Control
	for c in node.get_children():
		var found := _find_child_by_name(c, n)
		if found != null:
			return found
	return null
```

Hoặc dùng built-in `find_child("CandyLogo", true, false)`.

- [ ] **Step 5: Verify entrance plays correctly**

Run: `rtk godot --headless --path game --quit`
Expected: No errors.

- [ ] **Step 6: Verify motion_enabled=false**

In headless test or manual: set `LayoutTokens.motion_enabled = false`, ensure no animations run, elements shown at final state.

- [ ] **Step 7: Commit**

```bash
git add game/scripts/screens/title_screen.gd
git commit -m "feat(screens): coordinated entrance animation for title screen"
```

---

## Task 8: Win Screen — Use TweenHelpers + Updated Animations

**Files:**
- Modify: `game/scripts/screens/win_screen.gd`

**Interfaces:**
- Consumes: `TweenHelpers` from Task 1, updated `ribbon.animate()` from Task 2

- [ ] **Step 1: Add TweenHelpers const**

```gdscript
const TweenHelpers = preload("res://scripts/ui/tween_helpers.gd")
```

- [ ] **Step 2: Update `_play_entrance_animations()`**

Enhance the existing method:

```gdscript
func _play_entrance_animations() -> void:
	if not LayoutTokens.motion_enabled: return
	if _confetti != null: _confetti.start()
	if ribbon != null: ribbon.animate()  # now drops from top (Task 2)
	if _hearts != null: _hearts.animate()
	if stat_card != null: stat_card.animate(0.4)
	if _next_card != null:
		TweenHelpers.rise_in(_next_card, 1.3)
	if mascot != null:
		mascot.drop_in(0.8)
		get_tree().create_timer(2.2).timeout.connect(func():
			if is_instance_valid(mascot):
				mascot.celebrate()
		)
	if next_btn != null:
		get_tree().create_timer(2.0).timeout.connect(func():
			if is_instance_valid(next_btn):
				TweenHelpers.pulse(next_btn, 0.0)
		)
```

- [ ] **Step 3: Verify headless**

Run: `rtk godot --headless --path game --quit`

- [ ] **Step 4: Commit**

```bash
git add game/scripts/screens/win_screen.gd
git commit -m "feat(screens): enhanced win screen animations with tween helpers"
```

---

## Task 9: Integration Verification

**Files:**
- No new files

- [ ] **Step 1: Full headless gate**

```bash
rtk godot --headless --path game --quit
```

Expected: No errors, clean exit.

- [ ] **Step 2: Clean-room check**

```bash
rtk proxy rg -n "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/
```

Expected: no matches.

- [ ] **Step 3: No extracted_reusable imports**

```bash
rtk proxy rg -n "extracted_reusable" game/scripts/ game/tests/
```

Expected: no matches.

- [ ] **Step 4: Module size check**

```bash
wc -l game/scripts/ui/tween_helpers.gd game/scripts/ui/rain_layer.gd game/scripts/ui/confetti_layer.gd game/scripts/ui/action_button.gd game/scripts/ui/heart_display.gd game/scripts/ui/ribbon_banner.gd game/scripts/screens/win_screen.gd game/scripts/screens/fail_screen.gd game/scripts/screens/title_screen.gd
```

Expected: tất cả ≤ 300 dòng.

- [ ] **Step 5: Commit verification results**

Ghi kết quả vào `scratch/verification/visual-polish-gate.md`.

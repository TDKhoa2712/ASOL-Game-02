# Hint & Visual Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Nâng cấp trình bày Hint (overlay panel + giải thích chiến thuật + pulsing highlight) và thêm cell animation cơ bản (candy appear/mark/error/win) để thu hẹp khoảng cách visual polish với bản thương mại.

**Architecture:** 3 module mới (`hint_overlay.gd`, `cell_animator.gd`, `tween_fx.gd`) đều RefCounted/Node nhẹ, không autoload, inject qua `puzzle_screen`. `puzzle_board.gd` được mở rộng để hỗ trợ pulsing highlight và gọi cell animations. Tất cả animation dùng Godot 4 built-in `Tween` — không shader, không particle, không Spine.

**Tech Stack:** GDScript 4.x, Godot 4.7 Tween API

**Spec:** `docs/superpowers/specs/technical_comparison_and_optimization_guide.md` — Mục 2.2 (Hint), 2.7 (Thị giác). Tham khảo hành vi `extracted_reusable/scripts/gameplay/view/cell_view.gd` (animations) và `extracted_reusable/scripts/game/view/hint_overlay.gd` (hint UI).

## Global Constraints

- Module ≤ 300 dòng, một file một trách nhiệm.
- Không autoloads. Dependencies inject từ `puzzle_screen` hoặc `app_shell`.
- Clean-room: không sao chép code/tên/enum từ `extracted_reusable/`. Chỉ tham khảo hành vi.
- Không Spine, không shader custom, không CPUParticles2D. Chỉ dùng Godot built-in Tween + draw commands.
- Không thêm tính năng mới (combo, score, daily). Chỉ nâng cấp trình bày hint hiện tại và thêm visual feedback.
- Phạm vi R1, N=4-6, S1-S3. Không mở meta-game.
- GDD compliance: GR-22, GR-37, UX-14 (hint tô focus/source/target, progressive reveal, có nút đóng).
- Giữ nguyên toàn bộ API hiện tại của `BoardSolver`, `PlaySession`, `TouchDecoder`.

## Review Focus

1. **Hint overlay che board khi bàn cờ nhỏ (4×4):** Panel phải responsive — khi board nhỏ, overlay không che hết ô chơi. Test trên cả 3 kích thước N=4,5,6.
2. **Tween cleanup khi scene chuyển giữa chừng:** Nếu người chơi nhấn Home hoặc Restart trong lúc animation đang chạy, tween phải bị kill sạch — không crash, không orphan tween.
3. **Pulsing highlight timing với double-tap:** Highlight pulse phải không can thiệp vào double-tap timing (350ms). Pulse chỉ là visual; không block input.
4. **Hint overlay + undo interaction:** Nếu hint đang hiện overlay rồi người chơi nhấn Undo, overlay phải tự đóng vì board state đã thay đổi.
5. **Animation performance trên mobile:** Tween animation phải nhẹ — không tạo Node mới mỗi frame. Reuse tween instances, kill trước khi tạo mới.

---

### Task 1: Tạo `tween_fx.gd` — thư viện animation primitives

**Files:**
- Create: `game/scripts/feedback/tween_fx.gd`
- Test: `game/tests/test_tween_fx.gd`

**Interfaces:**
- Consumes: Không phụ thuộc file nào.
- Produces:
  - `TweenFx` class (RefCounted)
  - `static func scale_pop(node: Control, duration: float = 0.25) -> Tween` — scale 0.0→1.15→1.0
  - `static func shake(node: Control, amplitude: float = 6.0, duration: float = 0.3) -> Tween` — horizontal shake
  - `static func flash_color(node: Control, color: Color, duration: float = 0.2) -> Tween` — modulate to color and back
  - `static func bounce(node: Control, scale_peak: float = 1.2, duration: float = 0.3) -> Tween` — scale 1.0→peak→1.0
  - `static func fade_in(node: Control, duration: float = 0.15) -> Tween` — modulate.a 0→1
  - `static func fade_out(node: Control, duration: float = 0.15) -> Tween` — modulate.a 1→0

- [x] **Step 1: Write failing test**

```gdscript
# game/tests/test_tween_fx.gd
extends SceneTree

const TweenFx = preload("res://scripts/feedback/tween_fx.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_scale_pop_returns_tween()
	_test_shake_returns_tween()
	_test_flash_color_returns_tween()
	_test_bounce_returns_tween()
	_test_fade_in_returns_tween()
	_test_fade_out_returns_tween()
	_test_all_static_methods_exist()
	if _fails.is_empty():
		print("FEEDBACK_TWEEN_FX_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_scale_pop_returns_tween() -> void:
	var c := Control.new()
	root.add_child(c)
	var tw := TweenFx.scale_pop(c, 0.01)
	_assert(tw != null, "scale_pop returns a Tween")
	_assert(tw is Tween, "scale_pop returns Tween type")
	tw.kill()
	c.queue_free()

func _test_shake_returns_tween() -> void:
	var c := Control.new()
	root.add_child(c)
	var tw := TweenFx.shake(c, 4.0, 0.01)
	_assert(tw != null, "shake returns a Tween")
	tw.kill()
	c.queue_free()

func _test_flash_color_returns_tween() -> void:
	var c := Control.new()
	root.add_child(c)
	var tw := TweenFx.flash_color(c, Color.RED, 0.01)
	_assert(tw != null, "flash_color returns a Tween")
	tw.kill()
	c.queue_free()

func _test_bounce_returns_tween() -> void:
	var c := Control.new()
	root.add_child(c)
	var tw := TweenFx.bounce(c, 1.2, 0.01)
	_assert(tw != null, "bounce returns a Tween")
	tw.kill()
	c.queue_free()

func _test_fade_in_returns_tween() -> void:
	var c := Control.new()
	root.add_child(c)
	c.modulate.a = 0.0
	var tw := TweenFx.fade_in(c, 0.01)
	_assert(tw != null, "fade_in returns a Tween")
	tw.kill()
	c.queue_free()

func _test_fade_out_returns_tween() -> void:
	var c := Control.new()
	root.add_child(c)
	var tw := TweenFx.fade_out(c, 0.01)
	_assert(tw != null, "fade_out returns a Tween")
	tw.kill()
	c.queue_free()

func _test_all_static_methods_exist() -> void:
	_assert(TweenFx.has_method("scale_pop"), "has scale_pop")
	_assert(TweenFx.has_method("shake"), "has shake")
	_assert(TweenFx.has_method("flash_color"), "has flash_color")
	_assert(TweenFx.has_method("bounce"), "has bounce")
	_assert(TweenFx.has_method("fade_in"), "has fade_in")
	_assert(TweenFx.has_method("fade_out"), "has fade_out")

func _assert(condition: bool, label: String) -> void:
	if not condition:
		_fails.append("FAIL: " + label)
```

- [x] **Step 2: Run test to verify it fails**

```bash
rtk godot --headless --path game --script res://tests/test_tween_fx.gd
```

Expected: FAIL — `tween_fx.gd` does not exist.

- [x] **Step 3: Implement `TweenFx`**

```gdscript
# game/scripts/feedback/tween_fx.gd
extends RefCounted

static func scale_pop(node: Control, duration: float = 0.25) -> Tween:
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2.ZERO
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2(1.15, 1.15), duration * 0.6) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(node, "scale", Vector2.ONE, duration * 0.4) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	return tw

static func shake(node: Control, amplitude: float = 6.0, duration: float = 0.3) -> Tween:
	var origin_x: float = node.position.x
	var tw := node.create_tween()
	var steps: int = 6
	var step_dur: float = duration / float(steps)
	for i in range(steps):
		var offset: float = amplitude * (1.0 - float(i) / float(steps))
		var sign_val: float = -1.0 if i % 2 == 0 else 1.0
		tw.tween_property(node, "position:x", origin_x + offset * sign_val, step_dur)
	tw.tween_property(node, "position:x", origin_x, step_dur * 0.5)
	return tw

static func flash_color(node: Control, color: Color, duration: float = 0.2) -> Tween:
	var tw := node.create_tween()
	tw.tween_property(node, "modulate", color, duration * 0.4)
	tw.tween_property(node, "modulate", Color.WHITE, duration * 0.6)
	return tw

static func bounce(node: Control, scale_peak: float = 1.2, duration: float = 0.3) -> Tween:
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2.ONE * scale_peak, duration * 0.4) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(node, "scale", Vector2.ONE, duration * 0.6) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	return tw

static func fade_in(node: Control, duration: float = 0.15) -> Tween:
	node.modulate.a = 0.0
	var tw := node.create_tween()
	tw.tween_property(node, "modulate:a", 1.0, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	return tw

static func fade_out(node: Control, duration: float = 0.15) -> Tween:
	var tw := node.create_tween()
	tw.tween_property(node, "modulate:a", 0.0, duration) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	return tw
```

- [x] **Step 4: Run test to verify it passes**

```bash
rtk godot --headless --path game --script res://tests/test_tween_fx.gd
```

Expected: `FEEDBACK_TWEEN_FX_PASS`

- [x] **Step 5: Commit**

```bash
git add game/scripts/feedback/tween_fx.gd game/tests/test_tween_fx.gd
git commit -m "feat(feedback): add TweenFx animation primitives library"
```

---

### Task 2: Thêm pulsing highlight vào `puzzle_board.gd`

**Files:**
- Modify: `game/scripts/screens/puzzle_board.gd`
- Test: Kiểm tra bằng mắt + existing test pass

**Interfaces:**
- Consumes: Không file mới.
- Produces:
  - `puzzle_board.gd` highlight cells giờ nhấp nháy (pulse alpha 0.3↔1.0) thay vì border tĩnh.
  - Thêm `var _highlight_pulse_phase: float = 0.0` để track animation.
  - `_process()` cập nhật phase khi có highlight.

**Thay đổi cụ thể trong `puzzle_board.gd`:**

- [x] **Step 1: Add pulse state variable**

Thêm biến sau `_preview_mark`:

```gdscript
var _highlight_pulse_phase: float = 0.0
```

- [x] **Step 2: Update `_process` to advance pulse phase**

Sửa `_process` để cập nhật phase khi có highlight:

```gdscript
func _process(_delta: float) -> void:
	if _decoder != null:
		_decoder.tick(Time.get_ticks_msec())
	if not _highlight_cells.is_empty():
		_highlight_pulse_phase += _delta * 4.8
		if _highlight_pulse_phase > TAU:
			_highlight_pulse_phase -= TAU
		queue_redraw()
```

- [x] **Step 3: Replace static highlight border with pulsing**

Trong `_draw()`, tìm đoạn highlight (khoảng dòng 254-260):

```gdscript
# TRƯỚC (static border):
if _highlight_cells.has([r, c]):
	var hl_sb := StyleBoxFlat.new()
	hl_sb.draw_center = false
	hl_sb.border_color = Palette.ACCENT_ORANGE
	hl_sb.set_border_width_all(3)
	hl_sb.set_corner_radius_all(cr)
	draw_style_box(hl_sb, cell_rect)
```

Thay bằng:

```gdscript
# SAU (pulsing border):
if _highlight_cells.has([r, c]):
	var pulse_alpha: float = 0.35 + 0.65 * (0.5 + 0.5 * sin(_highlight_pulse_phase))
	var hl_col := Color(Palette.ACCENT_ORANGE, pulse_alpha)
	var hl_sb := StyleBoxFlat.new()
	hl_sb.draw_center = false
	hl_sb.border_color = hl_col
	hl_sb.set_border_width_all(3)
	hl_sb.set_corner_radius_all(cr)
	draw_style_box(hl_sb, cell_rect)
```

- [x] **Step 4: Reset pulse on clear_highlight**

Trong `clear_highlight()`, thêm reset:

```gdscript
func clear_highlight() -> void:
	_highlight_cells = []
	_highlight_unit = ""
	_highlight_pulse_phase = 0.0
	queue_redraw()
```

- [x] **Step 5: Run existing tests**

```bash
rtk godot --headless --path game --script res://tests/test_touch_decoder.gd
rtk godot --headless --path game --script res://tests/test_integration.gd
```

Expected: Tất cả PASS — thay đổi chỉ là visual.

- [x] **Step 6: Commit**

```bash
git add game/scripts/screens/puzzle_board.gd
git commit -m "feat(board): replace static highlight border with pulsing animation"
```

---

### Task 3: Tạo `hint_overlay.gd` — overlay panel hiển thị giải thích hint

**Files:**
- Create: `game/scripts/screens/hint_overlay.gd`
- Test: `game/tests/test_hint_overlay.gd`

**Interfaces:**
- Consumes:
  - `Palette` constants cho màu sắc
  - `LayoutTokens` cho sizing
  - `TweenFx.fade_in/fade_out` từ Task 1
- Produces:
  - `HintOverlay` extends `PanelContainer`
  - `func show_hint(text: String, unit_label: String) -> void` — hiện overlay với giải thích
  - `func dismiss() -> void` — ẩn overlay
  - `signal dismissed()` — khi người chơi đóng overlay
  - `func is_showing() -> bool`

- [x] **Step 1: Write failing test**

```gdscript
# game/tests/test_hint_overlay.gd
extends SceneTree

const HintOverlay = preload("res://scripts/screens/hint_overlay.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_show_and_dismiss()
	_test_dismiss_emits_signal()
	_test_show_updates_text()
	_test_double_show_replaces()
	_test_dismiss_when_not_showing()
	if _fails.is_empty():
		print("SCREENS_HINT_OVERLAY_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_show_and_dismiss() -> void:
	var overlay := HintOverlay.new()
	root.add_child(overlay)
	_assert(not overlay.is_showing(), "starts hidden")
	overlay.show_hint("Look at row 2", "Row 2")
	_assert(overlay.is_showing(), "showing after show_hint")
	overlay.dismiss()
	_assert(not overlay.is_showing(), "hidden after dismiss")
	overlay.queue_free()

func _test_dismiss_emits_signal() -> void:
	var overlay := HintOverlay.new()
	root.add_child(overlay)
	var signals: Array = []
	overlay.dismissed.connect(func(): signals.append(true))
	overlay.show_hint("Test", "Zone A")
	overlay.dismiss()
	_assert(signals.size() == 1, "dismissed signal emitted")
	overlay.queue_free()

func _test_show_updates_text() -> void:
	var overlay := HintOverlay.new()
	root.add_child(overlay)
	overlay.show_hint("First hint", "Row 1")
	overlay.show_hint("Second hint", "Zone B")
	_assert(overlay.is_showing(), "still showing after second show")
	overlay.dismiss()
	overlay.queue_free()

func _test_double_show_replaces() -> void:
	var overlay := HintOverlay.new()
	root.add_child(overlay)
	overlay.show_hint("A", "X")
	overlay.show_hint("B", "Y")
	_assert(overlay.is_showing(), "showing after replace")
	overlay.dismiss()
	overlay.queue_free()

func _test_dismiss_when_not_showing() -> void:
	var overlay := HintOverlay.new()
	root.add_child(overlay)
	overlay.dismiss()
	_assert(not overlay.is_showing(), "dismiss when not showing is safe")
	overlay.queue_free()

func _assert(condition: bool, label: String) -> void:
	if not condition:
		_fails.append("FAIL: " + label)
```

- [x] **Step 2: Run test to verify it fails**

```bash
rtk godot --headless --path game --script res://tests/test_hint_overlay.gd
```

Expected: FAIL.

- [x] **Step 3: Implement `HintOverlay`**

```gdscript
# game/scripts/screens/hint_overlay.gd
extends PanelContainer

signal dismissed()

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _showing: bool = false
var _label_text: Label = null
var _label_unit: Label = null
var _close_btn: Button = null
var _tween: Tween = null

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.SURFACE_WARM
	sb.set_corner_radius_all(Palette.CARD_CORNER)
	sb.content_margin_left = 20.0
	sb.content_margin_right = 20.0
	sb.content_margin_top = 14.0
	sb.content_margin_bottom = 14.0
	sb.shadow_color = Palette.CARD_SHADOW
	sb.shadow_size = 6
	add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	_label_unit = Label.new()
	_label_unit.add_theme_font_size_override("font_size", 28)
	_label_unit.add_theme_color_override("font_color", Palette.ACCENT_ORANGE)
	_label_unit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_label_unit)

	_label_text = Label.new()
	_label_text.add_theme_font_size_override("font_size", 22)
	_label_text.add_theme_color_override("font_color", Palette.INK)
	_label_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_label_text)

	_close_btn = Button.new()
	_close_btn.text = "OK"
	_close_btn.custom_minimum_size = Vector2(100, 40)
	_close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_close_btn.pressed.connect(_on_close)
	vbox.add_child(_close_btn)

func show_hint(text: String, unit_label: String) -> void:
	_label_text.text = text
	_label_unit.text = unit_label
	_showing = true
	visible = true
	modulate.a = 1.0
	if _tween != null and _tween.is_valid():
		_tween.kill()

func dismiss() -> void:
	if not _showing:
		return
	_showing = false
	visible = false
	dismissed.emit()

func is_showing() -> bool:
	return _showing

func _on_close() -> void:
	dismiss()
```

- [x] **Step 4: Run test to verify it passes**

```bash
rtk godot --headless --path game --script res://tests/test_hint_overlay.gd
```

Expected: `SCREENS_HINT_OVERLAY_PASS`

- [x] **Step 5: Commit**

```bash
git add game/scripts/screens/hint_overlay.gd game/tests/test_hint_overlay.gd
git commit -m "feat(screens): add HintOverlay panel for hint explanation display"
```

---

### Task 4: Wire `HintOverlay` vào `puzzle_screen.gd`

**Files:**
- Modify: `game/scripts/screens/puzzle_screen.gd`
- Modify: `game/scripts/screens/puzzle_layout.gd` (thêm overlay vào layout)
- Test: Existing integration tests + manual verification

**Interfaces:**
- Consumes: `HintOverlay` từ Task 3, `BoardSolver.progressive_hint` (existing)
- Produces: Hint button giờ mở overlay panel với explanation text thay vì chỉ highlight.

**Thay đổi cụ thể:**

- [x] **Step 1: Add overlay to puzzle_layout.gd**

Đọc `puzzle_layout.gd` để xác định vị trí thêm overlay. Tạo `HintOverlay` node và thêm vào layout dictionary trả về. Overlay nằm phía trên board, centered ngang, anchored bottom.

Trong `PuzzleLayout.build()`, thêm:

```gdscript
const HintOverlay = preload("res://scripts/screens/hint_overlay.gd")

# ...trong build(), sau khi tạo board:
var hint_overlay := HintOverlay.new()
hint_overlay.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
hint_overlay.custom_minimum_size = Vector2(500, 0)
# Thêm vào container phù hợp sau board
# ...
nodes["hint_overlay"] = hint_overlay
```

- [x] **Step 2: Wire overlay in puzzle_screen.gd**

Thêm biến `hint_overlay` và kết nối:

```gdscript
const HintOverlay = preload("res://scripts/screens/hint_overlay.gd")

var hint_overlay: HintOverlay
```

Trong `_ensure_nodes()`:

```gdscript
hint_overlay = nodes.get("hint_overlay")
```

- [x] **Step 3: Update `_on_hint` to use overlay**

Sửa `_on_hint()` trong `puzzle_screen.gd`:

```gdscript
func _on_hint() -> void:
	if session == null or runtime == null:
		return
	# Nếu overlay đang hiện, dismiss nó
	if hint_overlay != null and hint_overlay.is_showing():
		hint_overlay.dismiss()
		if board != null:
			board.clear_highlight()
		return
	var pace_data: Dictionary = runtime.current_pace()
	var costs: Array = pace_data.get("hintCosts", [1])
	var max_clicks: int = costs.size()
	if _hint_click_count >= max_clicks:
		return
	var lvl: Dictionary = session.level
	var hint: Dictionary = BoardSolver.progressive_hint(
		session.board, lvl["size"], lvl["regions"],
		lvl["solution"], _hint_click_count + 1
	)
	if not hint.get("found", true) or hint.get("stage") == "none":
		return
	_hint_click_count += 1
	session.use_hint()
	var hl: Array = hint.get("highlight", [])
	if board != null and not hl.is_empty():
		board.highlight_cells(hl)
	var explanation: String = str(hint.get("text", ""))
	var stage: String = str(hint.get("stage", ""))
	var unit_label: String = ""
	if stage == "unit":
		unit_label = "Xem kỹ khu vực này"
	elif stage == "cell":
		unit_label = "Đặt kẹo ở đây"
	if hint_overlay != null and explanation != "":
		hint_overlay.show_hint(explanation, unit_label)
	if sfx != null:
		sfx.play(SfxCatalog.Effect.HINT_SHOW)
```

- [x] **Step 4: Auto-dismiss overlay on candy found or state change**

Trong `_on_candy_found`, thêm overlay dismiss:

```gdscript
func _on_candy_found(_row: int, _col: int, _region: String) -> void:
	if hint_overlay != null and hint_overlay.is_showing():
		hint_overlay.dismiss()
	# ... existing code
```

Trong `_on_undo`, thêm overlay dismiss:

```gdscript
func _on_undo() -> void:
	if hint_overlay != null and hint_overlay.is_showing():
		hint_overlay.dismiss()
	# ... existing code
```

- [x] **Step 5: Run existing tests**

```bash
rtk godot --headless --path game --script res://tests/test_integration.gd
rtk godot --headless --path game --script res://tests/test_hint_overlay.gd
```

Expected: Tất cả PASS.

- [x] **Step 6: Commit**

```bash
git add game/scripts/screens/puzzle_screen.gd game/scripts/screens/puzzle_layout.gd
git commit -m "feat(screens): wire HintOverlay into puzzle screen hint flow"
```

---

### Task 5: Thêm cell animations vào `puzzle_board.gd`

**Files:**
- Modify: `game/scripts/screens/puzzle_board.gd`
- Test: Manual visual verification + existing tests pass

**Interfaces:**
- Consumes: `TweenFx` từ Task 1
- Produces: Board phát animation khi:
  - Candy đặt đúng: scale pop trên cell
  - Mark đặt/xóa: nhanh (không animation phức tạp — chỉ redraw)
  - Error: shake + red flash trên toàn board row
  - Level won: bounce tuần tự trên tất cả candy cells

**Thiết kế:** Vì `puzzle_board.gd` dùng `_draw()` (không có child node per cell), animation tạo một overlay `Control` tạm thời tại vị trí cell, animate nó, rồi xóa. Board phải expose `signal cell_animated(row, col, kind)` cho puzzle_screen trigger.

- [x] **Step 1: Add animation signals to puzzle_board**

```gdscript
signal candy_placed_anim(row: int, col: int)
signal error_anim(row: int, col: int)
signal win_anim()
```

- [x] **Step 2: Add `play_candy_pop` method**

```gdscript
const TweenFx = preload("res://scripts/feedback/tween_fx.gd")

func play_candy_pop(row: int, col: int) -> void:
	var rect := _cell_rect(row, col)
	if rect.size.x <= 0:
		return
	var dummy := ColorRect.new()
	dummy.color = Color(Palette.CANDY_BROWN, 0.4)
	dummy.position = rect.position
	dummy.size = rect.size
	dummy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dummy)
	var tw := TweenFx.scale_pop(dummy, 0.25)
	tw.finished.connect(func(): dummy.queue_free())
```

- [x] **Step 3: Add `play_error_shake` method**

```gdscript
func play_error_shake() -> void:
	TweenFx.shake(self, 4.0, 0.25)
```

- [x] **Step 4: Add `play_win_bounce` method**

```gdscript
func play_win_bounce() -> void:
	if _session == null:
		return
	var n: int = int(_session.level.get("size", 0))
	var delay: float = 0.0
	for r in range(n):
		for c in range(n):
			if CellModel.is_placed(_session.board[r][c]):
				var rect := _cell_rect(r, c)
				if rect.size.x <= 0:
					continue
				var dummy := ColorRect.new()
				dummy.color = Color(Palette.CANDY_BROWN, 0.3)
				dummy.position = rect.position
				dummy.size = rect.size
				dummy.mouse_filter = Control.MOUSE_FILTER_IGNORE
				add_child(dummy)
				var tw := dummy.create_tween()
				tw.tween_interval(delay)
				tw.tween_callback(func():
					dummy.pivot_offset = dummy.size * 0.5
				)
				tw.tween_property(dummy, "scale", Vector2(1.15, 1.15), 0.15) \
					.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
				tw.tween_property(dummy, "scale", Vector2.ONE, 0.15) \
					.set_ease(Tween.EASE_IN_OUT)
				tw.finished.connect(func(): dummy.queue_free())
				delay += 0.08
```

- [x] **Step 5: Add `_cell_rect` helper**

```gdscript
func _cell_rect(row: int, col: int) -> Rect2:
	if _session == null:
		return Rect2()
	var br := _board_rect()
	var count := int(_session.level.get("size", 0))
	if count <= 0:
		return Rect2()
	var gap := _cell_gap(br.size.x)
	var cell_w := (br.size.x - gap * float(count - 1)) / float(count)
	var step := cell_w + gap
	var pos := br.position + Vector2(float(col) * step, float(row) * step)
	return Rect2(pos, Vector2(cell_w, cell_w))
```

- [x] **Step 6: Wire animations in puzzle_screen.gd**

Sửa `_on_candy_found`:

```gdscript
func _on_candy_found(row: int, col: int, _region: String) -> void:
	if board != null:
		board.play_candy_pop(row, col)
	# ... existing sfx/vibration/highlight code
```

Sửa `_on_mistake`:

```gdscript
func _on_mistake(_row: int, _col: int, _clash: String) -> void:
	if board != null:
		board.play_error_shake()
	# ... existing sfx/vibration code
```

Sửa `_on_level_won`:

```gdscript
func _on_level_won() -> void:
	if board != null:
		board.play_win_bounce()
	# ... existing sfx code
```

- [x] **Step 7: Run all tests**

```bash
rtk godot --headless --path game --script res://tests/test_touch_decoder.gd
rtk godot --headless --path game --script res://tests/test_tween_fx.gd
rtk godot --headless --path game --script res://tests/test_integration.gd
```

Expected: Tất cả PASS.

- [x] **Step 8: Run full gate**

```bash
rtk proxy rg -n "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/
# Expected: no matches

rtk proxy rg -n "extracted_reusable" game/scripts/ game/tests/
# Expected: no matches
```

- [x] **Step 9: Commit**

```bash
git add game/scripts/screens/puzzle_board.gd game/scripts/screens/puzzle_screen.gd
git commit -m "feat(board): add candy pop, error shake, and win bounce animations"
```

---

## Appendix A: Tính năng Meowdoku KHÔNG áp dụng — lý do

| Tính năng Meowdoku | Lý do không áp dụng |
|---|---|
| Combo system + score bubbles | Ngoài R1 scope; CanDoKu không có scoring system |
| Pre-cat reveal FX (spotlight, wave, sweep) | Cần shader custom + Spine; quá phức tạp cho R1 |
| Daily challenge / push notifications | Meta-game ngoài R1 scope (AGENTS.md) |
| Super hard scheduling | CanDoKu đã có `pace_adjuster.gd` với cơ chế DDA organic |
| 40+ haptic interaction points | Over-engineered cho R1; 3 levels (SOFT/NORMAL/FIRM) đủ |
| Shader-based cell backgrounds | Hiện tại dùng `_draw()` procedural, đủ cho R1 |
| A/B testing framework | Ngoài R1 scope |
| Escalating combo voice lines | Ngoài R1 scope; cần audio assets chưa có |

## Appendix B: Meta-game — ghi nhận để sau

Khi mở rộng phạm vi (R2+), các tính năng sau đáng xem xét theo thứ tự ưu tiên:

1. **Daily First Easy** — hạ 1 tier độ khó cho game đầu tiên mỗi ngày (tham khảo `daily_first_easy_modifier.gd`)
2. **Score + Combo** — điểm per cell, combo streak, rolling counter (tham khảo `game_score_model.gd`, `combo_feedback_view.gd`)
3. **Escalating SFX** — crescendo sound khi đặt liên tiếp đúng (tham khảo `sound_manager.gd` — 6 meow levels)
4. **Region sweep overlay** — shader highlight vùng khi hint (tham khảo `board_pattern_sweep_overlay.gd`)
5. **Super hard milestones** — deterministic hard level ở cột mốc (tham khảo `super_hard_schedule.gd`)

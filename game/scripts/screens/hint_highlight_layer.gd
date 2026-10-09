extends Control

signal dismiss_requested()

const CellModel = preload("res://scripts/core/cell_model.gd")
const CellAnimator = preload("res://scripts/screens/cell_animator.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _hint: Dictionary = {}
var _chain: Dictionary = {}
var _cell_rect_fn: Callable
var _backdrop: ColorRect = null
var _showing: bool = false
var _pulse_phase: float = 0.0
var _badge_tweens: Array = []
var _badge_scales: Array = []
var _size: int = 0
var _focus_set: Dictionary = {}
var _scrim_style: StyleBoxFlat = StyleBoxFlat.new()
var _bob_style: StyleBoxFlat = StyleBoxFlat.new()
var _target_style: StyleBoxFlat = StyleBoxFlat.new()

const HIGHLIGHT_COLOR := Color(0.96, 0.62, 0.04)  # #F59E0B
const SCRIM_COLOR := Color(0.35, 0.20, 0.06, 0.32)  # Warm spotlight scrim matching the cream board
const CHAIN_HYPOTHESIS := Color(0.94, 0.27, 0.27)  # #EF4444
const CHAIN_STEP := Color(0.96, 0.62, 0.04)  # #F59E0B
const CHAIN_CONTRA := Color(0.86, 0.15, 0.15)  # #DC2626
const GHOST_ALPHA := 0.4
const BADGE_RADIUS_RATIO := 0.25

func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scrim_style.bg_color = SCRIM_COLOR
	_bob_style.draw_center = true
	_target_style.draw_center = false
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0, 0, 0, 0.01)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.visible = false
	_backdrop.gui_input.connect(_on_backdrop_input)
	add_child(_backdrop)

func show_hint(hint: Dictionary, cell_rect_fn: Callable, board_size: int = 0) -> void:
	_hint = hint
	_chain = {}
	_cell_rect_fn = cell_rect_fn
	_size = board_size if board_size > 0 else int(hint.get("size", 0))
	_showing = true
	visible = true
	_pulse_phase = 0.0
	_recompute_focus_set()
	if _backdrop != null:
		_backdrop.visible = true
	_kill_badge_tweens()
	queue_redraw()

func show_chain_detail(chain_detail: Dictionary, cell_rect_fn: Callable) -> void:
	_chain = chain_detail
	_cell_rect_fn = cell_rect_fn
	_showing = true
	visible = true
	_recompute_focus_set()
	if _backdrop != null:
		_backdrop.visible = true
	_kill_badge_tweens()
	_badge_scales.clear()
	var total: int = 1 + chain_detail.get("steps", []).size() + 1
	for i in range(total):
		_badge_scales.append(0.0)
	for i in range(total):
		var tw := create_tween()
		if tw != null:
			tw.tween_interval(float(i) * 0.05)
			var idx := i
			tw.tween_method(func(v: float):
				if idx < _badge_scales.size():
					_badge_scales[idx] = v
				queue_redraw()
			, 0.0, 1.0, 0.15)
			_badge_tweens.append(tw)
	queue_redraw()

func clear() -> void:
	_hint = {}
	_chain = {}
	_focus_set.clear()
	_size = 0
	_showing = false
	visible = false
	if _backdrop != null:
		_backdrop.visible = false
	_kill_badge_tweens()
	_badge_scales.clear()
	queue_redraw()

func is_showing() -> bool:
	return _showing

func is_cell_focused(row: int, col: int) -> bool:
	return _focus_set.has(Vector2i(row, col))

func _recompute_focus_set() -> void:
	_focus_set.clear()
	for cell in _hint.get("highlight_cells", []):
		if cell.size() >= 2:
			_focus_set[Vector2i(int(cell[0]), int(cell[1]))] = true
	for cell in _hint.get("eliminated_cells", []):
		if cell.size() >= 2:
			_focus_set[Vector2i(int(cell[0]), int(cell[1]))] = true
	var target: Array = _hint.get("target_cell", [])
	if target.size() >= 2:
		_focus_set[Vector2i(int(target[0]), int(target[1]))] = true
	var hyp: Array = _chain.get("hypothesis_cell", [])
	if hyp.size() >= 2:
		_focus_set[Vector2i(int(hyp[0]), int(hyp[1]))] = true
	for step in _chain.get("steps", []):
		if step.size() >= 2:
			_focus_set[Vector2i(int(step[0]), int(step[1]))] = true

func _process(delta: float) -> void:
	if _showing:
		_pulse_phase += delta * 4.8
		if _pulse_phase > TAU:
			_pulse_phase -= TAU
		queue_redraw()

func _on_backdrop_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		dismiss_requested.emit()
		accept_event()

func _draw() -> void:
	if not _showing or _hint.is_empty():
		return
	if not _cell_rect_fn.is_valid():
		return

	if _size > 0:
		for r in range(_size):
			for c in range(_size):
				if not _focus_set.has(Vector2i(r, c)):
					var rect: Rect2 = _cell_rect_fn.call(r, c)
					if rect.size.x > 0:
						_scrim_style.set_corner_radius_all(int(rect.size.x * 0.12))
						draw_style_box(_scrim_style, rect)

	var bob_t: float = 0.5 - 0.5 * cos(_pulse_phase) if LayoutTokens.motion_enabled else 0.5
	var bob_scale: float = 1.0 + bob_t * 0.08
	var bob_y: float = -bob_t * 3.5

	_bob_style.bg_color = Color(1.0, 0.84, 0.22, 0.16 + bob_t * 0.18)
	_bob_style.border_color = Color(HIGHLIGHT_COLOR, 0.85 + bob_t * 0.15)
	_bob_style.set_border_width_all(int(3.0 + bob_t * 2.0))
	_bob_style.shadow_color = Color(0.04, 0.03, 0.08, 0.28 * bob_t)
	_bob_style.shadow_size = int(4.0 + bob_t * 4.0)
	_bob_style.shadow_offset = Vector2(0.0, 3.0 + bob_t * 3.0)

	for cell in _hint.get("highlight_cells", []):
		if cell.size() < 2: continue
		var rect: Rect2 = _cell_rect_fn.call(int(cell[0]), int(cell[1]))
		if rect.size.x <= 0: continue
		var center := rect.get_center()
		var b_size := rect.size * bob_scale
		var b_rect := Rect2(center - b_size * 0.5 + Vector2(0.0, bob_y), b_size)
		_bob_style.set_corner_radius_all(int(b_rect.size.x * 0.14))
		draw_style_box(_bob_style, b_rect)

	var target: Array = _hint.get("target_cell", [])
	if target.size() >= 2:
		var t_rect: Rect2 = _cell_rect_fn.call(int(target[0]), int(target[1]))
		if t_rect.size.x > 0:
			var t_center := t_rect.get_center()
			var tb_size := t_rect.size * (1.0 + bob_t * 0.10)
			var tb_rect := Rect2(t_center - tb_size * 0.5 + Vector2(0.0, -bob_t * 4.5), tb_size)
			_target_style.set_corner_radius_all(int(tb_rect.size.x * 0.14))
			_target_style.border_color = Color(1.0, 1.0, 1.0, 0.88 + bob_t * 0.12)
			_target_style.set_border_width_all(2)
			draw_style_box(_target_style, tb_rect)

	for cell in _hint.get("eliminated_cells", []):
		if cell.size() < 2: continue
		var rect: Rect2 = _cell_rect_fn.call(int(cell[0]), int(cell[1]))
		if rect.size.x <= 0: continue
		var center := rect.get_center()
		var b_size := rect.size * (1.0 + bob_t * 0.05)
		var b_rect := Rect2(center - b_size * 0.5 + Vector2(0.0, bob_y * 0.5), b_size)
		var inset := b_rect.size * 0.22
		var inner := Rect2(b_rect.position + inset, b_rect.size - inset * 2.0)
		var c := Color(0.95, 0.25, 0.25, 0.70 + bob_t * 0.25)
		var w := 2.5 + bob_t * 1.5
		draw_line(inner.position, inner.position + inner.size, c, w, true)
		draw_line(inner.position + Vector2(inner.size.x, 0),
				inner.position + Vector2(0, inner.size.y), c, w, true)

	if not _chain.is_empty():
		_draw_chain_badges()

func _draw_chain_badges() -> void:
	var badge_idx: int = 0
	var hyp: Array = _chain.get("hypothesis_cell", [])
	if hyp.size() >= 2:
		var rect: Rect2 = _cell_rect_fn.call(int(hyp[0]), int(hyp[1]))
		var s: float = _badge_scales[badge_idx] if badge_idx < _badge_scales.size() else 1.0
		_draw_badge(rect, "?", CHAIN_HYPOTHESIS, s)
		badge_idx += 1

	for step in _chain.get("steps", []):
		if step.size() < 2: continue
		var rect: Rect2 = _cell_rect_fn.call(int(step[0]), int(step[1]))
		var s: float = _badge_scales[badge_idx] if badge_idx < _badge_scales.size() else 1.0
		_draw_badge(rect, str(badge_idx), CHAIN_STEP, s)
		badge_idx += 1

	var contra_type: String = _chain.get("contra_type", "")
	if contra_type != "":
		var s: float = _badge_scales[badge_idx] if badge_idx < _badge_scales.size() else 1.0
		if s > 0.01:
			badge_idx += 1

func _draw_badge(rect: Rect2, text: String, color: Color, scale_f: float) -> void:
	if rect.size.x <= 0 or scale_f < 0.01: return
	var center := rect.get_center()
	var radius := rect.size.x * BADGE_RADIUS_RATIO * scale_f
	draw_circle(center, radius, color)
	var font: Font = ThemeDB.fallback_font if ThemeDB.fallback_font != null else get_theme_default_font()
	if font == null: return
	var font_size := int(radius * 1.2)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, center - text_size * 0.5 + Vector2(0, text_size.y * 0.35),
			text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)

func _kill_badge_tweens() -> void:
	for tw in _badge_tweens:
		if is_instance_valid(tw): tw.kill()
	_badge_tweens.clear()

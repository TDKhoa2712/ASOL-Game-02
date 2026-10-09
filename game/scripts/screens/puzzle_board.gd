# puzzle_board.gd
extends Control

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const RegionPainter = preload("res://scripts/content/region_painter.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const TouchDecoder = preload("res://scripts/input/touch_decoder.gd")
const TouchGuard = preload("res://scripts/input/touch_guard.gd")
const BoardPointerRouter = preload("res://scripts/input/board_pointer_router.gd")
const CellAnimator = preload("res://scripts/screens/cell_animator.gd")
const CandyRenderer = preload("res://scripts/core/candy_renderer.gd")
const CandyAtlas = preload("res://scripts/screens/candy_atlas.gd")
const CandyAnimState = preload("res://scripts/screens/candy_anim_state.gd")
const CandyCellDrawer = preload("res://scripts/screens/candy_cell_drawer.gd")
const BoardEntryWave = preload("res://scripts/screens/board_entry_wave.gd")
const PuzzleBoardPainter = preload("res://scripts/screens/puzzle_board_painter.gd")

signal cell_tapped(row: int, col: int)
signal cell_double_tapped(row: int, col: int)
signal cell_swiped(cells: Array)
signal cell_stroke_step(row: int, col: int, is_mark: bool)
signal candy_placed_anim(row: int, col: int)
signal error_anim(row: int, col: int)
signal win_anim()

var _session: Variant = null
var _zone_grid: Array = []
var _zone_colors: Dictionary = {}
var _zone_overlays: Dictionary = {}
var _colorblind: bool = false
var _high_contrast: bool = false
var _decoder: TouchDecoder = null
var _guard: TouchGuard = null
var _candy_tex: Texture2D = null
var _candy_anim: Variant = null
var _highlight_cells: Array = []
var _highlight_set: Dictionary = {}
var _highlight_unit: String = ""
var _preview_cells: Array = []
var _preview_set: Dictionary = {}
var _preview_mark: bool = true
var _highlight_pulse_phase: float = 0.0
var _touch_in_progress: bool = false
var _mark_anims: Dictionary = {}
var _mark_tweens: Dictionary = {}
var _cached_rects: Array = []
var _stroke_visited: Array = []
var _entry_elapsed: float = -1.0
var _show_solution: bool = false
func set_show_solution(enabled: bool) -> void: _show_solution = enabled; queue_redraw()
func is_showing_solution() -> bool: return _show_solution

func configure(session: Variant, animate_entry: bool = false) -> void:
	_entry_elapsed = -1.0; _session = session
	if _session == null: return
	var level_id: String = str(_session.level.get("id", ""))
	_candy_tex = CandyRenderer.texture_for_type(CandyRenderer.type_for_label(level_id))
	_candy_anim = CandyAnimState.new(CandyAtlas.meta()) if CandyAtlas.ensure_loaded() else null
	if _candy_anim != null: _candy_anim.motion = LayoutTokens.motion_enabled; _candy_anim.sync(_session.board)
	var n: int = int(_session.level.get("size", 0)); var regions: Array = _session.level.get("regions", [])
	_zone_grid = RegionPainter.precompute_grid(n, regions)
	if _colorblind:
		var painted := RegionPainter.assign_with_overlays(n, regions, Palette.ZONE_COLORS)
		_zone_colors = painted.colors; _zone_overlays = painted.overlays
	else:
		_zone_colors = RegionPainter.assign_colors(n, regions, Palette.ZONE_COLORS); _zone_overlays = {}
	_decoder = TouchDecoder.new(); _guard = TouchGuard.new()
	_decoder.cell_tapped.connect(func(r: int, c: int): cell_tapped.emit(r, c))
	_decoder.cell_double_tapped.connect(func(r: int, c: int): cell_double_tapped.emit(r, c))
	_decoder.cell_swiped.connect(func(cells: Array): cell_swiped.emit(cells))
	_decoder.preview_changed.connect(_on_preview_changed)
	_highlight_cells = []; _highlight_set.clear(); _highlight_unit = ""; _preview_cells = []; _preview_set.clear(); _stroke_visited.clear()
	_mark_anims.clear(); _mark_tweens.clear(); _invalidate_rects(); queue_redraw()
	if animate_entry: play_entry_wave()

func play_entry_wave() -> void: _entry_elapsed = 0.0 if LayoutTokens.motion_enabled and _session != null else -1.0; queue_redraw()
func skip_entry_wave() -> void: _entry_elapsed = -1.0; queue_redraw()
func is_entering() -> bool: return _entry_elapsed >= 0.0 and LayoutTokens.motion_enabled

func cell_entry_scale(row: int, col: int) -> float:
	if not is_entering() or _session == null: return 1.0
	return BoardEntryWave.cell_scale(int(_session.level.get("size", 0)), row, col, _entry_elapsed)

func set_colorblind(enabled: bool) -> void: _colorblind = enabled
func set_high_contrast(enabled: bool) -> void: _high_contrast = enabled
func redraw() -> void: queue_redraw()

func settle_input() -> void:
	if _guard != null: _guard.end_touch()
	if _decoder != null: _decoder.flush_pending(); _decoder.cancel()

func highlight_cell(row: int, col: int) -> void: highlight_cells([[row, col]])
func highlight_cells(cells: Array) -> void:
	_highlight_cells = cells.duplicate(); _highlight_unit = ""; _update_highlight_set(); queue_redraw()

func highlight_unit(unit_type: String, unit_id: Variant) -> void:
	_highlight_unit = unit_type; _highlight_cells = _cells_in_unit(unit_type, unit_id); _update_highlight_set(); queue_redraw()

func clear_highlight() -> void:
	_highlight_cells = []; _highlight_set.clear(); _highlight_unit = ""; _highlight_pulse_phase = 0.0; queue_redraw()

func _update_highlight_set() -> void:
	_highlight_set.clear()
	for c in _highlight_cells:
		if c.size() >= 2: _highlight_set[Vector2i(int(c[0]), int(c[1]))] = true

func play_candy_pop(row: int, col: int) -> void:
	if _candy_anim != null: _candy_anim.play(Vector2i(row, col), "appear"); queue_redraw()
	else: CellAnimator.play_candy_pop(self, _cell_rect(row, col))
	candy_placed_anim.emit(row, col)
func play_error_shake() -> void:
	CellAnimator.play_error_shake(self)
	if _candy_anim != null: _candy_anim.play_all("error")
	error_anim.emit(0, 0)
func play_win_bounce() -> void:
	if _candy_anim != null: _candy_anim.play_all("win", 0.04); queue_redraw()
	else: CellAnimator.play_win_bounce(self, _session, _cell_rect)
	win_anim.emit()
func play_sad() -> void: if _candy_anim != null: _candy_anim.play_all("sad"); queue_redraw()
func candy_frame(row: int, col: int) -> Array: return _candy_anim.frame_of(Vector2i(row, col)) if _candy_anim != null else []

func has_mark_anim(row: int, col: int) -> bool: return _mark_anims.has(Vector2i(row, col))
func play_mark_anim(row: int, col: int) -> void: play_mark_anims([[row, col]])

func play_mark_anims(cells: Array) -> void:
	if not LayoutTokens.motion_enabled: queue_redraw(); return
	for cell in cells:
		if cell.size() >= 2:
			var key := Vector2i(int(cell[0]), int(cell[1]))
			_mark_anims[key] = 0.0; _mark_tweens[key] = RefCounted.new()
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP; custom_minimum_size = Vector2(320, 320)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: settle_input()
	elif what == NOTIFICATION_RESIZED: _invalidate_rects(); queue_redraw()

func _on_preview_changed(cells: Array) -> void:
	_preview_cells = cells.duplicate(true); _preview_set.clear()
	if cells.is_empty():
		_stroke_visited.clear()
	elif _session != null:
		var first: Array = _preview_cells[0]
		var first_kind: int = _session.cell_at(int(first[0]), int(first[1]))
		if not CellModel.is_available(first_kind):
			_preview_cells = []
		else:
			_preview_mark = first_kind == CellModel.CellKind.BLANK
			for c in cells:
				if c.size() >= 2:
					_preview_set[Vector2i(int(c[0]), int(c[1]))] = true
					if not _stroke_visited.has(c):
						_stroke_visited.append(c)
						var r: int = int(c[0]); var col: int = int(c[1])
						var kind: int = _session.cell_at(r, col)
						if kind == (CellModel.CellKind.BLANK if _preview_mark else CellModel.CellKind.MARK):
							cell_stroke_step.emit(r, col, _preview_mark)
							if _preview_mark: play_mark_anim(r, col)
	queue_redraw()

func _process(_delta: float) -> void:
	if _candy_anim != null and _candy_anim.advance(_delta, LayoutTokens.motion_enabled and is_visible_in_tree()): queue_redraw()
	if _entry_elapsed >= 0.0:
		_entry_elapsed += _delta
		if not LayoutTokens.motion_enabled or _entry_elapsed >= BoardEntryWave.DURATION: _entry_elapsed = -1.0
		queue_redraw()
	if not _mark_anims.is_empty():
		var n := int(_session.level.get("size", 4)) if _session != null else 4
		var dur := 0.10 if n >= 10 else 0.15
		var step := _delta / dur; var to_erase: Array = []
		for key in _mark_anims.keys():
			var p: float = _mark_anims[key] + step
			if p >= 1.0 or (_session != null and _session.cell_at(key.x, key.y) != CellModel.CellKind.MARK and _session.cell_at(key.x, key.y) != CellModel.CellKind.ERROR and not _preview_set.has(key)):
				to_erase.append(key)
			else:
				_mark_anims[key] = p
		for key in to_erase:
			_mark_anims.erase(key); _mark_tweens.erase(key)
		queue_redraw()
	if _decoder != null: _decoder.tick(Time.get_ticks_msec())
	if not _highlight_cells.is_empty():
		_highlight_pulse_phase += _delta * 4.8
		if _highlight_pulse_phase > TAU: _highlight_pulse_phase -= TAU
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if _session == null or _decoder == null or _guard == null or _session.phase != 0 or is_entering(): return
	if event is InputEventScreenTouch:
		_touch_in_progress = event.pressed
		BoardPointerRouter.handle_button(event.pressed, event.position, _guard, _decoder, _cell_at); accept_event()
	elif event is InputEventScreenDrag:
		BoardPointerRouter.handle_move(event.position, _guard, _decoder, _cell_at); accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not _touch_in_progress:
			BoardPointerRouter.handle_button(event.pressed, event.position, _guard, _decoder, _cell_at); accept_event()
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		BoardPointerRouter.handle_move(event.position, _guard, _decoder, _cell_at); accept_event()

# Outer framed card (background + brown border).
func _card_rect() -> Rect2:
	var side := maxf(0.0, minf(size.x, size.y) - float(LayoutTokens.BOARD_PADDING * 2))
	return Rect2((size - Vector2.ONE * side) * 0.5, Vector2.ONE * side).grow(LayoutTokens.CARD_GROW)

# Cell grid, inset inside the card so the border, rounded corners and the cells'
# 3D bottom edge never overflow the frame.
func _board_rect() -> Rect2:
	var card := _card_rect()
	var inset := LayoutTokens.BOARD_BORDER_WIDTH + maxf(6.0, card.size.x * LayoutTokens.BOARD_INNER_PAD_RATIO)
	var inner := card.grow(-inset)
	if inner.size.x <= 0.0 or inner.size.y <= 0.0:
		return Rect2(card.get_center(), Vector2.ZERO)
	var n := maxi(1, int(_session.level.get("size", 1)) if _session != null else 1)
	var depth_k := LayoutTokens.CELL_DEPTH_RATIO * (1.0 - LayoutTokens.CELL_GAP_RATIO * float(n - 1)) / float(n)
	var side := minf(inner.size.x, inner.size.y / (1.0 + depth_k))
	var block := Vector2(side, side * (1.0 + depth_k))
	return Rect2(inner.position + (inner.size - block) * 0.5, Vector2.ONE * side)

func _cell_gap(board_w: float) -> float: return maxf(3.0, board_w * LayoutTokens.CELL_GAP_RATIO)

func _invalidate_rects() -> void:
	_cached_rects.clear()
	if _session == null: return
	var count := int(_session.level.get("size", 0))
	if count <= 0: return
	var br := _board_rect(); var gap := _cell_gap(br.size.x)
	var cell_w := (br.size.x - gap * float(count - 1)) / float(count)
	for r in range(count):
		var row_arr: Array = []
		for c in range(count):
			var pos := br.position + Vector2(float(c) * (cell_w + gap), float(r) * (cell_w + gap))
			row_arr.append(Rect2(pos, Vector2(cell_w, cell_w)))
		_cached_rects.append(row_arr)

func _cell_rect(row: int, col: int) -> Rect2:
	if _session == null: return Rect2()
	if _cached_rects.size() > row and _cached_rects[row].size() > col:
		return _cached_rects[row][col]
	var br := _board_rect(); var count := int(_session.level.get("size", 0))
	if count <= 0: return Rect2()
	var gap := _cell_gap(br.size.x); var cell_w := (br.size.x - gap * float(count - 1)) / float(count)
	return Rect2(br.position + Vector2(float(col) * (cell_w + gap), float(row) * (cell_w + gap)), Vector2(cell_w, cell_w))

func get_cell_rect(row: int, col: int) -> Rect2: return _cell_rect(row, col)

func _cell_at(pos: Vector2) -> Array:
	if _session == null: return []
	var br := _board_rect()
	if not br.has_point(pos): return []
	var count := int(_session.level.get("size", 4))
	if count <= 0: return []
	var gap := _cell_gap(br.size.x); var step := (br.size.x - gap * float(count - 1)) / float(count) + gap
	var rel := pos - br.position; var c := int(rel.x / step); var r := int(rel.y / step)
	return [r, c] if (r >= 0 and r < count and c >= 0 and c < count) else []

func _cells_in_unit(unit_type: String, unit_id: Variant) -> Array:
	if _session == null: return []
	var count := int(_session.level.get("size", 0)); var cells: Array = []
	for r in range(count):
		for c in range(count):
			if (unit_type == "row" and r == int(unit_id)) or (unit_type == "col" and c == int(unit_id)) or (unit_type == "zone" and _zone_grid.size() > r and _zone_grid[r][c] == str(unit_id)):
				cells.append([r, c])
	return cells

func _draw() -> void: PuzzleBoardPainter.draw(self)

func _draw_border(rect: Rect2, color: Color, width: int, radius: int) -> void:
	var border_tex := PuzzleBoardPainter.get_border_tex()
	if border_tex != null:
		draw_texture_rect(border_tex, rect, false, color)
	else:
		var sb := StyleBoxFlat.new(); sb.draw_center = false; sb.border_color = color
		sb.set_border_width_all(width); sb.set_corner_radius_all(radius); draw_style_box(sb, rect)

func _content_scale() -> float:
	return 1.0 if _session == null else LayoutTokens.cell_content_scale(int(_session.level.get("size", 0)))

func _draw_cell_candy(rect: Rect2, is_given: bool, r: int = -1, c: int = -1) -> void:
	CandyCellDrawer.draw(self, rect, is_given, _content_scale(), _candy_tex, candy_frame(r, c) if r >= 0 else [])

func _draw_cell_x(rect: Rect2, is_error: bool, r: int = -1, c: int = -1) -> void:
	if r >= 0 and c >= 0 and _mark_anims.has(Vector2i(r, c)):
		var prog: float = _mark_anims.get(Vector2i(r, c), 1.0)
		var anim_tex := CellAnimator.get_mark_texture(is_error, _high_contrast)
		if anim_tex != null:
			var pop_sz := rect.size * _content_scale() * (1.0 + 0.15 * (1.0 - prog))
			draw_texture_rect(anim_tex, Rect2(rect.get_center() - pop_sz * 0.5, pop_sz), false, Color(1, 1, 1, minf(prog * 2.0, 1.0))); return
	var tex := CellAnimator.get_mark_texture(is_error, _high_contrast)
	if tex != null:
		var mark_sz := rect.size * _content_scale()
		draw_texture_rect(tex, Rect2(rect.get_center() - mark_sz * 0.5, mark_sz), false)
	else:
		CellAnimator.draw_hand_drawn_x(self, rect, is_error, _high_contrast, 1.0, _content_scale())

func _draw_solution_hint(rect: Rect2) -> void:
	var cs := _content_scale()
	draw_circle(rect.get_center(), rect.size.x * minf(LayoutTokens.SOLUTION_HINT_RATIO * cs, 0.48), Color(0.2, 0.85, 0.4, 0.45))
	_draw_border(rect, Color(0.2, 0.85, 0.4, 0.9), 3, int(rect.size.x * LayoutTokens.CELL_CORNER_RATIO))

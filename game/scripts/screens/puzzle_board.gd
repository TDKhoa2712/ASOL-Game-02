# puzzle_board.gd
extends Control

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const RegionPainter = preload("res://scripts/content/region_painter.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const TouchDecoder = preload("res://scripts/input/touch_decoder.gd")

signal cell_tapped(row: int, col: int)
signal cell_double_tapped(row: int, col: int)
signal cell_swiped(cells: Array)

var _session: Variant = null
var _zone_grid: Array = []
var _zone_colors: Dictionary = {}
var _decoder: TouchDecoder = null
var _candy_tex: Texture2D = null
var _highlight_cells: Array = []
var _highlight_unit: String = ""
var _preview_cells: Array = []
var _preview_mark: bool = true
var _touch_in_progress: bool = false

func configure(session: Variant) -> void:
	_session = session
	if _session == null:
		return
	var n: int = int(_session.level.get("size", 0))
	var regions: Array = _session.level.get("regions", [])
	_zone_grid = RegionPainter.precompute_grid(n, regions)
	_zone_colors = RegionPainter.assign_colors(n, regions, Palette.ZONE_COLORS)
	_decoder = TouchDecoder.new()
	_decoder.cell_tapped.connect(func(r: int, c: int): cell_tapped.emit(r, c))
	_decoder.cell_double_tapped.connect(func(r: int, c: int): cell_double_tapped.emit(r, c))
	_decoder.cell_swiped.connect(func(cells: Array): cell_swiped.emit(cells))
	_decoder.preview_changed.connect(_on_preview_changed)
	_highlight_cells = []
	_highlight_unit = ""
	_preview_cells = []
	queue_redraw()

func redraw() -> void:
	queue_redraw()

func settle_input() -> void:
	if _decoder != null:
		_decoder.flush_pending()
		_decoder.cancel()

func highlight_cell(row: int, col: int) -> void:
	_highlight_cells = [[row, col]]
	_highlight_unit = ""
	queue_redraw()

func highlight_cells(cells: Array) -> void:
	_highlight_cells = cells.duplicate()
	_highlight_unit = ""
	queue_redraw()

func highlight_unit(unit_type: String, unit_id: Variant) -> void:
	_highlight_unit = unit_type
	_highlight_cells = _cells_in_unit(unit_type, unit_id)
	queue_redraw()

func clear_highlight() -> void:
	_highlight_cells = []
	_highlight_unit = ""
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(760, 760)
	var candy_path := "res://assets/ui/board/candy.svg"
	if ResourceLoader.exists(candy_path):
		_candy_tex = load(candy_path) as Texture2D

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and _decoder != null:
		_decoder.flush_pending()
		_decoder.cancel()

func _on_preview_changed(cells: Array) -> void:
	_preview_cells = cells.duplicate(true)
	if _session != null and not _preview_cells.is_empty():
		var first: Array = _preview_cells[0]
		var first_kind: int = _session.cell_at(int(first[0]), int(first[1]))
		if not CellModel.is_available(first_kind):
			_preview_cells = []
		else:
			_preview_mark = first_kind == CellModel.CellKind.BLANK
	queue_redraw()

func _process(_delta: float) -> void:
	if _decoder != null:
		_decoder.tick(Time.get_ticks_msec())

func _gui_input(event: InputEvent) -> void:
	if _session == null or _decoder == null or _session.phase != 0:
		return
	if event is InputEventScreenTouch:
		_touch_in_progress = event.pressed
		if event.pressed:
			var c := _cell_at(event.position)
			if not c.is_empty():
				_decoder.begin(c[0], c[1], Time.get_ticks_msec())
		else:
			_decoder.finish(Time.get_ticks_msec())
		accept_event()
	elif event is InputEventScreenDrag:
		var c := _cell_at(event.position)
		if not c.is_empty():
			_decoder.move(c[0], c[1])
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if _touch_in_progress:
			return
		if event.pressed:
			var c := _cell_at(event.position)
			if not c.is_empty():
				_decoder.begin(c[0], c[1], Time.get_ticks_msec())
		else:
			_decoder.finish(Time.get_ticks_msec())
		accept_event()
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		var c := _cell_at(event.position)
		if not c.is_empty():
			_decoder.move(c[0], c[1])
		accept_event()

func _board_rect() -> Rect2:
	var side := maxf(0.0, minf(size.x, size.y) - float(LayoutTokens.BOARD_PADDING * 2))
	return Rect2((size - Vector2.ONE * side) * 0.5, Vector2.ONE * side)

func _cell_gap(board_w: float) -> float:
	return maxf(2.0, board_w * LayoutTokens.CELL_GAP_RATIO)

func _cell_at(pos: Vector2) -> Array:
	if _session == null:
		return []
	var br := _board_rect()
	if not br.has_point(pos):
		return []
	var count := int(_session.level.get("size", 4))
	if count <= 0:
		return []
	var gap := _cell_gap(br.size.x)
	var cell_size := (br.size.x - gap * float(count - 1)) / float(count)
	var step := cell_size + gap
	var rel := pos - br.position
	var c := int(rel.x / step)
	var r := int(rel.y / step)
	if r < 0 or r >= count or c < 0 or c >= count:
		return []
	return [r, c]

func _cells_in_unit(unit_type: String, unit_id: Variant) -> Array:
	if _session == null:
		return []
	var count := int(_session.level.get("size", 0))
	var cells: Array = []
	for r in range(count):
		for c in range(count):
			if unit_type == "row" and r == int(unit_id):
				cells.append([r, c])
			elif unit_type == "col" and c == int(unit_id):
				cells.append([r, c])
			elif unit_type == "zone" and _zone_grid.size() > r and _zone_grid[r][c] == str(unit_id):
				cells.append([r, c])
	return cells

func _draw() -> void:
	if _session == null:
		return
	var br := _board_rect()
	var card_sb := StyleBoxFlat.new()
	card_sb.bg_color = Palette.BG_PAPER
	card_sb.set_corner_radius_all(int(br.size.x * LayoutTokens.CARD_CORNER_RATIO))
	var expanded_rect := br.grow(LayoutTokens.CARD_GROW)
	draw_style_box(card_sb, expanded_rect)

	var count := int(_session.level.get("size", 0))
	if count <= 0:
		return
	var gap := _cell_gap(br.size.x)
	var cell_w := (br.size.x - gap * float(count - 1)) / float(count)
	var cr := int(cell_w * LayoutTokens.CELL_CORNER_RATIO)

	for r in range(count):
		for c in range(count):
			var pos := br.position + Vector2(float(c) * (cell_w + gap), float(r) * (cell_w + gap))
			var cell_rect := Rect2(pos, Vector2(cell_w, cell_w))
			var zone := str(_zone_grid[r][c]) if _zone_grid.size() > r and _zone_grid[r].size() > c else ""
			var base_col: Color = _zone_colors.get(zone, Palette.BG_CREAM)
			var sb := StyleBoxFlat.new()
			sb.bg_color = base_col
			sb.set_corner_radius_all(cr)
			draw_style_box(sb, cell_rect)

			var kind: int = _session.board[r][c]
			if _preview_cells.has([r, c]):
				if _preview_mark and kind == CellModel.CellKind.BLANK:
					kind = CellModel.CellKind.MARK
				elif not _preview_mark and kind == CellModel.CellKind.MARK:
					kind = CellModel.CellKind.BLANK
			var ov: Color = Palette.cell_state_overlay(kind)
			if ov.a > 0.0:
				var ov_sb := StyleBoxFlat.new()
				ov_sb.bg_color = ov
				ov_sb.set_corner_radius_all(cr)
				draw_style_box(ov_sb, cell_rect)

			match kind:
				CellModel.CellKind.MARK:
					_draw_cell_x(cell_rect, false)
				CellModel.CellKind.CANDY:
					_draw_cell_candy(cell_rect, false)
				CellModel.CellKind.ERROR:
					_draw_cell_x(cell_rect, true)
				CellModel.CellKind.GIVEN:
					_draw_cell_candy(cell_rect, true)

			if _highlight_cells.has([r, c]):
				var hl_sb := StyleBoxFlat.new()
				hl_sb.draw_center = false
				hl_sb.border_color = Palette.ACCENT_ORANGE
				hl_sb.set_border_width_all(3)
				hl_sb.set_corner_radius_all(cr)
				draw_style_box(hl_sb, cell_rect)

func _draw_cell_candy(rect: Rect2, is_given: bool) -> void:
	var pad := rect.size.x * 0.16
	var candy_rect := rect.grow(-pad)
	if is_given:
		var halo_center := rect.position + rect.size * 0.5
		var halo_rad := rect.size.x * 0.42
		draw_arc(halo_center, halo_rad, 0.0, TAU, 32, Palette.GIVEN_HALO, 3.0)
	var tint := Palette.GIVEN_CANDY if is_given else Palette.CANDY_BROWN
	if _candy_tex != null:
		draw_texture_rect(_candy_tex, candy_rect, false, tint)
	else:
		var center := rect.position + rect.size * 0.5
		var rad := candy_rect.size.x * 0.45
		draw_circle(center, rad, tint)
		if not is_given:
			var hl_center := center - Vector2(rad * 0.3, rad * 0.3)
			draw_circle(hl_center, rad * 0.22, Palette.CANDY_LIGHT)

func _draw_cell_x(rect: Rect2, is_error: bool) -> void:
	var stroke_col: Color = Palette.ERROR_RED if is_error else Palette.MARK_WHITE
	var pad := rect.size.x * 0.28
	var w := maxf(2.5, rect.size.x * 0.08)
	var p1 := rect.position + Vector2(pad, pad)
	var p2 := rect.end - Vector2(pad, pad)
	var p3 := Vector2(rect.end.x - pad, rect.position.y + pad)
	var p4 := Vector2(rect.position.x + pad, rect.end.y - pad)
	draw_line(p1, p2, stroke_col, w)
	draw_line(p3, p4, stroke_col, w)

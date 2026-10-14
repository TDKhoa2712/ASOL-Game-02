# Draws tutorial-only marks over the board without touching the session:
# faded X's, row/column number badges, and for the onboarding puzzle a dimmed
# board with pulsing rings on the cells to touch (RST-028). Input always
# passes through.
extends Control

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

const X_COLOR := Color(0.35, 0.24, 0.12, 0.38)
const X_WIDTH_RATIO := 0.07
const X_INSET_RATIO := 0.3
const BADGE_RATIO := 0.2
const BADGE_FONT_RATIO := 0.22

var _cell_rect_fn: Callable = Callable()
var _faded: Array = []
var _rows: Array = []
var _cols: Array = []
var _lit: Array = []
var _rings: Array = []
var _pulse: float = 0.0
var _ripple_cell: Array = []
var _ripple_t: float = 1.0
const RIPPLE_SEC := 0.45
const DIM_COLOR := Color(0.16, 0.13, 0.11, 0.72)
const RING_COLOR := Color(1.0, 0.85, 0.4)

func _init() -> void:
	name = "TutorialOverlay"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	set_process(false)

func bind(cell_rect_fn: Callable) -> void:
	_cell_rect_fn = cell_rect_fn

func show_marks(faded: Array, rows: Array, cols: Array) -> void:
	_faded = faded.duplicate()
	_rows = rows.duplicate()
	_cols = cols.duplicate()
	queue_redraw()

func clear() -> void:
	show_marks([], [], [])
	show_spotlight([], [])

# Onboarding: every cell not in lit is darkened; rings pulse on the targets.
func show_spotlight(lit: Array, rings: Array) -> void:
	_lit = lit.duplicate()
	_rings = rings.duplicate()
	set_process(not _rings.is_empty() and LayoutTokens.motion_enabled)
	queue_redraw()

# A one-shot ring that spreads from a cell when the guide hand touches down.
func ripple(cell: Array) -> void:
	if not LayoutTokens.motion_enabled:
		return
	_ripple_cell = cell
	_ripple_t = 0.0
	set_process(true)

func dimmed_cells(size: int) -> Array:
	var out: Array = []
	if _lit.is_empty():
		return out
	for r in range(size):
		for c in range(size):
			if not _lit.has([r, c]): out.append([r, c])
	return out

func _process(delta: float) -> void:
	_pulse = fmod(_pulse + delta, 1.2)
	_ripple_t = minf(1.0, _ripple_t + delta / RIPPLE_SEC)
	if _ripple_t >= 1.0 and _rings.is_empty(): set_process(false)
	queue_redraw()

func faded_cells() -> Array: return _faded.duplicate()
func axis_rows() -> Array: return _rows.duplicate()
func axis_cols() -> Array: return _cols.duplicate()

func _draw() -> void:
	if not _cell_rect_fn.is_valid():
		return
	var board: Control = _cell_rect_fn.get_object() as Control
	var n: int = int(board._session.level.get("size", 0)) if board != null and board.get("_session") != null else 0
	for cell in dimmed_cells(n):
		var rect := _local(_cell_rect_fn.call(int(cell[0]), int(cell[1])))
		draw_style_box(_dim_box(rect.size.x), rect)
	for cell in _rings:
		var rect := _local(_cell_rect_fn.call(int(cell[0]), int(cell[1])))
		var t := _pulse / 1.2
		draw_arc(rect.get_center(), rect.size.x * (0.42 + 0.12 * t), 0.0, TAU, 48, Color(RING_COLOR, 1.0 - t), maxf(4.0, rect.size.x * 0.05), true)
	if _ripple_t < 1.0 and not _ripple_cell.is_empty():
		var rr := _local(_cell_rect_fn.call(int(_ripple_cell[0]), int(_ripple_cell[1])))
		var e := 1.0 - pow(1.0 - _ripple_t, 2.0)
		draw_circle(rr.get_center(), rr.size.x * (0.12 + 0.32 * e), Color(1, 1, 1, 0.45 * (1.0 - _ripple_t)))
		draw_arc(rr.get_center(), rr.size.x * (0.18 + 0.36 * e), 0.0, TAU, 48, Color(RING_COLOR, 1.0 - _ripple_t), maxf(3.0, rr.size.x * 0.04), true)
	for cell in _faded:
		_draw_x(_local(_cell_rect_fn.call(int(cell[0]), int(cell[1]))))
	for r in _rows:
		var rect := _local(_cell_rect_fn.call(int(r), 0))
		var radius := rect.size.x * BADGE_RATIO
		_draw_badge(Vector2(rect.position.x - radius * 0.9, rect.get_center().y), radius, int(r) + 1)
	for c in _cols:
		var rect := _local(_cell_rect_fn.call(0, int(c)))
		var radius := rect.size.y * BADGE_RATIO
		_draw_badge(Vector2(rect.get_center().x, rect.position.y - radius * 0.9), radius, int(c) + 1)

# The board's rects are in its own space; this overlay shares its parent rect.
func _local(board_rect: Rect2) -> Rect2:
	var board: Control = _cell_rect_fn.get_object() as Control
	if board == null:
		return board_rect
	return Rect2(board_rect.position + board.global_position - global_position, board_rect.size)

func _dim_box(width: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = DIM_COLOR
	sb.set_corner_radius_all(int(width * 0.16))
	return sb

func _draw_x(rect: Rect2) -> void:
	var inset := rect.size * X_INSET_RATIO
	var a := rect.position + inset
	var b := rect.end - inset
	var w := maxf(2.0, rect.size.x * X_WIDTH_RATIO)
	draw_line(a, b, X_COLOR, w, true)
	draw_line(Vector2(b.x, a.y), Vector2(a.x, b.y), X_COLOR, w, true)

func _draw_badge(center: Vector2, radius: float, number: int) -> void:
	draw_circle(center, radius + 3.0, Palette.BOARD_HINT_EDGE)
	draw_circle(center, radius, Palette.BOARD_HINT_BG)
	var font: Font = FontTokens.body_bold()
	if font == null:
		font = ThemeDB.fallback_font
	var size := int(radius * 2.0 * BADGE_FONT_RATIO / BADGE_RATIO * 0.5)
	var text := str(number)
	var extent := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, size)
	draw_string(font, center + Vector2(-extent.x * 0.5, extent.y * 0.32), text, HORIZONTAL_ALIGNMENT_CENTER, -1, size, Palette.BOARD_HINT_ICON)

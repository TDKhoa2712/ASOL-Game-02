# Draws tutorial-only marks over the board without touching the session:
# faded X's that illustrate what a candy rules out, and number badges on the
# board edge for the row/column the lesson names. Cells themselves are never
# lit (RST-004); input always passes through.
extends Control

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")

const X_COLOR := Color(0.35, 0.24, 0.12, 0.38)
const X_WIDTH_RATIO := 0.07
const X_INSET_RATIO := 0.3
const BADGE_RATIO := 0.2
const BADGE_FONT_RATIO := 0.22

var _cell_rect_fn: Callable = Callable()
var _faded: Array = []
var _rows: Array = []
var _cols: Array = []

func _init() -> void:
	name = "TutorialOverlay"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false

func bind(cell_rect_fn: Callable) -> void:
	_cell_rect_fn = cell_rect_fn

func show_marks(faded: Array, rows: Array, cols: Array) -> void:
	_faded = faded.duplicate()
	_rows = rows.duplicate()
	_cols = cols.duplicate()
	queue_redraw()

func clear() -> void:
	show_marks([], [], [])

func faded_cells() -> Array: return _faded.duplicate()
func axis_rows() -> Array: return _rows.duplicate()
func axis_cols() -> Array: return _cols.duplicate()

func _draw() -> void:
	if not _cell_rect_fn.is_valid():
		return
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

extends Control


const UiTheme = preload("res://scripts/ui_theme.gd")
const UiTokens = preload("res://scripts/ui_tokens.gd")
const CANDY_TEXTURE_PATH := "res://assets/ui/board/candy.svg"

const ERROR := Color("#E53935")
const INK := Color("#344054")
const CANDY := Color("#A56643")
const CANDY_LIGHT := Color("#F7CFA8")

# Option to show region letters for accessibility
var show_region_letters: bool = false

var engine
var level: Dictionary = {}
var _touch_in_progress := false
var _candy_texture: Texture2D = null
var _cell_styles: Dictionary = {}
var _region_grid: Array = []  # precomputed NxN grid of region labels
var _region_color_map: Dictionary = {}  # region label → Color (LAB-distance assigned)


func _ready() -> void:
	custom_minimum_size = Vector2(760.0, 760.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	set_process(true)
	if ResourceLoader.exists(CANDY_TEXTURE_PATH):
		_candy_texture = load(CANDY_TEXTURE_PATH)


func configure(gesture_engine, level_data: Dictionary) -> void:
	engine = gesture_engine
	level = level_data.duplicate(true)
	_precompute_region_grid()
	_assign_region_colors()
	if not engine.changed.is_connected(_on_engine_changed):
		engine.changed.connect(_on_engine_changed)
	queue_redraw()


func _process(_delta: float) -> void:
	if engine != null:
		engine.tick(Time.get_ticks_msec())


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and engine != null:
		if engine.active_pointer != -1:
			engine.cancel_active()
		if engine.pending_tap:
			engine.flush_pending()


func _gui_input(event: InputEvent) -> void:
	if engine == null or level.is_empty():
		return
	if event is InputEventScreenTouch:
		_touch_in_progress = event.pressed
		if event.pressed:
			_begin_pointer(event.index + 1, event.position)
		else:
			engine.end_pointer(event.index + 1, Time.get_ticks_msec())
		accept_event()
	elif event is InputEventScreenDrag:
		_move_pointer(event.index + 1, event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if _touch_in_progress:
			return
		if event.pressed:
			_begin_pointer(0, event.position)
		else:
			engine.end_pointer(0, Time.get_ticks_msec())
		accept_event()
	elif event is InputEventMouseMotion:
		if engine.active_pointer == 0 and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_move_pointer(0, event.position)
			accept_event()


func _begin_pointer(pointer_id: int, local_position: Vector2) -> void:
	var cell := _cell_at(local_position)
	if cell.is_empty():
		return
	engine.begin_pointer(
		pointer_id,
		cell,
		_to_contract_position(local_position),
		Time.get_ticks_msec()
	)


func _move_pointer(pointer_id: int, local_position: Vector2) -> void:
	var cell := _cell_at(local_position)
	if cell.is_empty():
		return
	engine.move_pointer(pointer_id, cell, _to_contract_position(local_position))


func _cell_gap(board_width: float, count: int) -> float:
	return maxf(3.0, round(board_width * 0.008))


func _cell_at(local_position: Vector2) -> Array:
	var board_rect := _board_rect()
	if not board_rect.has_point(local_position):
		return []
	var count := int(level.get("size", 4))
	if count <= 0:
		return []
	var gap := _cell_gap(board_rect.size.x, count)
	var step := (board_rect.size.x - gap * (count - 1)) / float(count) + gap
	var col := clampi(int((local_position.x - board_rect.position.x) / step), 0, count - 1)
	var row := clampi(int((local_position.y - board_rect.position.y) / step), 0, count - 1)
	return [row, col]


func _to_contract_position(local_position: Vector2) -> Vector2:
	var board_rect := _board_rect()
	var scale := float(engine.contract.get("cellLogicalPx", 100)) / (board_rect.size.x / float(level["size"]))
	return (local_position - board_rect.position) * scale


func _board_rect() -> Rect2:
	var side := maxf(0.0, minf(size.x, size.y) - 18.0)
	return Rect2((size - Vector2.ONE * side) * 0.5, Vector2.ONE * side)


func _region_at(row: int, column: int) -> String:
	if _region_grid.is_empty():
		return str(level["regions"][row]).substr(column, 1)
	return _region_grid[row][column]


func _get_region_color(region: String) -> Color:
	if _region_color_map.has(region):
		return _region_color_map[region]
	return UiTokens.REGION_PALETTE[0]


func _precompute_region_grid() -> void:
	_region_grid = []
	var size := int(level.get("size", 0))
	for row in range(size):
		var row_labels: Array = []
		var region_str: String = str(level["regions"][row])
		for col in range(size):
			row_labels.append(region_str.substr(col, 1))
		_region_grid.append(row_labels)


func _assign_region_colors() -> void:
	_region_color_map = {}
	var size := int(level.get("size", 0))
	if size == 0:
		return
	# Build adjacency: two regions are adjacent if they share a cell neighbor
	var region_cells: Dictionary = {}
	for row in range(size):
		for col in range(size):
			var label: String = str(_region_grid[row][col])
			if not region_cells.has(label):
				region_cells[label] = []
			region_cells[label].append([row, col])
	var adjacency: Dictionary = {}
	for label in region_cells:
		adjacency[label] = {}
	for row in range(size):
		for col in range(size):
			var label: String = str(_region_grid[row][col])
			for neighbor in [[row - 1, col], [row + 1, col], [row, col - 1], [row, col + 1]]:
				if neighbor[0] >= 0 and neighbor[0] < size and neighbor[1] >= 0 and neighbor[1] < size:
					var nlabel: String = str(_region_grid[neighbor[0]][neighbor[1]])
					if nlabel != label:
						adjacency[label][nlabel] = true
						adjacency[nlabel][label] = true
	# Greedy graph coloring: assign palette colors maximizing LAB distance from neighbors
	var palette: Array = UiTokens.REGION_PALETTE
	var labels := region_cells.keys()
	labels.sort()
	for label in labels:
		var best_idx := 0
		var best_min_dist := -1.0
		for idx in range(palette.size()):
			var candidate: Color = palette[idx]
			var min_dist := INF
			for adj_label in adjacency[label]:
				if _region_color_map.has(adj_label):
					var dist := _cie_lab_distance(candidate, _region_color_map[adj_label])
					min_dist = minf(min_dist, dist)
			if min_dist > best_min_dist:
				best_min_dist = min_dist
				best_idx = idx
		_region_color_map[label] = palette[best_idx]


static func _cie_lab_distance(a: Color, b: Color) -> float:
	var la := _to_lab(a)
	var lb := _to_lab(b)
	var dl: float = float(la[0]) - float(lb[0])
	var da: float = float(la[1]) - float(lb[1])
	var db: float = float(la[2]) - float(lb[2])
	return sqrt(dl * dl + da * da + db * db)


static func _to_lab(c: Color) -> Array:
	# sRGB → linear → XYZ → LAB (D65)
	var rl := _srgb_to_linear(c.r)
	var gl := _srgb_to_linear(c.g)
	var bl := _srgb_to_linear(c.b)
	var x := 0.4124564 * rl + 0.3575761 * gl + 0.1804375 * bl
	var y := 0.2126729 * rl + 0.7151522 * gl + 0.0721750 * bl
	var z := 0.0193339 * rl + 0.1191920 * gl + 0.9503041 * bl
	x /= 0.95047
	z /= 1.08883
	x = _lab_f(x)
	y = _lab_f(y)
	z = _lab_f(z)
	return [116.0 * y - 16.0, 500.0 * (x - y), 200.0 * (y - z)]


static func _srgb_to_linear(v: float) -> float:
	return pow((v + 0.055) / 1.055, 2.4) if v > 0.04045 else v / 12.92


static func _lab_f(t: float) -> float:
	return pow(t, 1.0 / 3.0) if t > 0.008856 else 7.787 * t + 16.0 / 116.0


func _get_cell_style(color: Color, radius: int) -> StyleBoxFlat:
	var key := "%s_%d" % [color.to_html(), radius]
	if not _cell_styles.has(key):
		var s := StyleBoxFlat.new()
		s.bg_color = color
		s.set_corner_radius_all(radius)
		_cell_styles[key] = s
	return _cell_styles[key]


func _draw() -> void:
	if level.is_empty() or engine == null:
		return
	var board_rect := _board_rect()
	var count := int(level["size"])
	if count <= 0:
		return

	# Card background (white rounded container)
	var card_radius: int = maxi(16, int(board_rect.size.x * 0.04))
	var card_style := _get_cell_style(Color.WHITE, card_radius)
	draw_style_box(card_style, board_rect.grow(8.0))

	var gap := _cell_gap(board_rect.size.x, count)
	var cell_size := (board_rect.size.x - gap * (count - 1)) / float(count)
	var corner_radius: int = maxi(4, int(cell_size * 0.14))

	for row in range(count):
		for column in range(count):
			var cell_pos := board_rect.position + Vector2(column, row) * (cell_size + gap)
			var rect := Rect2(cell_pos, Vector2.ONE * cell_size)
			var region := _region_at(row, column)
			var cell_color := _get_region_color(region)

			# Flat colored cell with rounded corners
			draw_style_box(_get_cell_style(cell_color, corner_radius), rect)

			# Accessibility: optional region letters
			if show_region_letters:
				var font := ThemeDB.fallback_font
				draw_string(
					font,
					rect.position + Vector2(8.0, rect.size.y - 8.0),
					region,
					HORIZONTAL_ALIGNMENT_LEFT,
					-1.0,
					maxi(12, int(cell_size * 0.22)),
					Color(0.2, 0.2, 0.2, 0.45)
				)

			_draw_cell_state(rect, [row, column])


func _draw_cell_state(rect: Rect2, cell: Array) -> void:
	var state: String = engine.session.cell_state(cell)
	if engine.session.is_given(cell) or state == "candy":
		_draw_candy(rect, engine.session.is_given(cell))
	elif state in ["x", "x_error"]:
		_draw_x(rect, state == "x_error")


func _draw_x(rect: Rect2, is_error: bool) -> void:
	var color := ERROR if is_error else Color(1.0, 1.0, 1.0, 0.88)
	var padding := rect.size.x * 0.28
	var thickness := maxf(4.0, rect.size.x * 0.09)
	draw_line(rect.position + Vector2(padding, padding), rect.end - Vector2(padding, padding), color, thickness, true)
	draw_line(
		rect.position + Vector2(rect.size.x - padding, padding),
		rect.position + Vector2(padding, rect.size.y - padding),
		color,
		thickness,
		true
	)
	if is_error:
		var badge_center := rect.position + rect.size * Vector2(0.78, 0.22)
		draw_circle(badge_center, rect.size.x * 0.09, Color.WHITE)
		draw_circle(badge_center, rect.size.x * 0.07, ERROR)


func _draw_candy(rect: Rect2, is_given: bool) -> void:
	if is_given:
		draw_circle(rect.get_center(), rect.size.x * 0.38, Color("#FFF7D6"))

	if _candy_texture != null:
		var candy_size := rect.size * 0.74
		var candy_rect := Rect2(rect.position + (rect.size - candy_size) * 0.5, candy_size)
		draw_texture_rect(_candy_texture, candy_rect, false)
	else:
		_draw_candy_procedural(rect)


func _draw_candy_procedural(rect: Rect2) -> void:
	var center := rect.get_center()
	var radius := rect.size.x * 0.25
	var outline := Color("#7F4A2F")
	for direction in [-1.0, 1.0]:
		var wrapper := PackedVector2Array([
			center + Vector2(direction * radius * 0.65, 0),
			center + Vector2(direction * radius * 1.6, -radius * 0.65),
			center + Vector2(direction * radius * 1.6, radius * 0.65),
		])
		draw_colored_polygon(wrapper, CANDY_LIGHT)
		draw_polyline(wrapper, outline, 2.0, true)
	draw_circle(center, radius, CANDY)
	draw_arc(center, radius * 0.60, -PI * 0.8, PI * 0.25, 18, CANDY_LIGHT, radius * 0.22, true)



func _on_engine_changed() -> void:
	queue_redraw()

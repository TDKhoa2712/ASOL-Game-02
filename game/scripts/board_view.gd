extends Control


const REGION_COLORS := {
	"A": Color("#F9D8C5"),
	"B": Color("#CFE8E1"),
	"C": Color("#D9D6F4"),
	"D": Color("#F6E7AC"),
}
const INK := Color("#344054")
const GRID := Color("#667085")
const ERROR := Color("#D64550")
const CAT := Color("#A56643")
const CAT_LIGHT := Color("#F7CFA8")


var engine
var level: Dictionary = {}
var _touch_in_progress := false


func _ready() -> void:
	custom_minimum_size = Vector2(760.0, 760.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	set_process(true)


func configure(gesture_engine, level_data: Dictionary) -> void:
	engine = gesture_engine
	level = level_data.duplicate(true)
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
		elif engine.pending_tap:
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


func _cell_at(local_position: Vector2) -> Array:
	var board_rect := _board_rect()
	if not board_rect.has_point(local_position):
		return []
	var cell_size := board_rect.size.x / float(level["size"])
	return [
		mini(int((local_position.y - board_rect.position.y) / cell_size), int(level["size"]) - 1),
		mini(int((local_position.x - board_rect.position.x) / cell_size), int(level["size"]) - 1),
	]


func _to_contract_position(local_position: Vector2) -> Vector2:
	var board_rect := _board_rect()
	var scale := float(engine.contract.get("cellLogicalPx", 100)) / (board_rect.size.x / float(level["size"]))
	return (local_position - board_rect.position) * scale


func _draw() -> void:
	if level.is_empty() or engine == null:
		return
	var board_rect := _board_rect()
	var count := int(level["size"])
	var cell_size := board_rect.size.x / float(count)
	draw_rect(board_rect.grow(7.0), Color("#FFFFFF"), true)
	draw_rect(board_rect.grow(7.0), Color("#D0D5DD"), false, 3.0)

	for row in range(count):
		for column in range(count):
			var rect := Rect2(
				board_rect.position + Vector2(column, row) * cell_size,
				Vector2.ONE * cell_size
			)
			var region := _region_at(row, column)
			draw_rect(rect, REGION_COLORS.get(region, Color("#F2F4F7")), true)
			_draw_region_pattern(rect, region, row, column)
			_draw_cell_state(rect, [row, column])

	for index in range(count + 1):
		var offset := float(index) * cell_size
		draw_line(
			board_rect.position + Vector2(offset, 0.0),
			board_rect.position + Vector2(offset, board_rect.size.y),
			GRID,
			2.0
		)
		draw_line(
			board_rect.position + Vector2(0.0, offset),
			board_rect.position + Vector2(board_rect.size.x, offset),
			GRID,
			2.0
		)
	_draw_region_borders(board_rect, cell_size, count)


func _board_rect() -> Rect2:
	var side := maxf(0.0, minf(size.x, size.y) - 18.0)
	return Rect2((size - Vector2.ONE * side) * 0.5, Vector2.ONE * side)


func _region_at(row: int, column: int) -> String:
	return str(level["regions"][row]).substr(column, 1)


func _draw_region_pattern(rect: Rect2, region: String, row: int, column: int) -> void:
	var accent := Color("#FFFFFF80")
	if (row + column) % 2 == 0:
		draw_circle(rect.position + rect.size * Vector2(0.22, 0.23), rect.size.x * 0.035, accent)
	if region in ["B", "D"]:
		draw_line(
			rect.position + rect.size * Vector2(0.72, 0.14),
			rect.position + rect.size * Vector2(0.88, 0.30),
			accent,
			5.0
		)
	var font := ThemeDB.fallback_font
	draw_string(
		font,
		rect.position + Vector2(12.0, rect.size.y - 12.0),
		region,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		18,
		Color("#47546766")
	)


func _draw_region_borders(board_rect: Rect2, cell_size: float, count: int) -> void:
	for row in range(count):
		for column in range(count):
			var top_left := board_rect.position + Vector2(column, row) * cell_size
			var region := _region_at(row, column)
			if row == 0 or _region_at(row - 1, column) != region:
				draw_line(top_left, top_left + Vector2(cell_size, 0.0), INK, 7.0)
			if column == 0 or _region_at(row, column - 1) != region:
				draw_line(top_left, top_left + Vector2(0.0, cell_size), INK, 7.0)
			if row == count - 1:
				draw_line(top_left + Vector2(0.0, cell_size), top_left + Vector2(cell_size, cell_size), INK, 7.0)
			if column == count - 1:
				draw_line(top_left + Vector2(cell_size, 0.0), top_left + Vector2(cell_size, cell_size), INK, 7.0)


func _draw_cell_state(rect: Rect2, cell: Array) -> void:
	var state: String = engine.session.cell_state(cell)
	if engine.session.is_given(cell) or state == "cat":
		_draw_cat(rect, engine.session.is_given(cell))
	elif state in ["x", "x_error"]:
		_draw_x(rect, state == "x_error")


func _draw_x(rect: Rect2, is_error: bool) -> void:
	var color := ERROR if is_error else INK
	var padding := rect.size.x * 0.31
	draw_line(rect.position + Vector2(padding, padding), rect.end - Vector2(padding, padding), color, 10.0, true)
	draw_line(
		rect.position + Vector2(rect.size.x - padding, padding),
		rect.position + Vector2(padding, rect.size.y - padding),
		color,
		10.0,
		true
	)
	if is_error:
		var badge_center := rect.position + rect.size * Vector2(0.78, 0.22)
		draw_circle(badge_center, rect.size.x * 0.09, Color.WHITE)
		draw_arc(badge_center, rect.size.x * 0.05, PI, TAU, 12, ERROR, 4.0)
		draw_rect(Rect2(badge_center + Vector2(-7.0, 0.0), Vector2(14.0, 11.0)), ERROR, true)


func _draw_cat(rect: Rect2, is_given: bool) -> void:
	var center := rect.get_center()
	var radius := rect.size.x * 0.22
	var outline := Color("#7F4A2F")
	if is_given:
		draw_circle(center, radius * 1.45, Color("#FFF7D6"))
	var left_ear := PackedVector2Array([
		center + Vector2(-radius * 0.85, -radius * 0.35),
		center + Vector2(-radius * 0.68, -radius * 1.25),
		center + Vector2(-radius * 0.08, -radius * 0.75),
	])
	var right_ear := PackedVector2Array([
		center + Vector2(radius * 0.85, -radius * 0.35),
		center + Vector2(radius * 0.68, -radius * 1.25),
		center + Vector2(radius * 0.08, -radius * 0.75),
	])
	draw_colored_polygon(left_ear, CAT)
	draw_colored_polygon(right_ear, CAT)
	draw_circle(center, radius, CAT)
	draw_circle(center + Vector2(0.0, radius * 0.16), radius * 0.62, CAT_LIGHT)
	for direction in [-1.0, 1.0]:
		draw_circle(center + Vector2(radius * 0.36 * direction, -radius * 0.22), radius * 0.08, outline)
	draw_circle(center + Vector2(0.0, radius * 0.12), radius * 0.09, outline)
	draw_arc(center + Vector2(0.0, radius * 0.10), radius * 0.30, 0.25, PI - 0.25, 12, outline, 3.0)


func _on_engine_changed() -> void:
	queue_redraw()

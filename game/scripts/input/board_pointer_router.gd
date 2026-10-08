extends RefCounted

static func handle_button(
		pressed: bool,
		pos: Vector2,
		guard: Variant,
		decoder: Variant,
		cell_at: Callable) -> void:
	var now := Time.get_ticks_msec()
	if pressed:
		var cell: Array = cell_at.call(pos)
		if not cell.is_empty():
			guard.start_touch(pos, now)
			if guard.has_method("filter_cell"):
				guard.filter_cell(Vector2i(int(cell[0]), int(cell[1])))
			decoder.begin(cell[0], cell[1], now)
	else:
		guard.end_touch()
		decoder.finish(now)

static func handle_move(
		pos: Vector2,
		guard: Variant,
		decoder: Variant,
		cell_at: Callable) -> void:
	var verdict: Dictionary = guard.filter_move(pos, Time.get_ticks_msec())
	if not bool(verdict.get("allow", true)):
		return
	if not bool(verdict.get("drag_started", false)):
		return
	if bool(verdict.get("drag_just_started", false)):
		decoder.start_drag()
	var snapped_pos: Vector2 = verdict.get("position", pos)
	var cell: Array = cell_at.call(snapped_pos)
	if not cell.is_empty():
		var cell_vec := Vector2i(int(cell[0]), int(cell[1]))
		if guard.has_method("filter_cell"):
			var cell_verdict: Dictionary = guard.filter_cell(cell_vec)
			if not bool(cell_verdict.get("allow", true)):
				return
		decoder.move(cell[0], cell[1])

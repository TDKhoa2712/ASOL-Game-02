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
	if not verdict.allow:
		decoder.flush_pending()
		decoder.cancel()
		return
	var cell: Array = cell_at.call(verdict.position)
	if not cell.is_empty():
		decoder.move(cell[0], cell[1])

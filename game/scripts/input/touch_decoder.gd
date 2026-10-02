extends RefCounted

signal cell_tapped(row: int, col: int)
signal cell_double_tapped(row: int, col: int)
signal cell_swiped(cells: Array)

const DOUBLE_TAP_WINDOW_MS := 350

var _has_pending_tap: bool = false
var _pending_tap_cell: Array = []
var _pending_tap_time: int = 0

var _pointer_active: bool = false
var _swipe_trail: Array = []
var _last_swipe_cell: Array = []

func begin(row: int, col: int, time_ms: int) -> void:
	_pointer_active = true
	if _has_pending_tap:
		if _pending_tap_cell == [row, col] and (time_ms - _pending_tap_time) <= DOUBLE_TAP_WINDOW_MS and time_ms >= _pending_tap_time:
			_clear_pending_tap()
			_pointer_active = false
			_swipe_trail.clear()
			_last_swipe_cell.clear()
			cell_double_tapped.emit(row, col)
			return
		_clear_pending_tap()

	_swipe_trail = [[row, col]]
	_last_swipe_cell = [row, col]

func move(row: int, col: int) -> void:
	if not _pointer_active:
		return
	if _last_swipe_cell.is_empty():
		_last_swipe_cell = [row, col]
		_swipe_trail = [[row, col]]
		return
	if _last_swipe_cell == [row, col]:
		return

	var cells: Array = _interpolate_cells(_last_swipe_cell, [row, col])
	for c in cells:
		if _swipe_trail.is_empty() or _swipe_trail[_swipe_trail.size() - 1] != c:
			_swipe_trail.append(c)
	_last_swipe_cell = [row, col]

func finish(time_ms: int) -> void:
	if not _pointer_active:
		return
	_pointer_active = false
	if _swipe_trail.size() > 1:
		var trail: Array = _swipe_trail.duplicate()
		_swipe_trail.clear()
		_last_swipe_cell.clear()
		cell_swiped.emit(trail)
	elif _swipe_trail.size() == 1:
		var tap_cell: Array = _swipe_trail[0]
		_swipe_trail.clear()
		_last_swipe_cell.clear()
		_has_pending_tap = true
		_pending_tap_cell = tap_cell
		_pending_tap_time = time_ms
		cell_tapped.emit(tap_cell[0], tap_cell[1])
	else:
		_swipe_trail.clear()
		_last_swipe_cell.clear()

func cancel() -> void:
	_pointer_active = false
	_swipe_trail.clear()
	_last_swipe_cell.clear()
	_clear_pending_tap()

func tick(time_ms: int) -> void:
	if _has_pending_tap and (time_ms - _pending_tap_time) >= DOUBLE_TAP_WINDOW_MS:
		_clear_pending_tap()

func _clear_pending_tap() -> void:
	_has_pending_tap = false
	_pending_tap_cell = []
	_pending_tap_time = 0

func _interpolate_cells(from: Array, to: Array) -> Array:
	var out: Array = []
	if from.size() < 2 or to.size() < 2:
		return out
	var dr: int = to[0] - from[0]
	var dc: int = to[1] - from[1]
	var steps: int = maxi(absi(dr), absi(dc))
	if steps == 0:
		return out
	for i in range(1, steps + 1):
		var ir: int = from[0] + int(roundi(float(dr) * i / steps))
		var ic: int = from[1] + int(roundi(float(dc) * i / steps))
		var cell: Array = [ir, ic]
		if out.is_empty() or out[out.size() - 1] != cell:
			out.append(cell)
	return out

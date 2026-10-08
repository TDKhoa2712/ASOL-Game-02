extends RefCounted

const DRAG_THRESHOLD_PX := 12.0
const MAX_VELOCITY_PX_PER_SEC := 6000.0
const MAX_INTERPOLATE_SPAN := 12

var _start_pos: Vector2
var _drag_started: bool = false

# Velocity gate state
var _prev_pos: Vector2
var _prev_time_ms: int = 0
var _has_prev: bool = false

# Neighbor guard state
var _prev_cell: Vector2i = Vector2i(-1, -1)

func start_touch(pos: Vector2, time_ms: int) -> void:
	_start_pos = pos
	_drag_started = false
	_prev_pos = pos
	_prev_time_ms = time_ms
	_has_prev = false
	_prev_cell = Vector2i(-1, -1)

func filter_cell(cell: Vector2i) -> Dictionary:
	if cell.x < 0 or cell.y < 0:
		return {"allow": false, "reason": "invalid_cell"}
	if _prev_cell == Vector2i(-1, -1) or cell == _prev_cell:
		_prev_cell = cell
		return {"allow": true, "reason": ""}
	var span := maxi(absi(cell.x - _prev_cell.x), absi(cell.y - _prev_cell.y))
	if span > MAX_INTERPOLATE_SPAN:
		return {"allow": false, "reason": "neighbor"}
	_prev_cell = cell
	return {"allow": true, "reason": ""}

func filter_move(pos: Vector2, time_ms: int, cell: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	var just_started := false
	if not _drag_started and _start_pos.distance_to(pos) > DRAG_THRESHOLD_PX:
		_drag_started = true
		just_started = true

	# Layer 1: Velocity Gate (threshold 6000 px/s)
	if _has_prev:
		var dt_sec := float(time_ms - _prev_time_ms) / 1000.0
		if dt_sec > 0.0:
			var velocity := _prev_pos.distance_to(pos) / dt_sec
			if velocity > MAX_VELOCITY_PX_PER_SEC:
				return {
					"allow": false,
					"reason": "velocity",
					"position": pos,
					"drag_started": _drag_started,
					"drag_just_started": just_started,
					"axis_snapped_delta": Vector2.ZERO,
				}

	# Layer 2: Free Multi-Axis Movement (no hard axis lock, permits diagonal and orthogonal freely)
	var delta := pos - _prev_pos

	# Layer 3: Neighbor Guard (if cell provided)
	if cell != Vector2i(-1, -1):
		if cell.x < 0 or cell.y < 0:
			return {
				"allow": false,
				"reason": "neighbor",
				"position": pos,
				"drag_started": _drag_started,
				"drag_just_started": just_started,
				"axis_snapped_delta": delta,
			}
		if _prev_cell != Vector2i(-1, -1) and cell != _prev_cell:
			var span := maxi(absi(cell.x - _prev_cell.x), absi(cell.y - _prev_cell.y))
			if span > MAX_INTERPOLATE_SPAN:
				return {
					"allow": false,
					"reason": "neighbor",
					"position": pos,
					"drag_started": _drag_started,
					"drag_just_started": just_started,
					"axis_snapped_delta": delta,
				}
		_prev_cell = cell

	_prev_pos = pos
	_prev_time_ms = time_ms
	_has_prev = true

	return {
		"allow": true,
		"reason": "",
		"position": pos,
		"drag_started": _drag_started,
		"drag_just_started": just_started,
		"axis_snapped_delta": delta,
	}

func end_touch() -> void:
	_drag_started = false
	_has_prev = false
	_prev_cell = Vector2i(-1, -1)

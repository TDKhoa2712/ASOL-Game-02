extends RefCounted

const DRAG_THRESHOLD_PX := 12.0
const MAX_VELOCITY_PX_PER_SEC := 2000.0
const AXIS_LOCK_RATIO := 1.5

enum AxisLock { NONE, HORIZONTAL, VERTICAL }

var _start_pos: Vector2
var _drag_started: bool = false

# Velocity gate state
var _prev_pos: Vector2
var _prev_time_ms: int = 0
var _has_prev: bool = false

# Axis lock state
var _axis_lock: int = AxisLock.NONE
var _cumulative_dx: float = 0.0
var _cumulative_dy: float = 0.0
var _current_pos: Vector2

func start_touch(pos: Vector2, time_ms: int) -> void:
	_start_pos = pos
	_drag_started = false
	_prev_pos = pos
	_prev_time_ms = time_ms
	_has_prev = false
	_axis_lock = AxisLock.NONE
	_cumulative_dx = 0.0
	_cumulative_dy = 0.0
	_current_pos = pos

func filter_move(pos: Vector2, time_ms: int) -> Dictionary:
	var just_started := false
	if not _drag_started and _start_pos.distance_to(pos) > DRAG_THRESHOLD_PX:
		_drag_started = true
		just_started = true

	# Layer 1: Velocity Gate
	if _has_prev:
		var dt_sec := float(time_ms - _prev_time_ms) / 1000.0
		if dt_sec > 0.0:
			var velocity := _prev_pos.distance_to(pos) / dt_sec
			if velocity > MAX_VELOCITY_PX_PER_SEC:
				return {
					"allow": false,
					"reason": "velocity",
					"position": _current_pos,
					"drag_started": _drag_started,
					"drag_just_started": just_started,
					"axis_snapped_delta": Vector2.ZERO,
				}

	# Layer 2: Axis Lock Hysteresis
	var delta := pos - _prev_pos
	_cumulative_dx += absf(delta.x)
	_cumulative_dy += absf(delta.y)

	if _axis_lock == AxisLock.NONE:
		if _cumulative_dx >= _cumulative_dy * AXIS_LOCK_RATIO and _cumulative_dx > 0.0:
			_axis_lock = AxisLock.HORIZONTAL
		elif _cumulative_dy >= _cumulative_dx * AXIS_LOCK_RATIO and _cumulative_dy > 0.0:
			_axis_lock = AxisLock.VERTICAL

	var snapped_delta := delta
	match _axis_lock:
		AxisLock.HORIZONTAL:
			snapped_delta = Vector2(delta.x, 0.0)
		AxisLock.VERTICAL:
			snapped_delta = Vector2(0.0, delta.y)
		_:
			snapped_delta = delta

	_current_pos += snapped_delta
	_prev_pos = pos
	_prev_time_ms = time_ms
	_has_prev = true

	return {
		"allow": true,
		"reason": "",
		"position": _current_pos,
		"drag_started": _drag_started,
		"drag_just_started": just_started,
		"axis_snapped_delta": snapped_delta,
	}

func end_touch() -> void:
	_drag_started = false
	_has_prev = false
	_axis_lock = AxisLock.NONE
	_cumulative_dx = 0.0
	_cumulative_dy = 0.0

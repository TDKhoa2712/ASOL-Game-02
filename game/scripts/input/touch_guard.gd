extends RefCounted

const DRAG_THRESHOLD_PX := 12.0
const MAX_VELOCITY_PX_PER_SEC := 2000.0

var _start_pos: Vector2
var _drag_started: bool = false

# Velocity gate state
var _prev_pos: Vector2
var _prev_time_ms: int = 0
var _has_prev: bool = false

func start_touch(pos: Vector2, time_ms: int) -> void:
	_start_pos = pos
	_drag_started = false
	_prev_pos = pos
	_prev_time_ms = time_ms
	_has_prev = false

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
					"position": pos,
					"drag_started": _drag_started,
					"drag_just_started": just_started,
				}

	_prev_pos = pos
	_prev_time_ms = time_ms
	_has_prev = true

	return {
		"allow": true,
		"reason": "",
		"position": pos,
		"drag_started": _drag_started,
		"drag_just_started": just_started,
	}

func end_touch() -> void:
	_drag_started = false
	_has_prev = false

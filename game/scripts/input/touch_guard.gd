extends RefCounted

const VELOCITY_LIMIT_PX_PER_SEC := 1200.0
const AXIS_LOCK_THRESHOLD_PX := 18.0
const AXIS_DOMINANCE_RATIO := 1.75

enum AxisMode { NONE, HORIZONTAL, VERTICAL }

var _start_pos: Vector2
var _last_pos: Vector2
var _last_time_ms: int = 0
var _axis_mode: int = AxisMode.NONE
var _is_speed_locked: bool = false

func start_touch(pos: Vector2, time_ms: int) -> void:
	_start_pos = pos
	_last_pos = pos
	_last_time_ms = time_ms
	_axis_mode = AxisMode.NONE
	_is_speed_locked = false

func filter_move(pos: Vector2, time_ms: int) -> Dictionary:
	if _is_speed_locked:
		return {"allow": false, "reason": "speed_locked", "position": pos}

	var delta_time_s := float(time_ms - _last_time_ms) / 1000.0
	if delta_time_s > 0.0:
		var speed := _last_pos.distance_to(pos) / delta_time_s
		if speed > VELOCITY_LIMIT_PX_PER_SEC:
			_is_speed_locked = true
			return {"allow": false, "reason": "too_fast", "position": pos}

	_last_pos = pos
	_last_time_ms = time_ms

	var delta := pos - _start_pos
	var dx := absf(delta.x)
	var dy := absf(delta.y)

	if _axis_mode == AxisMode.NONE:
		if dx > AXIS_LOCK_THRESHOLD_PX and dx > dy * AXIS_DOMINANCE_RATIO:
			_axis_mode = AxisMode.HORIZONTAL
		elif dy > AXIS_LOCK_THRESHOLD_PX and dy > dx * AXIS_DOMINANCE_RATIO:
			_axis_mode = AxisMode.VERTICAL
		elif dx > AXIS_LOCK_THRESHOLD_PX and dy > AXIS_LOCK_THRESHOLD_PX:
			return {"allow": false, "reason": "diagonal_ambiguity", "position": pos}

	var filtered_pos := _start_pos if _axis_mode == AxisMode.NONE else pos
	if _axis_mode == AxisMode.HORIZONTAL:
		filtered_pos.y = _start_pos.y
	elif _axis_mode == AxisMode.VERTICAL:
		filtered_pos.x = _start_pos.x
	return {"allow": true, "reason": "", "position": filtered_pos}

func end_touch() -> void:
	_axis_mode = AxisMode.NONE
	_is_speed_locked = false

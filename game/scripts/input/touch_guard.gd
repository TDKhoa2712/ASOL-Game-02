extends RefCounted

const DRAG_THRESHOLD_PX := 12.0

var _start_pos: Vector2
var _drag_started: bool = false

func start_touch(pos: Vector2, _time_ms: int) -> void:
	_start_pos = pos
	_drag_started = false

func filter_move(pos: Vector2, _time_ms: int) -> Dictionary:
	var just_started := false
	if not _drag_started and _start_pos.distance_to(pos) > DRAG_THRESHOLD_PX:
		_drag_started = true
		just_started = true
	return {
		"allow": true,
		"reason": "",
		"position": pos,
		"drag_started": _drag_started,
		"drag_just_started": just_started,
	}

func end_touch() -> void:
	_drag_started = false

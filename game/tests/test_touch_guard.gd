extends SceneTree

const TouchGuard = preload("res://scripts/input/touch_guard.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_drag_waits_through_twelve_pixels()
	_test_drag_starts_after_twelve_pixels()
	_test_fast_drag_is_allowed()
	_test_diagonal_drag_is_allowed()
	_test_new_gesture_resets_drag_state()
	_test_zero_delta_time_is_allowed()
	if _fails.is_empty():
		print("INPUT_TOUCH_GUARD_PASS")
		quit(0)
	else:
		for failure in _fails:
			printerr(failure)
		quit(1)

func _test_drag_waits_through_twelve_pixels() -> void:
	var guard := TouchGuard.new()
	guard.start_touch(Vector2(100, 100), 1000)
	var result := guard.filter_move(Vector2(112, 100), 1016)
	_assert(not bool(result.get("drag_started", false)), "12px movement remains a tap candidate")

func _test_drag_starts_after_twelve_pixels() -> void:
	var guard := TouchGuard.new()
	guard.start_touch(Vector2(100, 100), 1000)
	var result := guard.filter_move(Vector2(113, 100), 1016)
	_assert(bool(result.allow), "13px drag is allowed")
	_assert(bool(result.get("drag_started", false)), "13px movement starts drag")
	_assert(bool(result.get("drag_just_started", false)), "threshold crossing is reported once")
	_assert(result.position == Vector2(113, 100), "drag keeps physical position")

func _test_fast_drag_is_allowed() -> void:
	var guard := TouchGuard.new()
	guard.start_touch(Vector2(100, 100), 1000)
	# 24px in one 60Hz frame = 1500px/s; this is a normal intentional drag.
	var result := guard.filter_move(Vector2(124, 100), 1016)
	_assert(bool(result.allow), "one-frame drag is not rejected by physical speed")
	_assert(bool(result.get("drag_started", false)), "one-frame drag starts a stroke")

func _test_diagonal_drag_is_allowed() -> void:
	var guard := TouchGuard.new()
	guard.start_touch(Vector2(100, 100), 1000)
	var result := guard.filter_move(Vector2(125, 125), 1100)
	_assert(bool(result.allow), "diagonal drag is allowed")
	_assert(bool(result.get("drag_started", false)), "diagonal drag starts a stroke")
	_assert(result.position == Vector2(125, 125), "diagonal drag keeps both axes")

func _test_new_gesture_resets_drag_state() -> void:
	var guard := TouchGuard.new()
	guard.start_touch(Vector2(100, 100), 1000)
	guard.filter_move(Vector2(120, 100), 1100)
	guard.end_touch()
	guard.start_touch(Vector2(200, 200), 2000)
	var result := guard.filter_move(Vector2(205, 200), 2100)
	_assert(not bool(result.get("drag_started", false)), "new gesture starts below drag threshold")

func _test_zero_delta_time_is_allowed() -> void:
	var guard := TouchGuard.new()
	guard.start_touch(Vector2(100, 100), 1000)
	var result := guard.filter_move(Vector2(120, 100), 1000)
	_assert(bool(result.allow), "same-timestamp drag is allowed")
	_assert(bool(result.get("drag_started", false)), "same-timestamp drag still uses distance threshold")

func _assert(condition: bool, label: String) -> void:
	if not condition:
		_fails.append("FAIL: " + label)

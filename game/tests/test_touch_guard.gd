extends SceneTree

const TouchGuard = preload("res://scripts/input/touch_guard.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_drag_waits_through_twelve_pixels()
	_test_drag_starts_after_twelve_pixels()
	_test_fast_drag_is_allowed()
	_test_velocity_gate_fast_reject()
	_test_velocity_gate_first_frame()
	_test_axis_lock_horizontal()
	_test_axis_lock_vertical()
	_test_axis_lock_pure_horizontal()
	_test_axis_lock_pure_vertical()
	_test_axis_lock_diagonal_allowed()
	_test_axis_lock_reset_on_end()
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

func _test_velocity_gate_fast_reject() -> void:
	var guard := TouchGuard.new()
	guard.start_touch(Vector2(100, 100), 1000)
	# First move sets prev
	guard.filter_move(Vector2(110, 100), 1010)
	# 1000px in 10ms = 100,000 px/s (> 2000 px/s) → reject
	var result := guard.filter_move(Vector2(1110, 100), 1020)
	_assert(not bool(result.allow), "super fast swipe rejected by velocity gate")
	_assert(str(result.get("reason", "")) == "velocity", "reason is velocity")

func _test_velocity_gate_first_frame() -> void:
	var guard := TouchGuard.new()
	guard.start_touch(Vector2(100, 100), 1000)
	# First filter_move after start has no prev → always pass
	var result := guard.filter_move(Vector2(5000, 100), 1001)
	_assert(bool(result.allow), "first frame always passes velocity")

func _test_axis_lock_horizontal() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	g.filter_move(Vector2(100, 100), 1000)
	# Strong horizontal: dx=100, dy=10 → ratio 10x → lock horizontal
	var r := g.filter_move(Vector2(200, 110), 1100)
	_assert(bool(r.allow), "horizontal move allowed")
	# Subsequent vertical move should still be snapped horizontal
	var r2 := g.filter_move(Vector2(200, 200), 1200)
	_assert(bool(r2.allow), "locked horizontal allows move")
	var delta: Vector2 = r2.get("axis_snapped_delta", Vector2.ZERO)
	_assert(delta.y == 0.0, "vertical component snapped to zero when locked horizontal")
	var pos: Vector2 = r2.get("position", Vector2.ZERO)
	_assert(pos.y == 100.0, "position y remains snapped when locked horizontal")

func _test_axis_lock_vertical() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	g.filter_move(Vector2(100, 100), 1000)
	# Strong vertical: dx=10, dy=100 → lock vertical
	var r := g.filter_move(Vector2(110, 200), 1100)
	_assert(bool(r.allow), "vertical move allowed")
	var delta: Vector2 = r.get("axis_snapped_delta", Vector2.ZERO)
	_assert(delta.x == 0.0, "horizontal component snapped to zero when locked vertical")
	var r2 := g.filter_move(Vector2(200, 200), 1200)
	var delta2: Vector2 = r2.get("axis_snapped_delta", Vector2.ZERO)
	_assert(delta2.x == 0.0, "horizontal component snapped to zero in subsequent move")
	var pos2: Vector2 = r2.get("position", Vector2.ZERO)
	_assert(pos2.x == 100.0, "position x remains snapped when locked vertical")

func _test_axis_lock_pure_horizontal() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	g.filter_move(Vector2(100, 100), 1000)
	# Pure horizontal (dy == 0) must lock horizontal without deadlock
	var r := g.filter_move(Vector2(200, 100), 1100)
	_assert(bool(r.allow), "pure horizontal move allowed")
	var delta: Vector2 = r.get("axis_snapped_delta", Vector2.ZERO)
	_assert(delta.x == 100.0 and delta.y == 0.0, "pure horizontal delta preserved")
	# Now move diagonally/vertically: must be snapped horizontal
	var r2 := g.filter_move(Vector2(250, 150), 1200)
	var delta2: Vector2 = r2.get("axis_snapped_delta", Vector2.ZERO)
	_assert(delta2.y == 0.0, "pure horizontal locked subsequent vertical movement")

func _test_axis_lock_pure_vertical() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	g.filter_move(Vector2(100, 100), 1000)
	# Pure vertical (dx == 0) must lock vertical without deadlock
	var r := g.filter_move(Vector2(100, 200), 1100)
	_assert(bool(r.allow), "pure vertical move allowed")
	var delta: Vector2 = r.get("axis_snapped_delta", Vector2.ZERO)
	_assert(delta.y == 100.0 and delta.x == 0.0, "pure vertical delta preserved")
	# Now move horizontally: must be snapped vertical
	var r2 := g.filter_move(Vector2(150, 250), 1200)
	var delta2: Vector2 = r2.get("axis_snapped_delta", Vector2.ZERO)
	_assert(delta2.x == 0.0, "pure vertical locked subsequent horizontal movement")

func _test_axis_lock_diagonal_allowed() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	g.filter_move(Vector2(100, 100), 1000)
	# Diagonal: dx=50, dy=50 → ratio 1.0 < 1.5 → unlocked diagonal allowed
	var r := g.filter_move(Vector2(150, 150), 1100)
	_assert(bool(r.allow), "diagonal move allowed")
	var delta: Vector2 = r.get("axis_snapped_delta", Vector2.ZERO)
	_assert(delta == Vector2(50, 50), "diagonal move keeps both axes")

func _test_axis_lock_reset_on_end() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	g.filter_move(Vector2(100, 100), 1000)
	g.filter_move(Vector2(200, 110), 1100)  # lock horizontal
	g.end_touch()
	g.start_touch(Vector2(100, 100), 2000)
	g.filter_move(Vector2(100, 100), 2000)
	# New gesture: strong vertical should lock vertical, not horizontal
	var r := g.filter_move(Vector2(110, 200), 2100)
	var delta: Vector2 = r.get("axis_snapped_delta", Vector2.ZERO)
	_assert(delta.x == 0.0, "axis lock resets between gestures")

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

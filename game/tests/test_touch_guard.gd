extends SceneTree

const TouchGuard = preload("res://scripts/input/touch_guard.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_velocity_gate_rejects_fast_swipe()
	_test_velocity_gate_allows_slow_swipe()
	_test_velocity_gate_resets_on_new_gesture()
	_test_axis_lock_horizontal()
	_test_axis_lock_vertical()
	_test_axis_lock_projects_cross_axis_drift()
	_test_axis_waits_at_origin_before_lock()
	_test_axis_lock_diagonal_rejected()
	_test_axis_lock_resets_on_new_gesture()
	_test_short_movement_no_lock()
	_test_zero_delta_time_no_crash()
	if _fails.is_empty():
		print("INPUT_TOUCH_GUARD_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_velocity_gate_rejects_fast_swipe() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	# Move 200px in 100ms = 2000 px/s > 1200 limit
	var result := g.filter_move(Vector2(300, 100), 1100)
	_assert(result.allow == false, "fast swipe rejected")
	_assert(result.reason == "too_fast", "reason is too_fast")

func _test_velocity_gate_allows_slow_swipe() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	# Move 50px in 500ms = 100 px/s < 1200 limit
	var result := g.filter_move(Vector2(150, 100), 1500)
	_assert(result.allow == true, "slow swipe allowed")

func _test_velocity_gate_resets_on_new_gesture() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	# Trigger speed lock
	g.filter_move(Vector2(500, 100), 1050)
	# Subsequent move stays locked
	var locked := g.filter_move(Vector2(520, 100), 1200)
	_assert(locked.allow == false, "stays locked after fast swipe")
	_assert(locked.reason == "speed_locked", "reason is speed_locked")
	# New gesture resets
	g.end_touch()
	g.start_touch(Vector2(200, 200), 2000)
	var fresh := g.filter_move(Vector2(220, 200), 2500)
	_assert(fresh.allow == true, "new gesture is unlocked")

func _test_axis_lock_horizontal() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	# Move 25px right, 2px down — clearly horizontal
	var result := g.filter_move(Vector2(125, 102), 1300)
	_assert(result.allow == true, "horizontal move allowed")
	# Further move stays horizontal even if finger drifts
	var result2 := g.filter_move(Vector2(150, 110), 1500)
	_assert(result2.allow == true, "locked horizontal allows continued")

func _test_axis_lock_vertical() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	# Move 2px right, 25px down — clearly vertical
	var result := g.filter_move(Vector2(102, 125), 1300)
	_assert(result.allow == true, "vertical move allowed")

func _test_axis_lock_projects_cross_axis_drift() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	g.filter_move(Vector2(125, 102), 1300)
	var result := g.filter_move(Vector2(150, 130), 1800)
	_assert(result.has("position"), "axis verdict includes filtered position")
	if result.has("position"):
		_assert(result.position == Vector2(150, 100), "horizontal lock projects drift to start axis")

func _test_axis_waits_at_origin_before_lock() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	var result := g.filter_move(Vector2(105, 103), 1200)
	_assert(result.position == Vector2(100, 100), "movement stays at origin before axis lock")

func _test_axis_lock_diagonal_rejected() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	# Move 25px right, 25px down — ambiguous diagonal
	var result := g.filter_move(Vector2(125, 125), 1300)
	_assert(result.allow == false, "diagonal rejected")
	_assert(result.reason == "diagonal_ambiguity", "reason is diagonal_ambiguity")

func _test_axis_lock_resets_on_new_gesture() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	# Lock horizontal
	g.filter_move(Vector2(125, 102), 1300)
	# End and start new gesture
	g.end_touch()
	g.start_touch(Vector2(200, 200), 2000)
	# Now move vertical — should work (not locked horizontal)
	var result := g.filter_move(Vector2(202, 225), 2300)
	_assert(result.allow == true, "new gesture allows vertical after prior horizontal lock")

func _test_short_movement_no_lock() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	# Move only 5px — below AXIS_LOCK_THRESHOLD_PX (18px)
	var result := g.filter_move(Vector2(105, 103), 1200)
	_assert(result.allow == true, "short movement allowed without lock")

func _test_zero_delta_time_no_crash() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	# Same timestamp — 0 delta time, should not crash or divide by zero
	var result := g.filter_move(Vector2(110, 100), 1000)
	_assert(typeof(result.allow) == TYPE_BOOL, "zero delta returns valid result")

func _assert(condition: bool, label: String) -> void:
	if not condition:
		_fails.append("FAIL: " + label)

extends SceneTree

const TouchGuard = preload("res://scripts/input/touch_guard.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_drag_waits_through_twelve_pixels()
	_test_drag_starts_after_twelve_pixels()
	_test_fast_drag_is_allowed()
	_test_velocity_gate_fast_reject()
	_test_velocity_gate_first_frame()
	_test_velocity_gate_rapid_batch_allowed()
	_test_diagonal_drag_keeps_both_axes()
	_test_diagonal_drag_after_horizontal_movement_allowed()
	_test_diagonal_drag_after_vertical_movement_allowed()
	_test_neighbor_guard_adjacent_orthogonal_pass()
	_test_neighbor_guard_adjacent_diagonal_pass()
	_test_neighbor_guard_same_cell_pass()
	_test_neighbor_guard_first_cell_pass()
	_test_neighbor_guard_interpolatable_jump_pass()
	_test_neighbor_guard_huge_jump_reject()
	_test_neighbor_guard_skip_when_no_cell()
	_test_neighbor_guard_filter_cell_method()
	_test_pipeline_velocity_no_state_corruption()
	_test_full_guard_end_to_end()
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

func _test_velocity_gate_rapid_batch_allowed() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	g.filter_move(Vector2(110, 100), 1010)
	# Rapid batch swipe across 400px in 100ms = 4000 px/s (<= 6000 px/s threshold)
	var r := g.filter_move(Vector2(510, 100), 1110)
	_assert(bool(r.allow), "rapid intentional batch swipe passes velocity gate")

func _test_diagonal_drag_keeps_both_axes() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	g.filter_move(Vector2(100, 100), 1000)
	# Diagonal move: dx=100, dy=100
	var r := g.filter_move(Vector2(200, 200), 1100)
	_assert(bool(r.allow), "diagonal move allowed")
	var delta: Vector2 = r.get("axis_snapped_delta", Vector2.ZERO)
	_assert(delta == Vector2(100, 100), "diagonal delta preserves both axes")
	_assert(r.position == Vector2(200, 200), "diagonal position preserves both axes")

func _test_diagonal_drag_after_horizontal_movement_allowed() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	g.filter_move(Vector2(100, 100), 1000)
	# Start with strong horizontal move
	var r1 := g.filter_move(Vector2(200, 100), 1100)
	_assert(bool(r1.allow), "horizontal start allowed")
	# Then move diagonally: y component must NOT be locked or zeroed out
	var r2 := g.filter_move(Vector2(250, 150), 1200)
	_assert(bool(r2.allow), "subsequent diagonal move allowed without axis lock")
	var delta: Vector2 = r2.get("axis_snapped_delta", Vector2.ZERO)
	_assert(delta.y == 50.0 and delta.x == 50.0, "both axes preserved after horizontal movement")
	_assert(r2.position == Vector2(250, 150), "unconstrained position reflects true pointer")

func _test_diagonal_drag_after_vertical_movement_allowed() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	g.filter_move(Vector2(100, 100), 1000)
	# Start with strong vertical move
	var r1 := g.filter_move(Vector2(100, 200), 1100)
	_assert(bool(r1.allow), "vertical start allowed")
	# Then move diagonally: x component must NOT be locked or zeroed out
	var r2 := g.filter_move(Vector2(150, 250), 1200)
	_assert(bool(r2.allow), "subsequent diagonal move allowed without axis lock")
	var delta: Vector2 = r2.get("axis_snapped_delta", Vector2.ZERO)
	_assert(delta.x == 50.0 and delta.y == 50.0, "both axes preserved after vertical movement")
	_assert(r2.position == Vector2(150, 250), "unconstrained position reflects true pointer")

func _test_neighbor_guard_adjacent_orthogonal_pass() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	g.filter_move(Vector2(110, 100), 1100, Vector2i(0, 0))
	var r := g.filter_move(Vector2(120, 100), 1200, Vector2i(0, 1))
	_assert(bool(r.allow), "adjacent orthogonal cell passes neighbor guard")

func _test_neighbor_guard_adjacent_diagonal_pass() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	g.filter_move(Vector2(110, 100), 1100, Vector2i(0, 0))
	# Chebyshev distance = 1 → diagonal adjacent cell passes
	var r := g.filter_move(Vector2(120, 120), 1200, Vector2i(1, 1))
	_assert(bool(r.allow), "adjacent diagonal cell passes neighbor guard")

func _test_neighbor_guard_same_cell_pass() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	g.filter_move(Vector2(110, 100), 1100, Vector2i(2, 3))
	var r := g.filter_move(Vector2(115, 100), 1200, Vector2i(2, 3))
	_assert(bool(r.allow), "same cell passes neighbor guard")

func _test_neighbor_guard_first_cell_pass() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	# First cell in gesture always passes regardless of position
	var r := g.filter_move(Vector2(110, 100), 1100, Vector2i(5, 5))
	_assert(bool(r.allow), "first cell always passes neighbor guard")

func _test_neighbor_guard_interpolatable_jump_pass() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	g.filter_move(Vector2(110, 100), 1100, Vector2i(0, 0))
	# Normal swipe jumping 2 cells on board (e.g. 0,0 to 2,2) allowed for interpolation
	var r := g.filter_move(Vector2(130, 130), 1200, Vector2i(2, 2))
	_assert(bool(r.allow), "interpolatable cell jump passes neighbor guard")

func _test_neighbor_guard_huge_jump_reject() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	g.filter_move(Vector2(110, 100), 1100, Vector2i(0, 0))
	# Normal physical speed (20px in 100ms = 200 px/s) but huge jump across 50 cells rejected
	var r := g.filter_move(Vector2(130, 100), 1200, Vector2i(0, 50))
	_assert(not bool(r.allow), "huge jump rejected by neighbor guard")
	_assert(str(r.get("reason", "")) == "neighbor", "reason is neighbor")

func _test_neighbor_guard_skip_when_no_cell() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	g.filter_move(Vector2(110, 100), 1100, Vector2i(0, 0))
	# Default cell (-1, -1) skips neighbor guard
	var r := g.filter_move(Vector2(130, 130), 1200)
	_assert(bool(r.allow), "neighbor guard skipped when cell not provided")

func _test_neighbor_guard_filter_cell_method() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	var r1 := g.filter_cell(Vector2i(1, 1))
	_assert(bool(r1.allow), "filter_cell allows first cell")
	var r2 := g.filter_cell(Vector2i(1, 2))
	_assert(bool(r2.allow), "filter_cell allows adjacent cell")
	var r_bad := g.filter_cell(Vector2i(-1, -1))
	_assert(not bool(r_bad.allow), "filter_cell rejects negative cell")

func _test_pipeline_velocity_no_state_corruption() -> void:
	# Verify that a velocity rejection does not update axis or neighbor state
	var g := TouchGuard.new()
	g.start_touch(Vector2(100, 100), 1000)
	g.filter_move(Vector2(110, 100), 1100, Vector2i(0, 0))
	# Fast move → velocity reject (>2000 px/s) → should NOT update _prev_cell
	var r := g.filter_move(Vector2(5000, 100), 1101, Vector2i(0, 5))
	_assert(not bool(r.allow), "velocity rejects fast move")
	# Slow move to adjacent cell → should pass (prev_cell still 0,0)
	var r2 := g.filter_move(Vector2(120, 100), 1200, Vector2i(0, 1))
	_assert(bool(r2.allow), "adjacent cell after velocity reject passes")

func _test_full_guard_end_to_end() -> void:
	var g := TouchGuard.new()
	g.start_touch(Vector2(50, 50), 1000)
	# Slow, horizontal, adjacent → all 3 layers pass
	var r1 := g.filter_move(Vector2(100, 55), 1100, Vector2i(0, 0))
	_assert(bool(r1.allow), "first cell passes all guards")
	var r2 := g.filter_move(Vector2(150, 58), 1200, Vector2i(0, 1))
	_assert(bool(r2.allow), "adjacent horizontal cell passes")
	var r3 := g.filter_move(Vector2(200, 60), 1300, Vector2i(0, 2))
	_assert(bool(r3.allow), "next adjacent cell passes")
	g.end_touch()

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

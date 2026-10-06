extends SceneTree

const PlaySession = preload("res://scripts/input/play_session.gd")
const CandyCounterAnimator = preload("res://scripts/screens/candy_counter_animator.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const Palette = preload("res://scripts/theme/palette.gd")

var _fails: Array[String] = []

func _init() -> void:
	call_deferred("_run_tests")

func _assert(cond: bool, msg: String) -> void:
	if not cond:
		_fails.append("FAIL: " + msg)

func _create_test_level() -> Dictionary:
	return {
		"size": 4,
		"regions": ["AAAA", "BBBB", "CCCC", "DDDD"],
		"solution": [0, 1, 2, 3],
		"givens": [{"r": 1, "c": 1}], # Zone B is given
		"id": "T04"
	}

func _run_tests() -> void:
	var level := _create_test_level()
	var session := PlaySession.new(level)
	var row := HBoxContainer.new()
	row.size = Vector2(400, 80)
	root.add_child(row)
	await process_frame

	# 1. Initial sync: Zone B is given, should be in front (index 0)
	CandyCounterAnimator.sync_status(session, row)
	_assert(row.get_child_count() == 4, "Row has 4 children after initial sync")
	var c0: TextureRect = row.get_child(0) as TextureRect
	_assert(c0 != null and c0.get_meta("zone_id") == "B", "Given zone B is at index 0")
	_assert(c0.modulate != Palette.ICON_MUTED, "Zone B is revealed (found)")

	# Other children are unfound
	for i in range(1, 4):
		var child: TextureRect = row.get_child(i) as TextureRect
		_assert(child.modulate == Palette.ICON_MUTED, "Child %d is muted" % i)

	# 2. Player places candy in Zone D (index 3 initially)
	session.try_candy(3, 3) # Cell in zone D
	var tw: Tween = CandyCounterAnimator.play_candy_found(session, row, "D")
	_assert(tw != null, "Tween is created for candy found")

	# Wait for animation to finish
	if tw != null:
		await tw.finished
		await process_frame

	# After animation: D should be moved right after B (index 1)
	var new_c1: TextureRect = row.get_child(1) as TextureRect
	_assert(new_c1 != null and new_c1.get_meta("zone_id") == "D", "Zone D moved to index 1")
	_assert(new_c1.modulate != Palette.ICON_MUTED, "Zone D is now revealed")
	_assert(new_c1.scale == Vector2.ONE, "Zone D scale returned to 1.0")

	# The missing zones (A and C) are pushed behind D (indices 2 and 3)
	var remaining_zones: Array = [row.get_child(2).get_meta("zone_id"), row.get_child(3).get_meta("zone_id")]
	_assert(remaining_zones.has("A") and remaining_zones.has("C"), "Missing zones pushed back to indices 2 and 3")

	# 3. Test with motion_enabled = false
	LayoutTokens.motion_enabled = false
	session.try_candy(0, 0) # Zone A
	var tw_motion_off: Tween = CandyCounterAnimator.play_candy_found(session, row, "A")
	_assert(tw_motion_off == null, "No tween when motion_enabled is false")
	var new_c2: TextureRect = row.get_child(2) as TextureRect
	_assert(new_c2 != null and new_c2.get_meta("zone_id") == "A", "Zone A immediately at index 2 without motion")
	LayoutTokens.motion_enabled = true

	row.queue_free()
	await process_frame

	if _fails.is_empty():
		print("CANDY_COUNTER_ANIMATOR_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

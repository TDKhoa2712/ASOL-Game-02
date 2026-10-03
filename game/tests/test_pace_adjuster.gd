extends SceneTree

const PaceAdjuster = preload("res://scripts/campaign/pace_adjuster.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_no_offset_default()
	_test_clean_streak_promotes()
	_test_dirty_win_no_promote()
	_test_fail_streak_demotes()
	_test_retry_streak_demotes()
	_test_demote_guard()
	_test_rank_cap_low_level()
	_test_rank_cap_high_level()
	_test_round_trip()
	if _fails.is_empty():
		print("PACE_ADJUSTER_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_no_offset_default() -> void:
	var pa := PaceAdjuster.new()
	_assert(pa.rank_offset(1, 1) == 0, "no offset initially")

func _test_clean_streak_promotes() -> void:
	var pa := PaceAdjuster.new()
	pa.record_result(true, 0, 0, false)
	pa.record_result(true, 0, 0, false)
	_assert(pa.rank_offset(25, 1) == 1, "2 clean wins on level 25 base_rank 1 → +1")

func _test_dirty_win_no_promote() -> void:
	var pa := PaceAdjuster.new()
	pa.record_result(true, 1, 0, false)
	pa.record_result(true, 0, 0, false)
	_assert(pa.rank_offset(25, 1) == 0, "dirty win breaks clean streak → no promote")

func _test_fail_streak_demotes() -> void:
	var pa := PaceAdjuster.new()
	pa.record_result(false, 0, 0, false)
	pa.record_result(false, 0, 0, false)
	_assert(pa.rank_offset(25, 2) == -1, "2 fails → -1")

func _test_retry_streak_demotes() -> void:
	var pa := PaceAdjuster.new()
	pa.record_result(true, 1, 0, true)
	pa.record_result(true, 0, 0, true)
	_assert(pa.rank_offset(25, 2) == -1, "2 retries → -1")

func _test_demote_guard() -> void:
	var pa := PaceAdjuster.new()
	pa.record_result(false, 0, 0, false)
	pa.record_result(false, 0, 0, false)
	_assert(pa.rank_offset(25, 2) == -1, "first call demotes")
	_assert(pa.rank_offset(25, 2) == 0, "second call guarded — no double demote")
	pa.on_level_start()
	pa.record_result(false, 0, 0, false)
	pa.record_result(false, 0, 0, false)
	_assert(pa.rank_offset(25, 2) == -1, "after on_level_start guard resets")

func _test_rank_cap_low_level() -> void:
	var pa := PaceAdjuster.new()
	pa.record_result(true, 0, 0, false)
	pa.record_result(true, 0, 0, false)
	_assert(pa.rank_offset(10, 2) == 0, "level 10 max_rank 2, base_rank 2 → no room to promote")

func _test_rank_cap_high_level() -> void:
	var pa := PaceAdjuster.new()
	pa.record_result(true, 0, 0, false)
	pa.record_result(true, 0, 0, false)
	_assert(pa.rank_offset(25, 2) == 1, "level 25 max_rank 3, base_rank 2 → +1")

func _test_round_trip() -> void:
	var pa := PaceAdjuster.new()
	pa.record_result(true, 0, 0, false)
	pa.record_result(true, 0, 0, false)
	var d := pa.to_dict()
	var pa2 := PaceAdjuster.new()
	pa2.from_dict(d)
	_assert(pa2.rank_offset(25, 1) == pa.rank_offset(25, 1), "round trip preserves offset behavior")

func _assert(condition: bool, label: String) -> void:
	if not condition:
		_fails.append("FAIL: " + label)

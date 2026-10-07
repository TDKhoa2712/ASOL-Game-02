extends SceneTree

const EndlessProgress = preload("res://scripts/endless/endless_progress.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_defaults()
	_test_streak_and_stats()
	_test_dedup_fifo()
	_test_serialization()
	if _fails.is_empty():
		print("ENDLESS_PROGRESS_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_defaults() -> void:
	var p = EndlessProgress.new()
	_assert(p.get_level_num() == 1, "default level is 1")
	_assert(p.get_strategy() == 3, "default strategy is 3")
	_assert(p.current_streak == 0, "default current_streak is 0")
	_assert(p.longest_streak == 0, "default longest_streak is 0")
	_assert(p.total_played == 0, "default total_played is 0")

func _test_streak_and_stats() -> void:
	var p = EndlessProgress.new()
	p.record_win(12.5, 6)
	_assert(p.current_streak == 1, "streak 1 after win")
	_assert(p.longest_streak == 1, "longest 1 after win")
	_assert(p.total_played == 1, "total_played is 1")
	_assert(p.total_won == 1, "total_won is 1")
	_assert(p.get_best_time(6) == 12.5, "best time for size 6 is 12.5")

	p.record_win(10.0, 6)
	_assert(p.current_streak == 2, "streak 2 after 2nd win")
	_assert(p.longest_streak == 2, "longest 2 after 2nd win")
	_assert(p.get_best_time(6) == 10.0, "best time updated to 10.0")

	p.record_loss()
	_assert(p.current_streak == 0, "streak resets to 0 after loss")
	_assert(p.longest_streak == 2, "longest remains 2 after loss")
	_assert(p.total_played == 3, "total_played is 3")
	_assert(p.total_won == 2, "total_won is 2")

func _test_dedup_fifo() -> void:
	var p = EndlessProgress.new()
	for i in range(60):
		p.add_recent_hash("hash_%02d" % i)

	_assert(p.is_hash_recent("hash_59"), "hash_59 is recent")
	_assert(p.is_hash_recent("hash_10"), "hash_10 is recent (within 50)")
	_assert(not p.is_hash_recent("hash_00"), "hash_00 was evicted (> 50)")
	_assert(not p.is_hash_recent("hash_09"), "hash_09 was evicted (> 50)")
	_assert(p.recent_hashes.size() == 50, "recent hashes count capped at 50")

func _test_serialization() -> void:
	var p = EndlessProgress.new()
	p.set_level_num(42)
	p.set_strategy(5)
	p.record_win(15.0, 8)
	p.add_recent_hash("hash_xyz")
	p.main_cursor["idx"] = 7

	var d: Dictionary = p.to_dict()
	var p2 = EndlessProgress.new()
	p2.from_dict(d)

	_assert(p2.get_level_num() == 42, "round-trip level_num")
	_assert(p2.get_strategy() == 5, "round-trip strategy")
	_assert(p2.current_streak == 1, "round-trip streak")
	_assert(p2.is_hash_recent("hash_xyz"), "round-trip hash")
	_assert(p2.main_cursor.get("idx") == 7, "round-trip main_cursor")

func _assert(cond: bool, label: String) -> void:
	if not cond:
		_fails.append("FAIL: " + label)

extends SceneTree

const BankCursor = preload("res://scripts/endless/cursor/bank_cursor.gd")
const MainCursor = preload("res://scripts/endless/cursor/main_cursor.gd")
const SuperHardCursor = preload("res://scripts/endless/cursor/super_hard_cursor.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_bank_cursor_basics()
	_test_main_cursor_advance_sequential()
	_test_main_cursor_advance_injection()
	_test_main_cursor_serialization()
	_test_super_hard_cursor_deterministic()
	if _fails.is_empty():
		print("CURSORS_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_bank_cursor_basics() -> void:
	var c = BankCursor.new()
	c.total_levels = 10
	_assert(c.budget() == 80, "budget is 10 * 8 = 80")
	_assert(c.idx == 0, "initial idx is 0")
	_assert(c.transform_id == 0, "initial transform_id is 0")

func _test_main_cursor_advance_sequential() -> void:
	var c = MainCursor.new()
	c.total_levels = 2
	c._inject_counters["lk_mod"] = {"idx": 0, "since": 0}

	# Advance sequential entry
	c.advance({"_source": &"regular", "_is_injection": false})
	_assert(c.idx == 1, "idx advanced to 1")
	_assert(c.transform_id == 0, "transform_id remains 0")
	_assert(c._inject_counters["lk_mod"]["since"] == 1, "injection since incremented to 1")

	# Advance sequential entry -> rollover
	c.advance({"_source": &"regular", "_is_injection": false})
	_assert(c.idx == 0, "idx wrapped to 0")
	_assert(c.transform_id == 1, "transform_id incremented to 1")
	_assert(c._inject_counters["lk_mod"]["since"] == 2, "injection since incremented to 2")

func _test_main_cursor_advance_injection() -> void:
	var c = MainCursor.new()
	c.total_levels = 10
	c._inject_counters["lk_mod"] = {"idx": 0, "since": 4}

	# Advance injection entry
	c.advance({"_source": &"lk_mod", "_is_injection": true})
	_assert(c.idx == 0, "sequential idx did NOT advance")
	_assert(c._inject_counters["lk_mod"]["idx"] == 1, "injection idx advanced to 1")
	_assert(c._inject_counters["lk_mod"]["since"] == 0, "injection since reset to 0")

func _test_main_cursor_serialization() -> void:
	var c = MainCursor.new()
	c.idx = 5
	c.transform_id = 3
	c._inject_counters["lk_mod"] = {"idx": 2, "since": 1}

	var d: Dictionary = c.serialize()
	var c2 = MainCursor.new()
	c2.restore(d)

	_assert(c2.idx == 5, "restored idx")
	_assert(c2.transform_id == 3, "restored transform_id")
	_assert(c2._inject_counters["lk_mod"]["idx"] == 2, "restored inject idx")
	_assert(c2._inject_counters["lk_mod"]["since"] == 1, "restored inject since")

func _test_super_hard_cursor_deterministic() -> void:
	var c = SuperHardCursor.new()
	c.total_levels = 10
	# min_level = 35, phase = 5, period = 10
	# level 35 -> 0th occurrence
	# level 45 -> 1st occurrence
	# level 55 -> 2nd occurrence
	_assert(c.get_index_for_level(35) == 0, "level 35 is index 0")
	_assert(c.get_index_for_level(45) == 1, "level 45 is index 1")
	_assert(c.get_index_for_level(55) == 2, "level 55 is index 2")

func _assert(cond: bool, label: String) -> void:
	if not cond:
		_fails.append("FAIL: " + label)

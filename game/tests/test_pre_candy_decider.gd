extends SceneTree

const PreCandyDecider = preload("res://scripts/core/pre_candy_decider.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_should_prefill_consecutive_fail()
	_test_should_prefill_hard_next()
	_test_should_prefill_demote()
	_test_choose_prefill_cell()
	_test_apply_prefill_adds_given()
	_test_apply_prefill_does_not_mutate_original()
	if _fails.is_empty():
		print("PRE_CANDY_DECIDER_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_should_prefill_consecutive_fail() -> void:
	_assert(not PreCandyDecider.should_prefill(
		PreCandyDecider.Trigger.CONSECUTIVE_FAIL, 1), "streak 1 = no")
	_assert(PreCandyDecider.should_prefill(
		PreCandyDecider.Trigger.CONSECUTIVE_FAIL, 2), "streak 2 = yes")
	_assert(PreCandyDecider.should_prefill(
		PreCandyDecider.Trigger.CONSECUTIVE_FAIL, 5), "streak 5 = yes")

func _test_should_prefill_hard_next() -> void:
	_assert(PreCandyDecider.should_prefill(
		PreCandyDecider.Trigger.HARD_NEXT, 0), "hard_next always true")

func _test_should_prefill_demote() -> void:
	_assert(PreCandyDecider.should_prefill(
		PreCandyDecider.Trigger.DEMOTE, 0), "demote always true")

func _test_choose_prefill_cell() -> void:
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	var givens: Array = []
	var cell := PreCandyDecider.choose_prefill_cell(4, regions, solution, givens)
	_assert(cell.size() == 2, "returns [row, col]")
	_assert(cell[0] >= 0 and cell[0] < 4, "row in range")
	_assert(int(solution[cell[0]]) == cell[1], "cell is on solution")

func _test_apply_prefill_adds_given() -> void:
	var level := {
		"size": 4,
		"regions": ["AABB", "ABBB", "CCBB", "CCDB"],
		"solution": [1, 3, 0, 2],
		"givens": [],
	}
	var modified := PreCandyDecider.apply_prefill(level)
	_assert(modified["givens"].size() == 1, "one given added")
	var g: Dictionary = modified["givens"][0]
	_assert(g.has("r") and g.has("c"), "given has r and c")

func _test_apply_prefill_does_not_mutate_original() -> void:
	var level := {
		"size": 4,
		"regions": ["AABB", "ABBB", "CCBB", "CCDB"],
		"solution": [1, 3, 0, 2],
		"givens": [],
	}
	var _modified := PreCandyDecider.apply_prefill(level)
	_assert(level["givens"].size() == 0, "original unchanged")

func _assert(condition: bool, msg: String) -> void:
	if not condition:
		_fails.append("FAIL: " + msg)

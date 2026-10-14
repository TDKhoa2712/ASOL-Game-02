extends SceneTree

const TutorialTargets = preload("res://scripts/campaign/tutorial_targets.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_script_levels_are_unique()
	_test_l01_first_region_is_single_cell()
	_test_candy_and_diagonal_targets()
	_test_excluded_by_region()
	_test_region_column_lock()
	if _fails.is_empty():
		print("TUTORIAL_TARGETS_PASS")
		quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _levels() -> Dictionary:
	return TutorialTargets.load_script("res://tests/fixtures/tutorial_inlevel.json").get("levels", {})

func _test_script_levels_are_unique() -> void:
	var levels := _levels()
	_assert(levels.has("L01") and levels.has("L02"), "script has L01 and L02")
	for label in levels:
		var lvl: Dictionary = levels[label].level
		_assert(TutorialTargets.count_solutions(lvl, 2) == 1, label + " has exactly one solution")

func _test_l01_first_region_is_single_cell() -> void:
	var lvl: Dictionary = _levels().L01.level
	var count := 0
	for row in lvl.regions:
		count += str(row).count("B")
	_assert(count == 1, "L01 region B is a single cell")

func _test_candy_and_diagonal_targets() -> void:
	var lvl: Dictionary = _levels().L01.level
	_assert(TutorialTargets.resolve(lvl, {"type": "candy_of_region", "region": "B"}) == [[0, 1]], "candy of B")
	_assert(TutorialTargets.resolve(lvl, {"type": "candy_of_region", "region": "C"}) == [[1, 3]], "candy of C")
	_assert(TutorialTargets.resolve(lvl, {"type": "diagonal_of_region", "region": "B"}) == [[1, 0]], "first diagonal of B")

func _test_excluded_by_region() -> void:
	var lvl: Dictionary = _levels().L01.level
	var cells: Array = TutorialTargets.resolve(lvl, {"type": "excluded_by_region", "region": "B"})
	for expected in [[0, 0], [0, 2], [0, 3], [1, 1], [2, 1], [3, 1], [1, 0], [1, 2]]:
		_assert(cells.has(expected), "B excludes %s" % str(expected))
	_assert(not cells.has([0, 1]), "candy cell itself is not excluded")
	_assert(not cells.has([1, 3]), "C candy cell stays open")
	_assert(cells.size() == 8, "B excludes exactly 8 cells, got %d" % cells.size())

func _test_region_column_lock() -> void:
	var lvl: Dictionary = _levels().L02.level
	var cells: Array = TutorialTargets.resolve(lvl, {"type": "region_column_lock", "region": "A"})
	_assert(cells == [[2, 0], [3, 0]], "A locks column 1 rows 3-4, got %s" % str(cells))

func _assert(condition: bool, label: String) -> void:
	if not condition: _fails.append("FAIL: " + label)

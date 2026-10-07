extends SceneTree

const PuzzleDedup = preload("res://scripts/endless/delivery/puzzle_dedup.gd")
const LevelDeliveryValidator = preload("res://scripts/endless/delivery/level_validator.gd")
const EndlessProgress = preload("res://scripts/endless/endless_progress.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_puzzle_dedup()
	_test_level_validator()
	if _fails.is_empty():
		print("DELIVERY_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _sample_level() -> Dictionary:
	return {
		"size": 4,
		"seed": 1,
		"regions": ["AABB", "ABBB", "CCBB", "CCDB"],
		"solution": [1, 3, 0, 2],
		"givens": [],
		"steps": 4,
		"profile": [4, 0, 0],
		"rating": 4,
		"pidHash": "test1234",
		"logicTrace": []
	}

func _test_puzzle_dedup() -> void:
	var progress = EndlessProgress.new()
	var lvl = _sample_level()

	_assert(not PuzzleDedup.is_duplicate(lvl, progress), "not duplicate initially")
	PuzzleDedup.register(lvl, progress)
	_assert(PuzzleDedup.is_duplicate(lvl, progress), "duplicate after register")

func _test_level_validator() -> void:
	var progress = EndlessProgress.new()
	var lvl = _sample_level()
	lvl["_apply_transform"] = true

	# Valid level delivery with transform 1
	var delivered: Dictionary = LevelDeliveryValidator.prepare_delivery(lvl, 1, progress)
	_assert(not delivered.is_empty(), "level delivered successfully")
	_assert(delivered["regions"].size() == 4, "delivered size 4")
	_assert(PuzzleDedup.is_duplicate(lvl, progress), "registered in progress after delivery")

	# Duplicate rejection
	var dupe: Dictionary = LevelDeliveryValidator.prepare_delivery(lvl, 0, progress)
	_assert(dupe.is_empty(), "duplicate rejected")

func _assert(cond: bool, label: String) -> void:
	if not cond:
		_fails.append("FAIL: " + label)

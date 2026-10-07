extends SceneTree

const BankReader = preload("res://scripts/content/bank_reader.gd")
const PaceReader = preload("res://scripts/content/pace_reader.gd")
const LevelValidator = preload("res://scripts/content/level_validator.gd")
const BoardTransform = preload("res://scripts/content/board_transform.gd")
const RegionPainter = preload("res://scripts/content/region_painter.gd")
const CandyRules = preload("res://scripts/core/candy_rules.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_validate_good_level()
	_test_reject_bad_size()
	_test_reject_bad_solution()
	_test_level_validator_id()
	_test_level_validator_bank_level()
	_test_load_bank_4x4()
	_test_bank_reader_edge_cases()
	_test_pace_1to1()
	_test_pace_reader_edge_cases()
	_test_transform_identity()
	_test_transform_rotate90()
	_test_transform_all_8_unique()
	_test_transform_preserves_rules()
	_test_region_painter_colors()
	_test_lab_distance()
	_test_extended_banks()
	_test_flat_banks()
	if _fails.is_empty():
		print("CONTENT_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_validate_good_level() -> void:
	var result := LevelValidator.check(_sample_bank_level())
	_assert(result["ok"], "valid level passes")

func _test_reject_bad_size() -> void:
	var level := _sample_bank_level()
	level["regions"] = ["AAB"]  # size 3
	var result := LevelValidator.check(level)
	_assert(not result["ok"], "size 3 rejected")

func _test_reject_bad_solution() -> void:
	var level := _sample_bank_level()
	level["solution"] = [1, 1, 0, 2]  # duplicate column
	var result := LevelValidator.check(level)
	_assert(not result["ok"], "duplicate column rejected")

func _test_level_validator_id() -> void:
	_assert(LevelValidator.check_id("L01"), "valid id L01")
	_assert(LevelValidator.check_id("demo-30"), "valid id demo-30")
	_assert(LevelValidator.check_id("LEVEL_4_EASY"), "valid id with underscores")
	_assert(not LevelValidator.check_id(""), "empty id rejected")
	_assert(not LevelValidator.check_id("L 01"), "space in id rejected")
	_assert(not LevelValidator.check_id("L@01"), "special char rejected")

func _test_level_validator_bank_level() -> void:
	var level := _sample_bank_level()
	var res := LevelValidator.check_bank_level(level)
	_assert(res["ok"], "sample bank level passes check_bank_level")

	var bad_level := _sample_bank_level()
	bad_level.erase("seed")
	_assert(not LevelValidator.check_bank_level(bad_level)["ok"], "missing seed rejected")

	var bad_profile := _sample_bank_level()
	bad_profile["profile"] = [1, 2]
	_assert(not LevelValidator.check_bank_level(bad_profile)["ok"], "profile size != 3 rejected")

	var bad_hash := _sample_bank_level()
	bad_hash["pidHash"] = ""
	_assert(not LevelValidator.check_bank_level(bad_hash)["ok"], "empty pidHash rejected")

func _test_load_bank_4x4() -> void:
	var reader := BankReader.new()
	var result := reader.load_bank(4)
	_assert(result["ok"], "bank 4x4 loads")
	_assert(reader.level_count(4, 1) > 0, "rank 1 has levels")
	_assert(reader.total_count(4) > 0, "total levels > 0")
	var level := reader.get_level(4, 1, 0)
	_assert(level.has("regions"), "level has regions")
	_assert(level["regions"][0] is String, "regions are strings")

func _test_bank_reader_edge_cases() -> void:
	var reader := BankReader.new()
	reader.load_bank(4)
	_assert(reader.available_sizes() == [4], "available_sizes has 4")
	_assert(reader.get_level(4, 1, 999).is_empty(), "out of bounds index returns empty dict")
	_assert(reader.get_levels(4, 99).is_empty(), "unknown rank returns empty array")
	_assert(reader.level_count(4, 99) == 0, "unknown rank count is 0")

	var bad_res := reader.load_bank(99)
	_assert(not bad_res["ok"], "nonexistent bank returns error")

	reader.clear_cache()
	_assert(reader.total_count(4) == 0, "clear_cache empties cache")
	_assert(reader.available_sizes().is_empty(), "clear_cache clears available sizes")

func _test_pace_1to1() -> void:
	var bank := BankReader.new()
	bank.load_bank(4)
	var pace := PaceReader.new()
	pace.load_pace(4)
	var errors := pace.validate_against_bank(bank, 4)
	_assert(errors.is_empty(), "pace matches bank: %s" % str(errors))

func _test_pace_reader_edge_cases() -> void:
	var pace := PaceReader.new()
	var res := pace.load_pace(4)
	_assert(res["ok"], "pace 4 loads")
	var p0 := pace.get_pace(4, 1, 0)
	_assert(p0.has("rSeq") and p0.has("hintCosts"), "pace entry has rSeq and hintCosts")
	_assert(pace.get_pace(4, 1, 999).is_empty(), "out of bounds pace returns empty")

	var bad_load := pace.load_pace(99)
	_assert(not bad_load["ok"], "nonexistent pace returns error")

	pace.clear_cache()
	_assert(pace.get_pace(4, 1, 0).is_empty(), "clear_cache clears pace cache")

func _test_transform_identity() -> void:
	var level := _sample_bank_level()
	var t := BoardTransform.apply(level, BoardTransform.Transform.IDENTITY)
	_assert(t["regions"] == level["regions"], "identity preserves regions")
	_assert(t["solution"] == level["solution"], "identity preserves solution")

func _test_transform_rotate90() -> void:
	var regions := ["AB", "CD"]
	var rotated := BoardTransform.transform_regions(regions, 2, BoardTransform.Transform.ROTATE_90)
	_assert(rotated[0] == "CA", "rotate90 row0")
	_assert(rotated[1] == "DB", "rotate90 row1")

func _test_transform_all_8_unique() -> void:
	var level := _sample_bank_level()
	var seen: Array[String] = []
	for t in 8:
		var transformed := BoardTransform.apply(level, t)
		var key := "".join(transformed["regions"])
		_assert(key not in seen, "transform %d unique" % t)
		seen.append(key)

func _test_transform_preserves_rules() -> void:
	var level := _sample_bank_level()
	level["size"] = 4
	for t in 8:
		var transformed := BoardTransform.apply(level, t)
		_assert(CandyRules.verify_level(transformed), "transform %d maintains valid puzzle rules" % t)

func _test_region_painter_colors() -> void:
	var zones := ["AABB", "ABBB", "CCBB", "CCDB"]
	var palette: Array[Color] = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.CYAN]
	var colors := RegionPainter.assign_colors(4, zones, palette)
	_assert(colors.size() == 4, "4 zones get colors")
	_assert(colors.get("A") != colors.get("B"), "A and B different")

func _test_lab_distance() -> void:
	var d := RegionPainter.lab_distance(Color.RED, Color.BLUE)
	_assert(d > 50.0, "red-blue far in LAB")
	var d2 := RegionPainter.lab_distance(Color.RED, Color.RED)
	_assert(d2 < 0.01, "same color zero distance")

func _test_extended_banks() -> void:
	var reader := BankReader.new()
	var lkstyle_7_2 := reader.get_lkstyle_levels(7, 2)
	_assert(not lkstyle_7_2.is_empty(), "lkstyle 7x7 rank 2 has levels")

	var gc_6_1 := reader.get_gc_levels(6, 1)
	_assert(not gc_6_1.is_empty(), "gc 6x6 rank 1 has levels")

	var onefish_8_3 := reader.get_onefish_levels(8, 3)
	_assert(not onefish_8_3.is_empty(), "onefish 8x8 rank 3 has levels")


func _test_flat_banks() -> void:
	var reader := BankReader.new()

	var sp_0 := reader.get_sp_level(0)
	_assert(not sp_0.is_empty(), "sp level 0 exists")
	_assert(sp_0.has("regions"), "sp level 0 has regions")

	var lk_0 := reader.get_lk_level(0)
	_assert(not lk_0.is_empty(), "lk level 0 exists")

	var lk_mod_8_1 := reader.get_lk_mod_levels(8, 1, false)
	_assert(not lk_mod_8_1.is_empty(), "lk_mod 8x8 rank 1 relaxed has levels")

	var sp_tt := reader.get_sp_tt_levels(1, 8, 2)
	# category 1-6
	_assert(sp_tt is Array, "sp_tt returns array")

	var single_reg := reader.get_single_region_levels(8, 3)
	_assert(not single_reg.is_empty(), "single_region 8x8 rank 3 has levels")


	var super_hard := reader.get_super_hard_levels()
	_assert(super_hard.size() == 275, "super_hard has 275 levels")


func _sample_bank_level() -> Dictionary:

	return {
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

func _assert(cond: bool, label: String) -> void:
	if not cond:
		_fails.append("FAIL: " + label)

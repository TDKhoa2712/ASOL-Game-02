extends SceneTree

const LevelSelector = preload("res://scripts/endless/level_selector.gd")
const EndlessConfig = preload("res://scripts/endless/endless_config.gd")
const EndlessProgress = preload("res://scripts/endless/endless_progress.gd")
const BankReader = preload("res://scripts/content/bank_reader.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_100_consecutive_selects()
	_test_feature_toggles()
	_test_dda_win_loss_streaks()

	if _fails.is_empty():
		print("ENDLESS_QA_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_100_consecutive_selects() -> void:
	var bank = BankReader.new()
	var cfg = EndlessConfig.default_config()
	var prog = EndlessProgress.new()
	var selector = LevelSelector.new(bank, cfg, prog)

	var seen_signatures: Dictionary = {}
	var total_tested := 100

	for level_num in range(1, total_tested + 1):
		prog.set_level_num(level_num)
		var lvl: Dictionary = selector.select_next_level()
		_assert(not lvl.is_empty(), "Level %d is not empty" % level_num)
		_assert(lvl.has("solution") and lvl.has("regions") and lvl.has("size"), "Level %d has valid schema" % level_num)

		var sz: int = int(lvl.get("size", 0))
		_assert(sz >= 4 and sz <= 12, "Level %d size %d in range 4-12" % [level_num, sz])

		# Check that solution length matches size
		var sol: Array = lvl.get("solution", [])
		_assert(sol.size() == sz, "Level %d solution size matches board size" % level_num)

		# Check regions array length matches size
		var regs: Array = lvl.get("regions", [])
		_assert(regs.size() == sz, "Level %d regions count matches board size" % level_num)

		# Verify that milestone levels (10, 20, 30...) return SP content
		if level_num % 10 == 0:
			_assert(lvl.get("_source") == &"sp", "Level %d is milestone SP" % level_num)

		# Verify that super_hard levels (35, 45, 55...) return super_hard content
		if level_num >= 35 and level_num % 10 == 5:
			_assert(lvl.get("_source") == &"super_hard", "Level %d is super_hard" % level_num)

		# Record signature
		var sig: String = "%d_%s_%s" % [sz, str(regs), str(sol)]
		seen_signatures[sig] = true

	_assert(seen_signatures.size() >= 80, "At least 80 unique levels among 100 selects (dedup working)")

func _test_feature_toggles() -> void:
	var bank = BankReader.new()

	# 1. Milestone toggle disabled
	var cfg_no_ms = EndlessConfig.default_config()
	cfg_no_ms.milestone_enabled = false
	var prog_ms = EndlessProgress.new()
	prog_ms.set_level_num(10)
	var selector_ms = LevelSelector.new(bank, cfg_no_ms, prog_ms)
	var lvl_ms: Dictionary = selector_ms.select_next_level()
	_assert(not lvl_ms.is_empty(), "level 10 generated with milestone disabled")
	_assert(lvl_ms.get("_source") != &"sp", "level 10 is NOT SP when milestone disabled")

	# 2. Super hard toggle disabled
	var cfg_no_sh = EndlessConfig.default_config()
	cfg_no_sh.super_hard_enabled = false
	var prog_sh = EndlessProgress.new()
	prog_sh.set_level_num(35)
	var selector_sh = LevelSelector.new(bank, cfg_no_sh, prog_sh)
	var lvl_sh: Dictionary = selector_sh.select_next_level()
	_assert(not lvl_sh.is_empty(), "level 35 generated with super_hard disabled")
	_assert(lvl_sh.get("_source") != &"super_hard", "level 35 is NOT super_hard when disabled")

	# 3. Single region disabled
	var cfg_no_sr = EndlessConfig.default_config()
	cfg_no_sr.single_region_supp_enabled = false
	var prog_sr = EndlessProgress.new()
	var selector_sr = LevelSelector.new(bank, cfg_no_sr, prog_sr)
	var lvl_sr: Dictionary = selector_sr.select_next_level()
	_assert(not lvl_sr.is_empty(), "level generated with single_region disabled")

func _test_dda_win_loss_streaks() -> void:
	var bank = BankReader.new()
	var cfg = EndlessConfig.default_config()
	var prog = EndlessProgress.new()
	var selector = LevelSelector.new(bank, cfg, prog)

	prog.set_strategy(3)
	_assert(prog.get_strategy() == 3, "initial strategy is 3")

	# Win streak of 5 clean wins (no hints, under par) -> strategy should promote up to max (7)
	for i in range(5):
		selector.on_level_complete({
			"won": true,
			"hints_used": 0,
			"time": 20.0,
			"par_time": 60.0,
			"size": 6
		})

	_assert(prog.get_strategy() == 7, "strategy promoted to 7 after win streak")
	_assert(prog.current_streak == 5, "current streak is 5")

	# Loss streak of 3 -> strategy should demote down (7 -> 6 -> 5 -> 4)
	for i in range(3):
		selector.on_level_complete({
			"won": false,
			"hints_used": 0,
			"time": 80.0,
			"size": 6
		})

	_assert(prog.get_strategy() == 4, "strategy demoted to 4 after 3 losses")
	_assert(prog.current_streak == 0, "streak reset to 0 after loss")

func _assert(cond: bool, label: String) -> void:
	if not cond:
		_fails.append("FAIL: " + label)

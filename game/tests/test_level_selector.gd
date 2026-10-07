extends SceneTree

const LevelSelector = preload("res://scripts/endless/level_selector.gd")
const EndlessConfig = preload("res://scripts/endless/endless_config.gd")
const EndlessProgress = preload("res://scripts/endless/endless_progress.gd")
const BankReader = preload("res://scripts/content/bank_reader.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_selector_tutorial_level()
	_test_selector_milestone_level()
	_test_selector_super_hard_level()
	_test_selector_consecutive_selects()
	if _fails.is_empty():
		print("LEVEL_SELECTOR_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_selector_tutorial_level() -> void:
	var bank = BankReader.new()
	var cfg = EndlessConfig.default_config()
	var prog = EndlessProgress.new()
	var selector = LevelSelector.new(bank, cfg, prog)

	var level: Dictionary = selector.select_next_level()
	_assert(not level.is_empty(), "level 1 returned")
	_assert(int(level.get("size", 0)) == 4, "level 1 size is 4")
	_assert(level.has("regions"), "level has regions")
	_assert(level.has("solution"), "level has solution")

func _test_selector_milestone_level() -> void:
	var bank = BankReader.new()
	var cfg = EndlessConfig.default_config()
	var prog = EndlessProgress.new()
	prog.set_level_num(10)
	var selector = LevelSelector.new(bank, cfg, prog)

	var level: Dictionary = selector.select_next_level()
	_assert(not level.is_empty(), "level 10 returned")
	_assert(level.get("_source") == &"sp", "level 10 source is sp milestone")

func _test_selector_super_hard_level() -> void:
	var bank = BankReader.new()
	var cfg = EndlessConfig.default_config()
	var prog = EndlessProgress.new()
	prog.set_level_num(35)
	var selector = LevelSelector.new(bank, cfg, prog)

	var level: Dictionary = selector.select_next_level()
	_assert(not level.is_empty(), "level 35 returned")
	_assert(level.get("_source") == &"super_hard", "level 35 is super_hard")
	_assert(int(level.get("size", 0)) == 11, "super_hard size is 11")

func _test_selector_consecutive_selects() -> void:
	var bank = BankReader.new()
	var cfg = EndlessConfig.default_config()
	var prog = EndlessProgress.new()
	var selector = LevelSelector.new(bank, cfg, prog)

	for i in range(1, 25):
		prog.set_level_num(i)
		var lvl: Dictionary = selector.select_next_level()
		_assert(not lvl.is_empty(), "level %d not empty" % i)
		_assert(lvl.has("solution"), "level %d has solution" % i)

func _assert(cond: bool, label: String) -> void:
	if not cond:
		_fails.append("FAIL: " + label)

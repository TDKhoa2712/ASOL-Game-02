extends SceneTree

const EndlessConfig = preload("res://scripts/endless/endless_config.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_default_config()
	_test_load_config_file()
	_test_pool_enabled_and_inject()
	if _fails.is_empty():
		print("ENDLESS_CONFIG_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_default_config() -> void:
	var cfg = EndlessConfig.default_config()
	_assert(cfg.milestone_enabled, "default milestone_enabled is true")
	_assert(cfg.super_hard_enabled, "default super_hard_enabled is true")
	_assert(cfg.super_hard_min_level == 35, "default super_hard_min_level is 35")
	_assert(cfg.super_hard_phase == 5, "default super_hard_phase is 5")
	_assert(cfg.super_hard_period == 10, "default super_hard_period is 10")
	_assert(cfg.single_region_supp_enabled, "default single_region_supp_enabled is true")
	_assert(not cfg.sp_tt_enabled, "default sp_tt_enabled is false")
	_assert(not cfg.onefish_enabled, "default onefish_enabled is false")
	_assert(cfg.initial_strategy == 3, "default initial_strategy is 3")

func _test_load_config_file() -> void:
	var cfg = EndlessConfig.load_from_file("res://data/endless_config.json")
	_assert(cfg.milestone_enabled, "loaded milestone_enabled is true")
	_assert(cfg.super_hard_enabled, "loaded super_hard_enabled is true")
	_assert(cfg.super_hard_min_level == 35, "loaded super_hard_min_level is 35")
	_assert(cfg.is_pool_enabled(&"regular"), "regular pool is enabled")
	_assert(cfg.is_pool_enabled(&"lk_modified"), "lk_modified pool is enabled")
	_assert(cfg.get_inject_every(&"lk_modified") == 4, "lk_modified inject_every is 4")

func _test_pool_enabled_and_inject() -> void:
	var cfg = EndlessConfig.default_config()
	_assert(cfg.is_pool_enabled(&"regular"), "default regular is enabled")
	_assert(not cfg.is_pool_enabled(&"non_existent"), "non_existent pool is disabled")
	_assert(cfg.get_inject_every(&"regular") == 0, "regular inject_every is 0")

func _assert(cond: bool, label: String) -> void:
	if not cond:
		_fails.append("FAIL: " + label)

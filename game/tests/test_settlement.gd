extends SceneTree

const SettlementHandler = preload("res://scripts/endless/settlement/settlement_handler.gd")
const EndlessProgress = preload("res://scripts/endless/endless_progress.gd")
const EndlessConfig = preload("res://scripts/endless/endless_config.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_settlement_win_promotion()
	_test_settlement_win_with_hints_no_promotion()
	_test_settlement_loss_demotion()
	if _fails.is_empty():
		print("SETTLEMENT_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_settlement_win_promotion() -> void:
	var handler = SettlementHandler.new()
	var prog = EndlessProgress.new()
	var cfg = EndlessConfig.default_config()

	prog.set_strategy(3)
	var res = {
		"won": true,
		"hints_used": 0,
		"time": 25.0,
		"par_time": 60.0,
		"size": 6,
	}
	handler.on_level_complete(res, prog, cfg)
	_assert(prog.get_strategy() == 4, "promoted 3 -> 4 on clean win")
	_assert(prog.get_level_num() == 2, "level advanced to 2")
	_assert(prog.current_streak == 1, "streak is 1")

func _test_settlement_win_with_hints_no_promotion() -> void:
	var handler = SettlementHandler.new()
	var prog = EndlessProgress.new()
	var cfg = EndlessConfig.default_config()

	prog.set_strategy(3)
	var res = {
		"won": true,
		"hints_used": 2, # hints used -> freeze difficulty
		"time": 20.0,
		"par_time": 60.0,
		"size": 6,
	}
	handler.on_level_complete(res, prog, cfg)
	_assert(prog.get_strategy() == 3, "strategy frozen at 3 due to hints")
	_assert(prog.get_level_num() == 2, "level advanced to 2")

func _test_settlement_loss_demotion() -> void:
	var handler = SettlementHandler.new()
	var prog = EndlessProgress.new()
	var cfg = EndlessConfig.default_config()

	prog.set_strategy(3)
	var res = {
		"won": false,
		"hints_used": 0,
		"time": 100.0,
		"par_time": 60.0,
		"size": 6,
	}
	handler.on_level_complete(res, prog, cfg)
	_assert(prog.get_strategy() == 2, "demoted 3 -> 2 on loss")
	_assert(prog.get_level_num() == 2, "level advanced to 2")
	_assert(prog.current_streak == 0, "streak reset to 0")

func _assert(cond: bool, label: String) -> void:
	if not cond:
		_fails.append("FAIL: " + label)

extends SceneTree

const SelectContext = preload("res://scripts/endless/context/select_context.gd")
const SizeSchedule = preload("res://scripts/endless/context/size_schedule.gd")
const StrategyModifier = preload("res://scripts/endless/context/strategy_modifier.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_select_context()
	_test_size_schedule()
	_test_strategy_modifier()
	if _fails.is_empty():
		print("CONTEXT_MODULES_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_select_context() -> void:
	var ctx = SelectContext.new()
	_assert(ctx.level_num == 1, "default level_num is 1")
	_assert(ctx.size == 4, "default size is 4")
	_assert(ctx.rank == 1, "default rank is 1")
	_assert(ctx.tier == "N", "default tier is N")
	_assert(not ctx.is_hard, "default is_hard is false")
	_assert(not ctx.is_super_hard, "default is_super_hard is false")
	_assert(ctx.relaxation_phase == 0, "default relaxation_phase is 0")

func _test_size_schedule() -> void:
	_assert(SizeSchedule.get_size(0) == 0, "size for 0 is 0")
	_assert(SizeSchedule.get_size(1) == 4, "level 1 is 4")
	_assert(SizeSchedule.get_size(4) == 5, "level 4 is 5")
	_assert(SizeSchedule.get_size(7) == 6, "level 7 is 6")
	_assert(SizeSchedule.get_size(11) == 7, "level 11 is 7")
	_assert(SizeSchedule.get_size(20) == 12, "level 20 is 12")
	_assert(SizeSchedule.get_size(21) == 8, "level 21 is 8")
	_assert(SizeSchedule.get_size(22) == 10, "level 22 is 10")
	_assert(SizeSchedule.get_size(23) == 11, "level 23 is 11")
	_assert(SizeSchedule.get_size(26) == 12, "level 26 is 12")
	_assert(SizeSchedule.get_size(31) == 8, "level 31 is 8 (cycle wrap)")

func _test_strategy_modifier() -> void:
	_assert(StrategyModifier.strategy_to_rank(1) == 1, "s1 -> r1")
	_assert(StrategyModifier.strategy_to_rank(3) == 3, "s3 -> r3")
	_assert(StrategyModifier.strategy_to_rank(5) == 4, "s5 -> r4")
	_assert(StrategyModifier.strategy_to_rank(6) == 5, "s6 -> r5")
	_assert(StrategyModifier.strategy_to_rank(7) == 5, "s7 -> r5")

	_assert(StrategyModifier.strategy_to_tier(3) == "N", "s3 -> tier N")
	_assert(StrategyModifier.strategy_to_tier(5) == "H", "s5 -> tier H")
	_assert(StrategyModifier.strategy_to_tier(6) == "N", "s6 -> tier N")
	_assert(StrategyModifier.strategy_to_tier(7) == "H", "s7 -> tier H")

	_assert(StrategyModifier.rank_tier_to_strategy(4, "H") == 5, "r4 H -> s5")
	_assert(StrategyModifier.rank_tier_to_strategy(5, "N") == 6, "r5 N -> s6")
	_assert(StrategyModifier.rank_tier_to_strategy(5, "H") == 7, "r5 H -> s7")

func _assert(cond: bool, label: String) -> void:
	if not cond:
		_fails.append("FAIL: " + label)

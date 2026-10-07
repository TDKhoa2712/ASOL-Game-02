# control_strategy.gd
class_name ControlStrategy
extends "res://scripts/endless/strategy/selection_strategy.gd"

const SizeScheduleClass = preload("res://scripts/endless/context/size_schedule.gd")
const StrategyModifierClass = preload("res://scripts/endless/context/strategy_modifier.gd")
const SpecialProviderClass = preload("res://scripts/endless/provider/special_provider.gd")
const SuperHardProviderClass = preload("res://scripts/endless/provider/super_hard_provider.gd")
const SingleRegionProviderClass = preload("res://scripts/endless/provider/single_region_provider.gd")
const PoolBuilderClass = preload("res://scripts/endless/pool/pool_builder.gd")
const PoolPickerClass = preload("res://scripts/endless/pool/pool_picker.gd")
const MainCursorClass = preload("res://scripts/endless/cursor/main_cursor.gd")
const LevelDeliveryValidatorClass = preload("res://scripts/endless/delivery/level_validator.gd")

var _config: RefCounted
var _special: RefCounted
var _super_hard: RefCounted
var _single_region: RefCounted
var _pool_builder: RefCounted
var _main_cursor: RefCounted


func _init(config: RefCounted = null) -> void:
	_config = config
	_special = SpecialProviderClass.new(_config)
	_super_hard = SuperHardProviderClass.new(_config)
	_single_region = SingleRegionProviderClass.new(_config)
	_pool_builder = PoolBuilderClass.new()
	_main_cursor = MainCursorClass.new()


func select(request: Dictionary) -> Dictionary:
	var bank: RefCounted = request.get("bank")
	var config: RefCounted = request.get("config", _config)
	var progress: RefCounted = request.get("progress")
	var level_num: int = int(request.get("level_num", progress.get_level_num() if progress != null else 1))

	# Tier 1: Super Hard
	if _super_hard.is_super_hard(level_num):
		var sh_entry: Dictionary = _super_hard.get_entry(level_num, bank)
		if not sh_entry.is_empty():
			var t_id: int = int(sh_entry.get("_transform_id", 0))
			var delivered: Dictionary = LevelDeliveryValidatorClass.prepare_delivery(sh_entry, t_id, progress)
			if not delivered.is_empty():
				return delivered
			return sh_entry

	# Tier 1: Milestone
	if _special.is_available(level_num, false):
		var ms_entry: Dictionary = _special.get_entry(level_num, bank)
		if not ms_entry.is_empty():
			var delivered_ms: Dictionary = LevelDeliveryValidatorClass.prepare_delivery(ms_entry, 0, progress)
			if not delivered_ms.is_empty():
				return delivered_ms
			return ms_entry

	# Normal Flow: Size & Strategy
	var size: int = SizeScheduleClass.get_size(level_num)
	var strategy_val: int = progress.get_strategy() if progress != null else 3
	var rank: int = StrategyModifierClass.strategy_to_rank(strategy_val)
	var tier: String = StrategyModifierClass.strategy_to_tier(strategy_val)

	# Main Pool attempt
	var res: Dictionary = _try_pick_pool(bank, config, progress, size, rank, tier)
	if not res.is_empty():
		return res

	# 7-Phase Relaxation
	# Phase 1: drop tier
	if not tier.is_empty():
		res = _try_pick_pool(bank, config, progress, size, rank, "")
		if not res.is_empty():
			return res

	# Phase 2: lower ranks
	for r in range(rank - 1, 0, -1):
		res = _try_pick_pool(bank, config, progress, size, r, "")
		if not res.is_empty():
			return res

	# Phase 3: higher ranks
	for r in range(rank + 1, 6):
		res = _try_pick_pool(bank, config, progress, size, r, "")
		if not res.is_empty():
			return res

	# Phase 4: adjacent sizes
	for adj_sz in [size - 1, size + 1]:
		if adj_sz >= 4 and adj_sz <= 12:
			res = _try_pick_pool(bank, config, progress, adj_sz, rank, "")
			if not res.is_empty():
				return res

	# Phase 5: DDA SingleRegion support
	if _single_region.is_available():
		var sr_entry: Dictionary = _single_region.get_entry(size, rank, bank, progress)
		if not sr_entry.is_empty():
			var t_id: int = int(sr_entry.get("_transform_id", 0))
			var del: Dictionary = LevelDeliveryValidatorClass.prepare_delivery(sr_entry, t_id, progress)
			if not del.is_empty():
				return del

	# Phase 6: Fallback to regular bank size
	for fb_size in [size, 4, 5, 6]:
		bank.load_bank(fb_size)
		for r in range(1, 6):
			var lvs: Array = bank.get_levels(fb_size, r)
			if not lvs.is_empty():
				var raw: Dictionary = (lvs[0] as Dictionary).duplicate(true)
				raw["_source"] = &"fallback"
				var del_fb: Dictionary = LevelDeliveryValidatorClass.prepare_delivery(raw, 0, progress)
				if not del_fb.is_empty():
					return del_fb
				return raw

	return {}


func _try_pick_pool(bank: RefCounted, config: RefCounted, progress: RefCounted, size: int, rank: int, tier: String) -> Dictionary:
	var sources: Array = _pool_builder.build(bank, config, size, rank, tier)
	if sources.is_empty():
		return {}

	var total_levels: int = 0
	for s in sources:
		total_levels += s.levels.size()

	if total_levels == 0:
		return {}

	_main_cursor.total_levels = total_levels
	if progress != null:
		_main_cursor.restore(progress.main_cursor)

	for _attempt in range(5):
		var pos_info: Dictionary = _main_cursor.pos()
		var candidate: Dictionary = PoolPickerClass.pick_at(sources, pos_info)
		if candidate.is_empty():
			break
		var t_id: int = _main_cursor.transform_id
		var delivered: Dictionary = LevelDeliveryValidatorClass.prepare_delivery(candidate, t_id, progress)
		_main_cursor.advance(candidate)
		if progress != null:
			progress.main_cursor = _main_cursor.serialize()
		if not delivered.is_empty():
			return delivered

	return {}

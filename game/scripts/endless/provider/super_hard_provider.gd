# super_hard_provider.gd
class_name SuperHardProvider
extends RefCounted

const SuperHardCursorClass = preload("res://scripts/endless/cursor/super_hard_cursor.gd")

var _config: RefCounted
var _cursor: RefCounted


func _init(config: RefCounted = null) -> void:
	_config = config
	_cursor = SuperHardCursorClass.new()


func is_super_hard(level_num: int) -> bool:
	if _config == null or not _config.super_hard_enabled:
		return false
	var min_lvl: int = _config.super_hard_min_level
	var period: int = _config.super_hard_period
	var phase: int = _config.super_hard_phase
	return level_num >= min_lvl and (level_num % period) == phase


func get_entry(level_num: int, bank: RefCounted) -> Dictionary:
	var levels: Array = bank.get_super_hard_levels()
	if levels.is_empty():
		return {}

	_cursor.total_levels = levels.size()
	var min_lvl: int = _config.super_hard_min_level if _config != null else 35
	var period: int = _config.super_hard_period if _config != null else 10
	var phase: int = _config.super_hard_phase if _config != null else 5

	var pos_info: Dictionary = _cursor.pos_for_level(level_num, min_lvl, period, phase)
	var idx: int = int(pos_info.get("idx", 0))
	var t_id: int = int(pos_info.get("transform_id", 0))

	var raw: Dictionary = levels[idx]
	var out: Dictionary = raw.duplicate(true)
	out["_source"] = &"super_hard"
	out["_apply_transform"] = true
	out["_transform_id"] = t_id
	out["_is_injection"] = false
	return out

# sp_tt_provider.gd
class_name SpTtProvider
extends RefCounted

var _config: RefCounted


func _init(config: RefCounted = null) -> void:
	_config = config


func is_available() -> bool:
	if _config == null:
		return false
	return _config.sp_tt_enabled


func get_entry(size: int, rank: int, bank: RefCounted, progress: RefCounted) -> Dictionary:
	var cursor_state: Dictionary = progress.sp_tt_cursor
	var cat: int = int(cursor_state.get("cat", 1))

	var levels: Array = bank.get_sp_tt_levels(cat, size, rank)

	# advance category 1..6
	cursor_state["cat"] = (cat % 6) + 1

	if levels.is_empty():
		return {}

	var idx: int = int(cursor_state.get("idx_%d" % cat, 0))
	var chosen_idx := idx % levels.size()
	cursor_state["idx_%d" % cat] = idx + 1

	var raw: Dictionary = levels[chosen_idx]
	var out: Dictionary = raw.duplicate(true)
	out["_source"] = &"sp_tt"
	out["_apply_transform"] = false
	out["_is_injection"] = false
	return out

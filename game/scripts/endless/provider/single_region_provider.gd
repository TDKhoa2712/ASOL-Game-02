# single_region_provider.gd
class_name SingleRegionProvider
extends RefCounted

var _config: RefCounted


func _init(config: RefCounted = null) -> void:
	_config = config


func is_available() -> bool:
	if _config == null:
		return true
	return _config.single_region_supp_enabled


func get_entry(size: int, rank: int, bank: RefCounted, progress: RefCounted) -> Dictionary:
	var levels: Array = bank.get_single_region_levels(size, rank)
	if levels.is_empty():
		# Fallback to default available single region size/rank (e.g. 8x8 rank 3)
		levels = bank.get_single_region_levels(8, 3)
	if levels.is_empty():
		return {}

	var cursor_state: Dictionary = progress.single_region_cursor
	var idx: int = int(cursor_state.get("idx", 0))
	var t_id: int = int(cursor_state.get("transform_id", 0))

	var chosen_idx := idx % levels.size()
	var raw: Dictionary = levels[chosen_idx]

	# advance cursor in progress
	idx += 1
	if idx >= levels.size():
		idx = 0
		t_id = (t_id + 1) % 8
	cursor_state["idx"] = idx
	cursor_state["transform_id"] = t_id

	var out: Dictionary = raw.duplicate(true)
	out["_source"] = &"single_region"
	out["_apply_transform"] = true
	out["_transform_id"] = t_id
	out["_is_injection"] = false
	return out

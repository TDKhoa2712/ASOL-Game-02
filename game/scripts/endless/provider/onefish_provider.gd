# onefish_provider.gd
class_name OneFishProvider
extends RefCounted

var _config: RefCounted


func _init(config: RefCounted = null) -> void:
	_config = config


func is_available() -> bool:
	if _config == null:
		return false
	return _config.onefish_enabled


func get_entry(size: int, rank: int, bank: RefCounted, progress: RefCounted) -> Dictionary:
	var levels: Array = bank.get_onefish_levels(size, rank)
	if levels.is_empty():
		return {}

	var cursor_state: Dictionary = progress.onefish_cursor
	var idx: int = int(cursor_state.get("idx", 0))
	var t_id: int = int(cursor_state.get("transform_id", 0))

	var chosen_idx := idx % levels.size()
	idx += 1
	if idx >= levels.size():
		idx = 0
		t_id = (t_id + 1) % 8
	cursor_state["idx"] = idx
	cursor_state["transform_id"] = t_id

	var raw: Dictionary = levels[chosen_idx]
	var out: Dictionary = raw.duplicate(true)
	out["_source"] = &"onefish"
	out["_apply_transform"] = true
	out["_transform_id"] = t_id
	out["_is_injection"] = false
	return out

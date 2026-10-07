# main_cursor.gd
class_name MainCursor
extends "res://scripts/endless/cursor/bank_cursor.gd"


var _inject_counters: Dictionary = {} # source_id (String) -> {"idx": int, "since": int}


func pos() -> Dictionary:
	return {
		"main_idx": idx,
		"transform_id": transform_id,
		"inject_counters": _inject_counters,
	}


func advance(entry: Dictionary) -> void:
	var is_inj: bool = bool(entry.get("_is_injection", false))
	if is_inj:
		var src_id: String = str(entry.get("_source", ""))
		if not _inject_counters.has(src_id):
			_inject_counters[src_id] = {"idx": 0, "since": 0}
		_inject_counters[src_id]["idx"] = int(_inject_counters[src_id]["idx"]) + 1
		_inject_counters[src_id]["since"] = 0
	else:
		idx += 1
		if total_levels > 0 and idx >= total_levels:
			idx = 0
			transform_id = (transform_id + 1) % TRANSFORM_COUNT
		for src_id in _inject_counters.keys():
			_inject_counters[src_id]["since"] = int(_inject_counters[src_id]["since"]) + 1


func serialize() -> Dictionary:
	var d := super.serialize()
	d["inject_counters"] = _inject_counters.duplicate(true)
	return d


func restore(data: Dictionary) -> void:
	super.restore(data)
	_inject_counters = data.get("inject_counters", {}).duplicate(true)

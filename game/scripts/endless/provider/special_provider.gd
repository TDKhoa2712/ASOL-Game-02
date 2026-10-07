# special_provider.gd
class_name SpecialProvider
extends RefCounted

const MILESTONES: Dictionary = {
	10: {"source": &"sp", "index": 0},
	20: {"source": &"sp", "index": 1},
	30: {"source": &"sp", "index": 2},
	40: {"source": &"sp", "index": 3},
	50: {"source": &"sp", "index": 4},
	60: {"source": &"sp", "index": 5},
	70: {"source": &"sp", "index": 6},
	80: {"source": &"sp", "index": 7},
	90: {"source": &"sp", "index": 8},
	100: {"source": &"sp", "index": 9},
	123: {"source": &"sp", "index": 10},
	456: {"source": &"sp", "index": 11},
	200: {"source": &"lk", "index": 0},
	250: {"source": &"lk", "index": 1},
	314: {"source": &"lk", "index": 2},
}

var _config: RefCounted


func _init(config: RefCounted = null) -> void:
	_config = config


func is_available(level_num: int, is_super_hard: bool = false) -> bool:
	if _config != null and not _config.milestone_enabled:
		return false
	if is_super_hard:
		return false
	return MILESTONES.has(level_num)


func get_entry(level_num: int, bank: RefCounted) -> Dictionary:
	var m: Dictionary = MILESTONES.get(level_num, {})
	if m.is_empty():
		return {}

	var src: StringName = m.get("source", &"sp")
	var idx: int = int(m.get("index", 0))
	var level_raw: Dictionary = {}

	if src == &"sp":
		level_raw = bank.get_sp_level(idx)
	elif src == &"lk":
		level_raw = bank.get_lk_level(idx)

	if level_raw.is_empty():
		return {}

	var out: Dictionary = level_raw.duplicate(true)
	out["_source"] = src
	out["_apply_transform"] = false
	out["_is_injection"] = false
	return out

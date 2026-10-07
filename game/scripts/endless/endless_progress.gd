# endless_progress.gd
class_name EndlessProgress
extends RefCounted

const MAX_RECENT_HASHES: int = 50

var _level_num: int = 1
var _strategy: int = 3

var current_streak: int = 0
var longest_streak: int = 0
var total_played: int = 0
var total_won: int = 0
var best_by_size: Dictionary = {} # size (int/str) -> best_time (float)

var main_cursor: Dictionary = {}
var super_hard_cursor: Dictionary = {}
var single_region_cursor: Dictionary = {}
var sp_tt_cursor: Dictionary = {}
var onefish_cursor: Dictionary = {}

var recent_hashes: Array = []


func get_level_num() -> int:
	return _level_num


func set_level_num(v: int) -> void:
	_level_num = maxi(1, v)


func advance_level() -> void:
	_level_num += 1


func get_strategy() -> int:
	return _strategy


func set_strategy(v: int) -> void:
	_strategy = clampi(v, 1, 7)


func record_win(time_spent: float, size: int) -> void:
	total_played += 1
	total_won += 1
	current_streak += 1
	longest_streak = maxi(longest_streak, current_streak)

	var sz_key := str(size)
	if not best_by_size.has(sz_key) or time_spent < float(best_by_size[sz_key]):
		best_by_size[sz_key] = time_spent


func record_loss() -> void:
	total_played += 1
	current_streak = 0


func get_best_time(size: int) -> float:
	var sz_key := str(size)
	if best_by_size.has(sz_key):
		return float(best_by_size[sz_key])
	return -1.0


func add_recent_hash(h: String) -> void:
	if h.is_empty():
		return
	recent_hashes.append(h)
	while recent_hashes.size() > MAX_RECENT_HASHES:
		recent_hashes.pop_front()


func is_hash_recent(h: String) -> bool:
	return recent_hashes.has(h)


func to_dict() -> Dictionary:
	return {
		"level_num": _level_num,
		"strategy": _strategy,
		"current_streak": current_streak,
		"longest_streak": longest_streak,
		"total_played": total_played,
		"total_won": total_won,
		"best_by_size": best_by_size.duplicate(true),
		"main_cursor": main_cursor.duplicate(true),
		"super_hard_cursor": super_hard_cursor.duplicate(true),
		"single_region_cursor": single_region_cursor.duplicate(true),
		"sp_tt_cursor": sp_tt_cursor.duplicate(true),
		"onefish_cursor": onefish_cursor.duplicate(true),
		"recent_hashes": recent_hashes.duplicate(),
	}


func from_dict(d: Dictionary) -> void:
	_level_num = int(d.get("level_num", 1))
	_strategy = int(d.get("strategy", 3))
	current_streak = int(d.get("current_streak", 0))
	longest_streak = int(d.get("longest_streak", 0))
	total_played = int(d.get("total_played", 0))
	total_won = int(d.get("total_won", 0))
	best_by_size = d.get("best_by_size", {}).duplicate(true)

	main_cursor = d.get("main_cursor", {}).duplicate(true)
	super_hard_cursor = d.get("super_hard_cursor", {}).duplicate(true)
	single_region_cursor = d.get("single_region_cursor", {}).duplicate(true)
	sp_tt_cursor = d.get("sp_tt_cursor", {}).duplicate(true)
	onefish_cursor = d.get("onefish_cursor", {}).duplicate(true)

	recent_hashes = d.get("recent_hashes", []).duplicate()

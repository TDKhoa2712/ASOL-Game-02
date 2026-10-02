extends RefCounted

signal adjusted(reason: String, offset: int)

var _clean_streak: int = 0
var _fail_streak: int = 0
var _retry_streak: int = 0
var _demoted_this_level: bool = false

func record_result(won: bool, hints_used: int, mistakes: int, was_retry: bool) -> void:
	if won:
		_fail_streak = 0
		if hints_used == 0 and mistakes == 0:
			_clean_streak += 1
		else:
			_clean_streak = 0
	else:
		_clean_streak = 0
		_fail_streak += 1
	if was_retry:
		_retry_streak += 1
	else:
		_retry_streak = 0

func rank_offset(level_order: int, base_rank: int) -> int:
	var max_rank: int = 2 if level_order <= 15 else (3 if level_order <= 30 else 4)
	if _clean_streak >= 2:
		return maxi(0, mini(1, max_rank - base_rank))
	if _fail_streak >= 2 and not _demoted_this_level:
		_demoted_this_level = true
		adjusted.emit("fail_streak", -1)
		return -1
	if _retry_streak >= 2 and not _demoted_this_level:
		_demoted_this_level = true
		adjusted.emit("retry_streak", -1)
		return -1
	return 0

func on_level_start() -> void:
	_demoted_this_level = false

func to_dict() -> Dictionary:
	return {"clean_streak": _clean_streak, "fail_streak": _fail_streak, "retry_streak": _retry_streak}

func from_dict(data: Dictionary) -> void:
	_clean_streak = int(data.get("clean_streak", 0))
	_fail_streak = int(data.get("fail_streak", 0))
	_retry_streak = int(data.get("retry_streak", 0))
	_demoted_this_level = false

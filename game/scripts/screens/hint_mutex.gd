extends RefCounted

var _active_id: String = ""
var _cooldown_until: int = 0

const COOLDOWN_MS: int = 500

func try_acquire(hint_id: String) -> bool:
	if _active_id != "":
		return false
	if Time.get_ticks_msec() < _cooldown_until:
		return false
	_active_id = hint_id
	return true

func release(hint_id: String) -> void:
	if _active_id == hint_id:
		_active_id = ""
		_cooldown_until = Time.get_ticks_msec() + COOLDOWN_MS

func is_locked() -> bool:
	return _active_id != "" or Time.get_ticks_msec() < _cooldown_until

func force_release() -> void:
	_active_id = ""
	_cooldown_until = 0

# game/scripts/state/day_clock.gd
# Session-only date source; debug tools shift it, nothing persists it.
extends RefCounted

var offset_days: int = 0

func today() -> String:
	return shift_date(Time.get_date_string_from_system(), offset_days)

func advance(days: int) -> void:
	offset_days += days

func reset() -> void:
	offset_days = 0

func is_faked() -> bool:
	return offset_days != 0

static func shift_date(date: String, days: int) -> String:
	var unix := Time.get_unix_time_from_datetime_string(date + "T12:00:00")
	return Time.get_date_string_from_unix_time(unix + days * 86400)

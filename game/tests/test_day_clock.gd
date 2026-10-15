extends SceneTree

const DayClock = preload("res://scripts/state/day_clock.gd")
var failures: Array[String] = []

func check(c: bool, m: String) -> void:
	if not c: failures.append(m)

func _init() -> void:
	var real := Time.get_date_string_from_system()
	var clock := DayClock.new()
	check(clock.today() == real and not clock.is_faked(), "default is real date")
	clock.advance(1)
	check(clock.offset_days == 1 and clock.today() == DayClock.shift_date(real, 1), "+1 day")
	clock.advance(2)
	check(clock.offset_days == 3 and clock.is_faked(), "+2 day skip")
	clock.reset()
	check(clock.today() == real and clock.offset_days == 0, "reset to real")
	check(DayClock.shift_date("2026-12-31", 1) == "2027-01-01", "year boundary")
	check(DayClock.shift_date("2028-02-28", 1) == "2028-02-29", "leap day")
	check(DayClock.shift_date("2026-10-15", -1) == "2026-10-14", "yesterday")
	check(DayClock.new().offset_days == 0, "new instance not faked (session-only)")
	_finish("DAY_CLOCK_PASS")

func _finish(tag: String) -> void:
	if failures.is_empty():
		print(tag); quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

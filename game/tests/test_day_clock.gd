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

	var Inv = load("res://scripts/state/assist_inventory.gd")
	var Ops = load("res://scripts/state/assist_debug_ops.gd")
	var dir := OS.get_user_data_dir().path_join("day_clock_%s" % Time.get_ticks_usec())
	var inv = Inv.new(dir)
	var c2 := DayClock.new()
	inv.clock = c2
	var first: Dictionary = inv.on_round_finished()
	check(first.extended and inv.data.lastStreakDate == c2.today(), "inventory uses injected clock")
	c2.advance(1)
	check(inv.streak_view().at_risk and not inv.streak_view().kept_today, "+1 day puts streak at risk")
	var second: Dictionary = inv.on_round_finished()
	check(second.extended and int(inv.data.totalStreak) == 2 and second.view.count == 2, "next fake day extends streak")
	_check_callers(inv)
	c2.advance(2)
	check(inv.streak_view().count == 0, "skipped day drops view to 0")
	inv.replace_data(Ops.set_cycle(inv.data, 6, inv.current_day()))
	check(int(inv.data.streakDays) == 6 and inv.data.lastStreakDate == DayClock.shift_date(inv.current_day(), -1), "cycle 6, yesterday")
	var before_hint: int = inv.count("hint")
	var week: Dictionary = inv.on_round_finished()
	check(week.extended and week.reward.has("hint") and inv.count("hint") >= before_hint, "day 7 pays reward after set_cycle")
	inv.replace_data(Ops.set_cycle(inv.data, 99, inv.current_day()))
	check(int(inv.data.streakDays) == 6, "cycle clamped to 6")
	inv.replace_data(Ops.reset_streak(inv.data))
	check(int(inv.data.totalStreak) == 0 and inv.data.lastStreakDate == "" and int(inv.data.streakDays) == 0, "reset streak")
	inv.replace_data(Ops.nudge(inv.data, "place", 1))
	inv.replace_data(Ops.nudge(inv.data, "hint", -1))
	inv.replace_data(Ops.reset_stock(inv.data))
	check(inv.count("hint") == 3 and inv.count("place") == 1, "reset stock to START")
	inv.debug_counts_custom = true
	check(not Inv.new(dir).debug_counts_custom, "toggle not persisted")
	check(Inv.new(dir).clock == null, "clock not persisted")
	inv._store.remove_all()

	_finish("DAY_CLOCK_PASS")

func _check_callers(inv) -> void:
	var screen: Control = (load("res://scenes/streak.tscn") as PackedScene).instantiate()
	root.add_child(screen)
	screen.setup(inv)
	check(screen.count_label.text == "2" and screen.flame.lit, "streak screen follows the clock")
	var chip: Button = load("res://scripts/screens/streak_chip.gd").new()
	root.add_child(chip)
	chip.bind(inv)
	check(chip.count_label.text == "2" and chip.flame.lit, "home chip follows the clock")
	screen.free(); chip.free()

func _finish(tag: String) -> void:
	if failures.is_empty():
		print(tag); quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

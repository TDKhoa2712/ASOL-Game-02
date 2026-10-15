extends SceneTree

const Inventory = preload("res://scripts/state/assist_inventory.gd")
var failures: Array[String] = []
var events: Array = []

func _init() -> void:
	var dir := OS.get_user_data_dir().path_join("assist_inv_%s" % Time.get_ticks_usec())
	var inv := Inventory.new(dir)
	check(inv.count("hint") == 3 and inv.count("place") == 1, "fresh defaults")
	inv.changed.connect(func(k, c): events.append([k, c]))
	check(inv.try_consume("place"), "consume place")
	check(not inv.try_consume("place"), "place empty")
	check(events == [["place", 0]], "changed emitted once")
	check(inv.grant("hint", 50) == 7 and inv.count("hint") == 10, "grant clipped")
	var reloaded := Inventory.new(dir)
	check(reloaded.count("hint") == 10 and reloaded.count("place") == 0, "persisted")
	var first: Dictionary = reloaded.on_round_finished("2026-10-01")
	check(first.extended and first.reward.is_empty(), "day 1 extends, no reward")
	check(first.view.count == 1 and first.view.kept_today, "day 1 view")
	check(Inventory.new(dir).data.streakDays == 1, "streak persisted")
	reloaded._store.inject_corrupt("{oops")
	var recovered := Inventory.new(dir)
	check(recovered.count("hint") == 10, "recover from other slot")
	recovered._store.remove_all()
	check(Inventory.new(dir).count("hint") == 3, "missing files -> defaults")
	var sdir := dir + "_streak"
	var s_inv := Inventory.new(sdir)
	var a: Dictionary = s_inv.on_round_finished("2026-06-01")
	var b: Dictionary = s_inv.on_round_finished("2026-06-01")
	var c: Dictionary = s_inv.on_round_finished("2026-06-03")
	check(a.extended and not b.extended and c.extended, "restart from 1 extends; same day does not")
	check(b.reward.is_empty() and b.view.count == 1, "same day result keeps view")
	# Day 7 reward, clipped at CAP for hint
	var wdir := dir + "_week"
	var w_inv := Inventory.new(wdir)
	w_inv.data.streakDays = 6; w_inv.data.totalStreak = 6; w_inv.data.lastStreakDate = "2026-06-06"
	w_inv.data.hint = 10
	var week: Dictionary = w_inv.on_round_finished("2026-06-07")
	check(week.extended and week.reward == {"hint": 0, "place": 2}, "day 7 reward clipped, never negative")
	check(week.view.cycle_done == 7 and week.view.count == 7, "day 7 view shows full pack")
	check(not w_inv.has_signal("streak_extended"), "burst signal removed")
	w_inv._store.remove_all()
	check(s_inv.streak_view("2026-06-03").kept_today, "inventory view")
	s_inv._store.remove_all()
	DirAccess.remove_absolute(dir)
	if failures.is_empty():
		print("ASSIST_INVENTORY_PASS")
		quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)

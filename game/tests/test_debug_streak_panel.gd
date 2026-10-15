extends SceneTree

const Inv = preload("res://scripts/state/assist_inventory.gd")
const DayClock = preload("res://scripts/state/day_clock.gd")
const Ctl = preload("res://scripts/screens/puzzle_assist_controller.gd")
var failures: Array[String] = []

func check(c: bool, m: String) -> void:
	if not c: failures.append(m)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var dir := OS.get_user_data_dir().path_join("dbg_streak_%s" % Time.get_ticks_usec())
	var inv := Inv.new(dir); inv.clock = DayClock.new()
	var ctl := Ctl.new()          # RefCounted, not a Node
	ctl.bind(null, null, inv)     # puzzle_screen binds no stock for custom levels, but passes the streak source
	var fake_session := RefCounted.new()
	var off: Dictionary = ctl.on_round_finished(fake_session, true)
	check(off.is_empty() and ctl.round_result.is_empty() and int(inv.data.totalStreak) == 0, "custom level ignored by default")
	inv.debug_counts_custom = true
	var on: Dictionary = ctl.on_round_finished(fake_session, true)
	check(on.extended and ctl.round_result == on and int(inv.data.totalStreak) == 1, "custom level counts when toggled")
	inv.debug_counts_custom = false
	await _panel_tests(inv, dir)
	inv._store.remove_all()
	if failures.is_empty():
		print("DEBUG_STREAK_PANEL_PASS"); quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func _panel_tests(_inv, _dir: String) -> void:
	await process_frame  # filled in Task 4

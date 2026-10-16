extends SceneTree

const Inv = preload("res://scripts/state/assist_inventory.gd")
const DayClock = preload("res://scripts/state/day_clock.gd")
const Ctl = preload("res://scripts/screens/puzzle_assist_controller.gd")
const SLOT_FILES := ["assists.a.json", "assists.b.json", "assists.flag"]

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

func _n(p: Node, node_name: String) -> Node:
	return p.find_child(node_name, true, false)

func _panel_tests(inv, dir: String) -> void:
	var Panel = load("res://scripts/screens/debug_streak_panel.gd")
	var p = Panel.new(); root.add_child(p); p.setup(inv)
	var real := Time.get_date_string_from_system()
	check(_n(p, "DateLabel").text.contains(real), "shows real date")
	_n(p, "PlusDay").pressed.emit()
	check(inv.clock.offset_days == 1 and _n(p, "DateLabel").text.contains(inv.current_day()), "+1 day shown")
	_n(p, "SkipDay").pressed.emit()
	check(inv.clock.offset_days == 3, "skip = +2")
	_n(p, "RealDay").pressed.emit()
	check(inv.clock.offset_days == 0 and inv.current_day() == real, "back to real")
	_n(p, "CycleSpin").value = 4
	_n(p, "CycleApply").pressed.emit()
	check(int(inv.data.streakDays) == 4, "cycle set")
	_n(p, "ResetStreak").pressed.emit()
	check(int(inv.data.totalStreak) == 0, "streak reset")
	var h: int = inv.count("hint")
	_n(p, "HintPlus").pressed.emit()
	check(inv.count("hint") == mini(h + 1, 10), "hint +1")
	_n(p, "PlaceMinus").pressed.emit()
	_n(p, "ResetStock").pressed.emit()
	check(inv.count("hint") == 3 and inv.count("place") == 1, "stock reset")
	check(not _n(p, "CountToggle").button_pressed, "toggle default off")
	_n(p, "CountToggle").button_pressed = true
	check(inv.debug_counts_custom, "toggle writes session flag")
	# previews never write save: slot files byte-identical before/after
	var snapshot := JSON.stringify(inv.data)
	var before := {}
	for f in SLOT_FILES: before[f] = FileAccess.get_file_as_string(dir.path_join(f))
	for btn in ["PreviewStreak", "PreviewActivate", "PreviewGift"]:
		_n(p, btn).pressed.emit()
		var overlay: Node = root.get_node_or_null("DebugStreakPreview")
		check(overlay != null, btn + " opens overlay")
		if overlay != null:
			check(overlay.get("assists") == null, btn + " has no inventory")
			overlay.queue_free()
		await process_frame
	check(JSON.stringify(inv.data) == snapshot, "preview leaves data untouched")
	for f in SLOT_FILES:
		check(FileAccess.get_file_as_string(dir.path_join(f)) == before[f], "file unchanged: " + f)
	p.queue_free()
	await process_frame

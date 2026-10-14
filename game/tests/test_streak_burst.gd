extends SceneTree

const StreakBurst = preload("res://scripts/screens/streak_burst.gd")
const Controller = preload("res://scripts/screens/puzzle_assist_controller.gd")
const Inventory = preload("res://scripts/state/assist_inventory.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const LEVEL := {"id": "T1", "size": 4, "regions": ["ABCC", "AAAC", "ADDC", "ADDD"], "solution": [1, 3, 0, 2]}
var failures: Array[String] = []

func _init() -> void:
	LayoutTokens.motion_enabled = false
	var host := Control.new()
	root.add_child(host)
	var burst := StreakBurst.play(host, 12)
	check(burst.name == "StreakBurst" and burst.get_parent() == host, "burst added")
	check((burst.get_meta("label") as Label).text == "12", "reduced motion shows final count")

	var dir := OS.get_user_data_dir().path_join("streak_burst_%s" % Time.get_ticks_usec())
	var inv := Inventory.new(dir)
	var screen := Control.new()
	root.add_child(screen)
	var ctl := Controller.new()
	var hint_btn := Button.new(); var place_btn := Button.new()
	screen.add_child(hint_btn); screen.add_child(place_btn)  # owned by the tree so nothing leaks
	ctl.setup(screen, hint_btn, place_btn)
	ctl.bind(inv, null)
	ctl.on_level_won(PlaySession.new(LEVEL), false)
	check(ctl.burst_played and screen.get_node_or_null("StreakBurst") != null, "first win of the day bursts")
	screen.get_node("StreakBurst").free()
	ctl.on_level_won(PlaySession.new(LEVEL), false)
	check(not ctl.burst_played and screen.get_node_or_null("StreakBurst") == null, "second win same day: no burst")
	ctl.on_level_won(PlaySession.new(LEVEL), true)
	check(screen.get_node_or_null("StreakBurst") == null, "custom win: no burst")
	host.queue_free(); screen.queue_free()
	inv._store.remove_all()
	if failures.is_empty():
		print("STREAK_BURST_PASS")
		quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)

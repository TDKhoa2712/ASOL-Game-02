extends SceneTree

const PuzzleScreen = preload("res://scripts/screens/puzzle_screen.gd")
const Inventory = preload("res://scripts/state/assist_inventory.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const LEVEL := {"id": "T1", "size": 4, "regions": ["ABCC", "AAAC", "ADDC", "ADDD"], "solution": [1, 3, 0, 2]}
var failures: Array[String] = []

func _init() -> void:
	PuzzleScreen.hold_results = false
	var dir := OS.get_user_data_dir().path_join("assist_flow_%s" % Time.get_ticks_usec())
	var inv := Inventory.new(dir)
	inv.grant("place", 9)  # place = 10
	var screen := PuzzleScreen.new()
	screen.assists = inv
	root.add_child(screen)
	screen.setup(null, null, null, LEVEL, false)
	screen.assist_ctl.bind(inv, screen.hint_coordinator)  # simulate a campaign level
	check(screen.place_btn.get_node("Badge/PlaceCount").text == "10", "place badge bound")
	check(screen.hint_btn.get_node("Badge").visible, "hint badge visible when bound")
	for i in 3:
		screen.place_btn.pressed.emit()
	check(screen.session.remaining_candies() == 1 and inv.count("place") == 7, "three placed, three charged")
	screen.place_btn.pressed.emit()
	check(screen.session.phase == 1, "last candy wins the level")
	check(inv.count("place") == 6, "last candy charged once")
	screen.place_btn.pressed.emit()
	check(inv.count("place") == 6, "no charge after win")
	check(inv.data.streakDays == 0, "custom win does not count for streak")
	# Custom/debug levels never touch the real stock
	var custom := PuzzleScreen.new()
	custom.assists = inv
	root.add_child(custom)
	custom.setup(null, null, null, LEVEL, false)
	check(not custom.place_btn.visible, "place hidden on custom level")
	custom.hint_coordinator.request_hint(custom.session)
	check(inv.count("hint") == 3, "custom hint does not charge")
	custom.queue_free()
	# Empty stock opens popup
	var screen2 := PuzzleScreen.new()
	var inv2 := Inventory.new(dir + "_b")
	inv2.try_consume("place")
	screen2.assists = inv2
	root.add_child(screen2)
	screen2.setup(null, null, null, LEVEL, false)
	screen2.assist_ctl.bind(inv2, screen2.hint_coordinator)  # simulate a campaign level
	screen2.place_btn.pressed.emit()
	check(screen2.assist_ctl.popup.visible, "empty place opens popup")
	check(screen2.session.remaining_candies() == 4, "nothing placed when empty")
	# Campaign-style win records streak once even if won handler runs twice
	screen2.assist_ctl.on_level_won(screen2.session, false)
	screen2.assist_ctl.on_level_won(screen2.session, false)
	check(inv2.data.streakDays == 1, "resume won twice records once")
	screen.queue_free(); screen2.queue_free()
	inv._store.remove_all(); inv2._store.remove_all()
	if failures.is_empty():
		print("ASSIST_FLOW_PASS")
		quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)

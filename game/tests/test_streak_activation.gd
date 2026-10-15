extends SceneTree

const NavController = preload("res://scripts/campaign/nav_controller.gd")
const StreakFlow = preload("res://scripts/campaign/streak_flow.gd")
const ActivateScreen = preload("res://scripts/screens/streak_activate_screen.gd")
const GiftScreen = preload("res://scripts/screens/streak_gift_screen.gd")
const S = NavController.Screen
const VIEW := {"count": 3, "best": 5, "kept_today": true, "at_risk": false, "cycle_done": 3}
var failures: Array[String] = []

func _initialize() -> void:
	_test_flow()
	_test_routes()
	await _test_screens()
	if failures.is_empty():
		print("STREAK_ACTIVATION_PASS")
		quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func _test_flow() -> void:
	var flow := StreakFlow.new()
	check(flow.start({}, S.WIN) == S.WIN, "empty result goes straight to result screen")
	check(flow.start(null, S.FAIL) == S.FAIL, "null source tolerated")
	check(flow.start({"extended": false, "view": VIEW, "reward": {}}, S.WIN) == S.WIN, "same day: no activate")
	check(flow.start({"extended": true, "view": VIEW, "reward": {}}, S.FAIL) == S.STREAK_ACTIVATE, "first round: activate")
	check(flow.view == VIEW and flow.next() == S.FAIL, "activate then fail")
	var gift := {"hint": 2, "place": 3}
	check(flow.start({"extended": true, "view": VIEW, "reward": gift}, S.WIN) == S.STREAK_ACTIVATE, "day 7 starts with activate")
	check(flow.next() == S.STREAK_GIFT and flow.reward == gift, "then gift")
	check(flow.next() == S.WIN and flow.next() == S.WIN, "then win; empty queue stays on result")
	var holder := Node.new(); holder.set_meta("unused", 1)
	check(flow.start(holder, S.WIN) == S.WIN, "source without round_result")
	holder.free()

func _test_routes() -> void:
	var nav := NavController.new()
	check(nav.go_to(S.PUZZLE) and nav.go_to(S.STREAK_ACTIVATE), "puzzle -> activate")
	check(nav.current_name() == "streak_activate", "activate name")
	check(nav.go_to(S.STREAK_GIFT) and nav.current_name() == "streak_gift", "activate -> gift")
	check(nav.go_to(S.WIN), "gift -> win")
	nav = NavController.new(); nav.go_to(S.PUZZLE); nav.go_to(S.STREAK_ACTIVATE)
	check(nav.go_to(S.FAIL), "activate -> fail")
	nav = NavController.new()
	check(not nav.go_to(S.STREAK_ACTIVATE), "title cannot open activate")

func _test_screens() -> void:
	await process_frame
	var act := ActivateScreen.new()
	root.add_child(act)
	act.setup(VIEW)
	check(act.count_label.text == "3", "activate shows streak count")
	check(act.flame.lit, "activate lights the flame")
	var hits := [0]
	act.continued.connect(func(): hits[0] += 1)
	act.continue_btn.pressed.emit()
	check(hits[0] == 1, "activate continue emits once")
	act.queue_free()
	var gift := GiftScreen.new()
	root.add_child(gift)
	gift.setup({"hint": 0, "place": 4})
	check(gift.hint_label.text == tr("streak.gift_hint") % 0, "gift shows +0 hint")
	check(gift.place_label.text == tr("streak.gift_place") % 4, "gift shows +4 place")
	var g_hits := [0]
	gift.continued.connect(func(): g_hits[0] += 1)
	gift.continue_btn.pressed.emit()
	check(g_hits[0] == 1, "gift continue emits once")
	gift.queue_free()
	# No save access: neither script references a store/inventory
	for p in ["res://scripts/screens/streak_activate_screen.gd", "res://scripts/screens/streak_gift_screen.gd"]:
		var src := FileAccess.get_file_as_string(p)
		check(not src.contains("assist_inventory") and not src.contains("dual_slot_store"), "no save access in " + p)

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)

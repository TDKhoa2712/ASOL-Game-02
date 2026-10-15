extends SceneTree

const NavController = preload("res://scripts/campaign/nav_controller.gd")
const StreakFlow = preload("res://scripts/campaign/streak_flow.gd")
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
	pass  # filled in Task 3

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)

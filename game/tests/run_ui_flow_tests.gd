extends SceneTree

const Flow = preload("res://scripts/ui_flow_controller.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_check_flow_routes()
	_check_bootstrap_scene()
	if failures.is_empty():
		print("M1_A07_UI_FLOW_PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_flow_routes() -> void:
	var flow = Flow.new(["L01", "L02", "L03", "L04"])
	_check(flow.current_screen == Flow.SCREEN_HOME, "flow starts at home")
	_check(flow.current_level_id == "L01", "flow starts at L01")

	_check(flow.dispatch("start_game"), "home accepts start_game")
	_check(flow.current_screen == Flow.SCREEN_PUZZLE, "start_game opens puzzle")
	_check(flow.dispatch("win"), "puzzle accepts win")
	_check(flow.current_screen == Flow.SCREEN_RESULT_WIN, "win opens result win")
	_check(flow.dispatch("next"), "result win accepts next")
	_check(flow.current_screen == Flow.SCREEN_PUZZLE, "next opens next puzzle")
	_check(flow.current_level_id == "L02", "next advances to L02")

	_check(flow.dispatch("fail"), "puzzle accepts fail")
	_check(flow.current_screen == Flow.SCREEN_RESULT_FAIL, "fail opens result fail")
	_check(flow.dispatch("retry"), "result fail accepts retry")
	_check(flow.current_screen == Flow.SCREEN_PUZZLE, "retry opens puzzle")
	_check(flow.current_level_id == "L02", "retry keeps current level")

	_check(flow.dispatch("help"), "puzzle accepts help")
	_check(flow.current_screen == Flow.SCREEN_HELP, "help opens help screen")
	_check(flow.dispatch("back"), "help accepts back")
	_check(flow.current_screen == Flow.SCREEN_PUZZLE, "back returns to previous screen")
	_check(flow.dispatch("settings"), "puzzle accepts settings")
	_check(flow.current_screen == Flow.SCREEN_SETTINGS, "settings opens settings screen")
	_check(flow.dispatch("home"), "settings accepts home")
	_check(flow.current_screen == Flow.SCREEN_HOME, "home returns to home")
	_check(flow.dispatch("start_game"), "home resumes current level")
	_check(flow.current_screen == Flow.SCREEN_PUZZLE, "resume opens current puzzle")

	var before_invalid: String = flow.current_screen
	_check(not flow.dispatch("not-a-route"), "unknown action is rejected")
	_check(flow.current_screen == before_invalid, "unknown action does not mutate state")

	for level_id in ["L02", "L03"]:
		_check(flow.dispatch("win"), "puzzle can win %s" % level_id)
		_check(flow.dispatch("next"), "result can advance after %s" % level_id)
	_check(flow.dispatch("win"), "puzzle can win L04")
	_check(flow.dispatch("next"), "final result returns home")
	_check(flow.current_screen == Flow.SCREEN_HOME, "winning final level returns home")
	_check(flow.current_level_id == "L04", "final level remains selected after campaign end")


func _check_bootstrap_scene() -> void:
	var scene = load("res://scenes/bootstrap.tscn")
	_check(scene != null, "bootstrap scene loads")
	if scene == null:
		return
	var bootstrap = scene.instantiate()
	_check(bootstrap.get_script() != null, "bootstrap has flow script")
	_check(bootstrap.get_node_or_null("ScreenHost") != null, "bootstrap has screen host")
	bootstrap.free()


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append("FAIL: " + label)

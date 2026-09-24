extends SceneTree

const Runtime = preload("res://scripts/mvp_runtime.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_run()
	if failures.is_empty():
		print("M1_A08_MVP_RUNTIME_PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run() -> void:
	var root := OS.get_user_data_dir().path_join("m1_a08_runtime_tests")
	var runtime = Runtime.new(root)
	runtime.clear_saved_state()
	runtime.initialize()
	_check(runtime.level_ids == ["L01", "L02", "L03", "L04"], "campaign levels load in order")
	_check(runtime.current_level_id == "L01", "runtime starts at L01")
	_check(runtime.engine != null, "runtime creates gesture engine")
	_check(runtime.engine.level.get("id", "") == "L01", "engine uses campaign L01")

	runtime.apply_action({"type": "MarkX", "cell": [0, 0]})
	_check(runtime.engine.session.cell_state([0, 0]) == "x", "committed action reaches session")
	_check(runtime.has_saved_session(), "committed session is persisted")

	var resumed = Runtime.new(root)
	resumed.initialize()
	_check(resumed.engine.session.cell_state([0, 0]) == "x", "new runtime resumes saved X")
	_check(resumed.current_level_id == "L01", "resume keeps current level")

	var hint := resumed.use_hint()
	_check(hint.get("ok", false), "runtime exposes current Hint evidence")
	_check(resumed.engine.session.hint_count == 1, "valid Hint consumes one Hint")
	_check(resumed.engine.session.cell_state([3, 2]) != "cat", "Hint does not place a cat")
	_check(not resumed.use_hint().get("ok", false), "second Hint is rejected")

	var tutorial_target: Array = resumed.tutorial_state.get("tutorialHighlight", [])
	var tutorial_result := resumed.process_tutorial_action({"type": "MarkX", "cell": tutorial_target})
	_check(tutorial_result.get("completed", []).has("T1"), "L01 tutorial receives runtime action")
	_check(resumed.progress.get("tutorialState", {}).get("tutorialSeenIds", []).has("T1"), "tutorial state is saved in progress")

	for row in range(4):
		resumed.apply_action({"type": "TryCat", "cell": [row, [1, 3, 0, 2][row]]})
	_check(resumed.progress.get("completedLevelIds", []).has("L01"), "winning L01 updates progress")
	_check(resumed.progress.get("currentLevelId", "") == "L02", "winning L01 selects successor")
	_check(not resumed.has_saved_session(), "winning L01 clears active session")

	resumed.start_level("L02")
	_check(resumed.current_level_id == "L02", "runtime starts successor level")
	_check(resumed.engine.level.get("size", 0) == 5, "successor uses L02 board size")

	var bootstrap_scene = load("res://scenes/bootstrap.tscn")
	var bootstrap = bootstrap_scene.instantiate()
	bootstrap._ready()
	bootstrap._on_action("start_game")
	var active_screen = bootstrap.get_node("ScreenHost").get_child(0)
	active_screen._ready()
	_check(active_screen.get_script() == load("res://scripts/board_screen.gd"), "bootstrap opens real board screen")
	_check(active_screen.get_session() != null, "real board screen receives runtime session")
	bootstrap.runtime.clear_saved_state()
	bootstrap.runtime.progress = bootstrap.runtime.repository.new_progress("L01")
	bootstrap.runtime.start_level("L01", false)
	bootstrap.flow.current_screen = "home"
	bootstrap.flow.current_level_index = 0
	bootstrap._on_action("start_game")
	for row in range(4):
		bootstrap.runtime.apply_action({"type": "TryCat", "cell": [row, [1, 3, 0, 2][row]]})
	_check(bootstrap.flow.current_screen == "result_win", "real gameplay routes to win result")
	_check(bootstrap.get_node("ScreenHost").get_child(0).get_meta("screen_id", "") == "result_win", "win result screen is visible")
	_check(bootstrap.get_node_or_null("ScreenHost/ResultWin/SafeArea/Content/Stack") != null, "win result has managed layout stack")
	_check(bootstrap.get_node_or_null("ScreenHost/ResultWin/SafeArea/Content/Stack/ContinueButton") != null, "win result has Continue button")

	bootstrap.runtime.progress = bootstrap.runtime.repository.new_progress("L01")
	bootstrap.runtime.start_level("L01", false)
	bootstrap.flow.current_screen = "home"
	bootstrap.flow.current_level_index = 0
	bootstrap._on_action("start_game")
	for wrong_cell in [[0, 0], [1, 0], [2, 1]]:
		bootstrap.runtime.apply_action({"type": "TryCat", "cell": wrong_cell})
	_check(bootstrap.flow.current_screen == "result_fail", "real gameplay routes to fail result")
	_check(bootstrap.get_node("ScreenHost").get_child(0).get_meta("screen_id", "") == "result_fail", "fail result screen is visible")
	_check(bootstrap.get_node_or_null("ScreenHost/ResultFail/SafeArea/Content/Stack") != null, "fail result has managed layout stack")
	_check(bootstrap.get_node_or_null("ScreenHost/ResultFail/SafeArea/Content/Stack/RetryButton") != null, "fail result has Retry button")
	bootstrap.free()

	resumed.clear_saved_state()


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append("FAIL: " + label)

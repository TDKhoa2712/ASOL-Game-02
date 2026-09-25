extends SceneTree

const Runtime = preload("res://scripts/mvp_runtime.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _finish() -> void:
	if failures.is_empty():
		print("M1_A08_MVP_RUNTIME_PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run() -> void:
	var profile := OS.get_user_data_dir().path_join("r1_runtime_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()])
	var runtime = Runtime.new(profile)
	runtime.clear_saved_state()
	runtime.initialize()
	_check(runtime.level_ids == ["L01", "L02", "L03", "L04"], "campaign levels load in order")
	_check(runtime.current_level_id == "L01", "runtime starts at L01")
	_check(runtime.engine != null, "runtime creates gesture engine")
	_check(runtime.engine.level.get("id", "") == "L01", "engine uses campaign L01")

	runtime.apply_action({"type": "MarkX", "cell": [1, 1]})
	_check(runtime.engine.session.cell_state([1, 1]) == "x", "committed action reaches session")
	_check(runtime.has_saved_session(), "committed session is persisted")

	var resumed = Runtime.new(profile)
	resumed.initialize()
	_check(resumed.engine.session.cell_state([1, 1]) == "x", "new runtime resumes saved X")
	_check(resumed.current_level_id == "L01", "resume keeps current level")

	var hint := resumed.use_hint()
	_check(hint.get("ok", false), "runtime exposes current Hint evidence")
	_check(resumed.engine.session.hint_count == 1, "valid Hint consumes one Hint")
	_check(resumed.engine.session.cell_state([3, 2]) != "cat", "Hint does not place a cat")
	_check(not resumed.use_hint().get("ok", false), "second Hint is rejected")

	_check(resumed.progress.get("tutorialState", {}).get("tutorialSeenIds", []).has("T1"), "committed X records tutorial T1")

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
	var win_profile := profile.path_join("win")
	bootstrap.runtime = Runtime.new(win_profile)
	root.add_child(bootstrap)
	await process_frame
	bootstrap.get_node("ScreenHost/Home/SafeArea/Content/Stack/PlayButton").pressed.emit()
	await process_frame
	var active_screen = bootstrap.get_node("ScreenHost").get_child(0)
	_check(active_screen.get_script() == load("res://scripts/board_screen.gd"), "bootstrap opens real board screen")
	_check(active_screen.get_session() != null, "real board screen receives runtime session")
	for row in range(4):
		bootstrap.runtime.apply_action({"type": "TryCat", "cell": [row, [1, 3, 0, 2][row]]})
	_check(bootstrap.flow.current_screen == "puzzle", "win result waits until current input completes")
	await process_frame
	_check(bootstrap.flow.current_screen == "result_win", "real gameplay routes to win result")
	_check(bootstrap.get_node("ScreenHost").get_child(0).get_meta("screen_id", "") == "result_win", "win result screen is visible")
	_check(bootstrap.get_node_or_null("ScreenHost/ResultWin/SafeArea/Content/Stack") != null, "win result has managed layout stack")
	_check(bootstrap.get_node_or_null("ScreenHost/ResultWin/SafeArea/Content/Stack/ContinueButton") != null, "win result has Continue button")

	var win_runtime = bootstrap.runtime
	bootstrap.free()
	win_runtime.clear_saved_state()
	DirAccess.remove_absolute(win_profile)
	var fail_profile := profile.path_join("fail")
	bootstrap = bootstrap_scene.instantiate()
	bootstrap.runtime = Runtime.new(fail_profile)
	root.add_child(bootstrap)
	await process_frame
	bootstrap.get_node("ScreenHost/Home/SafeArea/Content/Stack/PlayButton").pressed.emit()
	await process_frame
	for wrong_cell in [[0, 2], [1, 0], [2, 1]]:
		bootstrap.runtime.apply_action({"type": "TryCat", "cell": wrong_cell})
	_check(bootstrap.flow.current_screen == "puzzle", "fail result waits until current input completes")
	await process_frame
	_check(bootstrap.flow.current_screen == "result_fail", "real gameplay routes to fail result")
	_check(bootstrap.get_node("ScreenHost").get_child(0).get_meta("screen_id", "") == "result_fail", "fail result screen is visible")
	_check(bootstrap.get_node_or_null("ScreenHost/ResultFail/SafeArea/Content/Stack") != null, "fail result has managed layout stack")
	_check(bootstrap.get_node_or_null("ScreenHost/ResultFail/SafeArea/Content/Stack/RetryButton") != null, "fail result has Retry button")
	var fail_runtime = bootstrap.runtime
	bootstrap.free()
	fail_runtime.clear_saved_state()
	DirAccess.remove_absolute(fail_profile)

	resumed.clear_saved_state()
	DirAccess.remove_absolute(profile)
	_finish()


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append("FAIL: " + label)

extends SceneTree

const Runtime = preload("res://scripts/mvp_runtime.gd")
const BootstrapScene = preload("res://scenes/bootstrap.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await _win_home_play()
	await _failed_resume()
	await _complete_campaign()
	if failures.is_empty():
		print("R1_PLAYABLE_FLOW_PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _win_home_play() -> void:
	var profile := OS.get_user_data_dir().path_join("r1_flow_win_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()])
	var bootstrap = BootstrapScene.instantiate()
	bootstrap.runtime = Runtime.new(profile)
	root.add_child(bootstrap)
	await process_frame
	_press(bootstrap, "Home/SafeArea/Content/Stack/PlayButton")
	await process_frame
	for row in range(4):
		bootstrap.runtime.apply_action({"type": "TryCat", "cell": [row, [1, 3, 0, 2][row]]})
	await process_frame
	_check(bootstrap.flow.current_screen == "result_win", "winning L01 shows result")
	var win_score = bootstrap.get_node_or_null("ScreenHost/ResultWin/SafeArea/Content/Stack/ScoreLabel")
	_check(win_score != null and win_score.text.contains("400"), "win result shows score 400 for four cats")
	_press(bootstrap, "ResultWin/SafeArea/Content/Stack/HomeButton")
	await process_frame
	_check(bootstrap.flow.current_screen == "home", "result Home returns home")
	_press(bootstrap, "Home/SafeArea/Content/Stack/PlayButton")
	await process_frame
	_check(bootstrap.runtime.current_level_id == "L02", "Home Play starts saved successor L02")
	_check(bootstrap.runtime.engine.level.get("id", "") == "L02", "visible puzzle uses L02")
	var runtime = bootstrap.runtime
	bootstrap.free()
	runtime.clear_saved_state()
	DirAccess.remove_absolute(profile)

func _press(bootstrap: Node, path: String) -> void:
	var button = bootstrap.get_node_or_null("ScreenHost/" + path)
	if button == null:
		failures.append("missing button: " + path)
		return
	button.pressed.emit()

func _failed_resume() -> void:
	var profile := OS.get_user_data_dir().path_join("r1_flow_fail_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()])
	var bootstrap = BootstrapScene.instantiate()
	bootstrap.runtime = Runtime.new(profile)
	root.add_child(bootstrap)
	await process_frame
	_press(bootstrap, "Home/SafeArea/Content/Stack/PlayButton")
	await process_frame
	for wrong_cell in [[0, 2], [1, 0], [2, 1]]:
		bootstrap.runtime.apply_action({"type": "TryCat", "cell": wrong_cell})
	await process_frame
	_check(bootstrap.flow.current_screen == "result_fail", "three mistakes show Fail")
	var fail_score = bootstrap.get_node_or_null("ScreenHost/ResultFail/SafeArea/Content/Stack/ScoreLabel")
	_check(fail_score != null and fail_score.text == "Điểm: 0", "fail result shows score zero")
	_press(bootstrap, "ResultFail/SafeArea/Content/Stack/HomeButton")
	await process_frame
	var runtime = bootstrap.runtime
	bootstrap.free()
	bootstrap = BootstrapScene.instantiate()
	bootstrap.runtime = Runtime.new(profile)
	root.add_child(bootstrap)
	await process_frame
	_press(bootstrap, "Home/SafeArea/Content/Stack/PlayButton")
	await process_frame
	_check(bootstrap.flow.current_screen == "result_fail", "Home Play restores failed result")
	_check(bootstrap.runtime.engine.session.hearts == 0, "failed resume keeps zero hearts")
	_press(bootstrap, "ResultFail/SafeArea/Content/Stack/RetryButton")
	await process_frame
	_check(bootstrap.flow.current_screen == "puzzle", "Retry opens puzzle")
	_check(bootstrap.runtime.current_level_id == "L01", "Retry stays on failed level")
	_check(bootstrap.runtime.engine.session.hearts == 3, "Retry starts with three hearts")
	var resumed_runtime = bootstrap.runtime
	bootstrap.free()
	resumed_runtime.clear_saved_state()
	DirAccess.remove_absolute(profile)

func _complete_campaign() -> void:
	var profile := OS.get_user_data_dir().path_join("r1_flow_end_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()])
	var bootstrap = BootstrapScene.instantiate()
	bootstrap.runtime = Runtime.new(profile)
	root.add_child(bootstrap)
	await process_frame
	_press(bootstrap, "Home/SafeArea/Content/Stack/PlayButton")
	await process_frame
	for level_id in ["L01", "L02", "L03", "L04"]:
		_check(bootstrap.runtime.current_level_id == level_id, "campaign order reaches " + level_id)
		var level: Dictionary = bootstrap.runtime.active_level
		for row in range(int(level["size"])):
			var cell := [row, int(level["solution"][row])]
			if bootstrap.runtime.engine.session.cell_state(cell) != "cat":
				bootstrap.runtime.apply_action({"type": "TryCat", "cell": cell})
		await process_frame
		_check(bootstrap.flow.current_screen == "result_win", "win screen after " + level_id)
		var continue_button = bootstrap.get_node_or_null("ScreenHost/ResultWin/SafeArea/Content/Stack/ContinueButton")
		if level_id == "L04":
			_check(continue_button != null and continue_button.text == "Chơi lại từ L01", "only final Result offers replay from L01")
			_check(bootstrap.get_node_or_null("ScreenHost/ResultWin/SafeArea/Content/Stack/HomeButton") != null, "final Result still offers Home")
			_press(bootstrap, "ResultWin/SafeArea/Content/Stack/ContinueButton")
			await process_frame
		else:
			_check(continue_button != null and continue_button.text == "Tiếp tục", level_id + " Result keeps Continue")
			_press(bootstrap, "ResultWin/SafeArea/Content/Stack/ContinueButton")
			await process_frame
	_check(bootstrap.flow.current_screen == "puzzle", "final Result replay opens puzzle directly")
	_check(bootstrap.runtime.progress.get("currentLevelId", "missing") == null, "campaign stores completion marker")
	_check(bootstrap.runtime.current_level_id == "L01", "MVP replay starts at L01")
	_check(bootstrap.runtime.engine.session.attempt_state == "Playing", "MVP replay creates a fresh attempt")
	var replay_level: Dictionary = bootstrap.runtime.active_level
	for row in range(int(replay_level["size"])):
		bootstrap.runtime.apply_action({"type": "TryCat", "cell": [row, int(replay_level["solution"][row])]})
	await process_frame
	var replay_continue = bootstrap.get_node_or_null("ScreenHost/ResultWin/SafeArea/Content/Stack/ContinueButton")
	_check(replay_continue != null and replay_continue.text == "Tiếp tục", "replayed L01 returns to normal Continue")
	_press(bootstrap, "ResultWin/SafeArea/Content/Stack/ContinueButton")
	await process_frame
	_check(bootstrap.flow.current_screen == "puzzle", "replayed L01 Continue opens next puzzle")
	_check(bootstrap.runtime.current_level_id == "L02", "replayed L01 advances to L02")
	var replay_board = bootstrap.get_node("ScreenHost").get_child(0)
	var replay_home = replay_board.find_child("HomeButton", true, false)
	_check(replay_home != null, "MVP replay board exposes Home")
	if replay_home != null:
		replay_home.pressed.emit()
	await process_frame
	await process_frame
	_check(bootstrap.flow.current_screen == "home", "MVP replay can return Home")
	_check(bootstrap.runtime.progress.get("completedLevelIds", []).size() == 4, "MVP replay preserves completed level history")
	var runtime = bootstrap.runtime
	bootstrap.free()
	bootstrap = BootstrapScene.instantiate()
	bootstrap.runtime = Runtime.new(profile)
	root.add_child(bootstrap)
	await process_frame
	_check(bootstrap.runtime.progress.get("currentLevelId", "missing") == null, "reload preserves completed campaign")
	var play = bootstrap.get_node_or_null("ScreenHost/Home/SafeArea/Content/Stack/PlayButton")
	_check(play != null and not play.disabled, "Home Play stays available for MVP replay")
	var resumed_runtime = bootstrap.runtime
	bootstrap.free()
	resumed_runtime.clear_saved_state()
	DirAccess.remove_absolute(profile)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

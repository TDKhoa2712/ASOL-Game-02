extends SceneTree

const Runtime = preload("res://scripts/mvp_runtime.gd")
const BootstrapScene = preload("res://scenes/bootstrap.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var profile := OS.get_user_data_dir().path_join("r1_save_failure_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()])
	var runtime = Runtime.new(profile)
	var wins: Array[String] = []
	runtime.level_won.connect(func(level_id: String, _next_id: String) -> void: wins.append(level_id))
	var errors: Array[String] = []
	runtime.save_failed.connect(func(reason: String) -> void: errors.append(reason))
	_check(runtime.initialize(), "runtime initializes in isolated profile")
	var blocker := profile.path_join("progress.json.tmp")
	_check(DirAccess.make_dir_absolute(blocker) == OK, "create controlled progress write failure")
	for row in range(4):
		runtime.apply_action({"type": "TryCandy", "cell": [row, [1, 3, 0, 2][row]]})
	_check(wins.is_empty(), "no Win signal when progress write fails")
	_check(runtime.progress.get("currentLevelId") == "L01", "in-memory progress remains L01 on failure")
	_check(runtime.repository.load_progress().get("ok", false) == false, "no false durable progress")
	_check(runtime.has_saved_session(), "winning session remains available for retry")
	_check(errors.size() == 1, "save failure is reported once")
	DirAccess.remove_absolute(blocker)
	_check(runtime.retry_pending_save(), "saved winning board can retry progress commit")
	_check(wins == ["L01"], "retry emits exactly one Win")
	_check(runtime.progress.get("currentLevelId") == "L02", "retry advances in-memory progress")
	_check(runtime.repository.load_progress().get("data", {}).get("currentLevelId") == "L02", "retry writes durable progress")
	_check(not runtime.has_saved_session(), "retry clears completed session")
	runtime.clear_saved_state()
	DirAccess.remove_absolute(profile)
	await _ui_retry()
	await _reload_pending_win()
	await _corrupt_progress()
	await _session_write_failure()
	await _tutorial_progress_write_failure()
	if failures.is_empty():
		print("R1_SAVE_FAILURE_PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _ui_retry() -> void:
	var profile := OS.get_user_data_dir().path_join("r1_save_ui_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()])
	var bootstrap = BootstrapScene.instantiate()
	bootstrap.runtime = Runtime.new(profile)
	root.add_child(bootstrap)
	await process_frame
	bootstrap.get_node("ScreenHost/Home/SafeArea/Content/Stack/PlayButton").pressed.emit()
	await process_frame
	var blocker := profile.path_join("progress.json.tmp")
	DirAccess.make_dir_absolute(blocker)
	for row in range(4):
		bootstrap.runtime.apply_action({"type": "TryCandy", "cell": [row, [1, 3, 0, 2][row]]})
	await process_frame
	var dialog = bootstrap.get_node_or_null("SaveErrorDialog")
	_check(dialog != null and dialog.visible, "save error is shown to player")
	DirAccess.remove_absolute(blocker)
	if dialog != null:
		dialog.confirmed.emit()
	await process_frame
	_check(bootstrap.flow.current_screen == "result_win", "retry button reaches Win after durable save")
	var test_runtime = bootstrap.runtime
	bootstrap.free()
	test_runtime.clear_saved_state()
	DirAccess.remove_absolute(profile)

func _reload_pending_win() -> void:
	var profile := OS.get_user_data_dir().path_join("r1_save_reload_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()])
	var bootstrap = BootstrapScene.instantiate()
	bootstrap.runtime = Runtime.new(profile)
	root.add_child(bootstrap)
	await process_frame
	bootstrap.get_node("ScreenHost/Home/SafeArea/Content/Stack/PlayButton").pressed.emit()
	await process_frame
	var blocker := profile.path_join("progress.json.tmp")
	DirAccess.make_dir_absolute(blocker)
	for row in range(4):
		bootstrap.runtime.apply_action({"type": "TryCandy", "cell": [row, [1, 3, 0, 2][row]]})
	await process_frame
	bootstrap.free()
	DirAccess.remove_absolute(blocker)
	bootstrap = BootstrapScene.instantiate()
	bootstrap.runtime = Runtime.new(profile)
	root.add_child(bootstrap)
	await process_frame
	_check(bootstrap.runtime.progress.get("currentLevelId") == "L02", "reload commits pending winning session")
	_check(bootstrap.flow.current_screen == "home", "reload remains at Home after durable commit")
	_check(not bootstrap.runtime.has_saved_session(), "old winning session is cleared after recovery")
	var test_runtime = bootstrap.runtime
	bootstrap.free()
	test_runtime.clear_saved_state()
	DirAccess.remove_absolute(profile)

func _corrupt_progress() -> void:
	var profile := OS.get_user_data_dir().path_join("r1_corrupt_progress_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()])
	var repository = load("res://scripts/save_repository.gd").new(profile)
	_check(repository.save_progress(repository.new_progress("L02")), "seed progress without backup")
	_check(repository.corrupt_for_test("progress"), "corrupt primary progress")
	var runtime = Runtime.new(profile)
	_check(not runtime.initialize(), "invalid progress blocks startup instead of creating L01")
	_check(FileAccess.get_file_as_string(profile.path_join("progress.json")) == "[]", "invalid progress is not overwritten")
	var bootstrap = BootstrapScene.instantiate()
	bootstrap.runtime = Runtime.new(profile)
	root.add_child(bootstrap)
	await process_frame
	_check(bootstrap.get_node_or_null("ScreenHost/SaveLoadError") != null, "player sees corrupt save error")
	bootstrap.free()
	repository.clear_all()
	DirAccess.remove_absolute(profile)

func _session_write_failure() -> void:
	var profile := OS.get_user_data_dir().path_join("r1_session_failure_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()])
	var bootstrap = BootstrapScene.instantiate()
	bootstrap.runtime = Runtime.new(profile)
	root.add_child(bootstrap)
	await process_frame
	bootstrap.get_node("ScreenHost/Home/SafeArea/Content/Stack/PlayButton").pressed.emit()
	await process_frame
	var blocker := profile.path_join("session.json.tmp")
	DirAccess.make_dir_absolute(blocker)
	bootstrap.runtime.apply_action({"type": "MarkX", "cell": [0, 0]})
	_check(bootstrap.get_node_or_null("SaveErrorDialog") != null, "session write error is reported")
	var board_screen = bootstrap.get_node("ScreenHost").get_child(0)
	board_screen.find_child("HomeButton", true, false).pressed.emit()
	await process_frame
	_check(bootstrap.flow.current_screen == "puzzle", "Home does not leave unsaved session")
	DirAccess.remove_absolute(blocker)
	var dialog = bootstrap.get_node_or_null("SaveErrorDialog")
	if dialog != null:
		dialog.confirmed.emit()
	_check(bootstrap.runtime.has_saved_session(), "Retry writes session after error clears")
	board_screen = bootstrap.get_node("ScreenHost").get_child(0)
	board_screen.find_child("HomeButton", true, false).pressed.emit()
	await process_frame
	_check(bootstrap.flow.current_screen == "home", "Home works after session is durable")
	var runtime = bootstrap.runtime
	bootstrap.free()
	runtime.clear_saved_state()
	DirAccess.remove_absolute(profile)

func _tutorial_progress_write_failure() -> void:
	var profile := OS.get_user_data_dir().path_join("r1_tutorial_save_failure_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()])
	var bootstrap = BootstrapScene.instantiate()
	bootstrap.runtime = Runtime.new(profile)
	root.add_child(bootstrap)
	await process_frame
	bootstrap.get_node("ScreenHost/Home/SafeArea/Content/Stack/PlayButton").pressed.emit()
	await process_frame
	var blocker := profile.path_join("progress.json.tmp")
	DirAccess.make_dir_absolute(blocker)
	bootstrap.runtime.apply_action({"type": "MarkX", "cell": [1, 1]})
	var dialog = bootstrap.get_node_or_null("SaveErrorDialog")
	_check(dialog != null and dialog.visible, "tutorial progress write failure is reported")
	DirAccess.remove_absolute(blocker)
	if dialog != null:
		dialog.confirmed.emit()
	var persisted: Dictionary = bootstrap.runtime.repository.load_progress().get("data", {})
	_check(persisted.get("tutorialState", {}).get("tutorialSeenIds", []).has("T1"), "retry persists tutorial milestone")
	var runtime = bootstrap.runtime
	bootstrap.free()
	runtime.clear_saved_state()
	DirAccess.remove_absolute(profile)

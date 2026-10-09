extends SceneTree

var _fails: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var shell = load("res://scenes/main.tscn").instantiate()
	shell.profile_dir = OS.get_user_data_dir().path_join("combo_screen_%d" % Time.get_ticks_usec())
	root.add_child(shell)
	await process_frame
	shell._on_title_play()
	var puzzle = shell.screen_host.get_child(0)
	var session = puzzle.session
	puzzle._on_board_double_tap(0, int(session.level.solution[0]))
	_assert(puzzle.combo.tracker.streak == 1, "first correct candy starts combo")
	puzzle.settings_btn.pressed.emit()
	var options = shell._options_overlay if shell._options_overlay != null else shell.screen_host.get_child(0)
	options.back_btn.pressed.emit()
	await process_frame
	puzzle = shell.screen_host.get_child(0)
	_assert(puzzle.combo.tracker.streak == 1, "visiting options keeps the combo")
	puzzle.setup(puzzle.runtime, puzzle.sfx, puzzle.config)
	_assert(puzzle.combo.tracker.streak == 1, "re-entering setup with the same session keeps the combo")
	puzzle.hint_coordinator._applying = true
	puzzle.hint_coordinator.force_release()
	_assert(not puzzle.hint_coordinator.is_applying(), "force_release clears a stuck hint flag")
	if _fails.is_empty():
		print("COMBO_SCREEN_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)

extends SceneTree

const PuzzleScreenScript = preload("res://scripts/screens/puzzle_screen.gd")

const AppShell = preload("res://scripts/screens/app_shell.gd")
const NavController = preload("res://scripts/campaign/nav_controller.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	PuzzleScreenScript.hold_results = false # result hold is covered by test_heart_feedback
	call_deferred("_run")

func _run() -> void:
	await _test_endless_flow_win_and_progression()
	await _test_endless_flow_fail_and_retry()

	if _failures.is_empty():
		print("ENDLESS_INTEGRATION_PASS")
		quit(0)
	else:
		for f in _failures:
			printerr(f)
		quit(1)

func _create_test_profile(tag: String) -> String:
	var path := OS.get_user_data_dir().path_join("test_endless_integ_%s_%s" % [tag, Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(path)
	return path

func _clean_dir(path: String) -> void:
	var da := DirAccess.open(path)
	if da != null:
		da.list_dir_begin()
		var file_name := da.get_next()
		while file_name != "":
			if not da.current_is_dir():
				da.remove(file_name)
			file_name = da.get_next()
		da.list_dir_end()
	DirAccess.remove_absolute(path)

func _test_endless_flow_win_and_progression() -> void:
	var pdir := _create_test_profile("win_prog")
	var shell: AppShell = load("res://scenes/main.tscn").instantiate()
	shell.profile_dir = pdir
	root.add_child(shell)
	await process_frame

	_assert(shell.endless_runtime != null, "endless runtime initialized in app shell")

	# 1. From Title, trigger endless
	var title_screen = shell.screen_host.get_child(0)
	_assert(title_screen != null and title_screen.name == "TitleScreen", "starts on TitleScreen")
	_assert(title_screen.endless_btn != null, "endless button exists on TitleScreen")

	title_screen._on_endless()
	_assert(shell.nav.current() == NavController.Screen.PUZZLE, "nav moved to puzzle screen for endless")
	_assert(shell._mode == "endless", "shell mode is endless")
	_assert(shell.endless_runtime.current_session != null, "endless active session started")

	var session: PlaySession = shell.endless_runtime.current_session
	_assert(session.level.get("id") == "Endless 1", "level label is Endless 1")

	# 2. Solve level
	var solution: Array = session.level["solution"]
	for r in range(solution.size()):
		var c: int = int(solution[r])
		if session.cell_at(r, c) != CellModel.CellKind.GIVEN:
			session.try_candy(r, c)

	_assert(session.phase == PlaySession.Phase.WON, "session phase is WON")
	_assert(shell.nav.current() == NavController.Screen.WIN, "nav moved to WIN screen")

	var win_screen = shell.screen_host.get_child(0)
	_assert(win_screen != null and win_screen.name == "WinScreen", "screen host holds WinScreen")
	_assert(win_screen.next_btn != null and win_screen.next_btn.visible, "next button visible on endless win")

	# 3. Next level
	win_screen._on_next()
	_assert(shell.nav.current() == NavController.Screen.PUZZLE, "nav moved to next puzzle")
	_assert(shell.endless_runtime.current_session != null, "new endless session started")
	_assert(shell.endless_runtime.progress.get_level_num() == 2, "progress advanced to Endless 2")
	_assert(shell.endless_runtime.current_level_label() == "Endless 2", "current label is Endless 2")

	root.remove_child(shell)
	shell.free()
	_clean_dir(pdir)

func _test_endless_flow_fail_and_retry() -> void:
	var pdir := _create_test_profile("fail_retry")
	var shell: AppShell = load("res://scenes/main.tscn").instantiate()
	shell.profile_dir = pdir
	root.add_child(shell)
	await process_frame

	var title_screen = shell.screen_host.get_child(0)
	title_screen._on_endless()

	var session: PlaySession = shell.endless_runtime.current_session
	var level: Dictionary = session.level
	var solution: Array = level["solution"]

	# Make 3 mistakes
	for r in range(3):
		var wrong_col: int = (int(solution[r]) + 1) % int(level["size"])
		session.try_candy(r, wrong_col)

	_assert(session.phase == PlaySession.Phase.FAILED, "session is FAILED")
	await create_timer(1.0).timeout
	_assert(shell.nav.current() == NavController.Screen.FAIL, "nav moved to FAIL screen")

	var fail_screen = shell.screen_host.get_child(0)
	_assert(fail_screen != null and fail_screen.name == "FailScreen", "FailScreen active")

	# Retry
	fail_screen._on_retry()
	_assert(shell.nav.current() == NavController.Screen.PUZZLE, "nav returned to PUZZLE")

	var retry_session: PlaySession = shell.endless_runtime.current_session
	_assert(retry_session != null, "retry session initialized")
	_assert(retry_session.phase == PlaySession.Phase.ACTIVE, "retry session active")
	_assert(retry_session.hearts == 3, "retry session has 3 hearts")

	root.remove_child(shell)
	shell.free()
	_clean_dir(pdir)

func _assert(cond: bool, label: String) -> void:
	if not cond:
		_failures.append("FAIL: " + label)

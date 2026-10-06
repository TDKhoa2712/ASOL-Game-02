extends SceneTree

const AppShell = preload("res://scripts/screens/app_shell.gd")
const PuzzleBoard = preload("res://scripts/screens/puzzle_board.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	await _test_new_level_and_resume()
	_test_wave_sizes()
	await process_frame
	if failures.is_empty(): print("BOARD_ENTRY_PASS")
	else:
		for failure in failures: printerr(failure)
	quit(0 if failures.is_empty() else 1)

func _entering(board: Control) -> bool:
	return board.has_method("is_entering") and bool(board.call("is_entering"))

func _test_new_level_and_resume() -> void:
	LayoutTokens.set_motion(true)
	var profile := OS.get_user_data_dir().path_join("test_entry_%d" % Time.get_ticks_usec())
	var shell: AppShell = load("res://scenes/main.tscn").instantiate()
	shell.profile_dir = profile
	root.add_child(shell)
	await process_frame
	shell.sfx.set_muted(true)
	shell._on_title_play()
	var puzzle = shell.screen_host.get_child(0)
	_assert(_entering(puzzle.board), "new campaign level starts the wave")
	puzzle._on_settings()
	shell._on_options_back()
	puzzle = shell.screen_host.get_child(0)
	_assert(not _entering(puzzle.board), "return from Settings skips the wave")
	puzzle._on_home()
	shell._on_title_play()
	puzzle = shell.screen_host.get_child(0)
	_assert(not _entering(puzzle.board), "unfinished level from Home skips the wave even without moves")
	puzzle._confirm_restart()
	_assert(not _entering(puzzle.board), "restart of the same level skips the wave")
	root.remove_child(shell); shell.free()
	await process_frame
	# Reboot an untouched saved round: elapsed/moves are not a new-level test.
	shell = load("res://scenes/main.tscn").instantiate()
	shell.profile_dir = profile
	root.add_child(shell)
	await process_frame
	shell.sfx.set_muted(true)
	shell._on_title_play()
	puzzle = shell.screen_host.get_child(0)
	_assert(not _entering(puzzle.board), "saved unfinished level after reboot skips the wave")
	var sess = puzzle.session
	for r in range(int(sess.level.size)):
		if sess.cell_at(r, int(sess.level.solution[r])) != CellModel.CellKind.GIVEN:
			puzzle._on_board_double_tap(r, int(sess.level.solution[r]))
	shell._on_next_level()
	puzzle = shell.screen_host.get_child(0)
	_assert(_entering(puzzle.board), "next level after a win starts another wave")
	root.remove_child(shell); shell.free()
	await process_frame
	var dir := DirAccess.open(profile)
	for file in dir.get_files(): dir.remove(file)
	DirAccess.remove_absolute(profile)

func _test_wave_sizes() -> void:
	for n in [4, 5, 6, 9]:
		var regions: Array = []; var solution: Array = []
		for r in range(n): regions.append(String.chr(65 + r).repeat(n)); solution.append(r)
		var sess := PlaySession.new({"id": "test", "size": n, "regions": regions, "solution": solution, "givens": [{"r": n - 1, "c": 0}]})
		var board := PuzzleBoard.new()
		board.size = Vector2(500, 500)
		root.add_child(board)
		board.configure(sess)
		_assert(board.has_method("play_entry_wave"), "board supports entry animation")
		if not board.has_method("play_entry_wave"):
			board.free(); continue
		board.call("play_entry_wave")
		var tapped: Array = []
		board.cell_tapped.connect(func(r: int, c: int): tapped.append([r, c]))
		var touch := InputEventScreenTouch.new()
		touch.position = board._cell_rect(n - 1, 0).get_center(); touch.pressed = true
		board._gui_input(touch)
		touch.pressed = false; board._gui_input(touch)
		board._decoder.tick(Time.get_ticks_msec() + 1000)
		_assert(tapped.is_empty(), "hidden cells cannot receive taps during entry")
		board._process(0.1)
		_assert(float(board.call("cell_entry_scale", n - 1, 0)) > 0.0, "bottom-left given appears first (%d)" % n)
		_assert(is_zero_approx(float(board.call("cell_entry_scale", 0, n - 1))), "top-right waits for the wave (%d)" % n)
		_assert(is_equal_approx(float(board.call("cell_entry_scale", n - 2, 0)), float(board.call("cell_entry_scale", n - 1, 1))), "equal distance from origin appears together")
		board._process(0.5)
		_assert(float(board.call("cell_entry_scale", 0, n - 1)) > 0.0, "wave reaches top-right on every size")
		board._process(1.0)
		_assert(not _entering(board), "entry finishes and releases input")
		touch.pressed = true; board._gui_input(touch)
		touch.pressed = false; board._gui_input(touch)
		board._decoder.tick(Time.get_ticks_msec() + 1000)
		_assert(tapped == [[n - 1, 0]], "normal taps work after entry")
		for r in range(n):
			for c in range(n): _assert(is_equal_approx(float(board.call("cell_entry_scale", r, c)), 1.0), "every cell settles at normal size")
		board.call("play_entry_wave")
		board.configure(sess)
		_assert(not _entering(board), "reconfigure cancels unfinished entry")
		LayoutTokens.set_motion(false)
		board.call("play_entry_wave")
		_assert(not _entering(board), "reduced motion shows the board immediately")
		LayoutTokens.set_motion(true)
		board.call("play_entry_wave")
		LayoutTokens.set_motion(false); board._process(0.1)
		_assert(is_equal_approx(float(board.call("cell_entry_scale", n - 1, 0)), 1.0), "enabling reduced motion mid-wave restores full cells")
		LayoutTokens.set_motion(true)
		_assert(not _entering(board), "cancelled wave does not restart when motion is re-enabled")
		board.free()

func _assert(ok: bool, message: String) -> void:
	if not ok: failures.append("FAIL: " + message)

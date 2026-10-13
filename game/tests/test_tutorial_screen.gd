extends SceneTree

const AppShell = preload("res://scripts/screens/app_shell.gd")
const PuzzleScreenScript = preload("res://scripts/screens/puzzle_screen.gd")
const NavController = preload("res://scripts/campaign/nav_controller.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _fails: Array[String] = []

func _init() -> void:
	PuzzleScreenScript.hold_results = false
	LayoutTokens.motion_enabled = false
	TranslationServer.set_locale("vi")
	await process_frame
	await _test_l01_flow()
	await _test_skip_and_tips()
	await _test_help_replay()
	if _fails.is_empty():
		print("TUTORIAL_SCREEN_PASS")
		quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _shell(tag: String) -> AppShell:
	var dir := OS.get_user_data_dir().path_join("test_tutorial_screen_%s_%s" % [tag, Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(dir)
	var shell: AppShell = load("res://scenes/main.tscn").instantiate()
	shell.profile_dir = dir
	root.add_child(shell)
	await process_frame
	return shell

func _puzzle(shell: AppShell) -> Control:
	shell.screen_host.get_child(0)._on_play()
	await process_frame
	await process_frame
	return shell.screen_host.get_child(0)

func _test_l01_flow() -> void:
	var shell := await _shell("flow")
	var puzzle := await _puzzle(shell)
	var tut: Node = puzzle.get_node_or_null("PuzzleTutorial")
	_assert(tut != null and tut.bubble != null and tut.bubble.visible, "L01 shows the coach bubble")
	if tut == null:
		shell.queue_free(); return
	var bubble_index: int = tut.bubble.get_index()
	_assert(bubble_index == puzzle.rules_card.get_index() + 1, "bubble sits right below the rule cards, not over the board")
	_assert(tut.bubble.message() == tr("tutorial.l1_0"), "intro text is localized")
	_assert(tut.bubble.mouse_filter == Control.MOUSE_FILTER_IGNORE and tut.overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE, "tutorial layers never take board input")
	tut.bubble.primary_pressed.emit()
	_assert(tut.bubble.message() == tr("tutorial.l1_1").format({"r": 1, "c": 2}), "L1-1 names row 1, column 2")
	_assert(tut.overlay.axis_rows() == [0] and tut.overlay.axis_cols() == [1], "L1-1 lights the axis numbers")
	var session: Variant = puzzle.session
	puzzle._on_board_double_tap(1, 0)
	_assert(session.hearts == 3 and session.mistake_count == 0 and session.cell_at(1, 0) == CellModel.CellKind.BLANK, "named-cell miss costs nothing")
	_assert(tut.bubble.message().begins_with(tr("tutorial.retry")), "named-cell miss re-prompts")
	puzzle._on_board_double_tap(0, 1)
	_assert(tut.overlay.faded_cells().size() == 8, "first candy shows the 8 ruled-out cells")
	_assert(tut.bubble.message() == tr("tutorial.l1_2"), "L1-2 explains the faded X's")
	tut.bubble.primary_pressed.emit()
	_assert(tut.overlay.faded_cells().is_empty() and tut.bubble.message() == tr("tutorial.l1_3").format({"r": 2, "c": 1}), "L1-3 asks for an X on row 2, column 1")
	puzzle._on_board_tap(1, 0)
	_assert(tut.bubble.message() == tr("tutorial.l1_4"), "tapping the named cell advances to clearing")
	puzzle._on_board_tap(1, 0)
	_assert(tut.bubble.message() == tr("tutorial.l1_5"), "clearing advances to the self-found S2")
	puzzle._on_board_double_tap(1, 3)
	_assert(not tut.bubble.is_showing(), "L01 lessons end after region C")
	_assert(shell.runtime.progress.current.tutorialSeenIds.has("L1-4"), "steps persist in progress")
	shell.queue_free()
	await process_frame

func _test_skip_and_tips() -> void:
	var shell := await _shell("skip")
	var puzzle := await _puzzle(shell)
	var tut: Node = puzzle.get_node("PuzzleTutorial")
	tut.bubble.primary_pressed.emit()
	tut.bubble.skip_pressed.emit()
	_assert(not tut.bubble.is_showing(), "skip hides the bubble")
	_assert(shell.runtime.progress.current.tutorialSeenIds.has("L2-2"), "skip records every step")
	var session: Variant = puzzle.session
	puzzle._on_board_double_tap(1, 0)
	_assert(session.hearts == 2, "after skip the named cell costs a heart like any other")
	_assert(tut.bubble.message() == tr("tutorial.tip_error").format({"n": 2}), "first real mistake explains the red X")
	shell.queue_free()
	await process_frame

func _test_help_replay() -> void:
	var shell := await _shell("replay")
	var title: Control = shell.screen_host.get_child(0)
	title._on_help()
	var help: Control = title._help_overlay
	_assert(help != null and help.find_child("ReplayTutorialButton", true, false) != null, "help offers replay tutorial")
	help.replay_tutorial_pressed.emit()
	await process_frame
	await process_frame
	_assert(shell.nav.current() == NavController.Screen.PUZZLE, "replay opens the puzzle")
	var puzzle: Control = shell.screen_host.get_child(0)
	var tut: Node = puzzle.get_node_or_null("PuzzleTutorial")
	_assert(tut != null and tut.bubble.message() == tr("tutorial.l1_0"), "practice starts at the intro")
	_assert(puzzle.session.protect_fn.is_valid(), "practice keeps the forgiveness rule")
	tut.bubble.primary_pressed.emit()
	_assert(shell.runtime.progress.current.tutorialSeenIds.is_empty(), "practice writes no progress")
	_assert(shell.runtime.current_level_label() == "L01" and not shell.runtime.has_pending_session(), "practice leaves the campaign untouched")
	shell.queue_free()
	await process_frame

func _assert(condition: bool, label: String) -> void:
	if not condition: _fails.append("FAIL: " + label)

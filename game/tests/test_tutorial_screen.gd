extends SceneTree

const AppShell = preload("res://scripts/screens/app_shell.gd")
const PuzzleScreenScript = preload("res://scripts/screens/puzzle_screen.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const TutorialScreen = preload("res://scripts/screens/tutorial_screen.gd")

var _fails: Array[String] = []

func _init() -> void:
	PuzzleScreenScript.hold_results = false
	TutorialScreen.step_pause = 0.0
	LayoutTokens.motion_enabled = false
	TranslationServer.set_locale("vi")
	await process_frame
	await _test_mandatory_onboarding()
	await _test_help_replay()
	await _test_pacing_and_free_play()
	if _fails.is_empty():
		print("TUTORIAL_SCREEN_PASS")
		quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _shell(tag: String, dir: String = "") -> AppShell:
	if dir.is_empty():
		dir = OS.get_user_data_dir().path_join("test_tutorial_screen_%s_%s" % [tag, Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(dir)
	var shell: AppShell = load("res://scenes/main.tscn").instantiate()
	shell.profile_dir = dir
	root.add_child(shell)
	await process_frame
	await process_frame
	return shell

func _test_mandatory_onboarding() -> void:
	var dir := OS.get_user_data_dir().path_join("test_tutorial_screen_flow_%s" % Time.get_ticks_usec())
	var shell := await _shell("flow", dir)
	var title: Control = shell.screen_host.get_child(0)
	var tut: Control = title.get_node_or_null("TutorialScreen")
	_assert(tut != null, "first launch shows the onboarding over Home")
	if tut == null:
		shell.queue_free(); return
	_assert(tut.mouse_filter == Control.MOUSE_FILTER_STOP, "onboarding blocks Home until finished")
	_assert(tut.find_child("Skip*", true, false) == null, "onboarding has no skip")
	_assert(tut.bubble_text.text == TutorialScreen.emphasize(tr("tutorial.s_place")), "step 1 text shown")
	_assert(tut.overlay.dimmed_cells(4).size() == 15, "only the first target cell is lit")
	var b: Control = tut.board
	b.cell_double_tapped.emit(2, 0)
	_assert(tut.flow.step().id == "place", "touching a dark cell does nothing")
	b.cell_double_tapped.emit(0, 1)
	_assert(tut.flow.step().id == "regions" and tut.action_button.visible, "candy placed; OK shown")
	b.cell_tapped.emit(2, 2)
	_assert(tut.flow.session.cell_at(2, 2) == 0, "OK step ignores the board")
	tut.action_button.pressed.emit()
	_assert(tut.flow.step().id == "touch" and tut.flow.session.remaining_candies() == 3, "touch rule is taught around the player's own candy")
	b.cell_swiped.emit([[0, 0], [1, 0], [1, 1], [1, 2], [0, 2]])
	_assert(tut.flow.step().id == "rowcol", "touching cells crossed")
	for cell in tut.flow.step().targets.duplicate(): b.cell_tapped.emit(cell[0], cell[1])
	b.cell_double_tapped.emit(1, 3)
	_assert(tut.flow.step().id == "hearts" and tut.hearts_row.visible, "hearts step shows the three hearts")
	tut.action_button.pressed.emit()
	_assert(tut.flow.step().id == "last" and tut.hint_button.visible and not tut.hand.visible, "last step offers a hint instead of the hand")
	_assert(tut.overlay._rings.is_empty(), "free play does not ring the answer before a hint")
	tut.hint_button.pressed.emit()
	await process_frame
	_assert(tut.hand.visible and not tut.hint_button.visible, "hint shows the hand on the answer")
	_assert(tut.overlay._rings == [[2, 0]], "hint rings only the next candy")
	b.cell_double_tapped.emit(2, 0)
	b.cell_double_tapped.emit(3, 2)
	_assert(tut.flow.step().id == "done" and tut.action_button.text == tr("tutorial.continue"), "celebration with continue")
	tut.action_button.pressed.emit()
	await process_frame
	_assert(title.get_node_or_null("TutorialScreen") == null, "continue closes the onboarding")
	_assert(shell.runtime.progress.current.tutorialSeenIds.has(TutorialScreen.DONE_ID), "completion persists")
	shell.queue_free()
	await process_frame
	var again := await _shell("again", dir)
	_assert(again.screen_host.get_child(0).get_node_or_null("TutorialScreen") == null, "onboarding never returns after it is done")
	again.queue_free()
	await process_frame

func _test_help_replay() -> void:
	var shell := await _shell("replay")
	var title: Control = shell.screen_host.get_child(0)
	title.get_node("TutorialScreen").queue_free()
	await process_frame
	title._on_help()
	title._help_overlay.replay_tutorial_pressed.emit()
	await process_frame
	var tut: Control = title.get_node_or_null("TutorialScreen")
	_assert(tut != null and tut.practice, "help replays the onboarding as practice")
	tut._finish()
	_assert(not shell.runtime.progress.current.tutorialSeenIds.has(TutorialScreen.DONE_ID), "practice writes no progress")
	shell.queue_free()
	await process_frame

func _test_pacing_and_free_play() -> void:
	var shell := await _shell("pace")
	var tut: Control = shell.screen_host.get_child(0).get_node("TutorialScreen")
	var b: Control = tut.board
	TutorialScreen.step_pause = 0.3
	b.cell_double_tapped.emit(0, 1)
	_assert(tut.flow.step().id == "regions" and tut._busy and not tut.action_button.visible, "finished step is held before the next appears")
	b.cell_tapped.emit(0, 0)
	_assert(tut.flow.session.cell_at(0, 0) == 0, "input is locked during the pause")
	await create_timer(0.8).timeout
	_assert(not tut._busy and tut.action_button.visible and tut.bubble_text.text == TutorialScreen.emphasize(tr("tutorial.s_regions")), "next step fades in after the pause")
	TutorialScreen.step_pause = 0.0
	tut.action_button.pressed.emit()
	b.cell_swiped.emit([[0, 0], [1, 0], [1, 1], [1, 2], [0, 2]])
	for cell in tut.flow.step().targets.duplicate(): b.cell_tapped.emit(cell[0], cell[1])
	b.cell_double_tapped.emit(1, 3)
	tut.action_button.pressed.emit()
	_assert(tut.flow.step().id == "last", "reached free play")
	b.cell_tapped.emit(3, 0)
	_assert(tut.flow.session.cell_at(3, 0) == 1, "free play: any empty cell can be crossed")
	b.cell_double_tapped.emit(3, 0)
	_assert(tut.bubble_text.text == TutorialScreen.emphasize(tr("tutorial.s_miss")) and tut.flow.session.mistake_count == 0, "free play: wrong candy gets a gentle note, no penalty")
	shell.queue_free()
	await process_frame

func _assert(condition: bool, label: String) -> void:
	if not condition: _fails.append("FAIL: " + label)

extends SceneTree

const PuzzleScreen = preload("res://scripts/screens/puzzle_screen.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const SfxPlayer = preload("res://scripts/feedback/sfx_player.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	LayoutTokens.set_motion(true)
	await _test_release_keeps_preview_feedback(false)
	await _test_release_keeps_preview_feedback(true)
	_test_mixed_stroke_skips_unchanged_cells()
	await _test_cancel_and_direct_commit()
	LayoutTokens.set_motion(false)
	await _test_release_keeps_preview_feedback(false)
	LayoutTokens.set_motion(true)
	await _wait_ms(100)
	if failures.is_empty():
		print("STROKE_FEEDBACK_PASS")
		quit(0)
	else:
		for failure in failures: printerr(failure)
		quit(1)

func _screen() -> PuzzleScreen:
	var player := SfxPlayer.new()
	root.add_child(player)
	var screen := PuzzleScreen.new()
	root.add_child(screen)
	screen.sfx = player
	screen._is_custom = true
	screen.session = PlaySession.new({
		"id": "L01", "size": 4, "regions": ["AABB", "ABBB", "CCBB", "CCDB"],
		"solution": [1, 3, 0, 2], "givens": []})
	screen.board.configure(screen.session)
	return screen

func _dispose(screen: PuzzleScreen) -> void:
	screen.sfx.set_muted(true)
	screen.sfx.free()
	screen.free()

func _wait_ms(duration: int) -> void:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < duration: await process_frame

func _test_release_keeps_preview_feedback(clear_mark: bool) -> void:
	var screen := _screen()
	var board = screen.board
	if clear_mark: screen.session.mark_stroke([[2, 0], [2, 1], [2, 2]], true)
	var changes := [0]
	screen.session.state_changed.connect(func(): changes[0] += 1)
	board._decoder.begin(2, 0, Time.get_ticks_msec())
	board._decoder.move(2, 2)
	_check(screen.sfx._pool_idx == 3, "drag emits one cue per changed cell")
	_check(changes[0] == 0, "preview does not commit session")
	var tweens: Dictionary = board._mark_tweens.duplicate()
	board._decoder.move(2, 0)
	_check(screen.sfx._pool_idx == 3, "revisiting cells does not replay sound")
	for key in tweens:
		_check(board._mark_tweens.get(key) == tweens[key], "revisiting keeps original animation")
	# Release after the audio limit and all preview animations have finished.
	# Checking only active tweens would miss replay on a long stroke.
	await _wait_ms(300)
	_check(board._mark_tweens.is_empty(), "preview animations finish before release")
	var voices_before: int = screen.sfx._pool_idx
	board._decoder.finish(Time.get_ticks_msec())
	_check(screen.sfx._pool_idx == voices_before, "release does not replay stroke sound")
	_check(board._mark_tweens.is_empty(), "release does not restart finished animations")
	_check(changes[0] == 1, "release commits exactly one transaction")
	_check(board._preview_cells.is_empty(), "release clears preview")
	for col in range(3):
		_check(screen.session.cell_at(2, col) == (CellModel.CellKind.BLANK if clear_mark else CellModel.CellKind.MARK), "release commits stroke state")
	_check(screen.session.undo_mark(), "batch can be undone once")
	for col in range(3):
		_check(screen.session.cell_at(2, col) == (CellModel.CellKind.MARK if clear_mark else CellModel.CellKind.BLANK), "undo restores complete batch")
	_check(not screen.session.undo_mark(), "batch has only one undo transaction")
	_dispose(screen)

func _test_mixed_stroke_skips_unchanged_cells() -> void:
	var screen := _screen()
	screen.session.mark_x(2, 1)
	screen.session.board[2][3] = CellModel.CellKind.ERROR
	var board = screen.board
	board._decoder.begin(2, 0, Time.get_ticks_msec())
	board._decoder.move(2, 3)
	_check(screen.sfx._pool_idx == 2, "paint skips feedback on existing X and error")
	_check(not board.has_mark_anim(2, 1), "existing X does not animate again")
	var original: Dictionary = board._mark_tweens.duplicate()
	board._decoder.finish(Time.get_ticks_msec())
	for key in original:
		_check(board._mark_tweens.get(key) == original[key], "quick release preserves running animation")
	_check(screen.sfx._pool_idx == 2, "quick release adds no cue")
	screen.session.undo_mark()
	_check(screen.session.cell_at(2, 1) == CellModel.CellKind.MARK, "undo preserves preexisting X")
	_check(screen.session.cell_at(2, 3) == CellModel.CellKind.ERROR, "stroke preserves error cell")
	# Clearing a mixed row emits feedback only for its existing X.
	board._decoder.begin(2, 1, Time.get_ticks_msec())
	board._decoder.move(2, 3)
	_check(screen.sfx._pool_idx == 3, "clear skips feedback on blank and error")
	board._decoder.finish(Time.get_ticks_msec())
	_check(screen.sfx._pool_idx == 3, "clear release adds no cue")
	_dispose(screen)

func _test_cancel_and_direct_commit() -> void:
	var screen := _screen()
	var board = screen.board
	board._decoder.begin(2, 0, Time.get_ticks_msec())
	board._decoder.move(2, 2)
	board.settle_input()
	_check(screen.session.cell_at(2, 0) == CellModel.CellKind.BLANK, "cancel does not commit preview")
	_check(board._stroke_visited.is_empty(), "cancel clears stroke feedback history")
	# Direct semantic batches have no preview and still need feedback.
	await _wait_ms(110)
	var before: int = screen.sfx._pool_idx
	screen._on_board_swipe([[3, 0], [3, 1]])
	_check(screen.sfx._pool_idx == (before + 1) % SfxPlayer.POOL_SIZE, "direct batch retains sound")
	_check(board.has_mark_anim(3, 0) and board.has_mark_anim(3, 1), "direct batch retains animations")
	_dispose(screen)

func _check(ok: bool, label: String) -> void:
	if not ok: failures.append("FAIL: " + label)

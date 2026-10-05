extends SceneTree

const PuzzleBoard = preload("res://scripts/screens/puzzle_board.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_drag_threshold_previews_origin_immediately()
	_test_threshold_drag_commits_single_cell_stroke()
	_test_diagonal_drag_previews_full_path()
	_test_mouse_drag_uses_same_threshold()
	_test_second_touch_drag_preserves_first_tap()
	if _fails.is_empty():
		print("INPUT_TOUCH_GUARD_INTEGRATION_PASS")
		quit(0)
	else:
		for failure in _fails:
			printerr(failure)
		quit(1)

func _sample_level() -> Dictionary:
	return {
		"size": 4,
		"regions": ["AABB", "ABBB", "CCBB", "CCDB"],
		"solution": [1, 3, 0, 2],
		"givens": [{"r": 0, "c": 1}],
		"id": "touch-guard-integration",
		"hash": "touch_guard_integration_hash",
	}

func _configured_board() -> PuzzleBoard:
	var board := PuzzleBoard.new()
	board.size = Vector2(400, 400)
	root.add_child(board)
	board.configure(PlaySession.new(_sample_level()))
	return board

func _cell_center(board: PuzzleBoard, row: int, col: int) -> Vector2:
	var br := board._board_rect()
	var gap := board._cell_gap(br.size.x)
	var cell_size := (br.size.x - gap * 3.0) / 4.0
	return br.position + Vector2(
		(float(col) + 0.5) * (cell_size + gap),
		(float(row) + 0.5) * (cell_size + gap))

func _screen_press(board: PuzzleBoard, pos: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.pressed = true
	press.position = pos
	board._gui_input(press)

func _screen_release(board: PuzzleBoard, pos: Vector2) -> void:
	var release := InputEventScreenTouch.new()
	release.pressed = false
	release.position = pos
	board._gui_input(release)

func _screen_drag(board: PuzzleBoard, pos: Vector2) -> void:
	var drag := InputEventScreenDrag.new()
	drag.position = pos
	board._gui_input(drag)

func _test_drag_threshold_previews_origin_immediately() -> void:
	var board := _configured_board()
	var origin := _cell_center(board, 0, 0)
	_screen_press(board, origin)
	_screen_drag(board, origin + Vector2(13, 0))
	_assert(board._preview_cells == [[0, 0]], "13px drag previews origin without waiting for another cell")
	board.free()

func _test_threshold_drag_commits_single_cell_stroke() -> void:
	var board := _configured_board()
	var swipes: Array = []
	var taps: Array = []
	board.cell_swiped.connect(func(cells: Array): swipes.append(cells))
	board.cell_tapped.connect(func(row: int, col: int): taps.append([row, col]))
	var origin := _cell_center(board, 0, 0)
	_screen_press(board, origin)
	_screen_drag(board, origin + Vector2(13, 0))
	_screen_release(board, origin + Vector2(13, 0))
	board._decoder.tick(Time.get_ticks_msec() + 400)
	_assert(swipes == [[[0, 0]]], "threshold drag commits one-cell stroke immediately on release")
	_assert(taps.is_empty(), "threshold drag never falls back to delayed tap")
	board.free()

func _test_diagonal_drag_previews_full_path() -> void:
	var board := _configured_board()
	var origin := _cell_center(board, 0, 0)
	_screen_press(board, origin)
	_screen_drag(board, _cell_center(board, 2, 2))
	_assert(board._preview_cells == [[0, 0], [1, 1], [2, 2]], "diagonal batch drag previews interpolated cells")
	board.free()

func _test_mouse_drag_uses_same_threshold() -> void:
	var board := _configured_board()
	var origin := _cell_center(board, 0, 0)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = origin
	board._gui_input(press)
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.position = origin + Vector2(13, 0)
	board._gui_input(motion)
	_assert(board._preview_cells == [[0, 0]], "mouse drag previews at the same 12px threshold")
	board.free()

func _test_second_touch_drag_preserves_first_tap() -> void:
	var board := _configured_board()
	var taps: Array = []
	board.cell_tapped.connect(func(row: int, col: int): taps.append([row, col]))
	var origin := _cell_center(board, 0, 0)
	board._decoder.begin(0, 0, 1000)
	board._decoder.finish(1010)
	board._decoder.begin(0, 0, 1100)
	board._guard.start_touch(origin, 1100)
	var verdict: Dictionary = board._guard.filter_move(origin + Vector2(13, 0), 1116)
	if verdict.get("drag_just_started", false) and board._decoder.has_method("start_drag"):
		board._decoder.start_drag()
	board._decoder.move(0, 1)
	_assert(taps == [[0, 0]], "second-touch drag commits first pending tap")
	board.free()

func _assert(condition: bool, label: String) -> void:
	if not condition:
		_fails.append("FAIL: " + label)

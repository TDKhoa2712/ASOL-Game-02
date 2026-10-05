extends SceneTree

const PuzzleBoard = preload("res://scripts/screens/puzzle_board.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_speed_locked_screen_drag_is_not_forwarded()
	_test_speed_locked_mouse_motion_is_not_forwarded()
	_test_rejected_fast_drag_does_not_become_tap()
	_test_rejected_second_touch_preserves_first_tap()
	_test_horizontal_lock_keeps_stroke_in_start_row()
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

func _test_speed_locked_screen_drag_is_not_forwarded() -> void:
	var board := _configured_board()
	var guard: Variant = board.get("_guard")
	_assert(guard != null, "board creates touch guard")
	if guard == null:
		board.free()
		return

	var br := board._board_rect()
	var origin := br.position + Vector2(20, 20)
	board._decoder.begin(0, 0, 1000)
	board._decoder.move(0, 1)
	guard.start_touch(origin, 1000)
	guard.filter_move(origin + Vector2(300, 0), 1100)
	var drag := InputEventScreenDrag.new()
	drag.position = br.position + Vector2(br.size.x * 0.65, 20)
	board._gui_input(drag)
	_assert(board._preview_cells.is_empty(), "speed-locked screen drag is not forwarded")
	board.free()

func _test_speed_locked_mouse_motion_is_not_forwarded() -> void:
	var board := _configured_board()
	var guard: Variant = board.get("_guard")
	_assert(guard != null, "board creates touch guard for mouse input")
	if guard == null:
		board.free()
		return

	var br := board._board_rect()
	var origin := br.position + Vector2(20, 20)
	board._decoder.begin(0, 0, 1000)
	board._decoder.move(0, 1)
	guard.start_touch(origin, 1000)
	guard.filter_move(origin + Vector2(300, 0), 1100)
	var motion := InputEventMouseMotion.new()
	motion.position = br.position + Vector2(br.size.x * 0.65, 20)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	board._gui_input(motion)
	_assert(board._preview_cells.is_empty(), "speed-locked mouse motion is not forwarded")
	board.free()

func _test_rejected_fast_drag_does_not_become_tap() -> void:
	var board := _configured_board()
	var taps: Array = []
	board.cell_tapped.connect(func(row: int, col: int): taps.append([row, col]))
	var br := board._board_rect()
	var origin := br.position + Vector2(20, 20)
	var now := Time.get_ticks_msec()
	board._decoder.begin(0, 0, now)
	board._guard.start_touch(origin, now - 100)
	board._guard.filter_move(origin + Vector2(300, 0), now)
	var drag := InputEventScreenDrag.new()
	drag.position = br.position + Vector2(br.size.x * 0.65, 20)
	board._gui_input(drag)
	var release := InputEventScreenTouch.new()
	release.pressed = false
	release.position = drag.position
	board._gui_input(release)
	board._decoder.tick(Time.get_ticks_msec() + 400)
	_assert(taps.is_empty(), "rejected fast drag never becomes a tap")
	board.free()

func _test_rejected_second_touch_preserves_first_tap() -> void:
	var board := _configured_board()
	var taps: Array = []
	board.cell_tapped.connect(func(row: int, col: int): taps.append([row, col]))
	var br := board._board_rect()
	var origin := br.position + Vector2(20, 20)
	board._decoder.begin(0, 0, 1000)
	board._decoder.finish(1010)
	board._decoder.begin(0, 0, 1100)
	board._guard.start_touch(origin, 1000)
	board._guard.filter_move(origin + Vector2(300, 0), 1100)
	var drag := InputEventScreenDrag.new()
	drag.position = br.position + Vector2(br.size.x * 0.65, 20)
	board._gui_input(drag)
	_assert(taps == [[0, 0]], "rejected second touch commits the first pending tap")
	board.free()

func _test_horizontal_lock_keeps_stroke_in_start_row() -> void:
	var board := _configured_board()
	var br := board._board_rect()
	var gap := board._cell_gap(br.size.x)
	var cell_size := (br.size.x - gap * 3.0) / 4.0
	var step := cell_size + gap
	var origin := br.position + Vector2(cell_size * 0.5, cell_size - 1.0)
	var now := Time.get_ticks_msec()
	board._decoder.begin(0, 0, now - 1000)
	board._guard.start_touch(origin, now - 1000)
	board._guard.filter_move(origin + Vector2(20, 1), now - 500)
	var drag := InputEventScreenDrag.new()
	drag.position = origin + Vector2(step * 2.0, 10)
	board._gui_input(drag)
	_assert(not board._preview_cells.is_empty(), "horizontal locked drag produces preview")
	for cell in board._preview_cells:
		_assert(cell[0] == 0, "horizontal lock keeps every preview cell in start row")
	board.free()

func _assert(condition: bool, label: String) -> void:
	if not condition:
		_fails.append("FAIL: " + label)

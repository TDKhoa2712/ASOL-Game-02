extends SceneTree

const PuzzleBoard = preload("res://scripts/screens/puzzle_board.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_speed_locked_screen_drag_is_not_forwarded()
	_test_speed_locked_mouse_motion_is_not_forwarded()
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
	guard.start_touch(origin, 1000)
	guard.filter_move(origin + Vector2(300, 0), 1100)
	var motion := InputEventMouseMotion.new()
	motion.position = br.position + Vector2(br.size.x * 0.65, 20)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	board._gui_input(motion)
	_assert(board._preview_cells.is_empty(), "speed-locked mouse motion is not forwarded")
	board.free()

func _assert(condition: bool, label: String) -> void:
	if not condition:
		_fails.append("FAIL: " + label)

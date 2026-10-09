# game/tests/test_board_candy_anim.gd
extends SceneTree

const PuzzleBoard = preload("res://scripts/screens/puzzle_board.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _fails: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)

func _level() -> Dictionary:
	return {"id": "T04", "size": 4, "regions": ["AABB", "AABB", "CCDD", "CCDD"], "solution": [1, 3, 0, 2], "givens": [{"r": 0, "c": 1}]}

func _run() -> void:
	LayoutTokens.motion_enabled = true
	var board := PuzzleBoard.new()
	board.size = Vector2(400, 400)
	root.add_child(board)
	board.configure(PlaySession.new(_level()))
	await process_frame
	_assert(board.candy_frame(0, 1) == ["idle", 0], "given candy synced at idle rest without appear")
	board.play_candy_pop(1, 3)
	_assert(board.candy_frame(1, 3)[0] == "appear", "placed candy plays appear")
	board.play_sad()
	_assert(board.candy_frame(0, 1)[0] == "sad", "fail makes every candy sad")
	board.configure(PlaySession.new(_level()))
	_assert(board.candy_frame(0, 1) == ["idle", 0], "reconfigure resets to idle")
	if _fails.is_empty():
		print("BOARD_CANDY_ANIM_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

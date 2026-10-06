extends SceneTree

const CandyRenderer = preload("res://scripts/core/candy_renderer.gd")
const PuzzleBoard = preload("res://scripts/screens/puzzle_board.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")

var _fails: Array[String] = []

func _init() -> void:
	for pair in [["L01", "bonbon"], ["L06", "lollipop"], ["L11", "gummy_drop"], ["L16", "hard_candy"], ["L21", "toffee"], ["L26", "cotton_puff"], ["L99", "bonbon"]]:
		var board := PuzzleBoard.new()
		board.configure(PlaySession.new(_level(pair[0])))
		if board._candy_tex != CandyRenderer.texture_for_type(pair[1]):
			_fails.append("board texture mismatch for %s" % pair[0])
		board.free()
	if _fails.is_empty():
		print("CANDY_BOARD_PASS")
		quit(0)
	else:
		for failure in _fails:
			printerr(failure)
		quit(1)

func _level(label: String) -> Dictionary:
	return {"id": label, "size": 4, "regions": ["AABB", "ABBB", "CCBB", "CCDB"], "solution": [1, 3, 0, 2], "givens": [{"r": 0, "c": 1}], "hash": "test_candy_board"}

# game/tests/test_cell_animator.gd
extends SceneTree

const CellAnimator = preload("res://scripts/screens/cell_animator.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_play_candy_pop()
	_test_play_error_shake()
	_test_play_win_bounce()
	_test_mark_textures_cached()
	if _fails.is_empty():
		print("SCREENS_CELL_ANIMATOR_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_play_candy_pop() -> void:
	var board := Control.new()
	root.add_child(board)
	CellAnimator.play_candy_pop(board, Rect2(10, 10, 50, 50))
	_assert(board.get_child_count() == 1, "candy pop creates dummy node")
	board.queue_free()

func _test_play_error_shake() -> void:
	var board := Control.new()
	root.add_child(board)
	CellAnimator.play_error_shake(board)
	_assert(board != null, "error shake executes cleanly")
	board.queue_free()

func _test_play_win_bounce() -> void:
	var board := Control.new()
	root.add_child(board)
	var mock_session := {
		"level": {"size": 2},
		"board": [
			[CellModel.CellKind.CANDY, CellModel.CellKind.BLANK],
			[CellModel.CellKind.BLANK, CellModel.CellKind.CANDY]
		]
	}
	var cell_rect_fn := func(r: int, c: int) -> Rect2:
		return Rect2(r * 40, c * 40, 30, 30)
	CellAnimator.play_win_bounce(board, mock_session, cell_rect_fn)
	_assert(board.get_child_count() == 2, "win bounce creates dummies for placed candies")
	board.queue_free()

func _test_mark_textures_cached() -> void:
	var t_white := CellAnimator.get_mark_texture(false, false)
	_assert(t_white != null, "white mark texture created")
	_assert(t_white.get_width() >= 64 and t_white.get_height() >= 64, "white texture has valid dimensions")
	var t_white_2 := CellAnimator.get_mark_texture(false, false)
	_assert(t_white == t_white_2, "mark texture is cached")

	var t_hc := CellAnimator.get_mark_texture(false, true)
	_assert(t_hc != null and t_hc != t_white, "high contrast texture is distinct")

	var t_err := CellAnimator.get_mark_texture(true, false)
	_assert(t_err != null and t_err != t_white, "error mark texture is distinct")

func _assert(condition: bool, label: String) -> void:
	if not condition:
		_fails.append("FAIL: " + label)

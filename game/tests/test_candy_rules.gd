extends SceneTree

const CellModel = preload("res://scripts/core/cell_model.gd")
const CandyRules = preload("res://scripts/core/candy_rules.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_cell_model()
	_test_cell_model_immutable()
	_test_detect_clash()
	_test_can_place()
	_test_attempt_candy_correct()
	_test_attempt_candy_wrong()
	_test_attempt_candy_win()
	_test_attempt_candy_last_heart()
	_test_tally()
	_test_verify_level()
	if _fails.is_empty():
		print("CORE_CANDY_RULES_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_cell_model() -> void:
	_assert(CellModel.is_empty(CellModel.CellKind.BLANK), "blank is empty")
	_assert(not CellModel.is_empty(CellModel.CellKind.CANDY), "candy not empty")
	_assert(not CellModel.is_empty(CellModel.CellKind.MARK), "mark not empty")
	_assert(CellModel.is_placed(CellModel.CellKind.CANDY), "candy is placed")
	_assert(CellModel.is_placed(CellModel.CellKind.GIVEN), "given is placed")
	_assert(CellModel.label(CellModel.CellKind.ERROR) == "error", "error label")

func _test_cell_model_immutable() -> void:
	_assert(CellModel.is_locked(CellModel.CellKind.GIVEN), "given is locked")
	_assert(not CellModel.is_available(CellModel.CellKind.GIVEN), "given not available")
	_assert(not CellModel.is_available(CellModel.CellKind.ERROR), "error not available")
	_assert(CellModel.is_available(CellModel.CellKind.BLANK), "blank is available")
	_assert(CellModel.is_available(CellModel.CellKind.MARK), "mark is available")
	_assert(CellModel.is_cross(CellModel.CellKind.ERROR), "error is cross")
	_assert(CellModel.is_candy(CellModel.CellKind.GIVEN), "given is candy")

func _test_detect_clash() -> void:
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var board := _empty_board(4)
	board[0][0] = CellModel.CellKind.CANDY
	board[0][2] = CellModel.CellKind.CANDY
	_assert(CandyRules.detect_clash(regions, board, [0, 0], [0, 2]) == CandyRules.Clash.SAME_ROW, "same row")
	board = _empty_board(4)
	board[0][0] = CellModel.CellKind.CANDY
	_assert(CandyRules.detect_clash(regions, board, [0, 0], [2, 0]) == CandyRules.Clash.SAME_COL, "same col")
	_assert(CandyRules.detect_clash(regions, board, [0, 0], [1, 1]) == CandyRules.Clash.TOUCHING, "diagonal")
	_assert(CandyRules.detect_clash(regions, board, [0, 0], [2, 2]) == CandyRules.Clash.NONE, "no clash")

func _test_can_place() -> void:
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var board := _empty_board(4)
	_assert(CandyRules.can_place(board, regions, 0, 1), "empty cell can place")
	board[0][1] = CellModel.CellKind.CANDY
	_assert(not CandyRules.can_place(board, regions, 0, 2), "same row blocked")
	_assert(not CandyRules.can_place(board, regions, 1, 1), "same col blocked")
	_assert(not CandyRules.can_place(board, regions, 1, 0), "adjacent blocked")

func _test_attempt_candy_correct() -> void:
	var level := _make_level_4x4()
	var board := _empty_board(4)
	# solution[0] == 1, so placing at (0, 1) is correct
	var result := CandyRules.attempt_candy(board, level["regions"], level["solution"], 3, 0, 0, 1)
	_assert("CandyFound" in str(result["events"]), "correct placement event")
	_assert(result["phase"] == "active", "still active")
	_assert(result.keys().size() == 6, "placement has only gameplay fields")
	_assert(board[0][0] == CellModel.CellKind.BLANK, "same row remains blank")
	_assert(board[1][1] == CellModel.CellKind.BLANK, "same column remains blank")

func _test_attempt_candy_wrong() -> void:
	var level := _make_level_4x4()
	var board := _empty_board(4)
	# solution[0] == 1, so placing at (0, 0) is wrong
	var result := CandyRules.attempt_candy(board, level["regions"], level["solution"], 3, 0, 0, 0)
	_assert("Mistake" in str(result["events"]), "wrong placement event")
	_assert(result["hearts"] == 2, "lost a heart")
	_assert(result["reason"] != "", "has reason")
	_assert(board[0][0] == CellModel.CellKind.ERROR, "mistake is permanent error")

func _test_attempt_candy_win() -> void:
	var level := _make_level_4x4()
	var board := _empty_board(4)
	for row in range(3):
		board[row][level["solution"][row]] = CellModel.CellKind.CANDY
	var result := CandyRules.attempt_candy(board, level["regions"], level["solution"], 3, 0, 3, level["solution"][3])
	_assert(result["phase"] == "won", "level won")

func _test_attempt_candy_last_heart() -> void:
	var level := _make_level_4x4()
	var board := _empty_board(4)
	# solution[0] == 1, placing at (0, 0) is wrong with 1 heart left
	var result := CandyRules.attempt_candy(board, level["regions"], level["solution"], 1, 2, 0, 0)
	_assert(result["phase"] == "failed", "game over on last heart")

func _test_tally() -> void:
	_assert(CandyRules.tally(4, 0) == 400, "perfect score")
	_assert(CandyRules.tally(4, 2) == 350, "score with mistakes")
	_assert(CandyRules.tally(0, 10) == 0, "no negative score")

func _test_verify_level() -> void:
	_assert(CandyRules.verify_level(_make_level_4x4()), "valid level passes")

func _make_level_4x4() -> Dictionary:
	return {
		"size": 4,
		"regions": ["AABB", "ABBB", "CCBB", "CCDB"],
		"solution": [1, 3, 0, 2],
		"givens": []
	}

func _empty_board(size: int) -> Array:
	var board: Array = []
	for r in range(size):
		var row: Array = []
		for c in range(size):
			row.append(CellModel.CellKind.BLANK)
		board.append(row)
	return board

func _assert(condition: bool, label: String) -> void:
	if not condition:
		_fails.append("FAIL: " + label)

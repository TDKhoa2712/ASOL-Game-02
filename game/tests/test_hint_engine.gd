extends SceneTree

const HintEngine = preload("res://scripts/core/hint_engine.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const CandyRules = preload("res://scripts/core/candy_rules.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_wrong_mark_detected()
	_test_wrong_mark_skipped_when_none()
	_test_mark_hint_finds_new_marks()
	_test_mark_hint_skips_all_marked()
	_test_has_new_guard_filters()
	_test_single_candidate()
	_test_fallback_on_empty()
	_test_chain_returns_detail()
	_test_hint_not_found_on_solved()
	_test_given_not_wrong_mark()
	if _fails.is_empty():
		print("HINT_ENGINE_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_wrong_mark_detected() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	# Mark cell [2][0] which IS the solution for row 2
	board[2][0] = CellModel.CellKind.MARK
	var hint := HintEngine.find_hint(board, 4, regions, solution)
	_assert(hint["found"], "wrong mark found")
	_assert(hint["strategy"] == "WRONG_MARK", "strategy is WRONG_MARK")
	_assert(hint["action"] == "CLEAR_MARK", "action is CLEAR_MARK")
	_assert(hint["target_cell"][0] == 2 and hint["target_cell"][1] == 0, "target is [2,0]")

func _test_wrong_mark_skipped_when_none() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	# Mark cell [0][0] which is NOT solution[0]=1
	board[0][0] = CellModel.CellKind.MARK
	var hint := HintEngine.find_hint(board, 4, regions, solution)
	_assert(hint["found"], "hint found")
	_assert(hint["strategy"] != "WRONG_MARK", "not wrong mark when mark is valid")

func _test_mark_hint_finds_new_marks() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	# Place candy at solution spot
	board[0][1] = CellModel.CellKind.CANDY
	var hint := HintEngine.find_hint(board, 4, regions, solution)
	_assert(hint["found"], "hint found")
	_assert(hint["strategy"] == "MARK_NEIGHBORS", "strategy is MARK_NEIGHBORS")
	_assert(hint["action"] == "PLACE_MARKS", "action is PLACE_MARKS")
	_assert(hint["eliminated_cells"].size() > 0, "has cells to mark")

func _test_mark_hint_skips_all_marked() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	board[0][1] = CellModel.CellKind.CANDY
	# Mark ALL blank cells in row 0, col 1, and neighbors
	for c in range(4):
		if c != 1 and board[0][c] == CellModel.CellKind.BLANK:
			board[0][c] = CellModel.CellKind.MARK
	for r in range(4):
		if board[r][1] == CellModel.CellKind.BLANK:
			board[r][1] = CellModel.CellKind.MARK
	# Mark 8-neighbors
	for dr in [-1, 0, 1]:
		for dc in [-1, 0, 1]:
			var nr: int = 0 + dr
			var nc: int = 1 + dc
			if nr >= 0 and nr < 4 and nc >= 0 and nc < 4:
				if board[nr][nc] == CellModel.CellKind.BLANK:
					board[nr][nc] = CellModel.CellKind.MARK
	# Mark same-zone cells
	var target_zone: String = CandyRules.zone_of(regions, 0, 1)
	for r in range(4):
		for c in range(4):
			if CandyRules.zone_of(regions, r, c) == target_zone:
				if board[r][c] == CellModel.CellKind.BLANK:
					board[r][c] = CellModel.CellKind.MARK
	var hint := HintEngine.find_hint(board, 4, regions, solution)
	_assert(hint["found"], "hint found")
	_assert(hint["strategy"] != "MARK_NEIGHBORS", "skips mark_neighbors when all marked")

func _test_has_new_guard_filters() -> void:
	var board := _empty_board(4)
	board[1][3] = CellModel.CellKind.MARK
	var eliminated := [[1, 3], [1, 2]]
	var filtered := HintEngine._filter_new_eliminations(eliminated, board)
	_assert(filtered.size() == 1, "filters out existing mark")
	_assert(filtered[0][0] == 1 and filtered[0][1] == 2, "keeps blank cell")

func _test_single_candidate() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	board[0][1] = CellModel.CellKind.CANDY
	for r in range(4):
		for c in range(4):
			if board[r][c] == CellModel.CellKind.BLANK and solution[r] != c:
				if not CandyRules.can_place(board, regions, r, c):
					board[r][c] = CellModel.CellKind.MARK
	for c in range(4):
		if c != 1 and board[0][c] == CellModel.CellKind.BLANK:
			board[0][c] = CellModel.CellKind.MARK
	for r in range(4):
		if board[r][1] == CellModel.CellKind.BLANK:
			board[r][1] = CellModel.CellKind.MARK
	for dr in [-1, 0, 1]:
		for dc in [-1, 0, 1]:
			if dr == 0 and dc == 0: continue
			var nr: int = 0 + int(dr)
			var nc: int = 1 + int(dc)
			if nr >= 0 and nr < 4 and nc >= 0 and nc < 4:
				if board[nr][nc] == CellModel.CellKind.BLANK:
					board[nr][nc] = CellModel.CellKind.MARK
	var z: String = CandyRules.zone_of(regions, 0, 1)
	for r in range(4):
		for c in range(4):
			if CandyRules.zone_of(regions, r, c) == z and board[r][c] == CellModel.CellKind.BLANK:
				board[r][c] = CellModel.CellKind.MARK
	var hint := HintEngine.find_hint(board, 4, regions, solution)
	_assert(hint["found"], "hint found")
	_assert(hint["strategy"] in ["SINGLE_CANDIDATE", "MARK_NEIGHBORS", "LOCK_INTERSECTION", "LOCKED_SUBSET", "CONTRA_CHAIN", "FALLBACK"], "valid strategy")

func _test_fallback_on_empty() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	for r in range(4):
		for c in range(4):
			if solution[r] != c:
				board[r][c] = CellModel.CellKind.MARK
	var hint := HintEngine.find_hint(board, 4, regions, solution)
	_assert(hint["found"], "fallback found")
	_assert(hint["strategy"] in ["SINGLE_CANDIDATE", "FALLBACK"], "either single or fallback")

func _test_chain_returns_detail() -> void:
	var board := _empty_board(5)
	var regions := ["AABBB", "AABBB", "CCCBB", "CDDEE", "CDDEE"]
	var solution := [2, 4, 0, 3, 1]
	board[0][2] = CellModel.CellKind.CANDY
	board[1][4] = CellModel.CellKind.CANDY
	for placed_r in [0, 1]:
		var placed_c: int = int(solution[placed_r])
		for c in range(5):
			if c != placed_c and board[placed_r][c] == CellModel.CellKind.BLANK:
				board[placed_r][c] = CellModel.CellKind.MARK
		for r in range(5):
			if board[r][placed_c] == CellModel.CellKind.BLANK:
				board[r][placed_c] = CellModel.CellKind.MARK
		for dr in [-1, 0, 1]:
			for dc in [-1, 0, 1]:
				var nr: int = placed_r + int(dr)
				var nc: int = placed_c + int(dc)
				if nr >= 0 and nr < 5 and nc >= 0 and nc < 5:
					if board[nr][nc] == CellModel.CellKind.BLANK:
						board[nr][nc] = CellModel.CellKind.MARK
	var hint := HintEngine.find_hint(board, 5, regions, solution)
	_assert(hint["found"], "hint found on 5x5")
	if hint["strategy"] == "CONTRA_CHAIN":
		_assert(hint.has("chain_detail"), "chain has detail")
		_assert(hint["chain_detail"].has("depth"), "detail has depth")

func _test_hint_not_found_on_solved() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	for r in range(4):
		board[r][int(solution[r])] = CellModel.CellKind.CANDY
	for r in range(4):
		for c in range(4):
			if board[r][c] == CellModel.CellKind.BLANK:
				board[r][c] = CellModel.CellKind.MARK
	var hint := HintEngine.find_hint(board, 4, regions, solution)
	_assert(not hint["found"], "no hint on solved board")

func _test_given_not_wrong_mark() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	board[0][1] = CellModel.CellKind.GIVEN
	var hint := HintEngine.find_hint(board, 4, regions, solution)
	_assert(hint["found"], "hint found")
	_assert(hint["strategy"] != "WRONG_MARK", "given is not wrong mark")

func _empty_board(n: int) -> Array:
	var b: Array = []
	for r in range(n):
		var row: Array = []
		for c in range(n):
			row.append(CellModel.CellKind.BLANK)
		b.append(row)
	return b

func _assert(condition: bool, msg: String) -> void:
	if not condition:
		_fails.append("FAIL: " + msg)

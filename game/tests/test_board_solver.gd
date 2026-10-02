extends SceneTree

const BoardSolver = preload("res://scripts/core/board_solver.gd")
const SolverTechniques = preload("res://scripts/core/solver_techniques.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_next_hint_empty_board()
	_test_next_hint_after_placement()
	_test_next_hint_returns_unit_info()
	_test_progressive_hint_stages()
	_test_solve_sequence()
	_test_compute_cell_ranks()
	_test_lock_intersection()
	_test_internal_exclusions_are_not_candidates()
	_test_gen_subsets()
	_test_locked_subset_returns_dict()
	_test_locked_subset_no_crash_empty_board()
	_test_contradiction_returns_dict()
	_test_clone_board()
	_test_replay_solve_standard()
	if _fails.is_empty():
		print("CORE_BOARD_SOLVER_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_next_hint_empty_board() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	var hint := BoardSolver.next_hint(board, 4, regions, solution)
	_assert(hint["found"], "hint found on empty board")

func _test_next_hint_after_placement() -> void:
	var board := _empty_board(4)
	board[0][1] = CellModel.CellKind.CANDY
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	var hint := BoardSolver.next_hint(board, 4, regions, solution)
	_assert(hint["found"], "hint after placement")

func _test_next_hint_returns_unit_info() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	var hint := BoardSolver.next_hint(board, 4, regions, solution)
	_assert(hint.has("unit_type"), "hint has unit_type")
	_assert(hint["unit_type"] in ["zone", "row", "col"], "valid unit_type")

func _test_progressive_hint_stages() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	var h1 := BoardSolver.progressive_hint(board, 4, regions, solution, 1)
	_assert(h1["stage"] == "unit", "first click shows unit")
	var h2 := BoardSolver.progressive_hint(board, 4, regions, solution, 2)
	_assert(h2["stage"] == "cell" or h2["stage"] == "place", "second click narrows")

func _test_solve_sequence() -> void:
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	var seq := BoardSolver.solve_sequence(4, regions, solution)
	_assert(seq.size() == 4, "sequence has 4 steps")
	for rank in seq:
		_assert(rank >= 1 and rank <= 3, "rank in S1-S3 range")

func _test_compute_cell_ranks() -> void:
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	var ranks := BoardSolver.compute_cell_ranks(4, regions, solution, [])
	_assert(ranks.size() == 4, "ranks has 4 rows")
	_assert(ranks[0].size() == 4, "ranks row has 4 cols")
	# Each solution cell should have a rank 1-4
	for row in range(4):
		_assert(ranks[row][solution[row]] >= 1, "solution cell has rank")

func _test_lock_intersection() -> void:
	# S3 test: set up board where lock intersection can eliminate
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var result := SolverTechniques._try_lock_intersection(board, 4, regions)
	# On empty 4x4 board, S3 may or may not find eliminations depending on geometry
	_assert(result.has("found"), "lock intersection returns found key")

func _test_internal_exclusions_are_not_candidates() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	board[0][0] = CellModel.CellKind.MARK
	_assert(not SolverTechniques._is_candidate(board, 4, regions, 0, 0), "internal exclusion is not a candidate")

func _test_gen_subsets() -> void:
	var items := ["A", "B", "C", "D"]
	var pairs := SolverTechniques._gen_subsets(items, 2)
	_assert(pairs.size() == 6, "C(4,2) = 6 subsets, got %d" % pairs.size())
	var triples := SolverTechniques._gen_subsets(items, 3)
	_assert(triples.size() == 4, "C(4,3) = 4 subsets, got %d" % triples.size())
	var singles := SolverTechniques._gen_subsets(items, 1)
	_assert(singles.size() == 4, "C(4,1) = 4 subsets")
	var empty := SolverTechniques._gen_subsets(items, 0)
	_assert(empty.size() == 0, "C(4,0) = 0 subsets")
	var over := SolverTechniques._gen_subsets(items, 5)
	_assert(over.size() == 0, "C(4,5) = 0 subsets")

func _test_locked_subset_returns_dict() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "AABB", "CCDD", "CCDD"]
	board[0][0] = CellModel.CellKind.CANDY
	board[1][3] = CellModel.CellKind.CANDY
	SolverTechniques._apply_elimination(board, 4, regions)
	var result := SolverTechniques._try_locked_subsets(board, 4, regions, 2)
	_assert(result.has("found"), "subset returns found key")
	_assert(result.has("eliminated"), "subset returns eliminated key")
	if result.get("found", false):
		for cell in result.get("eliminated", []):
			_assert(cell is Array and cell.size() == 2, "eliminated cell is [r, c]")

func _test_locked_subset_no_crash_empty_board() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	SolverTechniques._apply_elimination(board, 4, regions)
	var result := SolverTechniques._try_locked_subsets(board, 4, regions, 3)
	_assert(result.has("found"), "subset on empty board returns found key")

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

func _test_contradiction_returns_dict() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var result := SolverTechniques._try_contradiction(board, 4, regions, 2)
	_assert(result.has("found"), "contradiction returns found key")
	_assert(result.has("eliminated"), "contradiction returns eliminated key")

func _test_clone_board() -> void:
	var board := _empty_board(4)
	board[0][0] = CellModel.CellKind.CANDY
	var clone := SolverTechniques._clone_board(board, 4)
	clone[1][1] = CellModel.CellKind.MARK
	_assert(board[1][1] == CellModel.CellKind.BLANK, "clone does not affect original")
	_assert(clone[0][0] == CellModel.CellKind.CANDY, "clone preserves existing")

func _test_replay_solve_standard() -> void:
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var solution := [1, 3, 0, 2]
	var result := BoardSolver.replay_solve(4, regions, solution, [])
	_assert(result.get("solved", false), "replay solves standard 4x4")
	_assert(result.get("steps", 0) == 4, "4 steps for 4x4 (one candy per row)")
	_assert(result.has("profile"), "replay has profile")
	_assert(result.get("max_technique", 0) >= 1, "some technique used")

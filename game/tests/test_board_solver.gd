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
	_test_popcount()
	_test_precompute_zone_masks()
	_test_locked_subset_returns_dict()
	_test_locked_subset_no_crash_empty_board()
	_test_locked_pair_rows()
	_test_locked_triple_rows()
	_test_locked_triple_columns()
	_test_locked_subset_ignores_empty_zone()
	_test_locked_subset_benchmarks()
	_test_contradiction_returns_dict()
	_test_contradiction_chain_detail()
	_test_propagate_with_trace_no_contradiction()
	_test_clone_board()
	_test_replay_solve_standard()
	_test_advanced_technique_puzzle()
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

func _test_popcount() -> void:
	_assert(SolverTechniques._popcount(0) == 0, "popcount zero")
	_assert(SolverTechniques._popcount(1) == 1, "popcount one")
	_assert(SolverTechniques._popcount(0b1010) == 2, "popcount sparse")
	_assert(SolverTechniques._popcount(0xFFF) == 12, "popcount 12 bits")
	_assert(SolverTechniques._popcount(0b1000000000001) == 2, "popcount sparse 13 bits")

func _test_precompute_zone_masks() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "AABB", "CCDD", "CCDD"]
	var masks: Dictionary = SolverTechniques._precompute_zone_masks(board, 4, regions)
	_assert(masks["row"]["A"] == 0b0011, "zone A row mask")
	_assert(masks["col"]["A"] == 0b0011, "zone A col mask")
	for r in range(2):
		for c in range(2):
			board[r][c] = CellModel.CellKind.MARK
	masks = SolverTechniques._precompute_zone_masks(board, 4, regions)
	_assert(masks["row"]["A"] == 0, "empty zone row mask")
	_assert(masks["col"]["A"] == 0, "empty zone col mask")

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

func _test_locked_pair_rows() -> void:
	# bank_6x6.json, rank 1, index 0, seed 4.
	var regions := ["AAAAAA", "AEBAAA", "CEEEEA", "EEDDAA", "EEDDDD", "EEEEFD"]
	var result := SolverTechniques._try_locked_subsets(_empty_board(6), 6, regions, 2)
	_assert(result.get("found", false), "6x6 row pair found")
	_assert(result.get("technique", 0) == SolverTechniques.Technique.SUBSET_PAIR, "6x6 pair technique")
	_assert(result.get("subset_zones", []) == ["B", "C"], "6x6 pair zones")
	_assert(result.get("eliminated", []) == [[1, 0], [1, 1], [1, 3], [1, 4], [1, 5], [2, 1], [2, 2], [2, 3], [2, 4], [2, 5]], "6x6 pair eliminations")

func _test_locked_triple_rows() -> void:
	# bank_8x8.json, rank 1, index 164, seed 334.
	var regions := ["DCACCCCB", "DCCCBBBB", "DDCCBBEB", "DDDBBEEE", "DDDDBBBE", "FDGDEEEE", "FFGGGHHE", "FFFFFFHE"]
	var result := SolverTechniques._try_locked_subsets(_empty_board(8), 8, regions, 3)
	_assert(result.get("found", false), "8x8 row triple found")
	_assert(result.get("technique", 0) == SolverTechniques.Technique.SUBSET_TRIPLE, "8x8 triple technique")
	_assert(result.get("subset_zones", []) == ["F", "G", "H"], "8x8 triple zones")
	_assert(result.get("eliminated", []) == [[5, 1], [5, 3], [5, 4], [5, 5], [5, 6], [5, 7], [6, 7], [7, 7]], "8x8 triple eliminations")

func _test_locked_triple_columns() -> void:
	# bank_10x10.json, rank 3, index 8, seed 100277.
	var regions := ["AAAAABBBCC", "ADABBBFBBC", "ADABAAFCCC", "ADAAAAFFEC", "ADAADAAFEC", "DDDDDAFFFC", "DGGDAAFJJC", "GGDDHAFJCC", "GDDDHHJJJI", "HHHHHJJIII"]
	var result := SolverTechniques._try_locked_subsets(_empty_board(10), 10, regions, 3)
	_assert(result.get("found", false), "10x10 column triple found")
	_assert(result.get("technique", 0) == SolverTechniques.Technique.SUBSET_TRIPLE, "10x10 column triple technique")
	_assert(result.get("subset_zones", []) == ["C", "E", "I"], "10x10 column triple zones")
	_assert(result.get("eliminated", []) == [[1, 8], [5, 8], [6, 8], [8, 8], [0, 7], [1, 7], [3, 7], [4, 7], [5, 7], [6, 7], [7, 7], [8, 7]], "10x10 column triple eliminations")

func _test_locked_subset_ignores_empty_zone() -> void:
	var regions := ["AABCC", "AABCC", "DDEEC", "DDEEC", "DDEEC"]
	var board := _empty_board(5)
	for r in range(2):
		for c in range(2):
			board[r][c] = CellModel.CellKind.MARK
	var result := SolverTechniques._try_locked_subsets(board, 5, regions, 2)
	_assert(not result.get("subset_zones", []).has("A"), "zone without candidates cannot form a locked subset")

func _test_locked_subset_benchmarks() -> void:
	# Both bank geometries require a triple on an unmarked board; measure the S4-S6 function itself.
	var cases := [
		{"label": "10x10", "size": 10, "regions": ["AAAAABBBCC", "ADABBBFBBC", "ADABAAFCCC", "ADAAAAFFEC", "ADAADAAFEC", "DDDDDAFFFC", "DGGDAAFJJC", "GGDDHAFJCC", "GDDDHHJJJI", "HHHHHJJIII"], "zones": ["C", "E", "I"], "budget_us": 200000},
		{"label": "12x12", "size": 12, "regions": ["AAAAABBBAAAA", "DDIIABBBBCCA", "DDDIAEEECCCA", "DDDIAEEAAAAA", "DDDIAEEEAGFF", "DDDIAHHHAGFF", "IIIIAHLHAGGG", "IIIIAHHHAGGG", "IIIJAHHAAJGG", "KIJJAAAAJJGG", "KJJJAJJJJJGG", "KKKJJJJJJJGG"], "zones": ["E", "H", "L"], "budget_us": 500000},
	]
	for case in cases:
		var size: int = case["size"]
		var board := _empty_board(size)
		var times: Array[int] = []
		for _run in range(5):
			var start := Time.get_ticks_usec()
			var result := SolverTechniques._try_locked_subsets(board, size, case["regions"], 3)
			times.append(Time.get_ticks_usec() - start)
			_assert(result.get("technique", 0) == SolverTechniques.Technique.SUBSET_TRIPLE, case["label"] + " benchmark invokes S5")
			_assert(result.get("subset_zones", []) == case["zones"], case["label"] + " benchmark triple zones")
		times.sort()
		print("LOCKED_SUBSET_BENCH ", case["label"], " median_us=", times[2], " samples=", times)
		_assert(times[2] < case["budget_us"], case["label"] + " subset median below budget")

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

func _test_advanced_technique_puzzle() -> void:
	# 5x5 pentomino-style regions: S4 (SUBSET_PAIR) is required to solve
	# Discovered via exploration: givens=[[1,4]] forces the solver to invoke
	# _try_locked_subsets (S4) at least once before reaching a solution.
	# Profile confirmed: s4=1, max_technique=7 (CONTRA_CHAIN also needed).
	var size := 5
	var regions := ["AABCC", "AABBC", "DABBC", "DDDBC", "DDEEE"]
	var solution := [1, 4, 0, 3, 2]
	# One given: row 1 col 4 (zone C)
	var givens := [[1, 4]]

	var result := BoardSolver.replay_solve(size, regions, solution, givens)
	_assert(result.get("solved", false), "advanced puzzle: solved")
	_assert(result.get("max_technique", 0) >= 4, "advanced puzzle: required S4+")
	# Verify profile shows S4+ technique was actually used
	var profile: Dictionary = result.get("profile", {})
	var used_advanced := false
	for key in ["s4", "s5", "s6", "s7"]:
		if profile.get(key, 0) > 0:
			used_advanced = true
	_assert(used_advanced, "advanced puzzle: profile shows S4+ technique used")
	# Verify specifically that SUBSET_PAIR (S4) was invoked
	_assert(profile.get("s4", 0) > 0, "advanced puzzle: S4 SUBSET_PAIR invoked")

func _test_contradiction_chain_detail() -> void:
	# 4x4 board where placing candy at [2,0] causes contradiction
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	board[0][1] = CellModel.CellKind.CANDY
	board[1][3] = CellModel.CellKind.CANDY
	SolverTechniques._apply_elimination(board, 4, regions)
	var result := SolverTechniques._try_contradiction(board, 4, regions)
	if result["found"]:
		_assert(result.has("chain_detail"), "contradiction has chain_detail")
		var detail: Dictionary = result["chain_detail"]
		_assert(detail.has("hypothesis_cell"), "detail has hypothesis_cell")
		_assert(detail.has("depth"), "detail has depth")
		_assert(detail.has("steps"), "detail has steps")
		_assert(detail.has("contra_type"), "detail has contra_type")
		_assert(detail["contra_type"] in ["row", "col", "zone"], "contra_type is valid")
		_assert(detail["depth"] >= 0, "depth >= 0")

func _test_propagate_with_trace_no_contradiction() -> void:
	var board := _empty_board(4)
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	board[0][1] = CellModel.CellKind.CANDY
	SolverTechniques._apply_elimination(board, 4, regions)
	var result := SolverTechniques._propagate_with_trace(board, 4, regions, 99)
	_assert(not result["contradiction"], "no contradiction on valid partial board")
	_assert(result["depth"] >= 0, "depth >= 0")
	_assert(result["steps"] is Array, "steps is Array")

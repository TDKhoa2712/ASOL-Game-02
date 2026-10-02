# board_solver.gd
extends RefCounted

const CellModel = preload("res://scripts/core/cell_model.gd")
const SolverTechniques = preload("res://scripts/core/solver_techniques.gd")

const Technique = SolverTechniques.Technique

static func next_hint(board: Array, size: int, regions: Array, _solution: Array) -> Dictionary:
	var work_board: Array = _build_work_board(board, size, regions)
	var s2: Dictionary = SolverTechniques._try_single_candidate(work_board, size, regions)
	if s2.get("found", false):
		return {
			"found": true,
			"technique": Technique.SINGLE_CANDIDATE,
			"cell": s2["cell"],
			"unit_type": s2["unit_type"],
			"unit_id": s2["unit_id"],
			"explanation": "Single candidate in " + str(s2["unit_type"]) + " " + str(s2["unit_id"])
		}

	var s3: Dictionary = SolverTechniques._try_lock_intersection(work_board, size, regions)
	if s3.get("found", false):
		for cell in (s3["eliminated"] as Array):
			work_board[cell[0]][cell[1]] = CellModel.CellKind.MARK
		var s2_after: Dictionary = SolverTechniques._try_single_candidate(work_board, size, regions)
		if s2_after.get("found", false):
			return {
				"found": true,
				"technique": Technique.LOCK_INTERSECTION,
				"cell": s2_after["cell"],
				"unit_type": s2_after["unit_type"],
				"unit_id": s2_after["unit_id"],
				"explanation": "Lock intersection revealed cell in " + str(s2_after["unit_type"])
			}
		return {
			"found": true,
			"technique": Technique.LOCK_INTERSECTION,
			"cell": (s3["eliminated"] as Array)[0],
			"unit_type": s3.get("target_type", "zone"),
			"unit_id": s3.get("target_id", 0),
			"explanation": "Lock intersection eliminates candidates"
		}

	var s4: Dictionary = SolverTechniques._try_locked_subsets(work_board, size, regions, 6)
	if s4.get("found", false):
		for cell in (s4["eliminated"] as Array):
			work_board[cell[0]][cell[1]] = CellModel.CellKind.MARK
		var s2_after_s4: Dictionary = SolverTechniques._try_single_candidate(work_board, size, regions)
		if s2_after_s4.get("found", false):
			return {
				"found": true,
				"technique": s4.get("technique", Technique.SUBSET_PAIR),
				"cell": s2_after_s4["cell"],
				"unit_type": s2_after_s4["unit_type"],
				"unit_id": s2_after_s4["unit_id"],
				"explanation": "Locked subset revealed cell in " + str(s2_after_s4["unit_type"])
			}
		return {
			"found": true,
			"technique": s4.get("technique", Technique.SUBSET_PAIR),
			"cell": (s4["eliminated"] as Array)[0],
			"unit_type": "zone",
			"unit_id": s4.get("subset_zones", [""])[0],
			"explanation": "Locked subset eliminates candidates"
		}

	var s7: Dictionary = SolverTechniques._try_contradiction(work_board, size, regions, 2)
	if s7.get("found", false):
		for cell in (s7["eliminated"] as Array):
			work_board[cell[0]][cell[1]] = CellModel.CellKind.MARK
		var s2_after_s7: Dictionary = SolverTechniques._try_single_candidate(work_board, size, regions)
		if s2_after_s7.get("found", false):
			return {
				"found": true,
				"technique": Technique.CONTRA_CHAIN,
				"cell": s2_after_s7["cell"],
				"unit_type": s2_after_s7["unit_type"],
				"unit_id": s2_after_s7["unit_id"],
				"explanation": "Contradiction chain revealed cell"
			}
		return {
			"found": true,
			"technique": Technique.CONTRA_CHAIN,
			"cell": (s7["eliminated"] as Array)[0],
			"unit_type": "zone",
			"unit_id": "",
			"explanation": "Contradiction chain eliminates candidate"
		}

	return {"found": false}

static func progressive_hint(board: Array, size: int, regions: Array,
		solution: Array, max_clicks: int) -> Dictionary:
	var hint: Dictionary = next_hint(board, size, regions, solution)
	if not hint.get("found", false):
		return {"stage": "none", "highlight": [], "text": "No hint available"}

	if max_clicks <= 1:
		return {
			"stage": "unit",
			"highlight": SolverTechniques._unit_cells(size, regions, str(hint["unit_type"]), hint["unit_id"]),
			"text": "Look closely at this " + str(hint["unit_type"])
		}

	return {
		"stage": "cell",
		"highlight": [hint["cell"]],
		"text": str(hint.get("explanation", "Place candy here"))
	}

static func solve_sequence(size: int, regions: Array, solution: Array) -> Array[int]:
	var work_board: Array = _empty_board(size)
	var seq: Array[int] = []
	var current_max: int = 1

	for _step in range(size):
		SolverTechniques._apply_elimination(work_board, size, regions)
		var placed: bool = false
		for _loop in range(size * 2):
			var s2: Dictionary = SolverTechniques._try_single_candidate(work_board, size, regions)
			if s2.get("found", false):
				var cell: Array = s2["cell"]
				work_board[cell[0]][cell[1]] = CellModel.CellKind.CANDY
				seq.append(current_max)
				current_max = 1
				placed = true
				break
			var s3: Dictionary = SolverTechniques._try_lock_intersection(work_board, size, regions)
			if s3.get("found", false):
				for cell in (s3["eliminated"] as Array):
					work_board[cell[0]][cell[1]] = CellModel.CellKind.MARK
				current_max = maxi(current_max, 2)
				continue
			break
		if not placed:
			for r in range(size):
				if not CellModel.is_placed(work_board[r][solution[r]]):
					work_board[r][solution[r]] = CellModel.CellKind.CANDY
					seq.append(3)
					current_max = 1
					break

	return seq

static func compute_cell_ranks(size: int, regions: Array, solution: Array,
		givens: Array) -> Array:
	var ranks: Array = []
	var work_board: Array = _empty_board(size)
	for r in range(size):
		var row_ranks: Array = []
		for c in range(size):
			row_ranks.append(0)
		ranks.append(row_ranks)

	for g in givens:
		var gr: int = int(g[0]) if g is Array else int(g["row"])
		var gc: int = int(g[1]) if g is Array else int(g["col"])
		work_board[gr][gc] = CellModel.CellKind.GIVEN
		ranks[gr][gc] = 1

	var current_max: int = 1
	while true:
		SolverTechniques._apply_elimination(work_board, size, regions)
		var s2: Dictionary = SolverTechniques._try_single_candidate(work_board, size, regions)
		if s2.get("found", false):
			var cell: Array = s2["cell"]
			work_board[cell[0]][cell[1]] = CellModel.CellKind.CANDY
			ranks[cell[0]][cell[1]] = current_max
			current_max = 1
			continue
		var s3: Dictionary = SolverTechniques._try_lock_intersection(work_board, size, regions)
		if s3.get("found", false):
			for cell in (s3["eliminated"] as Array):
				work_board[cell[0]][cell[1]] = CellModel.CellKind.MARK
			current_max = maxi(current_max, 2)
			continue
		break

	for r in range(size):
		var sc: int = int(solution[r])
		if ranks[r][sc] == 0:
			ranks[r][sc] = 4
	return ranks

static func replay_solve(size: int, regions: Array, solution: Array, givens: Array) -> Dictionary:
	var board := _empty_board(size)
	for g in givens:
		var gr: int = int(g.get("r", g.get("row", -1))) if g is Dictionary else int(g[0])
		var gc: int = int(g.get("c", g.get("col", -1))) if g is Dictionary else int(g[1])
		if gr >= 0 and gr < size and gc >= 0 and gc < size:
			board[gr][gc] = CellModel.CellKind.GIVEN
	var profile := {"s1": 0, "s2": 0, "s3": 0, "s4": 0, "s5": 0, "s6": 0, "s7": 0}
	var max_tech: int = 0
	var steps: int = 0
	var placed_count: int = givens.size()
	for _outer in range(size * size * 2):
		if placed_count >= size:
			break
		SolverTechniques._apply_elimination(board, size, regions)
		profile["s1"] += 1
		var s2 := SolverTechniques._try_single_candidate(board, size, regions)
		if s2.get("found", false):
			board[s2["cell"][0]][s2["cell"][1]] = CellModel.CellKind.CANDY
			profile["s2"] += 1
			max_tech = maxi(max_tech, Technique.SINGLE_CANDIDATE)
			steps += 1
			placed_count += 1
			continue
		var s3 := SolverTechniques._try_lock_intersection(board, size, regions)
		if s3.get("found", false):
			for cell in (s3["eliminated"] as Array):
				board[cell[0]][cell[1]] = CellModel.CellKind.MARK
			profile["s3"] += 1
			max_tech = maxi(max_tech, Technique.LOCK_INTERSECTION)
			continue
		var s4 := SolverTechniques._try_locked_subsets(board, size, regions, 6)
		if s4.get("found", false):
			for cell in (s4["eliminated"] as Array):
				board[cell[0]][cell[1]] = CellModel.CellKind.MARK
			var tk: int = int(s4.get("technique", Technique.SUBSET_PAIR))
			profile["s" + str(tk)] += 1
			max_tech = maxi(max_tech, tk)
			continue
		var s7 := SolverTechniques._try_contradiction(board, size, regions, 2)
		if s7.get("found", false):
			for cell in (s7["eliminated"] as Array):
				board[cell[0]][cell[1]] = CellModel.CellKind.MARK
			profile["s7"] += 1
			max_tech = maxi(max_tech, Technique.CONTRA_CHAIN)
			continue
		break
	return {"solved": placed_count >= size, "steps": steps, "profile": profile, "max_technique": max_tech}

static func _build_work_board(board: Array, size: int, regions: Array) -> Array:
	var work: Array = _empty_board(size)
	for r in range(size):
		for c in range(size):
			if CellModel.is_placed(board[r][c]):
				work[r][c] = board[r][c]
	SolverTechniques._apply_elimination(work, size, regions)
	return work

static func _empty_board(size: int) -> Array:
	var b: Array = []
	for r in range(size):
		var row: Array = []
		for c in range(size):
			row.append(CellModel.CellKind.BLANK)
		b.append(row)
	return b

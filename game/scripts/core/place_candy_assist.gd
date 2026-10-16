# Chooses the cell the place-candy assist fills: a deduced single first,
# otherwise the solution cell of the region with the fewest open cells.
extends RefCounted

const CellModel = preload("res://scripts/core/cell_model.gd")
const CandyRules = preload("res://scripts/core/candy_rules.gd")
const HintEngine = preload("res://scripts/core/hint_engine.gd")
const SolverTechniques = preload("res://scripts/core/solver_techniques.gd")

static func pick_cell(board: Array, size: int, regions: Array, solution: Array) -> Array:
	var work := HintEngine._build_hint_work_board(board, size, regions, solution)
	var single := SolverTechniques._try_single_candidate(work, size, regions)
	if single.get("found", false):
		var cell: Array = single["cell"]
		var r := int(cell[0]); var c := int(cell[1])
		if r < solution.size() and int(solution[r]) == c and CellModel.is_available(board[r][c]):
			return [r, c]
	var best: Array = []
	var best_open := 1 << 30
	for r in range(mini(size, solution.size())):
		var c := int(solution[r])
		if not CellModel.is_available(board[r][c]):
			continue
		var open := _open_cells(board, size, regions, CandyRules.zone_of(regions, r, c))
		if open < best_open:
			best_open = open
			best = [r, c]
	return best

static func _open_cells(board: Array, size: int, regions: Array, zone: String) -> int:
	var n := 0
	for r in range(size):
		for c in range(size):
			if CandyRules.zone_of(regions, r, c) == zone and CellModel.is_available(board[r][c]):
				n += 1
	return n

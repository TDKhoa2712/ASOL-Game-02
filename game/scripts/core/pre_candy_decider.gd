extends RefCounted

const BoardSolver = preload("res://scripts/core/board_solver.gd")

enum Trigger {
	HARD_NEXT = 1,
	CONSECUTIVE_FAIL = 2,
	DEMOTE = 3,
}

static func should_prefill(trigger: int, fail_streak: int) -> bool:
	match trigger:
		Trigger.CONSECUTIVE_FAIL:
			return fail_streak >= 2
		Trigger.HARD_NEXT, Trigger.DEMOTE:
			return true
	return false

static func choose_prefill_cell(size: int, regions: Array,
		solution: Array, givens: Array) -> Array:
	var ranks: Array = BoardSolver.compute_cell_ranks(size, regions, solution, givens)
	var best_rank: int = 0
	var best_cell: Array = []
	for r in range(size):
		var c: int = int(solution[r])
		var is_given: bool = false
		for g in givens:
			var gr: int = int(g.get("r", g.get("row", -1))) if g is Dictionary else int(g[0])
			var gc: int = int(g.get("c", g.get("col", -1))) if g is Dictionary else int(g[1])
			if gr == r and gc == c:
				is_given = true
				break
		if is_given:
			continue
		if ranks[r][c] > best_rank:
			best_rank = ranks[r][c]
			best_cell = [r, c]
	return best_cell

static func apply_prefill(level: Dictionary) -> Dictionary:
	var modified: Dictionary = level.duplicate(true)
	var cell: Array = choose_prefill_cell(
		int(level["size"]), level["regions"],
		level["solution"], level.get("givens", [])
	)
	if not cell.is_empty():
		var givens: Array = modified.get("givens", []).duplicate(true)
		givens.append({"r": cell[0], "c": cell[1]})
		modified["givens"] = givens
	return modified

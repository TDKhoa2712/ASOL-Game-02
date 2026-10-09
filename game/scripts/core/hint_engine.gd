extends RefCounted

const CellModel = preload("res://scripts/core/cell_model.gd")
const CandyRules = preload("res://scripts/core/candy_rules.gd")
const SolverTechniques = preload("res://scripts/core/solver_techniques.gd")

static func find_hint(board: Array, size: int, regions: Array, solution: Array) -> Dictionary:
	var res := _find_hint_impl(board, size, regions, solution)
	if res.get("found", false):
		res["size"] = size
	return res

static func _find_hint_impl(board: Array, size: int, regions: Array, solution: Array) -> Dictionary:
	var wrong := _find_wrong_mark(board, size, solution)
	if wrong.get("found", false):
		return wrong

	var mark := _find_mark_hint(board, size, regions)
	if mark.get("found", false):
		return mark

	var work := _build_hint_work_board(board, size, regions, solution)

	var single := SolverTechniques._try_single_candidate(work, size, regions)
	if single.get("found", false):
		var unit_type: String = single.get("unit_type", "")
		var unit_id: Variant = single.get("unit_id", "")
		return _make_result("SINGLE_CANDIDATE", "PLACE_CANDY",
				single["cell"], _unit_cells(size, regions, unit_type, unit_id),
				[], "hint.single_" + unit_type, [unit_id], unit_type, unit_id)

	var lock := SolverTechniques._try_lock_intersection(work, size, regions)
	if lock.get("found", false):
		var filtered := _filter_new_eliminations(lock.get("eliminated", []), board)
		if not filtered.is_empty():
			var mode: String = lock.get("mode", "")
			var explanation := _lock_explanation_key(mode)
			var hl: Array = lock.get("eliminated", [])
			return _make_result("LOCK_INTERSECTION", "PLACE_MARKS",
					filtered[0], hl, filtered, explanation, [],
					lock.get("target_type", ""), lock.get("target_id", ""))

	var subset := SolverTechniques._try_locked_subsets(work, size, regions)
	if subset.get("found", false):
		var filtered := _filter_new_eliminations(subset.get("eliminated", []), board)
		if not filtered.is_empty():
			var tech: int = subset.get("technique", 4)
			var key: String = "hint.subset_pair"
			if tech == SolverTechniques.Technique.SUBSET_TRIPLE:
				key = "hint.subset_triple"
			elif tech == SolverTechniques.Technique.SUBSET_QUAD:
				key = "hint.subset_quad"
			return _make_result("LOCKED_SUBSET", "PLACE_MARKS",
					filtered[0], subset.get("eliminated", []), filtered,
					key, subset.get("subset_zones", []))

	var chain := SolverTechniques._try_contradiction(work, size, regions)
	if chain.get("found", false):
		var filtered := _filter_new_eliminations(chain.get("eliminated", []), board)
		if not filtered.is_empty():
			var detail: Dictionary = chain.get("chain_detail", {})
			var depth: int = detail.get("depth", 0)
			var exp_key := "hint.chain_short" if depth <= 2 else "hint.chain_long"
			var result := _make_result("CONTRA_CHAIN", "PLACE_MARKS",
					filtered[0], chain.get("eliminated", []), filtered, exp_key, [])
			result["chain_detail"] = detail
			return result

	return _find_fallback(board, size, solution)

static func _sol_col(solution: Array, r: int) -> int:
	if r < 0 or r >= solution.size(): return -1
	var v = solution[r]
	return int(v.get("c", -1)) if v is Dictionary else int(v)

static func _find_wrong_mark(board: Array, size: int, solution: Array) -> Dictionary:
	for r in range(size):
		for c in range(size):
			if board[r][c] == CellModel.CellKind.MARK and _sol_col(solution, r) == c:
				return _make_result("WRONG_MARK", "CLEAR_MARK",
						[r, c], [[r, c]], [], "hint.wrong_mark", [])
	return {"found": false}

static func _find_mark_hint(board: Array, size: int, regions: Array) -> Dictionary:
	for r in range(size):
		for c in range(size):
			if not CellModel.is_placed(board[r][c]):
				continue
			var to_mark: Array = []
			var seen: Dictionary = {}
			for cc in range(size):
				if cc != c and board[r][cc] == CellModel.CellKind.BLANK:
					var key := Vector2i(r, cc)
					if not seen.has(key):
						to_mark.append([r, cc]); seen[key] = true
			for rr in range(size):
				if rr != r and board[rr][c] == CellModel.CellKind.BLANK:
					var key := Vector2i(rr, c)
					if not seen.has(key):
						to_mark.append([rr, c]); seen[key] = true
			for dr in [-1, 0, 1]:
				for dc in [-1, 0, 1]:
					if dr == 0 and dc == 0: continue
					var nr: int = r + int(dr)
					var nc: int = c + int(dc)
					if nr >= 0 and nr < size and nc >= 0 and nc < size:
						if board[nr][nc] == CellModel.CellKind.BLANK:
							var key := Vector2i(nr, nc)
							if not seen.has(key):
								to_mark.append([nr, nc]); seen[key] = true
			var candy_zone: String = CandyRules.zone_of(regions, r, c)
			for zr in range(size):
				for zc in range(size):
					if CandyRules.zone_of(regions, zr, zc) == candy_zone:
						if board[zr][zc] == CellModel.CellKind.BLANK:
							var key := Vector2i(zr, zc)
							if not seen.has(key):
								to_mark.append([zr, zc]); seen[key] = true
			if not to_mark.is_empty():
				return _make_result("MARK_NEIGHBORS", "PLACE_MARKS",
						[r, c], [[r, c]] + to_mark, to_mark,
						"hint.mark_neighbors", [])
	return {"found": false}

static func _find_fallback(board: Array, size: int, solution: Array) -> Dictionary:
	for r in range(size):
		var c: int = _sol_col(solution, r)
		if c >= 0 and not CellModel.is_placed(board[r][c]):
			return _make_result("FALLBACK", "REVEAL",
					[r, c], [[r, c]], [], "hint.fallback", [])
	return {"found": false}

static func _build_hint_work_board(board: Array, size: int, regions: Array, solution: Array) -> Array:
	var work: Array = []
	for r in range(size):
		var row: Array = []
		for c in range(size):
			var cell: int = board[r][c]
			if CellModel.is_placed(cell):
				row.append(cell)
			elif cell == CellModel.CellKind.MARK and _sol_col(solution, r) != c:
				row.append(CellModel.CellKind.MARK)
			else:
				row.append(CellModel.CellKind.BLANK)
		work.append(row)
	SolverTechniques._apply_elimination(work, size, regions)
	return work

static func _filter_new_eliminations(eliminated: Array, board: Array) -> Array:
	var result: Array = []
	for cell in eliminated:
		if board[cell[0]][cell[1]] == CellModel.CellKind.BLANK:
			result.append(cell)
	return result

static func _unit_cells(size: int, regions: Array, unit_type: String, unit_id: Variant) -> Array:
	var cells: Array = []
	for r in range(size):
		for c in range(size):
			if (unit_type == "row" and r == int(unit_id)) \
					or (unit_type == "col" and c == int(unit_id)) \
					or (unit_type == "zone" and CandyRules.zone_of(regions, r, c) == str(unit_id)):
				cells.append([r, c])
	return cells

static func _lock_explanation_key(mode: String) -> String:
	match mode:
		"zone_to_row": return "hint.lock_zone_row"
		"zone_to_col": return "hint.lock_zone_col"
		"row_to_zone": return "hint.lock_row_zone"
		"col_to_zone": return "hint.lock_col_zone"
	return "hint.lock_zone_row"

static func _make_result(strategy: String, action: String,
		target_cell: Array, highlight_cells: Array,
		eliminated_cells: Array, explanation_key: String,
		explanation_params: Array, unit_type: String = "",
		unit_id: Variant = "") -> Dictionary:
	return {
		"found": true,
		"strategy": strategy,
		"action": action,
		"target_cell": target_cell,
		"highlight_cells": highlight_cells,
		"eliminated_cells": eliminated_cells,
		"explanation_key": explanation_key,
		"explanation_params": explanation_params,
		"unit_type": unit_type,
		"unit_id": unit_id,
	}

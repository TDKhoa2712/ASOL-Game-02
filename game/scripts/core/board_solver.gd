# board_solver.gd
extends RefCounted

const CellModel = preload("res://scripts/core/cell_model.gd")
const CandyRules = preload("res://scripts/core/candy_rules.gd")

enum Technique { ELIMINATION = 1, SINGLE_CANDIDATE = 2, LOCK_INTERSECTION = 3 }

static func next_hint(board: Array, size: int, regions: Array, _solution: Array) -> Dictionary:
	var work_board: Array = _build_work_board(board, size, regions)
	var s2: Dictionary = _try_single_candidate(work_board, size, regions)
	if s2.get("found", false):
		return {
			"found": true,
			"technique": Technique.SINGLE_CANDIDATE,
			"cell": s2["cell"],
			"unit_type": s2["unit_type"],
			"unit_id": s2["unit_id"],
			"explanation": "Single candidate in " + str(s2["unit_type"]) + " " + str(s2["unit_id"])
		}

	var s3: Dictionary = _try_lock_intersection(work_board, size, regions)
	if s3.get("found", false):
		for cell in (s3["eliminated"] as Array):
			work_board[cell[0]][cell[1]] = CellModel.CellKind.MARK
		var s2_after: Dictionary = _try_single_candidate(work_board, size, regions)
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

	return {"found": false}

static func progressive_hint(board: Array, size: int, regions: Array,
		solution: Array, max_clicks: int) -> Dictionary:
	var hint: Dictionary = next_hint(board, size, regions, solution)
	if not hint.get("found", false):
		return {"stage": "none", "highlight": [], "text": "No hint available"}

	if max_clicks <= 1:
		return {
			"stage": "unit",
			"highlight": _unit_cells(size, regions, str(hint["unit_type"]), hint["unit_id"]),
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
		_apply_elimination(work_board, size, regions)
		var placed: bool = false
		for _loop in range(size * 2):
			var s2: Dictionary = _try_single_candidate(work_board, size, regions)
			if s2.get("found", false):
				var cell: Array = s2["cell"]
				work_board[cell[0]][cell[1]] = CellModel.CellKind.CANDY
				seq.append(current_max)
				current_max = 1
				placed = true
				break
			var s3: Dictionary = _try_lock_intersection(work_board, size, regions)
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
		_apply_elimination(work_board, size, regions)
		var s2: Dictionary = _try_single_candidate(work_board, size, regions)
		if s2.get("found", false):
			var cell: Array = s2["cell"]
			work_board[cell[0]][cell[1]] = CellModel.CellKind.CANDY
			ranks[cell[0]][cell[1]] = current_max
			current_max = 1
			continue
		var s3: Dictionary = _try_lock_intersection(work_board, size, regions)
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

static func _apply_elimination(board: Array, _size: int, regions: Array) -> Array:
	var marks: Array = []
	for r in range(board.size()):
		for c in range(board[r].size()):
			if board[r][c] == CellModel.CellKind.BLANK and not CandyRules.can_place(board, regions, r, c):
				marks.append([r, c])
	for m in marks:
		board[m[0]][m[1]] = CellModel.CellKind.MARK
	return marks

static func _try_single_candidate(board: Array, size: int, regions: Array) -> Dictionary:
	for z in _zones(regions, size):
		if not _has_candy(board, size, regions, "zone", z):
			var cands: Array = _candidates_in_zone(board, size, regions, z)
			if cands.size() == 1:
				return {"found": true, "cell": cands[0], "unit_type": "zone", "unit_id": z}

	for r in range(size):
		if not _has_candy(board, size, regions, "row", r):
			var cands: Array = _candidates_in_row(board, size, regions, r)
			if cands.size() == 1:
				return {"found": true, "cell": cands[0], "unit_type": "row", "unit_id": r}

	for c in range(size):
		if not _has_candy(board, size, regions, "col", c):
			var cands: Array = _candidates_in_col(board, size, regions, c)
			if cands.size() == 1:
				return {"found": true, "cell": cands[0], "unit_type": "col", "unit_id": c}

	return {"found": false}

static func _try_lock_intersection(board: Array, size: int, regions: Array) -> Dictionary:
	# Mode 1 & 2: Zone -> Row / Col
	for z in _zones(regions, size):
		if _has_candy(board, size, regions, "zone", z):
			continue
		var cands: Array = _candidates_in_zone(board, size, regions, z)
		if cands.size() <= 1:
			continue
		var r0: int = cands[0][0]
		if cands.all(func(c: Array) -> bool: return c[0] == r0):
			var elim: Array = []
			for c in range(size):
				if CandyRules.zone_of(regions, r0, c) != z and _is_candidate(board, size, regions, r0, c):
					elim.append([r0, c])
			if not elim.is_empty():
				return {"found": true, "eliminated": elim, "mode": "zone_to_row", "target_type": "row", "target_id": r0}
		var c0: int = cands[0][1]
		if cands.all(func(c: Array) -> bool: return c[1] == c0):
			var elim: Array = []
			for r in range(size):
				if CandyRules.zone_of(regions, r, c0) != z and _is_candidate(board, size, regions, r, c0):
					elim.append([r, c0])
			if not elim.is_empty():
				return {"found": true, "eliminated": elim, "mode": "zone_to_col", "target_type": "col", "target_id": c0}

	# Mode 3: Row -> Zone
	for r in range(size):
		if _has_candy(board, size, regions, "row", r):
			continue
		var cands: Array = _candidates_in_row(board, size, regions, r)
		if cands.size() <= 1:
			continue
		var tz: String = CandyRules.zone_of(regions, r, cands[0][1])
		if cands.all(func(c: Array) -> bool: return CandyRules.zone_of(regions, r, c[1]) == tz):
			var elim: Array = []
			for cell in _candidates_in_zone(board, size, regions, tz):
				if cell[0] != r:
					elim.append(cell)
			if not elim.is_empty():
				return {"found": true, "eliminated": elim, "mode": "row_to_zone", "target_type": "zone", "target_id": tz}

	# Mode 4: Col -> Zone
	for c in range(size):
		if _has_candy(board, size, regions, "col", c):
			continue
		var cands: Array = _candidates_in_col(board, size, regions, c)
		if cands.size() <= 1:
			continue
		var tz: String = CandyRules.zone_of(regions, cands[0][0], c)
		if cands.all(func(cell: Array) -> bool: return CandyRules.zone_of(regions, cell[0], c) == tz):
			var elim: Array = []
			for cell in _candidates_in_zone(board, size, regions, tz):
				if cell[1] != c:
					elim.append(cell)
			if not elim.is_empty():
				return {"found": true, "eliminated": elim, "mode": "col_to_zone", "target_type": "zone", "target_id": tz}

	return {"found": false, "eliminated": [], "mode": ""}

static func _build_work_board(board: Array, size: int, regions: Array) -> Array:
	var work: Array = _empty_board(size)
	for r in range(size):
		for c in range(size):
			if CellModel.is_placed(board[r][c]):
				work[r][c] = board[r][c]
	_apply_elimination(work, size, regions)
	return work

static func _is_candidate(board: Array, _size: int, regions: Array, row: int, col: int) -> bool:
	return board[row][col] == CellModel.CellKind.BLANK and CandyRules.can_place(board, regions, row, col)

static func _candidates_in_zone(board: Array, size: int, regions: Array, zone: String) -> Array:
	var cands: Array = []
	for r in range(size):
		for c in range(size):
			if CandyRules.zone_of(regions, r, c) == zone and _is_candidate(board, size, regions, r, c):
				cands.append([r, c])
	return cands

static func _candidates_in_row(board: Array, size: int, regions: Array, row: int) -> Array:
	var cands: Array = []
	for c in range(size):
		if _is_candidate(board, size, regions, row, c):
			cands.append([row, c])
	return cands

static func _candidates_in_col(board: Array, size: int, regions: Array, col: int) -> Array:
	var cands: Array = []
	for r in range(size):
		if _is_candidate(board, size, regions, r, col):
			cands.append([r, col])
	return cands

static func _has_candy(board: Array, size: int, regions: Array, utype: String, uid: Variant) -> bool:
	for cell in _unit_cells(size, regions, utype, uid):
		if CellModel.is_placed(board[cell[0]][cell[1]]):
			return true
	return false

static func _zones(regions: Array, size: int) -> Array:
	var zlist: Array = []
	for r in range(size):
		for c in range(size):
			var z: String = CandyRules.zone_of(regions, r, c)
			if not z in zlist:
				zlist.append(z)
	return zlist

static func _unit_cells(size: int, regions: Array, utype: String, uid: Variant) -> Array:
	var cells: Array = []
	for r in range(size):
		for c in range(size):
			if (utype == "row" and r == int(uid)) or (utype == "col" and c == int(uid)) or (utype == "zone" and CandyRules.zone_of(regions, r, c) == str(uid)):
				cells.append([r, c])
	return cells

static func _empty_board(size: int) -> Array:
	var b: Array = []
	for r in range(size):
		var row: Array = []
		for c in range(size):
			row.append(CellModel.CellKind.BLANK)
		b.append(row)
	return b

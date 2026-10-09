# solver_techniques.gd - private technique helpers for BoardSolver
extends RefCounted

const CellModel = preload("res://scripts/core/cell_model.gd")
const CandyRules = preload("res://scripts/core/candy_rules.gd")

enum Technique { ELIMINATION = 1, SINGLE_CANDIDATE = 2, LOCK_INTERSECTION = 3, SUBSET_PAIR = 4, SUBSET_TRIPLE = 5, SUBSET_QUAD = 6, CONTRA_CHAIN = 7 }

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
	for z in _zones(regions, size):
		if _has_candy(board, size, regions, "zone", z): continue
		var cands: Array = _candidates_in_zone(board, size, regions, z)
		if cands.size() <= 1: continue
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

	for r in range(size):
		if _has_candy(board, size, regions, "row", r): continue
		var cands: Array = _candidates_in_row(board, size, regions, r)
		if cands.size() <= 1: continue
		var tz: String = CandyRules.zone_of(regions, r, cands[0][1])
		if cands.all(func(c: Array) -> bool: return CandyRules.zone_of(regions, r, c[1]) == tz):
			var elim: Array = []
			for cell in _candidates_in_zone(board, size, regions, tz):
				if cell[0] != r: elim.append(cell)
			if not elim.is_empty():
				return {"found": true, "eliminated": elim, "mode": "row_to_zone", "target_type": "zone", "target_id": tz}

	for c in range(size):
		if _has_candy(board, size, regions, "col", c): continue
		var cands: Array = _candidates_in_col(board, size, regions, c)
		if cands.size() <= 1: continue
		var tz: String = CandyRules.zone_of(regions, cands[0][0], c)
		if cands.all(func(cell: Array) -> bool: return CandyRules.zone_of(regions, cell[0], c) == tz):
			var elim: Array = []
			for cell in _candidates_in_zone(board, size, regions, tz):
				if cell[1] != c: elim.append(cell)
			if not elim.is_empty():
				return {"found": true, "eliminated": elim, "mode": "col_to_zone", "target_type": "zone", "target_id": tz}

	return {"found": false, "eliminated": [], "mode": ""}

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

static func _gen_subsets(items: Array, k: int) -> Array:
	var result: Array = []
	if k <= 0 or k > items.size():
		return result
	var indices: Array[int] = []
	for i in range(k):
		indices.append(i)
	while true:
		var subset: Array = []
		for idx in indices:
			subset.append(items[idx])
		result.append(subset)
		var i := k - 1
		while i >= 0 and indices[i] == i + items.size() - k:
			i -= 1
		if i < 0:
			break
		indices[i] += 1
		for j in range(i + 1, k):
			indices[j] = indices[j - 1] + 1
	return result

static func _popcount(mask: int) -> int:
	var count: int = 0
	var remaining: int = mask
	while remaining != 0:
		remaining &= remaining - 1
		count += 1
	return count

static func _precompute_zone_masks(board: Array, size: int, regions: Array) -> Dictionary:
	var row_masks: Dictionary = {}; var col_masks: Dictionary = {}
	var row_orders: Dictionary = {}; var col_orders: Dictionary = {}
	for zone in _zones(regions, size):
		if _has_candy(board, size, regions, "zone", zone): continue
		var row_mask: int = 0; var col_mask: int = 0
		var rows: Array = []; var cols: Array = []
		for cell in _candidates_in_zone(board, size, regions, zone):
			row_mask |= 1 << cell[0]; col_mask |= 1 << cell[1]
			if not rows.has(cell[0]): rows.append(cell[0])
			if not cols.has(cell[1]): cols.append(cell[1])
		row_masks[zone] = row_mask; col_masks[zone] = col_mask
		row_orders[zone] = rows; col_orders[zone] = cols
	return {"row": row_masks, "col": col_masks, "row_order": row_orders, "col_order": col_orders}

static func _ordered_subset_units(subset: Array, zone_orders: Dictionary) -> Array:
	var units: Array = []
	for zone in subset:
		for unit in zone_orders[zone]:
			if not units.has(unit):
				units.append(unit)
	return units

static func _try_locked_subsets(board: Array, size: int, regions: Array, max_k: int = 6) -> Dictionary:
	var all_zones := _zones(regions, size)
	var unplaced_zones: Array = []
	for z in all_zones:
		if not _has_candy(board, size, regions, "zone", z):
			unplaced_zones.append(z)
	if unplaced_zones.size() < 2:
		return {"found": false, "eliminated": []}
	var masks := _precompute_zone_masks(board, size, regions)
	var row_masks: Dictionary = masks["row"]
	var col_masks: Dictionary = masks["col"]
	var limit := mini(unplaced_zones.size() - 1, max_k)
	for k in range(2, limit + 1):
		for subset in _gen_subsets(unplaced_zones, k):
			var union_rows: int = 0
			var union_cols: int = 0
			var has_empty_zone: bool = false
			for z in subset:
				if row_masks[z] == 0:
					has_empty_zone = true
					break
				union_rows |= row_masks[z]
				union_cols |= col_masks[z]
			if has_empty_zone:
				continue
			if _popcount(union_rows) == k:
				var elim: Array = []
				for row_idx in _ordered_subset_units(subset, masks["row_order"]):
					for c in range(size):
						var z := CandyRules.zone_of(regions, row_idx, c)
						if not subset.has(z) and _is_candidate(board, size, regions, row_idx, c):
							elim.append([row_idx, c])
				if not elim.is_empty():
					var tech: int = Technique.SUBSET_PAIR if k == 2 else (Technique.SUBSET_TRIPLE if k == 3 else Technique.SUBSET_QUAD)
					return {"found": true, "eliminated": elim, "technique": tech, "subset_zones": subset}
			if _popcount(union_cols) == k:
				var elim: Array = []
				for col_idx in _ordered_subset_units(subset, masks["col_order"]):
					for r in range(size):
						var z := CandyRules.zone_of(regions, r, col_idx)
						if not subset.has(z) and _is_candidate(board, size, regions, r, col_idx):
							elim.append([r, col_idx])
				if not elim.is_empty():
					var tech: int = Technique.SUBSET_PAIR if k == 2 else (Technique.SUBSET_TRIPLE if k == 3 else Technique.SUBSET_QUAD)
					return {"found": true, "eliminated": elim, "technique": tech, "subset_zones": subset}
	return {"found": false, "eliminated": []}

static func _clone_board(board: Array, size: int) -> Array:
	var clone: Array = []
	for r in range(size):
		clone.append(board[r].duplicate())
	return clone

static func _check_contradiction(board: Array, size: int, regions: Array) -> Dictionary:
	for z in _zones(regions, size):
		if not _has_candy(board, size, regions, "zone", z) and _candidates_in_zone(board, size, regions, z).is_empty():
			return {"found": true, "type": "zone", "index": z}
	for r in range(size):
		if not _has_candy(board, size, regions, "row", r) and _candidates_in_row(board, size, regions, r).is_empty():
			return {"found": true, "type": "row", "index": r}
	for c in range(size):
		if not _has_candy(board, size, regions, "col", c) and _candidates_in_col(board, size, regions, c).is_empty():
			return {"found": true, "type": "col", "index": c}
	return {"found": false, "type": "", "index": -1}

static func _propagate_with_trace(board: Array, size: int, regions: Array, max_depth: int) -> Dictionary:
	var steps: Array = []
	var depth: int = 0
	for _i in range(size * size):
		_apply_elimination(board, size, regions)
		var c := _check_contradiction(board, size, regions)
		if c["found"]:
			return {"contradiction": true, "depth": depth, "steps": steps, "contra_type": c["type"], "contra_index": c["index"]}
		var s2 := _try_single_candidate(board, size, regions)
		if s2.get("found", false):
			var cell: Array = s2["cell"]
			board[cell[0]][cell[1]] = CellModel.CellKind.CANDY
			steps.append(cell)
			depth += 1
			if depth > max_depth: break
			continue
		break
	var fc := _check_contradiction(board, size, regions)
	if fc["found"]:
		return {"contradiction": true, "depth": depth, "steps": steps, "contra_type": fc["type"], "contra_index": fc["index"]}
	return {"contradiction": false, "depth": depth, "steps": steps, "contra_type": "", "contra_index": -1}

static func _try_contradiction(board: Array, size: int, regions: Array, max_depth: int = 99) -> Dictionary:
	var best_result: Dictionary = {"found": false, "eliminated": []}
	var best_depth: int = size * size
	for r in range(size):
		for c in range(size):
			if not _is_candidate(board, size, regions, r, c): continue
			var test_board := _clone_board(board, size)
			test_board[r][c] = CellModel.CellKind.CANDY
			var chain := _propagate_with_trace(test_board, size, regions, max_depth)
			if chain["contradiction"] and chain["depth"] < best_depth:
				best_depth = chain["depth"]
				best_result = {
					"found": true, "eliminated": [[r, c]], "technique": Technique.CONTRA_CHAIN,
					"chain_detail": {
						"hypothesis_cell": [r, c], "depth": chain["depth"],
						"steps": chain["steps"], "contra_type": chain["contra_type"],
						"contra_index": chain["contra_index"],
					}
				}
	return best_result

# candy_rules.gd
extends RefCounted

const CellModel = preload("res://scripts/core/cell_model.gd")

enum Clash { NONE = 0, SAME_ROW = 1, SAME_COL = 2, SAME_ZONE = 3, TOUCHING = 4 }

static func zone_of(regions: Array, row: int, col: int) -> String:
	if row < 0 or row >= regions.size():
		return ""
	var row_str: String = str(regions[row])
	if col < 0 or col >= row_str.length():
		return ""
	return row_str[col]

static func can_place(board: Array, regions: Array, row: int, col: int) -> bool:
	var size: int = regions.size()
	if row < 0 or row >= size or col < 0 or col >= size:
		return false
	if not CellModel.is_available(board[row][col]):
		return false

	var target_zone: String = zone_of(regions, row, col)

	for c in range(size):
		if c != col and CellModel.is_placed(board[row][c]):
			return false

	for r in range(size):
		if r != row and CellModel.is_placed(board[r][col]):
			return false

	for r in range(size):
		for c in range(size):
			if (r != row or c != col) and zone_of(regions, r, c) == target_zone and CellModel.is_placed(board[r][c]):
				return false

	for dr in [-1, 0, 1]:
		for dc in [-1, 0, 1]:
			if dr == 0 and dc == 0:
				continue
			var nr: int = row + dr
			var nc: int = col + dc
			if nr >= 0 and nr < size and nc >= 0 and nc < size:
				if CellModel.is_placed(board[nr][nc]):
					return false

	return true

static func detect_clash(regions: Array, _board: Array, a: Array, b: Array) -> int:
	if a[0] == b[0] and a[1] == b[1]:
		return Clash.NONE
	if a[0] == b[0]:
		return Clash.SAME_ROW
	if a[1] == b[1]:
		return Clash.SAME_COL
	if zone_of(regions, a[0], a[1]) == zone_of(regions, b[0], b[1]):
		return Clash.SAME_ZONE
	if abs(a[0] - b[0]) <= 1 and abs(a[1] - b[1]) <= 1:
		return Clash.TOUCHING
	return Clash.NONE

static func attempt_candy(board: Array, regions: Array, solution: Array,
		hearts: int, mistake_count: int, row: int, col: int) -> Dictionary:
	var size: int = regions.size()
	if solution[row] == col:
		board[row][col] = CellModel.CellKind.CANDY
		var won: bool = correct_count(board) == size
		return {
			"board": board,
			"hearts": hearts,
			"mistake_count": mistake_count,
			"phase": "won" if won else "active",
			"events": ["CandyFound"],
			"reason": "",
		}

	board[row][col] = CellModel.CellKind.ERROR
	var new_hearts: int = hearts - 1
	var new_mistakes: int = mistake_count + 1
	var reason: String = ""

	for r in range(size):
		for c in range(size):
			if CellModel.is_placed(board[r][c]):
				var clash: int = detect_clash(regions, board, [row, col], [r, c])
				match clash:
					Clash.SAME_ROW:
						reason = "same_row"
						break
					Clash.SAME_COL:
						reason = "same_col"
						break
					Clash.SAME_ZONE:
						reason = "same_zone"
						break
					Clash.TOUCHING:
						reason = "touching"
						break
		if reason != "":
			break

	if reason == "":
		reason = "not_solution"

	var failed: bool = new_hearts <= 0
	return {
		"board": board,
		"hearts": new_hearts,
		"mistake_count": new_mistakes,
		"phase": "failed" if failed else "active",
		"events": ["Mistake"],
		"reason": reason,
	}

static func tally(cur_correct: int, mistakes: int) -> int:
	return maxi(0, 100 * cur_correct - 25 * mistakes)

static func correct_count(board: Array) -> int:
	var count: int = 0
	for r in range(board.size()):
		for c in range(board[r].size()):
			if CellModel.is_placed(board[r][c]):
				count += 1
	return count

static func verify_level(level: Dictionary) -> bool:
	if not level.has("size") or not level.has("regions") or not level.has("solution"):
		return false
	var size: int = int(level["size"])
	var regions: Array = level["regions"]
	var solution: Array = level["solution"]

	if size < 4 or regions.size() != size or solution.size() != size:
		return false

	for r in range(size):
		if str(regions[r]).length() != size:
			return false

	var used_cols: Dictionary = {}
	var used_zones: Dictionary = {}
	for r in range(size):
		var c: int = int(solution[r])
		if c < 0 or c >= size:
			return false
		if used_cols.has(c):
			return false
		used_cols[c] = true

		var zone: String = zone_of(regions, r, c)
		if used_zones.has(zone):
			return false
		used_zones[zone] = true

	for r1 in range(size):
		for r2 in range(r1 + 1, size):
			var c1: int = int(solution[r1])
			var c2: int = int(solution[r2])
			if abs(r1 - r2) <= 1 and abs(c1 - c2) <= 1:
				return false

	return true

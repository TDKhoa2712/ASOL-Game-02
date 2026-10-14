# Resolves the semantic targets of the tutorial script into board cells.
# Pure and stateless: the script names a region or rule, never a coordinate,
# so the lesson text stays correct for the hand-authored board it ships with.
extends RefCounted

const SCRIPT_PATH := "res://data/tutorial/tutorial.json"
const SCRIPT_VERSION := 1

static func load_script(path: String = SCRIPT_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or int(parsed.get("tutorialVersion", 0)) != SCRIPT_VERSION or not parsed.get("levels") is Dictionary:
		return {}
	return parsed

# Returns the cells a target spec names, as [[r, c], ...] in row-major order.
static func resolve(level: Dictionary, target: Dictionary) -> Array:
	match str(target.get("type", "")):
		"candy_of_region":
			var cell := candy_of_region(level, str(target.get("region", "")))
			return [] if cell.is_empty() else [cell]
		"diagonal_of_region":
			var cell := candy_of_region(level, str(target.get("region", "")))
			if cell.is_empty():
				return []
			var diagonals := _diagonals(int(level.size), cell)
			return [] if diagonals.is_empty() else [diagonals[0]]
		"excluded_by_region":
			var cell := candy_of_region(level, str(target.get("region", "")))
			return [] if cell.is_empty() else excluded_by(level, [cell])
		"region_column_lock":
			return region_column_lock(level, str(target.get("region", "")))
	return []

static func candy_of_region(level: Dictionary, region: String) -> Array:
	var solution: Array = level.get("solution", [])
	for r in range(solution.size()):
		var c := int(solution[r])
		if region_at(level, r, c) == region:
			return [r, c]
	return []

static func region_at(level: Dictionary, r: int, c: int) -> String:
	var rows: Array = level.get("regions", [])
	if r < 0 or r >= rows.size() or c < 0 or c >= str(rows[r]).length():
		return ""
	return str(rows[r])[c]

static func conflicts(level: Dictionary, a: Array, b: Array) -> bool:
	return a[0] == b[0] or a[1] == b[1] \
		or region_at(level, a[0], a[1]) == region_at(level, b[0], b[1]) \
		or (absi(a[0] - b[0]) <= 1 and absi(a[1] - b[1]) <= 1)

# Every cell that the candies rule out (row, column, region, touching).
static func excluded_by(level: Dictionary, candies: Array) -> Array:
	var out: Array = []
	var n := int(level.get("size", 0))
	for r in range(n):
		for c in range(n):
			var cell := [r, c]
			if candies.has(cell):
				continue
			for candy in candies:
				if conflicts(level, cell, candy):
					out.append(cell)
					break
	return out

# S3 pointing: when every open cell of a region sits in one column, the rest of
# that column cannot hold a candy (judged on the empty board).
static func region_column_lock(level: Dictionary, region: String) -> Array:
	var n := int(level.get("size", 0))
	var column := -1
	for r in range(n):
		for c in range(n):
			if region_at(level, r, c) != region:
				continue
			if column >= 0 and column != c:
				return []
			column = c
	if column < 0:
		return []
	var out: Array = []
	for r in range(n):
		var cell := [r, column]
		if region_at(level, r, column) != region:
			out.append(cell)
	return out

# Counts solutions up to `limit` with a plain backtracking search; used by tests
# and the content check to prove the authored boards stay unique.
static func count_solutions(level: Dictionary, limit: int = 2) -> int:
	var n := int(level.get("size", 0))
	return _count(level, n, 0, [], {}, limit)

static func _count(level: Dictionary, n: int, row: int, placed: Array, fixed: Dictionary, limit: int) -> int:
	if row == n:
		return 1
	var total := 0
	for c in range(n):
		if fixed.has(row) and fixed[row] != c:
			continue
		var cell := [row, c]
		var ok := true
		for other in placed:
			if conflicts(level, cell, other):
				ok = false
				break
		if not ok:
			continue
		placed.append(cell)
		total += _count(level, n, row + 1, placed, fixed, limit - total)
		placed.pop_back()
		if total >= limit:
			break
	return total

static func _diagonals(n: int, cell: Array) -> Array:
	var out: Array = []
	for d in [[1, -1], [1, 1], [-1, -1], [-1, 1]]:
		var r: int = cell[0] + d[0]
		var c: int = cell[1] + d[1]
		if r >= 0 and r < n and c >= 0 and c < n:
			out.append([r, c])
	return out

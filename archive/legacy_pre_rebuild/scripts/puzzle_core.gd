extends RefCounted

# Data-only puzzle rules. The gesture layer decides when an action is committed.

enum Violation { NONE, ROW, COLUMN, REGION, DIAGONAL }

const VIOLATION_PRIORITY := [Violation.ROW, Violation.COLUMN, Violation.REGION, Violation.DIAGONAL]


static func find_conflicts(level: Dictionary, cells: Dictionary) -> Array:
	var candy_positions: Array = []
	var size := int(level["size"])
	for row in range(size):
		for col in range(size):
			var key := cell_key([row, col])
			if is_given(level, [row, col]) or cells.get(key, "empty") == "candy":
				candy_positions.append([row, col])
	var conflicts := {}
	for i in range(candy_positions.size()):
		for j in range(i + 1, candy_positions.size()):
			var v := classify_violation(level, candy_positions[i], candy_positions[j])
			if v != Violation.NONE:
				conflicts[cell_key(candy_positions[i])] = true
				conflicts[cell_key(candy_positions[j])] = true
	return conflicts.keys()


static func classify_violation(level: Dictionary, cell_a: Array, cell_b: Array) -> int:
	var ra := int(cell_a[0])
	var ca := int(cell_a[1])
	var rb := int(cell_b[0])
	var cb := int(cell_b[1])
	if ra == rb:
		return Violation.ROW
	if ca == cb:
		return Violation.COLUMN
	var reg_a: String = str(level["regions"][ra]).substr(ca, 1)
	var reg_b: String = str(level["regions"][rb]).substr(cb, 1)
	if reg_a == reg_b:
		return Violation.REGION
	if abs(ra - rb) == 1 and abs(ca - cb) == 1:
		return Violation.DIAGONAL
	return Violation.NONE


static func find_priority_conflict(level: Dictionary, cells: Dictionary, cell: Array) -> Dictionary:
	var best_violation: int = Violation.NONE
	var best_cell: Array = []
	var size := int(level["size"])
	for row in range(size):
		for col in range(size):
			if row == int(cell[0]) and col == int(cell[1]):
				continue
			var other := [row, col]
			var key := cell_key(other)
			if not (is_given(level, other) or cells.get(key, "empty") == "candy"):
				continue
			var v := classify_violation(level, cell, other)
			if v == Violation.NONE:
				continue
			if best_violation == Violation.NONE or VIOLATION_PRIORITY.find(v) < VIOLATION_PRIORITY.find(best_violation):
				best_violation = v
				best_cell = other
	if best_violation == Violation.NONE:
		return {"violation": Violation.NONE}
	return {"violation": best_violation, "cell": best_cell}


static func score(correct_placed_count: int, mistake_count: int) -> int:
	return maxi(0, 100 * correct_placed_count - 25 * mistake_count)


static func cell_key(cell: Array) -> String:
	return "%d,%d" % [int(cell[0]), int(cell[1])]


static func in_bounds(level: Dictionary, cell: Array) -> bool:
	if cell.size() != 2:
		return false
	var size := int(level["size"])
	return int(cell[0]) >= 0 and int(cell[0]) < size and int(cell[1]) >= 0 and int(cell[1]) < size


static func is_given(level: Dictionary, cell: Array) -> bool:
	for given_value in level.get("givens", []):
		var given: Dictionary = given_value
		if int(given["r"]) == int(cell[0]) and int(given["c"]) == int(cell[1]):
			return true
	return false


static func cell_state(level: Dictionary, cells: Dictionary, cell: Array) -> String:
	if is_given(level, cell):
		return "candy"
	return str(cells.get(cell_key(cell), "empty"))


static func correct_placed_count(level: Dictionary, cells: Dictionary) -> int:
	var count := 0
	for row in range(int(level["size"])):
		var cell := [row, int(level["solution"][row])]
		if cell_state(level, cells, cell) == "candy":
			count += 1
	return count


static func mistake_reason(level: Dictionary, cells: Dictionary, cell: Array) -> String:
	var result := find_priority_conflict(level, cells, cell)
	var v: int = result["violation"]
	if v == Violation.ROW:
		return "row"
	if v == Violation.COLUMN:
		return "column"
	if v == Violation.REGION:
		return "region"
	if v == Violation.DIAGONAL:
		return "diagonal"
	return "neutral"


static func try_candy(level: Dictionary, cells: Dictionary, hearts: int, mistakes: int, cell: Array) -> Dictionary:
	var result := {"cells": cells.duplicate(true), "hearts": hearts, "mistakeCount": mistakes, "state": "Playing", "events": []}
	if hearts <= 0:
		result["state"] = "Failed"
		result["events"].append("NoOp")
		return result
	if not in_bounds(level, cell) or cell_state(level, cells, cell) not in ["empty", "x"]:
		result["events"].append("NoOp")
		return result
	var key := cell_key(cell)
	var old_score := score(correct_placed_count(level, cells) - level.get("givens", []).size(), mistakes)
	if int(level["solution"][int(cell[0])]) == int(cell[1]):
		result["cells"][key] = "candy"
		result["events"].append("CandyFound")
		if correct_placed_count(level, result["cells"]) == int(level["size"]):
			result["state"] = "Won"
			result["events"].append("LevelWon")
	else:
		result["cells"][key] = "x_error"
		result["hearts"] = hearts - 1
		result["mistakeCount"] = mistakes + 1
		result["events"].append("Mistake")
		result["events"].append("HeartLost")
		result["reason"] = mistake_reason(level, cells, cell)
		if result["hearts"] == 0:
			result["state"] = "Failed"
			result["events"].append("LevelFailed")
	var new_score := score(correct_placed_count(level, result["cells"]) - level.get("givens", []).size(), int(result["mistakeCount"]))
	if new_score != old_score:
		result["events"].append("ScoreChanged")
	return result


static func validate_level(level: Dictionary) -> bool:
	if not level.has_all(["size", "regions", "solution", "givens"]):
		return false
	var size := int(level["size"])
	if size < 4 or size > 12 or level["regions"].size() != size or level["solution"].size() != size:
		return false
	var columns := {}
	var regions := {}
	var region_cells := {}
	for row in range(size):
		if str(level["regions"][row]).length() != size:
			return false
		for grid_col in range(size):
			var label := str(level["regions"][row][grid_col])
			if not region_cells.has(label):
				region_cells[label] = []
			region_cells[label].append([row, grid_col])
		var col := int(level["solution"][row])
		if col < 0 or col >= size or columns.has(col):
			return false
		columns[col] = true
		var region := str(level["regions"][row][col])
		if regions.has(region):
			return false
		regions[region] = true
		if row > 0 and abs(col - int(level["solution"][row - 1])) <= 1:
			return false
	if regions.size() != size or region_cells.size() != size:
		return false
	for label in region_cells:
		if not regions.has(label) or not _region_connected(region_cells[label]):
			return false
	var given_rows := {}
	for given_value in level["givens"]:
		var given: Dictionary = given_value
		var row := int(given["r"])
		if row < 0 or row >= size or given_rows.has(row) or int(given["c"]) != int(level["solution"][row]):
			return false
		given_rows[row] = true
	return _count_solutions(level, 0, {}, {}, -100, given_rows) == 1


static func _region_connected(region_cells: Array) -> bool:
	var remaining := {}
	for cell in region_cells:
		remaining[cell_key(cell)] = true
	var frontier: Array = [region_cells[0]]
	remaining.erase(cell_key(region_cells[0]))
	while not frontier.is_empty():
		var cell: Array = frontier.pop_back()
		for neighbor in [[cell[0] - 1, cell[1]], [cell[0] + 1, cell[1]], [cell[0], cell[1] - 1], [cell[0], cell[1] + 1]]:
			var key := cell_key(neighbor)
			if remaining.has(key):
				remaining.erase(key)
				frontier.append(neighbor)
	return remaining.is_empty()


static func _count_solutions(level: Dictionary, row: int, columns: Dictionary, regions: Dictionary, previous_col: int, given_rows: Dictionary) -> int:
	var size := int(level["size"])
	if row == size:
		return 1
	var total := 0
	for col in range(size):
		if given_rows.has(row) and col != int(level["solution"][row]):
			continue
		var region := str(level["regions"][row][col])
		if columns.has(col) or regions.has(region) or abs(col - previous_col) <= 1:
			continue
		columns[col] = true
		regions[region] = true
		total += _count_solutions(level, row + 1, columns, regions, col, given_rows)
		columns.erase(col)
		regions.erase(region)
		if total >= 2:
			return 2
	return total

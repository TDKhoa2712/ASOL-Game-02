extends RefCounted

const LEVEL_KEYS := ["schemaVersion", "id", "order", "size", "regions", "givens", "solution", "difficulty", "tags", "logicTrace"]
const STEP_KEYS := ["rule", "focus", "conclusion", "textKey"]
const S3_KEYS := ["rule", "source", "target", "conclusion", "textKey"]
const UNIT_KEYS := ["type", "id"]
const RELEASE_MAX_ORDER := 30
const RELEASE_MAX_SIZE := 6

static var _id_regex: RegEx = null


static func load_document(path: String, release: bool = false) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _failure("", "file not found: %s" % path)
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return _failure("", "root must be an object")
	return validate_document(parsed, release)


static func validate_document(data: Dictionary, release: bool = false) -> Dictionary:
	var root_error := _require_keys(data, ["levels"], "root")
	if not root_error.is_empty():
		return _failure("", root_error)
	if typeof(data["levels"]) != TYPE_ARRAY or data["levels"].is_empty():
		return _failure("", "levels must be a nonempty array")
	var ids := {}
	var orders := {}
	var valid_levels: Array = []
	for level_value in data["levels"]:
		if typeof(level_value) != TYPE_DICTIONARY:
			return _failure("", "level must be an object")
		var level: Dictionary = level_value
		var level_id := str(level.get("id", "<missing id>"))
		var result := validate_level(level, release)
		if not result.get("ok", false):
			return _failure(level_id, result.get("error", {}).get("reason", "invalid level"))
		if ids.has(level_id):
			return _failure(level_id, "duplicate id")
		ids[level_id] = true
		var order: int = level["order"]
		if orders.has(order):
			return _failure(level_id, "duplicate order %d" % order)
		orders[order] = true
		valid_levels.append(level)
	if release:
		for order in range(1, RELEASE_MAX_ORDER + 1):
			if not orders.has(order):
				return _failure("", "release missing order %d" % order)
	return {"ok": true, "levels": valid_levels, "warnings": []}


static func validate_level(level: Dictionary, release: bool = false) -> Dictionary:
	var keys_error := _require_keys(level, LEVEL_KEYS, "level")
	if not keys_error.is_empty():
		return _failure(str(level.get("id", "")), keys_error)
	var level_id = level["id"]
	if typeof(level_id) != TYPE_STRING or not _matches_id(level_id):
		return _failure(str(level_id), "invalid id")
	if not _is_int(level["schemaVersion"]) or level["schemaVersion"] != 4:
		return _failure(str(level_id), "schemaVersion must be 4")
	if not _is_int(level["order"]) or level["order"] < 1:
		return _failure(str(level_id), "order must be an integer >=1")
	var n: int = level["size"]
	if not _is_int(level["size"]) or n < 4 or n > 12:
		return _failure(str(level_id), "size must be an integer from 4 to 12")
	var rows = level["regions"]
	if typeof(rows) != TYPE_ARRAY or rows.size() != n:
		return _failure(str(level_id), "regions must contain N strings")
	for row_value in rows:
		if typeof(row_value) != TYPE_STRING or row_value.length() != n:
			return _failure(str(level_id), "regions must contain N strings of length N")
	var region_error := _validate_regions(rows, n)
	if not region_error.is_empty():
		return _failure(str(level_id), region_error)
	var solution = level["solution"]
	if typeof(solution) != TYPE_ARRAY or solution.size() != n:
		return _failure(str(level_id), "solution must be a permutation of integer columns")
	var seen_columns := {}
	for column_value in solution:
		if not _is_int(column_value) or column_value < 0 or column_value >= n or seen_columns.has(column_value):
			return _failure(str(level_id), "solution must be a permutation of integer columns")
		seen_columns[column_value] = true
	var givens = level["givens"]
	if typeof(givens) != TYPE_ARRAY:
		return _failure(str(level_id), "givens must be an array")
	var given_by_row := {}
	for given_value in givens:
		if typeof(given_value) != TYPE_DICTIONARY:
			return _failure(str(level_id), "given must be an object")
		var given: Dictionary = given_value
		var given_error := _require_keys(given, ["r", "c"], "given")
		if not given_error.is_empty():
			return _failure(str(level_id), given_error)
		if not _is_int(given["r"]) or not _is_int(given["c"]):
			return _failure(str(level_id), "given coordinates must be integers")
		var row: int = given["r"]
		var column: int = given["c"]
		if row < 0 or row >= n or column < 0 or column >= n or given_by_row.has(row) or solution[row] != column:
			return _failure(str(level_id), "given is duplicate, out of bounds, or differs from solution")
		given_by_row[row] = column
	if not _solution_satisfies(rows, solution):
		return _failure(str(level_id), "declared solution violates board constraints")
	if _count_solutions(rows, solution, given_by_row, 0, {}, {}, -100) != 1:
		return _failure(str(level_id), "expected exactly one independent solution")
	if typeof(level["difficulty"]) != TYPE_STRING or not ["tutorial", "easy", "medium", "hard"].has(level["difficulty"]):
		return _failure(str(level_id), "invalid difficulty")
	var tags = level["tags"]
	if typeof(tags) != TYPE_ARRAY or tags.is_empty():
		return _failure(str(level_id), "tags must be nonempty strings")
	var seen_tags := {}
	for tag in tags:
		if typeof(tag) != TYPE_STRING or tag.is_empty() or seen_tags.has(tag):
			return _failure(str(level_id), "tags must be unique nonempty strings")
		seen_tags[tag] = true
	if typeof(level["logicTrace"]) != TYPE_ARRAY:
		return _failure(str(level_id), "logicTrace must be an array")
	var trace_result := _validate_trace(level, given_by_row)
	if not trace_result.is_empty():
		return _failure(str(level_id), trace_result)
	if release:
		if level["order"] < 1 or level["order"] > RELEASE_MAX_ORDER:
			return _failure(str(level_id), "release order must be 1..%d" % RELEASE_MAX_ORDER)
		if n > RELEASE_MAX_SIZE or level["difficulty"] == "hard":
			return _failure(str(level_id), "release supports size 4..6 and no hard level")
		if n - givens.size() < 2:
			return _failure(str(level_id), "release needs at least two playable candies")
		var rules: Array = []
		for step in level["logicTrace"]:
			if typeof(step) == TYPE_DICTIONARY:
				rules.append(step.get("rule", ""))
		if level["order"] <= 18 and rules.has("S3"):
			return _failure(str(level_id), "release orders 1..18 cannot use S3")
		if level["order"] >= 19 and level["order"] <= 24:
			if not rules.has("S3"):
				return _failure(str(level_id), "release orders 19..24 require S3")
			if _s2_only_reaches_solution(rows, given_by_row):
				return _failure(str(level_id), "release S3 must be necessary")
	return {"ok": true, "level": level}


static func _validate_trace(level: Dictionary, given_by_row: Dictionary) -> String:
	var rows: Array = level["regions"]
	var n: int = level["size"]
	var candies := given_by_row.duplicate()
	var eliminated := {}
	for index in range(level["logicTrace"].size()):
		var step_value = level["logicTrace"][index]
		var label: String = "trace step %d" % (index + 1)
		if typeof(step_value) != TYPE_DICTIONARY:
			return "%s: step must be an object" % label
		var step: Dictionary = step_value
		if step.get("rule", "") == "S3":
			var s3_error := _validate_s3(rows, candies, eliminated, step)
			if not s3_error.is_empty():
				return "%s: %s" % [label, s3_error]
			continue
		if step.get("rule", "") != "S2":
			return "%s: unsupported rule %s" % [label, str(step.get("rule", ""))]
		var keys_error := _require_keys(step, STEP_KEYS, label)
		if not keys_error.is_empty():
			return "%s: %s" % [label, keys_error]
		var focus: Dictionary = step["focus"]
		if typeof(focus) != TYPE_DICTIONARY:
			return "%s: focus must be an object" % label
		var focus_error := _require_keys(focus, UNIT_KEYS, "focus")
		if not focus_error.is_empty():
			return "%s: %s" % [label, focus_error]
		var unit := _unit_cells(rows, focus)
		if unit.is_empty():
			return "%s: invalid focus" % label
		if _unit_contains_candy(unit, candies):
			return "%s: focus already contains a candy" % label
		var candidates := _possible_cells(rows, candies, eliminated)
		var focus_candidates := _intersect(candidates, unit)
		var conclusion = step["conclusion"]
		if typeof(conclusion) != TYPE_DICTIONARY:
			return "%s: conclusion must be an object" % label
		var conclusion_error := _require_keys(conclusion, ["type", "r", "c"], "conclusion")
		if not conclusion_error.is_empty() or conclusion.get("type") != "place":
			return "%s: S2 conclusion must place a candy" % label
		if not _is_int(conclusion["r"]) or not _is_int(conclusion["c"]) or not focus_candidates.has(_cell_key(conclusion["r"], conclusion["c"])):
			return "%s: S2 target is not the sole candidate" % label
		var target_key := _cell_key(conclusion["r"], conclusion["c"])
		if focus_candidates.size() != 1 or not focus_candidates.has(target_key):
			return "%s: S2 focus must have exactly one candidate" % label
		var expected_text := "hint.single.%s" % str(focus["type"])
		if step["textKey"] != expected_text:
			return "%s: textKey does not match focus" % label
		candies[int(conclusion["r"])] = int(conclusion["c"])
	if candies.size() != n:
		return "trace ends with %d/%d candies" % [candies.size(), n]
	return ""


static func _validate_s3(rows: Array, candies: Dictionary, eliminated: Dictionary, step: Dictionary) -> String:
	var keys_error := _require_keys(step, S3_KEYS, "S3 step")
	if not keys_error.is_empty():
		return keys_error
	var source = step["source"]
	var target = step["target"]
	if typeof(source) != TYPE_DICTIONARY or typeof(target) != TYPE_DICTIONARY:
		return "S3 source and target must be objects"
	if _require_keys(source, UNIT_KEYS, "S3 source") != "" or _require_keys(target, UNIT_KEYS, "S3 target") != "":
		return "S3 units require type and id"
	if source["type"] == target["type"]:
		return "S3 source and target must have different unit types"
	var source_unit := _unit_cells(rows, source)
	var target_unit := _unit_cells(rows, target)
	if source_unit.is_empty() or target_unit.is_empty():
		return "S3 source or target is invalid"
	if _unit_contains_candy(source_unit, candies) or _unit_contains_candy(target_unit, candies):
		return "S3 units must not already contain a candy"
	var candidates := _possible_cells(rows, candies, eliminated)
	var source_candidates := _intersect(candidates, source_unit)
	if source_candidates.is_empty() or not _is_subset(source_candidates, target_unit):
		return "S3 source candidates must be nonempty and contained in target"
	var expected := _difference(_intersect(candidates, target_unit), source_unit)
	if expected.is_empty():
		return "S3 must eliminate at least one new candidate"
	var conclusion = step["conclusion"]
	if typeof(conclusion) != TYPE_DICTIONARY or _require_keys(conclusion, ["type", "cells"], "S3 conclusion") != "" or conclusion.get("type") != "eliminate":
		return "S3 conclusion must eliminate cells"
	var declared: Variant = _cells_from_json(conclusion["cells"], rows.size())
	if declared == null:
		return "S3 conclusion cells are invalid or duplicated"
	if not _same_set(declared, expected):
		return "S3 conclusion cells differ from expected elimination"
	if step["textKey"] != "hint.lock.intersection":
		return "S3 textKey must be hint.lock.intersection"
	for key in expected:
		eliminated[key] = true
	return ""


static func _validate_regions(rows: Array, n: int) -> String:
	var cells_by_region := {}
	for row in range(n):
		for column in range(n):
			var label: String = rows[row].substr(column, 1)
			if not _region_label_valid(label, n):
				return "regions contain invalid label %s" % label
			if not cells_by_region.has(label):
				cells_by_region[label] = []
			cells_by_region[label].append(_cell_key(row, column))
	if cells_by_region.size() != n:
		return "regions must use exactly N labels"
	for index in range(n):
		var label: String = char(65 + index)
		if not cells_by_region.has(label) or not _connected(cells_by_region[label], n):
			return "region %s is missing or disconnected" % label
	return ""


static func _connected(region: Array, n: int) -> bool:
	if region.is_empty():
		return false
	var remaining := {}
	for cell in region:
		remaining[str(cell)] = true
	var first: String = str(remaining.keys()[0])
	var frontier := [first]
	remaining.erase(first)
	while not frontier.is_empty():
		var key: String = frontier.pop_back()
		var parts := key.split(",")
		var row: int = int(parts[0])
		var column: int = int(parts[1])
		for neighbor in [[row - 1, column], [row + 1, column], [row, column - 1], [row, column + 1]]:
			if neighbor[0] < 0 or neighbor[0] >= n or neighbor[1] < 0 or neighbor[1] >= n:
				continue
			var neighbor_key := _cell_key(neighbor[0], neighbor[1])
			if remaining.has(neighbor_key):
				remaining.erase(neighbor_key)
				frontier.append(neighbor_key)
	return remaining.is_empty()


static func _solution_satisfies(rows: Array, solution: Array) -> bool:
	var columns := {}
	var regions := {}
	for row in range(rows.size()):
		var column: int = int(solution[row])
		var region: String = rows[row].substr(column, 1)
		if columns.has(column) or regions.has(region) or (row > 0 and abs(column - int(solution[row - 1])) <= 1):
			return false
		columns[column] = true
		regions[region] = true
	return columns.size() == rows.size() and regions.size() == rows.size()


static func _count_solutions(rows: Array, solution: Array, givens: Dictionary, row: int, columns: Dictionary, regions: Dictionary, previous_column: int) -> int:
	var n: int = rows.size()
	if row == n:
		return 1
	var total := 0
	for column in range(n):
		if givens.has(row) and column != givens[row]:
			continue
		var region: String = rows[row].substr(column, 1)
		if columns.has(column) or regions.has(region) or (row > 0 and abs(column - previous_column) <= 1):
			continue
		columns[column] = true
		regions[region] = true
		total += _count_solutions(rows, solution, givens, row + 1, columns, regions, column)
		columns.erase(column)
		regions.erase(region)
		if total >= 2:
			return 2
	return total


static func _s2_only_reaches_solution(rows: Array, givens: Dictionary) -> bool:
	var candies := givens.duplicate()
	var n: int = rows.size()
	while candies.size() < n:
		var candidates := _possible_cells(rows, candies, {})
		var placements := {}
		for unit in _all_units(rows, n):
			if _unit_contains_candy(unit, candies):
				continue
			var remaining := _intersect(candidates, unit)
			if remaining.size() == 1:
				placements[remaining.keys()[0]] = true
		if placements.is_empty():
			return false
		for key in placements:
			var parts := str(key).split(",")
			candies[int(parts[0])] = int(parts[1])
	return true


static func _all_units(rows: Array, n: int) -> Array:
	var units: Array = []
	for row in range(n):
		var unit := {}
		for column in range(n):
			unit[_cell_key(row, column)] = true
		units.append(unit)
	for column in range(n):
		var unit := {}
		for row in range(n):
			unit[_cell_key(row, column)] = true
		units.append(unit)
	for label_index in range(n):
		var unit := {}
		var label := char(65 + label_index)
		for row in range(n):
			for column in range(n):
				if rows[row].substr(column, 1) == label:
					unit[_cell_key(row, column)] = true
		units.append(unit)
	return units


static func _unit_cells(rows: Array, spec: Dictionary) -> Dictionary:
	var result := {}
	var kind := str(spec.get("type", ""))
	var id = spec.get("id", null)
	var n: int = rows.size()
	if kind == "row" and _is_int(id) and id >= 0 and id < n:
		for column in range(n):
			result[_cell_key(id, column)] = true
	elif kind == "column" and _is_int(id) and id >= 0 and id < n:
		for row in range(n):
			result[_cell_key(row, id)] = true
	elif kind == "region" and typeof(id) == TYPE_STRING and _region_label_valid(id, n):
		for row in range(n):
			for column in range(n):
				if rows[row].substr(column, 1) == id:
					result[_cell_key(row, column)] = true
	return result


static func _possible_cells(rows: Array, candies: Dictionary, eliminated: Dictionary) -> Dictionary:
	var result := {}
	var n: int = rows.size()
	for row in range(n):
		for column in range(n):
			var key: String = _cell_key(row, column)
			if candies.has(row) or eliminated.has(key):
				continue
			if _exclusion_reason(rows, candies, row, column) == "":
				result[key] = true
	return result


static func _exclusion_reason(rows: Array, candies: Dictionary, row: int, column: int) -> String:
	for candy_row in candies:
		var candy_column: int = candies[candy_row]
		if candy_row == row:
			return "row"
		if candy_column == column:
			return "column"
		if rows[candy_row].substr(candy_column, 1) == rows[row].substr(column, 1):
			return "region"
		if abs(candy_row - row) == 1 and abs(candy_column - column) == 1:
			return "diagonal"
	return ""


static func _cells_from_json(value, n: int):
	if typeof(value) != TYPE_ARRAY:
		return null
	var result := {}
	for cell_value in value:
		if typeof(cell_value) != TYPE_DICTIONARY or _require_keys(cell_value, ["r", "c"], "cell") != "":
			return null
		if not _is_int(cell_value["r"]) or not _is_int(cell_value["c"]) or cell_value["r"] < 0 or cell_value["r"] >= n or cell_value["c"] < 0 or cell_value["c"] >= n:
			return null
		var key := _cell_key(cell_value["r"], cell_value["c"])
		if result.has(key):
			return null
		result[key] = true
	return result


static func _unit_contains_candy(unit: Dictionary, candies: Dictionary) -> bool:
	for row in candies:
		if unit.has(_cell_key(row, candies[row])):
			return true
	return false


static func _intersect(left: Dictionary, right: Dictionary) -> Dictionary:
	var result := {}
	for key in left:
		if right.has(key):
			result[key] = true
	return result


static func _difference(left: Dictionary, right: Dictionary) -> Dictionary:
	var result := {}
	for key in left:
		if not right.has(key):
			result[key] = true
	return result


static func _is_subset(left: Dictionary, right: Dictionary) -> bool:
	for key in left:
		if not right.has(key):
			return false
	return true


static func _same_set(left: Dictionary, right: Dictionary) -> bool:
	return left.size() == right.size() and _is_subset(left, right)


static func _is_int(value) -> bool:
	return typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and is_equal_approx(value, round(value)))


static func _region_label_valid(label: String, n: int) -> bool:
	return label.length() == 1 and label.unicode_at(0) >= 65 and label.unicode_at(0) < 65 + n


static func _cell_key(row: int, column: int) -> String:
	return "%d,%d" % [row, column]


static func _require_keys(value: Dictionary, expected: Array, label: String) -> String:
	for key in expected:
		if not value.has(key):
			return "%s fields missing %s" % [label, key]
	for key in value.keys():
		if not expected.has(key):
			return "%s fields contain unsupported %s" % [label, key]
	return ""


static func _matches_id(value: String) -> bool:
	if _id_regex == null:
		_id_regex = RegEx.new()
		_id_regex.compile("^[A-Z0-9_-]+$")
	return _id_regex.search(value) != null


static func _failure(level_id: String, reason: String) -> Dictionary:
	return {"ok": false, "error": {"id": level_id, "reason": reason}}

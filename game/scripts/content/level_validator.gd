# level_validator.gd
extends RefCounted

const CandyRules = preload("res://scripts/core/candy_rules.gd")

static func check(level: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	errors.append_array(_check_schema(level))
	if not errors.is_empty():
		return {"ok": false, "errors": errors}

	errors.append_array(_check_geometry(level))
	if not errors.is_empty():
		return {"ok": false, "errors": errors}

	errors.append_array(_check_rules(level))
	return {"ok": errors.is_empty(), "errors": errors}

static func check_bank_level(level: Dictionary) -> Dictionary:
	var base_result := check(level)
	var errors: Array[String] = []
	if not base_result["ok"]:
		for err in base_result["errors"]:
			errors.append(str(err))

	if not level.has("seed") or not (level["seed"] is int or level["seed"] is float):
		errors.append("Missing or invalid 'seed'")
	if not level.has("steps") or not (level["steps"] is int or level["steps"] is float):
		errors.append("Missing or invalid 'steps'")
	if not level.has("profile") or not (level["profile"] is Array) or level["profile"].size() != 3:
		errors.append("Missing or invalid 'profile' (must be array of 3 integers)")
	if not level.has("rating") or not (level["rating"] is int or level["rating"] is float):
		errors.append("Missing or invalid 'rating'")
	if not level.has("pidHash") or not (level["pidHash"] is String) or level["pidHash"].is_empty():
		errors.append("Missing or invalid 'pidHash'")
	if not level.has("logicTrace") or not (level["logicTrace"] is Array):
		errors.append("Missing or invalid 'logicTrace' (must be Array)")

	return {"ok": errors.is_empty(), "errors": errors}

static func check_id(level_id: String) -> bool:
	if level_id.is_empty():
		return false
	var regex := RegEx.create_from_string("^[A-Za-z0-9_\\-]+$")
	if regex == null:
		return false
	var match_res := regex.search(level_id)
	return match_res != null and match_res.get_string() == level_id

static func _check_schema(level: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not level.has("regions") or not (level["regions"] is Array):
		errors.append("Missing or non-array 'regions'")
	if not level.has("solution") or not (level["solution"] is Array):
		errors.append("Missing or non-array 'solution'")
	if level.has("givens") and not (level["givens"] is Array and level["givens"].is_empty()):
		errors.append("'givens' is no longer supported; omit it or leave it empty")
	return errors

static func _check_geometry(level: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var regions: Array = level["regions"]
	var solution: Array = level["solution"]
	var size: int = regions.size()

	if level.has("size"):
		var declared_size: int = int(level["size"])
		if declared_size != size:
			errors.append("Declared size %d does not match regions count %d" % [declared_size, size])

	if size < 4 or size > 12:
		errors.append("Invalid board size %d (must be between 4 and 12)" % size)
		return errors

	for r in range(size):
		if not (regions[r] is String):
			errors.append("Region row %d is not a String" % r)
		elif (regions[r] as String).length() != size:
			errors.append("Region row %d length %d does not match size %d" % [r, (regions[r] as String).length(), size])

	if solution.size() != size:
		errors.append("Solution size %d does not match board size %d" % [solution.size(), size])
		return errors

	var col_seen: Dictionary = {}
	for r in range(size):
		var c_val: Variant = solution[r]
		if not (c_val is int or c_val is float):
			errors.append("Solution column at row %d is not an integer" % r)
			continue
		var col: int = int(c_val)
		if col < 0 or col >= size:
			errors.append("Solution column %d at row %d out of bounds" % [col, r])
		if col_seen.has(col):
			errors.append("Duplicate solution column %d at row %d" % [col, r])
		col_seen[col] = true

	return errors

static func _check_rules(level: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var size: int = level["regions"].size()
	var verify_payload := {
		"size": size,
		"regions": level["regions"],
		"solution": level["solution"]
	}
	if not CandyRules.verify_level(verify_payload):
		errors.append("Level failed CandyRules.verify_level check")
	return errors

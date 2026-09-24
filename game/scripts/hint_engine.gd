extends RefCounted

const EMPTY := "empty"
const X := "x"
const X_ERROR := "x_error"
const CAT := "cat"

func get_hint(level: Dictionary, session: Dictionary) -> Dictionary:
	if int(session.get("hintCount", 0)) != 0:
		return _no_hint("hint already used")
	var eliminated := _eliminated(session)
	var units := _units(level)
	var known := _known_cells(level, session)
	var direct := _find_s2(level, session, units, known, eliminated)
	if not direct.is_empty():
		return _evidence(direct)
	var locked := _find_s3(level, session, units, known, eliminated)
	if not locked.is_empty():
		return _evidence(locked)
	return _no_hint("no current S2 or S3 evidence")

func _find_s2(level: Dictionary, session: Dictionary, units: Array, known: Dictionary, eliminated: Dictionary) -> Dictionary:
	for unit in units:
		var candidates := _candidates(level, session, unit["cells"], known, eliminated)
		if candidates.size() != 1:
			continue
		var cell: Array = candidates[0]
		var current := _cell_value(session, cell, int(level.get("size", 0)))
		if current == X_ERROR:
			continue
		var evidence := {
			"rule": "S2",
			"focus": {"type": unit["type"], "id": unit["id"]},
			"cell": cell,
			"textKey": "hint.single." + str(unit["type"])
		}
		if current == X:
			evidence["action"] = "try_cat"
		return evidence
	return {}

func _find_s3(level: Dictionary, session: Dictionary, units: Array, known: Dictionary, eliminated: Dictionary) -> Dictionary:
	for source in _s3_units(units):
		var source_candidates := _candidates(level, session, source["cells"], known, eliminated)
		if source_candidates.size() < 2:
			continue
		for target in _s3_units(units):
			if source == target:
				continue
			var target_candidates := _candidates(level, session, target["cells"], known, eliminated)
			var intersection: Array = []
			for cell in source_candidates:
				if _contains_cell(target_candidates, cell):
					intersection.append(cell)
			if intersection.size() != source_candidates.size() or target_candidates.size() <= intersection.size():
				continue
			var outside: Array = []
			for cell in target_candidates:
				if not _contains_cell(intersection, cell):
					outside.append(cell)
			return {
				"rule": "S3",
				"source": {"type": source["type"], "id": source["id"]},
				"target": {"type": target["type"], "id": target["id"]},
				"eliminateCells": outside,
				"sourceCells": source_candidates,
				"textKey": "hint.lock.intersection"
			}
	return {}

func _evidence(evidence: Dictionary) -> Dictionary:
	return {"ok": true, "consumeHint": true, "evidence": evidence}

func _no_hint(reason: String) -> Dictionary:
	return {"ok": false, "consumeHint": false, "reason": reason}

func _units(level: Dictionary) -> Array:
	var size := int(level.get("size", 0))
	var units: Array = []
	for row in size:
		var cells: Array = []
		for col in size:
			cells.append([row, col])
		units.append({"type": "row", "id": row, "cells": cells})
	for col in size:
		var cells: Array = []
		for row in size:
			cells.append([row, col])
		units.append({"type": "column", "id": col, "cells": cells})
	var regions: Array = level.get("regions", [])
	var region_ids: Array = []
	for row in size:
		var region_row: String = str(regions[row])
		for col in size:
			var region_id := str(region_row[col])
			if not region_ids.has(region_id):
				region_ids.append(region_id)
	for region_id in region_ids:
		var cells: Array = []
		for row in size:
			var region_row: String = str(regions[row])
			for col in size:
				if str(region_row[col]) == region_id:
					cells.append([row, col])
		units.append({"type": "region", "id": region_id, "cells": cells})
	return units

func _known_cells(level: Dictionary, session: Dictionary) -> Dictionary:
	var known := {}
	var size := int(level.get("size", 0))
	for given in level.get("givens", []):
		known[_key([int(given.get("r", -1)), int(given.get("c", -1))])] = true
	for row in size:
		for col in size:
			if _cell_value(session, [row, col], size) == CAT:
				known[_key([row, col])] = true
	return known

func _candidates(level: Dictionary, session: Dictionary, cells: Array, known: Dictionary, eliminated: Dictionary) -> Array:
	var candidates: Array = []
	var size := int(level.get("size", 0))
	for cell in cells:
		var key := _key(cell)
		if known.has(key) or eliminated.has(key):
			continue
		if _cell_value(session, cell, size) == X_ERROR:
			continue
		var blocked := false
		for known_key in known.keys():
			var other: Array = _parse_key(str(known_key))
			if other[0] == cell[0] or other[1] == cell[1] or _same_region(level, other, cell):
				blocked = true
				break
		if not blocked:
			candidates.append(cell)
	return candidates

func _same_region(level: Dictionary, first: Array, second: Array) -> bool:
	var regions: Array = level.get("regions", [])
	return str(regions[first[0]])[first[1]] == str(regions[second[0]])[second[1]]

func _eliminated(session: Dictionary) -> Dictionary:
	var result := {}
	for item in session.get("eliminated", []):
		result[str(item)] = true
	return result

func _cell_value(session: Dictionary, cell: Array, size: int) -> String:
	var cells = session.get("cells", [])
	var key := _key(cell)
	if typeof(cells) == TYPE_DICTIONARY:
		return str(cells.get(key, EMPTY))
	var index := int(cell[0]) * size + int(cell[1])
	if index < 0 or index >= cells.size():
		return EMPTY
	return str(cells[index])

func _contains_cell(cells: Array, cell: Array) -> bool:
	for candidate in cells:
		if candidate == cell:
			return true
	return false

func _key(cell: Array) -> String:
	return "%d,%d" % [int(cell[0]), int(cell[1])]

func _parse_key(key: String) -> Array:
	var parts := key.split(",")
	return [int(parts[0]), int(parts[1])]


func _s3_units(units: Array) -> Array:
	var ordered: Array = []
	for unit in units:
		if unit["type"] == "region":
			ordered.append(unit)
	for unit in units:
		if unit["type"] != "region":
			ordered.append(unit)
	return ordered
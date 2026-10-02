# pace_reader.gd
extends RefCounted

const BANK_DIR := "res://data/banks/"
const PACE_VERSION := 1

var _cache: Dictionary = {}   # "4_1" -> Array of pace entries

func load_pace(size: int) -> Dictionary:
	var path := _pace_path(size)
	if not FileAccess.file_exists(path):
		return {"ok": false, "errors": ["File not found: " + path] as Array[String]}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "errors": ["Failed to open file: " + path] as Array[String]}

	var text := file.get_as_text()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		var err_msg := "JSON parse error in %s: %s (line %d)" % [path, json.get_error_message(), json.get_error_line()]
		return {"ok": false, "errors": [err_msg] as Array[String]}

	var data: Variant = json.data
	if not (data is Dictionary):
		return {"ok": false, "errors": ["Root JSON in %s must be a Dictionary" % path] as Array[String]}

	var errors: Array[String] = []
	if not data.has("bankVersion") or int(data["bankVersion"]) != PACE_VERSION:
		errors.append("Invalid or missing bankVersion in %s" % path)
	if not data.has("size") or int(data["size"]) != size:
		errors.append("Pace size %s does not match expected %d" % [str(data.get("size")), size])
	if not data.has("pacing") or not (data["pacing"] is Dictionary):
		errors.append("Missing or non-dictionary 'pacing' in %s" % path)
		return {"ok": false, "errors": errors}

	var pacing: Dictionary = data["pacing"]
	for rank_key in pacing.keys():
		var rank_num := int(str(rank_key))
		var cache_key := "%d_%d" % [size, rank_num]
		var entries: Variant = pacing[rank_key]
		if not (entries is Array):
			errors.append("Rank '%s' pacing must be an Array" % str(rank_key))
			continue
		for i in range(entries.size()):
			var entry: Variant = entries[i]
			if not (entry is Dictionary):
				errors.append("Rank '%s' index %d is not a Dictionary" % [str(rank_key), i])
				continue
			if not entry.has("rSeq") or not (entry["rSeq"] is Array):
				errors.append("Rank '%s' index %d missing 'rSeq' array" % [str(rank_key), i])
			if not entry.has("hintCosts") or not (entry["hintCosts"] is Array):
				errors.append("Rank '%s' index %d missing 'hintCosts' array" % [str(rank_key), i])
		_cache[cache_key] = entries

	return {"ok": errors.is_empty(), "errors": errors}

func get_pace(size: int, rank: int, index: int) -> Dictionary:
	var cache_key := "%d_%d" % [size, rank]
	var list: Array = _cache.get(cache_key, [])
	if index < 0 or index >= list.size():
		return {}
	return list[index]

func validate_against_bank(bank: RefCounted, size: int) -> Array[String]:
	var errors: Array[String] = []
	var prefix := "%d_" % size

	var checked_ranks: Dictionary = {}
	for key in _cache.keys():
		var k_str: String = str(key)
		if k_str.begins_with(prefix):
			var rank_num := int(k_str.split("_")[1])
			checked_ranks[rank_num] = true
			var pace_count: int = (_cache[key] as Array).size()
			var bank_count: int = bank.level_count(size, rank_num)
			if pace_count != bank_count:
				errors.append("Pace count %d for rank %d does not match bank count %d" % [pace_count, rank_num, bank_count])

	for rank_num in range(1, 10):
		var b_count: int = bank.level_count(size, rank_num)
		if b_count > 0 and not checked_ranks.has(rank_num):
			errors.append("Bank has %d levels for rank %d, but pace sidecar has no entries" % [b_count, rank_num])

	return errors

func clear_cache() -> void:
	_cache.clear()

func _pace_path(size: int) -> String:
	return BANK_DIR + "bank_%dx%d.pace.json" % [size, size]

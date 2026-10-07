# bank_reader.gd
extends RefCounted

const LevelValidator = preload("res://scripts/content/level_validator.gd")
const BankCodec = preload("res://scripts/content/bank_codec.gd")
const FlatBankCache = preload("res://scripts/content/flat_bank_cache.gd")

const BANK_DIR := "res://data/banks/"
const BANK_VERSION := 1
const _CODEC_KEY := "candoku-2026-bank-key"

var _cache: Dictionary = {}   # "4_1" or "prefix_4_1" -> Array of level dicts
var _flat_cache = FlatBankCache.new()
var _loaded_ranked_types: Dictionary = {} # "prefix_size" -> bool


func load_bank(size: int) -> Dictionary:
	var path := _bank_path(size)
	var parse_res := _parse_bank(path)
	if not parse_res["ok"]:
		return {"ok": false, "errors": parse_res["errors"]}

	var data: Dictionary = parse_res["data"]
	var val_errors := _validate_bank(data, size)
	if not val_errors.is_empty():
		return {"ok": false, "errors": val_errors}

	var ranks: Dictionary = data["ranks"]
	for rank_key in ranks.keys():
		var rank_num := int(str(rank_key))
		var cache_key := "%d_%d" % [size, rank_num]
		var raw_levels: Array = ranks[rank_key]
		var processed: Array = []
		for lvl in raw_levels:
			var lvl_dict: Dictionary = (lvl as Dictionary).duplicate(true)
			if not lvl_dict.has("size"):
				lvl_dict["size"] = size
			processed.append(lvl_dict)
		_cache[cache_key] = processed

	return {"ok": true, "errors": [] as Array[String]}


func get_levels(size: int, rank: int) -> Array:
	var cache_key := "%d_%d" % [size, rank]
	return _cache.get(cache_key, [])


func get_level(size: int, rank: int, index: int) -> Dictionary:
	var list := get_levels(size, rank)
	if index < 0 or index >= list.size():
		return {}
	return list[index]


func level_count(size: int, rank: int) -> int:
	return get_levels(size, rank).size()


func total_count(size: int) -> int:
	var count: int = 0
	var prefix := "%d_" % size
	for key in _cache.keys():
		var key_str := key as String
		if key_str.begins_with(prefix):
			var list: Array = _cache[key]
			count += list.size()
	return count


func get_lkstyle_levels(size: int, rank: int, tier: String = "") -> Array:
	_ensure_ranked_bank("lkstyle", size)
	var list: Array = _cache.get("lkstyle_%d_%d" % [size, rank], [])
	if tier.is_empty():
		return list
	var filtered: Array = []
	for lvl in list:
		if (lvl as Dictionary).get("tier", "") == tier:
			filtered.append(lvl)
	return filtered


func get_gc_levels(size: int, rank: int) -> Array:
	_ensure_ranked_bank("gc", size)
	return _cache.get("gc_%d_%d" % [size, rank], [])


func get_onefish_levels(size: int, rank: int) -> Array:
	_ensure_ranked_bank("onefish", size)
	return _cache.get("onefish_%d_%d" % [size, rank], [])


func get_sp_level(index: int) -> Dictionary:
	return _flat_cache.get_sp_level(index)


func get_lk_level(index: int) -> Dictionary:
	return _flat_cache.get_lk_level(index)


func get_lk_mod_levels(size: int, rank: int, strict: bool = false) -> Array:
	return _flat_cache.get_lk_mod_levels(size, rank, strict)


func get_sp_tt_levels(category: int, size: int, rank: int) -> Array:
	return _flat_cache.get_sp_tt_levels(category, size, rank)


func get_single_region_levels(size: int, rank: int) -> Array:
	return _flat_cache.get_single_region_levels(size, rank)


func get_super_hard_levels() -> Array:
	return _flat_cache.get_super_hard_levels()


func available_sizes() -> Array[int]:
	var sizes_dict: Dictionary = {}
	for key in _cache.keys():
		var key_str := key as String
		var parts := key_str.split("_")
		if parts.size() == 2 and parts[0].is_valid_int():
			sizes_dict[int(parts[0])] = true
	var result: Array[int] = []
	for s in sizes_dict.keys():
		result.append(s)
	result.sort()
	return result


func clear_cache() -> void:
	_cache.clear()
	_loaded_ranked_types.clear()
	_flat_cache.clear()


func _bank_path(size: int) -> String:
	return BANK_DIR + "bank_%dx%d.json" % [size, size]


func _ensure_ranked_bank(prefix: String, size: int) -> void:
	var load_key := "%s_%d" % [prefix, size]
	if _loaded_ranked_types.has(load_key):
		return
	_loaded_ranked_types[load_key] = true
	var path := BANK_DIR + "bank_%s_%dx%d.json" % [prefix, size, size]
	var parse_res := _parse_bank(path)
	if not parse_res["ok"]:
		return
	var data: Dictionary = parse_res["data"]
	var ranks: Dictionary = data.get("ranks", {})
	for rank_key in ranks.keys():
		var rank_num := int(str(rank_key))
		var cache_key := "%s_%d_%d" % [prefix, size, rank_num]
		var raw_levels: Array = ranks[rank_key]
		var processed: Array = []
		for lvl in raw_levels:
			var lvl_dict: Dictionary = (lvl as Dictionary).duplicate(true)
			if not lvl_dict.has("size"):
				lvl_dict["size"] = size
			processed.append(lvl_dict)
		_cache[cache_key] = processed


func _parse_bank(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "errors": ["File not found: " + path] as Array[String], "data": {}}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "errors": ["Failed to open file: " + path] as Array[String], "data": {}}
	var raw := file.get_buffer(file.get_length())
	var text := raw.get_string_from_utf8()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		var decoded := BankCodec.xor_transform(raw, _CODEC_KEY)
		var decoded_text := decoded.get_string_from_utf8()
		var decoded_err := json.parse(decoded_text)
		if decoded_err == OK:
			text = decoded_text
			err = OK
	if err != OK:
		var err_msg := "JSON parse error in %s: %s (line %d)" % [path, json.get_error_message(), json.get_error_line()]
		return {"ok": false, "errors": [err_msg] as Array[String], "data": {}}
	var data: Variant = json.data
	if not (data is Dictionary):
		return {"ok": false, "errors": ["Root JSON in %s must be a Dictionary" % path] as Array[String], "data": {}}
	return {"ok": true, "errors": [] as Array[String], "data": data}


func _validate_bank(data: Dictionary, size: int) -> Array[String]:
	var errors: Array[String] = []
	if not data.has("bankVersion") or int(data["bankVersion"]) != BANK_VERSION:
		errors.append("Invalid or missing bankVersion (expected %d)" % BANK_VERSION)
	if not data.has("size") or int(data["size"]) != size:
		errors.append("Bank size %s does not match expected %d" % [str(data.get("size")), size])
	if not data.has("ranks") or not (data["ranks"] is Dictionary):
		errors.append("Missing or non-dictionary 'ranks'")
		return errors

	var ranks: Dictionary = data["ranks"]
	for rank_key in ranks.keys():
		var rank_levels: Variant = ranks[rank_key]
		if not (rank_levels is Array):
			errors.append("Rank '%s' must be an Array of levels" % str(rank_key))
			continue
		for i in range(rank_levels.size()):
			var lvl: Variant = rank_levels[i]
			if not (lvl is Dictionary):
				errors.append("Rank '%s' index %d is not a Dictionary" % [str(rank_key), i])
				continue
			var check_payload: Dictionary = (lvl as Dictionary).duplicate()
			if not check_payload.has("size"):
				check_payload["size"] = size
			var res := LevelValidator.check_bank_level(check_payload)
			if not res["ok"]:
				for err in res["errors"]:
					errors.append("Rank '%s' index %d error: %s" % [str(rank_key), i, err])
	return errors

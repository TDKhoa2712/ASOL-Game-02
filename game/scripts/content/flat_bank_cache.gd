# flat_bank_cache.gd
extends RefCounted

const BankCodec = preload("res://scripts/content/bank_codec.gd")

const BANK_DIR := "res://data/banks/"
const _CODEC_KEY := "candoku-2026-bank-key"

var _sp_levels: Array = []
var _lk_levels: Array = []
var _lk_mod_levels: Array = []
var _sp_tt_levels: Array = []
var _single_region_levels: Array = []
var _super_hard_levels: Array = []

var _sp_loaded: bool = false
var _lk_loaded: bool = false
var _lk_mod_loaded: bool = false
var _sp_tt_loaded: bool = false
var _single_region_loaded: bool = false
var _super_hard_loaded: bool = false

var _lk_mod_index_strict: Dictionary = {}
var _lk_mod_index_relaxed: Dictionary = {}
var _sp_tt_index: Dictionary = {}
var _single_region_index: Dictionary = {}


func get_sp_level(index: int) -> Dictionary:
	_ensure_sp()
	if index >= 0 and index < _sp_levels.size():
		return _sp_levels[index]
	return {}


func get_lk_level(index: int) -> Dictionary:
	_ensure_lk()
	if index >= 0 and index < _lk_levels.size():
		return _lk_levels[index]
	return {}


func get_lk_mod_levels(size: int, rank: int, strict: bool = false) -> Array:
	_ensure_lk_mod()
	var key := "%d_%d" % [size, rank]
	var dict := _lk_mod_index_strict if strict else _lk_mod_index_relaxed
	return dict.get(key, [])


func get_sp_tt_levels(category: int, size: int, rank: int) -> Array:
	_ensure_sp_tt()
	var key := "%d_%d_%d" % [category, size, rank]
	return _sp_tt_index.get(key, [])


func get_single_region_levels(size: int, rank: int) -> Array:
	_ensure_single_region()
	var key := "%d_%d" % [size, rank]
	return _single_region_index.get(key, [])


func get_super_hard_levels() -> Array:
	_ensure_super_hard()
	return _super_hard_levels


func clear() -> void:
	_sp_levels.clear()
	_lk_levels.clear()
	_lk_mod_levels.clear()
	_sp_tt_levels.clear()
	_single_region_levels.clear()
	_super_hard_levels.clear()
	_lk_mod_index_strict.clear()
	_lk_mod_index_relaxed.clear()
	_sp_tt_index.clear()
	_single_region_index.clear()
	_sp_loaded = false
	_lk_loaded = false
	_lk_mod_loaded = false
	_sp_tt_loaded = false
	_single_region_loaded = false
	_super_hard_loaded = false


func _ensure_sp() -> void:
	if _sp_loaded:
		return
	_sp_loaded = true
	var levels := _load_flat_file("bank_sp.json")
	_sp_levels = levels


func _ensure_lk() -> void:
	if _lk_loaded:
		return
	_lk_loaded = true
	var levels := _load_flat_file("bank_lk.json")
	_lk_levels = levels


func _ensure_lk_mod() -> void:
	if _lk_mod_loaded:
		return
	_lk_mod_loaded = true
	var levels := _load_flat_file("bank_lk_modified.json")
	_lk_mod_levels = levels
	for lvl in levels:
		var d: Dictionary = lvl
		var sz: int = int(d.get("size", 0))
		var r_strict: int = int(d.get("rank", d.get("r", 1)))
		var r_relaxed: int = int(d.get("maxR", r_strict))

		var k_strict := "%d_%d" % [sz, r_strict]
		if not _lk_mod_index_strict.has(k_strict):
			_lk_mod_index_strict[k_strict] = []
		_lk_mod_index_strict[k_strict].append(d)

		var k_relaxed := "%d_%d" % [sz, r_relaxed]
		if not _lk_mod_index_relaxed.has(k_relaxed):
			_lk_mod_index_relaxed[k_relaxed] = []
		_lk_mod_index_relaxed[k_relaxed].append(d)


func _ensure_sp_tt() -> void:
	if _sp_tt_loaded:
		return
	_sp_tt_loaded = true
	var levels := _load_flat_file("bank_sp_tt.json")
	_sp_tt_levels = levels
	for lvl in levels:
		var d: Dictionary = lvl
		var cat: int = int(d.get("shapeCategory", 0))
		var sz: int = int(d.get("size", 0))
		var r: int = int(d.get("rank", d.get("r", 1)))
		var k := "%d_%d_%d" % [cat, sz, r]
		if not _sp_tt_index.has(k):
			_sp_tt_index[k] = []
		_sp_tt_index[k].append(d)


func _ensure_single_region() -> void:
	if _single_region_loaded:
		return
	_single_region_loaded = true
	var levels := _load_flat_file("bank_single_region.json")
	_single_region_levels = levels
	for lvl in levels:
		var d: Dictionary = lvl
		var sz: int = int(d.get("size", 0))
		var r: int = int(d.get("rank", d.get("r", 1)))
		var k := "%d_%d" % [sz, r]
		if not _single_region_index.has(k):
			_single_region_index[k] = []
		_single_region_index[k].append(d)


func _ensure_super_hard() -> void:
	if _super_hard_loaded:
		return
	_super_hard_loaded = true
	var levels := _load_flat_file("bank_super_hard.json")
	_super_hard_levels = levels


func _load_flat_file(filename: String) -> Array:
	var path := BANK_DIR + filename
	if not FileAccess.file_exists(path):
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var raw := file.get_buffer(file.get_length())
	var text := raw.get_string_from_utf8()
	var json := JSON.new()
	if json.parse(text) != OK:
		var decoded := BankCodec.xor_transform(raw, _CODEC_KEY)
		text = decoded.get_string_from_utf8()
		if json.parse(text) != OK:
			return []
	var data: Variant = json.data
	if data is Dictionary and data.has("levels") and data["levels"] is Array:
		return data["levels"]
	return []

# endless_config.gd
class_name EndlessConfig
extends RefCounted

var milestone_enabled: bool = true
var super_hard_enabled: bool = true
var super_hard_min_level: int = 35
var super_hard_phase: int = 5
var super_hard_period: int = 10
var single_region_supp_enabled: bool = true
var sp_tt_enabled: bool = false
var onefish_enabled: bool = false

var pool_source_config: Dictionary = {}
var initial_strategy: int = 3


static func default_config():
	var cfg = new()

	cfg.pool_source_config = {
		"regular": {"enabled": true},
		"lkstyle": {"enabled": true},
		"gc": {"enabled": true},
		"lk_modified": {"enabled": true, "inject_every": 4},
	}
	return cfg


static func load_from_file(path: String):

	var cfg = default_config()
	if not FileAccess.file_exists(path):
		return cfg
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return cfg
	var text := file.get_as_text()
	var json := JSON.new()
	if json.parse(text) != OK:
		return cfg
	var data: Variant = json.data
	if not (data is Dictionary):
		return cfg

	var d: Dictionary = data
	var tiers: Dictionary = d.get("tiers", {})

	var ms: Dictionary = tiers.get("milestone", {})
	cfg.milestone_enabled = ms.get("enabled", cfg.milestone_enabled)

	var sh: Dictionary = tiers.get("super_hard", {})
	cfg.super_hard_enabled = sh.get("enabled", cfg.super_hard_enabled)
	cfg.super_hard_min_level = int(sh.get("min_level", cfg.super_hard_min_level))
	cfg.super_hard_phase = int(sh.get("phase", cfg.super_hard_phase))
	cfg.super_hard_period = int(sh.get("period", cfg.super_hard_period))

	var sr: Dictionary = tiers.get("single_region_supp", {})
	cfg.single_region_supp_enabled = sr.get("enabled", cfg.single_region_supp_enabled)

	var tt: Dictionary = tiers.get("sp_tt", {})
	cfg.sp_tt_enabled = tt.get("enabled", cfg.sp_tt_enabled)

	var of: Dictionary = tiers.get("onefish", {})
	cfg.onefish_enabled = of.get("enabled", cfg.onefish_enabled)

	if d.has("pool_sources") and d["pool_sources"] is Dictionary:
		cfg.pool_source_config = d["pool_sources"]

	var diff: Dictionary = d.get("difficulty", {})
	cfg.initial_strategy = int(diff.get("initial_strategy", cfg.initial_strategy))

	return cfg


func is_pool_enabled(source_id: StringName) -> bool:
	var key := str(source_id)
	var s_cfg: Dictionary = pool_source_config.get(key, {})
	return s_cfg.get("enabled", false)


func get_inject_every(source_id: StringName) -> int:
	var key := str(source_id)
	var s_cfg: Dictionary = pool_source_config.get(key, {})
	return int(s_cfg.get("inject_every", 0))

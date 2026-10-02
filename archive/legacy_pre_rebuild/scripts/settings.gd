extends RefCounted

const SETTINGS_VERSION := 1

## Default values per UX spec (GDD 03)
const DEFAULTS := {
	"settingsVersion": SETTINGS_VERSION,
	"audioEnabled": true,
	"hapticsEnabled": true,
	"reducedMotion": false,
	"highContrast": false,
	"largeText": false,
}

const _MUTABLE_KEYS: Array[String] = ["audioEnabled", "hapticsEnabled", "reducedMotion", "highContrast", "largeText"]

var _current: Dictionary = DEFAULTS.duplicate(true)
var _root_dir: String = ""

signal changed(key: String, value: Variant)


func _init(save_dir: String = "") -> void:
	_root_dir = save_dir if not save_dir.is_empty() else OS.get_user_data_dir()
	_load()


func get_value(key: String) -> Variant:
	if _current.has(key):
		return _current[key]
	if DEFAULTS.has(key):
		return DEFAULTS[key]
	return null


func get_all() -> Dictionary:
	return _current.duplicate(true)


func set_value(key: String, value: Variant) -> bool:
	if key not in _MUTABLE_KEYS:
		return false
	if _current[key] != value:
		_current[key] = value
		_save()
		changed.emit(key, value)
		return true
	return false


func set_all(data: Dictionary) -> void:
	var any_changed := false
	for key in _MUTABLE_KEYS:
		if key in data and typeof(data[key]) == typeof(DEFAULTS[key]):
			if _current[key] != data[key]:
				_current[key] = data[key]
				any_changed = true
	if any_changed:
		_save()
		changed.emit("", null)


func reset_to_defaults() -> void:
	_current = DEFAULTS.duplicate(true)
	_save()
	changed.emit("", null)


func is_large_text() -> bool:
	return _current["largeText"]


func is_reduced_motion() -> bool:
	return _current["reducedMotion"]


func is_high_contrast() -> bool:
	return _current["highContrast"]


func is_audio_enabled() -> bool:
	return _current["audioEnabled"]


func is_haptics_enabled() -> bool:
	return _current["hapticsEnabled"]


func _load() -> void:
	var path := _settings_path()
	if not FileAccess.file_exists(path):
		_current = DEFAULTS.duplicate(true)
		_save()
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		reset_to_defaults()
		return
	var version: int = parsed.get("settingsVersion", -1)
	if version == SETTINGS_VERSION:
		for key in DEFAULTS:
			if key in parsed and typeof(parsed[key]) == typeof(DEFAULTS[key]):
				_current[key] = parsed[key]
	elif version > 0 and version < SETTINGS_VERSION:
		# Forward migration: keep compatible keys, add new defaults
		for key in DEFAULTS:
			if key in parsed and typeof(parsed[key]) == typeof(DEFAULTS[key]):
				_current[key] = parsed[key]
		_current["settingsVersion"] = SETTINGS_VERSION
		_save()
	else:
		reset_to_defaults()


func _save() -> void:
	var path := _settings_path()
	var dir := path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_current))
		file.flush()
		file.close()
		DirAccess.rename_absolute(tmp, path)


func _settings_path() -> String:
	return _root_dir.path_join("settings.json")

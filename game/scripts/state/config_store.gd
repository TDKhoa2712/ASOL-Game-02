extends RefCounted

signal option_changed(key: String, value: Variant)

const VERSION := 1
const DEFAULTS := {"audio": true, "haptic": true, "reduced_motion": false, "high_contrast": false, "large_text": false, "colorblind": false}
const EDITABLE_KEYS: Array[String] = ["audio", "haptic", "reduced_motion", "high_contrast", "large_text", "colorblind"]

var _path: String
var _data: Dictionary = {}

func _init(profile_dir: String) -> void:
	_path = profile_dir.path_join("config.json")
	load_config()

func load_config() -> void:
	_data = DEFAULTS.duplicate()
	if not FileAccess.file_exists(_path):
		return
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(_path)) != OK or not json.data is Dictionary:
		return
	var saved: Dictionary = json.data
	if saved.get("version") != VERSION or not saved.get("options") is Dictionary:
		return
	for key in EDITABLE_KEYS:
		if saved.options.get(key) is bool:
			_data[key] = saved.options[key]

func save_config() -> void:
	var directory := _path.get_base_dir()
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		return
	var temporary := _path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"version": VERSION, "options": _data}))
	file.flush()
	var written := file.get_error() == OK
	file.close()
	if not written:
		return
	if FileAccess.file_exists(_path) and DirAccess.remove_absolute(_path) != OK:
		return
	DirAccess.rename_absolute(temporary, _path)

func get_option(key: String) -> Variant:
	return _data.get(key)

func set_option(key: String, value: Variant) -> void:
	if not EDITABLE_KEYS.has(key) or not value is bool or _data[key] == value:
		return
	_data[key] = value
	save_config()
	option_changed.emit(key, value)

func reset_defaults() -> void:
	_data = DEFAULTS.duplicate()
	save_config()
	option_changed.emit("", null)

func all_options() -> Dictionary:
	return _data.duplicate()

extends RefCounted

const READ_ATTEMPTS := 3
const RETRY_PAUSE_MS := 60

var _dir: String
var _name: String

func _init(directory: String, file_name: String) -> void:
	_dir = directory
	_name = file_name

func write_json(data: Dictionary) -> bool:
	if DirAccess.make_dir_recursive_absolute(_dir) != OK:
		return false
	var active := _active_label()
	var next := "b" if active == "a" else "a"
	if not _atomic_save(data, _slot_file(next)):
		return false
	return _flip_flag(next)

func read_json() -> Dictionary:
	var active := _active_label()
	for label in [active, "b" if active == "a" else "a"]:
		var result := _read_slot(label)
		if result.ok:
			return {"ok": true, "data": result.data, "recovered": label != active, "reason": ""}
	var legacy := _parse_file(_legacy_file())
	if legacy.ok:
		return {"ok": true, "data": legacy.data, "recovered": true, "reason": "legacy"}
	return {"ok": false, "data": {}, "recovered": false, "reason": "missing_or_invalid"}

func remove_all() -> void:
	for path in [_slot_file("a"), _slot_file("b"), _flag_file(), _legacy_file(), _slot_file("a") + ".tmp", _slot_file("b") + ".tmp", _flag_file() + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

func inject_corrupt(content: String) -> bool:
	var file := FileAccess.open(_slot_file(_active_label()), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(content)
	file.flush()
	var ok := file.get_error() == OK
	file.close()
	return ok

func _active_label() -> String:
	if not FileAccess.file_exists(_flag_file()):
		return "b"
	var flag := FileAccess.get_file_as_string(_flag_file()).strip_edges()
	return flag if flag == "a" or flag == "b" else "b"

func _slot_file(label: String) -> String:
	return _dir.path_join("%s.%s.json" % [_name, label])

func _flag_file() -> String:
	return _dir.path_join(_name + ".flag")

func _legacy_file() -> String:
	return _dir.path_join(_name + ".json")

func _atomic_save(data: Dictionary, target_path: String) -> bool:
	var temporary := target_path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var written := file.get_error() == OK
	file.close()
	if not written or not _parse_file(temporary).ok:
		DirAccess.remove_absolute(temporary)
		return false
	if FileAccess.file_exists(target_path) and DirAccess.remove_absolute(target_path) != OK:
		return false
	return DirAccess.rename_absolute(temporary, target_path) == OK

func _read_slot(label: String) -> Dictionary:
	var path := _slot_file(label)
	for attempt in READ_ATTEMPTS:
		var result := _parse_file(path)
		if result.ok:
			return result
		if attempt + 1 < READ_ATTEMPTS:
			OS.delay_msec(RETRY_PAUSE_MS)
	return {"ok": false, "data": {}}

func _parse_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "data": {}}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "data": {}}
	var raw := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(raw) != OK or not json.data is Dictionary:
		return {"ok": false, "data": {}}
	return {"ok": true, "data": json.data}

func _flip_flag(label: String) -> bool:
	var temporary := _flag_file() + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(label)
	file.flush()
	var written := file.get_error() == OK
	file.close()
	if not written:
		return false
	if FileAccess.file_exists(_flag_file()) and DirAccess.remove_absolute(_flag_file()) != OK:
		return false
	return DirAccess.rename_absolute(temporary, _flag_file()) == OK

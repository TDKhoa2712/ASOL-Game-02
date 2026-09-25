extends RefCounted

const PROGRESS_VERSION := 2
const SESSION_VERSION := 2
const EMPTY_PROGRESS_LEVEL := ""

var root_dir: String

func _init(save_dir: String = "") -> void:
	root_dir = save_dir if not save_dir.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(root_dir)

func new_progress(current_level_id: String) -> Dictionary:
	return {
		"progressVersion": PROGRESS_VERSION,
		"currentLevelId": current_level_id,
		"completedLevelIds": [],
		"results": {}
	}

func new_session(level_id: String, puzzle_hash: String, cell_count: int) -> Dictionary:
	return {
		"sessionVersion": SESSION_VERSION,
		"levelId": level_id,
		"puzzleHash": puzzle_hash,
		"cells": _empty_cells(cell_count),
		"hearts": 3,
		"mistakeCount": 0,
		"hintCount": 0,
		"elapsedMs": 0
	}

func save_progress(progress: Dictionary) -> bool:
	return _is_valid_progress(progress) and _atomic_write("progress", progress)

func save_session(session: Dictionary) -> bool:
	return _is_valid_session(session) and _atomic_write("session", session)

func load_progress() -> Dictionary:
	var primary := _read_json("progress")
	if primary.get("ok", false) and _is_valid_progress(primary["data"]):
		return {"ok": true, "data": primary["data"], "recovered": false}
	var backup := _read_json("progress", true)
	if backup.get("ok", false) and _is_valid_progress(backup["data"]):
		return {"ok": true, "data": backup["data"], "recovered": true}
	var missing := not FileAccess.file_exists(_path("progress")) and not FileAccess.file_exists(_path("progress", true))
	return {"ok": false, "reason": "missing" if missing else "invalid", "recovered": false}

func load_session(expected_level_id: String, expected_puzzle_hash: String) -> Dictionary:
	var result := _read_json("session")
	if not result.get("ok", false):
		return {"ok": false, "reason": "session is missing or invalid", "recreate": true}
	var session: Dictionary = result["data"]
	if not _is_valid_session(session):
		return {"ok": false, "reason": "session schema is invalid", "recreate": true}
	if session["levelId"] != expected_level_id:
		return {"ok": false, "reason": "session level mismatch", "recreate": true}
	if session["puzzleHash"] != expected_puzzle_hash:
		return {"ok": false, "reason": "session puzzle hash mismatch", "recreate": true}
	return {"ok": true, "data": session, "recovered": false}

func complete_level(progress: Dictionary, level_id: String, result: Dictionary, ordered_level_ids: Array) -> Dictionary:
	if not _is_valid_progress(progress) or level_id.is_empty() or typeof(result) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "invalid completion input"}
	var updated: Dictionary = progress.duplicate(true)
	var completed: Array = updated["completedLevelIds"]
	if not completed.has(level_id):
		completed.append(level_id)
	updated["completedLevelIds"] = completed
	var results: Dictionary = updated["results"]
	results[level_id] = result.duplicate(true)
	updated["results"] = results
	updated["currentLevelId"] = _first_uncompleted(ordered_level_ids, completed)
	return {"ok": true, "data": updated}

func puzzle_hash(level: Dictionary) -> String:
	var givens: Array = level.get("givens", []).duplicate(true)
	givens.sort_custom(func(a: Variant, b: Variant) -> bool:
		return [int(a.get("r", 0)), int(a.get("c", 0))] < [int(b.get("r", 0)), int(b.get("c", 0))]
	)
	var canonical := [level.get("size", 0), level.get("regions", []), givens, level.get("solution", [])]
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(JSON.stringify(canonical).to_utf8_buffer())
	return context.finish().hex_encode()

func clear_session() -> bool:
	return _remove_file("session") and _remove_file("session", true)

func clear_all() -> void:
	_remove_file("progress")
	_remove_file("progress", true)
	_remove_file("session")
	_remove_file("session", true)

func corrupt_for_test(kind: String) -> bool:
	if kind not in ["progress", "session"]:
		return false
	var file := FileAccess.open(_path(kind), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string("[]")
	file.flush()
	file.close()
	return true

func _atomic_write(kind: String, data: Dictionary) -> bool:
	var temporary := _path(kind, false, true)
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()

	var target := _path(kind)
	var backup := _path(kind, true)
	if kind == "progress" and not FileAccess.file_exists(target) and FileAccess.file_exists(backup):
		var restore_result := DirAccess.rename_absolute(temporary, target)
		if restore_result != OK:
			DirAccess.remove_absolute(temporary)
		return restore_result == OK
	if kind == "progress" and FileAccess.file_exists(target):
		var existing := _read_json(kind)
		if not existing.get("ok", false) or not _is_valid_progress(existing["data"]):
			var quarantine := target + ".corrupt"
			if FileAccess.file_exists(quarantine) or DirAccess.rename_absolute(target, quarantine) != OK:
				DirAccess.remove_absolute(temporary)
				return false
			if DirAccess.rename_absolute(temporary, target) != OK:
				DirAccess.rename_absolute(quarantine, target)
				return false
			return true
	if FileAccess.file_exists(backup):
		DirAccess.remove_absolute(backup)
	if FileAccess.file_exists(target) and DirAccess.rename_absolute(target, backup) != OK:
		DirAccess.remove_absolute(temporary)
		return false
	if DirAccess.rename_absolute(temporary, target) != OK:
		if FileAccess.file_exists(backup):
			DirAccess.rename_absolute(backup, target)
		return false
	return true

func _read_json(kind: String, backup: bool = false) -> Dictionary:
	var path := _path(kind, backup)
	if not FileAccess.file_exists(path):
		return {"ok": false, "reason": "file missing"}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "invalid JSON"}
	return {"ok": true, "data": parsed}

func _is_valid_progress(progress: Dictionary) -> bool:
	return progress.get("progressVersion", -1) == PROGRESS_VERSION \
		and (progress.get("currentLevelId") == null or typeof(progress.get("currentLevelId")) == TYPE_STRING) \
		and typeof(progress.get("completedLevelIds")) == TYPE_ARRAY \
		and typeof(progress.get("results")) == TYPE_DICTIONARY

func _is_valid_session(session: Dictionary) -> bool:
	if session.get("sessionVersion", -1) != SESSION_VERSION:
		return false
	if typeof(session.get("levelId")) != TYPE_STRING or typeof(session.get("puzzleHash")) != TYPE_STRING:
		return false
	if typeof(session.get("cells")) != TYPE_ARRAY or session["cells"].is_empty():
		return false
	if int(session.get("hintCount", -1)) not in [0, 1] or int(session.get("hearts", -1)) < 0:
		return false
	for cell in session["cells"]:
		if cell not in ["empty", "x", "x_error", "cat"]:
			return false
	return true

func _first_uncompleted(ordered_level_ids: Array, completed: Array) -> Variant:
	for level_id in ordered_level_ids:
		if not completed.has(level_id):
			return level_id
	return null

func _empty_cells(count: int) -> Array:
	var cells: Array = []
	for _index in count:
		cells.append("empty")
	return cells

func _path(kind: String, backup: bool = false, temporary: bool = false) -> String:
	var suffix := ".json"
	if backup:
		suffix += ".bak"
	if temporary:
		suffix += ".tmp"
	return root_dir.path_join(kind + suffix)

func _remove_file(kind: String, backup: bool = false) -> bool:
	var path := _path(kind, backup)
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(path) == OK

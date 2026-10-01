extends RefCounted

const PROGRESS_VERSION := 2
const SESSION_VERSION := 3
const LegacySessionMigration = preload("res://scripts/legacy_session_migration.gd")
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
		return {"ok": true, "data": primary["data"], "recovered": primary.get("recovered", false)}
	var backup := _read_json("progress", true)
	if backup.get("ok", false) and _is_valid_progress(backup["data"]):
		return {"ok": true, "data": backup["data"], "recovered": true}
	var missing := not _any_slot_exists("progress") and not _legacy_exists("progress")
	return {"ok": false, "reason": "missing" if missing else "invalid", "recovered": false}

func load_session(expected_level_id: String, expected_puzzle_hash: String) -> Dictionary:
	var result := _read_json("session")
	if not result.get("ok", false):
		return {"ok": false, "reason": "session is missing or invalid", "recreate": true}
	var session: Dictionary = LegacySessionMigration.to_current(result["data"])
	if not _is_valid_session(session):
		return {"ok": false, "reason": "session schema is invalid", "recreate": true}
	if session["levelId"] != expected_level_id:
		return {"ok": false, "reason": "session level mismatch", "recreate": true}
	if session["puzzleHash"] != expected_puzzle_hash:
		return {"ok": false, "reason": "session puzzle hash mismatch", "recreate": true}
	return {"ok": true, "data": session, "recovered": result.get("recovered", false)}

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
	return _remove_slots("session")

func clear_all() -> void:
	_remove_slots("progress")
	_remove_slots("session")

func corrupt_for_test(kind: String) -> bool:
	if kind not in ["progress", "session"]:
		return false
	var slot_path := _slot_path(kind, _active_slot(kind))
	var file := FileAccess.open(slot_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string("[]")
	file.flush()
	file.close()
	return true

# --- A/B dual-slot persistence ---

func _atomic_write(kind: String, data: Dictionary) -> bool:
	var tmp := root_dir.path_join("%s.tmp" % kind)
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	# Verify-after-write: re-read and validate before committing
	var verify: Variant = JSON.parse_string(FileAccess.get_file_as_string(tmp))
	if typeof(verify) != TYPE_DICTIONARY:
		DirAccess.remove_absolute(tmp)
		return false
	var valid := _is_valid_progress(verify) if kind == "progress" else _is_valid_session(verify)
	if not valid:
		DirAccess.remove_absolute(tmp)
		return false
	# Write to the inactive slot, then flip the flag
	var active := _active_slot(kind)
	var inactive := "b" if active == "a" else "a"
	var target := _slot_path(kind, inactive)
	if DirAccess.rename_absolute(tmp, target) != OK:
		DirAccess.remove_absolute(tmp)
		return false
	# Flip flag to make the newly written slot active
	var flag_file := FileAccess.open(_flag_path(kind), FileAccess.WRITE)
	if flag_file == null:
		return false
	flag_file.store_string(inactive)
	flag_file.flush()
	flag_file.close()
	return true


func _read_json(kind: String, backup: bool = false) -> Dictionary:
	if backup:
		# Backup = inactive slot
		var active := _active_slot(kind)
		var inactive := "b" if active == "a" else "a"
		var result := _read_slot_with_retry(kind, inactive)
		if result.get("ok", false):
			result["recovered"] = true
			return result
		# Legacy fallback for migration from old single-file format
		result = _parse_json_file(_legacy_path(kind, true))
		if result.get("ok", false):
			result["recovered"] = true
		return result
	# Primary: read active slot with retry
	var active := _active_slot(kind)
	var result := _read_slot_with_retry(kind, active)
	if result.get("ok", false):
		result["recovered"] = false
		return result
	# Active failed — try inactive slot
	var inactive := "b" if active == "a" else "a"
	result = _read_slot_with_retry(kind, inactive)
	if result.get("ok", false):
		result["recovered"] = true
		return result
	# Both slots failed — try legacy single-file path for migration
	result = _parse_json_file(_legacy_path(kind, false))
	if result.get("ok", false):
		result["recovered"] = false
		return result
	result = _parse_json_file(_legacy_path(kind, true))
	if result.get("ok", false):
		result["recovered"] = true
	return result


func _read_slot_with_retry(kind: String, slot: String, attempts: int = 3) -> Dictionary:
	var path := _slot_path(kind, slot)
	for attempt in attempts:
		var result := _parse_json_file(path)
		if result.get("ok", false):
			return result
		if attempt < attempts - 1:
			OS.delay_msec(60)
	return {"ok": false, "reason": "read failed after retries"}


func _parse_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "reason": "file missing"}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "invalid JSON"}
	return {"ok": true, "data": parsed}


func _active_slot(kind: String) -> String:
	var path := _flag_path(kind)
	if FileAccess.file_exists(path):
		var content := FileAccess.get_file_as_string(path).strip_edges()
		if content in ["a", "b"]:
			return content
	return "a"


func _slot_path(kind: String, slot: String) -> String:
	return root_dir.path_join("%s.%s.json" % [kind, slot])


func _flag_path(kind: String) -> String:
	return root_dir.path_join("%s.flag" % kind)


func _legacy_path(kind: String, backup: bool) -> String:
	var suffix := ".json.bak" if backup else ".json"
	return root_dir.path_join(kind + suffix)


func _any_slot_exists(kind: String) -> bool:
	return FileAccess.file_exists(_slot_path(kind, "a")) or FileAccess.file_exists(_slot_path(kind, "b"))


func _legacy_exists(kind: String) -> bool:
	return FileAccess.file_exists(_legacy_path(kind, false)) or FileAccess.file_exists(_legacy_path(kind, true))


func _remove_slots(kind: String) -> bool:
	var ok := true
	for slot in ["a", "b"]:
		var path := _slot_path(kind, slot)
		if FileAccess.file_exists(path):
			if DirAccess.remove_absolute(path) != OK:
				ok = false
	var flag := _flag_path(kind)
	if FileAccess.file_exists(flag):
		DirAccess.remove_absolute(flag)
	# Also clean legacy files
	for legacy in [_legacy_path(kind, false), _legacy_path(kind, true)]:
		if FileAccess.file_exists(legacy):
			DirAccess.remove_absolute(legacy)
	return ok

# --- Validation ---

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
		if cell not in ["empty", "x", "x_error", "candy"]:
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

extends RefCounted

const DualSlotStore = preload("res://scripts/state/dual_slot_store.gd")
const SCHEMA_VER := 2

signal save_failed(reason: String)

var _store: DualSlotStore
var current: Dictionary = {}

func _init(profile_dir: String) -> void:
	_store = DualSlotStore.new(profile_dir, "progress")

func load() -> Dictionary:
	var read := _store.read_json()
	if not read.ok:
		return read
	var migrated := _migrate(read.data)
	if not _validate(migrated):
		return {"ok": false, "data": {}, "recovered": read.recovered, "reason": "invalid_progress"}
	current = migrated
	return {"ok": true, "data": current.duplicate(true), "recovered": read.recovered, "reason": read.reason}

func save() -> bool:
	if not _validate(current):
		save_failed.emit("invalid_progress")
		return false
	if not _store.write_json(current):
		save_failed.emit("write_failed")
		return false
	return true

func new_progress(first_level_id: String) -> Dictionary:
	return {"progressVersion": SCHEMA_VER, "currentLevelId": first_level_id, "completedLevelIds": [], "results": {}, "tutorialSeenIds": []}

func advance_level(level_id: String, score_data: Dictionary, level_order: Array) -> Dictionary:
	if not _validate(current) or current.currentLevelId != level_id or not level_order.has(level_id) or current.completedLevelIds.has(level_id):
		return {"ok": false, "data": current.duplicate(true), "reason": "invalid_level"}
	var next := current.duplicate(true)
	if not next.completedLevelIds.has(level_id):
		next.completedLevelIds.append(level_id)
	next.results[level_id] = score_data.duplicate(true)
	var index := level_order.find(level_id)
	if index + 1 < level_order.size():
		next.currentLevelId = level_order[index + 1]
	var previous := current
	current = next
	if not save():
		current = previous
		return {"ok": false, "data": previous.duplicate(true), "reason": "write_failed"}
	return {"ok": true, "data": current.duplicate(true)}

func puzzle_fingerprint(level: Dictionary) -> String:
	var basis := [level.get("size"), level.get("regions"), level.get("givens"), level.get("solution")]
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(JSON.stringify(basis).to_utf8_buffer())
	return context.finish().hex_encode()

func _validate(data: Dictionary) -> bool:
	return data.get("progressVersion") == SCHEMA_VER \
		and data.get("currentLevelId") is String \
		and not data.currentLevelId.is_empty() \
		and data.get("completedLevelIds") is Array \
		and data.get("results") is Dictionary \
		and data.get("tutorialSeenIds") is Array

func _migrate(data: Dictionary) -> Dictionary:
	if data.get("progressVersion") == SCHEMA_VER:
		return data
	if data.get("progressVersion") == 1 and data.get("currentLevelId") is String:
		var migrated := new_progress(data.currentLevelId)
		for key in ["completedLevelIds", "results", "tutorialSeenIds"]:
			if data.has(key):
				migrated[key] = data[key]
		return migrated
	return {}

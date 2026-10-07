extends RefCounted

const DualSlotStore = preload("res://scripts/state/dual_slot_store.gd")
const SCHEMA_VER := 3
const CELL_VALUES := ["empty", "x", "candy", "error", "wrong", "locked"]

var _store: DualSlotStore

func _init(profile_dir: String) -> void:
	_store = DualSlotStore.new(profile_dir, "session")

func save_session(data: Dictionary) -> bool:
	if not _valid_shape(data):
		return false
	return _store.write_json(data)

func load_session(level_id: String, expected_hash: String) -> Dictionary:
	var result := _store.read_json()
	if not result.ok:
		return {"ok": false, "data": {}, "reason": result.reason, "recreate": false}
	return _validate(result.data, level_id, expected_hash)

func clear() -> void:
	_store.remove_all()

func has_pending() -> bool:
	return _store.read_json().ok

func pending_snapshot(level_id: String) -> Dictionary:
	var saved := _store.read_json()
	if not saved.ok or not _valid_shape(saved.data) or saved.data.levelId != level_id:
		return {}
	var snapshot: Variant = saved.data.get("snapshot")
	if not snapshot is Dictionary or snapshot.get("level_id") != level_id:
		return {}
	var pinned: Dictionary = snapshot.duplicate(true)
	pinned["puzzle_hash"] = saved.data.puzzleHash
	return pinned

func new_session(level_id: String, puzzle_hash: String, board_size: int) -> Dictionary:
	var cells: Array[String] = []
	for unused in board_size * board_size:
		cells.append("empty")
	return {"sessionVersion": SCHEMA_VER, "levelId": level_id, "puzzleHash": puzzle_hash, "boardSize": board_size, "cells": cells, "hearts": 3, "mistake_count": 0, "hints_used": 0, "elapsedMs": 0, "status": "playing"}

func _validate(data: Dictionary, level_id: String, expected_hash: String) -> Dictionary:
	if not _valid_shape(data):
		return {"ok": false, "data": {}, "reason": "invalid_session", "recreate": false}
	if data.levelId != level_id:
		return {"ok": false, "data": {}, "reason": "level_mismatch", "recreate": false}
	if data.puzzleHash != expected_hash:
		return {"ok": false, "data": {}, "reason": "puzzle_changed", "recreate": true}
	return {"ok": true, "data": data, "reason": "", "recreate": false}

func _valid_shape(data: Dictionary) -> bool:
	if data.get("sessionVersion") != SCHEMA_VER or not data.get("levelId") is String or not data.get("puzzleHash") is String:
		return false
	var size = data.get("boardSize")
	if not _whole_number(size) or size < 4 or size > 12:
		return false
	var cells = data.get("cells")
	if not cells is Array or cells.size() != size * size:
		return false
	for cell in cells:
		if not cell is String or not CELL_VALUES.has(cell):
			return false
	for key in ["hearts", "mistake_count", "hints_used", "elapsedMs"]:
		if not _whole_number(data.get(key)) or data[key] < 0:
			return false
	return data.get("status") is String and ["playing", "won", "failed"].has(data.status)

func _whole_number(value: Variant) -> bool:
	return value is int or (value is float and is_finite(value) and value == floor(value))

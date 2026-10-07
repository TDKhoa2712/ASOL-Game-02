# bank_cursor.gd
class_name BankCursor
extends RefCounted

const TRANSFORM_COUNT: int = 8

var idx: int = 0
var transform_id: int = 0
var total_levels: int = 0


func budget() -> int:
	return total_levels * TRANSFORM_COUNT


func pos() -> Dictionary:
	return {
		"idx": idx,
		"transform_id": transform_id,
	}


func advance(_entry: Dictionary) -> void:
	idx += 1
	if total_levels > 0 and idx >= total_levels:
		idx = 0
		transform_id = (transform_id + 1) % TRANSFORM_COUNT


func serialize() -> Dictionary:
	return {
		"idx": idx,
		"transform_id": transform_id,
	}


func restore(data: Dictionary) -> void:
	idx = int(data.get("idx", 0))
	transform_id = int(data.get("transform_id", 0))

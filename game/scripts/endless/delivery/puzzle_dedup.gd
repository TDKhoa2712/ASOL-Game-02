# puzzle_dedup.gd
class_name PuzzleDedup
extends RefCounted


static func is_duplicate(entry: Dictionary, progress: RefCounted) -> bool:
	var h: String = str(entry.get("pidHash", ""))
	if h.is_empty():
		return false
	return progress.is_hash_recent(h)


static func register(entry: Dictionary, progress: RefCounted) -> void:
	var h: String = str(entry.get("pidHash", ""))
	if not h.is_empty():
		progress.add_recent_hash(h)

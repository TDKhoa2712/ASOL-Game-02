# super_hard_cursor.gd
class_name SuperHardCursor
extends "res://scripts/endless/cursor/bank_cursor.gd"



func get_index_for_level(level_num: int, min_level: int = 35, period: int = 10, phase: int = 5) -> int:
	if level_num < min_level:
		return 0
	var offset: int = int((level_num - phase) / float(period)) - int((min_level - phase) / float(period))
	return maxi(0, offset)


func pos_for_level(level_num: int, min_level: int = 35, period: int = 10, phase: int = 5) -> Dictionary:
	var total: int = total_levels if total_levels > 0 else 1
	var offset: int = get_index_for_level(level_num, min_level, period, phase)
	return {
		"idx": offset % total,
		"transform_id": int(float(offset) / float(total)) % TRANSFORM_COUNT,
	}

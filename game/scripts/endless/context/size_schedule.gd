# size_schedule.gd
class_name SizeSchedule
extends RefCounted

const SIZES_TUTORIAL: Array[int] = [4, 4, 4, 5, 5, 5, 6, 6, 6, 6]
const SIZES_TRANSITION: Array[int] = [7, 7, 8, 8, 9, 9, 10, 10, 11, 12]
const SIZES_CYCLE: Array[int] = [8, 10, 11, 9, 10, 12, 9, 10, 11, 12]


static func get_size(level_num: int) -> int:
	if level_num < 1:
		return 0
	if level_num <= 10:
		return SIZES_TUTORIAL[level_num - 1]
	if level_num <= 20:
		return SIZES_TRANSITION[level_num - 11]
	return SIZES_CYCLE[(level_num - 21) % SIZES_CYCLE.size()]

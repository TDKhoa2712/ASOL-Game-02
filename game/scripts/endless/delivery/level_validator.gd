# level_validator.gd
class_name LevelDeliveryValidator
extends RefCounted

const BoardTransformClass = preload("res://scripts/content/board_transform.gd")
const CandyRulesClass = preload("res://scripts/core/candy_rules.gd")
const PuzzleDedupClass = preload("res://scripts/endless/delivery/puzzle_dedup.gd")


static func validate_candidate(level: Dictionary) -> bool:
	if level.is_empty():
		return false
	if not level.has("regions") or not level.has("solution"):
		return false
	return CandyRulesClass.verify_level(level)


static func prepare_delivery(level: Dictionary, transform_id: int, progress: RefCounted) -> Dictionary:
	if not validate_candidate(level):
		return {}

	if PuzzleDedupClass.is_duplicate(level, progress):
		return {}

	var final_level := level.duplicate(true)
	if bool(level.get("_apply_transform", true)) and transform_id > 0:
		final_level = BoardTransformClass.apply(final_level, transform_id)

	if not CandyRulesClass.verify_level(final_level):
		return {}

	PuzzleDedupClass.register(level, progress)
	return final_level

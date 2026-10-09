# combo_tracker.gd — counts consecutive player-placed correct candies.
extends RefCounted

const MAX_LEVEL := 12

var streak: int = 0

func on_correct() -> int:
	streak += 1
	return mini(streak, MAX_LEVEL)

func reset() -> void:
	streak = 0

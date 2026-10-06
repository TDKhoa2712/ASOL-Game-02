extends RefCounted

# Normalize the corner distance so every board finishes in the same time.
const SWEEP_SECONDS := 0.5
const POP_SECONDS := 0.34
const DURATION := SWEEP_SECONDS + POP_SECONDS

static func cell_scale(count: int, row: int, col: int, elapsed: float) -> float:
	if elapsed < 0.0 or count <= 0: return 1.0
	var distance := Vector2(col, count - 1 - row).length()
	var furthest := sqrt(2.0) * float(maxi(1, count - 1))
	var progress := clampf((elapsed - SWEEP_SECONDS * distance / furthest) / POP_SECONDS, 0.0, 1.0)
	if progress <= 0.0: return 0.0
	if progress >= 1.0: return 1.0
	# A small overshoot makes the arriving cells feel like a travelling ripple.
	var tail := progress - 1.0
	return 1.0 + 2.70158 * tail * tail * tail + 1.70158 * tail * tail

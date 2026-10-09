# mascot_motion.gd — Continuous body motion for board mascots, sampled every rendered frame.
# Offsets (dx, dy) are in atlas-frame pixels (frame = 128px); the drawer rescales them to the cell.
extends RefCounted

const IDENTITY := {"sc": 1.0, "sx": 1.0, "sy": 1.0, "dx": 0.0, "dy": 0.0, "tint": 0.0}

# u: animation progress 0..1 (looping anims wrap before calling).
static func sample(anim: String, u: float) -> Dictionary:
	var m := IDENTITY.duplicate()
	u = clampf(u, 0.0, 1.0)
	match anim:
		"appear":
			var k := 1.0 - pow(1.0 - u, 3.0)
			m.sc = 0.2 + 0.8 * k + 0.25 * sin(PI * k)
			m.sy = 1.0 - 0.25 * _bump(u, 0.55, 1.0)
			m.dy = -18.0 * _bump(u, 0.0, 0.55)
		"idle":
			m.sy = 1.0 + 0.09 * sin(TAU * u)
			m.dy = -6.0 * maxf(0.0, sin(TAU * u))
		"error":
			m.dx = 14.0 * sin(TAU * 3.0 * u) * (1.0 - 0.6 * u)
			m.sy = 1.0 - 0.08 * sin(PI * u)
			m.tint = 0.55 * sin(PI * u)
		"sad":
			m.sy = 1.0 - 0.08 * sin(TAU * u)
			m.dx = 2.5 * sin(TAU * 4.0 * u)
		"win":
			m.dy = -34.0 * sin(PI * u)
			m.sy = 1.0 + 0.12 * _bump(u, 0.15, 0.85) - 0.2 * _bump(u, 0.0, 0.12) - 0.18 * _bump(u, 0.88, 1.0)
	m.sx = 2.0 - m.sy if anim != "idle" else 1.0 - 0.07 * sin(TAU * u)
	return m

# Smooth 0 -> 1 -> 0 hump over [a, b], zero outside.
static func _bump(u: float, a: float, b: float) -> float:
	return sin(PI * clampf((u - a) / (b - a), 0.0, 1.0))

# Cartoon flame outlines in a 100x100 box (base at y≈97), each as cubic Bezier chains:
# [start, c1, c2, end, c1, c2, end, ...]. A/B pairs share point counts so they blend.
extends RefCounted

const OUTER_A := [Vector2(52, 4),
	Vector2(62, 24), Vector2(82, 38), Vector2(82, 64), Vector2(82, 84), Vector2(68, 97), Vector2(50, 97),
	Vector2(32, 97), Vector2(18, 84), Vector2(18, 64), Vector2(18, 46), Vector2(30, 40), Vector2(34, 24),
	Vector2(40, 34), Vector2(44, 38), Vector2(46, 40), Vector2(46, 26), Vector2(48, 14), Vector2(52, 4)]
const OUTER_B := [Vector2(44, 6),
	Vector2(60, 22), Vector2(84, 40), Vector2(82, 64), Vector2(82, 84), Vector2(68, 97), Vector2(50, 97),
	Vector2(32, 97), Vector2(18, 84), Vector2(18, 64), Vector2(18, 44), Vector2(26, 36), Vector2(30, 22),
	Vector2(38, 32), Vector2(44, 36), Vector2(48, 38), Vector2(50, 26), Vector2(44, 16), Vector2(44, 6)]
const MID_A := [Vector2(50, 30),
	Vector2(58, 44), Vector2(70, 52), Vector2(70, 70), Vector2(70, 84), Vector2(61, 92), Vector2(50, 92),
	Vector2(39, 92), Vector2(30, 84), Vector2(30, 70), Vector2(30, 58), Vector2(38, 54), Vector2(42, 44),
	Vector2(44, 50), Vector2(46, 52), Vector2(48, 52), Vector2(48, 44), Vector2(48, 38), Vector2(50, 30)]
const MID_B := [Vector2(55, 32),
	Vector2(61, 46), Vector2(72, 54), Vector2(70, 70), Vector2(70, 84), Vector2(61, 92), Vector2(50, 92),
	Vector2(39, 92), Vector2(30, 84), Vector2(30, 70), Vector2(30, 56), Vector2(36, 50), Vector2(40, 42),
	Vector2(44, 48), Vector2(46, 52), Vector2(50, 52), Vector2(53, 44), Vector2(52, 38), Vector2(55, 32)]
const CORE_A := [Vector2(50, 54),
	Vector2(56, 64), Vector2(60, 70), Vector2(60, 78), Vector2(60, 86), Vector2(55, 90), Vector2(50, 90),
	Vector2(45, 90), Vector2(40, 86), Vector2(40, 78), Vector2(40, 70), Vector2(46, 64), Vector2(50, 54)]
const CORE_B := [Vector2(47, 56),
	Vector2(56, 64), Vector2(61, 72), Vector2(60, 79), Vector2(60, 86), Vector2(55, 90), Vector2(50, 90),
	Vector2(45, 90), Vector2(40, 86), Vector2(40, 79), Vector2(40, 70), Vector2(44, 64), Vector2(47, 56)]
# Small tongues that pop off the sides and tip, then drift up.
const LICKS := [
	[Vector2(22, 52), Vector2(26, 46), Vector2(30, 44), Vector2(30, 38), Vector2(34, 44), Vector2(34, 50),
		Vector2(30, 56), Vector2(27, 59), Vector2(22, 57), Vector2(22, 52)],
	[Vector2(70, 50), Vector2(70, 44), Vector2(74, 40), Vector2(76, 36), Vector2(80, 42), Vector2(82, 50),
		Vector2(78, 56), Vector2(75, 59), Vector2(70, 56), Vector2(70, 50)],
	[Vector2(47, 18), Vector2(47, 13), Vector2(50, 10), Vector2(52, 6), Vector2(55, 11), Vector2(56, 16),
		Vector2(53, 20), Vector2(51, 22), Vector2(47, 21), Vector2(47, 18)],
]
const LICK_DRIFT := [Vector2(-8, -26), Vector2(9, -26), Vector2(-3, -26)]
const TWINKLES := [Vector3(14, 37, 7.0), Vector3(86, 27.6, 5.6), Vector3(88, 78.8, 4.8)]  # x, y, radius

# Closed polygon from a Bezier chain; the closing point is dropped.
static func sample(chain: Array, steps: int) -> PackedVector2Array:
	var out := PackedVector2Array([chain[0]])
	var i := 1
	while i + 2 < chain.size():
		var p0: Vector2 = chain[i - 1]
		for s in range(1, steps + 1):
			var t := float(s) / steps
			out.append(p0.bezier_interpolate(chain[i], chain[i + 1], chain[i + 2], t))
		i += 3
	if out.size() > 1 and out[0].is_equal_approx(out[out.size() - 1]):
		out.remove_at(out.size() - 1)
	return out

static func blend(a: PackedVector2Array, b: PackedVector2Array, t: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(a.size())
	for i in a.size():
		out[i] = a[i].lerp(b[i], t)
	return out

# Four-point sparkle centred on c.
static func star(c: Vector2, r: float) -> PackedVector2Array:
	var k := r * 0.28
	return PackedVector2Array([c + Vector2(0, -r), c + Vector2(k, -k), c + Vector2(r, 0), c + Vector2(k, k),
		c + Vector2(0, r), c + Vector2(-k, k), c + Vector2(-r, 0), c + Vector2(-k, -k)])

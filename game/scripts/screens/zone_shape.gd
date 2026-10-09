# zone_shape.gd
# Vector shapes for colorblind mode: one distinct silhouette per zone color.
extends RefCounted

const RegionPainter = preload("res://scripts/content/region_painter.gd")
const Icon = RegionPainter.OverlayIcon

# Large, faint watermark centered in the cell; candies and marks draw on top of it.
const SIZE_RATIO := 0.62
const FILL_ALPHA := 0.32

static func draw(canvas: CanvasItem, icon: int, cell_rect: Rect2, base_color: Color) -> void:
	var side := cell_rect.size.x * SIZE_RATIO
	var center := cell_rect.get_center()
	var fill := Color(base_color.darkened(0.6), FILL_ALPHA)
	var outline := Color(1, 1, 1, FILL_ALPHA)
	var width := maxf(1.0, side * 0.04)
	for poly in polygons(icon, center, side * 0.5):
		canvas.draw_colored_polygon(poly, fill)
	if icon == Icon.RING:
		# Outline the two circles, not the seams between the half-rings.
		canvas.draw_arc(center, side * 0.5, 0.0, TAU, 32, outline, width, true)
		canvas.draw_arc(center, side * 0.25, 0.0, TAU, 24, outline, width, true)
		return
	for poly in polygons(icon, center, side * 0.5):
		var closed: PackedVector2Array = poly.duplicate()
		closed.append(poly[0])
		canvas.draw_polyline(closed, outline, width, true)

# Simple (non-self-intersecting) polygons filling a circle of radius r around c.
static func polygons(icon: int, c: Vector2, r: float) -> Array:
	match icon:
		Icon.CIRCLE: return [_regular(c, r, 24, 0.0)]
		Icon.SQUARE: return [_regular(c, r * 1.1, 4, PI / 4.0)]
		Icon.TRIANGLE: return [_regular(c + Vector2(0, r * 0.15), r * 1.1, 3, -PI / 2.0)]
		Icon.TRIANGLE_DOWN: return [_regular(c - Vector2(0, r * 0.15), r * 1.1, 3, PI / 2.0)]
		Icon.DIAMOND: return [_scaled(_regular(c, r, 4, -PI / 2.0), c, Vector2(0.75, 1.0))]
		Icon.HEXAGON: return [_regular(c, r, 6, 0.0)]
		Icon.STAR: return [_star(c, r, r * 0.45, 5)]
		Icon.PLUS: return [_plus(c, r, r * 0.36, 0.0)]
		Icon.DROP: return [_drop(c, r)]
		Icon.HEART: return [_heart(c, r)]
		Icon.RING: return _ring(c, r, r * 0.5)
		Icon.CRESCENT: return [_crescent(c, r)]
	return []

static func _regular(c: Vector2, r: float, n: int, start: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(n):
		out.append(c + Vector2.from_angle(start + TAU * float(i) / float(n)) * r)
	return out

static func _scaled(poly: PackedVector2Array, c: Vector2, k: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		out.append(c + (p - c) * k)
	return out

static func _star(c: Vector2, outer: float, inner: float, points: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(points * 2):
		var rad := outer if i % 2 == 0 else inner
		out.append(c + Vector2.from_angle(-PI / 2.0 + PI * float(i) / float(points)) * rad)
	return out

static func _plus(c: Vector2, r: float, half: float, angle: float) -> PackedVector2Array:
	var pts := [Vector2(-half, -r), Vector2(half, -r), Vector2(half, -half), Vector2(r, -half), Vector2(r, half), Vector2(half, half),
		Vector2(half, r), Vector2(-half, r), Vector2(-half, half), Vector2(-r, half), Vector2(-r, -half), Vector2(-half, -half)]
	var out := PackedVector2Array()
	for p in pts:
		out.append(c + (p as Vector2).rotated(angle))
	return out

# Teardrop: round bottom, point on top.
static func _drop(c: Vector2, r: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var bc := c + Vector2(0, r * 0.3)
	var br := r * 0.68
	out.append(c - Vector2(0, r))
	for i in range(21):
		out.append(bc + Vector2.from_angle(-PI * 0.17 + PI * 1.34 * float(i) / 20.0) * br)
	return out

static func _heart(c: Vector2, r: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(32):
		var t := TAU * float(i) / 32.0
		var x := 16.0 * pow(sin(t), 3)
		var y := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		out.append(c + Vector2(x, -y - 2.5) * (r / 16.0))
	return out

# Annulus split into two half-rings so each piece stays a simple polygon.
static func _ring(c: Vector2, outer: float, inner: float) -> Array:
	var halves: Array = []
	for h in range(2):
		var poly := PackedVector2Array()
		for i in range(13):
			poly.append(c + Vector2.from_angle(PI * float(h) + PI * float(i) / 12.0) * outer)
		for i in range(12, -1, -1):
			poly.append(c + Vector2.from_angle(PI * float(h) + PI * float(i) / 12.0) * inner)
		halves.append(poly)
	return halves

static func _crescent(c: Vector2, r: float) -> PackedVector2Array:
	# Outer arc of the moon, then the bite arc back, both spanning the same two horns.
	var out := PackedVector2Array()
	for i in range(21):
		out.append(c + Vector2.from_angle(PI * 0.3 + PI * 1.4 * float(i) / 20.0) * r)
	var bite_c := c + Vector2(r * 0.55, 0.0)
	var a0 := (out[out.size() - 1] - bite_c).angle()
	var a1 := (out[0] - bite_c).angle()
	if a1 > a0: a1 -= TAU
	for i in range(1, 20):
		var a := lerpf(a0, a1, float(i) / 20.0)
		out.append(bite_c + Vector2.from_angle(a) * (out[0] - bite_c).length())
	return out

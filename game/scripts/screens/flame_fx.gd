# Cartoon flame: outlined red shell, orange body and yellow core that morph between two shapes,
# bob, and (when decorated) pop small tongues and twinkles while lit.
extends Control

const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const FlameShapes = preload("res://scripts/screens/flame_shapes.gd")
const LAYER_COLORS := [Color("#FF5A2A"), Color("#FF9F1C"), Color("#FFE066")]
const LICK_COLORS := [Color("#FF8A1F"), Color("#FFB020"), Color("#FF6A2A")]
const OUTLINE := Color("#A8280E")
const OFF_COLOR := Color("#B9B4AC")
const OFF_OUTLINE := Color("#9A948B")
const TWINKLE := Color("#FFC93C")
const PERIODS := [0.9, 0.7, 0.55]  # seconds per half swing, per layer
const BOB_PERIOD := 1.1
const LICK_PERIOD := 1.6
const LICK_DELAYS := [0.0, 0.55, 1.05]
const TWINKLE_PERIOD := 1.8
const STEPS := 6

var lit := false
var decorated := false
var side := 64.0
var _time := 0.0
var _pairs: Array = []  # [a, b] sampled polygons per layer, in the 100-unit box
var _licks: Array[PackedVector2Array] = []
var _shine: PackedVector2Array

func _init(p_side: float = 64.0, embers: int = 0) -> void:
	name = "FlameFx"
	side = p_side
	decorated = embers > 0
	custom_minimum_size = Vector2(side, side)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for pair in [[FlameShapes.OUTER_A, FlameShapes.OUTER_B], [FlameShapes.MID_A, FlameShapes.MID_B],
			[FlameShapes.CORE_A, FlameShapes.CORE_B]]:
		_pairs.append([FlameShapes.sample(pair[0], STEPS), FlameShapes.sample(pair[1], STEPS)])
	for chain in FlameShapes.LICKS:
		_licks.append(FlameShapes.sample(chain, 4))
	_shine = PackedVector2Array()
	for i in 7:
		_shine.append(Vector2(27, 62).bezier_interpolate(Vector2(27, 52), Vector2(31, 46), Vector2(36, 40), i / 6.0))
	set_lit(false)

func set_lit(on: bool) -> void:
	lit = on
	_time = 0.0
	_sync_motion()
	queue_redraw()

func is_flickering() -> bool:
	return is_processing()

# Moves the animation clock by dt seconds (tests and the screens' timelines use it).
func advance(dt: float) -> void:
	_time += dt
	queue_redraw()

func layer_polygons() -> Array:
	var k := side / 100.0
	var out: Array = []
	for i in (_pairs.size() if lit else 1):
		out.append(_scaled(FlameShapes.blend(_pairs[i][0], _pairs[i][1], _morph(i)), k))
	return out

func layer_colors() -> Array:
	return LAYER_COLORS.duplicate() if lit else [OFF_COLOR]

func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		_sync_motion()
	elif what == NOTIFICATION_EXIT_TREE:
		set_process(false)

func _sync_motion() -> void:
	set_process(lit and LayoutTokens.motion_enabled and is_inside_tree())

func _process(delta: float) -> void:
	advance(delta)

func _morph(i: int) -> float:
	if not lit:
		return 0.0
	return 0.5 - 0.5 * cos(_time * PI / float(PERIODS[i]))

func _draw() -> void:
	var k := side / 100.0
	var w := TAU * _time / BOB_PERIOD if lit else 0.0
	var base := Vector2(side * 0.5, side * 0.97)
	var sc := Vector2(1.0 + 0.03 * sin(w), 1.0 - 0.03 * sin(w) + 0.02 * sin(w * 2.0))
	if decorated and lit:
		_draw_licks(k)
	draw_set_transform(base - (base * sc).rotated(0.026 * sin(w)), 0.026 * sin(w), sc)
	var polys := layer_polygons()
	var colors := layer_colors()
	for i in polys.size():
		draw_colored_polygon(polys[i], colors[i])
	var outer: PackedVector2Array = polys[0].duplicate()
	outer.append(outer[0])
	draw_polyline(outer, OUTLINE if lit else OFF_OUTLINE, maxf(1.0, 3.5 * k), true)
	if lit:
		var a := 0.65 + 0.2 * cos(w)
		draw_polyline(_scaled(_shine, k), Color(1, 1, 1, a), maxf(1.0, 4.0 * k), true)
		draw_circle(Vector2(26, 70) * k, 2.4 * k, Color(1, 1, 1, a))
	draw_set_transform(Vector2.ZERO)
	if decorated and lit:
		_draw_twinkles(k)

func _draw_licks(k: float) -> void:
	for i in _licks.size():
		var u := fposmod(_time - float(LICK_DELAYS[i]), LICK_PERIOD) / LICK_PERIOD
		var grow := u < 0.2
		var s := lerpf(0.3, 1.0, u / 0.2) if grow else lerpf(1.0, 0.2, (u - 0.2) / 0.8)
		var alpha := u / 0.2 if grow else 1.0 - (u - 0.2) / 0.8
		var drift: Vector2 = Vector2.ZERO if grow else FlameShapes.LICK_DRIFT[i] * ((u - 0.2) / 0.8)
		var pts := _licks[i]
		var pivot := _bottom_centre(pts)
		var moved := PackedVector2Array()
		for p in pts:
			moved.append((pivot + (p - pivot) * s + drift) * k)
		var c: Color = LICK_COLORS[i]
		draw_colored_polygon(moved, Color(c, alpha))
		moved.append(moved[0])
		draw_polyline(moved, Color(OUTLINE, alpha), maxf(1.0, 2.5 * k), true)

func _draw_twinkles(k: float) -> void:
	for i in FlameShapes.TWINKLES.size():
		var t: Vector3 = FlameShapes.TWINKLES[i]
		var u := fposmod(_time - 0.6 * i, TWINKLE_PERIOD) / TWINKLE_PERIOD
		var alpha := u / 0.45 if u < 0.45 else (1.0 - (u - 0.45) / 0.25 if u < 0.7 else 0.0)
		if alpha <= 0.01:
			continue
		var r := t.z * (0.2 + 0.8 * alpha) * k
		var pts := FlameShapes.star(Vector2(t.x, t.y) * k, r)
		draw_colored_polygon(pts, Color(TWINKLE, alpha))

static func _bottom_centre(pts: PackedVector2Array) -> Vector2:
	var sum := Vector2.ZERO
	var bottom := -INF
	for p in pts:
		sum += p
		bottom = maxf(bottom, p.y)
	return Vector2(sum.x / pts.size(), bottom)

static func _scaled(pts: PackedVector2Array, k: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(pts.size())
	for i in pts.size():
		out[i] = pts[i] * k
	return out

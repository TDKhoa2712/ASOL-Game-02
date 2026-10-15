# Gift box drawn in code: pink box, gold ribbon and bow. Idle wiggles now and then; opening
# shakes harder and harder, squashes, then the lid flies off and `opened` fires.
class_name GiftBoxView
extends Control

signal opened

const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const SCENE := "res://scenes/components/gift_box_view.tscn"
const BODY := Color("#F2667A")
const BAND := Color("#D94A62")
const LID := Color("#FF7E90")
const RIBBON := Color("#FFC93C")
const RIBBON_LIGHT := Color("#FFE27A")
const RIBBON_EDGE := Color("#C4A030")
const KNOT := Color("#E8A90A")
const SHADOW := Color(0.55, 0.26, 0.23, 0.18)
const SHAKE_TIME := 0.62
const LID_TIME := 0.5

var is_open := false
var lid_lift := 0.0:
	set(v): lid_lift = v; queue_redraw()
var wobble := 0.0:
	set(v): wobble = v; queue_redraw()
var squash := 0.0:
	set(v): squash = v; queue_redraw()
var _tween: Tween = null

static func create() -> GiftBoxView:
	return (load(SCENE) as PackedScene).instantiate() as GiftBoxView

func _init() -> void:
	name = "GiftBoxView"
	custom_minimum_size = Vector2(56, 56)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_open_amount(a: float) -> void:
	lid_lift = clampf(a, 0.0, 1.0)

func play_idle() -> void:
	_stop()
	is_open = false
	lid_lift = 0.0; squash = 0.0
	if not LayoutTokens.motion_enabled or not is_inside_tree():
		return
	_tween = create_tween().set_loops()
	_tween.tween_interval(2.2)
	for r in [-0.17, 0.17, -0.1, 0.07, 0.0]:
		_tween.tween_property(self, "wobble", r, 0.12).set_trans(Tween.TRANS_SINE)

func play_open() -> void:
	_stop()
	if not LayoutTokens.motion_enabled or not is_inside_tree():
		finish_open()
		return
	_tween = create_tween()
	var step := SHAKE_TIME / 8.0
	for i in 8:
		var amp := 0.1 + 0.012 * i * i
		_tween.tween_property(self, "wobble", amp if i % 2 == 0 else -amp, step)
	_tween.tween_property(self, "wobble", 0.0, 0.05)
	_tween.parallel().tween_property(self, "squash", 1.0, 0.08)
	_tween.tween_property(self, "squash", -0.6, 0.12)
	_tween.parallel().tween_property(self, "lid_lift", 1.0, LID_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "squash", 0.0, 0.3).set_delay(0.12)
	_tween.tween_callback(finish_open)

func finish_open() -> void:
	_stop()
	lid_lift = 1.0; wobble = 0.0; squash = 0.0
	is_open = true
	opened.emit()

func _stop() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	wobble = 0.0

func _draw() -> void:
	var k := minf(size.x, size.y) / 180.0
	var base := Vector2(size.x * 0.5, size.y)
	var sc := Vector2(1.0 + 0.18 * squash, 1.0 - 0.18 * squash)
	draw_set_transform(base - (base * sc).rotated(wobble), wobble, sc)
	var o := Vector2((size.x - 180.0 * k) * 0.5, size.y - 180.0 * k)
	var r := func(x: float, y: float, w: float, h: float) -> Rect2: return Rect2(o + Vector2(x, y) * k, Vector2(w, h) * k)
	draw_set_transform(base - (base * sc).rotated(wobble), wobble, sc)
	_ellipse(o + Vector2(90, 172) * k, Vector2(70, 8) * k, SHADOW)
	_round(r.call(22, 78, 136, 92), 14 * k, BODY)
	draw_rect(r.call(22, 78, 136, 20), BAND)
	draw_rect(r.call(78, 78, 24, 92), RIBBON)
	draw_rect(r.call(84, 78, 6, 92), RIBBON_LIGHT)
	if lid_lift >= 0.999:
		return
	# Lid flies up and to the right, spinning and fading.
	var pivot := o + Vector2(90, 86) * k
	var lift := Vector2(60, -170) * k * lid_lift
	var spin := deg_to_rad(40) * lid_lift
	var alpha := 1.0 - clampf((lid_lift - 0.6) / 0.4, 0.0, 1.0)
	var t := Transform2D(wobble, sc, 0.0, base - (base * sc).rotated(wobble))
	t = t * Transform2D(spin, pivot + lift) * Transform2D(0.0, -pivot)
	draw_set_transform_matrix(t)
	_round(r.call(12, 56, 156, 30), 10 * k, Color(LID, alpha))
	draw_rect(r.call(74, 56, 32, 30), Color(RIBBON, alpha))
	draw_rect(r.call(80, 56, 8, 30), Color(RIBBON_LIGHT, alpha))
	for side in [-1.0, 1.0]:
		var loop := PackedVector2Array()
		for i in 13:
			var a := PI * i / 12.0
			loop.append(o + (Vector2(90, 54) + Vector2(side * (21 - 21 * cos(a)), -15 * sin(a) - 4 * sin(a * 2.0))) * k)
		draw_colored_polygon(loop, Color(RIBBON, alpha))
		loop.append(loop[0])
		draw_polyline(loop, Color(RIBBON_EDGE, alpha), maxf(1.0, 3.0 * k), true)
	draw_circle(o + Vector2(90, 54) * k, 9 * k, Color(KNOT, alpha))

func _round(rect: Rect2, radius: float, color: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(int(radius))
	sb.anti_aliasing = true
	draw_style_box(sb, rect)

func _ellipse(c: Vector2, radii: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(pts, color)

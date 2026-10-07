# splash_screen.gd — Alpaca Solutions studio logo splash animation
extends Control

signal finished()

const DARK_PURPLE := Color("#3B2779")
const MID_PURPLE := Color("#523D94")
const YELLOW := Color("#FEB801")
const BG_COLOR := Color("#FFFDF5")
const TEXT_COLOR := Color("#3B2779")

const SVG_SIZE := 1254.0
const ANIM_DURATION := 3.2

const PIECES := [
	{ "pts": [Vector2(570,25), Vector2(769,140), Vector2(766,362)],                          "color": "dark",   "t": 0.30, "dur": 0.40, "rot": -0.15 },
	{ "pts": [Vector2(681,221), Vector2(410,287), Vector2(341,403)],                         "color": "yellow", "t": 0.40, "dur": 0.40, "rot":  0.18 },
	{ "pts": [Vector2(681,221), Vector2(766,362), Vector2(670,526)],                         "color": "yellow", "t": 0.50, "dur": 0.40, "rot": -0.12 },
	{ "pts": [Vector2(681,221), Vector2(577,433), Vector2(484,487), Vector2(341,403)],       "color": "dark",   "t": 0.58, "dur": 0.40, "rot":  0.20 },
	{ "pts": [Vector2(681,221), Vector2(670,526), Vector2(577,433)],                         "color": "mid",    "t": 0.66, "dur": 0.40, "rot": -0.12 },
	{ "pts": [Vector2(766,362), Vector2(936,661), Vector2(670,526)],                         "color": "mid",    "t": 0.74, "dur": 0.40, "rot":  0.15 },
	{ "pts": [Vector2(670,526), Vector2(936,661), Vector2(503,817)],                         "color": "yellow", "t": 0.90, "dur": 0.50, "rot": -0.20 },
	{ "pts": [Vector2(936,661), Vector2(503,817), Vector2(612,1226)],                        "color": "mid",    "t": 1.10, "dur": 0.40, "rot":  0.18 },
]

var _logo_container: Control
var _polygons: Array[Polygon2D] = []
var _glow_overlays: Array[Polygon2D] = []
var _glow_circle: GlowDraw
var _studio_label: Label
var _tween: Tween

func _ready() -> void:
	_build_scene()
	get_tree().process_frame.connect(_start_once, CONNECT_ONE_SHOT)

func _start_once() -> void:
	_position_elements()
	_play_animation()

func _build_scene() -> void:
	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_glow_circle = GlowDraw.new()
	_glow_circle.modulate.a = 0.0
	add_child(_glow_circle)

	_logo_container = Control.new()
	_logo_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_logo_container)

	var color_map := { "dark": DARK_PURPLE, "mid": MID_PURPLE, "yellow": YELLOW }
	for piece in PIECES:
		var poly := _make_polygon(piece.pts, color_map[piece.color])
		var c := _centroid(piece.pts)
		poly.position = c
		poly.offset = -c
		poly.modulate.a = 0.0
		poly.scale = Vector2(0.7, 0.0)
		poly.rotation = piece.rot
		_logo_container.add_child(poly)
		_polygons.append(poly)

	var yellow_indices := [1, 2, 6]
	for idx in yellow_indices:
		var overlay := _make_polygon(PIECES[idx].pts, Color(1, 1, 1, 0.9))
		var c := _centroid(PIECES[idx].pts)
		overlay.position = c
		overlay.offset = -c
		overlay.modulate.a = 0.0
		_logo_container.add_child(overlay)
		_glow_overlays.append(overlay)

	_studio_label = Label.new()
	_studio_label.text = "ALPACA SOLUTIONS"
	_studio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_studio_label.add_theme_font_size_override("font_size", 28)
	_studio_label.add_theme_color_override("font_color", TEXT_COLOR)
	var font := _load_font()
	if font != null:
		_studio_label.add_theme_font_override("font", font)
	_studio_label.modulate.a = 0.0
	_studio_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_studio_label)

	_position_elements()
	resized.connect(_position_elements)

func _load_font() -> Font:
	var path := "res://assets/fonts/Nunito-SemiBold.ttf"
	if ResourceLoader.exists(path):
		return load(path) as Font
	return null

func _make_polygon(svg_pts: Array, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	var packed := PackedVector2Array()
	for pt in svg_pts:
		packed.append(pt as Vector2)
	poly.polygon = packed
	poly.color = color
	return poly

func _centroid(pts: Array) -> Vector2:
	var sum := Vector2.ZERO
	for pt in pts:
		sum += pt as Vector2
	return sum / float(pts.size())

func _position_elements() -> void:
	var vp := get_viewport_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return

	var scale_factor: float = (vp.y * 0.30) / SVG_SIZE
	var bbox_cx: float = (341.0 + 936.0) / 2.0
	var bbox_cy: float = (25.0 + 1226.0) / 2.0

	_logo_container.position = Vector2(vp.x / 2.0 - bbox_cx * scale_factor,
										vp.y * 0.42 - bbox_cy * scale_factor)
	_logo_container.scale = Vector2(scale_factor, scale_factor)

	_glow_circle.position = Vector2(vp.x / 2.0, vp.y * 0.42)
	_glow_circle.radius = vp.y * 0.22
	_glow_circle.queue_redraw()

	_studio_label.position = Vector2(0, vp.y * 0.42 + (SVG_SIZE / 2.0) * scale_factor + 30)
	_studio_label.size = Vector2(vp.x, 60)

func _play_animation() -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)

	# Phase 1: Ambient glow fade in (0.0 – 0.4s)
	_tween.tween_property(_glow_circle, "modulate:a", 1.0, 0.5) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	# Phase 2: Triangle unfold cascade
	for i in _polygons.size():
		var piece: Dictionary = PIECES[i]
		var poly: Polygon2D = _polygons[i]
		var t0: float = piece.t
		var dur: float = piece.dur

		_tween.tween_property(poly, "modulate:a", 1.0, dur * 0.6) \
			.set_delay(t0) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

		_tween.tween_property(poly, "scale", Vector2.ONE, dur) \
			.set_delay(t0) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

		_tween.tween_property(poly, "rotation", 0.0, dur * 1.1) \
			.set_delay(t0) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Phase 3: Glow pulse on yellow pieces (staggered)
	var glow_start := 1.85
	for i in _glow_overlays.size():
		var overlay: Polygon2D = _glow_overlays[i]
		var gt: float = glow_start + i * 0.12
		_tween.tween_property(overlay, "modulate:a", 0.3, 0.20) \
			.set_delay(gt) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_tween.tween_property(overlay, "modulate:a", 0.0, 0.25) \
			.set_delay(gt + 0.20) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	# Ambient glow fade out
	_tween.tween_property(_glow_circle, "modulate:a", 0.0, 0.8) \
		.set_delay(1.85) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Phase 4: Text reveal (2.3 – 3.0s)
	var text_final_y: float = _studio_label.position.y
	_studio_label.position.y = text_final_y + 12.0
	_tween.tween_property(_studio_label, "modulate:a", 1.0, 0.5) \
		.set_delay(2.3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_studio_label, "position:y", text_final_y, 0.6) \
		.set_delay(2.3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Emit finished after full animation
	_tween.chain().tween_callback(func(): finished.emit()) \
		.set_delay(ANIM_DURATION)


class GlowDraw extends Node2D:
	var radius := 220.0
	var color := Color(0.996, 0.722, 0.004, 0.08)
	func _draw() -> void:
		var steps := 24
		for i in range(steps, 0, -1):
			var r: float = radius * (float(i) / float(steps))
			var a: float = color.a * (1.0 - float(i - 1) / float(steps))
			draw_circle(Vector2.ZERO, r, Color(color, a))

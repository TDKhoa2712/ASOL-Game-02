# splash_screen.gd — Alpaca Solutions studio logo splash animation
extends Control

signal finished()

const DARK_PURPLE := Color("#3B2779")
const MID_PURPLE := Color("#523D94")
const YELLOW := Color("#FEB801")
const BG_COLOR := Color("#0D0B1A")
const TEXT_COLOR := Color("#F0EDF5")

const SVG_SIZE := 1254.0
const LOGO_HEIGHT := 320.0
const ANIM_DURATION := 3.0

## Polygon data: id, vertices (SVG coords), color, unfold start time, duration, rotation offset
const PIECES := [
	{ "name": "DarkWing",     "pts": [Vector2(570,25), Vector2(769,140), Vector2(766,362)], "color": "dark", "t": 0.3, "dur": 0.27, "rot": -0.25 },
	{ "name": "YellowTop",    "pts": [Vector2(681,221), Vector2(410,287), Vector2(341,403)], "color": "yellow", "t": 0.4, "dur": 0.27, "rot": 0.3 },
	{ "name": "YellowSliver", "pts": [Vector2(681,221), Vector2(766,362), Vector2(670,526)], "color": "yellow", "t": 0.5, "dur": 0.27, "rot": -0.2 },
	{ "name": "DarkLeft",     "pts": [Vector2(681,221), Vector2(577,433), Vector2(484,487), Vector2(341,403)], "color": "dark", "t": 0.6, "dur": 0.27, "rot": 0.35 },
	{ "name": "MidSmall",     "pts": [Vector2(681,221), Vector2(670,526), Vector2(577,433)], "color": "mid", "t": 0.7, "dur": 0.27, "rot": -0.2 },
	{ "name": "MidRight",     "pts": [Vector2(766,362), Vector2(936,661), Vector2(670,526)], "color": "mid", "t": 0.8, "dur": 0.27, "rot": 0.25 },
	{ "name": "YellowBig",    "pts": [Vector2(670,526), Vector2(936,661), Vector2(503,817)], "color": "yellow", "t": 1.0, "dur": 0.35, "rot": -0.35 },
	{ "name": "MidBottom",    "pts": [Vector2(936,661), Vector2(503,817), Vector2(612,1226)], "color": "mid", "t": 1.27, "dur": 0.27, "rot": 0.3 },
]

var _logo_container: Control
var _polygons: Array[Polygon2D] = []
var _glow_overlays: Array[Polygon2D] = []
var _glow_ellipse: ColorRect
var _studio_label: Label
var _tween: Tween

func _ready() -> void:
	_build_scene()
	# Defer animation start so layout has settled and positions are final.
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

	_glow_ellipse = ColorRect.new()
	_glow_ellipse.color = Color(DARK_PURPLE, 0.15)
	_glow_ellipse.custom_minimum_size = Vector2(400, 400)
	_glow_ellipse.modulate.a = 0.0
	_glow_ellipse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_glow_ellipse)

	_logo_container = Control.new()
	_logo_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_logo_container)

	var color_map := { "dark": DARK_PURPLE, "mid": MID_PURPLE, "yellow": YELLOW }
	for piece in PIECES:
		var poly := _make_polygon(piece.pts, color_map[piece.color])
		poly.modulate.a = 0.0
		poly.scale.y = 0.0
		poly.rotation = piece.rot
		_logo_container.add_child(poly)
		_polygons.append(poly)

	var yellow_indices := [1, 2, 6]
	for idx in yellow_indices:
		var overlay := _make_polygon(PIECES[idx].pts, Color.WHITE)
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

func _position_elements() -> void:
	var vp := get_viewport_rect().size
	if vp.x <= 0 or vp.y <= 0:
		return

	var scale_factor: float = (vp.y * 0.30) / SVG_SIZE
	var cx: float = (341.0 + 936.0) / 2.0
	var cy: float = (25.0 + 1226.0) / 2.0

	_logo_container.position = Vector2(vp.x / 2.0, vp.y * 0.42)
	_logo_container.scale = Vector2(scale_factor, scale_factor)

	for poly in _polygons:
		poly.offset = Vector2(-cx, -cy)
	for overlay in _glow_overlays:
		overlay.offset = Vector2(-cx, -cy)

	_glow_ellipse.position = Vector2(vp.x / 2.0 - 200, vp.y * 0.42 - 200)

	_studio_label.position = Vector2(0, vp.y * 0.42 + (SVG_SIZE / 2.0) * scale_factor + 40)
	_studio_label.size = Vector2(vp.x, 60)

func _play_animation() -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)

	# Phase 1: Ambient glow fade in (0.0 – 0.3s)
	_tween.tween_property(_glow_ellipse, "modulate:a", 0.6, 0.3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Phase 2: Triangle unfold cascade
	for i in _polygons.size():
		var piece: Dictionary = PIECES[i]
		var poly: Polygon2D = _polygons[i]
		var t_start: float = piece.t
		var dur: float = piece.dur

		# Opacity: quick fade in
		_tween.tween_property(poly, "modulate:a", 1.0, dur * 0.5) \
			.set_delay(t_start)

		# ScaleY: 0 → 1 with back overshoot
		_tween.tween_property(poly, "scale:y", 1.0, dur) \
			.set_delay(t_start) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

		# Rotation: offset → 0 with back overshoot
		_tween.tween_property(poly, "rotation", 0.0, dur) \
			.set_delay(t_start) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Phase 3: Glow pulse on yellow pieces (1.8 – 2.4s)
	var glow_times := [1.8, 1.93, 2.07]
	for i in _glow_overlays.size():
		var overlay: Polygon2D = _glow_overlays[i]
		var gt: float = glow_times[i]
		_tween.tween_property(overlay, "modulate:a", 0.25, 0.15) \
			.set_delay(gt) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		_tween.tween_property(overlay, "modulate:a", 0.0, 0.15) \
			.set_delay(gt + 0.15) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

	# Ambient glow fade out
	_tween.tween_property(_glow_ellipse, "modulate:a", 0.0, 0.6) \
		.set_delay(1.8) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Phase 4: Text reveal (2.2 – 3.0s)
	var text_final_y: float = _studio_label.position.y
	_studio_label.position.y = text_final_y + 15.0
	_tween.tween_property(_studio_label, "modulate:a", 1.0, 0.4) \
		.set_delay(2.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(_studio_label, "position:y", text_final_y, 0.5) \
		.set_delay(2.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Signal when done
	_tween.chain().tween_callback(func(): finished.emit()) \
		.set_delay(ANIM_DURATION)

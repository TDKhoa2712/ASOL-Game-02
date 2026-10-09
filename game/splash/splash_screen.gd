extends Control
## Alpaca Solutions – studio splash screen (Godot 4.2+)
##
## Everything is built in code: the 8 origami facets fly in and assemble, a flash +
## rings + shards burst, a shine sweeps across the logo, the wordmark animates in,
## then the screen fades out and the next scene (loaded in the background) starts.
## Works in portrait and landscape – the layout is picked from the viewport size.

signal finished

## Scene to open after the splash. It is loaded in a background thread while the
## splash plays. Leave empty to only emit `finished`.
@export_file("*.tscn") var next_scene_path: String = ""
## Seconds from start until the exit fade begins.
@export var hold_time: float = 3.6
## Length of the exit fade.
@export var fade_time: float = 0.35
## Let the player tap to skip straight to the exit.
@export var skip_on_tap: bool = false

const C_BG := Color("#FFFDF8")
const C_DARK := Color("#3C2774")
const C_MID := Color("#523C94")
const C_YEL := Color("#FDB912")
const C_LAV := Color("#7C63C9")

const FONT := preload("res://splash/fonts/Unbounded.ttf")
const SHINE_SHADER := preload("res://splash/logo_shine.gdshader")

## Logo art space (the source image, cropped): x 330..950, y 15..1235.
const ART_H := 1220.0
const ART_CENTER := Vector2(640, 625)
const ART_MIN := Vector2(342, 25)
const ART_MAX := Vector2(935, 1225)

# Facets in fly-in order: points (art space), colour, start offset (art units),
# start rotation (deg), delay (s).
var FACETS := [
	[[Vector2(503, 817), Vector2(935, 660), Vector2(612, 1225)], C_MID, Vector2(-60, 700), -140.0, 0.20],
	[[Vector2(670, 525), Vector2(935, 660), Vector2(503, 817)], C_YEL, Vector2(640, 260), 160.0, 0.32],
	[[Vector2(766, 364), Vector2(935, 660), Vector2(670, 525)], C_MID, Vector2(700, -120), -200.0, 0.44],
	[[Vector2(680, 220), Vector2(766, 364), Vector2(670, 525)], C_YEL, Vector2(520, -560), 220.0, 0.56],
	[[Vector2(680, 220), Vector2(670, 525), Vector2(578, 432)], C_MID, Vector2(-620, 300), -180.0, 0.66],
	[[Vector2(342, 402), Vector2(680, 220), Vector2(578, 432), Vector2(484, 488)], C_DARK, Vector2(-720, 80), 140.0, 0.76],
	[[Vector2(410, 288), Vector2(680, 220), Vector2(342, 402)], C_YEL, Vector2(-560, -480), -220.0, 0.86],
	[[Vector2(572, 25), Vector2(770, 140), Vector2(766, 364), Vector2(680, 220)], C_DARK, Vector2(80, -760), 180.0, 0.96],
]

# Shards: burst offset (design px), rotation (deg), size (design px), colour.
var SHARDS := [
	[Vector2(-180, -120), 200.0, 14.0, C_YEL], [Vector2(170, -150), -160.0, 12.0, C_MID],
	[Vector2(220, 20), 240.0, 16.0, C_YEL], [Vector2(-230, 40), -200.0, 10.0, C_DARK],
	[Vector2(-140, 170), 180.0, 14.0, C_MID], [Vector2(150, 190), -220.0, 12.0, C_YEL],
	[Vector2(0, -240), 160.0, 10.0, C_YEL], [Vector2(30, 240), -140.0, 14.0, C_DARK],
	[Vector2(-90, -215), 120.0, 9.0, C_MID], [Vector2(240, -70), 200.0, 10.0, C_DARK],
	[Vector2(-250, -40), -120.0, 12.0, C_YEL], [Vector2(100, -225), 90.0, 8.0, C_MID],
	[Vector2(-200, 125), 150.0, 10.0, C_YEL], [Vector2(200, 120), -90.0, 9.0, C_MID],
]

var _landscape := false
var _design := Vector2(390, 844)   # design canvas the layout numbers refer to
var _k := 1.0                       # design px -> screen px
var _origin := Vector2.ZERO         # screen position of the design canvas' top-left
var _vp := Vector2.ZERO

var _logo: Node2D
var _logo_scale := 1.0
var _shine_mat: ShaderMaterial
var _exiting := false

var _w2_letters: Array[Label] = []
var _w2_widths: Array[float] = []
var _w2_center := Vector2.ZERO
var _w2_size := 13.0
var _line_l: ColorRect
var _line_r: ColorRect


# --------------------------------------------------------------------------- setup

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP if skip_on_tap else Control.MOUSE_FILTER_IGNORE
	if next_scene_path != "":
		ResourceLoader.load_threaded_request(next_scene_path)

	_vp = get_viewport_rect().size
	_landscape = _vp.x > _vp.y
	_design = Vector2(844, 390) if _landscape else Vector2(390, 844)
	_k = minf(_vp.x / _design.x, _vp.y / _design.y)
	_origin = (_vp - _design * _k) * 0.5

	_build_background()
	_build_floaters()
	var lay := _layout()
	_build_burst(lay["logo_center"])
	_build_logo(lay["logo_center"], lay["logo_h"])
	_build_wordmark(lay["wm_center_x"], lay["w1_top"], lay["w1_size"], lay["w2_top"], lay["w2_size"])
	_build_overlays()

	get_tree().create_timer(hold_time).timeout.connect(_begin_exit)


func _gui_input(event: InputEvent) -> void:
	if skip_on_tap and (event is InputEventScreenTouch or event is InputEventMouseButton) and event.is_pressed():
		hold_time = 0.0
		_begin_exit()


## Design position -> screen position.
func _S(p: Vector2) -> Vector2:
	return _origin + p * _k


func _layout() -> Dictionary:
	if not _landscape:
		return {
			"logo_center": Vector2(195, 290), "logo_h": 320.0,
			"wm_center_x": 195.0, "w1_top": 494.0, "w1_size": 46.0,
			"w2_top": 554.0, "w2_size": 13.0,
		}
	# Landscape: logo on the left, wordmark on the right, the pair centred.
	var w1 := _measure("ALPACA", 52.0, 800) + 5.0
	var w2 := _measure("SOLUTIONS", 14.0, 500) + 8.0 * 0.55 * 14.0 + 2.0 * (12.0 + 26.0)
	var wm_w := maxf(w1, w2)
	var total := 160.0 + 44.0 + wm_w
	var x0 := (844.0 - total) * 0.5
	var cy := 167.0
	return {
		"logo_center": Vector2(x0 + 80.0, cy), "logo_h": 250.0,
		"wm_center_x": x0 + 160.0 + 44.0 + wm_w * 0.5, "w1_top": cy - 40.0, "w1_size": 52.0,
		"w2_top": cy - 40.0 + 52.0 + 14.0, "w2_size": 14.0,
	}


func _font(weight: int) -> FontVariation:
	var fv := FontVariation.new()
	fv.base_font = FONT
	fv.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return fv


## Width in design px.
func _measure(text: String, size: float, weight: int) -> float:
	return _font(weight).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(size)).x


func _tri(size: float, col: Color) -> Polygon2D:
	var p := Polygon2D.new()
	var h := size * 0.5
	p.polygon = PackedVector2Array([Vector2(0, -h), Vector2(h, h), Vector2(-h, h)])
	p.color = col
	return p


# ------------------------------------------------------------------- background

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var polys := Node2D.new()
	polys.scale = _vp / _design      # stretch to fill like "slice"
	polys.modulate.a = 0.0
	add_child(polys)
	var shapes: Array
	if _landscape:
		shapes = [
			[[0, 0, 300, 0, 0, 220], "#F3EEFC"], [[844, 0, 844, 240, 560, 0], "#FFF5D6"],
			[[0, 220, 160, 300, 0, 390], "#FFF3CF"], [[0, 390, 160, 300, 330, 390], "#FAF7FF"],
			[[844, 390, 520, 390, 844, 240], "#F1ECFB"], [[300, 0, 430, 0, 360, 70], "#FFF9E8"],
		]
	else:
		shapes = [
			[[0, 0, 230, 0, 0, 270], "#F3EEFC"], [[390, 0, 390, 310, 240, 0], "#FFF5D6"],
			[[0, 270, 130, 430, 0, 570], "#FAF7FF"], [[390, 310, 270, 460, 390, 540], "#FFF9E8"],
			[[0, 844, 0, 570, 250, 844], "#FFF3CF"], [[390, 844, 140, 844, 390, 540], "#F1ECFB"],
		]
	for s in shapes:
		var pts := PackedVector2Array()
		var c: Array = s[0]
		for i in range(0, c.size(), 2):
			pts.append(Vector2(c[i], c[i + 1]))
		var p := Polygon2D.new()
		p.polygon = pts
		p.color = Color(s[1])
		polys.add_child(p)
	var t := create_tween()
	t.tween_property(polys, "modulate:a", 1.0, 1.6).set_delay(0.1).set_ease(Tween.EASE_OUT)


func _build_floaters() -> void:
	var data: Array
	if _landscape:
		data = [[0.06, 0.18, 16, C_YEL, 7.0], [0.30, 0.08, 12, C_MID, 8.0], [0.92, 0.22, 20, C_YEL, 9.0],
				[0.10, 0.74, 13, C_DARK, 6.5], [0.64, 0.84, 11, C_MID, 8.5], [0.88, 0.70, 16, C_YEL, 7.5]]
	else:
		data = [[0.12, 0.15, 18, C_YEL, 7.0], [0.82, 0.11, 14, C_MID, 8.0], [0.86, 0.47, 22, C_YEL, 9.0],
				[0.07, 0.55, 15, C_DARK, 6.5], [0.18, 0.80, 12, C_MID, 8.5], [0.80, 0.77, 18, C_YEL, 7.5]]
	for d in data:
		var f := _tri(float(d[2]) * _k, d[3])
		f.position = Vector2(d[0] * _vp.x, d[1] * _vp.y)
		f.modulate.a = 0.0
		add_child(f)
		create_tween().tween_property(f, "modulate:a", 0.5, 1.2).set_delay(2.3)
		var half: float = float(d[4])
		var drift := create_tween().set_loops().set_parallel(true)
		drift.tween_property(f, "position:y", f.position.y - 26.0 * _k, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		drift.tween_property(f, "rotation_degrees", 50.0, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		drift.chain().tween_property(f, "position:y", f.position.y, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		drift.tween_property(f, "rotation_degrees", 0.0, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		drift.pause()
		get_tree().create_timer(2.3).timeout.connect(drift.play)


# ------------------------------------------------------------- impact effects

class Ring extends Node2D:
	var col := Color.WHITE
	var radius := 60.0
	var width := 3.0
	func _draw() -> void:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, col, width, true)


func _build_burst(center: Vector2) -> void:
	var c := _S(center)
	for r in [[C_YEL, 3.0, 1.55], [C_LAV, 2.0, 1.72]]:
		var ring := Ring.new()
		ring.col = r[0]
		ring.radius = 60.0 * _k
		ring.width = float(r[1]) * _k
		ring.position = c
		ring.scale = Vector2.ONE * 0.2
		ring.modulate.a = 0.0
		add_child(ring)
		var t := create_tween().set_parallel(true)
		t.tween_callback(func(): ring.modulate.a = 0.95).set_delay(r[2])
		t.tween_property(ring, "scale", Vector2.ONE * 5.5, 1.2).set_delay(r[2]).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
		t.tween_property(ring, "modulate:a", 0.0, 1.2).set_delay(r[2]).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)

	for s in SHARDS:
		var sh := _tri(float(s[2]) * _k, s[3])
		sh.position = c
		sh.scale = Vector2.ONE * 0.2
		sh.modulate.a = 0.0
		add_child(sh)
		var t := create_tween().set_parallel(true)
		t.tween_callback(func(): sh.modulate.a = 1.0).set_delay(1.55)
		t.tween_property(sh, "position", c + Vector2(s[0]) * _k, 1.4).set_delay(1.55).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		t.tween_property(sh, "rotation_degrees", float(s[1]), 1.4).set_delay(1.55).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		t.tween_property(sh, "scale", Vector2.ONE, 1.4).set_delay(1.55).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		t.tween_property(sh, "modulate:a", 0.0, 0.5).set_delay(1.55 + 0.9)


# ------------------------------------------------------------------------ logo

func _build_logo(center: Vector2, height: float) -> void:
	_logo = Node2D.new()
	_logo.position = _S(center)
	_logo_scale = height * _k / ART_H
	_logo.scale = Vector2.ONE * _logo_scale
	add_child(_logo)

	_shine_mat = ShaderMaterial.new()
	_shine_mat.shader = SHINE_SHADER
	_shine_mat.set_shader_parameter("band", 26.0 * _k * height / 320.0)
	_shine_mat.set_shader_parameter("skew", 0.32)
	_shine_mat.set_shader_parameter("strength", 0.75)
	_shine_mat.set_shader_parameter("shine_pos", -100000.0)

	for f in FACETS:
		var pts: Array = f[0]
		var cen := Vector2.ZERO
		for p in pts:
			cen += p
		cen /= pts.size()
		var local := PackedVector2Array()
		for p in pts:
			local.append(p - cen)
		var poly := Polygon2D.new()
		poly.polygon = local
		poly.color = f[1]
		poly.material = _shine_mat
		var final_pos: Vector2 = cen - ART_CENTER
		poly.position = final_pos + Vector2(f[2])
		poly.rotation_degrees = f[3]
		poly.scale = Vector2.ONE * 0.3
		poly.modulate.a = 0.0
		_logo.add_child(poly)

		var delay: float = f[4]
		var t := create_tween().set_parallel(true)
		t.tween_property(poly, "position", final_pos, 1.15).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(poly, "rotation_degrees", 0.0, 1.15).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(poly, "scale", Vector2.ONE, 1.15).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(poly, "modulate:a", 1.0, 0.4).set_delay(delay)

	# Impact pop, then a gentle bob.
	var pop := create_tween()
	pop.tween_property(_logo, "scale", Vector2.ONE * _logo_scale * 1.09, 0.22).set_delay(1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pop.tween_property(_logo, "scale", Vector2.ONE * _logo_scale, 0.33).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var y0 := _logo.position.y
	var bob := create_tween().set_loops()
	bob.tween_property(_logo, "position:y", y0 - 8.0 * _k, 2.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(_logo, "position:y", y0, 2.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.pause()
	get_tree().create_timer(2.3).timeout.connect(bob.play)

	get_tree().create_timer(1.75).timeout.connect(_shine_loop)


func _shine_loop() -> void:
	while is_inside_tree() and not _exiting:
		var skew: float = _shine_mat.get_shader_parameter("skew")
		var band: float = _shine_mat.get_shader_parameter("band")
		var lo := INF
		var hi := -INF
		for corner in [ART_MIN, Vector2(ART_MAX.x, ART_MIN.y), Vector2(ART_MIN.x, ART_MAX.y), ART_MAX]:
			var g: Vector2 = _logo.to_global(corner - ART_CENTER)
			var d := g.x + g.y * skew
			lo = minf(lo, d)
			hi = maxf(hi, d)
		var t := create_tween()
		t.tween_method(func(v: float): _shine_mat.set_shader_parameter("shine_pos", v),
				lo - band, hi + band, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await get_tree().create_timer(5.0).timeout


# -------------------------------------------------------------------- wordmark

func _make_letter(ch: String, fv: FontVariation, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = ch
	l.add_theme_font_override("font", fv)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sz := fv.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	l.size = Vector2(sz.x, fv.get_height(size))
	l.pivot_offset = l.size * 0.5
	l.modulate.a = 0.0
	add_child(l)
	return l


func _build_wordmark(cx: float, w1_top: float, w1_size: float, w2_top: float, w2_size: float) -> void:
	# ALPACA – letters pop up one by one.
	var fv800 := _font(800)
	var px := int(round(w1_size * _k))
	var gap := (1.0 + 0.01 * w1_size) * _k
	var letters: Array[Label] = []
	var total := 0.0
	for ch in "ALPACA":
		var l := _make_letter(ch, fv800, px, C_DARK)
		letters.append(l)
		total += l.size.x
	total += gap * (letters.size() - 1)
	var x := _S(Vector2(cx, 0)).x - total * 0.5
	var line_h := fv800.get_height(px)
	var top := _S(Vector2(0, w1_top)).y - (line_h - px) * 0.5
	for i in letters.size():
		var l := letters[i]
		var final_pos := Vector2(x, top)
		x += l.size.x + gap
		l.position = final_pos + Vector2(0, 30.0 * _k)
		l.rotation_degrees = 10.0
		l.scale = Vector2.ONE * 0.5
		var d := 2.0 + 0.06 * i
		var t := create_tween().set_parallel(true)
		t.tween_property(l, "position", final_pos, 0.75).set_delay(d).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(l, "rotation_degrees", 0.0, 0.75).set_delay(d).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(l, "scale", Vector2.ONE, 0.75).set_delay(d).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(l, "modulate:a", 1.0, 0.3).set_delay(d)

	# SOLUTIONS – tracking opens up, with a yellow line on each side.
	var fv500 := _font(500)
	_w2_size = w2_size * _k
	var px2 := int(round(_w2_size))
	for ch in "SOLUTIONS":
		var l := _make_letter(ch, fv500, px2, C_MID)
		_w2_letters.append(l)
		_w2_widths.append(l.size.x)
	var lh2 := fv500.get_height(px2)
	_w2_center = Vector2(_S(Vector2(cx, 0)).x, _S(Vector2(0, w2_top)).y + px2 * 0.5)
	for l in _w2_letters:
		l.position.y = _w2_center.y - lh2 * 0.5

	_line_l = ColorRect.new()
	_line_r = ColorRect.new()
	for ln in [_line_l, _line_r]:
		ln.color = C_YEL
		ln.size = Vector2(26, 2) * _k
		ln.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ln.scale = Vector2(0, 1)
		add_child(ln)
	_line_l.pivot_offset = Vector2(_line_l.size.x, 0)
	_line_r.pivot_offset = Vector2.ZERO
	_layout_w2(0.0)

	var t2 := create_tween().set_parallel(true)
	t2.tween_method(_layout_w2, 0.0, 1.0, 1.3).set_delay(2.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	for l in _w2_letters:
		t2.tween_property(l, "modulate:a", 1.0, 0.9).set_delay(2.5)
	for ln in [_line_l, _line_r]:
		t2.tween_property(ln, "scale:x", 1.0, 0.7).set_delay(2.75).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


## p: 0 = letters tight, 1 = letter-spacing 0.55em. Keeps the word centred.
func _layout_w2(p: float) -> void:
	var spacing := 0.55 * _w2_size * p
	var width := 0.0
	for w in _w2_widths:
		width += w
	width += spacing * (_w2_widths.size() - 1)
	var x := _w2_center.x - width * 0.5
	for i in _w2_letters.size():
		_w2_letters[i].position.x = x
		x += _w2_widths[i] + spacing
	var gap := 12.0 * _k + spacing * 0.5
	_line_l.position = Vector2(_w2_center.x - width * 0.5 - gap - _line_l.size.x, _w2_center.y - _line_l.size.y * 0.5)
	_line_r.position = Vector2(_w2_center.x + width * 0.5 + gap, _w2_center.y - _line_r.size.y * 0.5)


# ---------------------------------------------------------------- flash + exit

func _build_overlays() -> void:
	var flash := ColorRect.new()
	flash.color = Color.WHITE
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.modulate.a = 0.0
	add_child(flash)
	var t := create_tween()
	t.tween_property(flash, "modulate:a", 0.85, 0.1).set_delay(1.5)
	t.tween_property(flash, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_OUT)


func _begin_exit() -> void:
	if _exiting:
		return
	_exiting = true

	# Wait for the next scene if it is still loading in the background.
	var packed: PackedScene = null
	if next_scene_path != "":
		while ResourceLoader.load_threaded_get_status(next_scene_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
		packed = ResourceLoader.load_threaded_get(next_scene_path) as PackedScene

	# Put the game under the splash, then fade the splash away so the first game
	# frame appears directly – no blank frames between logo and game.
	if packed:
		var game := packed.instantiate()
		var root := get_tree().root
		root.add_child(game)
		root.move_child(game, get_index())
		get_tree().current_scene = game
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, fade_time).set_ease(Tween.EASE_IN)
	await t.finished
	finished.emit()
	queue_free()

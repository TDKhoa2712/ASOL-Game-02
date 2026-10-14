# Animated guide hand for the onboarding (RST-028). The fingertip is the
# pivot, so a press tilts and squashes the hand onto the cell like a real
# finger; strokes press down, slide through the cells, then lift.
extends TextureRect

const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

const SVG := '<svg width="56" height="64" viewBox="0 0 56 64" xmlns="http://www.w3.org/2000/svg"><path d="M20 4 c3 0 5 2 5 5 v19 l3 -1 c2.5 -0.6 5 1 5.5 3.5 l0.3 1 l2.4 -0.6 c2.6 -0.6 5 1 5.6 3.6 l0.2 0.8 l1.6 -0.4 c2.8 -0.6 5.4 1.4 5.8 4.2 l1.6 11.4 C55.6 60 50 64 43 64 H29 c-4.6 0 -8.8 -2.4 -11.1 -6.3 L6.6 39 c-1.5 -2.5 -0.8 -5.8 1.6 -7.4 c2.2 -1.4 5.1 -1 6.8 1 L15 34 V9 c0 -3 2 -5 5 -5 z" fill="#FFFFFF" stroke="#7A4A2A" stroke-width="3" stroke-linejoin="round"/></svg>'
const TIP := Vector2(20.0 / 56.0, 4.0 / 64.0)  # fingertip inside the texture
const LIFT := Vector2(22, -40)                 # hovering offset before a press
const LIFT_TILT := -0.16                       # radians, leaning back while hovering
const PRESS_SCALE := Vector2(0.9, 0.9)
const PRESS_SEC := 0.24
const QUICK_SEC := 0.13
const SLIDE_SEC_PER_CELL := 0.34

var _tween: Tween = null

func _init() -> void:
	name = "Hand"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 5
	var img := Image.new()
	img.load_svg_from_string(SVG, 3.2)
	texture = ImageTexture.create_from_image(img)
	size = texture.get_size()
	pivot_offset = size * TIP
	visible = false

func stop() -> void:
	if _tween != null: _tween.kill()
	_tween = null
	visible = false

# Presses `presses` times on point; on_press runs at each touch-down.
func play_tap(point: Vector2, presses: int, on_press: Callable = Callable()) -> void:
	stop()
	visible = true
	if not LayoutTokens.motion_enabled:
		_pose(point, 0.0, Vector2.ONE, 1.0)
		return
	_pose(point + LIFT, LIFT_TILT, Vector2.ONE, 0.0)
	_tween = create_tween().set_loops()
	_tween.tween_callback(_pose.bind(point + LIFT, LIFT_TILT, Vector2.ONE, 0.0))
	_tween.tween_property(self, "modulate:a", 1.0, 0.2)
	for i in presses:
		var sec := PRESS_SEC if i == 0 else QUICK_SEC
		_move(point, 0.0, PRESS_SCALE, sec, Tween.EASE_IN)
		if on_press.is_valid(): _tween.tween_callback(on_press)
		var up := point + LIFT * (0.35 if i < presses - 1 else 1.0)
		_move(up, LIFT_TILT * (0.4 if i < presses - 1 else 1.0), Vector2.ONE, QUICK_SEC if i < presses - 1 else PRESS_SEC, Tween.EASE_OUT)
	_tween.tween_interval(0.45)
	_tween.tween_property(self, "modulate:a", 0.0, 0.22)
	_tween.tween_interval(0.35)

# Strokes: each path is an Array of points (the cell centers in order).
# on_pass(path_index, point_index) runs as the finger reaches each cell;
# on_reset runs before every loop so the caller can clear demo marks.
func play_strokes(paths: Array, on_pass: Callable, on_reset: Callable) -> void:
	stop()
	if paths.is_empty():
		return
	visible = true
	if not LayoutTokens.motion_enabled:
		_pose(paths[0][0], 0.0, Vector2.ONE, 1.0)
		return
	_tween = create_tween().set_loops()
	_tween.tween_callback(on_reset)
	for p in paths.size():
		var points: Array = paths[p]
		_tween.tween_callback(_pose.bind(points[0] + LIFT, LIFT_TILT, Vector2.ONE, 0.0))
		_tween.tween_property(self, "modulate:a", 1.0, 0.18)
		_move(points[0], 0.0, PRESS_SCALE, PRESS_SEC, Tween.EASE_IN)
		_tween.tween_callback(on_pass.bind(p, 0))
		var reached := [0]
		var slide := func(v: float) -> void:
			var at := _along(points, v)
			position = at - pivot_offset
			var idx := int(floor(v * (points.size() - 1) + 0.5))
			if idx > reached[0]:
				reached[0] = idx
				on_pass.call(p, idx)
		_tween.tween_callback(func() -> void: reached[0] = 0)
		_tween.tween_method(slide, 0.0, 1.0, SLIDE_SEC_PER_CELL * maxf(1.0, points.size() - 1)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_move(points[-1] + LIFT, LIFT_TILT, Vector2.ONE, PRESS_SEC, Tween.EASE_OUT)
		_tween.tween_property(self, "modulate:a", 0.0, 0.18)
	_tween.tween_interval(0.6)

func _move(point: Vector2, tilt: float, sc: Vector2, sec: float, ease: int) -> void:
	_tween.tween_property(self, "position", point - pivot_offset, sec).set_trans(Tween.TRANS_SINE).set_ease(ease)
	_tween.parallel().tween_property(self, "rotation", tilt, sec).set_trans(Tween.TRANS_SINE).set_ease(ease)
	_tween.parallel().tween_property(self, "scale", sc, sec).set_trans(Tween.TRANS_BACK if ease == Tween.EASE_OUT else Tween.TRANS_SINE).set_ease(ease)

func _pose(point: Vector2, tilt: float, sc: Vector2, alpha: float) -> void:
	position = point - pivot_offset
	rotation = tilt
	scale = sc
	modulate.a = alpha

# Fingertip position at progress v (0..1) along the polyline.
static func _along(points: Array, v: float) -> Vector2:
	if points.size() == 1:
		return points[0]
	var f := v * (points.size() - 1)
	var i := mini(int(floor(f)), points.size() - 2)
	return (points[i] as Vector2).lerp(points[i + 1], f - i)

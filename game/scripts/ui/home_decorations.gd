# home_decorations.gd — Floating candy balls and twinkle stars for home screen.
extends Control

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	var balls := [
		[0.08, 0.35, 72.0, Palette.CANDY_ORANGE, 0.0],
		[0.90, 0.40, 58.0, Palette.CANDY_BLUE, 0.6],
		[0.13, 0.62, 52.0, Palette.CANDY_GREEN, 1.2],
		[0.87, 0.64, 66.0, Palette.CANDY_YELLOW, 0.9],
	]
	for b in balls:
		_add_ball(b[0], b[1], b[2], b[3], b[4])
	var stars := [
		[0.15, 0.12, 16.0, Palette.TWINKLE_GOLD, 0.0],
		[0.80, 0.24, 20.0, Palette.TWINKLE_GOLD, 0.8],
		[0.72, 0.10, 14.0, Palette.TWINKLE_BLUE, 1.3],
	]
	for s in stars:
		_add_star(s[0], s[1], s[2], s[3], s[4])

func _add_ball(rx: float, ry: float, s: float, col: Color, delay: float) -> void:
	var ball := _CandyBall.new(s, col)
	ball.anchor_left = rx; ball.anchor_top = ry
	ball.offset_left = -s * 0.5; ball.offset_top = -s * 0.5
	ball.offset_right = ball.offset_left + s; ball.offset_bottom = ball.offset_top + s
	add_child(ball)
	if not LayoutTokens.motion_enabled: return
	var base := ball.offset_top
	var tw := ball.create_tween().set_loops()
	tw.tween_interval(delay)
	tw.tween_property(ball, "offset_top", base - 12.0, 1.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(ball, "offset_top", base, 1.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _add_star(rx: float, ry: float, s: float, col: Color, delay: float) -> void:
	var star := _TwinkleStar.new(s, col)
	star.anchor_left = rx; star.anchor_top = ry
	star.offset_left = -s * 0.5; star.offset_top = -s * 0.5
	star.offset_right = star.offset_left + s; star.offset_bottom = star.offset_top + s
	add_child(star)
	if not LayoutTokens.motion_enabled: return
	star.scale = Vector2(0.4, 0.4); star.modulate.a = 0.3
	var tw := star.create_tween().set_loops()
	tw.tween_interval(delay)
	tw.tween_property(star, "scale", Vector2(1.1, 1.1), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(star, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(star, "rotation", deg_to_rad(45), 0.9).set_trans(Tween.TRANS_SINE)
	tw.tween_property(star, "scale", Vector2(0.4, 0.4), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(star, "modulate:a", 0.3, 0.9).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(star, "rotation", 0.0, 0.9).set_trans(Tween.TRANS_SINE)

class _CandyBall extends Control:
	var _s: float; var _c: Color
	func _init(s: float, c: Color) -> void:
		_s = s; _c = c
		custom_minimum_size = Vector2(s, s)
		pivot_offset = Vector2(s * 0.5, s * 0.5)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var r := _s * 0.5
		var ctr := Vector2(r, r)
		draw_circle(ctr + Vector2(0, 6), r, Color(0.35, 0.20, 0.06, 0.18))
		draw_circle(ctr, r, _c)
		draw_circle(ctr + Vector2(0, r * 0.18), r * 0.88, _c.darkened(0.18))
		draw_circle(ctr + Vector2(-r * 0.25, -r * 0.28), r * 0.40, Color(1, 1, 1, 0.55))

class _TwinkleStar extends Control:
	var _s: float; var _c: Color
	func _init(s: float, c: Color) -> void:
		_s = s; _c = c
		custom_minimum_size = Vector2(s, s)
		pivot_offset = Vector2(s * 0.5, s * 0.5)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var r := _s * 0.5; var ctr := Vector2(r, r)
		var pts: PackedVector2Array = [
			ctr + Vector2(0, -r), ctr + Vector2(r * 0.24, -r * 0.24),
			ctr + Vector2(r, 0), ctr + Vector2(r * 0.24, r * 0.24),
			ctr + Vector2(0, r), ctr + Vector2(-r * 0.24, r * 0.24),
			ctr + Vector2(-r, 0), ctr + Vector2(-r * 0.24, -r * 0.24),
		]
		draw_colored_polygon(pts, _c)

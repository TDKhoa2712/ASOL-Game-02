# glow_burst.gd — Soft radial glow plus eight spark streaks that shoot outward.
# `glow` (0..1+) scales the halo; `burst` (0..1) drives the streaks; tween both from a screen timeline.
extends Control

const SPARKS := 8
const GLOW_INNER := Color(1.0, 0.85, 0.29, 0.85)
const GLOW_OUTER := Color(1.0, 0.54, 0.12, 0.0)
const SPARK_COLOR := Color("#FFD84A")

var radius := 300.0
var glow := 0.0:
	set(v): glow = v; queue_redraw()
var burst := 0.0:
	set(v): burst = v; queue_redraw()

func _init(p_radius: float = 300.0) -> void:
	radius = p_radius
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func spark_count() -> int:
	return SPARKS

func _draw() -> void:
	if glow > 0.0:
		var steps := 14
		for i in steps:
			var t := 1.0 - float(i) / steps
			var c := GLOW_OUTER.lerp(GLOW_INNER, 1.0 - t)
			c.a *= clampf(glow, 0.0, 1.0)
			draw_circle(Vector2.ZERO, radius * glow * t, Color(c, c.a / steps * 3.0))
	if burst <= 0.0 or burst >= 1.0:
		return
	var alpha := burst / 0.2 if burst < 0.2 else 1.0 - (burst - 0.2) / 0.8
	var dist := radius * 1.1 * ease(burst, 0.4)
	var length := radius * 0.16 * (0.4 + 0.6 * burst)
	for i in SPARKS:
		var dir := Vector2.UP.rotated(TAU * i / SPARKS)
		var from := dir * dist
		draw_line(from, from + dir * length, Color(SPARK_COLOR, alpha), radius * 0.04, true)

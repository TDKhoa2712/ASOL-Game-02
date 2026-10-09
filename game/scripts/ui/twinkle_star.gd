# twinkle_star.gd — Sparkle star decoration for result screens.
extends Control

var _sz: float
var _col: Color

func _init(sz: float, col: Color) -> void:
	_sz = sz; _col = col
	custom_minimum_size = Vector2(sz, sz)
	size = Vector2(sz, sz)
	pivot_offset = Vector2(sz * 0.5, sz * 0.5)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var c := _sz * 0.5
	var points: PackedVector2Array = []
	for i in range(8):
		var angle: float = i * TAU / 8.0 - TAU / 4.0
		var r: float = c if i % 2 == 0 else c * 0.38
		points.append(Vector2(c + cos(angle) * r, c + sin(angle) * r))
	draw_colored_polygon(points, _col)

extends Control

func _ready() -> void:
	custom_minimum_size = Vector2(40, 40)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var gear_color := Color("#73564F")
	var r_outer := 15.0
	var r_inner := 9.0
	var hole_r := 5.0
	var teeth := 8
	var points := PackedVector2Array()
	for i in range(teeth):
		var a1 := i * TAU / teeth - 0.16
		var a2 := i * TAU / teeth + 0.16
		var a3 := (i + 0.5) * TAU / teeth - 0.16
		var a4 := (i + 0.5) * TAU / teeth + 0.16
		points.append(center + Vector2(cos(a1), sin(a1)) * r_outer)
		points.append(center + Vector2(cos(a2), sin(a2)) * r_outer)
		points.append(center + Vector2(cos(a3), sin(a3)) * r_inner)
		points.append(center + Vector2(cos(a4), sin(a4)) * r_inner)
	draw_colored_polygon(points, gear_color)
	draw_circle(center, hole_r, Color("#FFFDF9"))

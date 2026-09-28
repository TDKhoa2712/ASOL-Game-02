extends Control

func _ready() -> void:
	custom_minimum_size = Vector2(32, 32)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	# Draw light golden/cream feather / leaf
	var gold := Color("#E6B86A")
	var white_soft := Color("#FFF5E0")
	# Central spine
	draw_line(center + Vector2(-6, 10), center + Vector2(8, -10), gold, 2.5, true)
	# Soft wings/vanes
	draw_circle(center + Vector2(2, -4), 7.0, white_soft)
	draw_arc(center + Vector2(2, -4), 7.0, 0, TAU, 16, gold, 1.8, true)
	draw_circle(center + Vector2(-2, 4), 6.0, white_soft)
	draw_arc(center + Vector2(-2, 4), 6.0, 0, TAU, 16, gold, 1.8, true)

extends Control

func _ready() -> void:
	custom_minimum_size = Vector2(80, 80)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var radius := 22.0
	
	# Background style
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color("#FFFDF9")
	bg_style.border_color = Color("#8CBF4D") # Fresh pistachio green border
	bg_style.set_border_width_all(3)
	bg_style.set_corner_radius_all(int(radius))
	bg_style.shadow_color = Color(0.3, 0.4, 0.2, 0.15)
	bg_style.shadow_size = 6
	bg_style.shadow_offset = Vector2(0, 3)
	draw_style_box(bg_style, rect)
	
	# Inner cute cat
	var center := rect.get_center() + Vector2(0, 6)
	
	# Left ear
	var ear_left := PackedVector2Array([
		center + Vector2(-24, -14),
		center + Vector2(-16, -30),
		center + Vector2(-6, -18)
	])
	draw_colored_polygon(ear_left, Color("#55494D")) # Calico dark patch
	
	# Right ear
	var ear_right := PackedVector2Array([
		center + Vector2(6, -18),
		center + Vector2(16, -30),
		center + Vector2(24, -14)
	])
	draw_colored_polygon(ear_right, Color("#EE9E54")) # Ginger patch
	
	# Head / Body chubby shape
	draw_circle(center + Vector2(0, 2), 22.0, Color("#FFFFFF"))
	
	# Patches on body
	draw_circle(center + Vector2(-12, -4), 10.0, Color("#55494D"))
	draw_circle(center + Vector2(14, -6), 9.0, Color("#EE9E54"))
	
	# Sleepy eyes
	draw_arc(center + Vector2(-8, 3), 4.0, PI * 0.15, PI * 0.85, 8, Color("#3B3435"), 2.2, true)
	draw_arc(center + Vector2(8, 3), 4.0, PI * 0.15, PI * 0.85, 8, Color("#3B3435"), 2.2, true)
	
	# Little nose & mouth
	draw_circle(center + Vector2(0, 7), 1.8, Color("#F58CA8"))
	
	# Rosy cheeks
	draw_circle(center + Vector2(-14, 8), 3.5, Color(0.98, 0.6, 0.65, 0.55))
	draw_circle(center + Vector2(14, 8), 3.5, Color(0.98, 0.6, 0.65, 0.55))
	
	# Cute little paw waving on the right
	draw_circle(center + Vector2(16, 12), 5.5, Color("#FFFFFF"))
	draw_circle(center + Vector2(16, 11), 3.0, Color("#F58CA8"))
	for offset in [Vector2(-3, -2), Vector2(0, -3.5), Vector2(3, -2)]:
		draw_circle(center + Vector2(16, 11) + offset, 1.2, Color("#F58CA8"))

extends Control

func _ready() -> void:
	custom_minimum_size = Vector2(480, 250)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var brown := Color("#7F5035")
	var cat_blue := Color("#778FED")
	var tail_orange := Color("#EE8822")
	var font := ThemeDB.fallback_font
	
	if font == null:
		return
		
	var font_size := 98
	
	# Row 1: MEOW
	var r1_y := center.y - 15.0
	var r1_x := center.x - 195.0
	
	# 'M' 'E'
	draw_string(font, Vector2(r1_x, r1_y), "ME", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, brown)
	
	# 'O' as Cat head in blue
	var cat_head_center := Vector2(r1_x + 185, r1_y - 34)
	var cat_r := 38.0
	draw_circle(cat_head_center, cat_r, cat_blue)
	
	# Triangular Ears
	var ear_l := PackedVector2Array([
		cat_head_center + Vector2(-28, -18),
		cat_head_center + Vector2(-30, -56),
		cat_head_center + Vector2(-8, -34)
	])
	draw_colored_polygon(ear_l, cat_blue)
	var ear_r := PackedVector2Array([
		cat_head_center + Vector2(8, -34),
		cat_head_center + Vector2(30, -56),
		cat_head_center + Vector2(28, -18)
	])
	draw_colored_polygon(ear_r, cat_blue)
	
	# Inner ear highlights
	draw_colored_polygon(PackedVector2Array([
		cat_head_center + Vector2(-24, -22),
		cat_head_center + Vector2(-26, -46),
		cat_head_center + Vector2(-12, -32)
	]), Color("#A4B8FB"))
	draw_colored_polygon(PackedVector2Array([
		cat_head_center + Vector2(12, -32),
		cat_head_center + Vector2(26, -46),
		cat_head_center + Vector2(24, -22)
	]), Color("#A4B8FB"))
	
	# Hollow center for 'O'
	draw_circle(cat_head_center, 16.0, Color("#FAF6F0"))
	
	# 'W'
	draw_string(font, Vector2(r1_x + 260, r1_y), "W", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, brown)
	
	# Row 2: DOKU
	var r2_y := center.y + 95.0
	var r2_x := center.x - 195.0
	
	# 'D'
	draw_string(font, Vector2(r2_x, r2_y), "D", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, brown)
	
	# 'O' with orange ring and cute curly cat tail
	var tail_o_center := Vector2(r2_x + 115, r2_y - 34)
	draw_arc(tail_o_center, 28.0, 0, TAU, 32, tail_orange, 18.0, true)
	
	# Curly tail dropping down and curving right
	var p0 := tail_o_center + Vector2(10, 26)
	var p1 := tail_o_center + Vector2(22, 58)
	var p2 := tail_o_center + Vector2(48, 62)
	var p3 := tail_o_center + Vector2(58, 44)
	draw_polyline(PackedVector2Array([p0, p1, p2, p3]), tail_orange, 16.0, true)
	# Tail tip cap
	draw_circle(p3, 8.0, tail_orange)
	# White stripes on tail
	draw_line(p1 + Vector2(2, -2), p1 + Vector2(12, 1), Color("#FEE5CF"), 4.0)
	draw_line(p2 + Vector2(-6, -2), p2 + Vector2(2, -8), Color("#FEE5CF"), 4.0)
	
	# 'KU'
	draw_string(font, Vector2(r2_x + 208, r2_y), "KU", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, brown)

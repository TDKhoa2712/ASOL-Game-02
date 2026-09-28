extends Control

@export var timer_text: String = "23:50:22"

func _ready() -> void:
	custom_minimum_size = Vector2(170, 160)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var center_x := 80.0
	var base_y := 98.0
	
	# 1. Golden arch over the podium
	var arch_center := Vector2(center_x, base_y - 28)
	draw_arc(arch_center, 54.0, PI * 1.08, PI * 1.92, 32, Color("#EEA850"), 9.0, true)
	
	# 2. Podium blocks
	# Block 2 (Left) - Purple
	var b2_rect := Rect2(center_x - 52, base_y - 42, 34, 42)
	var b2_style := StyleBoxFlat.new()
	b2_style.bg_color = Color("#8F88D6")
	b2_style.corner_radius_top_left = 8
	b2_style.corner_radius_top_right = 8
	b2_style.shadow_color = Color(0, 0, 0, 0.1)
	b2_style.shadow_size = 4
	b2_style.shadow_offset = Vector2(0, 2)
	draw_style_box(b2_style, b2_rect)
	
	# Block 3 (Right) - Coral Orange
	var b3_rect := Rect2(center_x + 18, base_y - 34, 34, 34)
	var b3_style := StyleBoxFlat.new()
	b3_style.bg_color = Color("#E88B42")
	b3_style.corner_radius_top_left = 8
	b3_style.corner_radius_top_right = 8
	b3_style.shadow_color = Color(0, 0, 0, 0.1)
	b3_style.shadow_size = 4
	b3_style.shadow_offset = Vector2(0, 2)
	draw_style_box(b3_style, b3_rect)

	# Block 1 (Center - highest) - Bright Golden Yellow
	var b1_rect := Rect2(center_x - 19, base_y - 58, 38, 58)
	var b1_style := StyleBoxFlat.new()
	b1_style.bg_color = Color("#FFB81E")
	b1_style.corner_radius_top_left = 10
	b1_style.corner_radius_top_right = 10
	b1_style.shadow_color = Color(0, 0, 0, 0.15)
	b1_style.shadow_size = 6
	b1_style.shadow_offset = Vector2(0, 3)
	draw_style_box(b1_style, b1_rect)
	
	# Sparkle star on Block 1
	var star := Vector2(center_x - 11, base_y - 48)
	draw_circle(star, 3.0, Color("#FFFFFF"))
	draw_line(star + Vector2(-6, 0), star + Vector2(6, 0), Color("#FFFFFF"), 1.8)
	draw_line(star + Vector2(0, -6), star + Vector2(0, 6), Color("#FFFFFF"), 1.8)
	
	# Numbers 2, 1, 3
	var font := ThemeDB.fallback_font
	if font != null:
		draw_string(font, Vector2(center_x - 42, base_y - 12), "2", HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color("#FFFFFF"))
		draw_string(font, Vector2(center_x - 8, base_y - 20), "1", HORIZONTAL_ALIGNMENT_CENTER, -1, 30, Color("#FFFFFF"))
		draw_string(font, Vector2(center_x + 28, base_y - 10), "3", HORIZONTAL_ALIGNMENT_CENTER, -1, 22, Color("#FFFFFF"))

	# 3. Dark Countdown Pill below the podium
	var pill_rect := Rect2(center_x - 70, base_y + 4, 140, 38)
	var pill_style := StyleBoxFlat.new()
	pill_style.bg_color = Color("#383234")
	pill_style.set_corner_radius_all(19)
	pill_style.shadow_color = Color(0, 0, 0, 0.2)
	pill_style.shadow_size = 6
	pill_style.shadow_offset = Vector2(0, 3)
	draw_style_box(pill_style, pill_rect)
	
	if font != null:
		draw_string(font, Vector2(center_x - 56, base_y + 30), timer_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 21, Color("#FFFFFF"))

extends Control

const Palette = preload("res://scripts/theme/palette.gd")

var kind: String = "rowcol"
var pattern: String = ""
var candy_texture: Texture2D

func _init(rule_pattern: String = "", texture: Texture2D = null) -> void:
	pattern = rule_pattern.replace("/", "")
	candy_texture = texture
	if rule_pattern == "rowcol" or pattern == ".X.XCX.X.":
		kind = "rowcol"
	elif rule_pattern == "region" or pattern == "XXXXC.X..":
		kind = "region"
	elif rule_pattern == "touch" or rule_pattern == "diagonal" or pattern == "XXXXXXXXX":
		kind = "touch"
	else:
		kind = "rowcol"
	custom_minimum_size = Vector2(76, 76)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var side := minf(size.x, size.y)
	var frame_rect := Rect2(Vector2.ZERO, Vector2.ONE * side)
	var frame_sb := StyleBoxFlat.new()
	frame_sb.bg_color = Color("#FFF6E2")
	frame_sb.set_corner_radius_all(10)
	frame_sb.set_border_width_all(2)
	frame_sb.border_color = Color("#E6C995")
	draw_style_box(frame_sb, frame_rect)

	var pad := 6.0
	var gap := 3.0
	var inner_side := side - pad * 2.0
	var cell_side := (inner_side - gap * 2.0) / 3.0

	for r in range(3):
		for c in range(3):
			var cell_rect := Rect2(
				Vector2(pad + float(c) * (cell_side + gap), pad + float(r) * (cell_side + gap)),
				Vector2.ONE * cell_side
			)
			var cell_bg := Color("#F3E3C2")
			var is_candy := false
			var is_x := false

			match kind:
				"rowcol":
					if r == 1 and c == 1:
						is_candy = true
					elif r == 1 or c == 1:
						cell_bg = Color("#BFDDFB")
						is_x = true
					else:
						cell_bg = Color("#F3E3C2")
				"region":
					var is_green := r < 2 and c < 2
					if r == 0 and c == 0:
						cell_bg = Color("#93DB7F")
						is_candy = true
					elif is_green:
						cell_bg = Color("#93DB7F")
						is_x = true
					else:
						cell_bg = Color("#FFB06E")
				"touch":
					if r == 1 and c == 1:
						cell_bg = Color("#FFF6E2")
						is_candy = true
					else:
						cell_bg = Color("#FFC9C2")
						is_x = true

			var csb := StyleBoxFlat.new()
			csb.bg_color = cell_bg
			csb.set_corner_radius_all(4)
			csb.border_width_bottom = 2
			csb.border_color = cell_bg.darkened(0.18)
			draw_style_box(csb, cell_rect)

			if is_candy:
				var center := cell_rect.get_center()
				var radius := cell_side * 0.32
				draw_circle(center + Vector2(0, 1), radius, Color("#B83228"))
				draw_circle(center, radius, Color("#FF5A4E"))
				draw_circle(center + Vector2(-radius * 0.32, -radius * 0.32), radius * 0.3, Color(1, 1, 1, 0.8))
			elif is_x:
				var inset := cell_side * 0.24
				var x_col := Color("#9A3A2A")
				draw_line(cell_rect.position + Vector2.ONE * inset, cell_rect.end - Vector2.ONE * inset, x_col, 2.4, true)
				draw_line(cell_rect.position + Vector2(cell_side - inset, inset), cell_rect.position + Vector2(inset, cell_side - inset), x_col, 2.4, true)

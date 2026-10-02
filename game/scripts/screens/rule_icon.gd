extends Control

const Palette = preload("res://scripts/theme/palette.gd")

var pattern: String = ""
var candy_texture: Texture2D

func _init(rule_pattern: String = "", texture: Texture2D = null) -> void:
	pattern = rule_pattern.replace("/", "")
	candy_texture = texture
	custom_minimum_size = Vector2(58, 58)

func _draw() -> void:
	var side: float = minf(size.x, size.y)
	var gap: float = 2.5
	var cell_side: float = (side - gap * 2.0) / 3.0
	for row in range(3):
		for col in range(3):
			var index: int = row * 3 + col
			var mark: String = pattern[index] if index < pattern.length() else "."
			var rect := Rect2(Vector2(col, row) * (cell_side + gap), Vector2.ONE * cell_side)
			var background := StyleBoxFlat.new()
			background.bg_color = Palette.TEXT_STAT if mark == "X" else Palette.RULE_EMPTY
			background.set_corner_radius_all(4)
			draw_style_box(background, rect)
			if mark == "X":
				var inset: float = cell_side * 0.24
				draw_line(rect.position + Vector2.ONE * inset, rect.end - Vector2.ONE * inset, Palette.TEXT_ON_ACCENT, 2.5)
				draw_line(rect.position + Vector2(cell_side - inset, inset), rect.position + Vector2(inset, cell_side - inset), Palette.TEXT_ON_ACCENT, 2.5)
			elif mark == "C":
				if candy_texture != null:
					draw_texture_rect(candy_texture, rect.grow(-1.5), false)
				else:
					draw_circle(rect.get_center(), cell_side * 0.3, Palette.CANDY_BROWN)

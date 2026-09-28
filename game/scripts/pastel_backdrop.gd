extends Control


const UiTheme = preload("res://scripts/ui_theme.gd")

@export_enum("home", "board", "settings") var variant := "home"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#FAF6F0") if variant == "home" else UiTheme.CREAM)
	if variant == "home":
		# Soft rounded sudoku grid pattern matching reference design
		var tile_fill := Color(0.965, 0.925, 0.885, 0.72)
		var tile := StyleBoxFlat.new()
		tile.bg_color = tile_fill
		tile.set_corner_radius_all(24)
		var tile_size := 180.0
		var gap := 22.0
		var step := tile_size + gap
		var start_x := (fposmod(size.x, step) - step) * 0.5
		var start_y := -20.0
		var y := start_y
		var row := 0
		while y < size.y + tile_size:
			var x := start_x
			var col := 0
			while x < size.x + tile_size:
				var rect := Rect2(x, y, tile_size, tile_size)
				draw_style_box(tile, rect)
				# Faint decorative X in top row/col (like in reference image)
				if (row == 0 and col == 1) or (row == 3 and col == 4) or (row == 7 and col == 0):
					var cx := x + tile_size * 0.5
					var cy := y + tile_size * 0.5
					var d := 32.0
					var cross_color := Color(0.89, 0.82, 0.75, 0.45)
					draw_line(Vector2(cx - d, cy - d), Vector2(cx + d, cy + d), cross_color, 14.0, true)
					draw_line(Vector2(cx + d, cy - d), Vector2(cx - d, cy + d), cross_color, 14.0, true)
				x += step
				col += 1
			y += step
			row += 1
		return

	var tile_fill := Color("#F7EDE4") if variant != "board" else Color("#F3E9DF")
	var tile_line := Color("#EEDFD2")
	var tile := UiTheme.rounded(tile_fill, 34, tile_line, 3)
	var tile_size := Vector2(210, 210)
	for py in range(-70, int(size.y) + 210, 280):
		draw_style_box(tile, Rect2(Vector2(-145, py), tile_size))
		draw_style_box(tile, Rect2(Vector2(size.x - 65, py + 120), tile_size))
	# Original four-petal mark: a quiet visual motif, not a character or logo.
	var motif_center := Vector2(size.x * 0.5, 170 if variant == "home" else 110)
	for offset in [Vector2(-22, 0), Vector2(22, 0), Vector2(0, -22), Vector2(0, 22)]:
		draw_circle(motif_center + offset, 24, Color("#F3C9A9"))
	draw_circle(motif_center, 14, UiTheme.CORAL)

extends Control


const UiTheme = preload("res://scripts/ui_theme.gd")

@export_enum("home", "board", "settings") var variant := "home"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UiTheme.CREAM)
	var tile_fill := Color("#F7EDE4") if variant != "board" else Color("#F3E9DF")
	var tile_line := Color("#EEDFD2")
	var tile := UiTheme.rounded(tile_fill, 34, tile_line, 3)
	var tile_size := Vector2(210, 210)
	for y in range(-70, int(size.y) + 210, 280):
		draw_style_box(tile, Rect2(Vector2(-145, y), tile_size))
		draw_style_box(tile, Rect2(Vector2(size.x - 65, y + 120), tile_size))
	# Original four-petal mark: a quiet visual motif, not a character or logo.
	var motif_center := Vector2(size.x * 0.5, 170 if variant == "home" else 110)
	for offset in [Vector2(-22, 0), Vector2(22, 0), Vector2(0, -22), Vector2(0, 22)]:
		draw_circle(motif_center + offset, 24, Color("#F3C9A9"))
	draw_circle(motif_center, 14, UiTheme.CORAL)

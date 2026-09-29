extends Control

const UiTheme = preload("res://scripts/ui_theme.gd")
const Tokens = preload("res://scripts/ui_tokens.gd")

@export_enum("home", "board", "settings") var variant: String = "home"
@export var tile_color: Color = Color("#FAF5F0")
@export var deco_color: Color = Color("#F5E3D0")
@export var columns: int = 6
@export var fade_center_alpha: float = 0.15


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var bg: Color = Tokens.BG_CREAM if variant == "home" else UiTheme.CREAM
	draw_rect(Rect2(Vector2.ZERO, size), bg)
	
	if variant != "home":
		var tile_fill := Color("#F7EDE4") if variant != "board" else Color("#F3E9DF")
		var tile_line := Color("#EEDFD2")
		var tile := UiTheme.rounded(tile_fill, 34, tile_line, 3)
		var tile_size := Vector2(210, 210)
		for py in range(-70, int(size.y) + 210, 280):
			draw_style_box(tile, Rect2(Vector2(-145, py), tile_size))
			draw_style_box(tile, Rect2(Vector2(size.x - 65, py + 120), tile_size))
		var motif_center := Vector2(size.x * 0.5, 110)
		for offset in [Vector2(-22, 0), Vector2(22, 0), Vector2(0, -22), Vector2(0, 22)]:
			draw_circle(motif_center + offset, 24, Color("#F3C9A9"))
		draw_circle(motif_center, 14, UiTheme.CORAL)
		return

	# HOME BACKDROP according to Spec §4.1:
	# 6-column rounded grid with Y-fade and deterministic decorative marks
	var cols: int = maxi(4, columns)
	var margin_x: float = 16.0
	var gap: float = 12.0
	var total_gaps: float = gap * float(cols - 1)
	var available_w: float = size.x - (margin_x * 2.0) - total_gaps
	var tile_dim: float = available_w / float(cols)
	var corner_rad: int = int(tile_dim * 0.22)
	
	var rows: int = int(ceil((size.y + 40.0) / (tile_dim + gap))) + 1
	var step: float = tile_dim + gap
	
	for r in range(rows):
		var y: float = float(r) * step - 20.0
		var norm_y: float = clampf(y / maxf(1.0, size.y), 0.0, 1.0)
		
		# Alpha fade along Y: higher at top (0-15%) & bottom (85-100%), fading to fade_center_alpha at center (30-70%)
		var alpha_mult: float = fade_center_alpha
		if norm_y < 0.20:
			alpha_mult = lerpf(1.0, fade_center_alpha, norm_y / 0.20)
		elif norm_y > 0.80:
			alpha_mult = lerpf(fade_center_alpha, 1.0, (norm_y - 0.80) / 0.20)
		
		var tile_style := StyleBoxFlat.new()
		tile_style.bg_color = Color(tile_color.r, tile_color.g, tile_color.b, tile_color.a * alpha_mult)
		tile_style.set_corner_radius_all(corner_rad)
		
		for c in range(cols):
			var x: float = margin_x + float(c) * step
			var rect := Rect2(x, y, tile_dim, tile_dim)
			draw_style_box(tile_style, rect)
			
			# Deterministic decorative marks (fixed rows/cols like §4.1)
			if (r == 0 and c == 1) or (r == 3 and c == 4) or (r == 8 and c == 0):
				# Decorative soft 'X'
				var cx: float = x + tile_dim * 0.5
				var cy: float = y + tile_dim * 0.5
				var d: float = tile_dim * 0.26
				var x_col := Color(deco_color.r, deco_color.g, deco_color.b, 0.45 * alpha_mult)
				draw_line(Vector2(cx - d, cy - d), Vector2(cx + d, cy + d), x_col, 10.0, true)
				draw_line(Vector2(cx + d, cy - d), Vector2(cx - d, cy + d), x_col, 10.0, true)
			elif (r == 1 and c == 5) or (r == 9 and c == 4):
				# Wrapped candy motif; decoration never communicates a clue.
				var center := Vector2(x + tile_dim * 0.5, y + tile_dim * 0.5)
				var tint := Color(deco_color.r, deco_color.g, deco_color.b, 0.35 * alpha_mult)
				draw_circle(center, tile_dim * 0.15, tint)
				for direction in [-1.0, 1.0]:
					draw_colored_polygon(PackedVector2Array([
						center + Vector2(direction * tile_dim * 0.12, 0),
						center + Vector2(direction * tile_dim * 0.30, -tile_dim * 0.12),
						center + Vector2(direction * tile_dim * 0.30, tile_dim * 0.12),
					]), tint)

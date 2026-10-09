# candy_cell_drawer.gd — Draws one board candy: animated mascot frame, static texture, or procedural fallback.
extends RefCounted

const Palette = preload("res://scripts/theme/palette.gd")
const CandyPalette = preload("res://scripts/theme/candy_palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const CandyAtlas = preload("res://scripts/screens/candy_atlas.gd")

static func draw(canvas: CanvasItem, rect: Rect2, is_given: bool, cs: float, static_tex: Texture2D, frame: Array) -> void:
	if is_given:
		canvas.draw_circle(rect.get_center(), rect.size.x * minf(LayoutTokens.GIVEN_HALO_RATIO * cs, 0.48), Color(CandyPalette.GIVEN_HALO, CandyPalette.GIVEN_HALO_OPACITY))
	var candy_size := rect.size * minf(LayoutTokens.CANDY_TEX_RATIO * cs, 0.95)
	var dst := Rect2(rect.position + (rect.size - candy_size) * 0.5, candy_size)
	var src := CandyAtlas.frame_rect(frame[0], frame[1]) if not frame.is_empty() else Rect2()
	if src.size.x > 0.0:
		var mascot_size := rect.size * minf(LayoutTokens.MASCOT_TEX_RATIO * cs, 1.35)
		canvas.draw_texture_rect_region(CandyAtlas.texture(), Rect2(rect.get_center() - mascot_size * 0.5, mascot_size), src)
	elif static_tex != null:
		canvas.draw_texture_rect(static_tex, dst, false)
	else:
		_draw_procedural(canvas, rect)

static func _draw_procedural(canvas: CanvasItem, rect: Rect2) -> void:
	var center := rect.get_center(); var radius := rect.size.x * 0.25
	for dir in [-1.0, 1.0]:
		var poly := PackedVector2Array([center + Vector2(dir * radius * 0.65, 0), center + Vector2(dir * radius * 1.6, -radius * 0.65), center + Vector2(dir * radius * 1.6, radius * 0.65)])
		canvas.draw_colored_polygon(poly, Palette.CANDY_LIGHT); canvas.draw_polyline(poly, Palette.CANDY_OUTLINE, 2.0, true)
	canvas.draw_circle(center, radius, Palette.CANDY_BROWN)
	canvas.draw_arc(center, radius * 0.60, -PI * 0.8, PI * 0.25, 18, Palette.CANDY_LIGHT, radius * 0.22, true)

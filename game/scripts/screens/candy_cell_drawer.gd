# candy_cell_drawer.gd — Draws one board candy: animated mascot frame, static texture, or procedural fallback.
extends RefCounted

const Palette = preload("res://scripts/theme/palette.gd")
const CandyPalette = preload("res://scripts/theme/candy_palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const CandyAtlas = preload("res://scripts/screens/candy_atlas.gd")
const MascotMotion = preload("res://scripts/screens/mascot_motion.gd")

const FOOT_Y := 94.0 / 128.0 # mascot feet inside an atlas frame (see tools/build_mascot_atlas.gd)
const SHADOW_COLOR := Color(0.66, 0.36, 0.04, 0.25)

static func draw(canvas: CanvasItem, rect: Rect2, is_given: bool, cs: float, static_tex: Texture2D, frame: Array, progress: float = 0.0) -> void:
	if is_given:
		canvas.draw_circle(rect.get_center(), rect.size.x * minf(LayoutTokens.GIVEN_HALO_RATIO * cs, 0.48), Color(CandyPalette.GIVEN_HALO, CandyPalette.GIVEN_HALO_OPACITY))
	var candy_size := rect.size * minf(LayoutTokens.CANDY_TEX_RATIO * cs, 0.95)
	var dst := Rect2(rect.position + (rect.size - candy_size) * 0.5, candy_size)
	var src := CandyAtlas.frame_rect(frame[0], frame[1]) if not frame.is_empty() else Rect2()
	if src.size.x > 0.0:
		_draw_mascot(canvas, rect, cs, src, MascotMotion.sample(frame[0], progress))
	elif static_tex != null:
		canvas.draw_texture_rect(static_tex, dst, false)
	else:
		_draw_procedural(canvas, rect)

# Body motion is applied here, per rendered frame, around the feet so squash stays grounded.
static func _draw_mascot(canvas: CanvasItem, rect: Rect2, cs: float, src: Rect2, m: Dictionary) -> void:
	var size := rect.size * minf(LayoutTokens.MASCOT_TEX_RATIO * cs, 1.35)
	var px := size / 128.0
	var foot := rect.get_center() + Vector2(0.0, (FOOT_Y - 0.5) * size.y)
	var lift: float = clampf(-m.dy / 40.0, 0.0, 0.6)
	_draw_ellipse(canvas, foot + Vector2(m.dx * px.x, 0.0), Vector2(size.x * 0.34, size.y * 0.055) * m.sc * (1.0 - lift), SHADOW_COLOR)
	var body := Vector2(size.x * m.sc * m.sx, size.y * m.sc * m.sy)
	var pos := foot - Vector2(body.x * 0.5, body.y * FOOT_Y) + Vector2(m.dx, m.dy) * px
	var flush: float = 0.75 * m.tint
	canvas.draw_texture_rect_region(CandyAtlas.texture(), Rect2(pos, body), src, Color(1.0, 1.0 - flush, 1.0 - flush))

static func _draw_ellipse(canvas: CanvasItem, center: Vector2, radii: Vector2, color: Color) -> void:
	if radii.x <= 0.5 or radii.y <= 0.5: return
	var pts := PackedVector2Array()
	for i in 16: pts.append(center + Vector2(cos(TAU * i / 16.0) * radii.x, sin(TAU * i / 16.0) * radii.y))
	canvas.draw_colored_polygon(pts, color)

static func _draw_procedural(canvas: CanvasItem, rect: Rect2) -> void:
	var center := rect.get_center(); var radius := rect.size.x * 0.25
	for dir in [-1.0, 1.0]:
		var poly := PackedVector2Array([center + Vector2(dir * radius * 0.65, 0), center + Vector2(dir * radius * 1.6, -radius * 0.65), center + Vector2(dir * radius * 1.6, radius * 0.65)])
		canvas.draw_colored_polygon(poly, Palette.CANDY_LIGHT); canvas.draw_polyline(poly, Palette.CANDY_OUTLINE, 2.0, true)
	canvas.draw_circle(center, radius, Palette.CANDY_BROWN)
	canvas.draw_arc(center, radius * 0.60, -PI * 0.8, PI * 0.25, 18, Palette.CANDY_LIGHT, radius * 0.22, true)

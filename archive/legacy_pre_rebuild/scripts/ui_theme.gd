extends RefCounted


const CREAM := Color("#FBF7F2")
const CREAM_DEEP := Color("#F1E8DE")
const PAPER := Color("#FFFDFC")
const INK := Color("#6D4A45")
const MUTED_INK := Color("#8E706B")
const CORAL := Color("#F29564")
const CORAL_DARK := Color("#D97145")
const LILAC := Color("#899EF0")
const MINT := Color("#8FD49A")
const LINE := Color("#E7D8CC")


static func rounded(fill: Color, radius: int = 28, border: Color = Color.TRANSPARENT, width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style


static func card(fill: Color = PAPER, radius: int = 32) -> StyleBoxFlat:
	var style := rounded(fill, radius, Color("#EADFD6"), 2)
	style.shadow_color = Color(0.35, 0.22, 0.18, 0.10)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 8)
	return style


static func button(fill: Color, radius: int = 34) -> StyleBoxFlat:
	var style := rounded(fill, radius)
	style.content_margin_left = 26.0
	style.content_margin_right = 26.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	style.shadow_color = Color(0.35, 0.22, 0.18, 0.12)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 6)
	return style

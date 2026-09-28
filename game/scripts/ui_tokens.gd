extends RefCounted
class_name UITokens

# Color tokens according to HOME_UI_Redesign_Spec.md §1.3 & §5
const BG_CREAM := Color("#F7F1EC")
const BG_TILE := Color("#FAF5F0")
const DECO_PEACH := Color("#F5E3D0")
const BROWN_LOGO := Color("#8B5A3C")
const ORANGE_PRIMARY := Color("#F0932A")
const ORANGE_PRESSED := Color("#D87D17")
const BLUE_ACCENT := Color("#8FA5F1")
const BLUE_PRESSED := Color("#738BE5")
const GEAR_MAUVE := Color("#86546A")
const AVATAR_BORDER := Color("#7DB843")
const TIMER_DARK := Color("#645858")
const CURRENCY_TEXT := Color("#A85A0A")
const TEXT_WHITE := Color("#FFFFFF")
const TEXT_WHITE_SOFT := Color(1.0, 1.0, 1.0, 0.85)
const TEXT_DARK := Color("#6D4A45")

# Radii and geometry
const PILL_RADIUS := 999
const BTN_GLOW_ALPHA := 0.35

static func make_pill_style(bg: Color, glow: Color = Color.TRANSPARENT, glow_size: int = 16, glow_offset: Vector2 = Vector2(0, 6)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(PILL_RADIUS)
	if glow != Color.TRANSPARENT:
		style.shadow_color = glow
		style.shadow_size = glow_size
		style.shadow_offset = glow_offset
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	return style

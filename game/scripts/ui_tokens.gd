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
const INK := TEXT_DARK

# Radii and geometry
const PILL_RADIUS := 999
const BTN_GLOW_ALPHA := 0.35

# Board tokens according to board_screen_restyle_spec.md §3
const BOARD_BG := Color("#F8F1EC")
const BOARD_CARD := Color("#FFFFFF")
const BOARD_TILE := Color("#FAF3EE")
const TEXT_STAT := Color("#9B5A52")
const TEXT_RULE := Color("#A0655C")
const ICON_BROWN := Color("#9B5A52")
const RULE_CELL_EMPTY := Color("#E0BFAA")
const BADGE_COUNT := Color("#E53935")
const BADGE_AD := Color("#12B84B")
const SHADOW_SOFT := Color(0.545, 0.353, 0.290, 0.18)

# 10 Region colors according to §3.2
const REGION_PALETTE: Array[Color] = [
	Color("#8BD87B"), # 0: Xanh lá nhạt
	Color("#8B7BD8"), # 1: Tím
	Color("#CDA800"), # 2: Vàng đậm
	Color("#F9D882"), # 3: Vàng kem
	Color("#F59DE0"), # 4: Hồng
	Color("#D17190"), # 5: Hồng đất
	Color("#F79C5D"), # 6: Cam
	Color("#AB6F4B"), # 7: Nâu
	Color("#2B9155"), # 8: Xanh lá đậm
	Color("#37A9C6"), # 9: Xanh lơ
]

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

static func make_card_style(fill: Color = Color.WHITE, radius: int = 32, shadow_alpha: float = 0.15) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	if shadow_alpha > 0.0:
		style.shadow_color = Color(0.545, 0.353, 0.290, shadow_alpha)
		style.shadow_size = 12
		style.shadow_offset = Vector2(0, 6)
	return style

static func make_circle_button_style(fill: Color = Color.WHITE, shadow_alpha: float = 0.18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(999)
	if shadow_alpha > 0.0:
		style.shadow_color = Color(0.545, 0.353, 0.290, shadow_alpha)
		style.shadow_size = 10
		style.shadow_offset = Vector2(0, 5)
	return style

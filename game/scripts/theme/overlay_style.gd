# overlay_style.gd — readable sizing and high-contrast styles shared by the
# settings, help and language overlays (portrait 1080 px design width).
extends RefCounted

const Palette = preload("res://scripts/theme/palette.gd")

const CARD_WIDTH := 960.0
const TITLE_FONT := 48
const HEADING_FONT := 34
const BODY_FONT := 30
const BUTTON_HEIGHT := 76.0
# Tiles sit on a near-white card; a visible edge keeps them apart.
const TILE_BORDER := Color("#D9C3B4")
const SELECTED_BG := Color("#B8501F")

const STATES := ["normal", "hover", "pressed", "focus"]

static func card(radius: int = 36, margin: int = 36) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Palette.SURFACE_WARM
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	s.shadow_color = Palette.CARD_SHADOW
	s.shadow_size = 16
	s.shadow_offset = Vector2(0, 6)
	return s

static func tile(margin: int = 20) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Palette.SURFACE_TILE
	s.border_color = TILE_BORDER
	s.set_border_width_all(2)
	s.set_corner_radius_all(22)
	s.set_content_margin_all(margin)
	return s

# Same background and text colour for every button state, so taps and focus on
# touch screens never fall back to the engine's white default text.
static func paint_button(btn: Button, bg: Color, text: Color, border: Color = Color.TRANSPARENT, radius: int = 18) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.content_margin_left = 24; s.content_margin_right = 24
	s.content_margin_top = 12; s.content_margin_bottom = 12
	if border.a > 0.0:
		s.border_color = border
		s.set_border_width_all(3)
	for st in STATES:
		btn.add_theme_stylebox_override(st, s)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		btn.add_theme_color_override(key, text)

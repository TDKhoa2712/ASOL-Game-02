# back_button.gd — coral round "X" close button shared by overlay headers (options, help)
extends RefCounted

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const OverlayStyle = preload("res://scripts/theme/overlay_style.gd")

const SIZE := Vector2(80, 80)
# Darker than CORAL so the white X keeps >= 3:1 contrast.
const CLOSE_BG := Color("#C9483D")

static func make() -> Button:
	var btn := Button.new()
	btn.name = "BackBtn"
	btn.text = "X"
	btn.tooltip_text = TranslationServer.translate("settings.back")
	btn.custom_minimum_size = SIZE
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 38)
	OverlayStyle.paint_button(btn, CLOSE_BG, Palette.TEXT_ON_ACCENT, Color.TRANSPARENT, int(SIZE.x * 0.5))
	btn.get_theme_stylebox("normal").set_content_margin_all(0) # one box shared by all states
	var font: Font = FontTokens.body_semibold()
	if font != null:
		btn.add_theme_font_override("font", font)
	return btn

# Header row: [balancing spacer] [title centered] [X]; stays outside any scroll.
static func make_header(back_btn: Button, title: Label) -> HBoxContainer:
	var bar := HBoxContainer.new()
	bar.name = "HeaderBar"
	var balance := Control.new()
	balance.custom_minimum_size = Vector2(SIZE.x, 0)
	balance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(balance)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar.add_child(title)
	bar.add_child(back_btn)
	return bar

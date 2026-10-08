# help_screen.gd
extends Control

signal back_pressed()

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")

const RULES := [
	{"icon": "1️⃣", "title_key": "help.rule1_title", "body_key": "help.rule1_body"},
	{"icon": "2️⃣", "title_key": "help.rule2_title", "body_key": "help.rule2_body"},
	{"icon": "3️⃣", "title_key": "help.rule3_title", "body_key": "help.rule3_body"},
]

const CONTROLS := [
	"help.control_tap",
	"help.control_double",
	"help.control_swipe",
]

func _ready() -> void:
	_build()

func _build() -> void:
	for child in get_children():
		child.queue_free()

	var dimmer := ColorRect.new()
	dimmer.color = Palette.SCRIM
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			back_pressed.emit()
	)
	add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card := PanelContainer.new()
	card.name = "HelpCard"
	card.custom_minimum_size = Vector2(720, 0)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Palette.SURFACE_WARM
	card_style.set_corner_radius_all(34)
	card_style.set_content_margin_all(36)
	card_style.shadow_color = Palette.CARD_SHADOW
	card_style.shadow_size = 16
	card_style.shadow_offset = Vector2(0, 6)
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 700)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card.add_child(scroll)

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 24)
	scroll.add_child(stack)

	var body_font: Font = FontTokens.body()
	var bold_font: Font = FontTokens.body_semibold()

	# Title
	var title := Label.new()
	title.text = tr("help.title")
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Palette.INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if bold_font != null:
		title.add_theme_font_override("font", bold_font)
	stack.add_child(title)

	# Rules
	for rule in RULES:
		stack.add_child(_make_rule_card(rule, body_font, bold_font))

	# Controls section
	var controls_title := Label.new()
	controls_title.text = tr("help.controls_title")
	controls_title.add_theme_font_size_override("font_size", 30)
	controls_title.add_theme_color_override("font_color", Palette.INK)
	if bold_font != null:
		controls_title.add_theme_font_override("font", bold_font)
	stack.add_child(controls_title)

	for key in CONTROLS:
		var ctrl_lbl := Label.new()
		ctrl_lbl.text = "• " + tr(key)
		ctrl_lbl.add_theme_font_size_override("font_size", LayoutTokens.tile_font_size())
		ctrl_lbl.add_theme_color_override("font_color", Palette.INK)
		ctrl_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if body_font != null:
			ctrl_lbl.add_theme_font_override("font", body_font)
		stack.add_child(ctrl_lbl)

	# Hearts section
	var hearts_card := _make_section_card(
		tr("help.hearts_title"), tr("help.hearts_body"),
		Palette.CORAL, body_font, bold_font
	)
	stack.add_child(hearts_card)

	# Close button
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_child(btn_row)

	var close_btn := Button.new()
	close_btn.text = tr("settings.back")
	close_btn.custom_minimum_size = Vector2(200, 56)
	close_btn.add_theme_font_size_override("font_size", 24)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Palette.CORAL
	btn_style.set_corner_radius_all(16)
	btn_style.set_content_margin_all(10)
	for state in ["normal", "hover", "pressed", "focus"]:
		close_btn.add_theme_stylebox_override(state, btn_style)
	close_btn.add_theme_color_override("font_color", Palette.TEXT_ON_ACCENT)
	if body_font != null:
		close_btn.add_theme_font_override("font", body_font)
	close_btn.pressed.connect(func(): back_pressed.emit())
	btn_row.add_child(close_btn)

func _make_rule_card(rule: Dictionary, body_font: Font, bold_font: Font) -> PanelContainer:
	var tile := PanelContainer.new()
	var tile_style := StyleBoxFlat.new()
	tile_style.bg_color = Palette.SURFACE_TILE
	tile_style.set_corner_radius_all(20)
	tile_style.set_content_margin_all(20)
	tile.add_theme_stylebox_override("panel", tile_style)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)

	var icon := Label.new()
	icon.text = rule.icon
	icon.add_theme_font_size_override("font_size", 28)
	header.add_child(icon)

	var title := Label.new()
	title.text = tr(rule.title_key)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Palette.INK)
	if bold_font != null:
		title.add_theme_font_override("font", bold_font)
	header.add_child(title)

	col.add_child(header)

	var body := Label.new()
	body.text = tr(rule.body_key)
	body.add_theme_font_size_override("font_size", LayoutTokens.tile_font_size())
	body.add_theme_color_override("font_color", Palette.INK_LIGHT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if body_font != null:
		body.add_theme_font_override("font", body_font)
	col.add_child(body)

	tile.add_child(col)
	return tile

func _make_section_card(title_text: String, body_text: String, accent: Color, body_font: Font, bold_font: Font) -> PanelContainer:
	var tile := PanelContainer.new()
	var tile_style := StyleBoxFlat.new()
	tile_style.bg_color = Palette.SURFACE_TILE
	tile_style.set_corner_radius_all(20)
	tile_style.set_content_margin_all(20)
	tile_style.border_color = accent
	tile_style.set_border_width_all(2)
	tile.add_theme_stylebox_override("panel", tile_style)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)

	var t := Label.new()
	t.text = title_text
	t.add_theme_font_size_override("font_size", 26)
	t.add_theme_color_override("font_color", accent)
	if bold_font != null:
		t.add_theme_font_override("font", bold_font)
	col.add_child(t)

	var b := Label.new()
	b.text = body_text
	b.add_theme_font_size_override("font_size", LayoutTokens.tile_font_size())
	b.add_theme_color_override("font_color", Palette.INK_LIGHT)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if body_font != null:
		b.add_theme_font_override("font", body_font)
	col.add_child(b)

	tile.add_child(col)
	return tile

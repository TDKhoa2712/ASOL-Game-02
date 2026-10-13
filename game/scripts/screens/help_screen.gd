# help_screen.gd
extends Control

signal back_pressed()

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const BackButton = preload("res://scripts/screens/back_button.gd")
const OverlayStyle = preload("res://scripts/theme/overlay_style.gd")

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
	card.custom_minimum_size = Vector2(OverlayStyle.CARD_WIDTH, 0)
	card.add_theme_stylebox_override("panel", OverlayStyle.card())
	center.add_child(card)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 20)
	card.add_child(outer)

	var body_font: Font = FontTokens.body()
	var bold_font: Font = FontTokens.body_semibold()

	# Title + back stay pinned above the scroll so closing never needs scrolling.
	var title := Label.new()
	title.text = tr("help.title")
	title.add_theme_font_size_override("font_size", OverlayStyle.TITLE_FONT)
	title.add_theme_color_override("font_color", Palette.INK)
	if bold_font != null:
		title.add_theme_font_override("font", bold_font)
	var back_btn := BackButton.make()
	back_btn.pressed.connect(func(): back_pressed.emit())
	outer.add_child(BackButton.make_header(back_btn, title))

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 1180)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 24)
	scroll.add_child(stack)

	# Rules
	for rule in RULES:
		stack.add_child(_make_rule_card(rule, body_font, bold_font))

	# Controls section
	var controls_title := Label.new()
	controls_title.text = tr("help.controls_title")
	controls_title.add_theme_font_size_override("font_size", OverlayStyle.HEADING_FONT)
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

func _make_rule_card(rule: Dictionary, body_font: Font, bold_font: Font) -> PanelContainer:
	var tile := PanelContainer.new()
	tile.add_theme_stylebox_override("panel", OverlayStyle.tile(24))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)

	var icon := Label.new()
	icon.text = rule.icon
	icon.add_theme_font_size_override("font_size", OverlayStyle.HEADING_FONT)
	header.add_child(icon)

	var title := Label.new()
	title.text = tr(rule.title_key)
	title.add_theme_font_size_override("font_size", OverlayStyle.HEADING_FONT)
	title.add_theme_color_override("font_color", Palette.INK)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if bold_font != null:
		title.add_theme_font_override("font", bold_font)
	header.add_child(title)

	col.add_child(header)

	var body := Label.new()
	body.text = tr(rule.body_key)
	body.add_theme_font_size_override("font_size", LayoutTokens.tile_font_size())
	body.add_theme_color_override("font_color", Palette.INK)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if body_font != null:
		body.add_theme_font_override("font", body_font)
	col.add_child(body)

	tile.add_child(col)
	return tile

func _make_section_card(title_text: String, body_text: String, accent: Color, body_font: Font, bold_font: Font) -> PanelContainer:
	var tile := PanelContainer.new()
	var tile_style := OverlayStyle.tile(24)
	tile_style.border_color = accent
	tile_style.set_border_width_all(3)
	tile.add_theme_stylebox_override("panel", tile_style)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)

	var t := Label.new()
	t.text = title_text
	t.add_theme_font_size_override("font_size", OverlayStyle.HEADING_FONT)
	t.add_theme_color_override("font_color", Palette.INK)
	if bold_font != null:
		t.add_theme_font_override("font", bold_font)
	col.add_child(t)

	var b := Label.new()
	b.text = body_text
	b.add_theme_font_size_override("font_size", LayoutTokens.tile_font_size())
	b.add_theme_color_override("font_color", Palette.INK)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if body_font != null:
		b.add_theme_font_override("font", body_font)
	col.add_child(b)

	tile.add_child(col)
	return tile

# "Out of assists" sheet. Shows how to earn more; the ad button is a placeholder.
extends Control

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")

signal ad_pressed()

var title_label: Label
var body_label: Label
var ad_btn: Button
var ad_badge: Label
var close_btn: Button

func _init() -> void:
	name = "AssistEmptyPopup"
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.45)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(560, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE; sb.set_corner_radius_all(32)
	sb.border_width_bottom = 8; sb.border_color = Palette.BOARD_HINT_EDGE
	sb.content_margin_left = 36; sb.content_margin_right = 36
	sb.content_margin_top = 32; sb.content_margin_bottom = 32
	card.add_theme_stylebox_override("panel", sb)
	center.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 24)
	card.add_child(col)
	title_label = _label("Title", 38, FontTokens.heading())
	body_label = _label("Body", 26, FontTokens.body_bold())
	col.add_child(title_label)
	col.add_child(body_label)
	col.add_child(_ad_button())
	close_btn = Button.new()
	close_btn.name = "CloseBtn"
	close_btn.text = tr("assist.close")
	close_btn.custom_minimum_size = Vector2(0, 88)
	close_btn.pressed.connect(close)
	col.add_child(close_btn)

func open(kind: String) -> void:
	title_label.text = tr("assist.empty_title_" + kind)
	body_label.text = tr("assist.empty_body")
	visible = true

func close() -> void:
	visible = false

func _label(node_name: String, font_size: int, font: Font) -> Label:
	var l := Label.new()
	l.name = node_name
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color("#23365E"))
	if font != null: l.add_theme_font_override("font", font)
	return l

func _ad_button() -> Control:
	var wrap := CenterContainer.new()
	var btn := Button.new()
	btn.name = "AdBtn"
	ad_btn = btn
	btn.custom_minimum_size = Vector2(150, 150)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.ERROR_RED; sb.set_corner_radius_all(40)
	sb.border_width_bottom = 8; sb.border_color = Palette.ERROR_RED.darkened(0.35)
	for state in ["normal", "hover", "pressed", "focus"]:
		btn.add_theme_stylebox_override(state, sb)
	btn.text = "▶"
	btn.add_theme_font_size_override("font_size", 72)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.pressed.connect(func(): ad_pressed.emit())
	ad_badge = Label.new()
	ad_badge.name = "AdBadge"
	ad_badge.visible = false  # Remaining ad views; shown once rewarded ads exist.
	ad_badge.position = Vector2(112, -10)
	btn.add_child(ad_badge)
	wrap.add_child(btn)
	return wrap

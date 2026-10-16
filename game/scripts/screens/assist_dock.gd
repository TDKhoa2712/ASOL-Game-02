# Dock pieces for the assists: count badges, the place-candy button, a short toast.
extends RefCounted

const Palette = preload("res://scripts/theme/palette.gd")
const BoardButtons = preload("res://scripts/ui/board_buttons.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const PLACE_ICON := "res://assets/candy/candy_icon.png"

static func attach_badge(btn: Button, label_name: String) -> void:
	var badge := PanelContainer.new()
	badge.name = "Badge"
	badge.add_theme_stylebox_override("panel", BoardButtons.card_sb(Palette.BOARD_BLUE, Palette.BOARD_BLUE_EDGE, 999, 2, 8, 2))
	badge.position = Vector2(btn.custom_minimum_size.x - 32, -8)
	badge.custom_minimum_size = Vector2(34, 34)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.visible = false  # Shown once an assist stock is bound.
	var label := Label.new()
	label.name = label_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	var font := FontTokens.body_bold()
	if font != null: label.add_theme_font_override("font", font)
	badge.add_child(label)
	btn.add_child(badge)

static func set_badge(btn: Button, value: int) -> void:
	var badge := btn.get_node_or_null("Badge") as Control
	if badge == null or badge.get_child_count() == 0:
		return
	(badge.get_child(0) as Label).text = str(value)
	badge.visible = true

static func make_place_button() -> Button:
	var btn: Button = BoardButtons.make_3d_btn("PlaceBtn", PLACE_ICON, Color.WHITE, Palette.BOARD_BTN_EDGE, Color.WHITE, Vector2(120, 120), 30, 8, Vector2(66, 66))
	attach_badge(btn, "PlaceCount")
	return btn

static func show_toast(parent: Control, text: String, delay: float = 0.0) -> Label:
	var toast := Label.new()
	toast.name = "AssistToast"
	toast.text = text
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size", 30)
	toast.add_theme_color_override("font_color", Color.WHITE)
	toast.add_theme_color_override("font_outline_color", Palette.BOARD_HINT_EDGE)
	toast.add_theme_constant_override("outline_size", 10)
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast.position.y += 220
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(toast)
	if parent.is_inside_tree():
		var tw := toast.create_tween()
		if delay > 0.0:
			toast.modulate.a = 0.0
			tw.tween_interval(delay)
			tw.tween_property(toast, "modulate:a", 1.0, 0.15)
		tw.tween_interval(1.6)
		tw.tween_property(toast, "modulate:a", 0.0, 0.4)
		tw.tween_callback(toast.queue_free)
	return toast

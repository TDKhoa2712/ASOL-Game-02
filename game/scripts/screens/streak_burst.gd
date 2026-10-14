# "+1 day" burst on the board: the flame pops and the count ticks to the new total.
extends RefCounted

const StreakSheet = preload("res://scripts/screens/streak_sheet.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")

static func play(parent: Control, total: int) -> Control:
	var box := VBoxContainer.new()
	box.name = "StreakBurst"
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(240, 260)
	box.position -= box.custom_minimum_size * 0.5
	box.pivot_offset = box.custom_minimum_size * 0.5
	var icon := TextureRect.new()
	icon.texture = load("res://assets/ui/home/icon_flame.svg") as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(150, 150)
	icon.modulate = StreakSheet.ON_COLOR
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 84)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", StreakSheet.ON_COLOR.darkened(0.35))
	label.add_theme_constant_override("outline_size", 14)
	var font := FontTokens.heading()
	if font != null: label.add_theme_font_override("font", font)
	box.add_child(label)
	box.set_meta("label", label)
	parent.add_child(box)
	if not LayoutTokens.motion_enabled or not parent.is_inside_tree():
		label.text = str(total)
		return box
	label.text = str(maxi(total - 1, 0))
	box.scale = Vector2(0.4, 0.4)
	var tw := box.create_tween()
	tw.tween_property(box, "scale", Vector2(1.25, 1.25), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): label.text = str(total))
	tw.tween_property(box, "scale", Vector2.ONE, 0.2)
	tw.tween_interval(0.5)
	tw.tween_property(box, "modulate:a", 0.0, 0.3)
	tw.tween_callback(box.queue_free)
	return box

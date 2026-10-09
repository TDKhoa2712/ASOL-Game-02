# action_button.gd — 3D-style button with shadow, press animation, and optional pulse.
extends RefCounted

const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

static func create(text: String, bg_color: Color, shadow_color: Color, text_shadow_color: Color, font_size: int = 34, height: int = 90) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, height)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var font := FontTokens.body_bold()
	if font != null:
		btn.add_theme_font_override("font", font)

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(24)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	style.shadow_color = shadow_color
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 8)

	for state in ["normal", "hover", "focus"]:
		btn.add_theme_stylebox_override(state, style)

	var pressed_style := style.duplicate() as StyleBoxFlat
	pressed_style.shadow_size = 2
	pressed_style.shadow_offset = Vector2(0, 2)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	btn.pivot_offset = Vector2(btn.custom_minimum_size.x * 0.5, btn.custom_minimum_size.y * 0.5)
	btn.resized.connect(func(): btn.pivot_offset = btn.size * 0.5)

	btn.button_down.connect(func():
		if not LayoutTokens.motion_enabled: return
		btn.pivot_offset = btn.size * 0.5
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(0.96, 0.96), 0.08)
	)
	btn.button_up.connect(func():
		if not LayoutTokens.motion_enabled: return
		btn.pivot_offset = btn.size * 0.5
		var tw := btn.create_tween()
		tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.15)
	)
	return btn

static func add_pulse(btn: Button) -> void:
	if not LayoutTokens.motion_enabled:
		return
	var tw := btn.create_tween().set_loops()
	tw.tween_property(btn, "position:y", btn.position.y - 4.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(btn, "position:y", btn.position.y, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

static func set_leading_icon(btn: Button, icon_path: String, icon_size: Vector2 = Vector2(30, 30)) -> Label:
	for s in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(s, Color.TRANSPARENT)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(row)
	var ico := TextureRect.new()
	ico.texture = load(icon_path) as Texture2D
	ico.custom_minimum_size = icon_size
	ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(ico)
	var lbl := Label.new()
	lbl.name = "ActionLabel"
	lbl.text = btn.text
	lbl.add_theme_font_size_override("font_size", btn.get_theme_font_size("font_size"))
	lbl.add_theme_color_override("font_color", Color.WHITE)
	var f := FontTokens.body_bold()
	if f != null: lbl.add_theme_font_override("font", f)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(lbl)
	return lbl


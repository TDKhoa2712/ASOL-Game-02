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

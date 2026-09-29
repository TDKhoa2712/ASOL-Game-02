class_name SettingsScreen
extends Control

const SettingsUIConfig = preload("res://scripts/ui/settings_ui_config.gd")

## Script điều khiển giao diện Cài đặt, tự động áp dụng thông số từ SettingsUIConfig


func _ready() -> void:
	apply_config()


## Áp dụng toàn bộ cấu hình từ SettingsUIConfig vào các node giao diện
func apply_config() -> void:
	var dimmer := get_node_or_null("Dimmer") as ColorRect
	if dimmer != null:
		dimmer.color = SettingsUIConfig.DIMMER_COLOR

	var content := get_node_or_null("SafeArea/Content") as PanelContainer
	if content != null:
		content.add_theme_stylebox_override("panel", SettingsUIConfig.make_panel_style())
		content.anchor_left = SettingsUIConfig.CARD_ANCHOR_LEFT
		content.anchor_right = SettingsUIConfig.CARD_ANCHOR_RIGHT

	var title := get_node_or_null("SafeArea/Content/Stack/TitleBar/Title") as Label
	if title != null:
		title.add_theme_color_override("font_color", SettingsUIConfig.TEXT_TITLE)
		title.add_theme_font_size_override("font_size", SettingsUIConfig.FONT_SIZE_TITLE)

	var close_btn := get_node_or_null("SafeArea/Content/Stack/TitleBar/CloseButton") as Button
	if close_btn != null:
		close_btn.modulate = SettingsUIConfig.TEXT_SUB

	var subtitle := get_node_or_null("SafeArea/Content/Stack/Subtitle") as Label
	if subtitle != null:
		subtitle.add_theme_color_override("font_color", SettingsUIConfig.TEXT_SUB)
		subtitle.add_theme_font_size_override("font_size", SettingsUIConfig.FONT_SIZE_SUBTITLE)

	var tile_style := SettingsUIConfig.make_tile_style()
	var tile_names := ["AudioToggle", "HapticsToggle", "ReducedMotionToggle", "LargeTextToggle"]
	for t_name in tile_names:
		var tile := get_node_or_null("SafeArea/Content/Stack/TileRow/%s" % t_name) as PanelContainer
		if tile != null:
			tile.add_theme_stylebox_override("panel", tile_style)
			var lbl := tile.find_child("*Label", true, false) as Label
			if lbl != null:
				lbl.add_theme_color_override("font_color", SettingsUIConfig.TEXT_BODY)
				lbl.add_theme_font_size_override("font_size", SettingsUIConfig.FONT_SIZE_TILE_LABEL)

	var contrast_toggle := get_node_or_null("SafeArea/Content/Stack/HighContrastToggle") as PanelContainer
	if contrast_toggle != null:
		contrast_toggle.add_theme_stylebox_override("panel", SettingsUIConfig.make_row_wide_style())
		contrast_toggle.custom_minimum_size.y = SettingsUIConfig.ROW_WIDE_MIN_HEIGHT
		var c_lbl := contrast_toggle.find_child("HighContrastLabel", true, false) as Label
		if c_lbl != null:
			c_lbl.add_theme_color_override("font_color", SettingsUIConfig.TEXT_BODY)
			c_lbl.add_theme_font_size_override("font_size", SettingsUIConfig.FONT_SIZE_ROW_LABEL)

	var back_btn := get_node_or_null("SafeArea/Content/Stack/ButtonStack/BackButton") as Button
	if back_btn != null:
		back_btn.add_theme_stylebox_override("normal", SettingsUIConfig.make_button_primary_style(false))
		back_btn.add_theme_stylebox_override("hover", SettingsUIConfig.make_button_primary_style(false))
		back_btn.add_theme_stylebox_override("pressed", SettingsUIConfig.make_button_primary_style(true))
		back_btn.add_theme_font_size_override("font_size", SettingsUIConfig.FONT_SIZE_BUTTON)
		back_btn.custom_minimum_size.y = SettingsUIConfig.BTN_PRIMARY_HEIGHT

	var restart_btn := get_node_or_null("SafeArea/Content/Stack/ButtonStack/RestartButton") as Button
	if restart_btn != null:
		restart_btn.add_theme_stylebox_override("normal", SettingsUIConfig.make_button_primary_style(false))
		restart_btn.add_theme_stylebox_override("hover", SettingsUIConfig.make_button_primary_style(false))
		restart_btn.add_theme_stylebox_override("pressed", SettingsUIConfig.make_button_primary_style(true))
		restart_btn.add_theme_font_size_override("font_size", SettingsUIConfig.FONT_SIZE_BUTTON)
		restart_btn.custom_minimum_size.y = SettingsUIConfig.BTN_PRIMARY_HEIGHT

	var feedback_btn := get_node_or_null("SafeArea/Content/Stack/ButtonStack/FeedbackButton") as Button
	if feedback_btn != null:
		feedback_btn.add_theme_stylebox_override("normal", SettingsUIConfig.make_button_outline_style())
		feedback_btn.add_theme_stylebox_override("hover", SettingsUIConfig.make_button_outline_style())
		feedback_btn.add_theme_stylebox_override("pressed", SettingsUIConfig.make_button_outline_style())
		feedback_btn.add_theme_color_override("font_color", SettingsUIConfig.BTN_OUTLINE_BORDER)
		feedback_btn.add_theme_font_size_override("font_size", SettingsUIConfig.FONT_SIZE_BUTTON)
		feedback_btn.custom_minimum_size.y = SettingsUIConfig.BTN_OUTLINE_HEIGHT

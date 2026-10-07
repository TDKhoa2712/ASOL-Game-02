# title_screen.gd
extends Control

signal play_pressed()
signal endless_pressed()
signal options_pressed()
signal debug_level_selected(level_data: Dictionary, label: String)

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const DebugLevelPicker = preload("res://scripts/screens/debug_level_picker.gd")

var runtime: Variant = null
var endless_runtime: Variant = null

var title_label: Label
var play_btn: Button
var campaign_subtitle: Label
var endless_btn: Button
var options_btn: Button
var help_btn: Button
var debug_btn: Button
var help_dialog: AcceptDialog
var debug_picker: DebugLevelPicker

func _ensure_nodes() -> void:
	if title_label != null:
		return
	var background := ColorRect.new()
	background.name = "Background"
	background.color = Palette.BOARD_BG
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var safe := MarginContainer.new()
	safe.name = "SafeArea"
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 40)
	safe.add_theme_constant_override("margin_right", 40)
	safe.add_theme_constant_override("margin_top", 56)
	safe.add_theme_constant_override("margin_bottom", 54)
	add_child(safe)
	var frame := VBoxContainer.new()
	frame.name = "Frame"
	safe.add_child(frame)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	frame.add_child(top)
	if OS.is_debug_build():
		debug_btn = Button.new()
		debug_btn.name = "DebugButton"
		debug_btn.text = tr("title.debug")
		debug_btn.custom_minimum_size = Vector2(140, 56)
		top.add_child(debug_btn)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	help_btn = Button.new()
	help_btn.name = "HelpButton"
	help_btn.custom_minimum_size = Vector2(88, 88)
	help_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_set_round_icon(help_btn, "res://assets/ui/home/button_help.png", 88)
	help_btn.tooltip_text = tr("title.help_tooltip")
	var help_style := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus"]:
		help_btn.add_theme_stylebox_override(state, help_style)
	top.add_child(help_btn)
	options_btn = Button.new()
	options_btn.name = "OptionsButton"
	options_btn.custom_minimum_size = Vector2(88, 88)
	options_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	options_btn.flat = false
	_set_round_icon(options_btn, "res://assets/ui/home/button_settings.png", 88)
	var option_style := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus"]:
		options_btn.add_theme_stylebox_override(state, option_style)
	top.add_child(options_btn)
	var top_gap := Control.new()
	top_gap.custom_minimum_size.y = 60
	frame.add_child(top_gap)
	var hero := VBoxContainer.new()
	hero.name = "HeroBlock"
	hero.alignment = BoxContainer.ALIGNMENT_CENTER
	hero.add_theme_constant_override("separation", 0)
	frame.add_child(hero)
	var logo := TextureRect.new()
	logo.name = "CandyLogo"
	logo.texture = load("res://assets/ui/home/logo_candoku.png") as Texture2D
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.custom_minimum_size = Vector2(580, 275)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.add_child(logo)
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = tr("title.name")
	title_label.visible = false
	hero.add_child(title_label)
	var middle_space := Control.new()
	middle_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(middle_space)
	var actions := VBoxContainer.new()
	actions.name = "ActionBlock"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 16)
	frame.add_child(actions)

	# 1. Campaign button container
	var campaign_box := VBoxContainer.new()
	campaign_box.name = "CampaignBox"
	campaign_box.alignment = BoxContainer.ALIGNMENT_CENTER
	campaign_box.add_theme_constant_override("separation", 4)
	actions.add_child(campaign_box)

	play_btn = Button.new()
	play_btn.name = "PlayButton"
	play_btn.custom_minimum_size = Vector2(560, 100)
	play_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	play_btn.add_theme_font_size_override("font_size", 40)
	var btn_font := FontTokens.body_semibold()
	if btn_font != null:
		play_btn.add_theme_font_override("font", btn_font)
	var play_style := StyleBoxFlat.new()
	play_style.bg_color = Palette.PLAY_BUTTON
	play_style.set_corner_radius_all(999)
	play_style.shadow_color = Palette.PLAY_GLOW
	play_style.shadow_size = 12
	play_style.shadow_offset = Vector2(0, 4)
	play_style.set_content_margin_all(16)
	for state in ["normal", "hover", "pressed", "focus"]:
		play_btn.add_theme_stylebox_override(state, play_style)
	campaign_box.add_child(play_btn)

	campaign_subtitle = Label.new()
	campaign_subtitle.name = "CampaignSubtitle"
	campaign_subtitle.text = "1->30"
	campaign_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	campaign_subtitle.add_theme_font_size_override("font_size", 22)
	campaign_subtitle.add_theme_color_override("font_color", Palette.INK_LIGHT)
	var sub_font := FontTokens.body()
	if sub_font != null:
		campaign_subtitle.add_theme_font_override("font", sub_font)
	campaign_box.add_child(campaign_subtitle)

	# 2. Endless button
	endless_btn = Button.new()
	endless_btn.name = "EndlessButton"
	endless_btn.custom_minimum_size = Vector2(560, 90)
	endless_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	endless_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	endless_btn.add_theme_font_size_override("font_size", 36)
	if btn_font != null:
		endless_btn.add_theme_font_override("font", btn_font)
	var endless_style := StyleBoxFlat.new()
	endless_style.bg_color = Palette.PILL_BG
	endless_style.set_corner_radius_all(999)
	endless_style.shadow_color = Palette.CARD_SHADOW
	endless_style.shadow_size = 8
	endless_style.shadow_offset = Vector2(0, 3)
	endless_style.set_content_margin_all(14)
	for state in ["normal", "hover", "pressed", "focus"]:
		endless_btn.add_theme_stylebox_override(state, endless_style)
	endless_btn.add_theme_color_override("font_color", Palette.INK)
	actions.add_child(endless_btn)

	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size.y = 80
	frame.add_child(bottom_spacer)
	help_dialog = AcceptDialog.new()
	help_dialog.title = tr("help.title")
	help_dialog.dialog_text = tr("help.body")
	add_child(help_dialog)
	if OS.is_debug_build():
		debug_picker = DebugLevelPicker.new()
		debug_picker.name = "DebugPicker"
		debug_picker.visible = false
		debug_picker.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		debug_picker.level_selected.connect(func(lvl: Dictionary, lbl: String):
			debug_picker.visible = false
			debug_level_selected.emit(lvl, lbl)
		)
		debug_picker.close_requested.connect(func(): debug_picker.visible = false)
		debug_picker.progress_reset.connect(func(_m): _update_ui())
		add_child(debug_picker)

func _ready() -> void:
	_ensure_nodes()
	if play_btn != null and not play_btn.pressed.is_connected(_on_play):
		play_btn.pressed.connect(_on_play)
	if endless_btn != null and not endless_btn.pressed.is_connected(_on_endless):
		endless_btn.pressed.connect(_on_endless)
	if options_btn != null and not options_btn.pressed.is_connected(_on_options):
		options_btn.pressed.connect(_on_options)
	if help_btn != null and not help_btn.pressed.is_connected(_on_help):
		help_btn.pressed.connect(_on_help)
	if debug_btn != null and not debug_btn.pressed.is_connected(_on_debug_pressed):
		debug_btn.pressed.connect(_on_debug_pressed)
	for btn in [play_btn, endless_btn, options_btn, help_btn, debug_btn]:
		if btn != null:
			btn.pivot_offset = btn.size * 0.5
			btn.resized.connect(func(): btn.pivot_offset = btn.size * 0.5)
			_add_press_anim(btn)
	_update_ui()

func setup(rt: Variant, endless_rt: Variant = null) -> void:
	runtime = rt
	endless_runtime = endless_rt
	_ensure_nodes()
	_update_ui()
	if debug_picker != null and rt != null:
		var pl: Array = rt._playlist if "_playlist" in rt else []
		var b: Variant = rt.bank if "bank" in rt else null
		debug_picker.setup(b, pl, endless_rt, rt)

func _on_debug_pressed() -> void:
	if debug_picker != null:
		debug_picker.visible = not debug_picker.visible

func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1 or event.keycode == KEY_QUOTELEFT:
			_on_debug_pressed()
			get_viewport().set_input_as_handled()

func _update_ui() -> void:
	if runtime != null:
		var label: String = runtime.current_level_label()
		if play_btn != null:
			if runtime.is_campaign_done():
				play_btn.text = tr("title.replay")
			else:
				play_btn.text = tr("title.play") % label.trim_prefix("L")
		if campaign_subtitle != null and runtime.has_method("playlist_order"):
			var order: Array = runtime.playlist_order()
			if not order.is_empty():
				campaign_subtitle.text = "1->%d" % order.size()
	if endless_btn != null:
		var endless_num: int = 1
		if endless_runtime != null and endless_runtime.progress != null:
			endless_num = endless_runtime.progress.get_level_num()
		endless_btn.text = "Level %d" % endless_num

func _on_play() -> void:
	play_pressed.emit()

func _on_endless() -> void:
	endless_pressed.emit()

func _on_options() -> void:
	options_pressed.emit()

func _add_press_anim(button: Button) -> void:
	button.button_down.connect(func():
		button.pivot_offset = button.size * 0.5
		var tw := button.create_tween()
		tw.tween_property(button, "scale", Vector2(0.95, 0.95), 0.06)
	)
	button.button_up.connect(func():
		button.pivot_offset = button.size * 0.5
		var tw := button.create_tween()
		tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(button, "scale", Vector2.ONE, 0.15)
	)

func _on_help() -> void:
	if help_dialog != null:
		help_dialog.popup_centered(Vector2i(700, 340))

func _set_round_icon(button: Button, path: String, side: float) -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(center)
	var icon := TextureRect.new()
	icon.texture = load(path) as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2.ONE * side
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(icon)

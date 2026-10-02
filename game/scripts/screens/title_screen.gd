# title_screen.gd
extends Control

signal play_pressed()
signal options_pressed()

const Palette = preload("res://scripts/theme/palette.gd")

var runtime: Variant = null

var title_label: Label
var level_label: Label
var play_btn: Button
var options_btn: Button

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
	frame.add_child(top)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	options_btn = Button.new()
	options_btn.name = "OptionsButton"
	options_btn.custom_minimum_size = Vector2(88, 88)
	options_btn.flat = false
	options_btn.icon = load("res://assets/ui/home/icon_settings.png") as Texture2D
	options_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	options_btn.expand_icon = true
	var option_style := StyleBoxFlat.new()
	option_style.bg_color = Color.WHITE
	option_style.set_corner_radius_all(999)
	option_style.shadow_color = Palette.SHADOW_SOFT
	option_style.shadow_size = 6
	for state in ["normal", "hover", "pressed", "focus"]:
		options_btn.add_theme_stylebox_override(state, option_style)
	top.add_child(options_btn)
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(center)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 28)
	center.add_child(content)
	var logo := TextureRect.new()
	logo.name = "CandyLogo"
	logo.texture = load("res://assets/ui/board/candy.svg") as Texture2D
	logo.custom_minimum_size = Vector2(480, 240)
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(logo)
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "CanDoKu"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 76)
	title_label.add_theme_color_override("font_color", Palette.INK)
	content.add_child(title_label)
	play_btn = Button.new()
	play_btn.name = "PlayButton"
	play_btn.custom_minimum_size = Vector2(560, 114)
	play_btn.add_theme_font_size_override("font_size", 42)
	var play_style := StyleBoxFlat.new()
	play_style.bg_color = Color("#F09329")
	play_style.set_corner_radius_all(999)
	play_style.shadow_color = Color(0.94, 0.58, 0.16, 0.35)
	play_style.shadow_size = 12
	play_style.shadow_offset = Vector2(0, 4)
	play_style.set_content_margin_all(16)
	for state in ["normal", "hover", "pressed", "focus"]:
		play_btn.add_theme_stylebox_override(state, play_style)
	content.add_child(play_btn)
	level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 28)
	level_label.add_theme_color_override("font_color", Palette.TEXT_STAT)
	content.add_child(level_label)
	var save_hint := Label.new()
	save_hint.text = "Tiến trình được lưu tự động"
	save_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_hint.add_theme_font_size_override("font_size", 24)
	save_hint.add_theme_color_override("font_color", Palette.INK_LIGHT)
	content.add_child(save_hint)

func _ready() -> void:
	_ensure_nodes()
	if play_btn != null and not play_btn.pressed.is_connected(_on_play):
		play_btn.pressed.connect(_on_play)
	if options_btn != null and not options_btn.pressed.is_connected(_on_options):
		options_btn.pressed.connect(_on_options)
	_update_ui()

func setup(rt: Variant) -> void:
	runtime = rt
	_ensure_nodes()
	_update_ui()

func _update_ui() -> void:
	if runtime == null:
		return
	var label: String = runtime.current_level_label()
	var completed: int = runtime.completed_count()
	if level_label != null:
		level_label.text = "Level %s (%d hoàn thành)" % [label, completed]
	if play_btn != null:
		if runtime.is_campaign_done():
			play_btn.text = "Chơi lại chiến dịch"
		elif runtime.has_pending_session():
			play_btn.text = "Tiếp tục"
		else:
			play_btn.text = "Chơi"

func _on_play() -> void:
	play_pressed.emit()

func _on_options() -> void:
	options_pressed.emit()

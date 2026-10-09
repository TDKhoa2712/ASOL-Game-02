# title_screen.gd
extends Control

signal play_pressed()
signal endless_pressed()
signal options_pressed()
signal debug_level_selected(level_data: Dictionary, label: String)

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const DebugLevelPicker = preload("res://scripts/screens/debug_level_picker.gd")
const HelpScreen = preload("res://scripts/screens/help_screen.gd")
const GradientBg = preload("res://scripts/ui/gradient_bg.gd")
const ActionButton = preload("res://scripts/ui/action_button.gd")
const ProgressBarWidget = preload("res://scripts/ui/progress_bar.gd")
const TitleHeroMascot = preload("res://scripts/ui/title_hero_mascot.gd")
const SunburstRays = preload("res://scripts/ui/sunburst_rays.gd")
const HomeDecorations = preload("res://scripts/ui/home_decorations.gd")

var runtime: Variant = null
var endless_runtime: Variant = null

var title_label: Label
var campaign_box: VBoxContainer
var play_btn: Button
var campaign_subtitle: Label
var endless_btn: Button
var options_btn: Button
var help_btn: Button
var debug_btn: Button
var _help_overlay: Control = null
var debug_picker: DebugLevelPicker
var _hero_mascot: TitleHeroMascot = null
var _progress_bar: ProgressBarWidget = null
var _play_label: Label = null

func _ensure_nodes() -> void:
	if title_label != null: return
	var background := GradientBg.new(Palette.HOME_BG_CENTER, Palette.HOME_BG_MID, Palette.HOME_BG_EDGE, Vector2(0.5, 0.46))
	background.name = "Background"
	add_child(background)
	add_child(SunburstRays.new(Vector2(0.5, 0.51)))
	add_child(HomeDecorations.new())

	var safe := MarginContainer.new()
	safe.name = "SafeArea"
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right"]: safe.add_theme_constant_override("margin_" + s, 48)
	safe.add_theme_constant_override("margin_top", 44)
	safe.add_theme_constant_override("margin_bottom", 48)
	add_child(safe)

	var frame := VBoxContainer.new()
	frame.name = "Frame"
	frame.add_theme_constant_override("separation", 12)
	safe.add_child(frame)

	# 1. Top bar
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	frame.add_child(top)

	if OS.is_debug_build():
		debug_btn = Button.new()
		debug_btn.name = "DebugButton"
		debug_btn.text = "🐞 " + tr("title.debug").trim_prefix("🛠 ")
		debug_btn.custom_minimum_size = Vector2(160, 64)
		debug_btn.add_theme_font_size_override("font_size", 26)
		var dstyle := StyleBoxFlat.new()
		dstyle.bg_color = Color("#5E6577"); dstyle.set_corner_radius_all(18)
		dstyle.shadow_color = Color("#3B4050"); dstyle.shadow_size = 5; dstyle.shadow_offset = Vector2(0, 5)
		dstyle.content_margin_left = 18; dstyle.content_margin_right = 18
		for s in ["normal", "hover", "pressed", "focus"]: debug_btn.add_theme_stylebox_override(s, dstyle)
		top.add_child(debug_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)

	help_btn = _make_round_top_btn("HelpButton", "res://assets/ui/home/icon_help_blue.svg")
	help_btn.tooltip_text = tr("title.help_tooltip")
	top.add_child(help_btn)

	options_btn = _make_round_top_btn("OptionsButton", "res://assets/ui/home/icon_settings_blue.svg")
	top.add_child(options_btn)

	# 2. Hero: Logo
	var hero := VBoxContainer.new()
	hero.name = "HeroBlock"
	hero.alignment = BoxContainer.ALIGNMENT_CENTER
	frame.add_child(hero)

	var logo := TextureRect.new()
	logo.name = "CandyLogo"
	logo.texture = load("res://assets/ui/home/logo_candoku_vector.svg") as Texture2D
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.custom_minimum_size = Vector2(740, 320)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.add_child(logo)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = tr("title.name")
	title_label.visible = false
	hero.add_child(title_label)

	# 3. Flex Spacer 1
	var spacer1 := Control.new()
	spacer1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(spacer1)

	# 4. Hero Mascot (Centered)
	_hero_mascot = TitleHeroMascot.new()
	frame.add_child(_hero_mascot)

	# 5. Flex Spacer 2
	var spacer2 := Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(spacer2)

	# 6. Action Block (Bottom: Progress Card + Play Button)
	var actions := VBoxContainer.new()
	actions.name = "ActionBlock"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 18)
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.add_child(actions)

	_progress_bar = ProgressBarWidget.new(0, 30)
	actions.add_child(_progress_bar)

	campaign_box = VBoxContainer.new()
	campaign_box.name = "CampaignBox"
	campaign_box.alignment = BoxContainer.ALIGNMENT_CENTER
	campaign_box.add_theme_constant_override("separation", 0)
	campaign_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(campaign_box)

	var play_init_fmt := tr("title.play")
	var play_init_txt := (play_init_fmt % "1") if play_init_fmt.contains("%s") else (play_init_fmt + " 1")
	play_btn = ActionButton.create(play_init_txt, Palette.HOME_BUTTON_BG, Palette.HOME_BUTTON_SHADOW, Color("#8A3306"), 38, 108)
	play_btn.name = "PlayButton"
	_play_label = ActionButton.set_leading_icon(play_btn, "res://assets/ui/home/icon_play_white.svg")
	campaign_box.add_child(play_btn)

	campaign_subtitle = Label.new()
	campaign_subtitle.name = "CampaignSubtitle"
	campaign_subtitle.text = "1->30"
	campaign_subtitle.visible = false
	campaign_box.add_child(campaign_subtitle)

	endless_btn = ActionButton.create("Endless", Palette.PILL_BG, Palette.HOME_CARD_SHADOW, Color.TRANSPARENT, 30, 84)
	endless_btn.name = "EndlessButton"
	endless_btn.add_theme_color_override("font_color", Palette.INK)
	actions.add_child(endless_btn)

	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size.y = 24
	frame.add_child(bottom_spacer)

	if OS.is_debug_build():
		debug_picker = DebugLevelPicker.new()
		debug_picker.name = "DebugPicker"
		debug_picker.visible = false
		debug_picker.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		debug_picker.level_selected.connect(func(lvl: Dictionary, lbl: String): debug_picker.visible = false; debug_level_selected.emit(lvl, lbl))
		debug_picker.close_requested.connect(func(): debug_picker.visible = false)
		debug_picker.progress_reset.connect(func(_m): _update_ui())
		add_child(debug_picker)

func _make_round_top_btn(btn_name: String, icon_path: String) -> Button:
	var btn := Button.new()
	btn.name = btn_name
	btn.custom_minimum_size = Vector2(84, 84)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE; style.set_corner_radius_all(22)
	style.shadow_color = Color("#E2C46A"); style.shadow_size = 6; style.shadow_offset = Vector2(0, 6)
	for s in ["normal", "hover", "pressed", "focus"]: btn.add_theme_stylebox_override(s, style)
	_set_round_icon(btn, icon_path, 46)
	return btn

func _ready() -> void:
	_ensure_nodes()
	var btn_signals := [
		[play_btn, _on_play], [endless_btn, _on_endless],
		[options_btn, _on_options], [help_btn, _on_help], [debug_btn, _on_debug_pressed]
	]
	for pair in btn_signals:
		var btn: Button = pair[0]
		if btn != null and not btn.pressed.is_connected(pair[1]):
			btn.pressed.connect(pair[1])
			btn.pivot_offset = btn.size * 0.5
			btn.resized.connect(func(): btn.pivot_offset = btn.size * 0.5)
			_add_press_anim(btn)
	_update_ui()
	if _progress_bar != null: _progress_bar.animate()

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
	var camp_on: bool = GameFeatures.is_campaign_enabled()
	var endless_on: bool = GameFeatures.is_endless_enabled()
	if campaign_box != null: campaign_box.visible = camp_on
	if endless_btn != null: endless_btn.visible = endless_on
	if runtime != null:
		var label: String = runtime.current_level_label()
		if play_btn != null:
			if runtime.is_campaign_done(): play_btn.text = tr("title.replay")
			else:
				var p_fmt := tr("title.play")
				play_btn.text = (p_fmt % label.trim_prefix("L")) if p_fmt.contains("%s") else (p_fmt + " " + label.trim_prefix("L"))
			if _play_label != null: _play_label.text = play_btn.text
		if campaign_subtitle != null and runtime.has_method("playlist_order"):
			var order: Array = runtime.playlist_order()
			if not order.is_empty(): campaign_subtitle.text = "1->%d" % order.size()
		if _progress_bar != null:
			var done_cnt: int = runtime.completed_count() if runtime.has_method("completed_count") else 0
			var total_cnt: int = runtime.playlist_order().size() if runtime.has_method("playlist_order") else 30
			_progress_bar.set_progress(done_cnt, total_cnt)
	if endless_btn != null:
		var endless_num: int = 1
		if endless_runtime != null and endless_runtime.progress != null:
			endless_num = endless_runtime.progress.get_level_num()
		endless_btn.text = "Level %d" % endless_num
		if not camp_on: _style_primary_endless()

func _style_primary_endless() -> void:
	if endless_btn == null: return
	endless_btn.custom_minimum_size = Vector2(560, 100)
	endless_btn.add_theme_font_size_override("font_size", 40)
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PLAY_BUTTON; style.set_corner_radius_all(999)
	style.shadow_color = Palette.PLAY_GLOW; style.shadow_size = 12; style.shadow_offset = Vector2(0, 4)
	style.set_content_margin_all(16)
	for s in ["normal", "hover", "pressed", "focus"]: endless_btn.add_theme_stylebox_override(s, style)
	endless_btn.add_theme_color_override("font_color", Color.WHITE)

func _on_play() -> void: play_pressed.emit()
func _on_endless() -> void: endless_pressed.emit()
func _on_options() -> void: options_pressed.emit()

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
	if _help_overlay != null: return
	_help_overlay = HelpScreen.new()
	_help_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_help_overlay.back_pressed.connect(_close_help)
	add_child(_help_overlay)

func _close_help() -> void:
	if _help_overlay != null: _help_overlay.queue_free(); _help_overlay = null

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

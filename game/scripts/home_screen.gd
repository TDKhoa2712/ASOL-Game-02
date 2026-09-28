extends Control

const UiTheme = preload("res://scripts/ui_theme.gd")

@export_group("Text & Content")
@export var game_title: String = "MÈO DOKU"
@export var subtitle: String = "BỐN MÙA · BỐN VÙNG · MỘT LỜI GIẢI"
@export var play_text: String = "Tiếp Tục"
@export var level_format: String = "Màn %s"
@export var daily_text: String = "Thử Thách Hằng Ngày"
@export var daily_timer_text: String = "09:48:34"
@export var event_timer_text: String = "23:50:22"
@export var currency_count: int = 7

@export_group("Colors & Theme")
@export var primary_color: Color = Color("#F28D24")
@export var primary_pressed: Color = Color("#D87815")
@export var secondary_color: Color = Color("#859CF8")
@export var secondary_pressed: Color = Color("#6F86E5")
@export var timer_badge_color: Color = Color("#6B82E6")
@export var event_badge_bg: Color = Color("#3B3435")
@export var text_dark_color: Color = Color("#6D4A45")
@export var text_light_color: Color = Color("#FFFFFF")
@export var button_corner_radius: int = 44

@export_group("Visibility")
@export var show_avatar: bool = true
@export var show_currency: bool = true
@export var show_top_settings: bool = true
@export var show_hero_card: bool = false
@export var show_title_text: bool = false
@export var show_event_badge: bool = true
@export var show_current_level_label: bool = false
@export var show_daily_challenge: bool = true
@export var show_bottom_buttons: bool = false
@export var show_help_button: bool = true
@export var show_settings_button: bool = true
@export var show_progress_hint: bool = false

@export_group("Config File")
@export var config_file_path: String = "res://data/home_ui_config.json"
@export var use_external_config: bool = true

var _current_level_id: String = "1"


func _ready() -> void:
	if use_external_config:
		_load_from_json()
	apply_configuration()
	_wire_internal_signals()


func _load_from_json() -> void:
	if not FileAccess.file_exists(config_file_path):
		return
	var file = FileAccess.open(config_file_path, FileAccess.READ)
	if file == null:
		return
	var content = file.get_as_text()
	var json = JSON.new()
	if json.parse(content) != OK or not (json.data is Dictionary):
		return
	var data: Dictionary = json.data
	if data.has("theme") and data["theme"] is Dictionary:
		var theme_dict: Dictionary = data["theme"]
		if theme_dict.has("primary_button_color"):
			primary_color = Color(theme_dict["primary_button_color"])
		if theme_dict.has("primary_button_pressed"):
			primary_pressed = Color(theme_dict["primary_button_pressed"])
		if theme_dict.has("secondary_button_color"):
			secondary_color = Color(theme_dict["secondary_button_color"])
		if theme_dict.has("secondary_button_pressed"):
			secondary_pressed = Color(theme_dict["secondary_button_pressed"])
		if theme_dict.has("timer_badge_color"):
			timer_badge_color = Color(theme_dict["timer_badge_color"])
		if theme_dict.has("event_badge_bg"):
			event_badge_bg = Color(theme_dict["event_badge_bg"])
		if theme_dict.has("text_dark_color"):
			text_dark_color = Color(theme_dict["text_dark_color"])
		if theme_dict.has("button_corner_radius"):
			button_corner_radius = int(theme_dict["button_corner_radius"])
	if data.has("content") and data["content"] is Dictionary:
		var content_dict: Dictionary = data["content"]
		if content_dict.has("game_title"):
			game_title = str(content_dict["game_title"])
		if content_dict.has("subtitle"):
			subtitle = str(content_dict["subtitle"])
		if content_dict.has("play_button_text"):
			play_text = str(content_dict["play_button_text"])
		if content_dict.has("level_format"):
			level_format = str(content_dict["level_format"])
		if content_dict.has("daily_challenge_text"):
			daily_text = str(content_dict["daily_challenge_text"])
		if content_dict.has("daily_timer"):
			daily_timer_text = str(content_dict["daily_timer"])
		if content_dict.has("event_timer"):
			event_timer_text = str(content_dict["event_timer"])
		if content_dict.has("currency_count"):
			currency_count = int(content_dict["currency_count"])
	if data.has("visibility") and data["visibility"] is Dictionary:
		var vis: Dictionary = data["visibility"]
		if vis.has("show_avatar"):
			show_avatar = bool(vis["show_avatar"])
		if vis.has("show_currency"):
			show_currency = bool(vis["show_currency"])
		if vis.has("show_top_settings"):
			show_top_settings = bool(vis["show_top_settings"])
		if vis.has("show_hero_card"):
			show_hero_card = bool(vis["show_hero_card"])
		if vis.has("show_title_text"):
			show_title_text = bool(vis["show_title_text"])
		if vis.has("show_event_badge"):
			show_event_badge = bool(vis["show_event_badge"])
		if vis.has("show_current_level_label"):
			show_current_level_label = bool(vis["show_current_level_label"])
		if vis.has("show_daily_challenge"):
			show_daily_challenge = bool(vis["show_daily_challenge"])
		if vis.has("show_bottom_buttons"):
			show_bottom_buttons = bool(vis["show_bottom_buttons"])
		if vis.has("show_help_button"):
			show_help_button = bool(vis["show_help_button"])
		if vis.has("show_settings_button"):
			show_settings_button = bool(vis["show_settings_button"])
		if vis.has("show_progress_hint"):
			show_progress_hint = bool(vis["show_progress_hint"])


func apply_configuration() -> void:
	# Top bar
	var avatar = get_node_or_null("SafeArea/TopBar/AvatarContainer")
	if avatar != null:
		avatar.visible = show_avatar
	var currency = get_node_or_null("SafeArea/TopBar/CurrencyBadge")
	if currency != null:
		currency.visible = show_currency
		var count_lbl: Label = currency.get_node_or_null("HBox/CountLabel")
		if count_lbl != null:
			count_lbl.text = str(currency_count)
	var top_settings = get_node_or_null("SafeArea/TopBar/TopSettingsButton")
	if top_settings != null:
		top_settings.visible = show_top_settings

	# Hero Card & Title
	var hero_card = get_node_or_null("SafeArea/Content/Stack/HeroCard")
	if hero_card != null:
		hero_card.visible = show_hero_card
	var hero_lbl: Label = get_node_or_null("SafeArea/Content/Stack/HeroCard/HeroText")
	if hero_lbl != null:
		hero_lbl.text = subtitle

	var title_lbl: Label = get_node_or_null("SafeArea/Content/Stack/Title")
	if title_lbl != null:
		title_lbl.visible = show_title_text
		title_lbl.text = game_title
		title_lbl.add_theme_color_override("font_color", text_dark_color)

	# Event Badge
	var event_badge = get_node_or_null("SafeArea/Content/Stack/EventRow/EventBadge")
	if event_badge != null:
		event_badge.visible = show_event_badge
		if "timer_text" in event_badge:
			event_badge.timer_text = event_timer_text
			event_badge.queue_redraw()

	# Current level label (optional separate label)
	var cur_lvl_lbl = get_node_or_null("SafeArea/Content/Stack/CurrentLevelLabel")
	if cur_lvl_lbl != null:
		cur_lvl_lbl.visible = show_current_level_label

	# Play Button
	var play_btn: Button = get_node_or_null("SafeArea/Content/Stack/PlayButton")
	if play_btn != null:
		var play_style := StyleBoxFlat.new()
		play_style.bg_color = primary_color
		play_style.set_corner_radius_all(button_corner_radius)
		play_style.shadow_color = Color(primary_color.r * 0.7, primary_color.g * 0.4, primary_color.b * 0.2, 0.35)
		play_style.shadow_size = 14
		play_style.shadow_offset = Vector2(0, 8)
		play_style.content_margin_top = 16.0
		play_style.content_margin_bottom = 16.0
		play_style.content_margin_left = 32.0
		play_style.content_margin_right = 32.0
		var play_pressed_style: StyleBoxFlat = play_style.duplicate()
		play_pressed_style.bg_color = primary_pressed
		play_btn.add_theme_stylebox_override("normal", play_style)
		play_btn.add_theme_stylebox_override("hover", play_style)
		play_btn.add_theme_stylebox_override("pressed", play_pressed_style)

		# Display two lines: "Tiếp Tục\nMàn %s"
		var display_level: String = _current_level_id
		if display_level.begins_with("L0"):
			display_level = str(int(display_level.substr(1)))
		elif display_level.begins_with("L"):
			display_level = str(int(display_level.substr(1)))
		play_btn.text = "%s\n%s" % [play_text, level_format % display_level]

	# Daily Challenge
	var daily_box = get_node_or_null("SafeArea/Content/Stack/DailyContainer")
	if daily_box != null:
		daily_box.visible = show_daily_challenge
		var daily_btn: Button = daily_box.get_node_or_null("DailyButton")
		if daily_btn != null:
			var daily_style := StyleBoxFlat.new()
			daily_style.bg_color = secondary_color
			daily_style.set_corner_radius_all(button_corner_radius)
			daily_style.shadow_color = Color(secondary_color.r * 0.6, secondary_color.g * 0.6, secondary_color.b * 0.9, 0.28)
			daily_style.shadow_size = 12
			daily_style.shadow_offset = Vector2(0, 7)
			daily_style.content_margin_top = 18.0
			daily_style.content_margin_bottom = 18.0
			daily_btn.add_theme_stylebox_override("normal", daily_style)
			daily_btn.add_theme_stylebox_override("hover", daily_style)
			var daily_pressed_style: StyleBoxFlat = daily_style.duplicate()
			daily_pressed_style.bg_color = secondary_pressed
			daily_btn.add_theme_stylebox_override("pressed", daily_pressed_style)
			daily_btn.text = daily_text
		var daily_timer_pill = daily_box.get_node_or_null("DailyTimerPill")
		if daily_timer_pill != null:
			var pill_style := StyleBoxFlat.new()
			pill_style.bg_color = timer_badge_color
			pill_style.set_corner_radius_all(20)
			pill_style.content_margin_left = 16.0
			pill_style.content_margin_right = 16.0
			pill_style.content_margin_top = 4.0
			pill_style.content_margin_bottom = 4.0
			daily_timer_pill.add_theme_stylebox_override("panel", pill_style)
			var daily_timer_lbl: Label = daily_timer_pill.get_node_or_null("TimerLabel")
			if daily_timer_lbl != null:
				daily_timer_lbl.text = "⏱ " + daily_timer_text

	# Help & Settings & ProgressHint
	var help_btn = get_node_or_null("SafeArea/Content/Stack/HelpButton")
	if help_btn != null:
		help_btn.visible = show_bottom_buttons and show_help_button
	var settings_btn = get_node_or_null("SafeArea/Content/Stack/SettingsButton")
	if settings_btn != null:
		settings_btn.visible = show_bottom_buttons and show_settings_button
	var hint = get_node_or_null("SafeArea/Content/Stack/ProgressHint")
	if hint != null:
		hint.visible = show_progress_hint


func update_level(level_id: String) -> void:
	_current_level_id = level_id
	var play_btn: Button = get_node_or_null("SafeArea/Content/Stack/PlayButton")
	if play_btn != null:
		var display_level: String = level_id
		if display_level.begins_with("L0"):
			display_level = str(int(display_level.substr(1)))
		elif display_level.begins_with("L"):
			display_level = str(int(display_level.substr(1)))
		play_btn.text = "%s\n%s" % [play_text, level_format % display_level]
	var current_level_label := get_node_or_null("SafeArea/Content/Stack/CurrentLevelLabel")
	if current_level_label is Label:
		current_level_label.text = "Level hiện tại: %s" % level_id


func _wire_internal_signals() -> void:
	var top_settings = get_node_or_null("SafeArea/TopBar/TopSettingsButton")
	var stack_settings = get_node_or_null("SafeArea/Content/Stack/SettingsButton")
	if top_settings != null and stack_settings != null:
		if not top_settings.pressed.is_connected(_on_top_settings_pressed):
			top_settings.pressed.connect(_on_top_settings_pressed)


func _on_top_settings_pressed() -> void:
	var stack_settings = get_node_or_null("SafeArea/Content/Stack/SettingsButton")
	if stack_settings != null:
		stack_settings.emit_signal("pressed")

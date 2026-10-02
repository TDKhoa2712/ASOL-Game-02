extends Control

const SettingsScript = preload("res://scripts/settings.gd")

@export_group("Text & Content")
@export var game_title: String = "CanDoKu"
@export var tagline: String = "TÌM KẸO BỊ ĐÁNH RƠI TRONG VƯỜN"
@export var play_text_fresh: String = "Chơi"
@export var play_text_resume: String = "Tiếp Tục"
@export var play_text_complete: String = "Chơi lại từ L01"
@export var level_format: String = "Level %s"

@export_group("Feature Flags")
@export var show_top_settings: bool = true
@export var show_tagline: bool = false
@export var show_progress_hint: bool = true

@export_group("External Config")
@export var config_file_path: String = "res://data/home_ui_config.json"
@export var use_external_config: bool = true

var _current_level_id: String = "1"
var _campaign_complete: bool = false
var _settings: SettingsScript


func _ready() -> void:
	_settings = SettingsScript.new()
	if use_external_config:
		_load_from_json()
	apply_configuration()
	_wire_signals_and_tweens()


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
	if data.has("content") and data["content"] is Dictionary:
		var c: Dictionary = data["content"]
		if c.has("game_title"): game_title = str(c["game_title"])
		if c.has("tagline"): tagline = str(c["tagline"])
		if c.has("play_button_text"): play_text_resume = str(c["play_button_text"])
		if c.has("level_format"): level_format = str(c["level_format"])
	if data.has("visibility") and data["visibility"] is Dictionary:
		var v: Dictionary = data["visibility"]
		if v.has("show_top_settings"): show_top_settings = bool(v["show_top_settings"])
		if v.has("show_tagline"): show_tagline = bool(v["show_tagline"])
		if v.has("show_progress_hint"): show_progress_hint = bool(v["show_progress_hint"])


func apply_configuration() -> void:
	# Top bar
	var top_settings = get_node_or_null("SafeArea/TopBar/TopSettingsButton")
	if top_settings != null:
		top_settings.visible = show_top_settings

	# Logo & Title
	var logo_img: TextureRect = get_node_or_null("SafeArea/Content/Stack/LogoBlock/LogoImage")
	var title_lbl: Label = get_node_or_null("SafeArea/Content/Stack/Title")
	if logo_img != null and title_lbl != null:
		if logo_img.texture != null:
			logo_img.visible = true
			title_lbl.visible = true
			title_lbl.text = game_title
		else:
			logo_img.visible = false
			title_lbl.visible = true
			title_lbl.text = game_title

	var tagline_card = get_node_or_null("SafeArea/Content/Stack/HeroCard")
	if tagline_card != null:
		tagline_card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		tagline_card.visible = show_tagline
		var hero_text: Label = tagline_card.get_node_or_null("HeroText")
		if hero_text != null:
			hero_text.text = tagline

	# Progress Hint
	var hint = get_node_or_null("SafeArea/Content/Stack/ProgressHint")
	if hint != null:
		hint.visible = show_progress_hint

	_refresh_play_button_text()


func set_campaign_state(level_id, is_complete: bool) -> void:
	_campaign_complete = is_complete
	if level_id != null:
		_current_level_id = str(level_id)
	_refresh_play_button_text()


func update_level(level_id: String) -> void:
	_current_level_id = level_id
	_refresh_play_button_text()


func _refresh_play_button_text() -> void:
	var play_btn: Button = get_node_or_null("SafeArea/Content/Stack/PlayButton")
	if play_btn == null:
		return
	if _campaign_complete:
		play_btn.text = "%s\n%s" % [play_text_complete, "Đã hoàn thành các level"]
	else:
		var display_id := _current_level_id
		if display_id.begins_with("L0"):
			display_id = str(int(display_id.substr(1)))
		elif display_id.begins_with("L"):
			display_id = str(int(display_id.substr(1)))
		var is_first: bool = (display_id == "1" or display_id == "01")
		var main_action := play_text_fresh if is_first else play_text_resume
		play_btn.text = "%s\n%s" % [main_action, level_format % display_id]


func _wire_signals_and_tweens() -> void:
	var top_settings = get_node_or_null("SafeArea/TopBar/TopSettingsButton")
	var stack_settings = get_node_or_null("SafeArea/Content/Stack/SettingsButton")
	if top_settings != null and stack_settings != null:
		if not top_settings.pressed.is_connected(_on_top_settings_pressed):
			top_settings.pressed.connect(_on_top_settings_pressed)

	# Wire interactive micro-animation for buttons
	var play_btn: Button = get_node_or_null("SafeArea/Content/Stack/PlayButton")
	_wire_button_tween(play_btn)
	var help_btn: Button = get_node_or_null("SafeArea/Content/Stack/HelpButton")
	_wire_button_tween(help_btn)
	if top_settings != null:
		_wire_button_tween(top_settings)


func _on_top_settings_pressed() -> void:
	var stack_settings = get_node_or_null("SafeArea/Content/Stack/SettingsButton")
	if stack_settings != null:
		stack_settings.emit_signal("pressed")


func _wire_button_tween(btn: Button) -> void:
	if btn == null:
		return
	btn.pivot_offset = btn.custom_minimum_size * 0.5
	btn.resized.connect(func(): btn.pivot_offset = btn.size * 0.5)
	btn.button_down.connect(func():
		if _is_reduced_motion():
			return
		var t = create_tween()
		t.tween_property(btn, "scale", Vector2(0.96, 0.96), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.button_up.connect(func():
		if _is_reduced_motion():
			btn.scale = Vector2.ONE
			return
		var t = create_tween()
		t.tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)


func _is_reduced_motion() -> bool:
	if _settings != null:
		return _settings.is_reduced_motion()
	return false

# title_screen.gd
extends Control

signal play_pressed()
signal options_pressed()

var runtime: Variant = null

var title_label: Label
var level_label: Label
var play_btn: Button
var options_btn: Button

func _ensure_nodes() -> void:
	if title_label == null:
		title_label = get_node_or_null("SafeArea/VBox/TitleLabel") as Label
	if level_label == null:
		level_label = get_node_or_null("SafeArea/VBox/LevelLabel") as Label
	if play_btn == null:
		play_btn = get_node_or_null("SafeArea/VBox/PlayButton") as Button
	if options_btn == null:
		options_btn = get_node_or_null("OptionsButton") as Button

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

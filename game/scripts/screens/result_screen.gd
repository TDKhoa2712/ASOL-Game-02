# result_screen.gd
extends Control

signal next_pressed()
signal retry_pressed()
signal home_pressed()
signal replay_pressed()

const Palette = preload("res://scripts/theme/palette.gd")

var _is_win: bool = false
var _score: int = 0
var _level_id: String = ""
var _is_last_level: bool = false

var message_label: Label
var score_label: Label
var next_btn: Button
var retry_btn: Button
var home_btn: Button
var replay_btn: Button
var _background: ColorRect
var _card: PanelContainer

func _ensure_nodes() -> void:
	if message_label != null:
		return
	_background = ColorRect.new()
	_background.name = "Background"
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)
	var safe := MarginContainer.new()
	safe.name = "SafeArea"
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		safe.add_theme_constant_override("margin_" + side, 32)
	add_child(safe)
	var center := CenterContainer.new()
	safe.add_child(center)
	_card = PanelContainer.new()
	_card.name = "ResultCard"
	_card.custom_minimum_size = Vector2(620, 560)
	center.add_child(_card)
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.BG_CREAM
	style.set_corner_radius_all(24)
	style.set_content_margin_all(40)
	style.shadow_color = Palette.CARD_SHADOW
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 4)
	_card.add_theme_stylebox_override("panel", style)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 24)
	_card.add_child(stack)
	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 54)
	message_label.add_theme_color_override("font_color", Palette.INK)
	stack.add_child(message_label)
	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 30)
	score_label.add_theme_color_override("font_color", Palette.TEXT_STAT)
	stack.add_child(score_label)
	next_btn = _make_button("NextBtn", "Tiếp tục")
	stack.add_child(next_btn)
	retry_btn = _make_button("RetryBtn", "Thử lại")
	stack.add_child(retry_btn)
	replay_btn = _make_button("ReplayBtn", "Chơi lại")
	stack.add_child(replay_btn)
	home_btn = _make_button("HomeBtn", "Trang chủ")
	stack.add_child(home_btn)

func _make_button(node_name: String, caption: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = caption
	button.custom_minimum_size = Vector2(460, 88)
	button.add_theme_font_size_override("font_size", 32)
	return button

func _ready() -> void:
	_ensure_nodes()
	if next_btn != null and not next_btn.pressed.is_connected(_on_next):
		next_btn.pressed.connect(_on_next)
	if retry_btn != null and not retry_btn.pressed.is_connected(_on_retry):
		retry_btn.pressed.connect(_on_retry)
	if home_btn != null and not home_btn.pressed.is_connected(_on_home):
		home_btn.pressed.connect(_on_home)
	if replay_btn != null and not replay_btn.pressed.is_connected(_on_replay):
		replay_btn.pressed.connect(_on_replay)
	_update_ui()

func setup(won: bool, score: int, level_id: String, is_last: bool) -> void:
	_is_win = won
	_score = score
	_level_id = level_id
	_is_last_level = is_last
	_ensure_nodes()
	_update_ui()

func _update_ui() -> void:
	if _background != null:
		_background.color = Color("#E2F1E8") if _is_win else Color("#FCECE2")
	if message_label != null:
		if _is_win:
			message_label.text = "Hoàn thành chiến dịch!" if _is_last_level else "Hoàn hồi!"
		else:
			message_label.text = "Hết tim"
	if score_label != null:
		if _is_win:
			var sec: int = int(_score / 1000.0) if _score > 1000 else _score
			score_label.text = "Level %s • %ds" % [_level_id, sec]
		else:
			score_label.text = "Level %s" % [_level_id]
	if next_btn != null:
		next_btn.visible = _is_win and not _is_last_level
	if retry_btn != null:
		retry_btn.visible = not _is_win
	if replay_btn != null:
		replay_btn.visible = _is_win and _is_last_level
	for button in [next_btn, retry_btn, replay_btn, home_btn]:
		if button == null:
			continue
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#55A683") if _is_win else Color("#F49359")
		if button == home_btn:
			style.bg_color = Color.WHITE
		style.set_corner_radius_all(999)
		style.set_content_margin_all(14)
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)
		button.add_theme_color_override("font_color", Palette.INK if button == home_btn else Color.WHITE)

func _on_next() -> void:
	next_pressed.emit()

func _on_retry() -> void:
	retry_pressed.emit()

func _on_home() -> void:
	home_pressed.emit()

func _on_replay() -> void:
	replay_pressed.emit()

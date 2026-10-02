# result_screen.gd
extends Control

signal next_pressed()
signal retry_pressed()
signal home_pressed()
signal replay_pressed()

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

func _ensure_nodes() -> void:
	if message_label == null:
		message_label = find_child("MessageLabel", true, false) as Label
	if score_label == null:
		score_label = find_child("ScoreLabel", true, false) as Label
	if next_btn == null:
		next_btn = find_child("NextBtn", true, false) as Button
	if retry_btn == null:
		retry_btn = find_child("RetryBtn", true, false) as Button
	if home_btn == null:
		home_btn = find_child("HomeBtn", true, false) as Button
	if replay_btn == null:
		replay_btn = find_child("ReplayBtn", true, false) as Button

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
	if message_label != null:
		if _is_win:
			message_label.text = "Hoàn thành chiến dịch!" if _is_last_level else "Thành công!"
		else:
			message_label.text = "Thất bại!"
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

func _on_next() -> void:
	next_pressed.emit()

func _on_retry() -> void:
	retry_pressed.emit()

func _on_home() -> void:
	home_pressed.emit()

func _on_replay() -> void:
	replay_pressed.emit()

extends Control


const GestureEngineScript = preload("res://scripts/gesture_engine.gd")
const BoardViewScript = preload("res://scripts/board_view.gd")
const LEVEL_PATH := "res://data/t01.json"
const CONTRACT_PATH := "res://tests/fixtures/interactions.v2.json"


var level: Dictionary
var contract: Dictionary
var engine
var hearts_label: Label
var status_label: Label
var undo_button: Button
var restart_dialog: ConfirmationDialog
var board_view


func _ready() -> void:
	level = _read_json(LEVEL_PATH)
	contract = _read_json(CONTRACT_PATH)
	engine = GestureEngineScript.new(level, contract)
	engine.session.changed.connect(_refresh)
	engine.changed.connect(_refresh)
	_build_interface()
	_refresh()


func get_session():
	return engine.session


func undo_last_x() -> void:
	_settle_input()
	engine.session.apply_action({"type": "UndoX"})


func request_restart() -> void:
	_settle_input()
	restart_dialog.popup_centered(Vector2i(650, 260))


func cancel_restart() -> void:
	restart_dialog.hide()


func confirm_restart() -> void:
	engine.cancel_all()
	engine.session.apply_action({"type": "RestartLevel"})
	restart_dialog.hide()


func _settle_input() -> void:
	if engine.active_pointer != -1:
		engine.cancel_active()
	if engine.pending_tap:
		engine.flush_pending()


func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Color("#F5F1E8")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 70)
	margin.add_theme_constant_override("margin_right", 70)
	margin.add_theme_constant_override("margin_top", 70)
	margin.add_theme_constant_override("margin_bottom", 58)
	add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 25)
	margin.add_child(content)

	var title := Label.new()
	title.text = "KHU VƯỜN BỐN MÙA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color("#344054"))
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Prototype tương tác T01 · Chạm, chạm đôi và kéo"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 25)
	subtitle.add_theme_color_override("font_color", Color("#667085"))
	content.add_child(subtitle)

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 20)
	content.add_child(top_bar)

	hearts_label = Label.new()
	hearts_label.name = "HeartsLabel"
	hearts_label.add_theme_font_size_override("font_size", 30)
	hearts_label.add_theme_color_override("font_color", Color("#B42318"))
	top_bar.add_child(hearts_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.add_theme_font_size_override("font_size", 26)
	status_label.add_theme_color_override("font_color", Color("#475467"))
	top_bar.add_child(status_label)

	var board_center := CenterContainer.new()
	board_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(board_center)

	board_view = BoardViewScript.new()
	board_view.name = "BoardView"
	board_view.configure(engine, level)
	board_center.add_child(board_view)

	var guide := Label.new()
	guide.text = "Chạm: đánh / xóa X     ·     Chạm đôi: thử đặt mèo     ·     Kéo: đánh dấu nhiều ô"
	guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide.add_theme_font_size_override("font_size", 23)
	guide.add_theme_color_override("font_color", Color("#667085"))
	content.add_child(guide)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 28)
	content.add_child(actions)

	undo_button = _make_button("UndoButton", "Hoàn tác", Color("#FFFFFF"), Color("#344054"))
	undo_button.pressed.connect(undo_last_x)
	actions.add_child(undo_button)

	var restart_button := _make_button("RestartButton", "Chơi lại", Color("#344054"), Color.WHITE)
	restart_button.pressed.connect(request_restart)
	actions.add_child(restart_button)

	var note := Label.new()
	note.text = "Bản prototype dùng hình vector tạm thời · chạy trực tiếp trong Godot Editor"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 20)
	note.add_theme_color_override("font_color", Color("#98A2B3"))
	content.add_child(note)

	restart_dialog = ConfirmationDialog.new()
	restart_dialog.name = "RestartDialog"
	restart_dialog.title = "Chơi lại màn T01?"
	restart_dialog.dialog_text = "Toàn bộ đánh dấu và số lỗi trong lượt hiện tại sẽ được xóa."
	restart_dialog.get_ok_button().text = "Chơi lại"
	restart_dialog.get_cancel_button().text = "Giữ nguyên"
	restart_dialog.confirmed.connect(confirm_restart)
	restart_dialog.canceled.connect(cancel_restart)
	add_child(restart_dialog)


func _make_button(node_name: String, text_value: String, fill: Color, ink: Color) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text_value
	button.custom_minimum_size = Vector2(260.0, 84.0)
	button.add_theme_font_size_override("font_size", 27)
	button.add_theme_color_override("font_color", ink)
	button.add_theme_color_override("font_hover_color", ink)
	button.add_theme_stylebox_override("normal", _button_style(fill))
	button.add_theme_stylebox_override("hover", _button_style(fill.lightened(0.06)))
	button.add_theme_stylebox_override("pressed", _button_style(fill.darkened(0.08)))
	button.add_theme_stylebox_override("disabled", _button_style(Color("#E4E7EC")))
	return button


func _button_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color("#D0D5DD")
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	return style


func _refresh() -> void:
	if hearts_label == null:
		return
	var state: Dictionary = engine.session.public_state()
	hearts_label.text = "Lượt sai còn lại: %d / 3" % int(state["hearts"])
	undo_button.disabled = not bool(state["undoAvailable"])
	var events: Array = state["events"]
	var latest := str(events[-1]) if not events.is_empty() else "Sẵn sàng"
	status_label.text = _status_text(latest)
	board_view.queue_redraw()


func _status_text(event_name: String) -> String:
	return {
		"Sẵn sàng": "Sẵn sàng",
		"MarkX": "Đã đánh dấu X",
		"ClearX": "Đã xóa X",
		"MarkStroke": "Đã cập nhật dải ô",
		"CatPlaced": "Đúng rồi!",
		"Mistake": "Ô này chưa đúng",
		"UndoApplied": "Đã hoàn tác",
		"UndoUnavailable": "Không có bước X để hoàn tác",
		"Restarted": "Đã bắt đầu lại",
	}.get(event_name, "Đang chơi")


func _read_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(parsed is Dictionary, "Invalid JSON object: %s" % path)
	return parsed

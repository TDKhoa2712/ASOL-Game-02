extends Control


const GestureEngineScript = preload("res://scripts/gesture_engine.gd")
const BoardViewScript = preload("res://scripts/board_view.gd")
const LEVEL_PATH := "res://data/t01.json"
const CONTRACT_PATH := "res://tests/fixtures/interactions.v2.json"


var configured_level: Dictionary = {}
var configured_contract: Dictionary = {}
var configured_engine
var runtime_controller
var level: Dictionary = {}
var contract: Dictionary = {}
var engine
var hearts_label: Label
var status_label: Label
var tutorial_label: Label
var undo_button: Button
var hint_button: Button
var hint_label: Label
var close_hint_button: Button
var region_labels: Dictionary = {}
var restart_dialog: ConfirmationDialog
var board_view
var last_terminal_event := ""
var hint_explanation_closed := false


func configure(level_data: Dictionary, engine_instance = null, runtime = null, contract_data: Dictionary = {}) -> void:
	configured_level = level_data.duplicate(true)
	configured_engine = engine_instance
	runtime_controller = runtime
	configured_contract = contract_data.duplicate(true)


func _ready() -> void:
	level = configured_level if not configured_level.is_empty() else _read_json(LEVEL_PATH)
	contract = configured_contract if not configured_contract.is_empty() else _read_json(CONTRACT_PATH)
	engine = configured_engine if configured_engine != null else GestureEngineScript.new(level, contract)
	engine.session.changed.connect(_refresh)
	engine.changed.connect(_refresh)
	_build_interface()
	_refresh()


func get_session():
	return engine.session if engine != null else null


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
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)

	var title := Label.new()
	title.text = "KHU VƯỜN BỐN MÙA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color("#344054"))
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Level %s · Chạm, chạm đôi và kéo" % str(level.get("id", ""))
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
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 26)
	status_label.add_theme_color_override("font_color", Color("#475467"))
	top_bar.add_child(status_label)

	tutorial_label = Label.new()
	tutorial_label.name = "TutorialLabel"
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_label.add_theme_font_size_override("font_size", 24)
	tutorial_label.add_theme_color_override("font_color", Color("#344054"))
	content.add_child(tutorial_label)

	var rules := GridContainer.new()
	rules.name = "RuleStrip"
	rules.columns = 2
	rules.add_theme_constant_override("h_separation", 14)
	rules.add_theme_constant_override("v_separation", 6)
	for rule_text in ["↔ 1 mèo mỗi hàng", "↕ 1 mèo mỗi cột", "▧ 1 mèo mỗi vùng", "◇ Mèo không chạm góc"]:
		var rule := Label.new()
		rule.text = rule_text
		rule.custom_minimum_size = Vector2(460, 36)
		rule.add_theme_font_size_override("font_size", 22)
		rule.add_theme_color_override("font_color", Color("#344054"))
		rules.add_child(rule)
	content.add_child(rules)

	var board_center := CenterContainer.new()
	board_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(board_center)

	board_view = BoardViewScript.new()
	board_view.name = "BoardView"
	board_view.configure(engine, level)
	board_center.add_child(board_view)

	var region_progress := HBoxContainer.new()
	region_progress.name = "RegionProgress"
	region_progress.alignment = BoxContainer.ALIGNMENT_CENTER
	region_progress.add_theme_constant_override("separation", 10)
	for index in range(int(level["size"])):
		var region_id := char(65 + index)
		var slot := Label.new()
		slot.name = "Region%s" % region_id
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.custom_minimum_size = Vector2(100, 54)
		slot.add_theme_font_size_override("font_size", 23)
		slot.add_theme_color_override("font_color", Color("#344054"))
		region_progress.add_child(slot)
		region_labels[region_id] = slot
	content.add_child(region_progress)

	var guide := Label.new()
	guide.text = "Chạm: đánh / xóa X     ·     Chạm đôi: thử đặt mèo     ·     Kéo: đánh dấu nhiều ô"
	guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide.add_theme_font_size_override("font_size", 23)
	guide.add_theme_color_override("font_color", Color("#667085"))
	content.add_child(guide)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 20)
	content.add_child(actions)

	undo_button = _make_button("UndoButton", "Hoàn tác", Color("#FFFFFF"), Color("#344054"))
	undo_button.pressed.connect(undo_last_x)
	actions.add_child(undo_button)

	hint_button = _make_button("HintButton", "Gợi ý", Color("#FFF7D6"), Color("#344054"))
	hint_button.pressed.connect(_on_hint_pressed)
	actions.add_child(hint_button)

	var restart_button := _make_button("RestartButton", "Chơi lại", Color("#344054"), Color.WHITE)
	restart_button.pressed.connect(request_restart)
	actions.add_child(restart_button)

	var home_button := _make_button("HomeButton", "Về Home", Color("#FFFFFF"), Color("#344054"))
	home_button.pressed.connect(_on_home_pressed)
	actions.add_child(home_button)

	var info_actions := HBoxContainer.new()
	info_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	info_actions.add_theme_constant_override("separation", 20)
	content.add_child(info_actions)
	var help_button := _make_button("HelpButton", "Trợ giúp", Color("#FFFFFF"), Color("#344054"))
	help_button.pressed.connect(_on_help_pressed)
	info_actions.add_child(help_button)
	var settings_button := _make_button("SettingsButton", "Cài đặt", Color("#FFFFFF"), Color("#344054"))
	settings_button.pressed.connect(_on_settings_pressed)
	info_actions.add_child(settings_button)

	hint_label = Label.new()
	hint_label.name = "HintLabel"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", 21)
	hint_label.add_theme_color_override("font_color", Color("#475467"))
	content.add_child(hint_label)
	close_hint_button = _make_button("CloseHintButton", "Đóng gợi ý", Color("#FFFFFF"), Color("#344054"))
	close_hint_button.visible = false
	close_hint_button.pressed.connect(_on_close_hint_pressed)
	content.add_child(close_hint_button)

	restart_dialog = ConfirmationDialog.new()
	restart_dialog.name = "RestartDialog"
	restart_dialog.title = "Chơi lại màn %s?" % str(level.get("id", ""))
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
	button.custom_minimum_size = Vector2(210.0, 84.0)
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
	hint_button.disabled = int(state["hintCount"]) > 0
	var events: Array = state["events"]
	var latest := str(events[-1]) if not events.is_empty() else "Sẵn sàng"
	status_label.text = _status_text(latest)
	_refresh_region_progress()
	if runtime_controller != null and level.get("id") == "L01":
		var step: String = runtime_controller.tutorial_controller.current_step(runtime_controller.tutorial_state)
		tutorial_label.text = {
			"T1": "Hướng dẫn: chạm ô đang sáng để đánh X.",
			"T2": "Chạm lại ô đó để xóa X.",
			"T3": "Kéo qua ít nhất hai ô để đánh dấu nhiều X.",
			"T4": "Chạm đôi ô mèo đang sáng để xác nhận.",
			"T5": "Mở Trợ giúp để xem bốn luật và ví dụ X đỏ.",
			"T6": "Mở Gợi ý để xem cách suy luận.",
		}.get(step, "")
		board_view.tutorial_highlight = (
			runtime_controller.tutorial_state.get("tutorialHighlight", []).duplicate() if step in ["T1", "T2"]
			else runtime_controller.tutorial_state.get("tutorialCatCell", []).duplicate() if step == "T4"
			else []
		)
	if hint_label != null and latest == "HintShown" and runtime_controller != null and not hint_explanation_closed:
		hint_label.text = _hint_text(runtime_controller.last_hint)
		close_hint_button.visible = true
	if runtime_controller != null and int(state["hintCount"]) > 0 and level.get("id") == "L01":
		var step: String = runtime_controller.tutorial_controller.current_step(runtime_controller.tutorial_state)
		if step == "T6" and not close_hint_button.visible and not hint_explanation_closed:
			hint_label.text = "Gợi ý đã dùng trong lượt này. Đóng phần giải thích để tiếp tục."
			close_hint_button.visible = true
	board_view.queue_redraw()


func _refresh_region_progress() -> void:
	var found: Dictionary = {}
	for row in range(int(level["size"])):
		for column in range(int(level["size"])):
			var cell := [row, column]
			if engine.session.is_given(cell) or engine.session.cell_state(cell) == "cat":
				found[str(level["regions"][row]).substr(column, 1)] = true
	for region_id in region_labels:
		var slot: Label = region_labels[region_id]
		var complete: bool = found.has(region_id)
		slot.text = "%s  %s" % ["●" if complete else "○", region_id]
		slot.tooltip_text = "Vùng %s: %s" % [region_id, "đã tìm mèo" if complete else "chưa tìm mèo"]
		slot.add_theme_color_override("font_color", Color("#344054") if complete else Color("#667085"))


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
		"LevelWon": "Hoàn thành %s!" % str(level.get("id", "")),
		"LevelFailed": "Đã hết lượt sai",
	}.get(event_name, "Đang chơi")


func _on_hint_pressed() -> void:
	if runtime_controller == null:
		return
	var result: Dictionary = runtime_controller.use_hint()
	if result.get("ok", false):
		hint_explanation_closed = false
		hint_label.text = _hint_text(result.get("evidence", {}))
	else:
		hint_label.text = "Chưa có gợi ý mới trong trạng thái hiện tại."
	_refresh()


func _on_close_hint_pressed() -> void:
	hint_explanation_closed = true
	close_hint_button.visible = false
	hint_label.text = ""
	if runtime_controller != null and level.get("id") == "L01" and engine.session.hint_count > 0:
		runtime_controller.process_tutorial_action({"type": "CloseHint", "valid": true})
	_refresh()


func _on_home_pressed() -> void:
	_settle_input()
	if runtime_controller != null:
		if not runtime_controller.save_current_session():
			return
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, "mvp_bootstrap", "return_home")

func _on_help_pressed() -> void:
	_settle_input()
	if runtime_controller != null:
		if not runtime_controller.save_current_session():
			return
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, "mvp_bootstrap", "open_help")

func _on_settings_pressed() -> void:
	_settle_input()
	if runtime_controller != null:
		if not runtime_controller.save_current_session():
			return
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, "mvp_bootstrap", "open_settings")


func _hint_text(evidence: Dictionary) -> String:
	if evidence.is_empty():
		return "Đã nhận gợi ý."
	var cell: Array = evidence.get("cell", [])
	if not cell.is_empty():
		return "Gợi ý %s tại ô (%d, %d)" % [str(evidence.get("rule", "")), int(cell[0]) + 1, int(cell[1]) + 1]
	return "Gợi ý %s: loại %d ô ứng viên." % [str(evidence.get("rule", "")), evidence.get("eliminateCells", []).size()]


func _read_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(parsed is Dictionary, "Invalid JSON object: %s" % path)
	return parsed

extends Control

const Flow = preload("res://scripts/ui_flow_controller.gd")
const Runtime = preload("res://scripts/mvp_runtime.gd")
const HomeScene = preload("res://scenes/home.tscn")
const WinScene = preload("res://scenes/result_win.tscn")
const FailScene = preload("res://scenes/result_fail.tscn")
const BoardScene = preload("res://scenes/board.tscn")

var flow
var runtime
var screen_host: Control


func _ready() -> void:
	add_to_group("mvp_bootstrap")
	screen_host = get_node("ScreenHost")
	if runtime == null:
		runtime = Runtime.new()
	if not runtime.initialize():
		var error_screen := Control.new()
		error_screen.name = "SaveLoadError"
		error_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var message := Label.new()
		message.text = "Không thể đọc tiến trình đã lưu. Dữ liệu được giữ nguyên; hãy thử mở lại trò chơi."
		message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		message.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		message.custom_minimum_size = Vector2(640, 120)
		error_screen.add_child(message)
		screen_host.add_child(error_screen)
		return
	flow = Flow.new()
	flow.changed.connect(_on_flow_changed)
	runtime.level_won.connect(_on_runtime_level_won)
	runtime.level_failed.connect(_on_runtime_level_failed)
	runtime.save_failed.connect(_on_save_failed)
	if runtime.engine != null and runtime.engine.session.attempt_state == "Won":
		runtime.retry_pending_save()
	_render()


func _on_flow_changed(_screen_id: String) -> void:
	_render()


func _on_runtime_level_won(_level_id: String, _next_level_id: String) -> void:
	call_deferred("_dispatch_result", "win")


func _on_runtime_level_failed(_level_id: String) -> void:
	call_deferred("_dispatch_result", "fail")


func _dispatch_result(action: String) -> void:
	if flow == null or flow.current_screen != Flow.SCREEN_PUZZLE:
		return
	flow.dispatch(action)


func return_home() -> void:
	flow.dispatch("home")

func open_help() -> void:
	_on_action("help")

func open_settings() -> void:
	_on_action("settings")


func _render() -> void:
	for child in screen_host.get_children():
		child.free()

	var screen: Control
	match flow.current_screen:
		Flow.SCREEN_HOME:
			screen = HomeScene.instantiate()
			_connect_button(screen, "SafeArea/Content/Stack/PlayButton", "start_game")
			_connect_button(screen, "SafeArea/Content/Stack/HelpButton", "help")
			_connect_button(screen, "SafeArea/Content/Stack/SettingsButton", "settings")
			var level_label = screen.get_node_or_null("SafeArea/Content/Stack/CurrentLevelLabel")
			if level_label != null:
				if runtime.progress.get("currentLevelId") == null:
					level_label.text = "Bạn đã hoàn thành các level hiện có"
				else:
					level_label.text = "Level hiện tại: %s" % str(runtime.progress.get("currentLevelId", ""))
			var play_button = screen.get_node_or_null("SafeArea/Content/Stack/PlayButton")
			if play_button != null:
				play_button.disabled = runtime.progress.get("currentLevelId") == null
		Flow.SCREEN_PUZZLE:
			screen = _build_puzzle_screen()
		Flow.SCREEN_RESULT_WIN:
			screen = WinScene.instantiate()
			_wrap_result_content(screen)
			_connect_button(screen, "SafeArea/Content/Stack/ContinueButton", "next")
			_connect_button(screen, "SafeArea/Content/Stack/HomeButton", "home")
			var win_score = screen.get_node_or_null("SafeArea/Content/Stack/ScoreLabel")
			if win_score != null:
				var result: Dictionary = runtime.progress.get("results", {}).get(runtime.current_level_id, {})
				win_score.text = "Điểm: %d" % int(result.get("score", 0))
		Flow.SCREEN_RESULT_FAIL:
			screen = FailScene.instantiate()
			_wrap_result_content(screen)
			_connect_button(screen, "SafeArea/Content/Stack/RetryButton", "retry")
			_connect_button(screen, "SafeArea/Content/Stack/HomeButton", "home")
			var fail_score = screen.get_node_or_null("SafeArea/Content/Stack/ScoreLabel")
			if fail_score != null:
				fail_score.text = "Điểm: %d" % runtime.engine.session.scorecard()
		Flow.SCREEN_HELP:
			screen = _build_info_shell("Trợ giúp / Luật", [
				"Mỗi hàng, cột và vùng có đúng một mèo.",
				"Hai mèo không được chạm nhau ở góc.",
				"Chạm để đánh hoặc xóa X; chạm đôi để thử đặt mèo.",
				"Bạn có ba lượt sai và một gợi ý mỗi lượt.",
			])
		Flow.SCREEN_SETTINGS:
			screen = _build_info_shell("Cài đặt", [
				"Âm thanh và rung: sẽ lấy từ cài đặt phiên chơi.",
				"Giảm chuyển động và phân biệt vùng: placeholder MVP.",
				"Các tuỳ chọn thật sẽ được nối ở M1-A08.",
			])
		_:
			screen = _build_info_shell("Màn hình chưa hỗ trợ", ["Route không hợp lệ."])

	screen.set_meta("screen_id", flow.current_screen)
	screen_host.add_child(screen)


func _connect_button(screen: Node, path: String, action: String) -> void:
	var button = screen.get_node_or_null(path)
	if button != null:
		button.pressed.connect(_on_action.bind(action), CONNECT_DEFERRED)


func _wrap_result_content(screen: Control) -> void:
	var content = screen.get_node_or_null("SafeArea/Content")
	if content == null:
		return
	var stack := VBoxContainer.new()
	stack.name = "Stack"
	stack.layout_mode = 2
	stack.add_theme_constant_override("separation", 18)
	var children: Array[Node] = content.get_children()
	for child in children:
		content.remove_child(child)
		child.owner = null
		stack.add_child(child)
	content.add_child(stack)


func _on_action(action: String) -> void:
	if action == "start_game" and runtime.progress.get("currentLevelId") == null:
		return
	if action == "start_game" and runtime.engine != null and runtime.engine.session.hearts <= 0:
		flow.dispatch("resume_fail")
		return
	if action == "next" and runtime.progress.get("currentLevelId") == null:
		flow.dispatch("home")
		return
	var from_puzzle: bool = flow.current_screen == Flow.SCREEN_PUZZLE
	if flow.dispatch(action) and action == "help" and from_puzzle:
		runtime.process_tutorial_action({"type": "ViewRules"})

func _on_save_failed(reason: String) -> void:
	var dialog = get_node_or_null("SaveErrorDialog")
	if dialog == null:
		dialog = ConfirmationDialog.new()
		dialog.name = "SaveErrorDialog"
		dialog.title = "Chưa lưu được"
		dialog.get_ok_button().text = "Thử lưu lại"
		dialog.confirmed.connect(_retry_pending_save)
		add_child(dialog)
	dialog.dialog_text = reason
	dialog.popup_centered(Vector2i(640, 220))

func _retry_pending_save() -> void:
	if runtime.retry_pending_save():
		var dialog = get_node_or_null("SaveErrorDialog")
		if dialog != null:
			dialog.hide()


func _build_puzzle_screen() -> Control:
	var level_id := str(runtime.progress.get("currentLevelId", ""))
	if flow.previous_screen == Flow.SCREEN_RESULT_FAIL:
		level_id = runtime.current_level_id
	runtime.start_level(level_id, flow.previous_screen != Flow.SCREEN_RESULT_FAIL)
	var screen = BoardScene.instantiate()
	screen.configure(runtime.active_level, runtime.engine, runtime, runtime.contract)
	return screen


func _build_info_shell(title_text: String, lines: Array) -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("#F5F1E8")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 80)
	margin.add_theme_constant_override("margin_bottom", 80)
	root.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 22)
	margin.add_child(stack)
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	stack.add_child(title)
	for line in lines:
		var label := Label.new()
		label.text = "• " + str(line)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 24)
		stack.add_child(label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(spacer)
	var back_button := _make_button("Quay lại")
	back_button.pressed.connect(_on_action.bind("back"))
	stack.add_child(back_button)
	return root


func _make_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(240, 56)
	button.add_theme_font_size_override("font_size", 22)
	return button

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
	runtime = Runtime.new()
	if not runtime.initialize():
		push_error("MVP runtime failed to load campaign")
		return
	flow = Flow.new(runtime.level_ids)
	flow.current_level_index = maxi(0, runtime.level_ids.find(runtime.current_level_id))
	flow.changed.connect(_on_flow_changed)
	runtime.level_won.connect(_on_runtime_level_won)
	runtime.level_failed.connect(_on_runtime_level_failed)
	_render()


func _on_flow_changed(_screen_id: String, _level_id: String) -> void:
	_render()


func _on_runtime_level_won(_level_id: String, _next_level_id: String) -> void:
	flow.dispatch("win")


func _on_runtime_level_failed(_level_id: String) -> void:
	flow.dispatch("fail")


func return_home() -> void:
	flow.dispatch("home")


func _render() -> void:
	for child in screen_host.get_children():
		child.free()

	var screen: Control
	match flow.current_screen:
		Flow.SCREEN_HOME:
			screen = HomeScene.instantiate()
			_connect_button(screen, "SafeArea/Content/PlayButton", "start_game")
			_connect_button(screen, "SafeArea/Content/HelpButton", "help")
			_connect_button(screen, "SafeArea/Content/SettingsButton", "settings")
			var level_label = screen.get_node_or_null("SafeArea/Content/CurrentLevelLabel")
			if level_label != null:
				level_label.text = "Level hiện tại: %s" % flow.current_level_id
		Flow.SCREEN_PUZZLE:
			screen = _build_puzzle_screen()
		Flow.SCREEN_RESULT_WIN:
			screen = WinScene.instantiate()
			_connect_button(screen, "SafeArea/Content/ContinueButton", "next")
			_connect_button(screen, "SafeArea/Content/HomeButton", "home")
			var win_score = screen.get_node_or_null("SafeArea/Content/ScoreLabel")
			if win_score != null:
				win_score.text = "%s đã hoàn thành" % flow.current_level_id
		Flow.SCREEN_RESULT_FAIL:
			screen = FailScene.instantiate()
			_connect_button(screen, "SafeArea/Content/RetryButton", "retry")
			_connect_button(screen, "SafeArea/Content/HomeButton", "home")
			var fail_score = screen.get_node_or_null("SafeArea/Content/ScoreLabel")
			if fail_score != null:
				fail_score.text = "Level hiện tại: %s" % flow.current_level_id
		Flow.SCREEN_HELP:
			screen = _build_info_shell("Trợ giúp / Luật", [
				"Điền đúng bốn biểu tượng vào hàng, cột và vùng.",
				"Chạm để đánh dấu; chạm đôi hoặc kéo để thao tác nhanh.",
				"Màn hướng dẫn đầy đủ sẽ được nối ở M1-A08.",
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
		button.pressed.connect(_on_action.bind(action))


func _on_action(action: String) -> void:
	flow.dispatch(action)


func _build_puzzle_screen() -> Control:
	runtime.start_level(flow.current_level_id)
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

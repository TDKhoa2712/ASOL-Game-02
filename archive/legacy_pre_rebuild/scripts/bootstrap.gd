extends Control

const Flow = preload("res://scripts/ui_flow_controller.gd")
const Runtime = preload("res://scripts/mvp_runtime.gd")
const SettingsScript = preload("res://scripts/settings.gd")
const HomeScene = preload("res://scenes/home.tscn")
const WinScene = preload("res://scenes/result_win.tscn")
const FailScene = preload("res://scenes/result_fail.tscn")
const BoardScene = preload("res://scenes/board.tscn")
const SettingsScene = preload("res://scenes/settings.tscn")

# MVP verification switch. Set false before the official release to make a
# completed campaign terminal again instead of exposing a Level 1 replay.
const MVP_ALLOW_CAMPAIGN_REPLAY := true

var flow
var runtime
var settings: SettingsScript
var screen_host: Control


func _ready() -> void:
	add_to_group("mvp_bootstrap")
	screen_host = get_node("ScreenHost")
	if settings == null:
		settings = SettingsScript.new()
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
			_connect_button(screen, "SafeArea/TopBar/TopSettingsButton", "settings")
			var level_label = screen.get_node_or_null("SafeArea/Content/Stack/CurrentLevelLabel")
			if level_label != null:
				if runtime.progress.get("currentLevelId") == null:
					level_label.text = "Đã hoàn thành các level hiện có · MVP cho phép kiểm tra lại từ L01"
				else:
					level_label.text = "Level hiện tại: %s" % str(runtime.progress.get("currentLevelId", ""))
			var campaign_complete: bool = runtime.progress.get("currentLevelId") == null
			if screen.has_method("set_campaign_state"):
				screen.set_campaign_state(runtime.progress.get("currentLevelId"), campaign_complete)
			elif screen.has_method("update_level"):
				var cur_id = runtime.progress.get("currentLevelId")
				if cur_id != null:
					screen.update_level(str(cur_id))
			var play_button = screen.get_node_or_null("SafeArea/Content/Stack/PlayButton")
			if play_button != null:
				play_button.disabled = campaign_complete and not MVP_ALLOW_CAMPAIGN_REPLAY
				if campaign_complete and MVP_ALLOW_CAMPAIGN_REPLAY:
					play_button.text = "Chơi lại từ L01"
		Flow.SCREEN_PUZZLE:
			screen = _build_puzzle_screen()
		Flow.SCREEN_RESULT_WIN:
			screen = WinScene.instantiate()
			_wrap_result_content(screen)
			var campaign_complete: bool = runtime.progress.get("currentLevelId") == null
			var at_campaign_end: bool = campaign_complete and runtime.current_level_id == runtime.level_ids[-1]
			var continue_action := "replay_campaign" if at_campaign_end and MVP_ALLOW_CAMPAIGN_REPLAY else "next"
			_connect_button(screen, "SafeArea/Content/Stack/ContinueButton", continue_action)
			_connect_button(screen, "SafeArea/Content/Stack/HomeButton", "home")
			var continue_button = screen.get_node_or_null("SafeArea/Content/Stack/ContinueButton")
			if continue_button != null and continue_action == "replay_campaign":
				continue_button.text = "Chơi lại từ L01"
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
				"Mỗi hàng, cột và vùng có đúng một kẹo.",
				"Hai kẹo không được chạm nhau ở góc.",
				"Chạm để đánh hoặc xóa X; chạm đôi để thử tìm kẹo.",
				"Bạn có ba lượt sai và một gợi ý mỗi lượt.",
			])
		Flow.SCREEN_SETTINGS:
			screen = SettingsScene.instantiate()
			_connect_settings_toggles(screen)
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
		if not MVP_ALLOW_CAMPAIGN_REPLAY:
			return
	if action == "start_game" and runtime.engine != null and runtime.engine.session.hearts <= 0:
		flow.dispatch("resume_fail")
		return
	if action == "replay_campaign":
		if not MVP_ALLOW_CAMPAIGN_REPLAY or runtime.progress.get("currentLevelId") != null:
			return
	if action == "next" and runtime.progress.get("currentLevelId") == null and runtime.current_level_id == runtime.level_ids[-1]:
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
	var saved_level = runtime.progress.get("currentLevelId")
	var resume: bool = flow.previous_screen != Flow.SCREEN_RESULT_FAIL
	var level_id := str(saved_level) if saved_level != null else ""
	if saved_level == null:
		if not MVP_ALLOW_CAMPAIGN_REPLAY or runtime.level_ids.is_empty():
			return _build_info_shell("Đã hoàn thành", ["Bản phát hành chính thức không cho chơi lại từ Level 1."])
		var current_index: int = runtime.level_ids.find(runtime.current_level_id)
		var continuing_replay: bool = flow.previous_screen == Flow.SCREEN_RESULT_WIN and current_index >= 0 and current_index + 1 < runtime.level_ids.size()
		level_id = runtime.level_ids[current_index + 1] if continuing_replay else runtime.level_ids[0]
		resume = false
	if flow.previous_screen == Flow.SCREEN_RESULT_FAIL:
		level_id = runtime.current_level_id
	runtime.start_level(level_id, resume, saved_level != null)
	var screen = BoardScene.instantiate()
	screen.configure(runtime.active_level, runtime.engine, runtime, runtime.contract, settings)
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


func _connect_settings_toggles(screen: Control) -> void:
	var audio_switch = screen.find_child("AudioSwitch", true, false)
	if audio_switch != null:
		audio_switch.button_pressed = settings.is_audio_enabled()
		if audio_switch.has_method("sync_state"):
			audio_switch.sync_state()
		audio_switch.toggled.connect(_on_audio_toggled)
	var haptics_switch = screen.find_child("HapticsSwitch", true, false)
	if haptics_switch != null:
		haptics_switch.button_pressed = settings.is_haptics_enabled()
		if haptics_switch.has_method("sync_state"):
			haptics_switch.sync_state()
		haptics_switch.toggled.connect(_on_haptics_toggled)
	var reduced_motion_switch = screen.find_child("ReducedMotionSwitch", true, false)
	if reduced_motion_switch != null:
		reduced_motion_switch.button_pressed = settings.is_reduced_motion()
		if reduced_motion_switch.has_method("sync_state"):
			reduced_motion_switch.sync_state()
		reduced_motion_switch.toggled.connect(_on_reduced_motion_toggled)
	var high_contrast_switch = screen.find_child("HighContrastSwitch", true, false)
	if high_contrast_switch != null:
		high_contrast_switch.button_pressed = settings.is_high_contrast()
		if high_contrast_switch.has_method("sync_state"):
			high_contrast_switch.sync_state()
		high_contrast_switch.toggled.connect(_on_high_contrast_toggled)
	var large_text_switch = screen.find_child("LargeTextSwitch", true, false)
	if large_text_switch != null:
		large_text_switch.button_pressed = settings.is_large_text()
		if large_text_switch.has_method("sync_state"):
			large_text_switch.sync_state()
		large_text_switch.toggled.connect(_on_large_text_toggled)
	var back_button = screen.find_child("BackButton", true, false)
	if back_button != null:
		back_button.pressed.connect(_on_action.bind("back"), CONNECT_DEFERRED)
	var close_button = screen.find_child("CloseButton", true, false)
	if close_button != null:
		close_button.pressed.connect(_on_action.bind("back"), CONNECT_DEFERRED)


func _on_audio_toggled(pressed: bool) -> void:
	settings.set_value("audioEnabled", pressed)


func _on_haptics_toggled(pressed: bool) -> void:
	settings.set_value("hapticsEnabled", pressed)


func _on_reduced_motion_toggled(pressed: bool) -> void:
	settings.set_value("reducedMotion", pressed)


func _on_high_contrast_toggled(pressed: bool) -> void:
	settings.set_value("highContrast", pressed)


func _on_large_text_toggled(pressed: bool) -> void:
	settings.set_value("largeText", pressed)

extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_check_home()
	_check_result("res://scenes/result_win.tscn", "win", "ContinueButton", "Tiếp tục")
	_check_result("res://scenes/result_fail.tscn", "fail", "RetryButton", "Thử lại")
	if failures.is_empty():
		print("M1_A05_UI_SHELL_PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_home() -> void:
	var scene = load("res://scenes/home.tscn")
	_check(scene != null, "Home scene loads")
	if scene == null:
		return
	var home = scene.instantiate()
	_check(home.get_meta("screen_id", "") == "home", "Home has screen metadata")
	_check(home.get_node_or_null("SafeArea") != null, "Home uses safe area container")
	_check(home.get_node_or_null("Backdrop") != null, "Home has original pastel backdrop")
	_check(home.get_node_or_null("SafeArea/TopBar") != null, "Home has floating top actions")
	_check(home.get_node_or_null("SafeArea/Content/Stack/HeroCard") != null, "Home content has a hero card")
	var content = home.get_node_or_null("SafeArea/Content")
	var stack = home.get_node_or_null("SafeArea/Content/Stack")
	_check(stack != null, "Home has content stack")
	if content != null and stack != null:
		_check(content.get_child_count() == 1, "Home content has one layout owner")
		_check(content.get_child(0) == stack, "Home stack owns content layout")
	for child_name in ["Title", "CurrentLevelLabel", "PlayButton", "HelpButton", "SettingsButton", "ProgressHint"]:
		_check(stack != null and stack.get_node_or_null(child_name) != null, "Home stack has %s" % child_name)
	_check(stack != null and stack.get_node("PlayButton").text == "Chơi / Tiếp tục", "Home Play label is explicit")
	_check(stack != null and _large_enough(stack.get_node("PlayButton")), "Home Play meets touch target")
	if stack != null:
		var play: Button = stack.get_node("PlayButton")
		var play_style: StyleBox = play.get_theme_stylebox("normal")
		_check(play_style is StyleBoxFlat and play_style.corner_radius_top_left >= 28, "Home Play uses a rounded primary style")
	home.free()

func _check_result(path: String, screen_id: String, action_name: String, action_text: String) -> void:
	var scene = load(path)
	_check(scene != null, "%s scene loads" % screen_id)
	if scene == null:
		return
	var result = scene.instantiate()
	_check(result.get_meta("screen_id", "") == screen_id, "%s metadata is stable" % screen_id)
	_check(result.get_node_or_null("SafeArea") != null, "%s uses safe area container" % screen_id)
	var action = result.get_node_or_null("SafeArea/Content/%s" % action_name)
	_check(action != null, "%s has primary action" % screen_id)
	if action != null:
		_check(action.text == action_text, "%s primary action label is clear" % screen_id)
		_check(_large_enough(action), "%s primary action meets touch target" % screen_id)
	_check(result.get_node_or_null("SafeArea/Content/HomeButton") != null, "%s has Home action" % screen_id)
	_check(result.get_node_or_null("SafeArea/Content/ScoreLabel") != null, "%s exposes score" % screen_id)
	for child_name in ["Title", "ScoreLabel", "StickerLabel" if screen_id == "win" else "Message"]:
		var label: Label = result.get_node_or_null("SafeArea/Content/%s" % child_name)
		_check(label != null and label.has_theme_color_override("font_color") and label.get_theme_color("font_color").get_luminance() < 0.4, "%s %s has readable dark text" % [screen_id, child_name])
	result.free()

func _large_enough(control: Control) -> bool:
	return control.custom_minimum_size.x >= 44.0 and control.custom_minimum_size.y >= 44.0

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append("FAIL: " + label)

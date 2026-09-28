extends SceneTree

const SettingsScript = preload("res://scripts/settings.gd")
const BoardScene = preload("res://scenes/board.tscn")
const BootstrapScene = preload("res://scenes/bootstrap.tscn")
const Runtime = preload("res://scripts/mvp_runtime.gd")
const SettingsScene = preload("res://scenes/settings.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_settings_store_roundtrip()
	_check_settings_scene_structure()
	await _check_board_applies_settings()
	await _check_bootstrap_settings_flow()
	if failures.is_empty():
		print("R1_E_SETTINGS_PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _isolated_dir() -> String:
	return OS.get_user_data_dir().path_join("r1_settings_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()])


## Store: defaults, persistence, reload from an isolated directory.
func _check_settings_store_roundtrip() -> void:
	var dir := _isolated_dir()
	var store = SettingsScript.new(dir)
	_check(store.get_value("audioEnabled") == true, "audio defaults on")
	_check(store.get_value("largeText") == false, "large text defaults off")
	_check(store.get_value("highContrast") == false, "high contrast defaults off")
	_check(store.get_value("reducedMotion") == false, "reduced motion defaults off")
	_check(not store.set_value("not-a-key", true), "unknown key is rejected")
	_check(store.set_value("largeText", true), "large text can be enabled")
	_check(store.is_large_text(), "large text flag reads back")
	var reloaded = SettingsScript.new(dir)
	_check(reloaded.is_large_text(), "large text persists across reload")
	_check(reloaded.is_audio_enabled(), "untouched audio persists across reload")
	reloaded.reset_to_defaults()
	var after_reset = SettingsScript.new(dir)
	_check(not after_reset.is_large_text(), "reset restores defaults")
	_clear_settings_dir(dir)


## Scene: real Settings screen exposes all five switches plus back action.
func _check_settings_scene_structure() -> void:
	var scene = SettingsScene.instantiate()
	_check(scene.get_meta("screen_id", "") == "settings", "settings has screen metadata")
	_check(scene.get_node_or_null("SafeArea") != null, "settings uses safe area container")
	for toggle_name in ["AudioToggle", "HapticsToggle", "ReducedMotionToggle", "HighContrastToggle", "LargeTextToggle"]:
		var toggle = scene.get_node_or_null("SafeArea/Content/Stack/%s" % toggle_name)
		_check(toggle != null, "settings has %s row" % toggle_name)
		if toggle != null:
			var switch = null
			if toggle.get_child_count() > 1:
				switch = toggle.get_child(1)
			_check(switch is CheckButton, "%s exposes a switch" % toggle_name)
			_check(switch.custom_minimum_size.x >= 44.0 and switch.custom_minimum_size.y >= 40.0, "%s meets touch target" % toggle_name)
	var back = scene.get_node_or_null("SafeArea/Content/Stack/BackButton")
	_check(back != null and back.custom_minimum_size.x >= 240.0 and back.custom_minimum_size.y >= 44.0, "settings back meets touch target")
	scene.free()


## Board: large text scales fonts +30%; high contrast darkens label ink.
func _check_board_applies_settings() -> void:
	var normal_dir := _isolated_dir()
	var large_dir := _isolated_dir()
	var contrast_dir := _isolated_dir()
	var normal_settings = SettingsScript.new(normal_dir)
	var large_settings = SettingsScript.new(large_dir)
	var contrast_settings = SettingsScript.new(contrast_dir)
	large_settings.set_value("largeText", true)
	contrast_settings.set_value("highContrast", true)

	var runtime = Runtime.new(_isolated_dir())
	runtime.initialize()
	runtime.start_level(runtime.level_ids[0], false, false)
	var base_font := 0
	var large_font := 0
	var base_ink := Color()
	var contrast_ink := Color()

	var base_board = BoardScene.instantiate()
	base_board.configure(runtime.active_level, runtime.engine, runtime, runtime.contract, normal_settings)
	root.add_child(base_board)
	await process_frame
	base_font = base_board.find_child("HeartsLabel", true, false).get_theme_font_size("font_size")
	base_ink = base_board.find_child("RuleStrip", true, false).get_child(0).get_theme_color("font_color")
	base_board.free()

	var large_board = BoardScene.instantiate()
	large_board.configure(runtime.active_level, runtime.engine, runtime, runtime.contract, large_settings)
	root.add_child(large_board)
	await process_frame
	large_font = large_board.find_child("HeartsLabel", true, false).get_theme_font_size("font_size")
	large_board.free()

	var contrast_board = BoardScene.instantiate()
	contrast_board.configure(runtime.active_level, runtime.engine, runtime, runtime.contract, contrast_settings)
	root.add_child(contrast_board)
	await process_frame
	contrast_ink = contrast_board.find_child("RuleStrip", true, false).get_child(0).get_theme_color("font_color")
	contrast_board.free()

	_check(large_font >= int(float(base_font) * 1.29), "large text scales fonts by at least 30%% (base %d, large %d)" % [base_font, large_font])
	_check(contrast_ink.v < base_ink.v, "high contrast darkens label ink (base %.3f, contrast %.3f)" % [base_ink.v, contrast_ink.v])

	runtime.clear_saved_state()
	for dir in [normal_dir, large_dir, contrast_dir]:
		_clear_settings_dir(dir)
	DirAccess.remove_absolute(_runtime_dir_of(runtime))


## Integration: a real Settings screen stores a toggle and returns to its caller.
func _check_bootstrap_settings_flow() -> void:
	var runtime_dir := _isolated_dir()
	var settings_dir := _isolated_dir()
	var bootstrap = BootstrapScene.instantiate()
	bootstrap.runtime = Runtime.new(runtime_dir)
	var supplied_settings = SettingsScript.new(settings_dir)
	bootstrap.settings = supplied_settings
	root.add_child(bootstrap)
	await process_frame
	_check(bootstrap.settings == supplied_settings, "bootstrap preserves the injected settings profile")

	var home = bootstrap.get_node("ScreenHost").get_child(0)
	home.get_node("SafeArea/Content/Stack/SettingsButton").emit_signal("pressed")
	await process_frame
	_check(bootstrap.flow.current_screen == "settings", "Home Settings opens the real Settings screen")

	var screen = bootstrap.get_node("ScreenHost").get_child(0)
	var large_text: CheckButton = screen.get_node("SafeArea/Content/Stack/LargeTextToggle/LargeTextSwitch")
	large_text.button_pressed = true
	await process_frame
	_check(bootstrap.settings.is_large_text(), "large text toggle updates the injected settings store")
	_check(SettingsScript.new(settings_dir).is_large_text(), "large text toggle persists to the isolated profile")

	screen.get_node("SafeArea/Content/Stack/BackButton").emit_signal("pressed")
	await process_frame
	_check(bootstrap.flow.current_screen == "home", "Settings Back returns to Home")

	var test_runtime = bootstrap.runtime
	bootstrap.free()
	test_runtime.clear_saved_state()
	DirAccess.remove_absolute(runtime_dir)
	_clear_settings_dir(settings_dir)


func _runtime_dir_of(runtime) -> String:
	return runtime.repository.root_dir


func _clear_settings_dir(dir: String) -> void:
	DirAccess.remove_absolute(dir.path_join("settings.json.tmp"))
	DirAccess.remove_absolute(dir.path_join("settings.json"))
	DirAccess.remove_absolute(dir)


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append("FAIL: " + label)

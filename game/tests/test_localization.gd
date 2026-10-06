extends SceneTree

const TitleScreen = preload("res://scripts/screens/title_screen.gd")
const ResultScreen = preload("res://scripts/screens/result_screen.gd")
const OptionsScreen = preload("res://scripts/screens/options_screen.gd")
const ConfigStore = preload("res://scripts/state/config_store.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")

var _fails: Array[String] = []
var _tmp_dir: String = ""

func _init() -> void:
	_tmp_dir = "user://test_i18n_%d" % Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(_tmp_dir)

	_test_title_uses_tr()
	_test_result_uses_tr()
	_test_locale_switch()
	_test_csv_key_coverage()

	DirAccess.remove_absolute(_tmp_dir.path_join("config.json"))
	DirAccess.remove_absolute(_tmp_dir)

	if _fails.is_empty():
		print("LOCALIZATION_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_title_uses_tr() -> void:
	TranslationServer.set_locale("en")
	var screen := TitleScreen.new()
	var mock := _MockRuntime.new()
	screen._ensure_nodes()
	screen.setup(mock)
	if screen.play_btn == null:
		_fails.append("title play_btn is null")
		screen.free()
		return
	if "Level" not in screen.play_btn.text:
		_fails.append("title play_btn should contain 'Level' in EN, got '%s'" % screen.play_btn.text)
	screen.free()
	TranslationServer.set_locale("vi")

func _test_result_uses_tr() -> void:
	TranslationServer.set_locale("en")
	var screen := ResultScreen.new()
	screen.setup(true, 5000, "L01", false)
	if screen.message_label == null:
		_fails.append("result message_label is null")
		screen.free()
		return
	if screen.message_label.text != "Hooray!":
		_fails.append("result win title in EN should be 'Hooray!', got '%s'" % screen.message_label.text)
	screen.free()
	TranslationServer.set_locale("vi")

func _test_locale_switch() -> void:
	TranslationServer.set_locale("vi")
	var result := tr("result.win.title")
	if result != "Hoan hô!":
		_fails.append("VI result.win.title should be 'Hoan hô!', got '%s'" % result)
	TranslationServer.set_locale("en")
	result = tr("result.win.title")
	if result != "Hooray!":
		_fails.append("EN result.win.title should be 'Hooray!', got '%s'" % result)
	TranslationServer.set_locale("vi")

func _test_csv_key_coverage() -> void:
	var expected_keys := [
		"title.name", "title.play", "title.replay",
		"settings.audio", "settings.haptic",
		"result.win.title", "result.lose.title",
		"puzzle.rule_row", "puzzle.rule_region", "puzzle.rule_diagonal",
	]
	TranslationServer.set_locale("vi")
	for key in expected_keys:
		var translated := tr(key)
		if translated == key:
			_fails.append("key '%s' has no VI translation (tr returned key)" % key)
	TranslationServer.set_locale("en")
	for key in expected_keys:
		var translated := tr(key)
		if translated == key:
			_fails.append("key '%s' has no EN translation (tr returned key)" % key)
	TranslationServer.set_locale("vi")

class _MockRuntime extends RefCounted:
	func current_level_label() -> String: return "L01"
	func is_campaign_done() -> bool: return false

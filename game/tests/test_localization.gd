extends SceneTree

const TitleScreen = preload("res://scripts/screens/title_screen.gd")
const WinScreen = preload("res://scripts/screens/win_screen.gd")
const OptionsScreen = preload("res://scripts/screens/options_screen.gd")
const ConfigStore = preload("res://scripts/state/config_store.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const LocaleResolver = preload("res://scripts/core/locale_resolver.gd")

var _fails: Array[String] = []
var _tmp_dir: String = ""

func _init() -> void:
	_tmp_dir = "user://test_i18n_%d" % Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(_tmp_dir)

	_test_title_uses_tr()
	_test_result_uses_tr()
	_test_all_7_locales_switch()
	_test_csv_key_coverage_all_7_locales()
	_test_parameter_format_accuracy()

	DirAccess.remove_absolute(_tmp_dir.path_join("config.json"))
	DirAccess.remove_absolute(_tmp_dir)

	TranslationServer.set_locale("en")

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

func _test_result_uses_tr() -> void:
	TranslationServer.set_locale("en")
	var screen := WinScreen.new()
	screen.setup(true, 5000, "L01", false)
	if screen.ribbon == null:
		_fails.append("win ribbon is null")
		screen.free()
		return
	if screen.ribbon.text != "Hooray!":
		_fails.append("win ribbon title in EN should be 'Hooray!', got '%s'" % screen.ribbon.text)
	screen.free()

func _test_all_7_locales_switch() -> void:
	var expected_win_titles := {
		"en": "Hooray!",
		"ja": "万歳！",
		"vi": "Hoan hô!",
		"id": "Hore!",
		"pt_BR": "Viva!",
		"es": "¡Hurra!",
		"ko": "만세!",
	}
	for loc in expected_win_titles:
		TranslationServer.set_locale(loc)
		var text := tr("result.win.title")
		if text != expected_win_titles[loc]:
			_fails.append("result.win.title in '%s' expected '%s', got '%s'" % [loc, expected_win_titles[loc], text])

func _test_csv_key_coverage_all_7_locales() -> void:
	var expected_keys := [
		"title.name", "title.play", "title.replay",
		"settings.audio", "settings.haptic",
		"result.win.title", "result.lose.title",
		"puzzle.rule_row", "puzzle.rule_region", "puzzle.rule_diagonal",
		"hint.wrong_mark", "hint.mark_neighbors", "hint.single_row", "hint.single_col",
		"hint.single_zone", "hint.lock_zone_row", "hint.lock_zone_col", "hint.lock_row_zone",
		"hint.lock_col_zone", "hint.subset_pair", "hint.subset_triple", "hint.subset_quad",
		"hint.chain_short", "hint.chain_long", "hint.fallback", "hint.clear_mark",
		"hint.mark_x", "hint.place_candy", "hint.reveal", "hint.detail",
		"result.stat.time", "result.stat.mistakes", "result.level_badge",
		"result.win.next_level", "result.lose.encourage_title",
		"title.progress", "title.mascot_bubble",
	]
	for loc in LocaleResolver.SUPPORTED_LOCALES:
		TranslationServer.set_locale(loc)
		for key in expected_keys:
			var translated := tr(key)
			if translated == key:
				_fails.append("key '%s' has no translation for locale '%s' (tr returned key)" % [key, loc])

func _test_parameter_format_accuracy() -> void:
	for loc in LocaleResolver.SUPPORTED_LOCALES:
		TranslationServer.set_locale(loc)
		var play_fmt := tr("title.play")
		if not play_fmt.contains("%s"):
			_fails.append("title.play in locale '%s' must contain '%%s', got '%s'" % [loc, play_fmt])
		else:
			var formatted := play_fmt % "5"
			if "5" not in formatted:
				_fails.append("title.play in '%s' failed to insert '5', got '%s'" % [loc, formatted])

		var endless_fmt := tr("title.endless")
		if not endless_fmt.contains("%d"):
			_fails.append("title.endless in locale '%s' must contain '%%d', got '%s'" % [loc, endless_fmt])
		else:
			var formatted := endless_fmt % 10
			if "10" not in formatted:
				_fails.append("title.endless in '%s' failed to insert '10', got '%s'" % [loc, formatted])

class _MockRuntime extends RefCounted:
	func current_level_label() -> String: return "L01"
	func is_campaign_done() -> bool: return false

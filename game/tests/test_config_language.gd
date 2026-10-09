extends SceneTree

const ConfigStore = preload("res://scripts/state/config_store.gd")

var _fails: Array[String] = []
var _tmp_dir: String = ""

func _init() -> void:
	_tmp_dir = "user://test_config_lang_%d" % Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(_tmp_dir)

	_test_default_language_is_empty_for_auto()
	_clear_file()
	_test_set_all_7_supported_languages()
	_clear_file()
	_test_persist_language()
	_clear_file()
	_test_signal_emitted()
	_clear_file()
	_test_invalid_language_rejected()

	_clear_file()
	DirAccess.remove_absolute(_tmp_dir)

	if _fails.is_empty():
		print("CONFIG_LANGUAGE_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _clear_file() -> void:
	var path := _tmp_dir.path_join("config.json")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func _test_default_language_is_empty_for_auto() -> void:
	var cfg := ConfigStore.new(_tmp_dir)
	var val: Variant = cfg.get_option("language")
	if str(val) != "":
		_fails.append("default language should be empty string (auto), got '%s'" % str(val))

func _test_set_all_7_supported_languages() -> void:
	var cfg := ConfigStore.new(_tmp_dir)
	var targets := ["en", "ja", "vi", "id", "pt_BR", "es", "ko"]
	for target in targets:
		cfg.set_option("language", target)
		if cfg.get_option("language") != target:
			_fails.append("language should be '%s' after set, got '%s'" % [target, str(cfg.get_option("language"))])

func _test_persist_language() -> void:
	var cfg1 := ConfigStore.new(_tmp_dir)
	cfg1.set_option("language", "ja")
	var cfg2 := ConfigStore.new(_tmp_dir)
	if cfg2.get_option("language") != "ja":
		_fails.append("language not persisted, got '%s'" % str(cfg2.get_option("language")))

func _test_signal_emitted() -> void:
	var cfg := ConfigStore.new(_tmp_dir)
	var received := []
	cfg.option_changed.connect(func(k: String, v: Variant): received.append([k, v]))
	cfg.set_option("language", "ko")
	if received.size() != 1 or received[0][0] != "language" or received[0][1] != "ko":
		_fails.append("signal not emitted for language change, received=%s" % str(received))

func _test_invalid_language_rejected() -> void:
	var cfg := ConfigStore.new(_tmp_dir)
	cfg.set_option("language", "es")
	cfg.set_option("language", "fr")
	if cfg.get_option("language") != "es":
		_fails.append("unsupported language 'fr' should be rejected, got '%s'" % str(cfg.get_option("language")))

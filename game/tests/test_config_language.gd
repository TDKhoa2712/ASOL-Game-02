extends SceneTree

const ConfigStore = preload("res://scripts/state/config_store.gd")

var _fails: Array[String] = []
var _tmp_dir: String = ""

func _init() -> void:
	_tmp_dir = "user://test_config_lang_%d" % Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(_tmp_dir)

	_test_default_language()
	_clear_file()
	_test_set_language_en()
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

func _test_default_language() -> void:
	var cfg := ConfigStore.new(_tmp_dir)
	if cfg.get_option("language") != "vi":
		_fails.append("default language should be 'vi', got '%s'" % str(cfg.get_option("language")))

func _test_set_language_en() -> void:
	var cfg := ConfigStore.new(_tmp_dir)
	cfg.set_option("language", "en")
	if cfg.get_option("language") != "en":
		_fails.append("language should be 'en' after set, got '%s'" % str(cfg.get_option("language")))

func _test_persist_language() -> void:
	var cfg1 := ConfigStore.new(_tmp_dir)
	cfg1.set_option("language", "en")
	var cfg2 := ConfigStore.new(_tmp_dir)
	if cfg2.get_option("language") != "en":
		_fails.append("language not persisted, got '%s'" % str(cfg2.get_option("language")))

func _test_signal_emitted() -> void:
	var cfg := ConfigStore.new(_tmp_dir)
	var received := []
	cfg.option_changed.connect(func(k: String, v: Variant): received.append([k, v]))
	cfg.set_option("language", "en")
	if received.size() != 1 or received[0][0] != "language":
		_fails.append("signal not emitted for language change, received=%s" % str(received))

func _test_invalid_language_rejected() -> void:
	var cfg := ConfigStore.new(_tmp_dir)
	cfg.set_option("language", "fr")
	if cfg.get_option("language") != "vi":
		_fails.append("invalid language 'fr' should be rejected, got '%s'" % str(cfg.get_option("language")))

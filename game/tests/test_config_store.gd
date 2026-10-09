extends SceneTree

const Config = preload("res://scripts/state/config_store.gd")
var failures: Array[String] = []
var changes: Array = []

func _init() -> void:
	var dir := OS.get_user_data_dir().path_join("m02_config_%s" % Time.get_ticks_usec())
	var config := Config.new(dir)
	config.option_changed.connect(func(key: String, value: Variant) -> void: changes.append([key, value]))
	check(config.get_option("audio") == true, "default audio")
	config.set_option("audio", false)
	check(config.get_option("audio") == false, "set option")
	check(changes == [["audio", false]], "change signal")
	config.set_option("unknown", true)
	config.set_option("audio", "bad")
	check(changes.size() == 1, "reject invalid options")
	var reopened := Config.new(dir)
	check(reopened.get_option("audio") == false, "persist option")
	var copy := config.all_options()
	copy["audio"] = true
	check(config.get_option("audio") == false, "defensive copy")
	config.reset_defaults()
	check(config.get_option("audio") == true, "reset defaults")
	check(changes.back() == ["", null], "reset signal")
	check(config.get_option("music") == true, "default music")
	config.set_option("music", false)
	check(Config.new(dir).get_option("music") == false, "persist music")
	check(Config.new(dir).get_option("audio") == true, "music independent of sound")
	_write_legacy(dir, {"audio": false})
	check(Config.new(dir).get_option("music") == false, "legacy muted profile keeps music off")
	_write_legacy(dir, {"audio": false, "music": true})
	check(Config.new(dir).get_option("music") == true, "saved music wins over legacy fallback")
	DirAccess.remove_absolute(dir.path_join("config.json"))
	DirAccess.remove_absolute(dir)
	if failures.is_empty():
		print("STATE_CONFIG_PASS")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func _write_legacy(dir: String, options: Dictionary) -> void:
	var file := FileAccess.open(dir.path_join("config.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "options": options}))
	file.close()

func check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

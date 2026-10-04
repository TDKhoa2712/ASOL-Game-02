extends SceneTree

const Config = preload("res://scripts/state/config_store.gd")
var failures: Array[String] = []
var changes: Array = []

func _init() -> void:
	var dir := OS.get_user_data_dir().path_join("m02_config_%s" % Time.get_ticks_usec())
	var config := Config.new(dir)
	config.option_changed.connect(func(key: String, value: Variant) -> void: changes.append([key, value]))
	check(config.get_option("audio") == true, "default audio")
	check(config.get_option("undo_x") == true, "default undo_x")
	config.set_option("audio", false)
	check(config.get_option("audio") == false, "set option")
	check(changes == [["audio", false]], "change signal")
	config.set_option("undo_x", false)
	check(config.get_option("undo_x") == false, "set undo_x off")
	config.set_option("unknown", true)
	config.set_option("audio", "bad")
	check(changes.size() == 2, "reject invalid options")
	var reopened := Config.new(dir)
	check(reopened.get_option("audio") == false, "persist option")
	var copy := config.all_options()
	copy["audio"] = true
	check(config.get_option("audio") == false, "defensive copy")
	config.reset_defaults()
	check(config.get_option("audio") == true, "reset defaults")
	check(changes.back() == ["", null], "reset signal")
	DirAccess.remove_absolute(dir.path_join("config.json"))
	DirAccess.remove_absolute(dir)
	if failures.is_empty():
		print("STATE_CONFIG_PASS")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

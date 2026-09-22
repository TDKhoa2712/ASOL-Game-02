extends SceneTree


func _initialize() -> void:
	var presets := ConfigFile.new()
	var load_error := presets.load("res://export_presets.cfg")
	if load_error != OK:
		push_error("Could not load export_presets.cfg: %s" % error_string(load_error))
		quit(1)
		return

	var expected := [
		{
			"section": "preset.0",
			"options": "preset.0.options",
			"name": "Android M0 Debug",
			"platform": "Android",
			"export_path": "build/android/asol-game-02-debug.apk",
			"identifier_key": "package/unique_name",
		},
		{
			"section": "preset.1",
			"options": "preset.1.options",
			"name": "iOS M0 Debug",
			"platform": "iOS",
			"export_path": "build/ios/asol-game-02",
			"identifier_key": "application/bundle_identifier",
		},
	]

	for entry: Dictionary in expected:
		if presets.get_value(entry.section, "name", "") != entry.name:
			_fail("Unexpected export preset name for %s" % entry.section)
			return
		if presets.get_value(entry.section, "platform", "") != entry.platform:
			_fail("Unexpected export platform for %s" % entry.section)
			return
		if presets.get_value(entry.section, "export_path", "") != entry.export_path:
			_fail("Unexpected export path for %s" % entry.section)
			return
		if presets.get_value(entry.section, "script_export_mode", -1) != 2:
			_fail("GDScript source is not configured for compiled export")
			return
		if presets.get_value(entry.options, entry.identifier_key, "") != "org.asol.game02":
			_fail("Unexpected application identifier for %s" % entry.section)
			return

	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

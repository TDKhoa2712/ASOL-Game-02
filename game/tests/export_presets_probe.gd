extends SceneTree

const RELEASE_VERSION := "1.0.1"
const RELEASE_EXCLUDES := ["tests/*", "tools/*", "assets/ui/source/*", "scenes/sfx_tuner.tscn", "scripts/feedback/sfx_tuner.gd"]


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
		{
			"section": "preset.2",
			"options": "preset.2.options",
			"name": "Android Release",
			"platform": "Android",
			"export_path": "build/android/candoku-v1.0.1.apk",
			"identifier_key": "package/unique_name",
			"version_key": "version/name",
		},
		{
			"section": "preset.3",
			"options": "preset.3.options",
			"name": "iOS Release",
			"platform": "iOS",
			"export_path": "build/ios/candoku-v1.0.1",
			"identifier_key": "application/bundle_identifier",
			"version_key": "application/short_version",
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
		if entry.has("version_key") and not _is_release_ready(presets, entry):
			return

	quit(0)


func _is_release_ready(presets: ConfigFile, entry: Dictionary) -> bool:
	if presets.get_value(entry.options, entry.version_key, "") != RELEASE_VERSION:
		_fail("Release version is not %s for %s" % [RELEASE_VERSION, entry.section])
		return false
	var excluded: String = presets.get_value(entry.section, "exclude_filter", "")
	for pattern: String in RELEASE_EXCLUDES:
		if not excluded.split(",").has(pattern):
			_fail("Release preset %s does not exclude %s" % [entry.section, pattern])
			return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

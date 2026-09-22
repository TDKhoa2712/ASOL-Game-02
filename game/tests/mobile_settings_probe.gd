extends SceneTree


func _initialize() -> void:
	var expected := {
		"display/window/size/viewport_width": 1080,
		"display/window/size/viewport_height": 1920,
		"display/window/stretch/mode": "canvas_items",
		"display/window/stretch/aspect": "expand",
		"display/window/handheld/orientation": 1,
		"rendering/renderer/rendering_method": "mobile",
		"rendering/renderer/rendering_method.mobile": "mobile",
	}

	for setting: String in expected:
		var actual: Variant = ProjectSettings.get_setting(setting, null)
		if actual != expected[setting]:
			push_error("%s expected %s, got %s" % [setting, expected[setting], actual])
			quit(1)
			return

	quit(0)

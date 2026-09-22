extends SceneTree


func _initialize() -> void:
	var compression_enabled: bool = ProjectSettings.get_setting(
		"rendering/textures/vram_compression/import_etc2_astc",
		false,
	)
	if not compression_enabled:
		push_error("ETC2/ASTC texture compression must be enabled for Android export")
		quit(1)
		return

	quit(0)


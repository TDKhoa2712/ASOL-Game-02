extends SceneTree


func _initialize() -> void:
	if not ProjectSettings.has_setting("application/config/name"):
		push_error("Missing application/config/name; project.godot was not loaded")
		quit(1)
		return

	var features: PackedStringArray = ProjectSettings.get_setting("application/config/features", PackedStringArray())
	if not features.has("4.7"):
		push_error("Project is not pinned to the Godot 4.7 feature set")
		quit(1)
		return

	quit(0)

extends SceneTree

const Runtime = preload("res://scripts/mvp_runtime.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var profile := OS.get_user_data_dir().path_join("r1_profile_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()])
	var supplied = Runtime.new(profile)
	var bootstrap = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	bootstrap.runtime = supplied
	root.add_child(bootstrap)
	await process_frame
	# Stop before any gameplay/save action if bootstrap discarded the profile.
	if bootstrap.runtime != supplied:
		push_error("FAIL: bootstrap discarded the supplied isolated runtime")
		bootstrap.free()
		DirAccess.remove_absolute(profile)
		quit(1)
		return
	bootstrap.get_node("ScreenHost/Home/SafeArea/Content/Stack/PlayButton").pressed.emit()
	await process_frame
	supplied.apply_action({"type": "MarkX", "cell": [0, 0]})
	var restored = Runtime.new(profile)
	var ok: bool = restored.initialize() and restored.engine.session.cell_state([0, 0]) == "x"
	bootstrap.free()
	supplied.clear_saved_state()
	DirAccess.remove_absolute(profile)
	if not ok:
		push_error("FAIL: bootstrap gameplay did not persist in the supplied profile")
		quit(1)
		return
	print("R1_BOOTSTRAP_PROFILE_PASS")
	quit(0)

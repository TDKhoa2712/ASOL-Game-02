extends SceneTree

const BootstrapScene = preload("res://scenes/bootstrap.tscn")
const Runtime = preload("res://scripts/mvp_runtime.gd")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() != 1 or not arguments[0].is_absolute_path():
		push_error("Pass one absolute output directory after --")
		quit(2)
		return
	var output_dir: String = arguments[0]
	if DirAccess.make_dir_recursive_absolute(output_dir) != OK:
		push_error("Cannot create screenshot directory")
		quit(2)
		return
	root.size = Vector2i(1080, 1920)
	var profile := OS.get_user_data_dir().path_join("r1_capture_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()])
	var screen = BootstrapScene.instantiate()
	screen.runtime = Runtime.new(profile)
	root.add_child(screen)
	await process_frame
	if not await _save_frame(output_dir.path_join("home.png")):
		_cleanup(screen, profile)
		quit(1)
		return
	screen.get_node("ScreenHost/Home/SafeArea/Content/Stack/SettingsButton").pressed.emit()
	await process_frame
	if not await _save_frame(output_dir.path_join("settings_home.png")):
		_cleanup(screen, profile)
		quit(1)
		return
	screen.get_node("ScreenHost/Settings/SafeArea/Content/Stack/BackButton").pressed.emit()
	await process_frame
	screen.get_node("ScreenHost/Home/SafeArea/Content/Stack/PlayButton").pressed.emit()
	await process_frame
	if not await _save_frame(output_dir.path_join("puzzle.png")):
		_cleanup(screen, profile)
		quit(1)
		return
	screen.get_node("ScreenHost/BoardScreen").find_child("SettingsButton", true, false).pressed.emit()
	await process_frame
	if not await _save_frame(output_dir.path_join("settings_board.png")):
		_cleanup(screen, profile)
		quit(1)
		return
	screen.get_node("ScreenHost/Settings/SafeArea/Content/Stack/BackButton").pressed.emit()
	await process_frame
	for row in range(4):
		screen.runtime.apply_action({"type": "TryCat", "cell": [row, [1, 3, 0, 2][row]]})
	await process_frame
	await process_frame
	var ok := await _save_frame(output_dir.path_join("result_win.png"))
	if ok:
		screen.get_node("ScreenHost/ResultWin/SafeArea/Content/Stack/ContinueButton").pressed.emit()
		await process_frame
		for row in range(3):
			screen.runtime.apply_action({"type": "TryCat", "cell": [row, 0]})
		await process_frame
		await process_frame
		ok = await _save_frame(output_dir.path_join("result_fail.png"))
	_cleanup(screen, profile)
	quit(0 if ok else 1)

func _save_frame(path: String) -> bool:
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(path)
	if result != OK:
		push_error("Screenshot failed: %s (%d)" % [path, result])
		return false
	print("R1_SCREENSHOT_SAVED: %s" % path)
	return true

func _cleanup(screen: Node, profile: String) -> void:
	screen.runtime.clear_saved_state()
	screen.free()
	DirAccess.remove_absolute(profile)

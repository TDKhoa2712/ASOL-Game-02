extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() != 1:
		push_error("Pass one absolute PNG output path after --")
		quit(2)
		return
	root.size = Vector2i(1080, 1920)
	var screen: Control = load("res://scenes/mobile_rendering_spike.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var result := image.save_png(arguments[0])
	screen.queue_free()
	if result != OK:
		push_error("Failed to save spike screenshot: %d" % result)
		quit(1)
	else:
		print("M0_A03_SCREENSHOT_SAVED: %s" % arguments[0])
		quit(0)

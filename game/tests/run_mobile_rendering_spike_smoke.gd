extends SceneTree


const SCENE_PATH := "res://scenes/mobile_rendering_spike.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	if not ResourceLoader.exists(SCENE_PATH):
		_fail("Mobile rendering spike scene is missing")
		return

	root.size = Vector2i(1080, 1920)
	var screen: Control = load(SCENE_PATH).instantiate()
	root.add_child(screen)
	await process_frame

	var board: Control = screen.get_node("Board6x6")
	var board_rect := board.get_global_rect()
	_expect(board_rect.position.x >= 54.0, "Board intrudes into left safe inset", failures)
	_expect(board_rect.end.x <= 1026.0, "Board intrudes into right safe inset", failures)
	_expect(board_rect.position.y >= 120.0, "Board intrudes into top safe inset", failures)
	_expect(board_rect.end.y <= 1740.0, "Board intrudes into bottom controls", failures)
	_expect(board_rect.size.x >= 600.0, "Six-cell board is too small for the probe", failures)

	var labels := screen.get_node("RegionLabels").get_children()
	_expect(labels.size() == 6, "Every region needs a visible text label", failures)
	var expected_labels := ["A", "B", "C", "D", "E", "F"]
	for index in range(mini(labels.size(), 6)):
		_expect(labels[index].text == expected_labels[index], "Region labels must remain ordered", failures)

	var cats := screen.get_node("CatSprites").get_children()
	_expect(cats.size() == 6, "Probe needs six visible cat placements", failures)
	if cats.size() == 6:
		var first_frame: AtlasTexture = cats[0].texture as AtlasTexture
		_expect(first_frame != null, "Cat must use a frame from the atlas", failures)
		for cat in cats:
			var frame: AtlasTexture = cat.texture as AtlasTexture
			_expect(frame != null, "Cat must use a frame from the atlas", failures)
			if frame != null and first_frame != null:
				_expect(frame.atlas == first_frame.atlas, "Region must not load a separate cat atlas", failures)
			_expect(cat.modulate == Color.WHITE, "Region tint must not recolor the cat", failures)

	var sticker: Control = screen.get_node("Sticker")
	_expect(not sticker.visible, "Sticker must start hidden", failures)
	screen.trigger_success()
	_expect(sticker.visible, "Success must show a short sticker", failures)
	await create_timer(0.75).timeout
	_expect(not sticker.visible, "Sticker must clear after the short feedback", failures)
	screen.trigger_success()
	screen.trigger_error()
	_expect(not sticker.visible, "Error must clear the success sticker", failures)
	_expect(screen.get_node("ErrorBadge").visible, "Error needs a non-color warning", failures)

	_expect(screen.has_method("start_measurement"), "Probe must offer on-screen measurement", failures)
	if screen.has_method("start_measurement"):
		screen.start_measurement(0.15, 0.0)
		await create_timer(0.25).timeout
		var result: Dictionary = screen.measurement_result()
		_expect(result.get("status") == "complete", "Measurement must complete without ADB", failures)
		_expect(int(result.get("frames", 0)) > 0, "Measurement must sample rendered frames", failures)
		_expect(screen.get_node("ProbeResults").visible, "Results must be visible for a phone screenshot", failures)
		_expect(screen.get_node("ProbeResults").text.contains("Hoàn tất"), "Results must state completion on screen", failures)

	screen.queue_free()
	if failures.is_empty():
		print("M0_A03_RENDERING_SPIKE_PASS")
		quit(0)
	else:
		_fail("\n".join(failures))


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

extends SceneTree

const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ResourceLoader.exists("res://scenes/sfx_tuner.tscn"):
		printerr("FAIL: tuner scene missing")
		quit(1)
		return
	var tuner = load("res://scenes/sfx_tuner.tscn").instantiate()
	root.add_child(tuner)
	await process_frame
	_check(tuner._preset_dropdown.item_count == 9, "all effects selectable")
	_check(is_equal_approx(tuner._current_params().freq, 600.0), "initial MARK loaded")
	tuner._preset_dropdown.grab_focus()
	var space := InputEventKey.new()
	space.keycode = KEY_SPACE
	space.pressed = true
	root.push_input(space)
	_check(tuner._player.playing, "Space previews while dropdown has focus")
	if OS.get_cmdline_user_args().has("--capture"):
		tuner._on_copy_params()
		_check(DisplayServer.clipboard_get() == tuner._params_literal(tuner._current_params()), "Copy button writes clipboard")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../scratch/verification/sfx-tuner-mark.png"))
	for effect in SfxCatalog.Effect.values():
		tuner._preset_dropdown.select(effect)
		tuner._preset_dropdown.item_selected.emit(effect)
		if effect == 4 and OS.get_cmdline_user_args().has("--capture"):
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../scratch/verification/sfx-tuner-melody.png"))
		var params: Dictionary = tuner._current_params()
		var preset: Dictionary = SfxCatalog.PRESETS.get(effect, SfxCatalog.MELODY_PRESETS.get(effect, {}))
		for key in preset:
			if preset[key] is Array:
				_check(params.get(key) == preset[key], "melody notes preserved")
			else:
				_check(is_equal_approx(float(params.get(key, -999)), float(preset[key])), "preset %d loads %s" % [effect, key])
		tuner._on_play()
		_check(tuner._player.playing, "preview plays")
		var expected_bytes := 0
		if params.has("freqs"):
			expected_bytes = int(22050 * params.note_dur) * params.freqs.size() * 2
		else:
			expected_bytes = int(22050 * params.duration) * 2
		_check(tuner._player.stream.data.size() == expected_bytes, "preview renders selected sound duration")
		var literal: String = tuner._params_literal(params)
		var script := GDScript.new()
		script.source_code = 'extends RefCounted\nconst PcmSynth = preload("res://scripts/feedback/pcm_synth.gd")\nfunc params() -> Dictionary:\n\treturn ' + literal.replace("\n", "\n\t")
		var parsed := script.reload()
		_check(parsed == OK, "copied dictionary parses as GDScript")
		if parsed == OK:
			var exported = script.new()
			var copied: Dictionary = exported.params()
			_check(copied.size() == params.size(), "copy preserves parameter keys")
			for key in params:
				if params[key] is Array:
					_check(copied.get(key) == params[key], "copy preserves note sequence")
				else:
					_check(absf(float(copied.get(key, -999)) - float(params[key])) < 0.0000001,
						"copy preserves %s numeric value" % key)
	# Editing real controls changes the generated sound and keeps enum types.
	tuner._preset_dropdown.select(0)
	tuner._preset_dropdown.item_selected.emit(0)
	tuner._sliders.duration.value = 1.0
	tuner._sliders.freq.value = -20.0
	tuner._sliders.sustain.value = 2.0
	tuner._choices.wave.select(1)
	tuner._on_play()
	_check(tuner._player.stream.data.size() == 44100, "duration slider changes preview")
	_check(tuner._current_params().freq >= 20.0, "frequency control rejects negative values")
	_check(tuner._current_params().sustain <= 1.0, "sustain control bounded")
	_check(tuner._current_params().wave is int, "wave dropdown exports enum int")
	_check(tuner._labels.duration.text == "1.000", "numeric value label updates")
	tuner._preset_dropdown.select(4)
	tuner._preset_dropdown.item_selected.emit(4)
	tuner._notes.text = "bad input"
	tuner._player.stop()
	tuner._on_play()
	_check(not tuner._player.playing and not tuner._status.text.is_empty(), "invalid notes show validation without playback")
	tuner.free()
	var cleanup_ms := Time.get_ticks_msec()
	while Time.get_ticks_msec() - cleanup_ms < 100: await process_frame
	if failures.is_empty():
		print("SFX_TUNER_PASS")
		quit(0)
	else:
		for failure in failures: printerr(failure)
		quit(1)

func _check(ok: bool, label: String) -> void:
	if not ok: failures.append("FAIL: " + label)

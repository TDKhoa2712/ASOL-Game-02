extends SceneTree

const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")
const SfxPlayer = preload("res://scripts/feedback/sfx_player.gd")
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
	_check(tuner._preset_dropdown.item_count == SfxCatalog.Effect.size(), "all effects selectable")
	_check(tuner._current_params().get("type") == "pencil", "initial MARK uses pencil sound")
	_check(is_equal_approx(tuner._current_params().get("high_pass", 0.0),
		SfxCatalog.PENCIL_PRESETS[SfxCatalog.Effect.MARK].high_pass), "MARK pencil high pass loaded")
	_check(is_equal_approx(tuner._current_params().get("speed", 0.0),
		SfxCatalog.PENCIL_PRESETS[SfxCatalog.Effect.MARK].speed), "MARK speed matches catalog")
	var runtime_player := SfxPlayer.new()
	root.add_child(runtime_player)
	tuner._preset_dropdown.grab_focus()
	var space := InputEventKey.new()
	space.keycode = KEY_SPACE
	space.pressed = true
	root.push_input(space)
	_check(tuner._player.playing, "Space previews while dropdown has focus")
	if OS.get_cmdline_user_args().has("--capture"):
		tuner._on_copy_params()
		_check(DisplayServer.clipboard_get().replace("\r\n", "\n") == tuner._params_literal(tuner._current_params()), "Copy button writes clipboard")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../scratch/verification/sfx-tuner-mark.png"))
	for effect in SfxCatalog.Effect.values():
		tuner._preset_dropdown.select(effect)
		tuner._preset_dropdown.item_selected.emit(effect)
		if effect == SfxCatalog.Effect.STAGE_CLEAR and OS.get_cmdline_user_args().has("--capture"):
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../scratch/verification/sfx-tuner-melody.png"))
		var params: Dictionary = tuner._current_params()
		var preset: Dictionary = SfxCatalog.PENCIL_PRESETS.get(effect,
			SfxCatalog.PRESETS.get(effect, SfxCatalog.MELODY_PRESETS.get(effect, {})))
		for key in preset:
			if preset[key] is Array:
				_check(params.get(key) == preset[key], "melody notes preserved")
			elif preset[key] is String:
				_check(params.get(key) == preset[key], "preset %d loads %s" % [effect, key])
			else:
				_check(is_equal_approx(float(params.get(key, -999)), float(preset[key])), "preset %d loads %s" % [effect, key])
		tuner._on_play()
		_check(tuner._player.playing, "preview plays")
		if effect != SfxCatalog.Effect.MARK and effect != SfxCatalog.Effect.SETTINGS_OPEN \
				and float(preset.get("noise_mix", 0.0)) == 0.0:
			_check(tuner._player.stream.data == runtime_player._streams[effect].data,
				"untouched preview matches game PCM for %s" % SfxCatalog.Effect.find_key(effect))
		if effect == SfxCatalog.Effect.SETTINGS_OPEN:
			_check(params.get("type") == "file", "settings tuner selects source file")
			_check(tuner._player.stream is AudioStreamOggVorbis,
				"settings tuner previews OGG")
			_check(tuner._player.stream == runtime_player._streams[effect],
				"settings tuner and game use the same audio resource")
			_check(tuner._rows.speed.visible and not tuner._rows.duration.visible,
				"settings file offers speed control without synth controls")
		else:
			var expected_bytes := 0
			if params.has("freqs"):
				expected_bytes = int(22050 * params.note_dur) * params.freqs.size() * 2
			else:
				expected_bytes = int(22050 * params.duration) * 2
			_check(tuner._player.stream.data.size() == expected_bytes,
				"preview renders selected sound duration")
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
				elif params[key] is String:
					_check(copied.get(key) == params[key], "copy preserves pencil type")
				else:
					_check(absf(float(copied.get(key, -999)) - float(params[key])) < 0.0000001,
						"copy preserves %s numeric value" % key)
	# Editing real controls changes the generated sound and keeps enum types.
	tuner._preset_dropdown.select(SfxCatalog.Effect.UNMARK)
	tuner._preset_dropdown.item_selected.emit(SfxCatalog.Effect.UNMARK)
	tuner._sliders.duration.value = 1.0
	if tuner._sliders.has("speed"):
		tuner._sliders.speed.value = 1.5
	else:
		_check(false, "speed control exists")
	tuner._sliders.freq.value = -20.0
	tuner._sliders.sustain.value = 2.0
	tuner._choices.wave.select(1)
	tuner._on_play()
	_check(tuner._player.stream.data.size() == 44100, "duration slider changes preview")
	_check(is_equal_approx(tuner._player.pitch_scale, 1.5), "speed control changes preview playback rate")
	_check(is_equal_approx(tuner._current_params().get("speed", 0.0), 1.5), "speed exports with preset")
	_check(tuner._current_params().freq >= 20.0, "frequency control rejects negative values")
	_check(tuner._current_params().sustain <= 1.0, "sustain control bounded")
	_check(tuner._current_params().wave is int, "wave dropdown exports enum int")
	_check(tuner._labels.duration.text == "1.000", "numeric value label updates")
	tuner._preset_dropdown.select(SfxCatalog.Effect.MARK)
	tuner._preset_dropdown.item_selected.emit(SfxCatalog.Effect.MARK)
	if tuner._sliders.has("high_pass"):
		tuner._sliders.high_pass.value = 1200.0
		_check(is_equal_approx(tuner._current_params().get("high_pass", 0.0), 1200.0), "pencil filter can be tuned")
	else:
		_check(false, "pencil filter can be tuned")
	tuner._on_play()
	_check(tuner._player.stream.data.size() == int(22050 * tuner._current_params().duration) * 2,
		"pencil preview renders selected duration")
	tuner._preset_dropdown.select(SfxCatalog.Effect.STAGE_CLEAR)
	tuner._preset_dropdown.item_selected.emit(SfxCatalog.Effect.STAGE_CLEAR)
	tuner._notes.text = "bad input"
	tuner._player.stop()
	tuner._on_play()
	_check(not tuner._player.playing and not tuner._status.text.is_empty(), "invalid notes show validation without playback")
	runtime_player.free()
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

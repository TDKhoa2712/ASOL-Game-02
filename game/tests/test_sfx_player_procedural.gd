extends SceneTree

const SfxPlayer = preload("res://scripts/feedback/sfx_player.gd")
const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := SfxPlayer.new()
	# Calls before entering the tree must remain safe.
	player.play(SfxCatalog.Effect.BTN_PRESS)
	root.add_child(player)
	await process_frame
	_check(player.get_child_count() == 8, "eight voices prewarmed")
	for effect in SfxCatalog.Effect.values():
		_check(SfxCatalog.PRESETS.has(effect) or SfxCatalog.MELODY_PRESETS.has(effect)
			or SfxCatalog.PENCIL_PRESETS.has(effect), "preset for %d" % effect)
		player.play(effect)
		var voice: AudioStreamPlayer = player.get_child((effect + 8) % 8) if player.get_child_count() == 8 else null
		if voice != null:
			_check(voice.playing, "effect %d starts playback" % effect)
			if SfxCatalog.PRESETS.get(effect, {}).get("type", "") == "file":
				_check(voice.stream is AudioStreamOggVorbis and voice.stream.get_length() > 0.0,
					"effect %d plays its source OGG" % effect)
				if effect == SfxCatalog.Effect.SETTINGS_OPEN:
					_check(voice.stream.get_length() > 0.70 and voice.stream.get_length() < 0.82,
						"settings cue starts without the quiet lead-in")
			else:
				_check(voice.stream is AudioStreamWAV and voice.stream.data.size() > 0,
					"effect %d has PCM" % effect)
				_check(_has_audio(voice.stream), "effect %d is audible PCM" % effect)
			var preset: Dictionary = SfxCatalog.PENCIL_PRESETS.get(effect,
				SfxCatalog.PRESETS.get(effect, SfxCatalog.MELODY_PRESETS.get(effect, {})))
			var expected_speed := float(preset.get("speed", 1.0))
			_check(voice.pitch_scale >= 0.94 * expected_speed and voice.pitch_scale <= 1.06 * expected_speed,
				"pitch range follows preset speed")
			if not SfxCatalog.PITCH_RANDOMIZE.get(effect, false):
				_check(is_equal_approx(voice.pitch_scale, expected_speed), "fixed effect uses preset speed")
	for effect in [SfxCatalog.Effect.STAGE_CLEAR, SfxCatalog.Effect.STAGE_FAIL]:
		_check(SfxCatalog.PRESETS.get(effect, {}).get("type", "") == "file",
			"effect %d uses the win/lose melody OGG" % effect)
	player.set_muted(true)
	_check(player.is_muted(), "mute state")
	_check(_playing_count(player) == 0, "mute stops all voices")
	player.play(SfxCatalog.Effect.BTN_PRESS)
	_check(_playing_count(player) == 0, "mute prevents new playback")
	player.set_muted(false)
	# A fresh player isolates MARK's first timestamp.
	var limited := SfxPlayer.new()
	root.add_child(limited)
	limited.play(SfxCatalog.Effect.MARK)
	limited.play(SfxCatalog.Effect.MARK)
	_check(_playing_count(limited) == 1, "rapid MARK throttles second voice")
	var first_mark_ms := Time.get_ticks_msec()
	while Time.get_ticks_msec() - first_mark_ms < 120:
		await process_frame
	limited.play(SfxCatalog.Effect.MARK)
	_check(limited.get_child(1).stream != null, "MARK plays again after interval")
	for index in range(24):
		player.play(SfxCatalog.Effect.BTN_PRESS)
	_check(player.get_child_count() == 8 and _playing_count(player) == 8, "pool bounded during rapid reuse")
	var before := _playing_count(player)
	player.play(-1)
	_check(_playing_count(player) == before, "unknown effect ignored")
	player.set_muted(true)
	limited.set_muted(true)
	player.free()
	limited.free()
	# AudioServer releases stopped playback objects on its next mix cycle.
	var cleanup_ms := Time.get_ticks_msec()
	while Time.get_ticks_msec() - cleanup_ms < 100:
		await process_frame
	if failures.is_empty():
		print("SFX_PLAYER_PROCEDURAL_PASS")
		quit(0)
	else:
		for failure in failures: printerr(failure)
		quit(1)

func _has_audio(stream: AudioStreamWAV) -> bool:
	for index in range(0, stream.data.size(), 2):
		if abs(stream.data.decode_s16(index)) > 100: return true
	return false

func _playing_count(player: Node) -> int:
	var count := 0
	for child in player.get_children():
		if child is AudioStreamPlayer and child.playing: count += 1
	return count

func _check(ok: bool, label: String) -> void:
	if not ok: failures.append("FAIL: " + label)

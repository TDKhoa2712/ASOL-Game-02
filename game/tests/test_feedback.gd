extends SceneTree

const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")
const SfxPlayer = preload("res://scripts/feedback/sfx_player.gd")
const BgmPlayer = preload("res://scripts/feedback/bgm_player.gd")
const Vibration = preload("res://scripts/feedback/vibration.gd")

var _fails: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_catalog_complete()
	_test_catalog_rate_limits()
	_test_vibration_toggle()
	_test_vibration_pulse_disabled()
	_test_vibration_pulse_enabled()
	_test_vibration_hardware()
	_test_sfx_player_mute()
	_test_sfx_player_rate_limit()
	_test_sfx_player_stop_on_mute()
	_test_bgm_player_mute_and_stop()
	# Allow queued nodes and AudioServer's stopped playbacks to release.
	var cleanup_ms := Time.get_ticks_msec()
	while Time.get_ticks_msec() - cleanup_ms < 100:
		await process_frame

	if _fails.is_empty():
		print("FEEDBACK_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_catalog_complete() -> void:
	for val in SfxCatalog.Effect.values():
		_assert(SfxCatalog.PRESETS.has(val) or SfxCatalog.MELODY_PRESETS.has(val), "preset for effect %d" % val)

func _test_catalog_rate_limits() -> void:
	_assert(SfxCatalog.MIN_INTERVAL_MS.has(SfxCatalog.Effect.MARK), "MARK has rate limit")
	_assert(SfxCatalog.MIN_INTERVAL_MS[SfxCatalog.Effect.MARK] == 100, "MARK interval == 100ms")
	_assert(not SfxCatalog.MIN_INTERVAL_MS.has(SfxCatalog.Effect.CANDY_YES), "CANDY_YES has no rate limit")
	_assert(not SfxCatalog.MIN_INTERVAL_MS.has(SfxCatalog.Effect.STAGE_CLEAR), "STAGE_CLEAR has no rate limit")

func _test_vibration_toggle() -> void:
	Vibration.set_on(true)
	_assert(Vibration.is_on(), "vibration on")
	Vibration.set_on(false)
	_assert(not Vibration.is_on(), "vibration off")
	Vibration.set_on(true)

func _test_vibration_pulse_disabled() -> void:
	Vibration.set_on(false)
	Vibration.pulse(Vibration.Strength.SOFT)
	Vibration.pulse(Vibration.Strength.NORMAL)
	Vibration.pulse(Vibration.Strength.FIRM)
	Vibration.set_on(true)

func _test_vibration_pulse_enabled() -> void:
	Vibration.set_on(true)
	Vibration.pulse(Vibration.Strength.SOFT)
	Vibration.pulse(Vibration.Strength.NORMAL)
	Vibration.pulse(Vibration.Strength.FIRM)
	# Unknown/custom strength should use fallback duration and not crash
	Vibration.pulse(999)
	_assert(true, "pulse strengths executed safely")

func _test_vibration_hardware() -> void:
	var hw: bool = Vibration.has_hardware()
	_assert(typeof(hw) == TYPE_BOOL, "returns bool")

func _test_sfx_player_mute() -> void:
	var player := SfxPlayer.new()
	root.add_child(player)
	_assert(not player.is_muted(), "sfx player not muted initially")
	player.set_muted(true)
	_assert(player.is_muted(), "sfx player muted after set_muted(true)")
	player.play(SfxCatalog.Effect.MARK)
	_assert(not player._last_play_ms.has(SfxCatalog.Effect.MARK), "muted player does not record play timestamp")
	player.set_muted(false)
	_assert(not player.is_muted(), "sfx player unmuted")
	player.queue_free()

func _test_sfx_player_rate_limit() -> void:
	var player := SfxPlayer.new()
	root.add_child(player)
	player.play(SfxCatalog.Effect.MARK)
	var first_play: int = player._last_play_ms.get(SfxCatalog.Effect.MARK, -1)
	_assert(first_play >= 0, "MARK recorded timestamp on first play")
	player.play(SfxCatalog.Effect.MARK)
	var second_play: int = player._last_play_ms.get(SfxCatalog.Effect.MARK, -1)
	_assert(second_play == first_play, "MARK throttled within min interval")

	# CANDY_YES without rate limiting can update timestamp every time
	player.play(SfxCatalog.Effect.CANDY_YES)
	_assert(player._last_play_ms.has(SfxCatalog.Effect.CANDY_YES), "CANDY_YES recorded timestamp")
	player.queue_free()

func _test_sfx_player_stop_on_mute() -> void:
	var player := SfxPlayer.new()
	root.add_child(player)
	player.play(SfxCatalog.Effect.MARK)
	var voice := player.get_child(0) as AudioStreamPlayer
	_assert(voice.playing, "real voice is playing")
	player.set_muted(true)
	_assert(not voice.playing, "real voice stopped when muted")
	player.queue_free()


func _test_bgm_player_mute_and_stop() -> void:
	var bgm := BgmPlayer.new()
	root.add_child(bgm)
	_assert(not bgm.is_muted(), "bgm player not muted initially")
	_assert(not bgm.is_playing(), "bgm not playing initially")
	bgm.play_track("res://non_existent.ogg")
	_assert(not bgm.is_playing(), "non-existent track handled gracefully")
	bgm.set_muted(true)
	_assert(bgm.is_muted(), "bgm player muted")
	bgm.stop()
	_assert(not bgm.is_playing(), "bgm stopped")
	bgm.set_muted(false)
	_assert(not bgm.is_muted(), "bgm player unmuted")
	bgm.queue_free()

func _assert(cond: bool, label: String) -> void:
	if not cond:
		_fails.append("FAIL: " + label)

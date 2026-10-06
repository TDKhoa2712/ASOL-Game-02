extends SceneTree

const PcmSynth = preload("res://scripts/feedback/pcm_synth.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var stream := PcmSynth.generate({"freq": 440.0, "duration": 0.1, "volume": 0.3, "wave": PcmSynth.Wave.SINE})
	_check(stream is AudioStreamWAV, "returns WAV")
	_check(stream.format == AudioStreamWAV.FORMAT_16_BITS, "16 bit")
	_check(stream.mix_rate == 22050 and not stream.stereo, "22050 Hz mono")
	_check(stream.data.size() == 4410, "duration matches sample count")
	_test_clipping()
	_test_edge_ramps()
	_test_zero_endpoint_sweeps()
	var melody := PcmSynth.generate_melody([440.0, 550.0, 660.0], 0.1, 0.3, PcmSynth.Wave.TRIANGLE)
	_check(melody.data.size() == 13230, "melody concatenates three notes")
	_test_pencil_scratch()
	_test_settings_swipe()
	if failures.is_empty():
		print("PCM_SYNTH_PASS")
		quit(0)
	else:
		for failure in failures: printerr(failure)
		quit(1)

func _test_pencil_scratch() -> void:
	var pencil := PcmSynth.generate_pencil_scratch({"duration": 0.12, "volume": 0.35})
	_check(pencil is AudioStreamWAV, "pencil scratch returns AudioStreamWAV")
	_check(pencil.format == AudioStreamWAV.FORMAT_16_BITS, "pencil scratch is 16 bit")
	_check(pencil.mix_rate == 22050 and not pencil.stereo, "pencil scratch is 22050 Hz mono")
	_check(pencil.data.decode_s16(0) == 0, "pencil scratch starts at silence")
	_check(pencil.data.decode_s16(pencil.data.size() - 2) == 0, "pencil scratch ends at silence")
	var generated_via_preset := PcmSynth.generate({"type": "pencil", "duration": 0.12})
	_check(generated_via_preset is AudioStreamWAV, "generate with type pencil works")

func _test_settings_swipe() -> void:
	var params := {"type": "settings_swipe", "duration": 0.11, "volume": 0.3,
		"noise_mix": 0.85, "snap_mix": 0.65, "high_pass": 1200.0, "low_pass": 6200.0}
	var swipe := PcmSynth.generate(params)
	_check(swipe is AudioStreamWAV and swipe.data.size() == int(22050 * 0.11) * 2,
		"settings swipe renders requested duration")
	_check(swipe.data.decode_s16(0) == 0 and swipe.data.decode_s16(swipe.data.size() - 2) == 0,
		"settings swipe has silent endpoints")
	var early_energy := _window_energy(swipe.data, 0.02, 0.035)
	var snap_energy := _window_energy(swipe.data, 0.055, 0.067)
	var tail_energy := _window_energy(swipe.data, 0.09, 0.105)
	_check(early_energy > 500.0 and snap_energy > 500.0 and tail_energy < snap_energy,
		"fast stick whip has a rushing body, sharp snap, and brief tail")
	params["noise_mix"] = 0.0
	params["snap_mix"] = 0.0
	var silent := PcmSynth.generate(params)
	_check(_window_energy(silent.data, 0.02, 0.1) == 0.0,
		"zero swish and snap mix silences both whip layers")
	params["snap_mix"] = 1.0
	var crack := PcmSynth.generate(params)
	_check(_window_energy(crack.data, 0.02, 0.035) < 20.0
		and _window_energy(crack.data, 0.055, 0.067) > 500.0,
		"snap mix controls the dry crack separately")

func _window_energy(data: PackedByteArray, start: float, end: float) -> float:
	var total := 0.0
	var count := 0
	for index in range(int(start * 22050), int(end * 22050)):
		total += absf(float(data.decode_s16(index * 2)))
		count += 1
	return total / maxf(1.0, float(count))

func _test_clipping() -> void:
	var params := {"freq": 0.0, "duration": 0.05, "volume": 2.0,
		"wave": PcmSynth.Wave.SQUARE, "attack": 0.005, "decay": 0.0,
		"release": 0.01, "sustain": 1.0}
	var positive := PcmSynth.generate(params)
	_check(positive.data.decode_s16(440) == 32767, "positive overdrive saturates without wrapping")
	params["duty_cycle"] = 0.0
	var negative := PcmSynth.generate(params)
	_check(negative.data.decode_s16(440) == -32767, "negative overdrive saturates without wrapping")

func _test_edge_ramps() -> void:
	var params := {"freq": 0.0, "duration": 0.05, "volume": 1.0,
		"wave": PcmSynth.Wave.SQUARE, "attack": 0.0, "decay": 0.0,
		"release": 0.0, "sustain": 1.0}
	_check_ramps(PcmSynth.generate(params).data, "zero attack/release")
	params.merge({"duration": 0.02, "attack": 0.005, "decay": 0.3, "release": 0.01}, true)
	_check_ramps(PcmSynth.generate(params).data, "oversized shortest envelope")
	params.merge({"duration": 0.02, "attack": 0.3, "decay": 0.3, "release": 0.3}, true)
	_check_ramps(PcmSynth.generate(params).data, "all oversized envelope segments")
	var melody := PcmSynth.generate_melody([0.0, 0.0], 0.02, 1.0, PcmSynth.Wave.SQUARE)
	var note_bytes := 441 * 2
	_check_ramps(melody.data.slice(0, note_bytes), "short melody first note")
	_check_ramps(melody.data.slice(note_bytes), "short melody next note")
	params["duration"] = 0.001
	var tiny := PcmSynth.generate(params).data
	_check(tiny.decode_s16(0) == 0 and tiny.decode_s16(tiny.size() - 2) == 0,
		"sub-minimum duration still has silent endpoints")

func _check_ramps(data: PackedByteArray, label: String) -> void:
	_check(data.decode_s16(0) == 0, label + " begins at silence")
	_check(data.decode_s16(data.size() - 2) == 0, label + " ends at silence")
	# A constant positive square isolates the envelope from oscillator phase.
	_check(data.decode_s16(44) > 0 and data.decode_s16(44) < 8000,
		label + " preserves at least 5 ms attack")
	_check(data.decode_s16(data.size() - 46) > 0 and data.decode_s16(data.size() - 46) < 4000,
		label + " preserves at least 10 ms release")

func _test_zero_endpoint_sweeps() -> void:
	for endpoints in [[440.0, 0.0], [0.0, 440.0]]:
		var params := {"freq": endpoints[0], "end_freq": endpoints[1], "duration": 0.05,
			"pitch_curve": PcmSynth.PitchCurve.EXPONENTIAL}
		var exponential := PcmSynth.generate(params)
		params["pitch_curve"] = PcmSynth.PitchCurve.LINEAR
		_check(exponential.data == PcmSynth.generate(params).data,
			"zero endpoint exponential sweep falls back to linear PCM")

func _check(ok: bool, label: String) -> void:
	if not ok: failures.append("FAIL: " + label)

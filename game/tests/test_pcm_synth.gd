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
	var loud := PcmSynth.generate({"freq": 440.0, "duration": 0.05, "volume": 2.0, "wave": PcmSynth.Wave.SQUARE})
	for i in range(0, loud.data.size(), 2):
		_check(abs(loud.data.decode_s16(i)) <= 32767, "clamped sample")
	var short := PcmSynth.generate({"duration": 0.05, "attack": 0.1, "decay": 0.1, "release": 0.1})
	_check(short.data.size() == 2204, "oversized envelope scales")
	var zero := PcmSynth.generate({"freq": 440.0, "end_freq": 0.0, "duration": 0.05, "pitch_curve": PcmSynth.PitchCurve.EXPONENTIAL})
	_check(zero.data.size() == 2204, "zero end frequency does not break sweep")
	var melody := PcmSynth.generate_melody([440.0, 550.0, 660.0], 0.1, 0.3, PcmSynth.Wave.TRIANGLE)
	_check(melody.data.size() == 13230, "melody concatenates three notes")
	if failures.is_empty():
		print("PCM_SYNTH_PASS")
		quit(0)
	else:
		for failure in failures: printerr(failure)
		quit(1)

func _check(ok: bool, label: String) -> void:
	if not ok: failures.append("FAIL: " + label)

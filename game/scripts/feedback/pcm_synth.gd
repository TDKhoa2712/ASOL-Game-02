class_name PcmSynth
extends RefCounted

enum Wave { SINE, SQUARE, TRIANGLE, SAWTOOTH }
enum PitchCurve { LINEAR, EXPONENTIAL }

const SAMPLE_RATE: int = 22050

static func generate(params: Dictionary) -> AudioStreamWAV:
	var frequency: float = maxf(0.0, float(params.get("freq", 440.0)))
	var end_frequency: float = float(params.get("end_freq", frequency))
	var duration: float = maxf(0.0, float(params.get("duration", 0.15)))
	var volume: float = float(params.get("volume", 0.5))
	var wave: int = int(params.get("wave", Wave.TRIANGLE))
	var noise_mix: float = clampf(float(params.get("noise_mix", 0.0)), 0.0, 1.0)
	var noise_decay: float = float(params.get("noise_decay", 0.05))
	var attack: float = maxf(0.0, float(params.get("attack", 0.01)))
	var decay: float = maxf(0.0, float(params.get("decay", 0.03)))
	var release: float = maxf(0.0, float(params.get("release", 0.04)))
	var sustain: float = clampf(float(params.get("sustain", 0.6)), 0.0, 1.0)
	var curve: int = int(params.get("pitch_curve", PitchCurve.LINEAR))
	var low_pass: float = float(params.get("low_pass", -1.0))
	var duty: float = clampf(float(params.get("duty_cycle", 0.5)), 0.0, 1.0)
	var envelope_total := attack + decay + release
	if envelope_total > duration and envelope_total > 0.0:
		var scale := duration / envelope_total
		attack *= scale
		decay *= scale
		release *= scale
	var count := int(SAMPLE_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase := 0.0
	var filtered := 0.0
	var alpha := 1.0
	if low_pass > 0.0:
		alpha = clampf(TAU * low_pass / SAMPLE_RATE, 0.0, 1.0)
	for index in range(count):
		var time := float(index) / SAMPLE_RATE
		var progress := time / duration
		var current_frequency := frequency + (end_frequency - frequency) * progress
		if curve == PitchCurve.EXPONENTIAL and frequency > 0.0 and end_frequency > 0.0:
			current_frequency = frequency * pow(end_frequency / frequency, progress)
		phase = fposmod(phase + TAU * current_frequency / SAMPLE_RATE, TAU)
		var sample := _wave_sample(wave, phase, duty)
		if noise_mix > 0.0:
			var amount := noise_mix
			if noise_decay > 0.0:
				amount *= exp(-time / noise_decay)
			sample = lerpf(sample, randf_range(-1.0, 1.0), amount)
		if low_pass > 0.0:
			filtered += alpha * (sample - filtered)
			sample = filtered
		sample *= volume * _envelope(time, duration, attack, decay, release, sustain)
		bytes.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _stream(bytes)

static func generate_melody(frequencies: Array[float], note_duration: float = 0.1,
		volume: float = 0.4, wave: int = Wave.TRIANGLE) -> AudioStreamWAV:
	var samples_per_note := int(SAMPLE_RATE * maxf(note_duration, 0.0))
	var bytes := PackedByteArray()
	bytes.resize(samples_per_note * frequencies.size() * 2)
	for note in range(frequencies.size()):
		var phase := 0.0
		for index in range(samples_per_note):
			var time := float(index) / SAMPLE_RATE
			phase = fposmod(phase + TAU * frequencies[note] / SAMPLE_RATE, TAU)
			var envelope := _envelope(time, note_duration, note_duration * 0.15,
				0.0, note_duration * 0.2, 1.0)
			var sample := _wave_sample(wave, phase, 0.5) * volume * envelope
			bytes.encode_s16((note * samples_per_note + index) * 2,
				int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _stream(bytes)

static func _stream(bytes: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return stream

static func _wave_sample(wave: int, phase: float, duty: float) -> float:
	match wave:
		Wave.SINE: return sin(phase)
		Wave.SQUARE: return 1.0 if phase / TAU < duty else -1.0
		Wave.TRIANGLE: return 2.0 / PI * asin(sin(phase))
		Wave.SAWTOOTH: return 2.0 * (phase / TAU) - 1.0
	return 0.0

static func _envelope(time: float, duration: float, attack: float, decay: float,
		release: float, sustain: float) -> float:
	if attack > 0.0 and time < attack:
		return time / attack
	if decay > 0.0 and time < attack + decay:
		return 1.0 - (1.0 - sustain) * (time - attack) / decay
	if release > 0.0 and time >= duration - release:
		return sustain * (duration - time) / release
	return sustain

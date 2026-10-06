class_name PcmSynth
extends RefCounted

enum Wave { SINE, SQUARE, TRIANGLE, SAWTOOTH }
enum PitchCurve { LINEAR, EXPONENTIAL }

const SAMPLE_RATE: int = 22050
const MIN_ATTACK: float = 0.005
const MIN_RELEASE: float = 0.01

static func generate(params: Dictionary) -> AudioStreamWAV:
	if params.get("type", "") == "pencil":
		return generate_pencil_scratch(params)
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
	var envelope := _fit_envelope(duration, attack, decay, release)
	attack = envelope[0]
	decay = envelope[1]
	release = envelope[2]
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
		var edge_time := duration * index / (count - 1) if count > 1 else 0.0
		sample *= volume * _envelope(edge_time, duration, attack, decay, release, sustain)
		bytes.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _stream(bytes)

static func generate_melody(frequencies: Array[float], note_duration: float = 0.1,
		volume: float = 0.4, wave: int = Wave.TRIANGLE) -> AudioStreamWAV:
	var samples_per_note := int(SAMPLE_RATE * maxf(note_duration, 0.0))
	var bytes := PackedByteArray()
	bytes.resize(samples_per_note * frequencies.size() * 2)
	var fitted := _fit_envelope(maxf(note_duration, 0.0), note_duration * 0.15,
		0.0, note_duration * 0.2)
	for note in range(frequencies.size()):
		var phase := 0.0
		for index in range(samples_per_note):
			phase = fposmod(phase + TAU * frequencies[note] / SAMPLE_RATE, TAU)
			var edge_time := note_duration * index / (samples_per_note - 1) if samples_per_note > 1 else 0.0
			var envelope := _envelope(edge_time, note_duration, fitted[0], fitted[1], fitted[2], 1.0)
			var sample := _wave_sample(wave, phase, 0.5) * volume * envelope
			bytes.encode_s16((note * samples_per_note + index) * 2,
				int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _stream(bytes)

static func generate_pencil_scratch(params: Dictionary = {}) -> AudioStreamWAV:
	var duration: float = maxf(0.02, float(params.get("duration", 0.15)))
	var volume: float = float(params.get("volume", 0.25))
	var high_pass: float = float(params.get("high_pass", 850.0))
	var low_pass: float = float(params.get("low_pass", 2700.0))
	var count := int(SAMPLE_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var alpha_hp := clampf(TAU * high_pass / SAMPLE_RATE, 0.0, 1.0)
	var alpha_lp := clampf(TAU * low_pass / SAMPLE_RATE, 0.0, 1.0)
	var lp_sub := 0.0
	var lp_mid := 0.0
	var lp_final := 0.0
	var stroke1_end := duration * 0.44
	var stroke2_start := duration * 0.54
	for index in range(count):
		var time := float(index) / SAMPLE_RATE
		var raw_noise := randf_range(-1.0, 1.0)
		var grain := 0.85 + 0.15 * sin(float(index) * 0.18)
		var noise_sample := raw_noise * grain
		lp_sub += alpha_hp * (noise_sample - lp_sub)
		var hp := noise_sample - lp_sub
		lp_mid += alpha_lp * (hp - lp_mid)
		lp_final += alpha_lp * (lp_mid - lp_final)
		var sample := lp_final
		var env := 0.0
		if time < stroke1_end:
			var t1 := time / stroke1_end
			if t1 < 0.20: env = t1 / 0.20
			elif t1 < 0.75: env = 1.0 - 0.25 * ((t1 - 0.20) / 0.55)
			else: env = 0.75 * (1.0 - (t1 - 0.75) / 0.25)
		elif time < stroke2_start:
			env = 0.005
		else:
			var t2 := (time - stroke2_start) / (duration - stroke2_start)
			if t2 < 0.20: env = 0.005 + 0.995 * (t2 / 0.20)
			elif t2 < 0.75: env = 1.0 - 0.30 * ((t2 - 0.20) / 0.55)
			else: env = 0.70 * (1.0 - (t2 - 0.75) / 0.25)
		if index == 0 or index == count - 1:
			env = 0.0
		elif index < 44:
			env *= float(index) / 44.0
		elif index > count - 45:
			env *= float(count - 1 - index) / 44.0
		sample = clampf(sample * volume * env * 1.9, -1.0, 1.0)
		bytes.encode_s16(index * 2, int(sample * 32767.0))
	return _stream(bytes)

static func _fit_envelope(duration: float, attack: float, decay: float,
		release: float) -> PackedFloat64Array:
	# Reserve edge ramps first. Only sub-15 ms sounds must shorten these minima.
	var edge_scale := minf(1.0, duration / (MIN_ATTACK + MIN_RELEASE))
	var attack_floor := MIN_ATTACK * edge_scale
	var release_floor := MIN_RELEASE * edge_scale
	var attack_extra := maxf(0.0, attack - attack_floor)
	var release_extra := maxf(0.0, release - release_floor)
	var decay_length := maxf(0.0, decay)
	var extra_total := attack_extra + decay_length + release_extra
	var remaining := maxf(0.0, duration - attack_floor - release_floor)
	var extra_scale := minf(1.0, remaining / extra_total) if extra_total > 0.0 else 0.0
	return PackedFloat64Array([attack_floor + attack_extra * extra_scale,
		decay_length * extra_scale, release_floor + release_extra * extra_scale])

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

extends Node

const PcmSynth = preload("res://scripts/feedback/pcm_synth.gd")
const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")
const POOL_SIZE: int = 8

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _pool_idx: int = 0
var _last_play_ms: Dictionary = {}
var _muted: bool = false

func _ready() -> void:
	for index in range(POOL_SIZE):
		var voice := AudioStreamPlayer.new()
		voice.bus = &"Master"
		add_child(voice)
		_pool.append(voice)
	for effect in SfxCatalog.Effect.values():
		if SfxCatalog.PRESETS.has(effect):
			_streams[effect] = PcmSynth.generate(SfxCatalog.PRESETS[effect])
		elif SfxCatalog.MELODY_PRESETS.has(effect):
			var preset: Dictionary = SfxCatalog.MELODY_PRESETS[effect]
			var frequencies: Array[float] = []
			for frequency in preset.freqs: frequencies.append(float(frequency))
			_streams[effect] = PcmSynth.generate_melody(frequencies, preset.note_dur,
				preset.volume, preset.wave)

func play(effect: int) -> void:
	if _muted or _pool.is_empty() or not _streams.has(effect):
		return
	var now := Time.get_ticks_msec()
	var interval: int = int(SfxCatalog.MIN_INTERVAL_MS.get(effect, 0))
	if now - int(_last_play_ms.get(effect, -100000)) < interval:
		return
	_last_play_ms[effect] = now
	var voice := _pool[_pool_idx]
	_pool_idx = (_pool_idx + 1) % POOL_SIZE
	voice.stop()
	voice.stream = _streams[effect]
	voice.pitch_scale = randf_range(0.94, 1.06) if SfxCatalog.PITCH_RANDOMIZE.get(effect, false) else 1.0
	voice.play()

func set_muted(on: bool) -> void:
	_muted = on
	if on:
		for voice in _pool: voice.stop()

func is_muted() -> bool:
	return _muted

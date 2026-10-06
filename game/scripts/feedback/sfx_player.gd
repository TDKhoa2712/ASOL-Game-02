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
	var ui_tick_stream := PcmSynth.generate(SfxCatalog.UI_TICK)
	for index in range(POOL_SIZE):
		var voice := AudioStreamPlayer.new()
		voice.bus = &"Master"
		add_child(voice)
		_pool.append(voice)
	for effect in SfxCatalog.Effect.values():
		if SfxCatalog.SHARED_UI_EFFECTS.has(effect):
			_streams[effect] = ui_tick_stream
		elif SfxCatalog.PENCIL_PRESETS.has(effect):
			_streams[effect] = PcmSynth.generate_pencil_scratch(SfxCatalog.PENCIL_PRESETS[effect])
		elif SfxCatalog.PRESETS.has(effect):
			var preset: Dictionary = SfxCatalog.PRESETS[effect]
			_streams[effect] = load(str(preset.path)) if preset.get("type", "") == "file" \
				else PcmSynth.generate(preset)
		elif SfxCatalog.MELODY_PRESETS.has(effect):
			var preset: Dictionary = SfxCatalog.MELODY_PRESETS[effect]
			var frequencies: Array[float] = []
			for frequency in preset.freqs: frequencies.append(float(frequency))
			_streams[effect] = PcmSynth.generate_melody(frequencies, preset.note_dur,
				preset.volume, preset.wave)
	# Native lifecycle signals also catch buttons built by screen scripts.
	get_tree().node_added.connect(_on_ui_node_added)
	_bind_existing_buttons(get_parent())

func _bind_existing_buttons(node: Node) -> void:
	_on_ui_node_added(node)
	for child in node.get_children(): _bind_existing_buttons(child)

func _on_ui_node_added(node: Node) -> void:
	if node is ConfirmationDialog and get_parent().is_ancestor_of(node):
		var cue := _on_dialog_visibility_changed.bind(node)
		if not node.visibility_changed.is_connected(cue): node.visibility_changed.connect(cue)
	if node is BaseButton and get_parent().is_ancestor_of(node):
		if node.has_signal("toggled_value"):
			if not node.is_connected("toggled_value", _on_toggle_changed):
				node.connect("toggled_value", _on_toggle_changed)
			return
		if node.name in [&"UndoBtn", &"RestartBtn", &"HelpBtn"]:
			return
		var effect := SfxCatalog.Effect.BTN_PRESS
		if node.name in [&"BackBtn", &"HomeBtn"]:
			effect = SfxCatalog.Effect.TAP_BACK
		elif node.name in [&"OptionsButton", &"SettingsBtn"]:
			effect = SfxCatalog.Effect.SETTINGS_OPEN
		var cue := play.bind(effect)
		if not node.pressed.is_connected(cue): node.pressed.connect(cue)

func _on_toggle_changed(on: bool) -> void:
	play(SfxCatalog.Effect.TOGGLE_ON if on else SfxCatalog.Effect.TOGGLE_OFF)

func _on_dialog_visibility_changed(dialog: ConfirmationDialog) -> void:
	play(SfxCatalog.Effect.DIALOG_OPEN if dialog.visible else SfxCatalog.Effect.DIALOG_CLOSE)

func play(effect: int, force: bool = false) -> void:
	if _muted or _pool.is_empty() or not _streams.has(effect):
		return
	var now := Time.get_ticks_msec()
	var interval: int = int(SfxCatalog.MIN_INTERVAL_MS.get(effect, 0))
	if not force and now - int(_last_play_ms.get(effect, -100000)) < interval:
		return
	_last_play_ms[effect] = now
	var voice := _pool[_pool_idx]
	_pool_idx = (_pool_idx + 1) % POOL_SIZE
	voice.stop()
	voice.stream = _streams[effect]
	var preset: Dictionary = SfxCatalog.PENCIL_PRESETS.get(effect,
		SfxCatalog.PRESETS.get(effect, SfxCatalog.MELODY_PRESETS.get(effect, {})))
	var speed := clampf(float(preset.get("speed", 1.0)), 0.5, 2.0)
	voice.pitch_scale = speed * (randf_range(0.94, 1.06) if SfxCatalog.PITCH_RANDOMIZE.get(effect, false) else 1.0)
	voice.play()

func set_muted(on: bool) -> void:
	_muted = on
	if on:
		for voice in _pool: voice.stop()

func is_muted() -> bool:
	return _muted

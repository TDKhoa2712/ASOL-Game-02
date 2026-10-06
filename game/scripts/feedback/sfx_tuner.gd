extends Control

const PcmSynth = preload("res://scripts/feedback/pcm_synth.gd")
const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")
const PARAM_DEFS := [
	["freq", 20.0, 4000.0, 440.0, 1.0],
	["end_freq", 0.0, 4000.0, 440.0, 1.0],
	["duration", 0.02, 1.0, 0.15, 0.001],
	["volume", 0.0, 1.0, 0.3, 0.01],
	["speed", 0.5, 2.0, 1.0, 0.01],
	["noise_mix", 0.0, 1.0, 0.0, 0.01],
	["snap_mix", 0.0, 1.0, 0.65, 0.01],
	["noise_decay", 0.005, 0.5, 0.05, 0.005],
	["attack", 0.0, 0.2, 0.01, 0.001],
	["decay", 0.0, 0.3, 0.03, 0.001],
	["release", 0.0, 0.3, 0.04, 0.001],
	["sustain", 0.0, 1.0, 0.6, 0.01],
	["low_pass", 0.0, 8000.0, 0.0, 10.0],
	["high_pass", 0.0, 8000.0, 850.0, 10.0],
	["duty_cycle", 0.1, 0.9, 0.5, 0.01],
	["note_dur", 0.02, 1.0, 0.1, 0.001],
]

var _player: AudioStreamPlayer
var _preset_dropdown: OptionButton
var _sliders: Dictionary = {}
var _labels: Dictionary = {}
var _choices: Dictionary = {}
var _rows: Dictionary = {}
var _notes: LineEdit
var _status: Label
var _vbox: VBoxContainer
var _melody := false
var _pencil := false
var _swipe := false

func _ready() -> void:
	# This standalone desktop tool uses pixels, not the game's portrait scaling.
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	_player = AudioStreamPlayer.new()
	add_child(_player)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	_vbox = VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(_vbox)
	var title := Label.new()
	title.text = "SFX Tuner — CanDoKu"
	title.add_theme_font_size_override("font_size", 24)
	_vbox.add_child(title)
	var row := _row("Preset")
	_preset_dropdown = OptionButton.new()
	_preset_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for effect in SfxCatalog.Effect.values():
		_preset_dropdown.add_item(SfxCatalog.Effect.find_key(effect), effect)
	_preset_dropdown.item_selected.connect(_on_preset_selected)
	row.add_child(_preset_dropdown)
	for definition in PARAM_DEFS: _add_slider(definition)
	_add_choice("wave", ["SINE", "SQUARE", "TRIANGLE", "SAWTOOTH"])
	_add_choice("pitch_curve", ["LINEAR", "EXPONENTIAL"])
	row = _row("Notes (Hz)")
	_rows["freqs"] = row
	_notes = LineEdit.new()
	_notes.placeholder_text = "523.25, 659.25, 783.99, 1046.50"
	_notes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_notes)
	row = HBoxContainer.new()
	_vbox.add_child(row)
	for action in [["Play (Space)", _on_play], ["Copy Params", _on_copy_params]]:
		var button := Button.new()
		button.text = action[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(action[1])
		row.add_child(button)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vbox.add_child(_status)
	_on_preset_selected(0)

func _row(label: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = "speed (pitch)" if label == "speed" else label
	name_label.custom_minimum_size.x = 120
	row.add_child(name_label)
	_vbox.add_child(row)
	return row

func _add_slider(definition: Array) -> void:
	var key: String = definition[0]
	var row := _row(key)
	_rows[key] = row
	var slider := HSlider.new()
	slider.min_value = definition[1]
	slider.max_value = definition[2]
	slider.step = definition[4]
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.x = 150
	row.add_child(slider)
	var value_label := Label.new()
	value_label.custom_minimum_size.x = 80
	row.add_child(value_label)
	slider.value_changed.connect(func(value: float): value_label.text = "%.3f" % value)
	_sliders[key] = slider
	_labels[key] = value_label

func _add_choice(key: String, options: Array) -> void:
	var row := _row(key)
	_rows[key] = row
	var choice := OptionButton.new()
	choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for option in options: choice.add_item(option)
	row.add_child(choice)
	_choices[key] = choice

func _on_preset_selected(index: int) -> void:
	var effect := _preset_dropdown.get_item_id(index)
	_melody = SfxCatalog.MELODY_PRESETS.has(effect)
	_pencil = SfxCatalog.PENCIL_PRESETS.has(effect)
	var preset: Dictionary = SfxCatalog.PENCIL_PRESETS[effect] if _pencil else (
		SfxCatalog.MELODY_PRESETS[effect] if _melody else SfxCatalog.PRESETS[effect])
	_swipe = preset.get("type", "") == "settings_swipe"
	for definition in PARAM_DEFS:
		var key: String = definition[0]
		_sliders[key].value = float(preset.get(key, definition[3]))
		_labels[key].text = "%.3f" % _sliders[key].value
		if _swipe:
			_rows[key].visible = key in ["duration", "volume", "speed", "noise_mix",
				"snap_mix", "high_pass", "low_pass"]
		elif _pencil:
			_rows[key].visible = key in ["duration", "volume", "speed", "high_pass", "low_pass"]
		elif _melody:
			_rows[key].visible = key in ["note_dur", "volume", "speed"]
		else:
			_rows[key].visible = key != "note_dur" and key != "high_pass" and key != "snap_mix"
	_choices.wave.select(int(preset.get("wave", PcmSynth.Wave.TRIANGLE)))
	_choices.pitch_curve.select(int(preset.get("pitch_curve", PcmSynth.PitchCurve.LINEAR)))
	_rows.wave.visible = not _pencil and not _swipe
	_rows.pitch_curve.visible = not _melody and not _pencil and not _swipe
	_rows.freqs.visible = _melody
	if _melody:
		var notes := PackedStringArray()
		for frequency in preset.freqs: notes.append(str(frequency))
		_notes.text = ", ".join(notes)
	_status.text = "Adjust parameters, then Play. Speed also changes pitch."

func _current_params() -> Dictionary:
	var params := {}
	for definition in PARAM_DEFS:
		var key: String = definition[0]
		if not _rows[key].visible: continue
		if key == "low_pass" and not _pencil and not _swipe and _sliders[key].value <= 0.0: continue
		params[key] = float(_sliders[key].value)
	if _pencil:
		params["type"] = "pencil"
		return params
	if _swipe:
		params["type"] = "settings_swipe"
		return params
	params["wave"] = _choices.wave.selected
	if _melody:
		var frequencies: Array[float] = []
		for part in _notes.text.split(","):
			var text_value := part.strip_edges()
			if not text_value.is_valid_float(): return {}
			var frequency := float(text_value)
			if not is_finite(frequency) or frequency < 20.0 or frequency > 4000.0: return {}
			frequencies.append(frequency)
		params["freqs"] = frequencies
	else:
		params["pitch_curve"] = _choices.pitch_curve.selected
	return params

func _on_play() -> void:
	var params := _current_params()
	if params.is_empty():
		_status.text = "Enter comma-separated note frequencies between 20 and 4000 Hz."
		return
	_player.stop()
	if _melody:
		_player.stream = PcmSynth.generate_melody(params.freqs, params.note_dur, params.volume, params.wave)
	else:
		_player.stream = PcmSynth.generate(params)
	_player.pitch_scale = params.speed
	_player.play()
	_status.text = "Playing " + _preset_dropdown.get_item_text(_preset_dropdown.selected)

func _params_literal(params: Dictionary) -> String:
	var entries := PackedStringArray()
	for key in params:
		var value := var_to_str(params[key])
		if params[key] is Array:
			var items := PackedStringArray()
			for item in params[key]: items.append(var_to_str(item))
			value = "[" + ", ".join(items) + "]"
		if key == "wave": value = "PcmSynth.Wave." + PcmSynth.Wave.find_key(params[key])
		elif key == "pitch_curve": value = "PcmSynth.PitchCurve." + PcmSynth.PitchCurve.find_key(params[key])
		entries.append('    "%s": %s' % [key, value])
	return "{\n" + ",\n".join(entries) + ",\n}"

func _on_copy_params() -> void:
	var params := _current_params()
	if params.is_empty():
		_status.text = "Fix the note frequencies before copying."
		return
	var output := _params_literal(params)
	DisplayServer.clipboard_set(output)
	print(output)
	_status.text = "Copied to clipboard and printed in the console."

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_on_play()
		get_viewport().set_input_as_handled()

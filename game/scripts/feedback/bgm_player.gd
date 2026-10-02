# bgm_player.gd
extends Node

var _player: AudioStreamPlayer
var _muted: bool = false
var _current_track: String = ""

func _ready() -> void:
	if not _player:
		_player = AudioStreamPlayer.new()
		_player.bus = &"Master"
		add_child(_player)

func play_track(path: String) -> void:
	_current_track = path
	if _muted:
		return
	if not _player:
		_player = AudioStreamPlayer.new()
		_player.bus = &"Master"
		add_child(_player)
	if path != "" and (ResourceLoader.exists(path) or FileAccess.file_exists(path)):
		var stream := load(path) as AudioStream
		if stream:
			if "loop" in stream:
				stream.set("loop", true)
			_player.stream = stream
			_player.play()

func stop() -> void:
	if _player and _player.playing:
		_player.stop()

func set_muted(on: bool) -> void:
	_muted = on
	if on:
		stop()
	elif _current_track != "":
		play_track(_current_track)

func is_muted() -> bool:
	return _muted

func is_playing() -> bool:
	return _player != null and _player.playing

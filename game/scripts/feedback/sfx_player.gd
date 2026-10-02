# sfx_player.gd
extends Node

const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")

var _streams: Dictionary = {}       # Effect -> AudioStream
var _players: Dictionary = {}       # Effect -> AudioStreamPlayer
var _last_play_ms: Dictionary = {}  # Effect -> int (last play timestamp)
var _muted: bool = false

func _ready() -> void:
	for effect in SfxCatalog.Effect.values():
		var path: String = SfxCatalog.FILE_MAP.get(effect, "")
		if path != "" and (ResourceLoader.exists(path) or FileAccess.file_exists(path)):
			var stream := load(path) as AudioStream
			if stream:
				_streams[effect] = stream
				var player := AudioStreamPlayer.new()
				player.stream = stream
				player.bus = &"Master"
				add_child(player)
				_players[effect] = player

func play(effect: int) -> void:
	if _muted:
		return
	var now := Time.get_ticks_msec()
	if SfxCatalog.MIN_INTERVAL_MS.has(effect):
		var last: int = _last_play_ms.get(effect, -100000)
		if now - last < SfxCatalog.MIN_INTERVAL_MS[effect]:
			return  # throttled
	_last_play_ms[effect] = now
	var player: AudioStreamPlayer = _players.get(effect)
	if player:
		player.play()

func set_muted(on: bool) -> void:
	_muted = on
	if on:
		for p in _players.values():
			if p and p.playing:
				p.stop()

func is_muted() -> bool:
	return _muted

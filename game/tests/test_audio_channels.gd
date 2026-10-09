extends SceneTree

var _fails: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var shell = load("res://scenes/main.tscn").instantiate()
	shell.profile_dir = OS.get_user_data_dir().path_join("audio_channels_%d" % Time.get_ticks_usec())
	root.add_child(shell)
	await process_frame
	shell.config.set_option("music", false)
	_assert(shell.bgm.is_muted(), "music off mutes background music")
	_assert(not shell.sfx.is_muted(), "music off keeps sound effects")
	shell.config.set_option("music", true)
	shell.config.set_option("audio", false)
	_assert(shell.sfx.is_muted(), "sound off mutes effects")
	_assert(not shell.bgm.is_muted(), "sound off keeps background music")
	if _fails.is_empty():
		print("AUDIO_CHANNELS_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)

extends SceneTree

const WinScreen = preload("res://scripts/screens/win_screen.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_instantiates()
	_test_setup_normal()
	_test_setup_last_level()
	_test_signals()
	_test_format_time()
	if _fails.is_empty():
		print("WIN_SCREEN_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)

func _test_instantiates() -> void:
	var screen := WinScreen.new()
	_assert(screen is Control, "win_screen is Control")
	screen.free()

func _test_setup_normal() -> void:
	var screen := WinScreen.new()
	screen.setup(true, 161000, "L5", false, 2, 1, "L06", 5, "medium")
	_assert(screen.has_signal("next_pressed"), "has next_pressed")
	_assert(screen.has_signal("home_pressed"), "has home_pressed")
	_assert(screen._next_label == "L06", "next_label stored")
	_assert(screen._next_size == 5, "next_size stored")
	_assert(screen._next_difficulty == "medium", "next_difficulty stored")
	screen.free()

func _test_setup_last_level() -> void:
	var screen := WinScreen.new()
	screen.setup(true, 300000, "L30", true, 3, 0)
	_assert(screen._is_last_level, "is_last_level true")
	_assert(screen._next_label == "", "no next_label on last level")
	screen.free()

func _test_signals() -> void:
	var screen := WinScreen.new()
	_assert(screen.has_signal("next_pressed"), "has next_pressed")
	_assert(screen.has_signal("retry_pressed"), "has retry_pressed")
	_assert(screen.has_signal("home_pressed"), "has home_pressed")
	_assert(screen.has_signal("replay_pressed"), "has replay_pressed")
	screen.free()

func _test_format_time() -> void:
	var screen := WinScreen.new()
	_assert(screen._format_time(161000) == "02:41", "format 161000 -> 02:41")
	_assert(screen._format_time(0) == "00:00", "format 0 -> 00:00")
	_assert(screen._format_time(3600000) == "60:00", "format 3600000 -> 60:00")
	screen.free()

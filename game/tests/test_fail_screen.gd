extends SceneTree

const FailScreen = preload("res://scripts/screens/fail_screen.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_instantiates()
	_test_setup()
	_test_signals()
	_test_format_time()
	if _fails.is_empty():
		print("FAIL_SCREEN_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)

func _test_instantiates() -> void:
	var screen := FailScreen.new()
	_assert(screen is Control, "fail_screen is Control")
	screen.free()

func _test_setup() -> void:
	var screen := FailScreen.new()
	screen.setup(false, 192000, "L12", false)
	_assert(screen.has_signal("retry_pressed"), "has retry_pressed")
	_assert(screen.has_signal("home_pressed"), "has home_pressed")
	screen.free()

func _test_signals() -> void:
	var screen := FailScreen.new()
	_assert(screen.has_signal("next_pressed"), "has next_pressed")
	_assert(screen.has_signal("retry_pressed"), "has retry_pressed")
	_assert(screen.has_signal("home_pressed"), "has home_pressed")
	_assert(screen.has_signal("replay_pressed"), "has replay_pressed")
	screen.free()

func _test_format_time() -> void:
	var screen := FailScreen.new()
	_assert(screen._format_time(192000) == "03:12", "format 192000 -> 03:12")
	_assert(screen._format_time(0) == "00:00", "format 0 -> 00:00")
	screen.free()

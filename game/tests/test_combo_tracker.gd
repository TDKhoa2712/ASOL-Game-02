extends SceneTree

const ComboTracker = preload("res://scripts/feedback/combo_tracker.gd")

var _fails: Array[String] = []

func _init() -> void:
	var tracker := ComboTracker.new()
	_assert(tracker.streak == 0, "starts at zero")
	_assert(tracker.on_correct() == 1, "first correct is level 1")
	_assert(tracker.on_correct() == 2, "second correct is level 2")
	tracker.reset()
	_assert(tracker.streak == 0, "reset clears streak")
	_assert(tracker.on_correct() == 1, "after reset back to level 1")
	for i in range(14): tracker.on_correct()
	_assert(tracker.streak == 15, "streak keeps counting past 12")
	_assert(tracker.on_correct() == ComboTracker.MAX_LEVEL, "level clamps to 12")
	if _fails.is_empty():
		print("COMBO_TRACKER_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)

# game/tests/test_hint_overlay.gd
extends SceneTree

const HintOverlay = preload("res://scripts/screens/hint_overlay.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_show_and_dismiss()
	_test_dismiss_emits_signal()
	_test_show_updates_text()
	_test_double_show_replaces()
	_test_dismiss_when_not_showing()
	if _fails.is_empty():
		print("SCREENS_HINT_OVERLAY_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_show_and_dismiss() -> void:
	var overlay := HintOverlay.new()
	root.add_child(overlay)
	_assert(not overlay.is_showing(), "starts hidden")
	overlay.show_hint("Look at row 2", "Row 2")
	_assert(overlay.is_showing(), "showing after show_hint")
	overlay.dismiss()
	_assert(not overlay.is_showing(), "hidden after dismiss")
	overlay.queue_free()

func _test_dismiss_emits_signal() -> void:
	var overlay := HintOverlay.new()
	root.add_child(overlay)
	var signals: Array = []
	overlay.dismissed.connect(func(): signals.append(true))
	overlay.show_hint("Test", "Zone A")
	overlay.dismiss()
	_assert(signals.size() == 1, "dismissed signal emitted")
	overlay.queue_free()

func _test_show_updates_text() -> void:
	var overlay := HintOverlay.new()
	root.add_child(overlay)
	overlay.show_hint("First hint", "Row 1")
	overlay.show_hint("Second hint", "Zone B")
	_assert(overlay.is_showing(), "still showing after second show")
	overlay.dismiss()
	overlay.queue_free()

func _test_double_show_replaces() -> void:
	var overlay := HintOverlay.new()
	root.add_child(overlay)
	overlay.show_hint("A", "X")
	overlay.show_hint("B", "Y")
	_assert(overlay.is_showing(), "showing after replace")
	overlay.dismiss()
	overlay.queue_free()

func _test_dismiss_when_not_showing() -> void:
	var overlay := HintOverlay.new()
	root.add_child(overlay)
	overlay.dismiss()
	_assert(not overlay.is_showing(), "dismiss when not showing is safe")
	overlay.queue_free()

func _assert(condition: bool, label: String) -> void:
	if not condition:
		_fails.append("FAIL: " + label)

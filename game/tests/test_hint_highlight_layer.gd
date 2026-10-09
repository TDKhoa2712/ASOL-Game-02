extends SceneTree

const HintHighlightLayer = preload("res://scripts/screens/hint_highlight_layer.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_highlight_layer_lifecycle()
	_test_spotlight_focus_cells()
	_test_chain_detail_focus()
	_test_backdrop_dismiss_signal()

	if _fails.is_empty():
		print("HINT_HIGHLIGHT_LAYER_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond:
		_fails.append(msg)

func _mock_cell_rect(r: int, c: int) -> Rect2:
	return Rect2(float(c * 60), float(r * 60), 60.0, 60.0)

func _test_highlight_layer_lifecycle() -> void:
	var layer := HintHighlightLayer.new()
	_assert(not layer.is_showing(), "initially not showing")
	_assert(not layer.visible, "initially visible is false to prevent blocking input")
	_assert(layer.mouse_filter == Control.MOUSE_FILTER_IGNORE, "initially mouse_filter is IGNORE")

	var hint := {
		"size": 4,
		"highlight_cells": [[0, 0], [0, 1]],
		"target_cell": [0, 2],
		"eliminated_cells": [[0, 3]],
	}
	layer.show_hint(hint, _mock_cell_rect, 4)
	_assert(layer.is_showing(), "showing after show_hint")
	_assert(layer.visible, "visible is true after show_hint")

	layer.clear()
	_assert(not layer.is_showing(), "not showing after clear")
	_assert(not layer.visible, "visible is false after clear")
	layer.free()

func _test_spotlight_focus_cells() -> void:
	var layer := HintHighlightLayer.new()
	var hint := {
		"size": 4,
		"highlight_cells": [[0, 0], [0, 1]],
		"target_cell": [1, 1],
		"eliminated_cells": [[2, 2]],
	}
	layer.show_hint(hint, _mock_cell_rect, 4)

	# Verify focus set contains the 4 distinct cells
	_assert(layer.is_cell_focused(0, 0), "cell (0, 0) is focused")
	_assert(layer.is_cell_focused(0, 1), "cell (0, 1) is focused")
	_assert(layer.is_cell_focused(1, 1), "target cell (1, 1) is focused")
	_assert(layer.is_cell_focused(2, 2), "eliminated cell (2, 2) is focused")

	# Verify un-highlighted cell is not focused (dimmed)
	_assert(not layer.is_cell_focused(3, 3), "cell (3, 3) is dimmed / not focused")
	_assert(not layer.is_cell_focused(0, 2), "cell (0, 2) is dimmed / not focused")

	layer.free()

func _test_chain_detail_focus() -> void:
	var layer := HintHighlightLayer.new()
	var hint := {
		"size": 4,
		"highlight_cells": [[0, 0]],
		"target_cell": [0, 0],
		"eliminated_cells": [],
	}
	layer.show_hint(hint, _mock_cell_rect, 4)

	var chain := {
		"hypothesis_cell": [1, 2],
		"steps": [[2, 3], [3, 1]],
		"contra_type": "zone",
		"contra_index": 1,
	}
	layer.show_chain_detail(chain, _mock_cell_rect)

	_assert(layer.is_cell_focused(1, 2), "hypothesis cell is focused")
	_assert(layer.is_cell_focused(2, 3), "step 1 is focused")
	_assert(layer.is_cell_focused(3, 1), "step 2 is focused")
	_assert(not layer.is_cell_focused(0, 3), "other cell remains dimmed")
	_assert(layer.visible, "visible is true during chain detail")

	layer.free()

func _test_backdrop_dismiss_signal() -> void:
	var layer := HintHighlightLayer.new()
	var dismiss_count := [0]
	layer.dismiss_requested.connect(func(): dismiss_count[0] += 1)

	var hint := {
		"size": 4,
		"highlight_cells": [[0, 0]],
	}
	layer.show_hint(hint, _mock_cell_rect, 4)

	var ev_mouse := InputEventMouseButton.new()
	ev_mouse.button_index = MOUSE_BUTTON_LEFT
	ev_mouse.pressed = true
	layer._on_backdrop_input(ev_mouse)

	var ev_touch := InputEventScreenTouch.new()
	ev_touch.pressed = true
	layer._on_backdrop_input(ev_touch)

	_assert(dismiss_count[0] == 2, "both mouse and touch emit dismiss_requested")
	layer.free()

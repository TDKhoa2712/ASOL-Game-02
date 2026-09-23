extends RefCounted


signal changed


const InteractionSessionScript = preload("res://scripts/interaction_session.gd")


var level: Dictionary
var contract: Dictionary
var session
var committed_actions: Array = []

var active_pointer := -1
var active_cell: Array = []
var active_position := Vector2.ZERO
var active_original_state := ""
var active_is_second := false
var dragging := false
var stroke_mode := ""
var stroke_cells: Array = []
var visited_cells: Dictionary = {}
var preview_original: Dictionary = {}

var pending_tap := false
var pending_cell: Array = []
var pending_released_ms := 0
var pending_original_state := ""


func _init(level_data: Dictionary, contract_data: Dictionary = {}) -> void:
	level = level_data.duplicate(true)
	contract = contract_data.duplicate(true)
	session = InteractionSessionScript.new(level)


func begin_pointer(
	pointer_id: int, cell: Array, logical_position: Vector2, time_ms: int
) -> bool:
	if active_pointer != -1:
		return false
	if pending_tap:
		var within_window := (
			time_ms - pending_released_ms <= _double_tap_window_ms()
		)
		if within_window and cell == pending_cell:
			active_pointer = pointer_id
			active_cell = cell.duplicate()
			active_position = logical_position
			active_is_second = true
			return true
		flush_pending()
	if session.is_given(cell) or session.cell_state(cell) not in ["empty", "x"]:
		return false
	active_pointer = pointer_id
	active_cell = cell.duplicate()
	active_position = logical_position
	active_original_state = session.cell_state(cell)
	active_is_second = false
	dragging = false
	stroke_cells = []
	visited_cells = {}
	preview_original = {}
	_preview_cell(cell, active_original_state)
	changed.emit()
	return true


func move_pointer(
	pointer_id: int, cell: Array, logical_position: Vector2
) -> void:
	if pointer_id != active_pointer:
		return
	if not dragging and logical_position.distance_to(active_position) <= _touch_slop():
		return
	if not dragging:
		if active_is_second:
			flush_pending()
			active_original_state = session.cell_state(active_cell)
			if active_original_state not in ["empty", "x"]:
				_clear_active()
				return
		else:
			_rollback_preview()
		preview_original = {}
		dragging = true
		stroke_mode = "mark" if active_original_state == "empty" else "clear"
		stroke_cells = []
		visited_cells = {}
		_preview_stroke_cell(active_cell)
	for target in line_cells(active_cell, cell, _cell_size()):
		_preview_stroke_cell(target)
	changed.emit()


func end_pointer(pointer_id: int, time_ms: int) -> void:
	if pointer_id != active_pointer:
		return
	if dragging:
		var committed_cells := stroke_cells.duplicate(true)
		_rollback_preview()
		session.apply_action(
			{"type": "MarkStroke", "mode": stroke_mode, "cells": committed_cells}
		)
		committed_actions.append("MarkStroke")
		_clear_active()
		changed.emit()
		return
	if active_is_second:
		var try_cell := pending_cell.duplicate()
		_rollback_preview()
		pending_tap = false
		session.apply_action({"type": "TryCat", "cell": try_cell})
		committed_actions.append("TryCat")
		_clear_active()
		changed.emit()
		return
	pending_tap = true
	pending_cell = active_cell.duplicate()
	pending_released_ms = time_ms
	pending_original_state = active_original_state
	_clear_active(false)
	changed.emit()


func tick(time_ms: int) -> void:
	if pending_tap and time_ms - pending_released_ms > _double_tap_window_ms():
		flush_pending()


func flush_pending() -> void:
	if not pending_tap:
		return
	var cell := pending_cell.duplicate()
	var original := pending_original_state
	_rollback_preview()
	pending_tap = false
	var action_type := "MarkX" if original == "empty" else "ClearX"
	session.apply_action({"type": action_type, "cell": cell})
	committed_actions.append(action_type)
	changed.emit()


func cancel_active() -> void:
	if active_pointer == -1:
		return
	_rollback_preview()
	_clear_active()
	changed.emit()


func cancel_all() -> void:
	_rollback_preview()
	pending_tap = false
	_clear_active()
	changed.emit()


func run_contract_case(case: Dictionary) -> Dictionary:
	var test_session = InteractionSessionScript.new(level)
	var initial_hearts := int(case.get("initialHearts", 3))
	test_session.load_initial(
		{
			"cells": case.get("initial", {}),
			"hearts": initial_hearts,
			"mistakeCount": 3 - initial_hearts,
		}
	)
	var actions: Array = []
	var kind := str(case["kind"])
	var cell: Array = case.get("cell", [])

	match kind:
		"tap", "jitter", "secondary":
			if kind == "secondary":
				cell = case["primary"]
			if (
				kind == "jitter"
				and float(case["distanceLogicalPx"]) > _touch_slop()
			):
				_contract_stroke(test_session, [cell], "mark", actions)
			else:
				_contract_single(test_session, cell, actions)
		"double":
			if (
				test_session.cell_state(cell) in ["empty", "x"]
				and int(case["intervalMs"]) <= _double_tap_window_ms()
			):
				test_session.apply_action({"type": "TryCat", "cell": cell})
				actions.append("TryCat")
			else:
				_contract_single(test_session, cell, actions)
				_contract_single(test_session, cell, actions)
		"different":
			_contract_single(test_session, case["first"], actions)
			_contract_single(test_session, case["second"], actions)
		"second_drag":
			_contract_single(test_session, cell, actions)
			var mode := "mark" if test_session.cell_state(cell) == "empty" else "clear"
			var path := line_cells(cell, case["to"], _cell_size())
			_contract_stroke(test_session, path, mode, actions)
		"locked", "locked_drag", "cancel_active":
			pass
		"flush_pending":
			_contract_single(test_session, cell, actions)
		"drag":
			var mode := "mark" if test_session.cell_state(case["from"]) == "empty" else "clear"
			var path := line_cells(case["from"], case["to"], _cell_size())
			if case.has("returnTo"):
				path.append_array(
					line_cells(case["to"], case["returnTo"], _cell_size())
				)
			_contract_stroke(test_session, path, mode, actions)
		_:
			assert(false, "Unknown gesture contract kind: %s" % kind)

	return {
		"cells": test_session.cells.duplicate(true),
		"hearts": test_session.hearts,
		"actions": actions,
	}


func line_cells(start: Array, finish: Array, cell_size: float) -> Array:
	var x0 := (float(start[1]) + 0.5) * cell_size
	var y0 := (float(start[0]) + 0.5) * cell_size
	var x1 := (float(finish[1]) + 0.5) * cell_size
	var y1 := (float(finish[0]) + 0.5) * cell_size
	var steps := maxi(
		1, int(maxf(absf(x1 - x0), absf(y1 - y0)))
	)
	var result: Array = []
	for index in range(steps + 1):
		var ratio := float(index) / float(steps)
		var cell := [
			int(floor((y0 + (y1 - y0) * ratio) / cell_size)),
			int(floor((x0 + (x1 - x0) * ratio) / cell_size)),
		]
		if result.is_empty() or result[-1] != cell:
			result.append(cell)
	return result


func _contract_single(test_session, cell: Array, actions: Array) -> void:
	var before: String = test_session.cell_state(cell)
	if before == "empty":
		test_session.apply_action({"type": "MarkX", "cell": cell})
		actions.append("MarkX")
	elif before == "x":
		test_session.apply_action({"type": "ClearX", "cell": cell})
		actions.append("ClearX")


func _contract_stroke(
	test_session, raw_cells: Array, mode: String, actions: Array
) -> void:
	var unique_cells: Array = []
	var seen: Dictionary = {}
	for raw_cell_value in raw_cells:
		var raw_cell: Array = raw_cell_value
		var key: String = test_session.cell_key(raw_cell)
		if not seen.has(key):
			seen[key] = true
			unique_cells.append(raw_cell)
	test_session.apply_action(
		{"type": "MarkStroke", "mode": mode, "cells": unique_cells}
	)
	actions.append("MarkStroke")


func _preview_cell(cell: Array, original: String) -> void:
	var key: String = session.cell_key(cell)
	if not preview_original.has(key):
		preview_original[key] = original
	session.write_cell(cell, "x" if original == "empty" else "empty")


func _preview_stroke_cell(cell: Array) -> void:
	var row := int(cell[0])
	var column := int(cell[1])
	var size := int(level["size"])
	if row < 0 or column < 0 or row >= size or column >= size:
		return
	var key: String = session.cell_key(cell)
	if visited_cells.has(key):
		return
	visited_cells[key] = true
	var required := "empty" if stroke_mode == "mark" else "x"
	if session.is_given(cell) or session.cell_state(cell) != required:
		return
	preview_original[key] = required
	session.write_cell(cell, "x" if stroke_mode == "mark" else "empty")
	stroke_cells.append(cell.duplicate())


func _rollback_preview() -> void:
	for key_value in preview_original:
		var key := str(key_value)
		var parts := key.split(",")
		session.write_cell(
			[int(parts[0]), int(parts[1])], str(preview_original[key])
		)
	preview_original = {}


func _clear_active(clear_preview: bool = true) -> void:
	active_pointer = -1
	active_cell = []
	active_position = Vector2.ZERO
	active_original_state = ""
	active_is_second = false
	dragging = false
	stroke_mode = ""
	stroke_cells = []
	visited_cells = {}
	if clear_preview:
		preview_original = {}


func _double_tap_window_ms() -> int:
	return int(contract.get("doubleTapWindowMs", 280))


func _touch_slop() -> float:
	return float(contract.get("touchSlopLogicalPx", 12))


func _cell_size() -> float:
	return float(contract.get("cellLogicalPx", 100))

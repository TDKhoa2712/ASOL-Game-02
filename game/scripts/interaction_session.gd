extends RefCounted


signal changed


var level: Dictionary
var cells: Dictionary = {}
var hearts := 3
var mistake_count := 0
var hint_count := 0
var attempt_state := "Playing"
var undo_diff: Variant = null
var events: Array = []


func _init(level_data: Dictionary) -> void:
	level = level_data.duplicate(true)
	reset_attempt()


func reset_attempt(event_name: String = "") -> void:
	cells = {}
	hearts = 3
	mistake_count = 0
	hint_count = 0
	attempt_state = "Playing"
	undo_diff = null
	events = []
	if not event_name.is_empty():
		events.append(event_name)
	changed.emit()


func load_initial(initial: Dictionary) -> void:
	cells = initial.get("cells", {}).duplicate(true)
	hearts = int(initial.get("hearts", 3))
	mistake_count = int(initial.get("mistakeCount", 0))
	hint_count = int(initial.get("hintCount", 0))
	attempt_state = (
		"Failed" if hearts <= 0
		else "Won" if _correct_placed_count() >= int(level["size"])
		else "Playing"
	)
	undo_diff = null
	events = []
	changed.emit()


func public_state() -> Dictionary:
	return {
		"cells": cells.duplicate(true),
		"hearts": hearts,
		"mistakeCount": mistake_count,
		"hintCount": hint_count,
		"undoAvailable": undo_diff != null,
		"events": events.duplicate(),
	}


func cell_state(cell: Array) -> String:
	return str(cells.get(cell_key(cell), "empty"))


func cell_key(cell: Array) -> String:
	return "%d,%d" % [int(cell[0]), int(cell[1])]


func is_given(cell: Array) -> bool:
	for given_value in level.get("givens", []):
		var given: Dictionary = given_value
		if int(given["r"]) == int(cell[0]) and int(given["c"]) == int(cell[1]):
			return true
	return false


func write_cell(cell: Array, value: String) -> void:
	var key := cell_key(cell)
	if value == "empty":
		cells.erase(key)
	else:
		cells[key] = value


func apply_action(action: Dictionary) -> void:
	var action_type := str(action["type"])
	if (
		action_type in ["MarkX", "ClearX", "MarkStroke", "TryCat"]
		and attempt_state != "Playing"
	):
		events.append("NoOp")
		changed.emit()
		return
	match action_type:
		"MarkX", "ClearX":
			_apply_single_x(action_type, action["cell"])
		"MarkStroke":
			_apply_stroke(action)
		"UndoX":
			_apply_undo()
		"TryCat":
			_apply_try_cat(action["cell"])
		"Hint":
			_apply_hint(str(action["result"]))
		"BackToHome":
			undo_diff = null
			events.append("ReturnedHome")
		"RestartLevel":
			reset_attempt("Restarted")
			return
		"Retry":
			reset_attempt("Retried")
			return
		"LevelWon":
			undo_diff = null
			attempt_state = "Won"
			events.append("LevelWon")
		"LevelFailed":
			undo_diff = null
			attempt_state = "Failed"
			events.append("LevelFailed")
		"CloseApp":
			undo_diff = null
			events.append("AppClosed")
		_:
			push_error("Unknown session action: %s" % action_type)
			assert(false, "Unknown session action")
	changed.emit()


func _apply_single_x(action_type: String, raw_cell: Array) -> void:
	var cell := [int(raw_cell[0]), int(raw_cell[1])]
	if is_given(cell):
		events.append("NoOp")
		return
	var before := cell_state(cell)
	var required := "empty" if action_type == "MarkX" else "x"
	if before != required:
		events.append("NoOp")
		return
	var after := "x" if action_type == "MarkX" else "empty"
	write_cell(cell, after)
	undo_diff = {cell_key(cell): before}
	events.append(action_type)


func _apply_stroke(action: Dictionary) -> void:
	var mode := str(action["mode"])
	var required := "empty" if mode == "mark" else "x"
	var after := "x" if mode == "mark" else "empty"
	var diff: Dictionary = {}
	for raw_cell_value in action["cells"]:
		var raw_cell: Array = raw_cell_value
		var cell := [int(raw_cell[0]), int(raw_cell[1])]
		if is_given(cell):
			continue
		var key := cell_key(cell)
		var before := cell_state(cell)
		if before == required and not diff.has(key):
			diff[key] = before
			write_cell(cell, after)
	undo_diff = diff if not diff.is_empty() else null
	events.append("MarkStroke" if undo_diff != null else "NoOp")


func _apply_undo() -> void:
	if undo_diff == null:
		events.append("UndoUnavailable")
		return
	for key_value in undo_diff:
		var key := str(key_value)
		var parts := key.split(",")
		write_cell([int(parts[0]), int(parts[1])], str(undo_diff[key]))
	undo_diff = null
	events.append("UndoApplied")


func _apply_try_cat(raw_cell: Array) -> void:
	undo_diff = null
	var cell := [int(raw_cell[0]), int(raw_cell[1])]
	if is_given(cell) or cell_state(cell) not in ["empty", "x"]:
		events.append("NoOp")
		return
	if int(level["solution"][cell[0]]) == cell[1]:
		write_cell(cell, "cat")
		events.append("CatPlaced")
		if _correct_placed_count() >= int(level["size"]) and hearts > 0:
			attempt_state = "Won"
			events.append("LevelWon")
	else:
		write_cell(cell, "x_error")
		hearts -= 1
		mistake_count += 1
		events.append("Mistake")
		if hearts <= 0:
			attempt_state = "Failed"
			events.append("LevelFailed")


func _correct_placed_count() -> int:
	var count: int = level.get("givens", []).size()
	for value in cells.values():
		if value == "cat":
			count += 1
	return count


func _apply_hint(result: String) -> void:
	assert(result in ["none", "evidence"], "Unknown Hint result")
	if hint_count != 0:
		events.append("HintUnavailable")
	elif result == "none":
		events.append("NoHint")
	else:
		hint_count = 1
		events.append("HintShown")

extends SceneTree


const InteractionSessionScript = preload("res://scripts/interaction_session.gd")
const GestureEngineScript = preload("res://scripts/gesture_engine.gd")

const LEVEL_PATH := "res://data/t01.json"
const E01_PATH := "res://tests/fixtures/e01.json"
const CONTRACT_PATH := "res://tests/fixtures/interactions.v2.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var level: Dictionary = _read_json(LEVEL_PATH)
	var e01: Dictionary = _read_json(E01_PATH)
	var contract: Dictionary = _read_json(CONTRACT_PATH)
	var failures: Array[String] = []

	for case_value in contract["cases"]:
		var case: Dictionary = case_value
		var engine = GestureEngineScript.new(level, contract)
		var actual: Dictionary = JSON.parse_string(
			JSON.stringify(_run_live_case(engine, case))
		)
		var expected: Dictionary = JSON.parse_string(JSON.stringify({
			"cells": case["expected"],
			"hearts": case["hearts"],
			"actions": case["actions"],
		}))
		if case.has("preview"):
			expected["preview"] = case["preview"]
		if (
			case["kind"] == "drag"
			or (
				case["kind"] == "jitter"
				and float(case["distanceLogicalPx"]) > float(contract["touchSlopLogicalPx"])
			)
		):
			expected["undoCells"] = case.get("initial", {})
		if actual != expected:
			failures.append(
				"%s\nEXPECTED: %s\nACTUAL:   %s"
				% [case["id"], expected, actual]
			)

	var boundary_cases := [
		{
			"id": "exact_12_px_remains_tap",
			"kind": "jitter",
			"initial": {},
			"cell": [0, 0],
			"distanceLogicalPx": 12,
			"expected": {"0,0": "x"},
			"hearts": 3,
			"actions": ["MarkX"],
		},
		{
			"id": "exact_280_ms_is_double_tap",
			"kind": "double",
			"initial": {},
			"cell": [0, 1],
			"intervalMs": 280,
			"expected": {"0,1": "cat"},
			"hearts": 3,
			"actions": ["TryCat"],
		},
	]
	for case in boundary_cases:
		var engine = GestureEngineScript.new(level, contract)
		var actual: Dictionary = JSON.parse_string(JSON.stringify(_run_live_case(engine, case)))
		var expected: Dictionary = JSON.parse_string(JSON.stringify({
			"cells": case["expected"],
			"hearts": case["hearts"],
			"actions": case["actions"],
		}))
		if actual != expected:
			failures.append(
				"%s\nEXPECTED: %s\nACTUAL:   %s"
				% [case["id"], expected, actual]
			)

	var segmented_engine = GestureEngineScript.new(level, contract)
	segmented_engine.begin_pointer(0, [0, 0], _center([0, 0]), 0)
	segmented_engine.move_pointer(0, [0, 3], _center([0, 3]))
	segmented_engine.move_pointer(0, [3, 3], _center([3, 3]))
	segmented_engine.end_pointer(0, 30)
	var segmented_expected := {
		"0,0": "x", "0,1": "x", "0,2": "x", "0,3": "x",
		"1,3": "x", "2,3": "x", "3,3": "x",
	}
	if segmented_engine.session.cells != segmented_expected:
		failures.append(
			"segmented_elbow_stroke\nEXPECTED: %s\nACTUAL:   %s"
			% [segmented_expected, segmented_engine.session.cells]
		)

	var ownership_engine = GestureEngineScript.new(level, contract)
	ownership_engine.session.load_initial({"cells": {"0,0": "x_error"}, "hearts": 2})
	var primary_claimed: bool = ownership_engine.begin_pointer(0, [0, 0], _center([0, 0]), 0)
	var secondary_claimed: bool = ownership_engine.begin_pointer(1, [0, 1], _center([0, 1]), 1)
	ownership_engine.end_pointer(1, 5)
	ownership_engine.end_pointer(0, 10)
	ownership_engine.tick(300)
	if (
		not primary_claimed
		or secondary_claimed
		or ownership_engine.session.cells != {"0,0": "x_error"}
		or not ownership_engine.committed_actions.is_empty()
	):
		failures.append(
			"locked_primary_owns_contact\nprimary=%s secondary=%s cells=%s actions=%s"
			% [primary_claimed, secondary_claimed, ownership_engine.session.cells, ownership_engine.committed_actions]
		)

	var failed_engine = GestureEngineScript.new(level, contract)
	for wrong_cell in [[0, 0], [0, 2], [0, 3]]:
		failed_engine.session.apply_action({"type": "TryCat", "cell": wrong_cell})
	var failed_accepts_input: bool = failed_engine.begin_pointer(0, [1, 0], _center([1, 0]), 100)
	if (
		failed_engine.session.hearts != 0
		or failed_accepts_input
		or failed_engine.session.events[-1] != "LevelFailed"
	):
		failures.append(
			"failed_attempt_locks_board\nhearts=%s accepts=%s events=%s"
			% [failed_engine.session.hearts, failed_accepts_input, failed_engine.session.events]
		)

	var won_engine = GestureEngineScript.new(level, contract)
	for row in range(int(level["size"])):
		won_engine.session.apply_action({"type": "TryCat", "cell": [row, int(level["solution"][row])]})
	var won_accepts_input: bool = won_engine.begin_pointer(0, [0, 0], _center([0, 0]), 100)
	if won_accepts_input or won_engine.session.events[-1] != "LevelWon":
		failures.append(
			"won_attempt_locks_board\naccepts=%s events=%s"
			% [won_accepts_input, won_engine.session.events]
		)

	for case_value in contract["sessionCases"]:
		var case: Dictionary = case_value
		var case_level: Dictionary = e01 if case.get("levelId", "T01") == "E01" else level
		var session = InteractionSessionScript.new(case_level)
		session.load_initial(case.get("initial", {}))
		for action_value in case["actions"]:
			session.apply_action(action_value)
		var actual: Dictionary = JSON.parse_string(
			JSON.stringify(session.public_state())
		)
		if actual != case["expected"]:
			failures.append(
				"%s\nEXPECTED: %s\nACTUAL:   %s"
				% [case["id"], case["expected"], actual]
			)

	if failures.is_empty():
		print(
			"M0_A02_INTERACTION_CONTRACT_PASS gestures=%d boundaries=%d segmented=1 ownership=1 terminals=2 sessions=%d"
			% [contract["cases"].size(), boundary_cases.size(), contract["sessionCases"].size()]
		)
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _run_live_case(engine, case: Dictionary) -> Dictionary:
	var initial_hearts := int(case.get("initialHearts", 3))
	engine.session.load_initial({
		"cells": case.get("initial", {}),
		"hearts": initial_hearts,
		"mistakeCount": 3 - initial_hearts,
	})
	var kind := str(case["kind"])
	var cell: Array = case.get("cell", case.get("from", case.get("primary", [])))
	var preview := ""
	var first_up_ms := 10

	match kind:
		"tap", "jitter":
			engine.begin_pointer(0, cell, _center(cell), 0)
			preview = engine.session.cell_state(cell)
			if kind == "jitter":
				engine.move_pointer(
					0,
					cell,
					_center(cell) + Vector2(float(case["distanceLogicalPx"]), 0.0)
				)
			engine.end_pointer(0, first_up_ms)
			engine.tick(first_up_ms + int(engine.contract["doubleTapWindowMs"]) + 1)
		"double":
			engine.begin_pointer(0, cell, _center(cell), 0)
			preview = engine.session.cell_state(cell)
			engine.end_pointer(0, first_up_ms)
			var second_down_ms := first_up_ms + int(case["intervalMs"])
			engine.begin_pointer(0, cell, _center(cell), second_down_ms)
			engine.end_pointer(0, second_down_ms + 10)
			engine.tick(second_down_ms + 10 + int(engine.contract["doubleTapWindowMs"]) + 1)
		"different":
			var first: Array = case["first"]
			var second: Array = case["second"]
			engine.begin_pointer(0, first, _center(first), 0)
			engine.end_pointer(0, first_up_ms)
			var second_down_ms := first_up_ms + int(case["intervalMs"])
			engine.begin_pointer(0, second, _center(second), second_down_ms)
			engine.end_pointer(0, second_down_ms + 10)
			engine.tick(second_down_ms + 10 + int(engine.contract["doubleTapWindowMs"]) + 1)
		"second_drag":
			engine.begin_pointer(0, cell, _center(cell), 0)
			preview = engine.session.cell_state(cell)
			engine.end_pointer(0, first_up_ms)
			var second_down_ms := first_up_ms + int(case["intervalMs"])
			engine.begin_pointer(0, cell, _center(cell), second_down_ms)
			engine.move_pointer(0, case["to"], _center(case["to"]))
			engine.end_pointer(0, second_down_ms + 20)
		"locked", "locked_drag":
			engine.begin_pointer(0, cell, _center(cell), 0)
			if kind == "locked_drag":
				engine.move_pointer(0, case["to"], _center(case["to"]))
			engine.end_pointer(0, first_up_ms)
		"drag":
			engine.begin_pointer(0, cell, _center(cell), 0)
			engine.move_pointer(0, case["to"], _center(case["to"]))
			if case.has("returnTo"):
				engine.move_pointer(0, case["returnTo"], _center(case["returnTo"]))
			engine.end_pointer(0, 30)
		"secondary":
			var primary: Array = case["primary"]
			engine.begin_pointer(0, primary, _center(primary), 0)
			engine.begin_pointer(1, case["secondaryFrom"], _center(case["secondaryFrom"]), 1)
			engine.move_pointer(1, case["secondaryTo"], _center(case["secondaryTo"]))
			engine.end_pointer(1, 5)
			engine.end_pointer(0, first_up_ms)
			engine.tick(first_up_ms + int(engine.contract["doubleTapWindowMs"]) + 1)
		"flush_pending":
			engine.begin_pointer(0, cell, _center(cell), 0)
			preview = engine.session.cell_state(cell)
			engine.end_pointer(0, first_up_ms)
			engine.flush_pending()
		"cancel_active":
			engine.begin_pointer(0, cell, _center(cell), 0)
			preview = engine.session.cell_state(cell)
			engine.cancel_active()
		_:
			assert(false, "Unknown live gesture kind: %s" % kind)

	var result := {
		"cells": engine.session.cells.duplicate(true),
		"hearts": engine.session.hearts,
		"actions": engine.committed_actions.duplicate(),
	}
	if case.has("preview"):
		result["preview"] = preview
	if (
		kind == "drag"
		or (
			kind == "jitter"
			and float(case["distanceLogicalPx"]) > float(engine.contract["touchSlopLogicalPx"])
		)
	):
		engine.session.apply_action({"type": "UndoX"})
		result["undoCells"] = engine.session.cells.duplicate(true)
	return result


func _center(cell: Array) -> Vector2:
	return Vector2(float(cell[1]) * 100.0 + 50.0, float(cell[0]) * 100.0 + 50.0)


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open JSON fixture: %s" % path)
		quit(1)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Invalid JSON object: %s" % path)
		quit(1)
		return {}
	return parsed

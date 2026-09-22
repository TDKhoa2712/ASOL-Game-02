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
			JSON.stringify(engine.run_contract_case(case))
		)
		var expected := {
			"cells": case["expected"],
			"hearts": case["hearts"],
			"actions": case["actions"],
		}
		if actual != expected:
			failures.append(
				"%s\nEXPECTED: %s\nACTUAL:   %s"
				% [case["id"], expected, actual]
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
			"M0_A02_INTERACTION_CONTRACT_PASS gestures=%d sessions=%d"
			% [contract["cases"].size(), contract["sessionCases"].size()]
		)
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


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

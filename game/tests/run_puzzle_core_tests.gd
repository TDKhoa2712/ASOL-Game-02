extends SceneTree

const Core = preload("res://scripts/puzzle_core.gd")
const Session = preload("res://scripts/interaction_session.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var level := _json("res://data/t01.json")
	var e01 := _json("res://tests/fixtures/e01.json")
	_check(Core.validate_level(level), "T01 rules and unique solution")
	_check(Core.validate_level(e01), "E01 rules and unique solution")
	var duplicate := level.duplicate(true)
	duplicate["solution"] = [0, 1, 2, 3]
	_check(not Core.validate_level(duplicate), "invalid solution rejected")
	var invalid_region := level.duplicate(true)
	var first_row: String = invalid_region["regions"][0]
	invalid_region["regions"][0] = "Z" + first_row.substr(1)
	_check(not Core.validate_level(invalid_region), "invalid region partition rejected")

	var session = Session.new(level)
	_check(session.scorecard() == 0, "initial score")
	session.apply_action({"type": "MarkX", "cell": [0, 1]})
	_check(session.cells.get("0,1") == "x", "MarkX commits")
	session.apply_action({"type": "TryCandy", "cell": [0, 1]})
	_check(session.cells.get("0,1") == "candy", "TryCandy replaces X")
	_check(session.scorecard() == 100, "correct candy adds 100")
	_check(not session.public_state()["undoAvailable"], "TryCandy clears Undo")
	session.apply_action({"type": "UndoX"})
	_check(session.cells.get("0,1") == "candy", "Undo cannot cross TryCandy")
	session.apply_action({"type": "TryCandy", "cell": [0, 0]})
	_check(session.cells.get("0,0") == "x_error", "wrong candy locks red X")
	_check(session.hearts == 2 and session.mistake_count == 1, "wrong candy costs one heart")
	_check(session.scorecard() == 75, "score recomputed after mistake")
	session.apply_action({"type": "TryCandy", "cell": [0, 0]})
	_check(session.hearts == 2 and session.mistake_count == 1, "red X cannot be retried")
	_check(session.domain_events.has("ScoreChanged"), "core emits score event")
	_check(session.get("detailed_events") is Array and session.detailed_events.has({"type": "Mistake", "reason": "row"}), "session exposes proven mistake reason")
	var neutral_result: Dictionary = Core.try_candy(level, {}, 3, 0, [0, 0])
	_check(neutral_result.get("reason") == "neutral", "unproven mistake stays neutral")
	var exhausted_result: Dictionary = Core.try_candy(level, {}, 0, 3, [0, 1])
	_check(exhausted_result["state"] == "Failed" and exhausted_result["cells"].is_empty(), "zero-heart core cannot win")

	var stroke = Session.new(level)
	stroke.apply_action({"type": "MarkStroke", "mode": "mark", "cells": [[0, 0], [0, 2], [0, 2], [0, 3]]})
	_check(stroke.cells.size() == 3, "stroke applies unique eligible cells")
	stroke.apply_action({"type": "UndoX"})
	_check(stroke.cells.is_empty(), "Undo restores whole stroke")
	stroke.apply_action({"type": "UndoX"})
	_check(stroke.cells.is_empty(), "Undo has no Redo")
	stroke.apply_action({"type": "MarkX", "cell": [0, 0]})
	stroke.apply_action({"type": "RestartLevel"})
	_check(stroke.cells.is_empty() and stroke.hearts == 3 and stroke.scorecard() == 0, "Restart resets attempt")
	_check(not stroke.public_state()["undoAvailable"], "Restart clears Undo")

	var failed = Session.new(level)
	for cell in [[0, 0], [0, 2], [0, 3]]:
		failed.apply_action({"type": "TryCandy", "cell": cell})
	_check(failed.attempt_state == "Failed" and failed.hearts == 0, "third mistake fails")
	_check(failed.scorecard() == 0, "score floors at zero")
	failed.apply_action({"type": "TryCandy", "cell": [0, 1]})
	_check(failed.cells.get("0,1", "empty") == "empty", "failed board is locked")
	failed.apply_action({"type": "Retry"})
	_check(failed.attempt_state == "Playing" and failed.hearts == 3, "Retry resets same level")

	var won = Session.new(e01)
	for row in range(int(e01["size"])):
		var cell := [row, int(e01["solution"][row])]
		if not won.is_given(cell):
			won.apply_action({"type": "TryCandy", "cell": cell})
	_check(won.attempt_state == "Won", "all candies including givens wins")
	_check(won.scorecard() == 100 * (int(e01["size"]) - e01["givens"].size()), "givens earn no points")

	if failures.is_empty():
		print("M1_A01_PUZZLE_CORE_PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

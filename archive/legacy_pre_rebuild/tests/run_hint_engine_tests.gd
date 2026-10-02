extends SceneTree

const HintEngine = preload("res://scripts/hint_engine.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_run()
	if failures.is_empty():
		print("M1_A04_HINT_ENGINE_PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _run() -> void:
	var levels = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/runtime_levels.json"))["levels"]
	var t01: Dictionary = levels[0]
	var s301: Dictionary = levels[1]
	var engine := HintEngine.new()

	var fresh := {"cells": [], "hintCount": 0}
	var direct := engine.get_hint(t01, fresh)
	_check(direct.get("ok", false), "fresh T01 has a hint")
	_check(direct["evidence"]["rule"] == "S2", "fresh T01 prefers direct S2")
	_check(direct["evidence"]["cell"] == [0, 1], "S2 points at the forced T01 cell")
	_check(direct["consumeHint"], "valid S2 consumes hint")
	_check(engine.get_hint(t01, {"cells": [], "hintCount": 1}).get("ok", false) == false, "used hint is not issued again")

	var s3_hint := engine.get_hint(s301, fresh)
	_check(s3_hint.get("ok", false), "fresh S301 has a hint")
	_check(s3_hint["evidence"]["rule"] == "S3", "S301 starts with S3 when no S2 exists")
	_check(s3_hint["evidence"]["eliminateCells"].size() == 2, "S3 exposes eliminated cells")
	_check(str(s3_hint["evidence"]["source"]["id"]) == "A", "S3 exposes source unit")
	_check(int(s3_hint["evidence"]["target"]["id"]) == 0, "S3 exposes target unit")

	var after_s3 := {"cells": [], "hintCount": 0, "eliminated": ["0,2", "0,3"]}
	var chained := engine.get_hint(s301, after_s3)
	_check(chained.get("ok", false), "S301 produces a follow-up hint")
	_check(chained["evidence"]["rule"] == "S2", "S3 elimination unlocks S2")
	_check(chained["evidence"]["cell"] == [1, 3], "follow-up S2 points at region B")

	var x_state := {"cells": ["empty", "x"], "hintCount": 0}
	var target_x := engine.get_hint(t01, x_state)
	_check(target_x.get("ok", false), "hint remains valid when target is X")
	_check(target_x["evidence"].get("action", "") == "try_candy", "X target asks for direct candy attempt")
	var error_state := {"cells": ["empty", "x_error"], "hintCount": 0}
	var error_hint := engine.get_hint(t01, error_state)
	_check(not error_hint.get("ok", false) or error_hint["evidence"].get("cell", []) != [0, 1], "x_error is never suggested as target")

	var no_hint := engine.get_hint(t01, {"cells": ["candy", "candy", "candy", "candy", "candy", "candy", "candy", "candy", "candy", "candy", "candy", "candy", "candy", "candy", "candy", "candy"], "hintCount": 0})
	_check(no_hint.get("ok", false) == false, "no evidence returns NoHint")
	_check(no_hint.get("consumeHint", true) == false, "NoHint does not consume hint")

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append("FAIL: " + label)

extends SceneTree

const Loader = preload("res://scripts/level_loader.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var loaded: Dictionary = Loader.load_document("res://tests/fixtures/runtime_levels.json")
	_check(loaded.get("ok", false), "runtime fixture loads")
	_check(loaded.get("levels", []).size() == 3, "runtime fixture has T01/S301/N12")
	_check(loaded.get("levels", [])[1].get("id") == "S301", "S301 is preserved")

	var t01: Dictionary = loaded["levels"][0].duplicate(true)
	var bad_version := t01.duplicate(true)
	bad_version["schemaVersion"] = 3
	_expect_invalid(bad_version, "schemaVersion", "old schema rejected")

	var bad_solution := t01.duplicate(true)
	bad_solution["solution"] = [0, 1, 2, 3]
	_expect_invalid(bad_solution, "solution", "declared solution rejected")

	var bad_regions := t01.duplicate(true)
	bad_regions["regions"][0] = "ZABB"
	_expect_invalid(bad_regions, "regions", "invalid region label rejected")

	var bad_given := t01.duplicate(true)
	bad_given["givens"] = [{"r": 0, "c": 0}]
	_expect_invalid(bad_given, "given", "given outside solution rejected")

	var s301: Dictionary = loaded["levels"][1].duplicate(true)
	var bad_s3 := s301.duplicate(true)
	bad_s3["logicTrace"][0]["conclusion"]["cells"] = [{"r": 0, "c": 1}]
	_expect_invalid(bad_s3, "S3", "wrong S3 elimination rejected")

	var bad_rule := s301.duplicate(true)
	bad_rule["logicTrace"][0]["rule"] = "S4"
	_expect_invalid(bad_rule, "unsupported", "S4 rejected")

	var n12: Dictionary = loaded["levels"][2].duplicate(true)
	var n12_result := Loader.validate_level(n12)
	_check(n12_result.get("ok", false), "N12 accepted as data")
	var release_result := Loader.validate_level(n12, true)
	_check(not release_result.get("ok", false), "N12 rejected for M1 campaign")
	_check(str(release_result.get("error", {}).get("reason", "")).find("release") >= 0, "release error explains N12")

	var malformed := {"levels": [{"id": "T01"}]}
	var malformed_result := Loader.validate_document(malformed)
	_check(not malformed_result.get("ok", false), "incomplete level rejected")
	_check(malformed_result.get("error", {}).get("id", "") == "T01", "error contains level ID")

	if failures.is_empty():
		print("M1_A02_LEVEL_LOADER_PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _expect_invalid(level: Dictionary, reason_fragment: String, label: String) -> void:
	var result := Loader.validate_level(level)
	_check(not result.get("ok", false), label)
	_check(str(result.get("error", {}).get("reason", "")).find(reason_fragment) >= 0, label + " reports reason")


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

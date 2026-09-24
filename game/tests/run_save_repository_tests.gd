extends SceneTree

const Repository = preload("res://scripts/save_repository.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_run()
	if failures.is_empty():
		print("M1_A03_SAVE_REPOSITORY_PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _run() -> void:
	var root := OS.get_user_data_dir().path_join("m1_a03_save_tests")
	var repository := Repository.new(root)
	repository.clear_all()

	var progress := repository.new_progress("L01")
	progress["completedLevelIds"] = ["L00"]
	progress["results"] = {"L00": {"score": 100, "mistakes": 0, "hints": 0, "elapsedMs": 10}}
	_check(repository.save_progress(progress), "progress saves")
	var loaded_progress := repository.load_progress()
	_check(loaded_progress.get("ok", false), "progress loads")
	_check(loaded_progress["data"]["currentLevelId"] == "L01", "progress keeps current level")

	var session := repository.new_session("L01", "hash-l01", 4)
	session["cells"] = ["empty", "x", "cat", "x_error"]
	session["hearts"] = 2
	session["mistakeCount"] = 1
	session["hintCount"] = 1
	session["elapsedMs"] = 84000
	_check(repository.save_session(session), "session saves")
	var loaded_session := repository.load_session("L01", "hash-l01")
	_check(loaded_session.get("ok", false), "session loads")
	_check(loaded_session["data"]["hintCount"] == 1, "session preserves hint count")
	_check(loaded_session["data"]["cells"].size() == 4, "session preserves cells")

	var wrong_level := repository.load_session("L02", "hash-l01")
	_check(not wrong_level.get("ok", false), "session level mismatch rejected")
	_check(wrong_level.get("reason", "").find("level") >= 0, "level mismatch explains recovery")
	var wrong_hash := repository.load_session("L01", "other-hash")
	_check(not wrong_hash.get("ok", false), "session hash mismatch rejected")
	_check(wrong_hash.get("recreate", false), "invalid session requests same-level recreation")

	var invalid_progress := progress.duplicate(true)
	invalid_progress["progressVersion"] = 1
	_check(not repository.save_progress(invalid_progress), "old progress version rejected")

	var next_progress := repository.complete_level(progress, "L01", {"score": 375, "mistakes": 1, "hints": 0, "elapsedMs": 84000}, ["L01", "L02"])
	_check(next_progress.get("ok", false), "level completion is accepted")
	_check(next_progress["data"]["currentLevelId"] == "L02", "completion advances to next level")
	_check(next_progress["data"]["completedLevelIds"].has("L01"), "completion records level once")
	_check(repository.save_progress(next_progress["data"]), "completed progress saves")
	_check(repository.clear_session(), "winning level clears session")
	_check(not repository.load_session("L01", "hash-l01").get("ok", false), "cleared session is absent")

	# Keep a valid backup, then corrupt the primary. Recovery must not replace it with empty progress.
	_check(repository.save_progress(next_progress["data"]), "second progress save creates backup")
	_check(repository.save_progress(next_progress["data"].duplicate(true)), "third progress save keeps backup")
	_check(repository.corrupt_for_test("progress"), "test corruption writes invalid primary")
	var recovered := repository.load_progress()
	_check(recovered.get("ok", false), "progress recovers from backup")
	_check(recovered.get("recovered", false), "progress recovery is reported")
	_check(recovered["data"]["currentLevelId"] == "L02", "backup recovery preserves progress")

	repository.clear_all()

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append("FAIL: " + label)

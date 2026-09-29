extends SceneTree

const Core = preload("res://scripts/puzzle_core.gd")
const Repository = preload("res://scripts/save_repository.gd")

func _initialize() -> void:
	var failures: Array = []
	if OS.has_feature("windows"):
		var expected := OS.get_environment("APPDATA").path_join("Godot/app_userdata/ASOL Game 02").replace("\\", "/")
		if OS.get_user_data_dir().replace("\\", "/") != expected:
			failures.append("Rebrand must preserve the existing Windows profile path")
	var core = Core.new()
	if not core.has_method("try_candy"):
		failures.append("CanDoKu API missing")
	else:
		var result: Dictionary = core.call("try_candy", {"size": 4, "regions": ["AAAA", "BBBB", "CCCC", "DDDD"], "solution": [1, 3, 0, 2], "givens": []}, {}, 3, 0, [0, 1])
		if result["cells"].get("0,1") != "candy" or not result["events"].has("CandyFound"):
			failures.append("Candy state/event contract")
	var repository = Repository.new(OS.get_user_data_dir().path_join("candoku_migration_%d" % Time.get_ticks_usec()))
	var legacy: Dictionary = repository.new_session("L01", "hash", 4)
	legacy.merge({"sessionVersion": 2, "cells": ["cat", "x", "x_error", "empty"], "hearts": 2, "hintCount": 1, "mistakeCount": 1, "elapsedMs": 1250}, true)
	var file := FileAccess.open(repository.root_dir.path_join("session.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var loaded: Dictionary = repository.load_session("L01", "hash")
	if FileAccess.get_file_as_string(repository.root_dir.path_join("session.json")) != JSON.stringify(legacy):
		failures.append("Loading migration must not overwrite the source file")
	if repository.load_session("L02", "hash").get("ok", false) or repository.load_session("L01", "changed").get("ok", false):
		failures.append("Migration must preserve level and hash validation")
	if not loaded.get("ok", false):
		failures.append("Legacy session must load")
	else:
		var data: Dictionary = loaded["data"]
		if data["sessionVersion"] != 3 or data["cells"] != ["candy", "x", "x_error", "empty"]:
			failures.append("Legacy session must migrate")
		if data["hearts"] != 2 or data["hintCount"] != 1 or data["mistakeCount"] != 1 or data["elapsedMs"] != 1250:
			failures.append("Migration must preserve attempt")
		if not repository.save_session(data) or not repository.load_session("L01", "hash").get("ok", false):
			failures.append("Migrated session must round-trip")
	var invalid: Dictionary = legacy.duplicate(true)
	invalid["sessionVersion"] = 3
	if repository.save_session(invalid):
		failures.append("Current schema must reject legacy tokens")
	var migration = load("res://scripts/legacy_session_migration.gd")
	for version in [1, 4]:
		invalid["sessionVersion"] = version
		if repository.save_session(migration.to_current(invalid)):
			failures.append("Unknown versions must not be silently accepted")
	invalid["sessionVersion"] = 2
	invalid["cells"] = ["candy", "unknown", "x", "empty"]
	if repository.save_session(migration.to_current(invalid)):
		failures.append("Malformed legacy vocabulary must be rejected")
	repository.clear_all()
	DirAccess.remove_absolute(repository.root_dir)
	if failures.is_empty():
		print("CANDOKU_CONTRACT_PASS")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

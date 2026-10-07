extends SceneTree

const Progress = preload("res://scripts/state/progress_manager.gd")
var failures: Array[String] = []

func _init() -> void:
	var dir := OS.get_user_data_dir().path_join("m02_progress_%s" % Time.get_ticks_usec())
	var manager := Progress.new(dir)
	manager.current = manager.new_progress("L01")
	check(manager.current["currentLevelId"] == "L01", "initial level")
	check(manager.save(), "save")
	check(manager.load().get("data", {}).get("currentLevelId") == "L01", "load")
	var advanced := manager.advance_level("L01", {"score": 400}, ["L01", "L02"])
	check(advanced.get("ok"), "advance")
	check(manager.current["currentLevelId"] == "L02", "next level")
	check(manager.current["completedLevelIds"] == ["L01"], "completed once")
	check(manager.current["results"].get("L01", {}).get("score") == 400, "score stored")
	check(not manager.advance_level("L01", {}, ["L01", "L02"]).get("ok"), "cannot advance stale level")
	check(manager.advance_level("L02", {}, ["L01", "L02"]).get("ok"), "finish campaign")
	check(manager.current["completedLevelIds"] == ["L01", "L02"], "final completed")
	check(not manager.advance_level("L02", {"score": 1}, ["L01", "L02"]).get("ok"), "final level cannot advance twice")
	manager.current["currentLevelId"] = "L01"
	var readvance := manager.advance_level("L01", {"score": 500}, ["L01", "L02", "L03"])
	check(readvance.get("ok"), "re-advance non-final level ok")
	check(manager.current["currentLevelId"] == "L02", "re-advance reaches next level")
	check(manager.current["results"].get("L01", {}).get("score") == 500, "re-advance updates score")
	check(manager.puzzle_fingerprint({"size": 4, "regions": ["A"], "solution": [0], "givens": []}) == manager.puzzle_fingerprint({"givens": [], "solution": [0], "regions": ["A"], "size": 4}), "fingerprint deterministic")
	manager._store.remove_all()
	DirAccess.remove_absolute(dir)
	# --- Shape queue tests ---
	var shape_dir := OS.get_user_data_dir().path_join("m02_shapes_%s" % Time.get_ticks_usec())
	var shape_pm := Progress.new(shape_dir)
	shape_pm.current = shape_pm.new_progress("L01")
	check(not shape_pm.has_recent_shape("4x4_abc123"), "shape not found initially")
	shape_pm.record_shape("4x4_abc123")
	check(shape_pm.has_recent_shape("4x4_abc123"), "shape found after record")
	check(not shape_pm.has_recent_shape("4x4_xyz789"), "different shape not found")
	for i in range(55):
		shape_pm.record_shape("shape_%d" % i)
	check(not shape_pm.has_recent_shape("4x4_abc123"), "original shape evicted after 55 inserts (cap 50)")
	check(shape_pm.has_recent_shape("shape_54"), "newest shape present")
	check(shape_pm.current.get("recentShapes", []).size() <= 50, "queue capped at 50")
	shape_pm._store.remove_all()
	DirAccess.remove_absolute(shape_dir)
	# --- Endless block & migration tests ---
	var endless_dir := OS.get_user_data_dir().path_join("m02_endless_%s" % Time.get_ticks_usec())
	var endless_pm := Progress.new(endless_dir)
	endless_pm.current = endless_pm.new_progress("L01")
	check(endless_pm.current.get("progressVersion") == 3, "progress version 3")
	check(endless_pm.current.get("endless") is Dictionary, "endless is dict")
	check(endless_pm.get_endless_data().is_empty(), "endless initial empty")
	endless_pm.set_endless_data({"level_num": 5, "streak": 2})
	check(endless_pm.save(), "save with endless")
	var loaded_endless = endless_pm.load()
	check(loaded_endless.get("ok"), "load with endless ok")
	check(endless_pm.get_endless_data().get("level_num") == 5, "endless level_num persisted")
	# Migration from v2
	var v2_data := {
		"progressVersion": 2,
		"currentLevelId": "L03",
		"completedLevelIds": ["L01", "L02"],
		"results": {"L01": {"score": 100}},
		"tutorialSeenIds": ["T01"],
		"recentShapes": ["shape_1"]
	}
	var migrated := endless_pm._migrate(v2_data)
	check(migrated.get("progressVersion") == 3, "migrated to v3")
	check(migrated.get("currentLevelId") == "L03", "preserved currentLevelId")
	check(migrated.get("completedLevelIds") == ["L01", "L02"], "preserved completedLevelIds")
	check(migrated.get("endless") is Dictionary, "migrated added endless")
	check(endless_pm._validate(migrated), "migrated passes validation")
	endless_pm._store.remove_all()
	DirAccess.remove_absolute(endless_dir)
	if failures.is_empty():
		print("STATE_PROGRESS_PASS")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

extends SceneTree

const Session = preload("res://scripts/state/session_store.gd")
var failures: Array[String] = []

func _init() -> void:
	var dir := OS.get_user_data_dir().path_join("m02_session_%s" % Time.get_ticks_usec())
	var store := Session.new(dir)
	var data := store.new_session("L01", "hash1", 4)
	check(data["cells"].size() == 16 and data["hearts"] == 3, "fresh session")
	check(store.save_session(data), "save valid session")
	check(store.has_pending(), "pending session")
	check(store.load_session("L01", "hash1").get("ok"), "load matching session")
	var mismatch := store.load_session("L01", "hash2")
	check(not mismatch.get("ok") and mismatch.get("recreate"), "hash mismatch recreates")
	check(not store.load_session("L02", "hash1").get("ok"), "wrong level rejected")
	data["cells"][0] = "error"
	check(store.save_session(data), "error cell can be persisted")
	check(store.load_session("L01", "hash1").get("data", {}).get("cells", [])[0] == "error", "error cell restored")
	data["cells"][0] = "given"
	check(not store.save_session(data), "given cannot be persisted")
	store.clear()
	check(not store.has_pending(), "clear")
	DirAccess.remove_absolute(dir)
	# --- Snapshot round-trip ---
	var snap_dir := OS.get_user_data_dir().path_join("m02_snap_%s" % Time.get_ticks_usec())
	var snap_store := Session.new(snap_dir)
	var snap_data := snap_store.new_session("L01", "hash_snap", 4)
	snap_data["snapshot"] = {
		"level_id": "L01", "size": 4, "rank": 1,
		"regions": ["AABB", "ABBB", "CCBB", "CCDB"],
		"solution": [1, 3, 0, 2], "givens": [],
		"zone_colors": {"A": "#FF0000", "B": "#00FF00", "C": "#0000FF", "D": "#FFFF00"},
		"zone_overlays": {}, "shape_hash": "4x4_abc123",
		"transform_id": 0, "hearts_start": 3, "seed": 7,
	}
	check(snap_store.save_session(snap_data), "save with snapshot")
	var snap_loaded := snap_store.load_session("L01", "hash_snap")
	check(snap_loaded.get("ok"), "load with snapshot ok")
	check(snap_loaded.get("data", {}).has("snapshot"), "snapshot field preserved")
	check(snap_loaded.get("data", {}).get("snapshot", {}).get("level_id") == "L01", "snapshot level_id correct")
	check(snap_loaded.get("data", {}).get("snapshot", {}).get("regions", []).size() == 4, "snapshot regions correct")
	# --- Session without snapshot still loads ---
	var no_snap := snap_store.new_session("L02", "hash_no_snap", 4)
	check(snap_store.save_session(no_snap), "save without snapshot")
	var no_snap_loaded := snap_store.load_session("L02", "hash_no_snap")
	check(no_snap_loaded.get("ok"), "load without snapshot ok")
	check(not no_snap_loaded.get("data", {}).has("snapshot"), "no phantom snapshot")
	snap_store.clear()
	DirAccess.remove_absolute(snap_dir)
	if failures.is_empty():
		print("STATE_SESSION_PASS")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

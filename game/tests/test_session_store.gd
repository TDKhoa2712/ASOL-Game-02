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
	data["cells"][0] = "given"
	check(not store.save_session(data), "given cannot be persisted")
	store.clear()
	check(not store.has_pending(), "clear")
	DirAccess.remove_absolute(dir)
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

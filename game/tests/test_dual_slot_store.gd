extends SceneTree

const Store = preload("res://scripts/state/dual_slot_store.gd")
var failures: Array[String] = []

func _init() -> void:
	var dir := OS.get_user_data_dir().path_join("m02_slot_%s" % Time.get_ticks_usec())
	var store := Store.new(dir, "progress")
	check(store.write_json({"value": 1}), "first write")
	check(store.write_json({"value": 2}), "second write")
	check(store.read_json().get("data", {}).get("value") == 2, "reads newest slot")
	check(store.inject_corrupt("invalid json"), "corrupt active")
	var recovered := store.read_json()
	check(recovered.get("ok") and recovered.get("recovered"), "recovers prior slot")
	check(recovered.get("data", {}).get("value") == 1, "prior payload intact")
	store.remove_all()
	check(not store.read_json().get("ok"), "remove all slots")
	var legacy := FileAccess.open(dir.path_join("progress.json"), FileAccess.WRITE)
	legacy.store_string('{"value":7}')
	legacy.close()
	check(store.read_json().get("data", {}).get("value") == 7, "reads legacy")
	store.remove_all()
	DirAccess.remove_absolute(dir)
	if failures.is_empty():
		print("STATE_DUAL_SLOT_PASS")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

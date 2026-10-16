extends SceneTree

const ScreenRouter = preload("res://scripts/campaign/screen_router.gd")
const AppShell = preload("res://scripts/screens/app_shell.gd")
var failures: Array[String] = []

func _init() -> void:
	for key in ["title", "puzzle", "win", "fail", "options", "streak", "streak_activate", "streak_gift"]:
		check(ScreenRouter.scene_path(key) == "res://scenes/%s.tscn" % key, "path for " + key)
	check(ScreenRouter.scene_path("nope") == "", "unknown key has no path")
	check(ScreenRouter.instantiate("nope") == null, "unknown key builds nothing")

	var fail_screen := ScreenRouter.instantiate("fail")
	check(fail_screen != null and fail_screen.get_parent() == null, "fail scene built, not parented")
	if fail_screen != null:
		check(fail_screen.anchor_right == 1.0 and fail_screen.anchor_bottom == 1.0, "full-rect anchors")
		fail_screen.free()

	var host := Control.new()
	root.add_child(host)
	host.add_child(Control.new()); host.add_child(Control.new())
	ScreenRouter.clear(host)
	check(host.get_child_count() == 0, "clear detaches all children")
	ScreenRouter.clear(null)
	host.queue_free()

	check(not (AppShell as Script).get_script_constant_map().has("SCENE_MAP"), "scene map lives only in the router")

	if failures.is_empty():
		print("SCREEN_ROUTER_PASS"); quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)

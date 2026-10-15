# Screen name -> scene lookup and instantiation; per-screen wiring stays in app_shell.
extends RefCounted

const SCENE_MAP := {
	"title": "res://scenes/title.tscn",
	"puzzle": "res://scenes/puzzle.tscn",
	"win": "res://scenes/win.tscn",
	"fail": "res://scenes/fail.tscn",
	"options": "res://scenes/options.tscn",
	"streak": "res://scenes/streak.tscn",
	"streak_activate": "res://scenes/streak_activate.tscn",
	"streak_gift": "res://scenes/streak_gift.tscn",
}

static func scene_path(screen_name: String) -> String:
	return SCENE_MAP.get(screen_name, "")

static func instantiate(screen_name: String) -> Control:
	var path := scene_path(screen_name)
	if path == "" or not ResourceLoader.exists(path):
		return null
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var screen := packed.instantiate() as Control
	if screen != null:
		screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return screen

static func clear(host: Node) -> void:
	if host == null:
		return
	for child in host.get_children():
		child.queue_free()
		host.remove_child(child)

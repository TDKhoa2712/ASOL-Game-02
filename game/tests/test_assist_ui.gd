extends SceneTree

const PuzzleLayout = preload("res://scripts/screens/puzzle_layout.gd")
const AssistDock = preload("res://scripts/screens/assist_dock.gd")
const EmptyPopup = preload("res://scripts/screens/assist_empty_popup.gd")
var failures: Array[String] = []

func _init() -> void:
	var root := Control.new()
	var n: Dictionary = PuzzleLayout.build(root)
	var place: Button = n.get("place")
	check(place != null and place.name == "PlaceBtn", "place button built")
	check(place.get_parent() == n["hint"].get_parent(), "place sits in the dock")
	check(place.get_index() == n["hint"].get_index() + 1, "place right of hint")
	var hb: Control = n["hint"].get_node("Badge")
	check(not hb.visible, "hint badge hidden until bound")
	AssistDock.set_badge(n["hint"], 0)
	check(hb.visible and n["hint"].get_node("Badge/HintCount").text == "0", "badge shows zero")
	AssistDock.set_badge(place, 4)
	check(place.get_node("Badge/PlaceCount").text == "4", "place badge")
	var popup := EmptyPopup.new()
	root.add_child(popup)
	check(not popup.visible, "popup starts hidden")
	popup.open("place")
	check(popup.visible, "popup opens")
	check(not popup.ad_badge.visible, "ad badge hidden until ads exist")
	var text := popup.title_label.text + popup.body_label.text
	check(not text.to_lower().contains("streak") and not text.contains("chuỗi"), "no streak shown")
	var hits: Array = []
	popup.ad_pressed.connect(func(): hits.append(1))
	popup.ad_btn.pressed.emit()
	check(hits == [1], "ad button emits")
	popup.close_btn.pressed.emit()
	check(not popup.visible, "close hides")
	root.free()
	if failures.is_empty():
		print("ASSIST_UI_PASS")
		quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)

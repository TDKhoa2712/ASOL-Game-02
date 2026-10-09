extends SceneTree

const PuzzleLayout = preload("res://scripts/screens/puzzle_layout.gd")
const RuleIcon = preload("res://scripts/screens/rule_icon.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_rule_cards_are_large()
	if _fails.is_empty():
		print("PUZZLE_LAYOUT_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_rule_cards_are_large() -> void:
	var root := Control.new()
	var n: Dictionary = PuzzleLayout.build(root)
	var icons: Array = n["rules"].find_children("*", "Control", true, false).filter(func(c): return c.get_script() == RuleIcon)
	_assert(icons.size() == 3, "three rule icons")
	for icon in icons:
		_assert(icon.custom_minimum_size.x >= PuzzleLayout.RULE_ICON_SIZE, "rule icon size >= %d" % PuzzleLayout.RULE_ICON_SIZE)
	for label in n["rules"].find_children("*", "Label", true, false):
		_assert(label.get_theme_font_size("font_size") >= PuzzleLayout.RULE_FONT_SIZE, "rule caption font >= %d" % PuzzleLayout.RULE_FONT_SIZE)
	root.free()

func _assert(cond: bool, msg: String) -> void:
	if not cond:
		_fails.append(msg)

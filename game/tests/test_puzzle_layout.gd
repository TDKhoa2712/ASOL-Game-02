extends SceneTree

const PuzzleLayout = preload("res://scripts/screens/puzzle_layout.gd")
const RuleIcon = preload("res://scripts/screens/rule_icon.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_rule_cards_are_large()
	_test_dock_is_large_and_above_ad_slot()
	_test_top_bar_buttons_are_large()
	_test_hint_card_above_board_and_apply_in_dock_area()
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
		_assert(label.max_font_size >= PuzzleLayout.RULE_FONT_SIZE, "rule caption may grow to %d" % PuzzleLayout.RULE_FONT_SIZE)
	root.free()

func _test_dock_is_large_and_above_ad_slot() -> void:
	var root := Control.new()
	var n: Dictionary = PuzzleLayout.build(root)
	for key in ["undo", "hint"]:
		_assert(n[key].custom_minimum_size.x >= PuzzleLayout.DOCK_BTN_SIZE, "%s button >= %d" % [key, PuzzleLayout.DOCK_BTN_SIZE])
	var ad: Control = n["ad_slot"]
	_assert(ad != null and ad.custom_minimum_size.y >= PuzzleLayout.AD_SLOT_HEIGHT, "ad slot reserves >= %d px" % PuzzleLayout.AD_SLOT_HEIGHT)
	_assert(n["undo"].custom_minimum_size.x <= 128, "dock buttons stay compact")
	var dock_area: Control = n["dock_area"]
	var board_card: Control = n["board"].get_parent()
	_assert(dock_area.get_parent() == board_card.get_parent() and dock_area.get_index() > board_card.get_index(), "dock sits in the gap below the board")
	_assert(dock_area.size_flags_vertical & Control.SIZE_EXPAND != 0, "dock area takes the space left under the board")
	_assert(board_card.size_flags_vertical & Control.SIZE_EXPAND == 0, "board card no longer stretches past the board")
	_assert(ad.get_parent() == dock_area.get_parent() and ad.get_index() > dock_area.get_index(), "ad slot sits below the dock")
	root.free()

func _test_top_bar_buttons_are_large() -> void:
	var root := Control.new()
	var n: Dictionary = PuzzleLayout.build(root)
	for key in ["back", "help", "restart", "settings"]:
		_assert(n[key].custom_minimum_size.x >= PuzzleLayout.TOP_BTN_SIZE, "%s button >= %d" % [key, PuzzleLayout.TOP_BTN_SIZE])
	root.free()

func _test_hint_card_above_board_and_apply_in_dock_area() -> void:
	var root := Control.new()
	var n: Dictionary = PuzzleLayout.build(root)
	var overlay: Control = n["hint_overlay"]
	var board_card: Control = n["board"].get_parent()
	_assert(overlay.get_parent() == n["rules"].get_parent(), "hint card shares the rule slot above the board")
	_assert(overlay.get_parent().get_index() < board_card.get_index(), "hint card sits above the board")
	_assert(overlay._apply_btn.get_parent() == n["dock_area"], "apply button lives in the dock area")
	_assert(not overlay._apply_btn.visible, "apply button hidden until a hint shows")
	overlay.show_hint({"strategy": "SINGLE_CANDIDATE", "explanation_key": "hint.wrong_mark"})
	_assert(overlay._apply_btn.visible, "apply button shown with the hint")
	overlay.dismiss()
	_assert(not overlay._apply_btn.visible, "apply button hidden after dismiss")
	root.free()

func _assert(cond: bool, msg: String) -> void:
	if not cond:
		_fails.append(msg)

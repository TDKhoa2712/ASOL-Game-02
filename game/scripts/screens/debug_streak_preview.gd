# game/scripts/screens/debug_streak_preview.gd
# Debug-only overlay showing streak screens with fake data; never touches the inventory.
extends RefCounted

const NavController = preload("res://scripts/campaign/nav_controller.gd")
const ScreenRouter = preload("res://scripts/campaign/screen_router.gd")
const FAKE_VIEW := {"count": 12, "best": 20, "kept_today": false, "at_risk": true, "cycle_done": 5}
const FAKE_REWARD := {"hint": 2, "place": 1}

static func open(host: Control, screen: int) -> Control:
	if not screen in [NavController.Screen.STREAK, NavController.Screen.STREAK_ACTIVATE, NavController.Screen.STREAK_GIFT]:
		return null
	var node := ScreenRouter.instantiate(NavController.SCREEN_NAMES[screen])
	if node == null:
		return null
	node.name = "DebugStreakPreview"
	match screen:
		NavController.Screen.STREAK:
			node.call("show_view", FAKE_VIEW)  # never setup(): that would read the real inventory
			node.connect("back_pressed", node.queue_free)
		NavController.Screen.STREAK_ACTIVATE:
			node.call("setup", FAKE_VIEW)
			node.connect("continued", node.queue_free)
		NavController.Screen.STREAK_GIFT:
			node.call("setup", FAKE_REWARD)
			node.connect("continued", node.queue_free)
	node.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
			node.queue_free())
	host.get_tree().root.add_child(node)
	return node

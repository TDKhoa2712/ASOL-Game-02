# Orders the streak steps shown between a finished round and its result screen.
extends RefCounted

const NavController = preload("res://scripts/campaign/nav_controller.gd")

var view: Dictionary = {}
var reward: Dictionary = {}
var _queue: Array[int] = []
var _final: int = NavController.Screen.WIN

# source: the finished screen's PuzzleAssistController (exposes round_result) or a result Dictionary.
func start(source: Variant, final_screen: int) -> int:
	var result: Variant = source
	if source is Object:
		result = (source as Object).get("round_result")
	if not result is Dictionary:
		result = {}
	_final = final_screen
	_queue.clear()
	view = result.get("view", {})
	reward = result.get("reward", {})
	if bool(result.get("extended", false)):
		_queue.append(NavController.Screen.STREAK_ACTIVATE)
		if not reward.is_empty():
			_queue.append(NavController.Screen.STREAK_GIFT)
	_queue.append(final_screen)
	return next()

func next() -> int:
	return _queue.pop_front() if not _queue.is_empty() else _final

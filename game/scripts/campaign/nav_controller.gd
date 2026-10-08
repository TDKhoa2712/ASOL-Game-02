extends RefCounted

signal screen_changed(from_screen: String, to_screen: String)

enum Screen { TITLE, PUZZLE, WIN, FAIL }

const SCREEN_NAMES := {
	Screen.TITLE: "title", Screen.PUZZLE: "puzzle", Screen.WIN: "win",
	Screen.FAIL: "fail",
}
const ROUTES := {
	Screen.TITLE: [Screen.PUZZLE],
	Screen.PUZZLE: [Screen.WIN, Screen.FAIL, Screen.TITLE],
	Screen.WIN: [Screen.PUZZLE, Screen.TITLE],
	Screen.FAIL: [Screen.PUZZLE, Screen.TITLE],
}

var _current: int = Screen.TITLE

func go_to(target: int) -> bool:
	if not SCREEN_NAMES.has(target) or not ROUTES[_current].has(target):
		return false
	var before := current_name()
	_current = target
	screen_changed.emit(before, current_name())
	return true

func current() -> int:
	return _current

func current_name() -> String:
	return SCREEN_NAMES[_current]

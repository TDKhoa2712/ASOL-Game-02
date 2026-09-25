extends RefCounted

## Small, deterministic navigation model for the MVP UI shell.
## Gameplay, persistence, Hint and tutorial systems are intentionally outside this model.

const SCREEN_HOME := "home"
const SCREEN_PUZZLE := "puzzle"
const SCREEN_RESULT_WIN := "result_win"
const SCREEN_RESULT_FAIL := "result_fail"
const SCREEN_HELP := "help"
const SCREEN_SETTINGS := "settings"

signal changed(screen_id: String)

var current_screen := SCREEN_HOME
var previous_screen := SCREEN_HOME


func _init(_campaign_level_ids: Array = []) -> void:
	pass



func dispatch(action: String) -> bool:
	var next_screen := current_screen
	var accepted := true

	match action:
		"start_game":
			accepted = current_screen == SCREEN_HOME
			next_screen = SCREEN_PUZZLE
		"resume_fail":
			accepted = current_screen == SCREEN_HOME
			next_screen = SCREEN_RESULT_FAIL
		"win":
			accepted = current_screen == SCREEN_PUZZLE
			next_screen = SCREEN_RESULT_WIN
		"fail":
			accepted = current_screen == SCREEN_PUZZLE
			next_screen = SCREEN_RESULT_FAIL
		"next":
			accepted = current_screen == SCREEN_RESULT_WIN
			next_screen = SCREEN_PUZZLE
		"retry":
			accepted = current_screen == SCREEN_RESULT_FAIL
			next_screen = SCREEN_PUZZLE
		"help":
			accepted = current_screen == SCREEN_HOME or current_screen == SCREEN_PUZZLE
			next_screen = SCREEN_HELP
		"settings":
			accepted = current_screen == SCREEN_HOME or current_screen == SCREEN_PUZZLE
			next_screen = SCREEN_SETTINGS
		"home":
			accepted = current_screen != SCREEN_HOME
			next_screen = SCREEN_HOME
		"back":
			accepted = current_screen == SCREEN_HELP or current_screen == SCREEN_SETTINGS
			next_screen = previous_screen if accepted else current_screen
		_:
			accepted = false

	if not accepted:
		return false

	previous_screen = current_screen
	current_screen = next_screen
	changed.emit(current_screen)
	return true

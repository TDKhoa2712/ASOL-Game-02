extends RefCounted

## Small, deterministic navigation model for the MVP UI shell.
## Gameplay, persistence, Hint and tutorial systems are intentionally outside this model.

const SCREEN_HOME := "home"
const SCREEN_PUZZLE := "puzzle"
const SCREEN_RESULT_WIN := "result_win"
const SCREEN_RESULT_FAIL := "result_fail"
const SCREEN_HELP := "help"
const SCREEN_SETTINGS := "settings"

signal changed(screen_id: String, level_id: String)

var level_ids: Array[String] = []
var current_level_index := 0
var current_screen := SCREEN_HOME
var previous_screen := SCREEN_HOME


func _init(campaign_level_ids: Array = []) -> void:
	for level_id in campaign_level_ids:
		level_ids.append(str(level_id))
	if level_ids.is_empty():
		level_ids = ["L01"]


var current_level_id: String:
	get:
		return level_ids[current_level_index]


func dispatch(action: String) -> bool:
	var next_screen := current_screen
	var next_level_index := current_level_index
	var accepted := true

	match action:
		"start_game":
			accepted = current_screen == SCREEN_HOME
			next_screen = SCREEN_PUZZLE
		"win":
			accepted = current_screen == SCREEN_PUZZLE
			next_screen = SCREEN_RESULT_WIN
		"fail":
			accepted = current_screen == SCREEN_PUZZLE
			next_screen = SCREEN_RESULT_FAIL
		"next":
			accepted = current_screen == SCREEN_RESULT_WIN
			if accepted and current_level_index + 1 < level_ids.size():
				next_level_index += 1
				next_screen = SCREEN_PUZZLE
			elif accepted:
				next_screen = SCREEN_HOME
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
	current_level_index = next_level_index
	current_screen = next_screen
	changed.emit(current_screen, current_level_id)
	return true

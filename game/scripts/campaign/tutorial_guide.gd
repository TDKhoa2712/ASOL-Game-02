extends RefCounted

const ProgressManager = preload("res://scripts/state/progress_manager.gd")

signal milestone_reached(milestone_id: String)
signal tutorial_step(text: String, highlight_cell: Array)

const MILESTONES := {
	"T1": {"trigger": "first_board", "text": "Tap a cell to mark X"},
	"T2": {"trigger": "first_mark", "text": "Tap X again to clear it"},
	"T3": {"trigger": "first_clear", "text": "Drag across cells to mark a line"},
	"T4": {"trigger": "first_drag", "text": "Double-tap to try placing candy"},
	"T5": {"trigger": "first_candy", "text": "Four rules: row, column, zone, diagonal"},
	"T6": {"trigger": "rules_shown", "text": "Use Hint when you're stuck"},
}

var _progress: ProgressManager
var _seen_ids: Array[String] = []

func _init(progress: ProgressManager) -> void:
	_progress = progress
	for id in progress.current.get("tutorialSeenIds", []):
		if id is String and MILESTONES.has(id) and not _seen_ids.has(id):
			_seen_ids.append(id)

func is_tutorial(level_id: String) -> bool:
	return level_id == "L01" and not is_all_done()

func tutorial_steps(level_id: String) -> Array:
	if not is_tutorial(level_id):
		return []
	var steps: Array = []
	for id in MILESTONES:
		if not _seen_ids.has(id):
			steps.append({"id": id, "trigger": MILESTONES[id].trigger, "text": MILESTONES[id].text})
	return steps

func mark_seen(tutorial_id: String) -> void:
	if not MILESTONES.has(tutorial_id) or _seen_ids.has(tutorial_id):
		return
	var previous := _progress.current.duplicate(true)
	_progress.current["tutorialSeenIds"].append(tutorial_id)
	if not _progress.save():
		_progress.current = previous
		return
	_seen_ids.append(tutorial_id)
	milestone_reached.emit(tutorial_id)

func check_trigger(trigger_name: String, context: Dictionary = {}) -> void:
	for id in MILESTONES:
		if MILESTONES[id].trigger == trigger_name and not _seen_ids.has(id):
			mark_seen(id)
			if _seen_ids.has(id):
				tutorial_step.emit(MILESTONES[id].text, context.get("highlight_cell", []))
			return

func seen_ids() -> Array[String]:
	return _seen_ids.duplicate()

func is_all_done() -> bool:
	return _seen_ids.size() == MILESTONES.size()

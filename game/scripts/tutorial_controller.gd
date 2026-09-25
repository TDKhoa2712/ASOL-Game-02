extends RefCounted

const TUTORIAL_LEVEL_IDS := ["L01", "T01", "1"]
const MILESTONES := ["T1", "T2", "T3", "T4", "T5", "T6"]

func is_tutorial_level(level_id: String) -> bool:
	return TUTORIAL_LEVEL_IDS.has(level_id)

func new_state(level_id: String, highlighted_cell: Array) -> Dictionary:
	return {
		"tutorialLevelId": level_id,
		"tutorialSeenIds": [],
		"tutorialHighlight": highlighted_cell.duplicate()
	}

func current_step(state: Dictionary) -> String:
	for milestone in MILESTONES:
		if not state.get("tutorialSeenIds", []).has(milestone):
			return milestone
	return ""

func all_complete(state: Dictionary) -> bool:
	return current_step(state).is_empty()

func should_show(level_id: String, state: Dictionary) -> bool:
	return is_tutorial_level(level_id) and not all_complete(state)

func process_action(state: Dictionary, action: Dictionary) -> Dictionary:
	var updated: Dictionary = state.duplicate(true)
	var completed: Array = []
	if not is_tutorial_level(str(updated.get("tutorialLevelId", ""))):
		return {"state": updated, "completed": completed, "step": "", "show": false}
	var action_type := str(action.get("type", ""))
	var target: Array = updated.get("tutorialHighlight", [])
	var action_cell: Array = action.get("cell", [])
	if action_type == "MarkX" and action_cell == target:
		_add_milestone(updated, "T1", completed)
	elif action_type == "ClearX" and action_cell == target:
		_add_milestone(updated, "T2", completed)
	elif action_type == "MarkStroke" and action.get("cells", []).size() >= 2:
		_add_milestone(updated, "T3", completed)
	elif action_type == "TryCat" and action_cell == updated.get("tutorialCatCell", target) and bool(action.get("correct", false)):
		_add_milestone(updated, "T4", completed)
	elif action_type in ["ViewRules", "OpenRules"]:
		_add_milestone(updated, "T5", completed)
	elif action_type == "CloseHint" and bool(action.get("valid", false)):
		_add_milestone(updated, "T6", completed)
	return {
		"state": updated,
		"completed": completed,
		"step": current_step(updated),
		"show": should_show(str(updated.get("tutorialLevelId", "")), updated)
	}

func try_cat_policy(level_id: String, attempted_cell: Array, highlighted_cell: Array) -> Dictionary:
	if is_tutorial_level(level_id) and attempted_cell == highlighted_cell:
		return {
			"penalize": false,
			"tutorialMessage": true,
			"reason": "Hãy thử chạm đôi trên ô đang sáng để xác nhận mèo."
		}
	return {"penalize": true, "tutorialMessage": false, "reason": ""}

func _add_milestone(state: Dictionary, milestone: String, completed: Array) -> void:
	var seen: Array = state.get("tutorialSeenIds", [])
	if not seen.has(milestone):
		seen.append(milestone)
		completed.append(milestone)
	state["tutorialSeenIds"] = seen

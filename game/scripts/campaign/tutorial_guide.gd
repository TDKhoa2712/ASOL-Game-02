# Tutorial state for the hand-authored L01/L02 boards (GDD 03 §4, RST-027).
# The current step is derived from the board plus the persisted seen ids, so a
# player who solves ahead skips the steps they no longer need and a reopened
# app lands on the same step without replaying any action.
extends RefCounted

const TutorialTargets = preload("res://scripts/campaign/tutorial_targets.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")

signal step_seen(step_id: String)

var _progress: Variant = null
var _practice: bool = false
var _script: Dictionary = {}
var _seen: Array[String] = []

# progress: a ProgressManager (or null). practice: replay from Help without
# touching saved progress.
func _init(progress: Variant = null, practice: bool = false, script: Dictionary = {}) -> void:
	_progress = progress
	_practice = practice
	_script = script if not script.is_empty() else TutorialTargets.load_script()
	if _practice or _progress == null:
		return
	for id in _progress.current.get("tutorialSeenIds", []):
		if id is String and not _seen.has(id):
			_seen.append(id)

func has_level(label: String) -> bool:
	return _levels().has(label)

func level_for(label: String) -> Dictionary:
	if not has_level(label):
		return {}
	var src: Dictionary = _levels()[label].level
	var solution: Array = []
	for c in src.solution: solution.append(int(c))
	var givens: Array = []
	for g in src.get("givens", []): givens.append({"r": int(g.r), "c": int(g.c)})
	return {"id": label, "size": int(src.size), "regions": src.regions.duplicate(), "solution": solution, "givens": givens}

# A copy of the board for Help → Replay tutorial; the key tells the puzzle
# screen to run a practice guide that never writes progress.
func practice_level(label: String) -> Dictionary:
	var level := level_for(label)
	if not level.is_empty(): level["_tutorial_practice"] = label
	return level

func has_seen(id: String) -> bool:
	return _seen.has(id)

# Records an id (tutorial step or contextual tip). Returns false when the save
# fails so the caller can show it again next time instead of losing it.
func mark_seen(id: String) -> bool:
	if _seen.has(id):
		return true
	if not _practice and _progress != null:
		var previous: Dictionary = _progress.current.duplicate(true)
		if not _progress.current.get("tutorialSeenIds") is Array:
			_progress.current["tutorialSeenIds"] = []
		_progress.current.tutorialSeenIds.append(id)
		if not _progress.save():
			_progress.current = previous
			return false
	_seen.append(id)
	step_seen.emit(id)
	return true

func skip() -> void:
	for label in _levels():
		for step in _steps(label):
			mark_seen(str(step.id))

func is_active(label: String, board: Array) -> bool:
	return not current_step(label, board).is_empty()

# The resolved step to show, or {} when this level has nothing left to teach.
func current_step(label: String, board: Array) -> Dictionary:
	var index := _current_index(label, board)
	if index < 0:
		return {}
	return _resolve(label, _steps(label)[index])

# Feeds a player/system event; returns true when the visible step changed.
# events: button, timeout, candy, mark, clear, hint_closed. data.cells lists the
# cells the event touched.
func handle(label: String, event: String, data: Dictionary, board: Array) -> bool:
	var before := _current_index(label, board)
	if before >= 0:
		var step: Dictionary = _steps(label)[before]
		if _event_completes(label, step, event, data):
			mark_seen(str(step.id))
	return _current_index(label, board) != before

# Cells the script names by coordinate are forgiven on a wrong candy try (GR-20).
func is_protected(label: String, r: int, c: int) -> bool:
	if not has_level(label) or _all_seen(label):
		return false
	var level := level_for(label)
	for step in _steps(label):
		if not step.get("protect", false):
			continue
		if TutorialTargets.resolve(level, step.get("target", {})).has([r, c]):
			return true
	return false

# Wires the forgiveness rule into a session playing a tutorial board.
func protect(session: Variant, label: String) -> void:
	if session != null and has_level(label):
		session.protect_fn = func(r: int, c: int) -> bool: return is_protected(label, r, c)

func _all_seen(label: String) -> bool:
	for step in _steps(label):
		if not has_seen(str(step.id)):
			return false
	return true

func _current_index(label: String, board: Array) -> int:
	var steps := _steps(label)
	var level := level_for(label)
	var reached := -1
	for i in range(steps.size()):
		if _state_done(level, steps[i].get("done", {}), board):
			reached = i
	for i in range(reached + 1, steps.size()):
		var step: Dictionary = steps[i]
		if has_seen(str(step.id)) or _state_done(level, step.get("skip_when", {}), board):
			continue
		return i
	return -1

func _state_done(level: Dictionary, cond: Dictionary, board: Array) -> bool:
	match str(cond.get("type", "")):
		"candy_of_region":
			var cell := TutorialTargets.candy_of_region(level, str(cond.get("region", "")))
			return not cell.is_empty() and _kind(board, cell) == CellModel.CellKind.CANDY
		"any_candy":
			for row in board:
				if row.has(CellModel.CellKind.CANDY):
					return true
	return false

func _event_completes(label: String, step: Dictionary, event: String, data: Dictionary) -> bool:
	var cond: Dictionary = step.get("done", {})
	var cells: Array = data.get("cells", [])
	var target := TutorialTargets.resolve(level_for(label), step.get("target", {}))
	match str(cond.get("type", "")):
		"button":
			return event == "button" or (event == "timeout" and step.has("auto_ms"))
		"mark", "clear":
			return event == cond.type and _overlap(cells, target) > 0
		"stroke":
			return event == "mark" and _overlap(cells, target) >= int(cond.get("min", 2))
		"hint_closed":
			return event == "hint_closed"
	return false

func _resolve(label: String, step: Dictionary) -> Dictionary:
	var level := level_for(label)
	var target := TutorialTargets.resolve(level, step.get("target", {}))
	var args: Dictionary = {}
	var rows: Array = []
	var cols: Array = []
	if not target.is_empty():
		args = {"r": int(target[0][0]) + 1, "c": int(target[0][1]) + 1}
		if step.get("axis", false):
			for cell in target:
				if not rows.has(cell[0]) and target.size() == 1: rows.append(cell[0])
				if not cols.has(cell[1]): cols.append(cell[1])
	return {
		"id": str(step.id),
		"text": str(step.get("text", "")),
		"args": args,
		"button": str(step.get("button", "")),
		"auto_ms": int(step.get("auto_ms", 0)),
		"axis_rows": rows,
		"axis_cols": cols,
		"overlay": TutorialTargets.resolve(level, step.get("overlay", {})),
		"rules": step.get("rules", []).duplicate(),
		"bounce_hint": bool(step.get("bounce_hint", false)),
		"skippable": str(step.id) != _steps(label)[0].id or label != "L01",
	}

static func _overlap(cells: Array, target: Array) -> int:
	var count := 0
	for cell in cells:
		if cell is Array and cell.size() >= 2 and target.has([int(cell[0]), int(cell[1])]):
			count += 1
	return count

static func _kind(board: Array, cell: Array) -> int:
	if cell[0] >= board.size() or cell[1] >= board[cell[0]].size():
		return CellModel.CellKind.BLANK
	return int(board[cell[0]][cell[1]])

func _levels() -> Dictionary:
	return _script.get("levels", {})

func _steps(label: String) -> Array:
	return _levels().get(label, {}).get("steps", [])

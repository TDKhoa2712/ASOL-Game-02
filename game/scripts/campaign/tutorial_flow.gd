# Mandatory onboarding puzzle (RST-028): one rule per step on a fixed 4x4
# board. Guided steps accept input only on their lit targets; the last step is
# free play (X anywhere, wrong candies refused softly). Nothing costs hearts.
extends RefCounted

const PlaySession = preload("res://scripts/input/play_session.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const TutorialTargets = preload("res://scripts/campaign/tutorial_targets.gd")

signal changed()
signal finished()
# Free play: a candy tried on a wrong cell; nothing changes on the board.
signal missed(row: int, col: int)

const LEVEL := {
	"id": "TUT", "size": 4,
	"regions": ["ABCC", "AAAC", "ADDC", "ADDD"],
	"solution": [1, 3, 0, 2], "givens": [],
}
const DROPPED_CANDY := [3, 2]

var level: Dictionary = LEVEL.duplicate(true)
var session: PlaySession = PlaySession.new(level)
var _index: int = 0
var _steps: Array = []

func _init() -> void:
	var all: Array = []
	for r in range(4):
		for c in range(4): all.append([r, c])
	var rowcol: Array = []
	for cell in all:
		if (cell[0] == 0 or cell[1] == 1) and cell != [0, 1]: rowcol.append(cell)
	var touch: Array = [DROPPED_CANDY]
	for cell in all:
		if cell != DROPPED_CANDY and absi(cell[0] - DROPPED_CANDY[0]) <= 1 and absi(cell[1] - DROPPED_CANDY[1]) <= 1: touch.append(cell)
	var lone: Array = []
	for cell in all:
		if TutorialTargets.region_at(level, cell[0], cell[1]) == "C": lone.append(cell)
	_steps = [
		{"id": "place", "text": "tutorial.s_place", "lit": [[0, 1]], "targets": [[0, 1]], "gesture": "double"},
		{"id": "regions", "text": "tutorial.s_regions", "lit": all, "button": "tutorial.ok"},
		{"id": "rowcol", "text": "tutorial.s_rowcol", "lit": rowcol + [[0, 1]], "targets": rowcol, "gesture": "tap",
			"demo": [[[0, 0], [0, 1], [0, 2], [0, 3]], [[1, 1], [2, 1], [3, 1]]]},
		{"id": "touch", "text": "tutorial.s_touch", "lit": touch, "targets": touch.slice(1), "gesture": "swipe",
			"demo": [[[2, 1], [2, 2], [2, 3], [3, 3]]]},
		{"id": "lone", "text": "tutorial.s_lone", "lit": lone, "targets": [[1, 3]], "gesture": "double"},
		{"id": "last", "text": "tutorial.s_last", "lit": all, "targets": [[2, 0]], "gesture": "double", "hint": true, "free": true},
		{"id": "done", "text": "tutorial.s_done", "lit": all, "button": "tutorial.continue", "confetti": true},
	]

# The current step with its still-open targets, or {} once finished.
func step() -> Dictionary:
	if _index >= _steps.size():
		return {}
	var s: Dictionary = _steps[_index].duplicate(true)
	var open: Array = []
	for cell in s.get("targets", []):
		if _is_open(s, cell): open.append(cell)
	s["targets"] = open
	if not s.has("demo"): s["demo"] = []
	for key in ["button", "gesture"]:
		if not s.has(key): s[key] = ""
	s["hint"] = bool(s.get("hint", false))
	s["free"] = bool(s.get("free", false))
	s["confetti"] = bool(s.get("confetti", false))
	return s

func tap(r: int, c: int) -> bool:
	var s := step()
	if s.is_empty():
		return false
	if s.free:
		if not CellModel.is_available(session.cell_at(r, c)):
			return false
		session.mark_x(r, c)
		changed.emit()
		return true
	if s.gesture not in ["tap", "swipe"] or not s.targets.has([r, c]):
		return false
	session.mark_x(r, c)
	_after_input()
	return true

func double_tap(r: int, c: int) -> bool:
	var s := step()
	if s.is_empty() or s.gesture != "double":
		return false
	if not s.targets.has([r, c]):
		if s.free and CellModel.is_available(session.cell_at(r, c)):
			missed.emit(r, c)
		return false
	session.try_candy(r, c)
	_after_input()
	return true

func stroke(cells: Array) -> bool:
	var s := step()
	if s.is_empty():
		return false
	if s.free:
		var first: Array = cells[0] if not cells.is_empty() and cells[0] is Array else []
		if first.size() < 2 or not CellModel.is_available(session.cell_at(int(first[0]), int(first[1]))):
			return false
		# Like the real board: the first cell decides between marking and clearing.
		session.mark_stroke(cells, session.cell_at(int(first[0]), int(first[1])) == CellModel.CellKind.BLANK)
		changed.emit()
		return true
	if s.gesture not in ["tap", "swipe"]:
		return false
	var hits: Array = []
	for cell in cells:
		if cell is Array and cell.size() >= 2 and s.targets.has([int(cell[0]), int(cell[1])]): hits.append([int(cell[0]), int(cell[1])])
	if hits.is_empty():
		return false
	session.mark_stroke(hits, true)
	_after_input()
	return true

func press_button() -> void:
	var s := step()
	if s.is_empty() or s.button.is_empty():
		return
	_advance()

func _is_open(s: Dictionary, cell: Array) -> bool:
	var kind := session.cell_at(cell[0], cell[1])
	if s.get("gesture", "") in ["tap", "swipe"]:
		return kind == CellModel.CellKind.BLANK
	return kind != CellModel.CellKind.CANDY

func _after_input() -> void:
	if step().targets.is_empty():
		_advance()
	else:
		changed.emit()

func _advance() -> void:
	_index += 1
	if _index < _steps.size() and _steps[_index].id == "touch":
		session.board[DROPPED_CANDY[0]][DROPPED_CANDY[1]] = CellModel.CellKind.CANDY
	if _index >= _steps.size():
		finished.emit()
	changed.emit()

extends RefCounted

const CellModel = preload("res://scripts/core/cell_model.gd")
const CandyRules = preload("res://scripts/core/candy_rules.gd")
const ActionRecorder = preload("res://scripts/input/action_recorder.gd")

signal state_changed()
signal candy_found(row: int, col: int, region: String)
signal heart_lost(remaining: int)
signal mistake_made(row: int, col: int, reason: String)
signal auto_marked(cells: Array)
signal level_won()
signal level_failed()

enum Phase {
	ACTIVE = 0,
	WON = 1,
	FAILED = 2,
}

var level: Dictionary = {}
var board: Array = []
var hearts: int = 3
var mistake_count: int = 0
var hints_used: int = 0
var elapsed_ms: int = 0
var phase: int = Phase.ACTIVE
var recorder: ActionRecorder

func _init(level_data: Dictionary, initial_hearts: int = 3) -> void:
	level = level_data
	hearts = initial_hearts
	mistake_count = 0
	hints_used = 0
	elapsed_ms = 0
	phase = Phase.ACTIVE
	recorder = ActionRecorder.new()

	var size: int = int(level.get("size", 0))
	board = []
	for r in range(size):
		var row_arr: Array = []
		for c in range(size):
			row_arr.append(CellModel.CellKind.BLANK)
		board.append(row_arr)

	for g in level.get("givens", []):
		var gr: int = int(g.get("r", -1))
		var gc: int = int(g.get("c", -1))
		if gr >= 0 and gr < size and gc >= 0 and gc < size:
			board[gr][gc] = CellModel.CellKind.GIVEN

	_recompute_all_locks()

func mark_x(row: int, col: int) -> void:
	if phase != Phase.ACTIVE:
		return
	if row < 0 or row >= board.size() or col < 0 or col >= board.size():
		return
	var current: int = board[row][col]
	if not CellModel.is_available(current):
		return

	var next: int = CellModel.CellKind.BLANK if current == CellModel.CellKind.MARK else CellModel.CellKind.MARK
	board[row][col] = next
	recorder.push_group([
		{
			"row": row,
			"col": col,
			"before": current,
			"after": next,
			"source": ActionRecorder.Source.USER
		}
	])
	state_changed.emit()

func try_candy(row: int, col: int) -> void:
	if phase != Phase.ACTIVE:
		return
	if row < 0 or row >= board.size() or col < 0 or col >= board.size():
		return
	var current: int = board[row][col]
	if not CellModel.is_available(current):
		return

	var regions: Array = level.get("regions", [])
	var solution: Array = level.get("solution", [])
	var res: Dictionary = CandyRules.attempt_candy(board, regions, solution, hearts, mistake_count, row, col)

	hearts = int(res.get("hearts", hearts))
	mistake_count = int(res.get("mistake_count", mistake_count))

	if board[row][col] == CellModel.CellKind.CANDY:
		var action_group: Array = [
			{
				"row": row,
				"col": col,
				"before": current,
				"after": CellModel.CellKind.CANDY,
				"source": ActionRecorder.Source.USER
			}
		]
		var marks: Array = res.get("auto_marks", [])
		for m in marks:
			action_group.append({
				"row": m[0],
				"col": m[1],
				"before": CellModel.CellKind.BLANK,
				"after": CellModel.CellKind.LOCKED,
				"source": ActionRecorder.Source.SYSTEM
			})
		recorder.push_group(action_group)

		var region: String = CandyRules.zone_of(regions, row, col)
		candy_found.emit(row, col, region)
		if not marks.is_empty():
			auto_marked.emit(marks)
		state_changed.emit()

		if res.get("phase") == "won":
			phase = Phase.WON
			level_won.emit()
	else:
		recorder.clear()
		mistake_made.emit(row, col, str(res.get("reason", "")))
		heart_lost.emit(hearts)
		state_changed.emit()

		if res.get("phase") == "failed" or hearts <= 0:
			phase = Phase.FAILED
			level_failed.emit()

func undo() -> bool:
	if phase != Phase.ACTIVE or not recorder.can_undo():
		return false
	var group: Array = recorder.pop_group()
	if group.is_empty():
		return false

	var had_candy_undone: bool = false
	for i in range(group.size() - 1, -1, -1):
		var action: Dictionary = group[i]
		var r: int = int(action["row"])
		var c: int = int(action["col"])
		board[r][c] = int(action["before"])
		if int(action.get("after", -1)) == CellModel.CellKind.CANDY:
			had_candy_undone = true

	if had_candy_undone:
		_recompute_all_locks()

	state_changed.emit()
	return true

func use_hint() -> void:
	hints_used += 1
	state_changed.emit()

func cell_at(row: int, col: int) -> int:
	if row < 0 or row >= board.size() or col < 0 or col >= board.size():
		return CellModel.CellKind.BLANK
	return board[row][col]

func is_preset(row: int, col: int) -> bool:
	return cell_at(row, col) == CellModel.CellKind.GIVEN

func can_undo() -> bool:
	return phase == Phase.ACTIVE and recorder != null and recorder.can_undo()

func remaining_candies() -> int:
	var size: int = board.size()
	var count: int = 0
	var solution: Array = level.get("solution", [])
	for r in range(size):
		if r < solution.size():
			var c: int = int(solution[r])
			if board[r][c] != CellModel.CellKind.CANDY and board[r][c] != CellModel.CellKind.GIVEN:
				count += 1
	return count

func to_save_data() -> Dictionary:
	var size: int = board.size()
	var flat_cells: Array[String] = []
	for r in range(size):
		for c in range(size):
			match board[r][c]:
				CellModel.CellKind.MARK:
					flat_cells.append("x")
				CellModel.CellKind.CANDY:
					flat_cells.append("candy")
				CellModel.CellKind.WRONG:
					flat_cells.append("wrong")
				CellModel.CellKind.LOCKED:
					flat_cells.append("locked")
				CellModel.CellKind.GIVEN, CellModel.CellKind.BLANK, _:
					flat_cells.append("empty")

	var status_str: String = "playing"
	if phase == Phase.WON:
		status_str = "won"
	elif phase == Phase.FAILED:
		status_str = "failed"

	return {
		"sessionVersion": 3,
		"levelId": str(level.get("id", "")),
		"puzzleHash": str(level.get("hash", "")),
		"boardSize": size,
		"cells": flat_cells,
		"hearts": hearts,
		"mistake_count": mistake_count,
		"hints_used": hints_used,
		"elapsedMs": elapsed_ms,
		"status": status_str,
	}

static func from_save_data(data: Dictionary, level_data: Dictionary) -> RefCounted:
	var script = load("res://scripts/input/play_session.gd") as GDScript
	var session = script.new(level_data, int(data.get("hearts", 3)))
	session.mistake_count = int(data.get("mistake_count", 0))
	session.hints_used = int(data.get("hints_used", 0))
	session.elapsed_ms = int(data.get("elapsedMs", 0))
	var status: String = str(data.get("status", "playing"))
	match status:
		"won":
			session.phase = Phase.WON
		"failed":
			session.phase = Phase.FAILED
		_:
			session.phase = Phase.ACTIVE

	var size: int = session.board.size()
	var flat_cells: Array = data.get("cells", [])
	for r in range(size):
		for c in range(size):
			var idx: int = r * size + c
			if idx < flat_cells.size():
				var val: String = str(flat_cells[idx])
				match val:
					"x":
						session.board[r][c] = CellModel.CellKind.MARK
					"candy":
						session.board[r][c] = CellModel.CellKind.CANDY
					"wrong":
						session.board[r][c] = CellModel.CellKind.WRONG
					"locked":
						session.board[r][c] = CellModel.CellKind.LOCKED
					"empty", _:
						session.board[r][c] = CellModel.CellKind.BLANK

	for g in level_data.get("givens", []):
		var gr: int = int(g.get("r", -1))
		var gc: int = int(g.get("c", -1))
		if gr >= 0 and gr < size and gc >= 0 and gc < size:
			session.board[gr][gc] = CellModel.CellKind.GIVEN

	return session

func _apply_auto_marks(candy_row: int, candy_col: int) -> Array:
	var regions: Array = level.get("regions", [])
	var marks: Array = CandyRules.compute_auto_marks(board, regions, candy_row, candy_col)
	var actions: Array = []
	for m in marks:
		var mr: int = m[0]
		var mc: int = m[1]
		if board[mr][mc] == CellModel.CellKind.BLANK:
			board[mr][mc] = CellModel.CellKind.LOCKED
			actions.append({
				"row": mr,
				"col": mc,
				"before": CellModel.CellKind.BLANK,
				"after": CellModel.CellKind.LOCKED,
				"source": ActionRecorder.Source.SYSTEM
			})
	return actions

func _recompute_all_locks() -> void:
	var size: int = board.size()
	for r in range(size):
		for c in range(size):
			if board[r][c] == CellModel.CellKind.LOCKED:
				board[r][c] = CellModel.CellKind.BLANK

	var regions: Array = level.get("regions", [])
	if regions.is_empty():
		return
	var marks: Array = CandyRules.compute_all_auto_marks(board, regions)
	for m in marks:
		var mr: int = m[0]
		var mc: int = m[1]
		if board[mr][mc] == CellModel.CellKind.BLANK:
			board[mr][mc] = CellModel.CellKind.LOCKED

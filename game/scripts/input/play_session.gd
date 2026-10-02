extends RefCounted

const CellModel = preload("res://scripts/core/cell_model.gd")
const CandyRules = preload("res://scripts/core/candy_rules.gd")

signal state_changed()
signal candy_found(row: int, col: int, region: String)
signal heart_lost(remaining: int)
signal mistake_made(row: int, col: int, reason: String)
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
var _undo_cells: Array = []

func _init(level_data: Dictionary, initial_hearts: int = 3) -> void:
	level = level_data
	hearts = initial_hearts
	mistake_count = 0
	hints_used = 0
	elapsed_ms = 0
	phase = Phase.ACTIVE

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


func mark_x(row: int, col: int) -> void:
	if phase != Phase.ACTIVE:
		return
	if row < 0 or row >= board.size() or col < 0 or col >= board.size():
		return
	var current: int = board[row][col]
	if not CellModel.is_available(current):
		return

	_undo_cells = [[row, col, current]]
	board[row][col] = CellModel.CellKind.BLANK if current == CellModel.CellKind.MARK else CellModel.CellKind.MARK
	state_changed.emit()

func mark_stroke(cells: Array, paint_mark: bool) -> void:
	if phase != Phase.ACTIVE:
		return
	var before: Array = []
	var seen: Dictionary = {}
	var required: int = CellModel.CellKind.BLANK if paint_mark else CellModel.CellKind.MARK
	var target: int = CellModel.CellKind.MARK if paint_mark else CellModel.CellKind.BLANK
	for value in cells:
		if not value is Array or value.size() < 2:
			continue
		var row: int = int(value[0])
		var col: int = int(value[1])
		var key := Vector2i(row, col)
		if seen.has(key) or row < 0 or row >= board.size() or col < 0 or col >= board.size():
			continue
		seen[key] = true
		if board[row][col] == required:
			before.append([row, col, required])
			board[row][col] = target
	if not before.is_empty():
		_undo_cells = before
		state_changed.emit()

func undo_mark() -> void:
	if phase != Phase.ACTIVE or _undo_cells.is_empty():
		return
	for cell in _undo_cells:
		board[int(cell[0])][int(cell[1])] = int(cell[2])
	_undo_cells = []
	state_changed.emit()

func try_candy(row: int, col: int) -> void:
	if phase != Phase.ACTIVE:
		return
	if row < 0 or row >= board.size() or col < 0 or col >= board.size():
		return
	var current: int = board[row][col]
	if not CellModel.is_available(current):
		return
	_undo_cells = []

	var regions: Array = level.get("regions", [])
	var solution: Array = level.get("solution", [])
	var res: Dictionary = CandyRules.attempt_candy(board, regions, solution, hearts, mistake_count, row, col)

	hearts = int(res.get("hearts", hearts))
	mistake_count = int(res.get("mistake_count", mistake_count))

	if board[row][col] == CellModel.CellKind.CANDY:
		var region: String = CandyRules.zone_of(regions, row, col)
		candy_found.emit(row, col, region)
		state_changed.emit()

		if res.get("phase") == "won":
			phase = Phase.WON
			level_won.emit()
	else:
		mistake_made.emit(row, col, str(res.get("reason", "")))
		heart_lost.emit(hearts)
		state_changed.emit()

		if res.get("phase") == "failed" or hearts <= 0:
			phase = Phase.FAILED
			level_failed.emit()

func use_hint() -> void:
	hints_used += 1
	state_changed.emit()

func cell_at(row: int, col: int) -> int:
	if row < 0 or row >= board.size() or col < 0 or col >= board.size():
		return CellModel.CellKind.BLANK
	return board[row][col]

func is_preset(row: int, col: int) -> bool:
	return cell_at(row, col) == CellModel.CellKind.GIVEN

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
				CellModel.CellKind.ERROR:
					flat_cells.append("error")
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
					"wrong", "error":
						session.board[r][c] = CellModel.CellKind.ERROR
					"empty", "locked", _:
						session.board[r][c] = CellModel.CellKind.BLANK

	for g in level_data.get("givens", []):
		var gr: int = int(g.get("r", -1))
		var gc: int = int(g.get("c", -1))
		if gr >= 0 and gr < size and gc >= 0 and gc < size:
			session.board[gr][gc] = CellModel.CellKind.GIVEN

	return session

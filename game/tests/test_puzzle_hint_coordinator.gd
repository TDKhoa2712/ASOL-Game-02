extends SceneTree

const PuzzleHintCoordinator = preload("res://scripts/screens/puzzle_hint_coordinator.gd")
const HintOverlay = preload("res://scripts/screens/hint_overlay.gd")
const HintHighlightLayer = preload("res://scripts/screens/hint_highlight_layer.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")

class MockSfx extends RefCounted:
	var played: Array[int] = []
	func play(effect: int, _overlap: bool = false) -> void:
		played.append(effect)

class MockBoard extends Control:
	var redrawn: bool = false
	var cell_rect_called: bool = false
	func redraw() -> void:
		redrawn = true
	func get_cell_rect(r: int, c: int) -> Rect2:
		cell_rect_called = true
		return Rect2(float(c * 50), float(r * 50), 50.0, 50.0)

var _fails: Array[String] = []

func _init() -> void:
	_test_coordinator_flow()
	_test_coordinator_wrong_mark()
	_test_coordinator_dismiss_on_second_request()

	if _fails.is_empty():
		print("HINT_COORDINATOR_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond:
		_fails.append(msg)

func _create_level() -> Dictionary:
	return {
		"id": "test_coord_1",
		"size": 4,
		"regions": [
			"0011",
			"0011",
			"2233",
			"2233",
		],
		"solution": [0, 2, 1, 3],
	}

func _test_coordinator_flow() -> void:
	var lvl := _create_level()
	var session := PlaySession.new(lvl)
	var board := MockBoard.new()
	var overlay := HintOverlay.new()
	var highlight := HintHighlightLayer.new()
	var sfx := MockSfx.new()

	var coord := PuzzleHintCoordinator.new()
	coord.setup(board, overlay, highlight, sfx)
	coord.connect_signals()

	_assert(not coord.is_hint_showing(), "initially no hint showing")

	# Request hint
	coord.request_hint(session)
	_assert(coord.is_hint_showing(), "hint showing after request")
	_assert(sfx.played.has(SfxCatalog.Effect.HINT_SHOW), "played HINT_SHOW")
	_assert(session.hints_used == 1, "session hints_used incremented")

	# Detail request
	coord.show_detail()

	# Apply hint
	coord.apply_hint(session)
	_assert(not coord.is_hint_showing(), "hint dismissed after apply")
	_assert(sfx.played.has(SfxCatalog.Effect.HINT_APPLY), "played HINT_APPLY")
	_assert(board.redrawn, "board redrawn on apply")

	overlay.free()
	highlight.free()
	board.free()

func _test_coordinator_wrong_mark() -> void:
	var lvl := _create_level()
	var session := PlaySession.new(lvl)
	# Mark cell (0, 0) which is candy in solution -> wrong mark!
	session.mark_x(0, 0)

	var board := MockBoard.new()
	var overlay := HintOverlay.new()
	var highlight := HintHighlightLayer.new()
	var sfx := MockSfx.new()

	var coord := PuzzleHintCoordinator.new()
	coord.setup(board, overlay, highlight, sfx)
	coord.connect_signals()

	coord.request_hint(session)
	_assert(coord.is_hint_showing(), "hint showing for wrong mark")
	_assert(sfx.played.has(SfxCatalog.Effect.HINT_WRONG_MARK), "played HINT_WRONG_MARK")
	_assert(session.hints_used == 0, "wrong mark does not consume hint count")

	# Dismiss
	coord.dismiss_hint()
	_assert(not coord.is_hint_showing(), "hint dismissed")
	_assert(sfx.played.has(SfxCatalog.Effect.HINT_DISMISS), "played HINT_DISMISS")

	overlay.free()
	highlight.free()
	board.free()

func _test_coordinator_dismiss_on_second_request() -> void:
	var lvl := _create_level()
	var session := PlaySession.new(lvl)
	var board := MockBoard.new()
	var overlay := HintOverlay.new()
	var highlight := HintHighlightLayer.new()
	var sfx := MockSfx.new()

	var coord := PuzzleHintCoordinator.new()
	coord.setup(board, overlay, highlight, sfx)
	coord.connect_signals()

	coord.request_hint(session)
	_assert(coord.is_hint_showing(), "hint showing")

	# Calling request_hint again while showing should toggle/dismiss it
	coord.request_hint(session)
	_assert(not coord.is_hint_showing(), "hint dismissed on second request")

	overlay.free()
	highlight.free()
	board.free()

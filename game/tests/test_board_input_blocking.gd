extends SceneTree

const PuzzleScreen = preload("res://scripts/screens/puzzle_screen.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var level := {
		"size": 4,
		"regions": ["AABB", "ABBB", "CCBB", "CCDB"],
		"solution": [1, 3, 0, 2],
		"givens": [],
		"id": "1-1",
	}

	root.size = Vector2i(1080, 1920)
	var packed := load("res://scenes/puzzle.tscn") as PackedScene
	var puzzle := packed.instantiate() as PuzzleScreen
	root.add_child(puzzle)
	puzzle.setup(null, null, null, level, false)
	puzzle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	await process_frame

	# 1. Verify initial layer states
	if puzzle.hint_highlight.visible:
		printerr("FAIL: HintHighlightLayer must not be visible initially")
		quit(1); return
	if puzzle.hint_highlight.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		printerr("FAIL: HintHighlightLayer must have MOUSE_FILTER_IGNORE")
		quit(1); return

	# 2. Click cell (2, 0) via root.push_input
	var cell_rect: Rect2 = puzzle.board.get_cell_rect(2, 0)
	var click_pos := puzzle.board.global_position + cell_rect.get_center()

	var ev_press := InputEventMouseButton.new()
	ev_press.button_index = MOUSE_BUTTON_LEFT
	ev_press.pressed = true
	ev_press.position = click_pos
	ev_press.global_position = click_pos
	root.push_input(ev_press)
	await process_frame

	var ev_release := InputEventMouseButton.new()
	ev_release.button_index = MOUSE_BUTTON_LEFT
	ev_release.pressed = false
	ev_release.position = click_pos
	ev_release.global_position = click_pos
	root.push_input(ev_release)

	puzzle.board.settle_input()
	await process_frame

	if puzzle.session.board[2][0] != CellModel.CellKind.MARK:
		printerr("FAIL: Cell (2, 0) was not marked after click!")
		quit(1); return

	# 3. Touch cell (0, 0) via touch event
	var cell_00_rect: Rect2 = puzzle.board.get_cell_rect(0, 0)
	var touch_pos := puzzle.board.global_position + cell_00_rect.get_center()

	var touch_down := InputEventScreenTouch.new()
	touch_down.pressed = true
	touch_down.position = touch_pos
	root.push_input(touch_down)
	await process_frame

	var touch_up := InputEventScreenTouch.new()
	touch_up.pressed = false
	touch_up.position = touch_pos
	root.push_input(touch_up)

	puzzle.board.settle_input()
	await process_frame

	if puzzle.session.board[0][0] != CellModel.CellKind.MARK:
		printerr("FAIL: Cell (0, 0) was not marked after touch!")
		quit(1); return

	# 4. Request hint -> HintHighlightLayer visible
	puzzle._on_hint()
	await process_frame

	if not puzzle.hint_highlight.visible:
		printerr("FAIL: HintHighlightLayer must be visible when hint is active")
		quit(1); return

	# 5. Tap backdrop outside hint overlay to dismiss hint
	var dismiss_touch := InputEventScreenTouch.new()
	dismiss_touch.pressed = true
	dismiss_touch.position = click_pos
	puzzle.hint_highlight._backdrop.gui_input.emit(dismiss_touch)
	await process_frame

	if puzzle.hint_coordinator.is_hint_showing():
		printerr("FAIL: Hint was not dismissed by backdrop touch")
		quit(1); return
	if puzzle.hint_highlight.visible:
		printerr("FAIL: HintHighlightLayer must be hidden after dismiss")
		quit(1); return

	# 6. Interact with board again after dismiss: unmark cell (2, 0)
	root.push_input(ev_press)
	await process_frame
	root.push_input(ev_release)
	puzzle.board.settle_input()
	await process_frame

	if puzzle.session.board[2][0] != CellModel.CellKind.BLANK:
		printerr("FAIL: Cell (2, 0) was not unmarked after second click!")
		quit(1); return

	puzzle.queue_free()
	print("BOARD_INPUT_BLOCKING_PASS")
	quit(0)

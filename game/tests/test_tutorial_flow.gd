extends SceneTree

const TutorialFlow = preload("res://scripts/campaign/tutorial_flow.gd")
const TutorialTargets = preload("res://scripts/campaign/tutorial_targets.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_board_is_unique()
	_test_full_walkthrough()
	_test_wrong_inputs_are_ignored()
	_test_swipe_marks_only_targets()
	_test_last_step_is_free_play()
	if _fails.is_empty():
		print("TUTORIAL_FLOW_PASS")
		quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _test_board_is_unique() -> void:
	var flow := TutorialFlow.new()
	_assert(TutorialTargets.count_solutions(flow.level, 2) == 1, "onboarding board has exactly one solution")

func _test_full_walkthrough() -> void:
	var flow := TutorialFlow.new()
	var finished := []
	flow.finished.connect(func() -> void: finished.append(true))
	var s := flow.step()
	_assert(s.id == "place" and s.lit == [[0, 1]] and s.gesture == "double", "step 1 lights the single-cell region")
	_assert(flow.double_tap(0, 1), "double tap places the first candy")
	s = flow.step()
	_assert(s.id == "regions" and s.lit.size() == 16 and s.button == "tutorial.ok", "step 2 explains regions with OK")
	flow.press_button()
	s = flow.step()
	_assert(s.id == "rowcol" and s.targets.size() == 6 and s.gesture == "tap", "step 3 asks to cross row 1 and column 2")
	for cell in s.targets.duplicate():
		_assert(flow.tap(cell[0], cell[1]), "tap crosses %s" % str(cell))
	s = flow.step()
	_assert(s.id == "touch" and flow.session.cell_at(3, 2) == CellModel.CellKind.CANDY, "step 4 drops a second candy")
	_assert(s.demo == [[[2, 2], [2, 3], [3, 3]]], "the demo stroke starts on the first cell without an X")
	_assert(s.gesture == "swipe" and s.targets == [[2, 2], [2, 3], [3, 3]], "step 4 targets the open touching cells")
	_assert(flow.stroke([[2, 2], [2, 3], [3, 3]]), "one swipe crosses the touching cells")
	s = flow.step()
	_assert(s.id == "lone" and s.targets == [[1, 3]] and s.lit.size() == 4, "step 5 lights the region with one cell left")
	_assert(flow.double_tap(1, 3), "candy in the last open cell")
	s = flow.step()
	_assert(s.id == "hearts" and s.hearts and s.button == "tutorial.ok" and s.gesture.is_empty(), "step 6 explains hearts with OK only")
	_assert(not flow.tap(2, 0) and not flow.double_tap(2, 0) and not flow.stroke([[2, 0]]), "OK steps take no board input")
	flow.press_button()
	s = flow.step()
	_assert(s.id == "last" and s.hint and s.targets == [[2, 0]], "step 6 asks for the last candy with a hint")
	_assert(flow.double_tap(2, 0), "last candy placed")
	s = flow.step()
	_assert(s.id == "done" and s.button == "tutorial.continue" and s.confetti, "step 7 celebrates")
	_assert(flow.session.phase == flow.session.Phase.WON, "board is solved")
	flow.press_button()
	_assert(finished.size() == 1 and flow.step().is_empty(), "continue finishes once")

func _test_wrong_inputs_are_ignored() -> void:
	var flow := TutorialFlow.new()
	_assert(not flow.double_tap(2, 0), "double tap outside the lit cell is ignored")
	_assert(not flow.tap(0, 1), "single tap on the candy cell is ignored")
	_assert(flow.session.mistake_count == 0 and flow.session.hearts == 3, "tutorial never costs hearts")
	_assert(flow.step().id == "place", "still on step 1")
	flow.double_tap(0, 1)
	_assert(not flow.tap(0, 0), "tapping during the OK step is ignored")
	flow.press_button()
	_assert(not flow.tap(1, 0), "tapping an unlit cell is ignored")
	_assert(not flow.double_tap(0, 0), "double tap on a target to cross is ignored")
	flow.tap(0, 0)
	_assert(not flow.tap(0, 0), "a crossed cell is not un-crossed")

func _test_swipe_marks_only_targets() -> void:
	var flow := TutorialFlow.new()
	flow.double_tap(0, 1)
	flow.press_button()
	_assert(flow.stroke([[0, 0], [1, 0], [2, 0]]), "swipe touching a target counts")
	_assert(flow.session.cell_at(0, 0) == CellModel.CellKind.MARK and flow.session.cell_at(1, 0) == CellModel.CellKind.BLANK, "swipe marks only target cells")

func _reach_last(flow: TutorialFlow) -> void:
	flow.double_tap(0, 1); flow.press_button()
	for cell in flow.step().targets.duplicate(): flow.tap(cell[0], cell[1])
	flow.stroke([[2, 2], [2, 3], [3, 3]]); flow.double_tap(1, 3); flow.press_button()

func _test_last_step_is_free_play() -> void:
	var flow := TutorialFlow.new()
	_reach_last(flow)
	_assert(flow.step().id == "last" and flow.step().free, "last step is free play")
	_assert(flow.tap(1, 0) and flow.session.cell_at(1, 0) == CellModel.CellKind.MARK, "any empty cell can be crossed")
	_assert(flow.tap(1, 0) and flow.session.cell_at(1, 0) == CellModel.CellKind.BLANK, "and un-crossed")
	_assert(flow.stroke([[1, 0], [1, 1]]), "swipe works anywhere")
	var missed := []
	flow.missed.connect(func(r: int, c: int) -> void: missed.append([r, c]))
	_assert(not flow.double_tap(3, 0), "a wrong candy is refused")
	_assert(missed == [[3, 0]] and flow.session.mistake_count == 0 and flow.session.cell_at(3, 0) == CellModel.CellKind.BLANK, "refused softly: no X, no mistake")
	_assert(not flow.tap(0, 1), "candies stay put")
	_assert(flow.double_tap(2, 0) and flow.step().id == "done", "right cell finishes the puzzle")

func _assert(condition: bool, label: String) -> void:
	if not condition: _fails.append("FAIL: " + label)

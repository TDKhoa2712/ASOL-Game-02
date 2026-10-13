extends SceneTree

const TutorialGuide = preload("res://scripts/campaign/tutorial_guide.gd")
const ProgressManager = preload("res://scripts/state/progress_manager.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")

var _fails: Array[String] = []
var _dir_index := 0

func _init() -> void:
	_test_fixed_levels()
	_test_l01_walkthrough()
	_test_out_of_order_candy_skips_steps()
	_test_resume_from_progress()
	_test_protected_cells()
	_test_skip()
	_test_practice_does_not_persist()
	_test_l02_stroke_and_hint()
	_test_l02_skips_drag_after_candy()
	_test_legacy_ids_ignored()
	if _fails.is_empty():
		print("TUTORIAL_GUIDE_PASS")
		quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _progress() -> ProgressManager:
	_dir_index += 1
	var dir := "user://test_tutorial_guide_%d_%d" % [Time.get_ticks_usec(), _dir_index]
	var p := ProgressManager.new(dir)
	p.current = p.new_progress("L01")
	p.save()
	return p

func _session(guide: TutorialGuide, label: String) -> PlaySession:
	return PlaySession.new(guide.level_for(label))

func _test_fixed_levels() -> void:
	var guide := TutorialGuide.new(_progress())
	_assert(guide.has_level("L01") and guide.has_level("L02") and not guide.has_level("L03"), "only L01/L02 are tutorial boards")
	var lvl := guide.level_for("L01")
	_assert(lvl.id == "L01" and int(lvl.size) == 4 and lvl.solution == [1, 3, 0, 2], "L01 level data")
	lvl.solution[0] = 9
	_assert(guide.level_for("L01").solution[0] == 1, "level_for returns a copy")

func _test_l01_walkthrough() -> void:
	var guide := TutorialGuide.new(_progress())
	var s := _session(guide, "L01")
	var step := guide.current_step("L01", s.board)
	_assert(step.id == "L1-0" and step.button == "tutorial.start", "starts at intro card")
	guide.handle("L01", "button", {}, s.board)
	step = guide.current_step("L01", s.board)
	_assert(step.id == "L1-1" and step.args == {"r": 1, "c": 2}, "L1-1 names row 1 col 2 (1-based)")
	_assert(step.axis_rows == [0] and step.axis_cols == [1], "L1-1 lights row/col axis")
	s.try_candy(0, 1)
	guide.handle("L01", "candy", {"cells": [[0, 1]]}, s.board)
	step = guide.current_step("L01", s.board)
	_assert(step.id == "L1-2" and step.overlay.size() == 8 and step.auto_ms == 4000, "L1-2 shows exclusion overlay")
	guide.handle("L01", "timeout", {}, s.board)
	step = guide.current_step("L01", s.board)
	_assert(step.id == "L1-3" and step.args == {"r": 2, "c": 1}, "L1-3 names the diagonal cell")
	guide.handle("L01", "mark", {"cells": [[3, 3]]}, s.board)
	_assert(guide.current_step("L01", s.board).id == "L1-3", "marking another cell does not advance")
	guide.handle("L01", "mark", {"cells": [[1, 0]]}, s.board)
	_assert(guide.current_step("L01", s.board).id == "L1-4", "mark target advances")
	guide.handle("L01", "clear", {"cells": [[1, 0]]}, s.board)
	step = guide.current_step("L01", s.board)
	_assert(step.id == "L1-5" and step.axis_rows.is_empty(), "L1-5 gives no coordinates")
	s.try_candy(1, 3)
	guide.handle("L01", "candy", {"cells": [[1, 3]]}, s.board)
	_assert(guide.current_step("L01", s.board).is_empty(), "L01 script done after region C")

func _test_out_of_order_candy_skips_steps() -> void:
	var guide := TutorialGuide.new(_progress())
	var s := _session(guide, "L01")
	s.try_candy(0, 1)
	s.try_candy(1, 3)
	guide.handle("L01", "candy", {"cells": [[1, 3]]}, s.board)
	_assert(guide.current_step("L01", s.board).is_empty(), "placing C first skips every earlier step")

func _test_resume_from_progress() -> void:
	var p := _progress()
	var guide := TutorialGuide.new(p)
	var s := _session(guide, "L01")
	guide.handle("L01", "button", {}, s.board)
	s.try_candy(0, 1)
	guide.handle("L01", "candy", {"cells": [[0, 1]]}, s.board)
	_assert(p.current.tutorialSeenIds == ["L1-0"], "acknowledged steps persist; board-derived steps need no id")
	var reopened := ProgressManager.new(p._store._dir)
	reopened.load()
	var again := TutorialGuide.new(reopened)
	_assert(again.current_step("L01", s.board).id == "L1-2", "resume continues at first unseen step")

func _test_protected_cells() -> void:
	var guide := TutorialGuide.new(_progress())
	_assert(guide.is_protected("L01", 1, 0), "named diagonal cell is protected")
	_assert(guide.is_protected("L01", 0, 1), "named candy cell is protected")
	_assert(not guide.is_protected("L01", 3, 3), "other cells are not protected")
	_assert(not guide.is_protected("L02", 0, 0), "L02 has no protection")

func _test_skip() -> void:
	var p := _progress()
	var guide := TutorialGuide.new(p)
	var s := _session(guide, "L01")
	guide.skip()
	_assert(guide.current_step("L01", s.board).is_empty(), "skip hides L01 steps")
	_assert(guide.current_step("L02", _session(guide, "L02").board).is_empty(), "skip hides L02 steps")
	_assert(not guide.is_protected("L01", 1, 0), "skip removes protection")
	_assert(p.current.tutorialSeenIds.has("L2-2"), "skip persists every step id")

func _test_practice_does_not_persist() -> void:
	var p := _progress()
	var guide := TutorialGuide.new(p, true)
	var s := _session(guide, "L01")
	_assert(guide.current_step("L01", s.board).id == "L1-0", "practice always starts fresh")
	guide.handle("L01", "button", {}, s.board)
	_assert(guide.current_step("L01", s.board).id == "L1-1", "practice advances in memory")
	_assert(p.current.tutorialSeenIds.is_empty(), "practice writes nothing to progress")

func _test_l02_stroke_and_hint() -> void:
	var guide := TutorialGuide.new(_progress())
	var s := _session(guide, "L02")
	var step := guide.current_step("L02", s.board)
	_assert(step.id == "L2-1" and step.axis_cols == [0] and step.axis_rows.is_empty() and step.args.c == 1, "L2-1 points at column 1")
	guide.handle("L02", "mark", {"cells": [[2, 0]]}, s.board)
	_assert(guide.current_step("L02", s.board).id == "L2-1", "one cell is not a stroke")
	guide.handle("L02", "mark", {"cells": [[2, 0], [3, 0]]}, s.board)
	step = guide.current_step("L02", s.board)
	_assert(step.id == "L2-2" and step.bounce_hint, "L2-2 bounces the hint button")
	guide.handle("L02", "hint_closed", {}, s.board)
	_assert(guide.current_step("L02", s.board).is_empty(), "hint closes the L02 script")

func _test_l02_skips_drag_after_candy() -> void:
	var guide := TutorialGuide.new(_progress())
	var s := _session(guide, "L02")
	s.try_candy(3, 1)
	guide.handle("L02", "candy", {"cells": [[3, 1]]}, s.board)
	_assert(guide.current_step("L02", s.board).id == "L2-2", "a placed candy skips the drag lesson")

func _test_legacy_ids_ignored() -> void:
	var p := _progress()
	p.current.tutorialSeenIds = ["T1", "T2", "T3", "T4", "T5", "T6"]
	var guide := TutorialGuide.new(p)
	_assert(guide.current_step("L01", _session(guide, "L01").board).id == "L1-0", "old T1-T6 ids do not hide the new tutorial")

func _assert(condition: bool, label: String) -> void:
	if not condition: _fails.append("FAIL: " + label)

extends SceneTree

const PlaySession = preload("res://scripts/input/play_session.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const ActionRecorder = preload("res://scripts/input/action_recorder.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_mark_toggle()
	_test_try_candy_correct()
	_test_try_candy_wrong()
	_test_undo_mark()
	_test_undo_candy_removes_auto_marks()
	_test_given_cells_locked()
	_test_cannot_interact_locked()
	_test_auto_marks_on_candy()
	_test_serialize_restore()
	_test_win_condition()
	_test_recorder_grouping()
	if _fails.is_empty():
		print("INPUT_PLAY_SESSION_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_mark_toggle() -> void:
	var session := PlaySession.new(_make_level(), 3)
	session.mark_x(2, 2)
	_assert(session.cell_at(2, 2) == CellModel.CellKind.MARK, "mark placed")
	session.mark_x(2, 2)
	_assert(session.cell_at(2, 2) == CellModel.CellKind.BLANK, "mark removed")

func _test_try_candy_correct() -> void:
	var session := PlaySession.new(_make_level(), 3)
	var found: Array = []
	session.candy_found.connect(func(r, c, region): found.append([r, c, region]))
	session.try_candy(0, 1)  # solution[0]=1
	_assert(found.size() == 1, "candy found emitted")
	_assert(session.cell_at(0, 1) == CellModel.CellKind.CANDY, "candy placed")

func _test_try_candy_wrong() -> void:
	var session := PlaySession.new(_make_level(), 3)
	session.try_candy(0, 0)  # wrong position
	_assert(session.hearts == 2, "lost a heart")
	_assert(session.cell_at(0, 0) == CellModel.CellKind.WRONG, "wrong marked")

func _test_undo_mark() -> void:
	var session := PlaySession.new(_make_level(), 3)
	session.mark_x(2, 2)
	_assert(session.undo(), "undo succeeds")
	_assert(session.cell_at(2, 2) == CellModel.CellKind.BLANK, "undo mark")

func _test_undo_candy_removes_auto_marks() -> void:
	var session := PlaySession.new(_make_level(), 3)
	session.try_candy(0, 1)  # correct candy
	# After candy, some cells should be LOCKED
	var has_locked := false
	for r in 4:
		for c in 4:
			if session.cell_at(r, c) == CellModel.CellKind.LOCKED:
				has_locked = true
				break
	_assert(has_locked, "auto marks exist after candy")
	# Undo should remove candy AND all auto-marks
	session.undo()
	_assert(session.cell_at(0, 1) == CellModel.CellKind.BLANK, "candy undone")
	var still_locked := false
	for r in 4:
		for c in 4:
			if session.cell_at(r, c) == CellModel.CellKind.LOCKED:
				still_locked = true
				break
	_assert(not still_locked, "auto marks cleared after undo")

func _test_given_cells_locked() -> void:
	var level := _make_level()
	level["givens"] = [{"r": 0, "c": 1}]
	var session := PlaySession.new(level, 3)
	_assert(session.cell_at(0, 1) == CellModel.CellKind.GIVEN, "given cell is GIVEN")
	_assert(session.is_preset(0, 1), "given is preset")
	# Cells excluded by given should be LOCKED
	_assert(session.cell_at(0, 0) == CellModel.CellKind.LOCKED, "same row locked by given")

func _test_cannot_interact_locked() -> void:
	var level := _make_level()
	level["givens"] = [{"r": 0, "c": 1}]
	var session := PlaySession.new(level, 3)
	session.mark_x(0, 0)  # should be no-op, cell is LOCKED
	_assert(session.cell_at(0, 0) == CellModel.CellKind.LOCKED, "locked cell not changed")

func _test_auto_marks_on_candy() -> void:
	var session := PlaySession.new(_make_level(), 3)
	var marked: Array = []
	session.auto_marked.connect(func(cells): marked.append_array(cells))
	session.try_candy(0, 1)  # correct
	_assert(marked.size() > 0, "auto_marked signal emitted")

func _test_serialize_restore() -> void:
	var session := PlaySession.new(_make_level(), 3)
	session.try_candy(0, 1)
	session.mark_x(2, 2)
	var data := session.to_save_data()
	var restored := PlaySession.from_save_data(data, _make_level())
	_assert(restored.cell_at(0, 1) == CellModel.CellKind.CANDY, "candy restored")
	_assert(restored.cell_at(2, 2) == CellModel.CellKind.MARK, "mark restored")
	_assert(restored.hearts == 3, "hearts restored")

func _test_win_condition() -> void:
	var level := _make_level()
	var session := PlaySession.new(level, 3)
	var won: Array = []
	session.level_won.connect(func(): won.append(true))
	for row in 4:
		session.try_candy(row, int(level["solution"][row]))
	_assert(won.size() == 1, "level won after all candies")

func _test_recorder_grouping() -> void:
	var rec := ActionRecorder.new()
	var group := [
		{"row": 0, "col": 1, "before": CellModel.CellKind.BLANK, "after": CellModel.CellKind.CANDY, "source": ActionRecorder.Source.USER},
		{"row": 0, "col": 0, "before": CellModel.CellKind.BLANK, "after": CellModel.CellKind.LOCKED, "source": ActionRecorder.Source.SYSTEM},
		{"row": 0, "col": 2, "before": CellModel.CellKind.BLANK, "after": CellModel.CellKind.LOCKED, "source": ActionRecorder.Source.SYSTEM},
	]
	rec.push_group(group)
	_assert(rec.depth() == 1, "one undo group")
	var popped := rec.pop_group()
	_assert(popped.size() == 3, "group has 3 actions")
	_assert(rec.depth() == 0, "stack empty after pop")

func _make_level() -> Dictionary:
	return {
		"size": 4,
		"regions": ["AABB", "ABBB", "CCBB", "CCDB"],
		"solution": [1, 3, 0, 2],
		"givens": []
	}

func _assert(condition: bool, label: String) -> void:
	if not condition:
		_fails.append("FAIL: " + label)

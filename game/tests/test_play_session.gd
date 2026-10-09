extends SceneTree

const PlaySession = preload("res://scripts/input/play_session.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_mark_toggle()
	_test_stroke_undo()
	_test_try_candy_correct()
	_test_try_candy_wrong()
	_test_error_immutable()
	_test_given_without_generated_marks()
	_test_double_tap_immutable()
	_test_legacy_restore()
	_test_serialize_restore()
	_test_win_condition()
	_test_clear_mark()
	_test_clear_mark_ignores_non_mark()
	_test_apply_marks()
	_test_apply_marks_skips_non_blank()
	_test_clear_mark_inactive_phase()
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

func _test_stroke_undo() -> void:
	var session := PlaySession.new(_make_level(), 3)
	session.mark_stroke([[1, 0], [1, 1], [1, 2]], true)
	_assert(session.cell_at(1, 0) == CellModel.CellKind.MARK and session.cell_at(1, 2) == CellModel.CellKind.MARK, "stroke paints cells")
	_assert(session.undo_mark() == true, "undo reports changed board")
	_assert(session.cell_at(1, 0) == CellModel.CellKind.BLANK and session.cell_at(1, 2) == CellModel.CellKind.BLANK, "undo reverses whole stroke")
	session.mark_x(2, 2)
	session.try_candy(0, 1)
	_assert(session.undo_mark() == false, "undo after candy reports no change")
	_assert(session.cell_at(2, 2) == CellModel.CellKind.MARK, "candy action clears undo")

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
	_assert(session.cell_at(0, 0) == CellModel.CellKind.ERROR, "error marked")

func _test_error_immutable() -> void:
	var session := PlaySession.new(_make_level(), 3)
	session.try_candy(0, 0)
	session.mark_x(0, 0)
	session.try_candy(0, 0)
	_assert(session.cell_at(0, 0) == CellModel.CellKind.ERROR, "error stays immutable")
	_assert(session.hearts == 2, "repeat attempt does not cost heart")
	_assert(session.to_save_data()["cells"][0] == "error", "error serialized")

func _test_given_without_generated_marks() -> void:
	var level := _make_level()
	level["givens"] = [{"r": 0, "c": 1}]
	var session := PlaySession.new(level, 3)
	_assert(session.cell_at(0, 1) == CellModel.CellKind.GIVEN, "given cell is GIVEN")
	_assert(session.is_preset(0, 1), "given is preset")
	_assert(session.cell_at(0, 0) == CellModel.CellKind.BLANK, "same row remains blank")

func _test_double_tap_immutable() -> void:
	var session := PlaySession.new(_make_level(), 3)
	session.try_candy(0, 1)
	session.try_candy(0, 1)
	_assert(session.hearts == 3, "repeat candy does not cost heart")
	_assert(session.cell_at(0, 0) == CellModel.CellKind.BLANK, "correct candy does not mark neighbors")

func _test_legacy_restore() -> void:
	var session := PlaySession.new(_make_level(), 3)
	var data := session.to_save_data()
	data["cells"][0] = "wrong"
	data["cells"][1] = "locked"
	var restored := PlaySession.from_save_data(data, _make_level())
	_assert(restored.cell_at(0, 0) == CellModel.CellKind.ERROR, "old mistake restored as error")
	_assert(restored.cell_at(0, 1) == CellModel.CellKind.BLANK, "old lock restored as blank")

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

func _test_clear_mark() -> void:
	var level := _make_level()
	var s := PlaySession.new(level)
	s.mark_x(0, 0)
	_assert(s.cell_at(0, 0) == CellModel.CellKind.MARK, "cell is marked")
	s.clear_mark(0, 0)
	_assert(s.cell_at(0, 0) == CellModel.CellKind.BLANK, "cell cleared to blank")

func _test_clear_mark_ignores_non_mark() -> void:
	var level := _make_level()
	var s := PlaySession.new(level)
	s.clear_mark(0, 0)
	_assert(s.cell_at(0, 0) == CellModel.CellKind.BLANK, "blank stays blank")

func _test_apply_marks() -> void:
	var level := _make_level()
	var s := PlaySession.new(level)
	s.apply_marks([[0, 0], [0, 2], [1, 1]])
	_assert(s.cell_at(0, 0) == CellModel.CellKind.MARK, "0,0 marked")
	_assert(s.cell_at(0, 2) == CellModel.CellKind.MARK, "0,2 marked")
	_assert(s.cell_at(1, 1) == CellModel.CellKind.MARK, "1,1 marked")

func _test_apply_marks_skips_non_blank() -> void:
	var level := _make_level()
	var s := PlaySession.new(level)
	s.mark_x(0, 0)
	s.apply_marks([[0, 0], [0, 2]])
	_assert(s.cell_at(0, 0) == CellModel.CellKind.MARK, "already marked stays")
	_assert(s.cell_at(0, 2) == CellModel.CellKind.MARK, "new cell marked")

func _test_clear_mark_inactive_phase() -> void:
	var level := _make_level()
	var s := PlaySession.new(level)
	s.mark_x(0, 0)
	s.phase = PlaySession.Phase.WON
	s.clear_mark(0, 0)
	_assert(s.cell_at(0, 0) == CellModel.CellKind.MARK, "no clear in WON phase")

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

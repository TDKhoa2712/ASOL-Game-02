extends SceneTree

const PillToggle = preload("res://scripts/screens/pill_toggle.gd")
const PuzzleBoard = preload("res://scripts/screens/puzzle_board.gd")
const TitleScreen = preload("res://scripts/screens/title_screen.gd")
const ResultScreen = preload("res://scripts/screens/result_screen.gd")
const OptionsScreen = preload("res://scripts/screens/options_screen.gd")
const PuzzleScreen = preload("res://scripts/screens/puzzle_screen.gd")
const AppShell = preload("res://scripts/screens/app_shell.gd")

const CellModel = preload("res://scripts/core/cell_model.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const ConfigStore = preload("res://scripts/state/config_store.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const CellAnimator = preload("res://scripts/screens/cell_animator.gd")

class MockRuntime extends RefCounted:
	var label: String = "1-2"
	var completed: int = 1
	var done: bool = false
	var pending: bool = false
	var current_session = null
	var sessions = null

	func current_level_label() -> String:
		return label

	func completed_count() -> int:
		return completed

	func is_campaign_done() -> bool:
		return done

	func has_pending_session() -> bool:
		return pending

	func current_pace() -> Dictionary:
		return {"hintCosts": [1, 2]}

	func restart_level():
		return null

	func playlist_order() -> Array[String]:
		var res: Array[String] = []
		for i in range(1, 31):
			res.append("L%02d" % i)
		return res

var _fails: Array[String] = []

func _init() -> void:
	_test_pill_toggle()
	_test_puzzle_board()
	_test_title_screen()
	_test_result_screen()
	_test_options_screen()
	_test_puzzle_screen()
	_test_scenes_loading()

	if _fails.is_empty():
		print("SCREENS_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _create_sample_level() -> Dictionary:
	return {
		"size": 4,
		"regions": ["AABB", "ABBB", "CCBB", "CCDB"],
		"solution": [1, 3, 0, 2],
		"givens": [{"r": 0, "c": 1}],
		"id": "1-1",
		"hash": "test_sample_hash",
	}

func _test_pill_toggle() -> void:
	var toggle := PillToggle.new()
	toggle.size = Vector2(56, 32)
	_assert(not toggle.is_on(), "pill toggle default is off")
	var signal_box := [false, false]
	toggle.toggled_value.connect(func(v: bool):
		signal_box[0] = true
		signal_box[1] = v
	)
	toggle.set_on(true)
	_assert(toggle.is_on(), "pill toggle is on after set_on(true)")

	toggle._on_toggled(false)
	_assert(not toggle.is_on(), "pill toggle is off after _on_toggled(false)")
	_assert(signal_box[0] and not signal_box[1], "toggled_value emitted false")
	toggle.free()

func _test_puzzle_board() -> void:
	var session := PlaySession.new(_create_sample_level())
	var board := PuzzleBoard.new()
	board.size = Vector2(400, 400)
	board.configure(session)

	_assert(board._zone_grid.size() == 4, "board precomputed 4 rows")
	_assert(board._zone_colors.size() > 0, "board precomputed colors")

	var br := board._board_rect()
	_assert(br.size.x > 0 and br.size.y > 0, "board rect valid")

	var cell := board._cell_at(br.position + Vector2(20, 20))
	_assert(cell == [0, 0], "cell_at maps to [0, 0]")

	board.highlight_cell(1, 2)
	_assert(board._highlight_cells == [[1, 2]], "highlight_cell sets cell")
	_assert(board._highlight_set.has(Vector2i(1, 2)), "highlight_set contains (1, 2)")

	board.highlight_unit("row", 2)
	_assert(board._highlight_cells.size() == 4, "highlight_unit row 2 sets 4 cells")
	_assert(board._highlight_set.size() == 4, "highlight_set has 4 cells")

	board.clear_highlight()
	_assert(board._highlight_cells.is_empty(), "clear_highlight clears cells")
	_assert(board._highlight_set.is_empty(), "clear_highlight clears highlight_set")

	var swipe_box: Array = []
	var stroke_steps: Array = []
	board.cell_swiped.connect(func(cells: Array): swipe_box.append(cells))
	board.cell_stroke_step.connect(func(r: int, c: int, is_mark: bool): stroke_steps.append([r, c, is_mark]))
	board._decoder.begin(2, 0, 0)
	_assert(board._preview_cells.is_empty(), "board touch-down has no X preview")
	_assert(board._preview_set.is_empty(), "board touch-down preview_set is empty")
	board._decoder.move(2, 2)
	_assert(board._preview_cells == [[2, 0], [2, 1], [2, 2]], "board previews drag")
	_assert(board._preview_set.has(Vector2i(2, 0)) and board._preview_set.has(Vector2i(2, 2)), "preview_set tracked")
	_assert(stroke_steps.size() == 3, "stroke steps emitted for each cell during drag")
	_assert(stroke_steps[0] == [2, 0, true] and stroke_steps[2] == [2, 2, true], "stroke step parameters match")
	board._decoder.finish(100)
	_assert(board._preview_cells.is_empty(), "board clears drag preview")
	_assert(board._preview_set.is_empty(), "board clears drag preview_set")
	board.play_mark_anims([[0, 1], [0, 2]])
	_assert(board.has_mark_anim(0, 1) and board.has_mark_anim(0, 2), "play_mark_anims registers multiple cells")
	LayoutTokens.set_motion(false)
	board.play_mark_anim(2, 3)
	_assert(not board.has_mark_anim(2, 3), "reduced motion skips mark anim")
	LayoutTokens.set_motion(true)
	board.draw.connect(func():
		CellAnimator.draw_hand_drawn_x(board, Rect2(0, 0, 50, 50), false, false, 0.0)
		CellAnimator.draw_hand_drawn_x(board, Rect2(0, 0, 50, 50), false, false, 0.4)
		CellAnimator.draw_hand_drawn_x(board, Rect2(0, 0, 50, 50), true, true, 1.0)
	)
	board.notification(CanvasItem.NOTIFICATION_DRAW)

	board.free()

func _test_title_screen() -> void:
	var packed := load("res://scenes/title.tscn") as PackedScene
	var title := packed.instantiate() as TitleScreen
	var mock_rt := MockRuntime.new()
	title.setup(mock_rt)
	_assert(title.runtime != null, "title runtime set")
	_assert(title.find_child("CandyLogo", true, false) != null, "title logo present")
	_assert(title.find_child("SafeArea", true, false) != null, "title safe area present")
	_assert(title.help_btn != null, "home help button present")
	_assert(title.play_btn.text == "Level 1-2", "play button shows only current level")
	_assert(title.campaign_subtitle != null and title.campaign_subtitle.text == "1->30", "campaign subtitle shows 1->30")
	_assert(title.endless_btn != null and title.endless_btn.text == "Level 1", "endless button shows default level 1")
	_assert(title.find_child("LevelLabel", true, false) == null, "progress count is absent from home")
	_assert(title.title_label.get_parent().name == "HeroBlock", "home separates top branding")
	mock_rt.pending = true
	title._update_ui()
	_assert(title.play_btn.text == "Level 1-2", "resume action keeps the same level label")

	var play_box := [false]
	title.play_pressed.connect(func(): play_box[0] = true)
	title._on_play()
	_assert(play_box[0], "title play_pressed emitted")

	var endless_box := [false]
	title.endless_pressed.connect(func(): endless_box[0] = true)
	title._on_endless()
	_assert(endless_box[0], "title endless_pressed emitted")

	var opt_box := [false]
	title.options_pressed.connect(func(): opt_box[0] = true)
	title._on_options()
	_assert(opt_box[0], "title options_pressed emitted")

	title.free()

func _test_result_screen() -> void:
	var win_packed := load("res://scenes/win.tscn") as PackedScene
	var win_screen := win_packed.instantiate() as ResultScreen

	var next_box := [false]
	var replay_box := [false]
	var home_box := [false]

	win_screen.next_pressed.connect(func(): next_box[0] = true)
	win_screen.replay_pressed.connect(func(): replay_box[0] = true)
	win_screen.home_pressed.connect(func(): home_box[0] = true)

	win_screen.setup(true, 12000, "1-1", false)
	_assert(win_screen.find_child("ResultCard", true, false) != null, "win result card present")
	_assert(win_screen.find_child("ResultMessage", true, false) != null, "result shows a supporting message")
	_assert(win_screen._is_win, "result is win")
	_assert(not win_screen._is_last_level, "result not last level")
	_assert(win_screen.next_btn != null and win_screen.next_btn.visible, "next btn visible on win")
	win_screen._on_next()
	_assert(next_box[0], "next_pressed emitted")

	win_screen.setup(true, 50000, "3-10", true)
	_assert(win_screen._is_last_level, "result is last level")
	_assert(win_screen.replay_btn != null and win_screen.replay_btn.visible, "replay btn visible on campaign win")
	win_screen._on_replay()
	_assert(replay_box[0], "replay_pressed emitted")

	win_screen._on_home()
	_assert(home_box[0], "home_pressed emitted")

	win_screen.free()

	var fail_packed := load("res://scenes/fail.tscn") as PackedScene
	var fail_screen := fail_packed.instantiate() as ResultScreen

	var retry_box := [false]
	fail_screen.retry_pressed.connect(func(): retry_box[0] = true)
	fail_screen.setup(false, 0, "1-1", false)
	_assert(fail_screen.find_child("ResultCard", true, false) != null, "fail result card present")
	_assert(not fail_screen._is_win, "result is fail")
	_assert(fail_screen.retry_btn != null and fail_screen.retry_btn.visible, "retry btn visible on fail")
	fail_screen._on_retry()
	_assert(retry_box[0], "retry_pressed emitted")

	fail_screen.free()

func _test_options_screen() -> void:
	var temp_dir := "user://test_screens_options_" + str(Time.get_ticks_msec())
	var config := ConfigStore.new(temp_dir)
	var packed := load("res://scenes/options.tscn") as PackedScene
	var options := packed.instantiate() as OptionsScreen
	options.setup(config)

	_assert(options.vbox != null and options.vbox.get_child_count() == 4 and options.vbox.get_child(0).get_child_count() == 4, "settings grid, two wide rows, and language row generated")
	_assert(options.find_child("OptionsCard", true, false) != null, "settings use a centered card")
	_assert(options.back_btn != null and options.back_btn.custom_minimum_size.x >= 48, "settings close target is touch sized")

	options._on_toggle("audio", false)
	_assert(not bool(config.get_option("audio")), "audio disabled via options screen")

	options._on_toggle("colorblind", true)
	_assert(bool(config.get_option("colorblind")), "colorblind enabled via options screen")
	var back_box := [false]
	options.back_pressed.connect(func(): back_box[0] = true)
	options._on_back()
	_assert(back_box[0], "back_pressed emitted")

	options.free()
	DirAccess.remove_absolute(temp_dir.path_join("config.json"))
	DirAccess.remove_absolute(temp_dir)

func _test_puzzle_screen() -> void:
	var session := PlaySession.new(_create_sample_level())
	var packed := load("res://scenes/puzzle.tscn") as PackedScene
	var puzzle := packed.instantiate() as PuzzleScreen
	puzzle._ensure_nodes()
	_assert(puzzle.undo_btn != null and puzzle.restart_confirm != null, "puzzle controls restored")
	var undo_icon: TextureRect = puzzle.undo_btn.get_node_or_null("IconCenter/Icon")
	_assert(undo_icon != null and undo_icon.custom_minimum_size.x < puzzle.undo_btn.custom_minimum_size.x, "board icon sits inside round button")
	puzzle.session = session
	puzzle._connect_session()
	if puzzle.board != null:
		puzzle.board.configure(session)

	# Cell (2, 0) is available (BLANK)
	_assert(CellModel.is_available(session.board[2][0]), "cell (2, 0) is available")
	puzzle._on_board_tap(2, 0)
	_assert(session.board[2][0] == CellModel.CellKind.MARK, "cell marked via puzzle screen tap")
	puzzle._on_board_tap(2, 0)
	_assert(session.board[2][0] == CellModel.CellKind.BLANK, "cell un-marked via puzzle screen tap")
	session.try_candy(0, 0)
	session.try_candy(1, 3)
	puzzle._on_board_swipe([[2, 0], [1, 3], [0, 0], [2, 1]])
	_assert(session.board[2][0] == CellModel.CellKind.MARK, "swipe paints blank")
	_assert(session.board[2][1] == CellModel.CellKind.MARK, "swipe continues across immutable cells")
	_assert(session.board[0][0] == CellModel.CellKind.ERROR, "swipe skips error")
	_assert(session.board[1][3] == CellModel.CellKind.CANDY, "swipe skips candy")
	puzzle._on_undo()
	_assert(session.board[2][0] == CellModel.CellKind.BLANK and session.board[2][1] == CellModel.CellKind.BLANK, "undo clears whole stroke")
	puzzle.board._decoder.begin(2, 0, 1000)
	puzzle.board._decoder.finish(1010)
	puzzle.board._decoder.begin(2, 0, 1100)
	puzzle.board._decoder.move(2, 1)
	puzzle.board._decoder.finish(1200)
	_assert(session.board[2][0] == CellModel.CellKind.BLANK, "second touch drag clears first mark")

	var won_box := [false, false]
	puzzle.level_done.connect(func(won: bool):
		won_box[0] = true
		won_box[1] = won
	)
	puzzle._on_level_won()
	_assert(won_box[0] and won_box[1], "puzzle screen emitted level_done won")

	var home_box := [false]
	puzzle.go_home.connect(func(): home_box[0] = true)
	puzzle._on_home()
	_assert(home_box[0], "puzzle screen emitted go_home")

	puzzle.free()

func _test_scenes_loading() -> void:
	var scenes := [
		"res://scenes/main.tscn",
		"res://scenes/title.tscn",
		"res://scenes/puzzle.tscn",
		"res://scenes/win.tscn",
		"res://scenes/fail.tscn",
		"res://scenes/options.tscn",
	]
	for sc_path in scenes:
		_assert(ResourceLoader.exists(sc_path), "scene file exists: %s" % sc_path)
		var sc := load(sc_path) as PackedScene
		_assert(sc != null, "scene loaded successfully: %s" % sc_path)
		var inst := sc.instantiate()
		_assert(inst != null, "scene instantiated successfully: %s" % sc_path)
		inst.free()

func _assert(cond: bool, label: String) -> void:
	if not cond:
		_fails.append("FAIL: " + label)

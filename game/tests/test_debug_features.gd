# test_debug_features.gd
extends SceneTree

const DebugLevelPicker = preload("res://scripts/screens/debug_level_picker.gd")
const DebugResetBar = preload("res://scripts/screens/debug_reset_bar.gd")
const PuzzleDebugBar = preload("res://scripts/screens/puzzle_debug_bar.gd")
const BankReader = preload("res://scripts/content/bank_reader.gd")
const PaceReader = preload("res://scripts/content/pace_reader.gd")
const ProgressManager = preload("res://scripts/state/progress_manager.gd")
const SessionStore = preload("res://scripts/state/session_store.gd")
const CampaignRuntime = preload("res://scripts/campaign/campaign_runtime.gd")
const EndlessRuntime = preload("res://scripts/endless/endless_runtime.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const PuzzleBoard = preload("res://scripts/screens/puzzle_board.gd")

var _fails: Array[String] = []

func _init() -> void:
	call_deferred("_run_tests")

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)

func _run_tests() -> void:
	var temp_dir := OS.get_user_data_dir().path_join("test_debug_features_%d" % Time.get_ticks_usec())
	var bank := BankReader.new()
	for s in range(4, 13): bank.load_bank(s)
	var pace := PaceReader.new()
	var pm := ProgressManager.new(temp_dir)
	var ss := SessionStore.new(temp_dir)

	var camp_rt := CampaignRuntime.new(bank, pace, pm, ss)
	camp_rt.playlist_path = "res://data/campaigns/campaign_100.json"
	var boot_res := camp_rt.boot()
	_assert(boot_res.get("ok", false), "Campaign 100 runtime booted successfully")
	_assert(camp_rt.playlist_order().size() == 100, "Campaign 100 has exactly 100 levels")

	var endless_rt := EndlessRuntime.new(bank, pm, ss)

	# 1. Test Debug Level Picker Endless Tab
	var picker := DebugLevelPicker.new()
	root.add_child(picker)
	picker.setup(bank, camp_rt._playlist, endless_rt, camp_rt)

	var selected_box := [{}]
	picker.level_selected.connect(func(lvl: Dictionary, lbl: String):
		selected_box[0] = {"level": lvl, "label": lbl}
	)

	picker._switch_mode(2) # Switch to Endless tab
	picker._endless_panel._spin_level.value = 5
	picker._endless_panel._update_selection()
	picker.confirm_selection()

	_assert(not selected_box[0].is_empty(), "Endless level selected from picker")
	_assert(selected_box[0].get("label") == "Endless 5", "Selected label is Endless 5")
	var endl_lvl: Dictionary = selected_box[0].get("level", {})
	_assert(endl_lvl.has("solution") and endl_lvl.has("regions"), "Endless level has solution and regions")
	_assert(int(endl_lvl.get("_endless_level_num", 0)) == 5, "Endless level num meta preserved")

	# 2. Test Reset Progress Bar
	var reset_bar: DebugResetBar = picker._reset_bar
	_assert(reset_bar != null, "Reset bar exists in debug picker")

	# Modify progresses
	camp_rt.progress.current.completedLevelIds.append("L01")
	camp_rt.progress.current.currentLevelId = "L05"
	camp_rt.progress.save()
	endless_rt.progress.set_level_num(42)
	pm.set_endless_data(endless_rt.progress.to_dict())
	pm.save()

	_assert(camp_rt.progress.current.currentLevelId == "L05", "Campaign progress advanced before reset")
	_assert(endless_rt.progress.get_level_num() == 42, "Endless progress advanced before reset")

	# Reset Endless only
	reset_bar.reset_endless()
	_assert(endless_rt.progress.get_level_num() == 1, "Endless reset back to level 1")
	_assert(camp_rt.progress.current.currentLevelId == "L05", "Campaign preserved when resetting only endless")

	# Reset Campaign only
	reset_bar.reset_campaign()
	_assert(camp_rt.progress.current.currentLevelId == "L01", "Campaign reset back to L01")

	# Advance both and Reset All
	camp_rt.progress.current.currentLevelId = "L10"
	endless_rt.progress.set_level_num(99)
	reset_bar.reset_all()
	_assert(camp_rt.progress.current.currentLevelId == "L01", "Reset all resets campaign to L01")
	_assert(endless_rt.progress.get_level_num() == 1, "Reset all resets endless to 1")

	picker.queue_free()
	await process_frame

	# 3. Test In-Game Cheats (PuzzleDebugBar)
	var sample_level := bank.get_level(4, 1, 0)
	sample_level["id"] = "TestLvl"
	var session := PlaySession.new(sample_level)
	var board := PuzzleBoard.new()
	root.add_child(board)
	board.configure(session)

	var debug_bar := PuzzleDebugBar.new()
	root.add_child(debug_bar)
	debug_bar.setup(null, session, board)

	# 3a. Toggle Show Solution
	_assert(not board.is_showing_solution(), "Initially show solution is false")
	debug_bar._on_solution_pressed()
	_assert(board.is_showing_solution(), "Show solution enabled after pressing solution button")
	debug_bar._on_solution_pressed()
	_assert(not board.is_showing_solution(), "Show solution toggled back to disabled")

	# 3b. Force Win
	var won_emitted := [false]
	session.level_won.connect(func(): won_emitted[0] = true)
	debug_bar._on_win_pressed()
	_assert(won_emitted[0], "Force win emitted level_won")
	_assert(session.phase == PlaySession.Phase.WON, "Session phase is WON")

	# 3c. Force Fail
	session = PlaySession.new(sample_level)
	board.configure(session)
	debug_bar.setup(null, session, board)
	var fail_emitted := [false]
	session.level_failed.connect(func(): fail_emitted[0] = true)
	debug_bar._on_fail_pressed()
	_assert(fail_emitted[0], "Force fail emitted level_failed")
	_assert(session.phase == PlaySession.Phase.FAILED, "Session phase is FAILED")
	_assert(session.hearts == 0, "Hearts are 0 on force fail")

	# 3d. Auto-Solve
	session = PlaySession.new(sample_level)
	board.configure(session)
	debug_bar.setup(null, session, board)
	var auto_won := [false]
	session.level_won.connect(func(): auto_won[0] = true)
	debug_bar._on_solve_pressed()
	_assert(auto_won[0], "Auto-solve emitted level_won")
	_assert(session.phase == PlaySession.Phase.WON, "Auto-solve set phase to WON")

	# Verify candies are placed in all solution cells
	var sol: Array = sample_level.get("solution", [])
	var all_solved := true
	for r in range(session.board.size()):
		var c: int = int(sol[r])
		var kind: int = session.board[r][c]
		if kind != CellModel.CellKind.CANDY and kind != CellModel.CellKind.GIVEN:
			all_solved = false
	_assert(all_solved, "All solution candies placed on board during auto-solve")

	board.queue_free()
	debug_bar.queue_free()
	await process_frame

	# 4. Summary & Exit
	if _fails.is_empty():
		print("DEBUG_FEATURES_PASS")
		quit(0)
	else:
		for f in _fails:
			push_error(f)
			print(f)
		quit(1)

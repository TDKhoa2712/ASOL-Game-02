extends SceneTree

const PuzzleScreenScript = preload("res://scripts/screens/puzzle_screen.gd")

const AppShell = preload("res://scripts/screens/app_shell.gd")
const NavController = preload("res://scripts/campaign/nav_controller.gd")
const CampaignRuntime = preload("res://scripts/campaign/campaign_runtime.gd")
const BankReader = preload("res://scripts/content/bank_reader.gd")
const PaceReader = preload("res://scripts/content/pace_reader.gd")
const ProgressManager = preload("res://scripts/state/progress_manager.gd")
const SessionStore = preload("res://scripts/state/session_store.gd")
const ConfigStore = preload("res://scripts/state/config_store.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const Vibration = preload("res://scripts/feedback/vibration.gd")

var _failures: Array[String] = []
func _initialize() -> void:
	PuzzleScreenScript.hold_results = false # result hold is covered by test_heart_feedback
	call_deferred("_run")
func _run() -> void:
	await _test_app_shell_boot_and_wiring()
	await _test_screen_flow_win_and_progression()
	await _test_screen_flow_fail_and_retry()
	await _test_options_navigation_and_settings()
	await _test_session_autosave_and_reboot_recovery()
	await _test_save_error_dialog()

	if _failures.is_empty():
		print("INTEGRATION_PASS")
		quit(0)
	else:
		for f in _failures:
			printerr(f)
		quit(1)
func _create_test_profile(tag: String) -> String:
	var path := OS.get_user_data_dir().path_join("test_integ_%s_%s" % [tag, Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(path)
	return path
func _clean_dir(path: String) -> void:
	var da := DirAccess.open(path)
	if da != null:
		da.list_dir_begin()
		var file_name := da.get_next()
		while file_name != "":
			if not da.current_is_dir():
				da.remove(file_name)
			file_name = da.get_next()
		da.list_dir_end()
	DirAccess.remove_absolute(path)

func _test_app_shell_boot_and_wiring() -> void:
	var pdir := _create_test_profile("boot")
	var shell: AppShell = load("res://scenes/main.tscn").instantiate()
	shell.profile_dir = pdir
	root.add_child(shell)
	await process_frame

	_assert(shell.config != null, "config store initialized")
	_assert(shell.sfx != null, "sfx player added")
	_assert(shell.bgm != null, "bgm player added")
	var bgm_track: String = str(shell.get_script().get_script_constant_map().get("BGM_TRACK", ""))
	_assert(bgm_track != "" and ResourceLoader.exists(bgm_track), "configured BGM asset exists")
	_assert(shell.bgm.is_playing(), "background music starts on boot")
	await create_timer(0.5).timeout
	var stream = shell.bgm._player.stream
	var has_valid_loop: bool = (stream.loop_end > 0) if (stream is AudioStreamWAV) else bool(stream.get("loop"))
	_assert(shell.bgm.is_playing() and has_valid_loop,
		"background music keeps playing with a valid loop")
	var icon_path: String = str(ProjectSettings.get_setting("application/config/icon", ""))
	_assert(icon_path != "" and ResourceLoader.exists(icon_path), "project icon asset exists")
	_assert(shell.runtime != null, "campaign runtime initialized")
	_assert(shell.nav != null, "nav controller initialized")
	_assert(shell.nav.current() == NavController.Screen.TITLE, "starts on title screen")
	_assert(shell.screen_host != null, "screen host exists")
	_assert(shell.screen_host.get_child_count() == 1, "has one active screen")

	var title_screen = shell.screen_host.get_child(0)
	_assert(title_screen != null and title_screen.name == "TitleScreen", "current screen is TitleScreen")

	root.remove_child(shell)
	shell.free()
	_clean_dir(pdir)

func _test_screen_flow_win_and_progression() -> void:
	var pdir := _create_test_profile("progression")
	var shell: AppShell = load("res://scenes/main.tscn").instantiate()
	shell.profile_dir = pdir
	root.add_child(shell)
	await process_frame

	# Use a 2-entry playlist so completing L02 finishes the campaign
	var second: Dictionary = shell.runtime._playlist[0].duplicate(true)
	second.label = "L02"
	shell.runtime._playlist = [shell.runtime._playlist[0], second]

	# 1. From Title, trigger play
	var title_screen = shell.screen_host.get_child(0)
	title_screen._on_play()

	_assert(shell.nav.current() == NavController.Screen.PUZZLE, "nav moved to puzzle screen")
	_assert(shell.runtime.current_session != null, "active session started")

	var first_label := shell.runtime.current_level_label()
	_assert(first_label == "L01", "starts at level L01")

	# 2. Complete L01 properly by placing candy at correct positions
	var session: PlaySession = shell.runtime.current_session
	var level: Dictionary = session.level
	var solution: Array = level["solution"]
	for r in range(solution.size()):
		var c: int = int(solution[r])
		if session.cell_at(r, c) != CellModel.CellKind.GIVEN:
			session.try_candy(r, c)

	_assert(session.phase == PlaySession.Phase.WON, "session phase is WON")
	_assert(shell.nav.current() == NavController.Screen.WIN, "nav moved to WIN screen")

	var win_screen = shell.screen_host.get_child(0)
	_assert(win_screen != null and win_screen.name == "WinScreen", "screen host holds WinScreen")
	_assert(shell._last_won_level == "L01", "recorded won level is L01")
	_assert(win_screen.message_label != null and (win_screen.message_label.text.containsn(tr("result.win.title")) or win_screen.ribbon.text == tr("result.win.title")), "win screen message shown")
	_assert(win_screen.next_btn != null and win_screen.next_btn.visible, "next button visible")

	# 3. Press Next on WinScreen to advance to L02
	win_screen._on_next()
	_assert(shell.nav.current() == NavController.Screen.PUZZLE, "nav moved to puzzle screen for next level")
	_assert(shell.runtime.current_level_label() == "L02", "next level is L02")
	_assert(shell.runtime.current_session != null, "new session started for L02")

	# 4. Complete L02 to finish campaign
	var session2: PlaySession = shell.runtime.current_session
	var level2: Dictionary = session2.level
	var sol2: Array = level2["solution"]
	for r in range(sol2.size()):
		var c: int = int(sol2[r])
		if session2.cell_at(r, c) != CellModel.CellKind.GIVEN:
			session2.try_candy(r, c)

	_assert(session2.phase == PlaySession.Phase.WON, "session2 phase is WON")
	_assert(shell.nav.current() == NavController.Screen.WIN, "nav moved to WIN screen for campaign complete")

	var final_win = shell.screen_host.get_child(0)
	_assert(final_win.message_label != null and (final_win.message_label.text.containsn(tr("result.win.title_campaign")) or final_win.ribbon.text == tr("result.win.title_campaign")), "campaign complete message shown")
	_assert(final_win.replay_btn != null and final_win.replay_btn.visible, "replay button visible on campaign complete")

	# 5. Replay campaign resets to L01
	final_win._on_replay()
	_assert(shell.nav.current() == NavController.Screen.PUZZLE, "returned to PUZZLE after replay")
	_assert(shell.runtime.current_level_label() == "L01", "reset back to L01 on replay")

	root.remove_child(shell)
	shell.free()
	_clean_dir(pdir)

func _test_screen_flow_fail_and_retry() -> void:
	var pdir := _create_test_profile("fail_retry")
	var shell: AppShell = load("res://scenes/main.tscn").instantiate()
	shell.profile_dir = pdir
	root.add_child(shell)
	await process_frame

	# Title -> Puzzle
	var title = shell.screen_host.get_child(0)
	title._on_play()

	var session: PlaySession = shell.runtime.current_session
	var level: Dictionary = session.level
	var solution: Array = level["solution"]

	# Make 3 mistakes on 3 distinct rows to fail level
	for r in range(3):
		var wrong_col: int = (int(solution[r]) + 1) % int(level["size"])
		session.try_candy(r, wrong_col)

	_assert(session.phase == PlaySession.Phase.FAILED, "session is FAILED")
	_assert(session.hearts == 0, "0 hearts remaining")
	_assert(shell.nav.current() == NavController.Screen.PUZZLE, "final heart remains visible while falling")
	var saved := shell.runtime.sessions.load_session(session.level.id, session.level.hash)
	_assert(saved.ok and saved.data.status == "failed", "failure saved before final fall finishes")
	await create_timer(1.0).timeout
	_assert(shell.nav.current() == NavController.Screen.FAIL, "nav moved to FAIL screen")

	var fail_screen = shell.screen_host.get_child(0)
	_assert(fail_screen != null and fail_screen.name == "FailScreen", "screen host holds FailScreen")

	# Retry level
	fail_screen._on_retry()
	_assert(shell.nav.current() == NavController.Screen.PUZZLE, "nav returned to PUZZLE screen")

	var retry_session = shell.runtime.current_session
	_assert(retry_session != null, "retry session initialized")
	_assert(retry_session.phase == PlaySession.Phase.ACTIVE, "retry session is active")
	_assert(retry_session.hearts == 3, "retry session has 3 fresh hearts")

	root.remove_child(shell)
	shell.free()
	_clean_dir(pdir)

func _test_options_navigation_and_settings() -> void:
	var pdir := _create_test_profile("options")
	var shell: AppShell = load("res://scenes/main.tscn").instantiate()
	shell.profile_dir = pdir
	root.add_child(shell)
	await process_frame

	# 1. From Title, open Options overlay
	var title = shell.screen_host.get_child(0)
	title._on_options()
	_assert(shell._options_overlay != null, "options overlay shown")
	_assert(shell.nav.current() == NavController.Screen.TITLE, "nav stays on title when options overlay opens")

	var options = shell._options_overlay
	_assert(options != null, "options overlay active")

	# Toggle audio off
	options._on_toggle("audio", false)
	_assert(shell.sfx.is_muted(), "sfx player muted when audio is off")
	_assert(not shell.bgm.is_muted(), "bgm keeps playing when only sound is off")
	options._on_toggle("music", false)
	_assert(shell.bgm.is_muted(), "bgm player muted when music is off")

	# Toggle haptic off
	options._on_toggle("haptic", false)
	_assert(not Vibration.is_on(), "vibration disabled when haptic is off")

	# Back from Options overlay
	options._on_back()
	await process_frame
	_assert(shell._options_overlay == null, "options overlay dismissed")
	_assert(shell.nav.current() == NavController.Screen.TITLE, "still on title after options dismissed")

	# 2. From Title to Puzzle, then open Options overlay, then dismiss
	title = shell.screen_host.get_child(0)
	title._on_play()
	_assert(shell.nav.current() == NavController.Screen.PUZZLE, "now on puzzle screen")

	shell._show_options_overlay()
	_assert(shell._options_overlay != null, "options overlay shown from puzzle")

	shell._hide_options_overlay()
	await process_frame
	_assert(shell._options_overlay == null, "options overlay dismissed from puzzle")
	_assert(shell.nav.current() == NavController.Screen.PUZZLE, "still on puzzle after options dismissed")

	root.remove_child(shell)
	shell.free()
	_clean_dir(pdir)

func _test_session_autosave_and_reboot_recovery() -> void:
	var pdir := _create_test_profile("autosave")

	# Run 1: Start game, tap an empty cell to mark X, verify auto-save
	var shell1: AppShell = load("res://scenes/main.tscn").instantiate()
	shell1.profile_dir = pdir
	root.add_child(shell1)
	await process_frame

	var title = shell1.screen_host.get_child(0)
	title._on_play()

	var puzzle = shell1.screen_host.get_child(0)
	var session = shell1.runtime.current_session
	var level = session.level
	var sol = level["solution"]

	# Find a cell that is not given or solution candy
	var mark_r := 0
	var mark_c := (int(sol[0]) + 1) % int(level["size"])
	puzzle._on_board_tap(mark_r, mark_c)

	_assert(session.cell_at(mark_r, mark_c) == CellModel.CellKind.MARK, "cell marked with X")
	_assert(shell1.runtime.has_pending_session(), "session was auto-saved to disk")

	# Simulate quitting app and restarting
	root.remove_child(shell1)
	shell1.free()

	# Run 2: Boot app again with same profile
	var shell2: AppShell = load("res://scenes/main.tscn").instantiate()
	shell2.profile_dir = pdir
	root.add_child(shell2)
	await process_frame

	_assert(shell2.runtime.has_pending_session(), "pending session detected on reboot")
	var title2 = shell2.screen_host.get_child(0)
	_assert(title2.play_btn.text == "Level %s" % shell2.runtime.current_level_label().trim_prefix("L"), "title button displays only the resumed level")

	title2._on_play()
	var puzzle2 = shell2.screen_host.get_child(0)
	var restored_session = shell2.runtime.current_session

	_assert(restored_session != null, "restored session active")
	_assert(restored_session.cell_at(mark_r, mark_c) == CellModel.CellKind.MARK, "marked X restored from save file")

	root.remove_child(shell2)
	shell2.free()
	_clean_dir(pdir)

func _test_save_error_dialog() -> void:
	var pdir := _create_test_profile("dialog")
	var shell: AppShell = load("res://scenes/main.tscn").instantiate()
	shell.profile_dir = pdir
	root.add_child(shell)
	await process_frame

	_assert(shell.save_error_dialog != null, "save error dialog exists")
	_assert(not shell.save_error_dialog.visible, "save error dialog initially hidden")

	shell.runtime.save_failed.emit("disk_full")
	_assert(shell.save_error_dialog.dialog_text.contains("disk_full"), "save error dialog updated with error reason")

	root.remove_child(shell)
	shell.free()
	_clean_dir(pdir)

func _assert(cond: bool, label: String) -> void:
	if not cond:
		_failures.append("FAIL: " + label)

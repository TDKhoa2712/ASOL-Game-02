extends SceneTree

const CampaignRuntime = preload("res://scripts/campaign/campaign_runtime.gd")
const BankCursor = preload("res://scripts/campaign/bank_cursor.gd")
const NavController = preload("res://scripts/campaign/nav_controller.gd")
const TutorialGuide = preload("res://scripts/campaign/tutorial_guide.gd")
const BankReader = preload("res://scripts/content/bank_reader.gd")
const PaceReader = preload("res://scripts/content/pace_reader.gd")
const ProgressManager = preload("res://scripts/state/progress_manager.gd")
const SessionStore = preload("res://scripts/state/session_store.gd")

var failures: Array[String] = []

func _init() -> void:
	_test_boot_and_resume()
	_test_unsolved_win_refused()
	_test_win_and_save_retry()
	_test_completion_and_replay()
	_test_transform_resolution()
	_test_loss_and_restart()
	_test_cursor()
	_test_navigation()
	_test_tutorial()
	_test_snapshot_creation()
	_test_restart_reuses_snapshot()
	_test_dda_integration()
	for failure in failures:
		printerr(failure)
	if failures.is_empty():
		print("CAMPAIGN_RUNTIME_PASS")
	quit(0 if failures.is_empty() else 1)

func _runtime(tag: String) -> CampaignRuntime:
	var dir := OS.get_user_data_dir().path_join("test_campaign_%s_%s" % [tag, Time.get_ticks_usec()])
	var runtime := CampaignRuntime.new(BankReader.new(), PaceReader.new(), ProgressManager.new(dir), SessionStore.new(dir))
	return runtime

func _two_entries(runtime: CampaignRuntime) -> void:
	var second: Dictionary = runtime._playlist[0].duplicate(true)
	second.label = "L02"
	runtime._playlist.append(second)

func _test_boot_and_resume() -> void:
	var runtime := _runtime("boot")
	var result := runtime.boot()
	_check(result.ok, "boot loads current content: " + str(result))
	_check(runtime.current_level_label() == "L01", "starts at L01")
	_check(runtime.playlist_order().size() == 30 and runtime.playlist_order()[0] == "L01", "reads current playlist")
	_check(not runtime.current_level_data().is_empty(), "resolves level")
	_check(runtime.current_pace().has("hintCosts"), "resolves pace")
	var session := runtime.start_level("L01")
	_check(session != null and runtime.has_pending_session(), "start persists session")
	var again := CampaignRuntime.new(runtime.bank, runtime.pace, runtime.progress, runtime.sessions)
	_check(again.boot().ok, "reboot succeeds")
	_check(again.resume_level() != null, "reboot restores session")
	_cleanup(runtime)

func _test_win_and_save_retry() -> void:
	var runtime := _runtime("win")
	_check(runtime.boot().ok, "win boot")
	_two_entries(runtime)
	_finish_level(runtime)
	var wins: Array = []
	runtime.level_won.connect(func(label, next_label): wins.append([label, next_label]))
	runtime.on_level_won("L01", {"score": 400})
	_check(runtime.current_level_label() == "L02", "win advances")
	_check(wins == [["L01", "L02"]], "win signal")
	_check(not runtime.has_pending_session(), "win clears session")
	_cleanup(runtime)

	var retry := _runtime("retry")
	_check(retry.boot().ok, "retry boot")
	_two_entries(retry)
	_finish_level(retry)
	var blocker := retry.progress._store._slot_file("b") + ".tmp"
	DirAccess.make_dir_absolute(blocker)
	var errors: Array = []
	retry.save_failed.connect(func(reason): errors.append(reason))
	retry.on_level_won("L01", {"score": 400})
	_check(not errors.is_empty(), "failed save signaled")
	_check(retry.current_level_label() == "L01", "failed save keeps progress")
	_check(retry.has_pending_session(), "failed save keeps session")
	DirAccess.remove_absolute(blocker)
	var rebooted := CampaignRuntime.new(BankReader.new(), PaceReader.new(), ProgressManager.new(retry.progress._store._dir), SessionStore.new(retry.progress._store._dir))
	_check(rebooted.boot().ok, "reboot after failed win")
	_two_entries(rebooted)
	_check(rebooted.retry_save(), "save retries after reboot")
	_check(rebooted.current_level_label() == "L02", "reboot retry advances")
	_check(rebooted.progress.current.get("results", {}).get("L01", {}).get("score") == 400, "retry keeps score data")
	_cleanup(retry)
	_cleanup(rebooted)

func _test_unsolved_win_refused() -> void:
	var runtime := _runtime("unsolved")
	_check(runtime.boot().ok, "unsolved boot")
	runtime.on_level_won("L01", {"score": 900})
	_check(not runtime.is_campaign_done(), "cannot win directly after boot")
	runtime.start_level("L01")
	runtime.on_level_won("L01", {"score": 900})
	_check(not runtime.is_campaign_done(), "cannot win active unsolved session")
	_cleanup(runtime)

func _test_loss_and_restart() -> void:
	var runtime := _runtime("loss")
	_check(runtime.boot().ok, "loss boot")
	runtime.start_level("L01")
	runtime.on_level_lost("L01")
	_check(runtime.has_pending_session(), "loss keeps session")
	_check(runtime.restart_level() != null, "restart creates session")
	_check(runtime.current_session.phase == 0, "restart active")
	_cleanup(runtime)

func _test_completion_and_replay() -> void:
	var runtime := _runtime("complete")
	_check(runtime.boot().ok, "complete boot")
	runtime.replay_campaign()
	_check(not runtime.is_campaign_done(), "early replay refused")
	var completions: Array = []
	runtime.campaign_complete.connect(func(): completions.append(true))
	runtime._playlist = [runtime._playlist[0]]
	_finish_level(runtime)
	runtime.on_level_won("L01", {"score": 800})
	_check(runtime.is_campaign_done(), "last level completes campaign")
	_check(runtime.completed_count() == 1 and completions.size() == 1, "completion recorded and signaled")
	_check(runtime.start_level("L01") == null, "completed level cannot start")
	runtime.replay_campaign()
	_check(not runtime.is_campaign_done(), "replay resets completion")
	_check(runtime.current_level_label() == "L01", "replay starts first level")
	_cleanup(runtime)

func _test_transform_resolution() -> void:
	var runtime := _runtime("transform")
	_check(runtime.boot().ok, "transform boot")
	var original := runtime.current_level_data()
	runtime._playlist[0].transform = 1
	var rotated := runtime.current_level_data()
	_check(rotated.solution != original.solution, "transform changes solution")
	_check(rotated.hash != original.hash, "transform changes puzzle fingerprint")
	_cleanup(runtime)

func _test_cursor() -> void:
	var cursor := BankCursor.new(4, 1, 5)
	for i in 5:
		cursor.advance()
	_check(cursor.current().index == 0 and cursor.current().transform == 1, "cursor wraps index")
	_check(cursor.effective_plays() == 40, "cursor play count")
	cursor.set_position(3, 7)
	var restored := BankCursor.from_dict(cursor.to_dict(), 5)
	_check(restored.current() == cursor.current(), "cursor serializes")
	var single := BankCursor.new(4, 1, 1)
	for i in 8:
		single.advance()
	_check(single.current().transform == 0, "transforms wrap")

func _test_navigation() -> void:
	var nav := NavController.new()
	var changes: Array = []
	nav.screen_changed.connect(func(before, after): changes.append([before, after]))
	_check(not nav.go_to(NavController.Screen.WIN), "invalid route refused")
	_check(nav.go_to(NavController.Screen.PUZZLE), "title to puzzle")
	_check(changes == [["title", "puzzle"]], "navigation signal")

func _test_tutorial() -> void:
	var runtime := _runtime("tutorial")
	_check(runtime.boot().ok, "tutorial boot")
	var guide := TutorialGuide.new(runtime.progress)
	_check(guide.is_tutorial("L01"), "L01 tutorial")
	var milestones: Array = []
	guide.milestone_reached.connect(func(id): milestones.append(id))
	guide.check_trigger("first_board")
	_check(milestones == ["T1"], "first trigger emits once")
	guide.check_trigger("first_board")
	_check(milestones.size() == 1, "seen trigger idempotent")
	_check(guide.seen_ids().has("T1"), "seen persists in progress")
	_cleanup(runtime)

func _test_snapshot_creation() -> void:
	var runtime := _runtime("snapshot")
	_check(runtime.boot().ok, "snapshot boot")
	var session := runtime.start_level("L01")
	_check(session != null, "snapshot start level")
	var saved := runtime.sessions._store.read_json()
	_check(saved.ok, "snapshot session saved")
	_check(saved.data.has("snapshot"), "session has snapshot field")
	var snap: Dictionary = saved.data.get("snapshot", {})
	_check(snap.has("regions"), "snapshot has regions")
	_check(snap.has("solution"), "snapshot has solution")
	_check(snap.has("zone_colors"), "snapshot has zone_colors")
	_check(snap.has("shape_hash"), "snapshot has shape_hash")
	_check(str(snap.get("shape_hash", "")).begins_with("4x4_"), "shape_hash format")
	_cleanup(runtime)

func _test_restart_reuses_snapshot() -> void:
	var runtime := _runtime("restart_snap")
	_check(runtime.boot().ok, "restart_snap boot")
	var s1 := runtime.start_level("L01")
	_check(s1 != null, "restart_snap first start")
	var snap1: Dictionary = runtime.sessions._store.read_json().data.get("snapshot", {})
	var s2 := runtime.restart_level()
	_check(s2 != null, "restart_snap restart")
	var snap2: Dictionary = runtime.sessions._store.read_json().data.get("snapshot", {})
	_check(snap2.get("regions", []) == snap1.get("regions", []), "restart same regions")
	_check(snap2.get("zone_colors", {}) == snap1.get("zone_colors", {}), "restart same colors")
	_check(snap2.get("solution", []) == snap1.get("solution", []), "restart same solution")
	var again := CampaignRuntime.new(runtime.bank, runtime.pace, runtime.progress, runtime.sessions)
	_check(again.boot().ok and again._current_snapshot.get("shape_hash") == snap1.get("shape_hash"), "resume restores snapshot")
	_cleanup(runtime)

func _cleanup(runtime: CampaignRuntime) -> void:
	runtime.progress._store.remove_all()
	runtime.sessions.clear()

func _finish_level(runtime: CampaignRuntime) -> void:
	var session := runtime.start_level("L01")
	if session == null:
		failures.append("FAIL: could not start level to finish")
		return
	for row in session.level.size:
		session.try_candy(row, int(session.level.solution[row]))
	_check(session.phase == session.Phase.WON, "sample level solved")

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append("FAIL: " + label)

func _test_dda_integration() -> void:
	var runtime := _runtime("dda")
	_check(runtime.boot().ok, "dda boot")
	_check(runtime.pace_adjuster != null, "pace_adjuster initialized")
	_check(runtime.pace_adjuster.rank_offset(1, 1) == 0, "initial offset 0")
	var label: String = runtime.current_level_label()
	runtime.start_level(label)
	runtime.on_level_lost(label)
	_check(int(runtime.progress.current.get("dda", {}).get("fail_streak", 0)) == 1, "loss persisted to dda")
	_cleanup(runtime)

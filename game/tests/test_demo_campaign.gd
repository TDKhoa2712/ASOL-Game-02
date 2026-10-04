extends SceneTree

const CampaignRuntime = preload("res://scripts/campaign/campaign_runtime.gd")
const BankReader = preload("res://scripts/content/bank_reader.gd")
const PaceReader = preload("res://scripts/content/pace_reader.gd")
const ProgressManager = preload("res://scripts/state/progress_manager.gd")
const SessionStore = preload("res://scripts/state/session_store.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")

var failures: Array[String] = []

func _init() -> void:
	_test_default_demo_playthrough()
	_test_existing_4x4_session_survives_playlist_change()
	for failure in failures:
		printerr(failure)
	if failures.is_empty():
		print("DEMO_CAMPAIGN_PASS")
	quit(0 if failures.is_empty() else 1)

func _test_default_demo_playthrough() -> void:
	var dir := OS.get_user_data_dir().path_join("test_demo_%s" % Time.get_ticks_usec())
	var runtime := _runtime(dir)
	var boot := runtime.boot()
	_check(boot.ok, "default demo boots: " + str(boot))
	if not boot.ok:
		_cleanup(runtime)
		return
	var expected_sizes := [
		4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
		5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
		6, 6, 6, 6, 6, 6, 6, 6, 6, 6
		]
	var completions: Array = []
	runtime.campaign_complete.connect(func(): completions.append(true))
	for index in expected_sizes.size():
		var label := "L%02d" % (index + 1)
		_check(runtime.current_level_label() == label, "sequential progress reaches " + label)
		_check(not runtime.is_campaign_done(), "demo still playable at " + label)
		var session := runtime.start_level(label)
		if session == null:
			_check(false, "can start " + label)
			break
		_check(session.level.size == expected_sizes[index], "%s uses %dx%d" % [label, expected_sizes[index], expected_sizes[index]])
		_check(not runtime.current_pace().get("hintCosts", []).is_empty(), label + " resolves matching pace")
		if label in ["L01", "L11", "L21"]:
			var mark_col := (int(session.level.solution[0]) + 1) % int(session.level.size)
			session.mark_x(0, mark_col)
			var saved := session.to_save_data()
			saved["snapshot"] = runtime._current_snapshot.duplicate(true)
			_check(runtime.sessions.save_session(saved), label + " saves board")
			var reopened := _runtime(dir)
			_check(reopened.boot().ok, label + " reboots")
			_check(reopened.current_session != null, label + " resumes pending board")
			if reopened.current_session != null:
				_check(reopened.current_session.level.size == expected_sizes[index], label + " resumes same size")
				_check(reopened.current_session.cell_at(0, mark_col) == CellModel.CellKind.MARK, label + " restores X")
				_check(reopened.current_pace() == runtime.current_pace(), label + " restores matching pace")
		_check(runtime.start_level("L30" if label != "L30" else "L01") == null, label + " cannot skip or replay another level")
		for row in session.level.size:
			session.try_candy(row, int(session.level.solution[row]))
		_check(session.phase == session.Phase.WON, label + " solves")
		runtime.on_level_won(label, {"time_ms": 1000, "mistakes": 0})
		_check(runtime.completed_count() == index + 1, label + " records completion")
	_check(runtime.is_campaign_done(), "demo completes after L30")
	_check(completions.size() == 1, "completion emitted once after L30")
	_check(runtime.next_level_label("L30").is_empty(), "no L31 in demo")
	_check(runtime.start_level("L30") == null, "finished demo cannot restart last level directly")
	var finished := _runtime(dir)
	_check(finished.boot().ok and finished.is_campaign_done(), "completed demo survives reboot")
	_cleanup(runtime)

func _test_existing_4x4_session_survives_playlist_change() -> void:
	var dir := OS.get_user_data_dir().path_join("test_demo_legacy_%s" % Time.get_ticks_usec())
	var legacy := _runtime(dir)
	_check(legacy.boot().ok, "legacy profile boots")
	# Recreate L16 from the previous 30-level, all-4x4 demo.
	legacy._playlist[15] = {"label": "L16", "size": 4, "rank": 2, "index": 3, "difficulty": "medium"}
	legacy.progress.current.currentLevelId = "L16"
	legacy.progress.current.completedLevelIds = legacy.playlist_order().slice(0, 15)
	_check(legacy.progress.save(), "legacy progress saved")
	var session := legacy.start_level("L16")
	_check(session != null, "legacy L16 starts")
	if session == null:
		_cleanup(legacy)
		return
	var legacy_pace := legacy.current_pace()
	var legacy_hash: String = session.level.hash
	var reopened := _runtime(dir)
	_check(reopened.boot().ok, "updated demo loads existing profile")
	_check(reopened.completed_count() == 15, "update preserves completed levels")
	_check(reopened.current_session != null, "update restores active session")
	if reopened.current_session != null:
		_check(reopened.current_session.level.size == 4, "active legacy board stays 4x4")
		_check(reopened.current_session.level.hash == legacy_hash, "active legacy puzzle stays pinned")
		_check(reopened.current_pace() == legacy_pace, "active legacy board keeps its original pace")
		var restarted := reopened.restart_level()
		_check(restarted != null and restarted.level.size == 4, "restart keeps legacy board")
		if restarted != null:
			for row in restarted.level.size:
				restarted.try_candy(row, int(restarted.level.solution[row]))
			reopened.on_level_won("L16", {"time_ms": 1000, "mistakes": 0})
			var next := reopened.start_level("L17")
			_check(next != null and next.level.size == 5, "next level uses updated 5x5 group")
	_cleanup(legacy)

func _runtime(dir: String) -> CampaignRuntime:
	return CampaignRuntime.new(BankReader.new(), PaceReader.new(), ProgressManager.new(dir), SessionStore.new(dir))

func _cleanup(runtime: CampaignRuntime) -> void:
	runtime.progress._store.remove_all()
	runtime.sessions.clear()

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append("FAIL: " + label)

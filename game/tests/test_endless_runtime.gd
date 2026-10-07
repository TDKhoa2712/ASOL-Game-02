extends SceneTree

const EndlessRuntime = preload("res://scripts/endless/endless_runtime.gd")
const BankReader = preload("res://scripts/content/bank_reader.gd")
const ProgressManager = preload("res://scripts/state/progress_manager.gd")
const SessionStore = preload("res://scripts/state/session_store.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_start_level()
	_test_win_and_advance()
	_test_loss_and_streak_reset()
	_test_restart_level()
	if _fails.is_empty():
		print("ENDLESS_RUNTIME_PASS")
		quit(0)
	else:
		print("FAILURES COUNT: ", _fails.size())
		for f in _fails:
			print("FAIL: ", f)
		quit(1)

func _setup_runtime() -> Dictionary:
	var temp_dir := OS.get_user_data_dir().path_join("test_endless_rt_%s" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(temp_dir)
	var bank = BankReader.new()
	var pm = ProgressManager.new(temp_dir)
	pm.current = pm.new_progress("L01")
	var ss = SessionStore.new(temp_dir)
	var rt = EndlessRuntime.new(bank, pm, ss)
	return {"rt": rt, "pm": pm, "ss": ss, "dir": temp_dir}

func _cleanup(dir: String) -> void:
	var da := DirAccess.open(dir)
	if da != null:
		da.list_dir_begin()
		var f := da.get_next()
		while f != "":
			if not da.current_is_dir():
				da.remove(f)
			f = da.get_next()
		da.list_dir_end()
	DirAccess.remove_absolute(dir)

func _test_start_level() -> void:
	var ctx := _setup_runtime()
	var rt: EndlessRuntime = ctx.rt
	_assert(rt.current_level_label() == "Endless 1", "initial level label Endless 1")

	var session := rt.start_level()
	_assert(session != null, "session created")
	_assert(rt.current_session == session, "current_session set")
	_assert(not rt.current_level_data().is_empty(), "level data populated")
	_assert(session.phase == PlaySession.Phase.ACTIVE, "session phase is ACTIVE")
	_assert(session.level.get("id") == "Endless 1", "level id is Endless 1")

	_cleanup(ctx.dir)

func _test_win_and_advance() -> void:
	var ctx := _setup_runtime()
	var rt: EndlessRuntime = ctx.rt
	var pm: ProgressManager = ctx.pm
	var session := rt.start_level()

	# Simulate win
	var sol: Array = session.level.get("solution", [])
	for r in range(sol.size()):
		var c: int = int(sol[r])
		if session.cell_at(r, c) != 4: # CellModel.CellKind.GIVEN
			session.try_candy(r, c)

	_assert(session.phase == PlaySession.Phase.WON, "session phase is WON")

	var won_signal: Array = []
	rt.level_won.connect(func(lbl: String, nxt: String): won_signal.append([lbl, nxt]))

	rt.on_level_won("Endless 1", {"time_ms": 15000, "hints_used": 0, "mistakes": 0})

	_assert(won_signal.size() == 1, "level_won emitted")
	_assert(won_signal[0][0] == "Endless 1", "won Endless 1")
	_assert(won_signal[0][1] == "Endless 2", "next is Endless 2")
	_assert(rt.progress.get_level_num() == 2, "progress advanced to 2")
	_assert(rt.progress.current_streak == 1, "streak incremented to 1")

	# Verify progress saved to PM
	var saved_dict := pm.get_endless_data()
	_assert(saved_dict.get("level_num") == 2, "persisted level_num is 2")
	_assert(saved_dict.get("current_streak") == 1, "persisted streak is 1")

	_cleanup(ctx.dir)

func _test_loss_and_streak_reset() -> void:
	var ctx := _setup_runtime()
	var rt: EndlessRuntime = ctx.rt
	var session := rt.start_level()

	# Force streak
	rt.progress.current_streak = 3

	# Simulate fail
	var sol: Array = session.level.get("solution", [])
	var sz: int = int(session.level.get("size", 4))
	for r in range(3):
		var wrong_c: int = (int(sol[r]) + 1) % sz
		session.try_candy(r, wrong_c)

	var lost_signal: Array = []
	rt.level_lost.connect(func(lbl: String): lost_signal.append(lbl))

	rt.on_level_lost("Endless 1")
	_assert(lost_signal.size() == 1, "level_lost emitted")
	_assert(lost_signal[0] == "Endless 1", "lost Endless 1")
	_assert(rt.progress.current_streak == 0, "streak reset to 0")

	_cleanup(ctx.dir)

func _test_restart_level() -> void:
	var ctx := _setup_runtime()
	var rt: EndlessRuntime = ctx.rt
	var session1 := rt.start_level()
	var lvl_data1 := rt.current_level_data().duplicate(true)

	var session2 := rt.restart_level()
	_assert(session2 != null, "restarted session created")
	_assert(session2 != session1, "new session instance")
	_assert(rt.current_level_data().get("regions") == lvl_data1.get("regions"), "same puzzle kept")

	_cleanup(ctx.dir)

func _assert(cond: bool, msg: String) -> void:
	if not cond:
		_fails.append(msg)

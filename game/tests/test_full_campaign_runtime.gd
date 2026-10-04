extends SceneTree

const CampaignRuntime = preload("res://scripts/campaign/campaign_runtime.gd")
const BankReader = preload("res://scripts/content/bank_reader.gd")
const PaceReader = preload("res://scripts/content/pace_reader.gd")
const ProgressManager = preload("res://scripts/state/progress_manager.gd")
const SessionStore = preload("res://scripts/state/session_store.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var folder := OS.get_user_data_dir().path_join("test_full_runtime_%s" % Time.get_ticks_usec())
	var runtime := CampaignRuntime.new(BankReader.new(), PaceReader.new(),
		ProgressManager.new(folder), SessionStore.new(folder))
	runtime.playlist_path = "res://data/campaigns/full_998.json"
	var boot := runtime.boot()
	_assert(boot.ok, "full campaign boots")
	if boot.ok:
		_assert(runtime.playlist_order().size() == 998, "all entries load")
		var promote := _find_entry(runtime, 4, 4, 0)
		var base_five := _find_entry(runtime, 4, 5, 0)
		var fallback := _find_entry(runtime, 6, 4, 158)
		_assert(not promote.is_empty() and not base_five.is_empty() and not fallback.is_empty(), "rank fixtures present")
		if not promote.is_empty() and not fallback.is_empty() and not base_five.is_empty():
			runtime.pace_adjuster.from_dict({"clean_streak": 2, "fail_streak": 0, "retry_streak": 0})
			runtime.progress.current.currentLevelId = promote.label
			_assert(runtime._dda_adjusted_rank(promote) == 5, "rank 4 promotes to 5")
			_assert(runtime.current_level_data().regions == runtime.bank.get_level(4, 5, 0).regions, "promoted rank-5 puzzle loads")
			runtime.progress.current.currentLevelId = base_five.label
			_assert(runtime._dda_adjusted_rank(base_five) == 5, "base rank 5 stays in range")
			_assert(not runtime.current_pace().is_empty(), "rank-5 pace loads")
			runtime.progress.current.currentLevelId = fallback.label
			_assert(runtime._dda_adjusted_rank(fallback) == 4, "missing promoted index falls back")
			_assert(runtime.current_level_data().regions == runtime.bank.get_level(6, 4, 158).regions, "fallback puzzle remains base rank")
	if _failures.is_empty():
		print("FULL_CAMPAIGN_RUNTIME_PASS")
		quit(0)
	else:
		for failure in _failures:
			printerr(failure)
		quit(1)

func _find_entry(runtime: CampaignRuntime, size: int, rank: int, index: int) -> Dictionary:
	for entry in runtime._playlist:
		if entry.size == size and entry.rank == rank and entry.index == index:
			return entry
	return {}

func _assert(condition: bool, label: String) -> void:
	if not condition:
		_failures.append("FAIL: " + label)

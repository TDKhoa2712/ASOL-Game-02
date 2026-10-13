extends SceneTree

const CampaignRuntime = preload("res://scripts/campaign/campaign_runtime.gd")
const BankReader = preload("res://scripts/content/bank_reader.gd")
const PaceReader = preload("res://scripts/content/pace_reader.gd")
const ProgressManager = preload("res://scripts/state/progress_manager.gd")
const SessionStore = preload("res://scripts/state/session_store.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")

var _fails: Array[String] = []

func _init() -> void:
	var dir := "user://test_tutorial_campaign_%d" % Time.get_ticks_usec()
	var runtime := CampaignRuntime.new(BankReader.new(), PaceReader.new(), ProgressManager.new(dir), SessionStore.new(dir))
	var boot := runtime.boot()
	_assert(boot.ok, "boot: " + str(boot.get("error", "")))
	_assert(runtime.tutorial != null, "runtime owns a tutorial guide built on its progress")
	var lvl: Dictionary = runtime.current_level_data()
	_assert(lvl.get("regions") == runtime.tutorial.level_for("L01").regions and lvl.get("id") == "L01", "L01 uses the hand-authored board")
	var session: PlaySession = runtime.start_level()
	_assert(session != null and session.level.regions == ["ABCC", "AACC", "AADD", "DDDD"], "started session plays the tutorial board")
	_assert(session.protect_fn.is_valid() and session.protect_fn.call(1, 0), "campaign session forgives the named tutorial cell")
	var resumed := CampaignRuntime.new(BankReader.new(), PaceReader.new(), ProgressManager.new(dir), SessionStore.new(dir))
	resumed.boot()
	_assert(resumed.current_session != null and resumed.current_session.protect_fn.is_valid(), "resumed session keeps protection")
	if _fails.is_empty():
		print("TUTORIAL_CAMPAIGN_PASS")
		quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _assert(condition: bool, label: String) -> void:
	if not condition: _fails.append("FAIL: " + label)

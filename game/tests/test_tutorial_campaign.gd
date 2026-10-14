extends SceneTree

const CampaignRuntime = preload("res://scripts/campaign/campaign_runtime.gd")
const BankReader = preload("res://scripts/content/bank_reader.gd")
const PaceReader = preload("res://scripts/content/pace_reader.gd")
const ProgressManager = preload("res://scripts/state/progress_manager.gd")
const SessionStore = preload("res://scripts/state/session_store.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const TutorialScreen = preload("res://scripts/screens/tutorial_screen.gd")

var _fails: Array[String] = []

func _init() -> void:
	var dir := "user://test_tutorial_campaign_%d" % Time.get_ticks_usec()
	var runtime := CampaignRuntime.new(BankReader.new(), PaceReader.new(), ProgressManager.new(dir), SessionStore.new(dir))
	var boot := runtime.boot()
	_assert(boot.ok, "boot: " + str(boot.get("error", "")))
	_assert(runtime.tutorial != null and not runtime.tutorial.has_seen(TutorialScreen.DONE_ID), "fresh profile still owes the onboarding")
	var session: PlaySession = runtime.start_level()
	_assert(session != null and not session.protect_fn.is_valid(), "L01 is a normal bank level with normal penalties")
	_assert(session.level.regions != ["ABCC", "AACC", "AADD", "DDDD"], "L01 no longer uses the old in-level tutorial board")
	runtime.tutorial.mark_seen(TutorialScreen.DONE_ID)
	var reopened := CampaignRuntime.new(BankReader.new(), PaceReader.new(), ProgressManager.new(dir), SessionStore.new(dir))
	reopened.boot()
	_assert(reopened.tutorial.has_seen(TutorialScreen.DONE_ID), "finished onboarding survives a restart")
	if _fails.is_empty():
		print("TUTORIAL_CAMPAIGN_PASS")
		quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _assert(condition: bool, label: String) -> void:
	if not condition: _fails.append("FAIL: " + label)

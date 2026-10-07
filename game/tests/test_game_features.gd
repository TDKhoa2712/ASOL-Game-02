extends SceneTree

const GameFeatures = preload("res://scripts/core/game_features.gd")
const TitleScreen = preload("res://scripts/screens/title_screen.gd")

class MockRuntime extends RefCounted:
	var label: String = "L01"
	func current_level_label() -> String:
		return label
	func is_campaign_done() -> bool:
		return false
	func playlist_order() -> Array[String]:
		return ["L01", "L02"]

var _fails: Array[String] = []

func _init() -> void:
	_test_default_features()
	_test_feature_overrides()
	_test_safety_fallback()
	_test_title_screen_both_modes()
	_test_title_screen_campaign_only()
	_test_title_screen_endless_only()
	_test_app_shell_initial_mode()

	GameFeatures.reset_overrides()

	if _fails.is_empty():
		print("GAME_FEATURES_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_default_features() -> void:
	GameFeatures.reset_overrides()
	var expected_c := GameFeatures.ENABLE_CAMPAIGN
	var expected_e := GameFeatures.ENABLE_ENDLESS
	if not expected_c and not expected_e:
		expected_c = true # safety fallback
	_assert(GameFeatures.is_campaign_enabled() == expected_c, "default campaign matches constant or fallback")
	_assert(GameFeatures.is_endless_enabled() == expected_e, "default endless matches constant")

func _test_feature_overrides() -> void:
	GameFeatures.set_campaign_enabled(true)
	GameFeatures.set_endless_enabled(false)
	_assert(GameFeatures.is_campaign_enabled(), "campaign override true")
	_assert(not GameFeatures.is_endless_enabled(), "endless override false")

	GameFeatures.set_campaign_enabled(false)
	GameFeatures.set_endless_enabled(true)
	_assert(not GameFeatures.is_campaign_enabled(), "campaign override false")
	_assert(GameFeatures.is_endless_enabled(), "endless override true")

func _test_safety_fallback() -> void:
	GameFeatures.set_campaign_enabled(false)
	GameFeatures.set_endless_enabled(false)
	# Safety fallback: cannot have 0 modes enabled
	_assert(GameFeatures.is_campaign_enabled(), "fallback enables campaign if both false")

func _test_title_screen_both_modes() -> void:
	GameFeatures.set_campaign_enabled(true)
	GameFeatures.set_endless_enabled(true)
	var packed := load("res://scenes/title.tscn") as PackedScene
	var title := packed.instantiate() as TitleScreen
	var mock_rt := MockRuntime.new()
	title.setup(mock_rt)

	var campaign_box := title.find_child("CampaignBox", true, false) as Control
	var endless_btn := title.find_child("EndlessButton", true, false) as Control
	_assert(campaign_box != null and campaign_box.visible, "both modes: campaign box visible")
	_assert(endless_btn != null and endless_btn.visible, "both modes: endless button visible")
	title.free()

func _test_title_screen_campaign_only() -> void:
	GameFeatures.set_campaign_enabled(true)
	GameFeatures.set_endless_enabled(false)
	var packed := load("res://scenes/title.tscn") as PackedScene
	var title := packed.instantiate() as TitleScreen
	var mock_rt := MockRuntime.new()
	title.setup(mock_rt)

	var campaign_box := title.find_child("CampaignBox", true, false) as Control
	var endless_btn := title.find_child("EndlessButton", true, false) as Control
	_assert(campaign_box != null and campaign_box.visible, "campaign only: campaign box visible")
	_assert(endless_btn != null and not endless_btn.visible, "campaign only: endless button hidden")
	title.free()

func _test_title_screen_endless_only() -> void:
	GameFeatures.set_campaign_enabled(false)
	GameFeatures.set_endless_enabled(true)
	var packed := load("res://scenes/title.tscn") as PackedScene
	var title := packed.instantiate() as TitleScreen
	var mock_rt := MockRuntime.new()
	title.setup(mock_rt)

	var campaign_box := title.find_child("CampaignBox", true, false) as Control
	var endless_btn := title.find_child("EndlessButton", true, false) as Control
	_assert(campaign_box != null and not campaign_box.visible, "endless only: campaign box hidden")
	_assert(endless_btn != null and endless_btn.visible, "endless only: endless button visible")
	title.free()

func _test_app_shell_initial_mode() -> void:
	GameFeatures.set_campaign_enabled(true)
	GameFeatures.set_endless_enabled(false)
	var shell = load("res://scenes/main.tscn").instantiate()
	shell._ready()
	_assert(shell._mode == "campaign", "shell mode is campaign when only campaign enabled")
	shell.free()

	GameFeatures.set_campaign_enabled(false)
	GameFeatures.set_endless_enabled(true)
	var shell_endless = load("res://scenes/main.tscn").instantiate()
	shell_endless._ready()
	_assert(shell_endless._mode == "endless", "shell mode is endless when only endless enabled")
	shell_endless.free()

func _assert(cond: bool, label: String) -> void:
	if not cond:
		_fails.append("FAIL: " + label)

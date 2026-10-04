extends SceneTree

const CampaignSelector = preload("res://scripts/campaign/campaign_selector.gd")
const AppShell = preload("res://scripts/screens/app_shell.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var folder := OS.get_user_data_dir().path_join("selector_test_%s" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(folder)
	var selector_path := folder.path_join("active_campaign.json")
	var profile := folder.path_join("profile")
	_write_selector(selector_path, "demo_30")
	var demo := CampaignSelector.load_config(selector_path, profile)
	_assert(demo.ok and demo.playlist_path.ends_with("demo_30.json"), "demo selector path")
	_assert(demo.progress_dir == profile, "demo keeps original save directory")
	_write_selector(selector_path, "full_998")
	var full := CampaignSelector.load_config(selector_path, profile)
	_assert(full.ok and full.playlist_path.ends_with("full_998.json"), "full selector path")
	_assert(full.progress_dir == profile.path_join("full_998"), "full save directory isolated")
	_write_selector(selector_path, "unknown")
	_assert(not CampaignSelector.load_config(selector_path, profile).ok, "unknown mode rejected")
	_write_selector(selector_path, "full_998")
	_assert(not CampaignSelector.load_config(selector_path, profile, folder).ok, "missing playlist rejected")
	var file := FileAccess.open(selector_path, FileAccess.WRITE)
	file.store_string("invalid json")
	file.close()
	_assert(not CampaignSelector.load_config(selector_path, profile).ok, "invalid JSON rejected")
	DirAccess.remove_absolute(selector_path)
	_assert(not CampaignSelector.load_config(selector_path, profile).ok, "missing selector rejected")
	await _test_visible_boot_error(selector_path, profile)
	await _test_mode_switch(selector_path, profile)
	await _test_hint_win_does_not_promote(selector_path, profile.path_join("hint_case"))
	if _failures.is_empty():
		print("CAMPAIGN_SELECTOR_PASS")
		quit(0)
	else:
		for failure in _failures:
			printerr(failure)
		quit(1)

func _test_mode_switch(selector_path: String, profile: String) -> void:
	_write_selector(selector_path, "demo_30")
	var demo_shell: AppShell = load("res://scenes/main.tscn").instantiate()
	demo_shell.profile_dir = profile
	demo_shell.selector_path = selector_path
	root.add_child(demo_shell)
	await process_frame
	_assert(demo_shell.runtime != null and demo_shell.runtime.playlist_order().size() == 30, "demo boots with 30 entries")
	var demo_session = demo_shell.runtime.start_level("L01")
	_assert(demo_session != null and demo_shell.runtime.has_pending_session(), "demo active round saved")
	demo_shell.config.set_option("audio", false)
	root.remove_child(demo_shell)
	demo_shell.free()
	_write_selector(selector_path, "full_998")
	var full_shell: AppShell = load("res://scenes/main.tscn").instantiate()
	full_shell.profile_dir = profile
	full_shell.selector_path = selector_path
	root.add_child(full_shell)
	await process_frame
	_assert(full_shell.runtime != null and full_shell.runtime.playlist_order().size() == 998, "full boots with 998 entries")
	_assert(not full_shell.runtime.has_pending_session(), "full mode does not load demo round")
	_assert(full_shell.config.get_option("audio") == false, "settings shared across modes")
	var full_session = full_shell.runtime.start_level("L01")
	_assert(full_session != null and full_shell.runtime.has_pending_session(), "full active round saved")
	root.remove_child(full_shell)
	full_shell.free()
	_write_selector(selector_path, "demo_30")
	var resumed_shell: AppShell = load("res://scenes/main.tscn").instantiate()
	resumed_shell.profile_dir = profile
	resumed_shell.selector_path = selector_path
	root.add_child(resumed_shell)
	await process_frame
	_assert(resumed_shell.runtime.has_pending_session(), "demo round survives mode switch")
	_assert(resumed_shell.runtime.current_session != null, "demo active round resumes")
	root.remove_child(resumed_shell)
	resumed_shell.free()
	_write_selector(selector_path, "full_998")
	var full_resume: AppShell = load("res://scenes/main.tscn").instantiate()
	full_resume.profile_dir = profile
	full_resume.selector_path = selector_path
	root.add_child(full_resume)
	await process_frame
	_assert(full_resume.runtime.has_pending_session(), "full round survives mode switch")
	_assert(full_resume.runtime.current_session != null, "full active round resumes")
	root.remove_child(full_resume)
	full_resume.free()

func _test_visible_boot_error(selector_path: String, profile: String) -> void:
	Engine.print_error_messages = false
	var shell: AppShell = load("res://scenes/main.tscn").instantiate()
	shell.profile_dir = profile
	shell.selector_path = selector_path
	root.add_child(shell)
	await process_frame
	_assert(shell.runtime == null, "invalid selector stops boot")
	_assert(shell.save_error_dialog != null and shell.save_error_dialog.visible, "boot error dialog visible")
	_assert(shell.save_error_dialog.dialog_text.contains("campaign selector missing"), "boot error explains selector")
	root.remove_child(shell)
	shell.free()
	Engine.print_error_messages = true

func _test_hint_win_does_not_promote(selector_path: String, profile: String) -> void:
	_write_selector(selector_path, "demo_30")
	var shell: AppShell = load("res://scenes/main.tscn").instantiate()
	shell.profile_dir = profile
	shell.selector_path = selector_path
	root.add_child(shell)
	await process_frame
	var session = shell.runtime.start_level("L01")
	session.use_hint()
	for row in range(session.level.solution.size()):
		session.try_candy(row, int(session.level.solution[row]))
	shell._on_level_done(true)
	_assert(int(shell.runtime.progress.current.get("dda", {}).get("clean_streak", -1)) == 0,
		"hint-assisted win does not count as clean DDA win")
	root.remove_child(shell)
	shell.free()

func _write_selector(path: String, mode: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"campaign": mode}))
	file.close()

func _assert(condition: bool, label: String) -> void:
	if not condition:
		_failures.append("FAIL: " + label)

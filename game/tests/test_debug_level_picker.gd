extends SceneTree

const DebugLevelPicker = preload("res://scripts/screens/debug_level_picker.gd")
const BankReader = preload("res://scripts/content/bank_reader.gd")

var _fails: Array[String] = []

func _init() -> void:
	call_deferred("_run_tests")

func _assert(cond: bool, msg: String) -> void:
	if not cond:
		_fails.append("FAIL: " + msg)

func _run_tests() -> void:
	var bank := BankReader.new()
	bank.load_bank(4)
	bank.load_bank(5)
	bank.load_bank(6)

	var picker := DebugLevelPicker.new()
	root.add_child(picker)

	# Test 1: Dynamic bank discovery
	var discovered_sizes: Array[int] = DebugLevelPicker.discover_banks("res://data/banks/")
	_assert(discovered_sizes.has(4) and discovered_sizes.has(5) and discovered_sizes.has(6), "Discovered sizes contain 4, 5, 6")
	_assert(discovered_sizes.size() >= 3, "At least 3 bank sizes discovered")

	# Test 2: Dynamic campaign discovery
	var discovered_campaigns: Dictionary = DebugLevelPicker.discover_campaigns("res://data/campaigns/")
	_assert(discovered_campaigns.has("demo_30") or discovered_campaigns.has("demo-30"), "Discovered demo_30 campaign")
	_assert(discovered_campaigns.has("full_998") or discovered_campaigns.has("full-998"), "Discovered full_998 campaign")

	# Test 3: Setup with sample playlist
	var sample_playlist: Array = [
		{"label": "L01", "size": 4, "rank": 1, "index": 0, "difficulty": "tutorial"},
		{"label": "L05", "size": 4, "rank": 2, "index": 0, "difficulty": "easy"},
		{"label": "L11", "size": 5, "rank": 1, "index": 0, "difficulty": "medium"},
		{"label": "L21", "size": 6, "rank": 1, "index": 0, "difficulty": "hard"},
	]
	picker.setup(bank, sample_playlist)

	# Test 4: Dynamic extraction of sizes and difficulties from playlist
	var playlist_sizes: Array[int] = picker.get_playlist_sizes()
	_assert(playlist_sizes == [4, 5, 6], "Playlist sizes match [4, 5, 6]: %s" % str(playlist_sizes))
	var playlist_diffs: Array[String] = picker.get_playlist_difficulties()
	_assert(playlist_diffs.has("tutorial") and playlist_diffs.has("easy") and playlist_diffs.has("medium") and playlist_diffs.has("hard"), "Playlist difficulties extracted dynamically")

	# Test 5: Selecting a playlist level emits level_selected signal with valid data
	var selected_box := [{}]
	picker.level_selected.connect(func(lvl: Dictionary, label: String):
		selected_box[0] = {"level": lvl, "label": label}
	)

	picker.select_playlist_entry("L11")
	picker.confirm_selection()
	_assert(not selected_box[0].is_empty(), "level_selected signal emitted")
	_assert(selected_box[0].get("label") == "L11", "Label is L11")
	var lvl_data: Dictionary = selected_box[0].get("level", {})
	_assert(int(lvl_data.get("size", 0)) == 5, "Level size is 5")
	_assert(lvl_data.has("regions") and lvl_data.has("solution"), "Level has regions and solution")

	# Test 6: Custom bank selection for any size/rank/index
	selected_box[0] = {}
	picker.select_custom_bank_level(6, 1, 0, 0)
	picker.confirm_selection()
	_assert(not selected_box[0].is_empty(), "Custom bank level emitted")
	var custom_lvl: Dictionary = selected_box[0].get("level", {})
	_assert(int(custom_lvl.get("size", 0)) == 6, "Custom level size is 6")
	_assert(custom_lvl.has("regions") and custom_lvl["regions"].size() == 6, "Custom level has 6 regions")

	picker.queue_free()
	await process_frame

	# Test 7: TitleScreen contains debug button and picker in debug mode
	var title_packed := load("res://scenes/title.tscn") as PackedScene
	var title_scene = title_packed.instantiate()
	root.add_child(title_scene)
	title_scene._ensure_nodes()
	if OS.is_debug_build():
		_assert(title_scene.debug_btn != null, "TitleScreen has debug_btn in debug build")
		_assert(title_scene.debug_picker != null, "TitleScreen has debug_picker in debug build")
		title_scene._on_debug_pressed()
		_assert(title_scene.debug_picker.visible, "debug_picker toggles to visible")
		title_scene._on_debug_pressed()
		_assert(not title_scene.debug_picker.visible, "debug_picker toggles back to hidden")
	title_scene.queue_free()
	await process_frame

	# Test 8: AppShell isolated debug session preserves main campaign progress
	var app_shell_packed := load("res://scenes/main.tscn") as PackedScene
	var app_shell = app_shell_packed.instantiate()
	# Isolate the test from an actual player save, which can be failed.
	app_shell.profile_dir = OS.get_user_data_dir().path_join("test_debug_picker_%d" % Time.get_ticks_usec())
	root.add_child(app_shell)
	await process_frame
	await process_frame

	var initial_main_level: String = str(app_shell.runtime.current_level_label())
	# Select a different level in debug mode (e.g. L02)
	var sample_lvl := bank.get_level(4, 1, 1)
	sample_lvl["id"] = "L02"
	app_shell._on_debug_level_selected(sample_lvl, "L02")
	await process_frame
	await process_frame

	_assert(app_shell._debug_mode, "Debug mode is active in AppShell")
	_assert(app_shell.runtime.current_level_label() == initial_main_level, "Main campaign level label preserved (not overwritten)")
	var puzzle_inst = app_shell.screen_host.get_child(0)
	_assert(puzzle_inst != null and puzzle_inst.session != null, "Puzzle screen instantiated with active session")
	_assert(puzzle_inst.session.level.get("id") == "L02", "Puzzle screen loaded selected debug level L02")

	# Test 9: Completing debug level advances to next default level without corrupting campaign progress
	_assert(app_shell._debug_next_lbl == "L03", "Next level for L02 is L03")
	app_shell._on_next_level()
	await process_frame
	await process_frame
	var puzzle_inst_2 = app_shell.screen_host.get_child(0)
	_assert(puzzle_inst_2 != null and puzzle_inst_2.session.level.get("id") == "L03", "Advanced to next default level L03")
	_assert(app_shell.runtime.current_level_label() == initial_main_level, "Main campaign level label still preserved after next level")

	# Exit debug to home
	app_shell._on_puzzle_home()
	await process_frame
	_assert(not app_shell._debug_mode, "Debug mode exited on return to home")
	_assert(app_shell.runtime.current_level_label() == initial_main_level, "Main level untouched upon returning home")

	# Test 10: Normal play mode enters successfully after debug mode
	app_shell._on_title_play()
	await process_frame
	await process_frame
	var normal_puzzle = app_shell.screen_host.get_child(0)
	_assert(normal_puzzle != null and normal_puzzle.session != null, "Normal puzzle screen instantiated with active session after debug mode")
	_assert(normal_puzzle.session != null and normal_puzzle.session.level.get("id") == initial_main_level, "Normal puzzle loaded correct campaign level %s" % initial_main_level)
	_assert(not app_shell._debug_mode, "AppShell is not in debug mode during normal play")

	app_shell.queue_free()
	await process_frame

	if _fails.is_empty():
		print("DEBUG_LEVEL_PICKER_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

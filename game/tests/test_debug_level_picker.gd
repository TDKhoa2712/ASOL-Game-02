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

	if _fails.is_empty():
		print("DEBUG_LEVEL_PICKER_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

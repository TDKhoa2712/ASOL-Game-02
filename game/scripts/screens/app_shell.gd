# app_shell.gd
extends Control

const CampaignRuntime = preload("res://scripts/campaign/campaign_runtime.gd")
const CampaignSelector = preload("res://scripts/campaign/campaign_selector.gd")
const BankReader = preload("res://scripts/content/bank_reader.gd")
const PaceReader = preload("res://scripts/content/pace_reader.gd")
const ProgressManager = preload("res://scripts/state/progress_manager.gd")
const SessionStore = preload("res://scripts/state/session_store.gd")
const ConfigStore = preload("res://scripts/state/config_store.gd")
const NavController = preload("res://scripts/campaign/nav_controller.gd")
const SfxPlayer = preload("res://scripts/feedback/sfx_player.gd")
const BgmPlayer = preload("res://scripts/feedback/bgm_player.gd")
const Vibration = preload("res://scripts/feedback/vibration.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

const SCENE_MAP := {
	"title": "res://scenes/title.tscn",
	"puzzle": "res://scenes/puzzle.tscn",
	"win": "res://scenes/win.tscn",
	"fail": "res://scenes/fail.tscn",
	"options": "res://scenes/options.tscn",
}

var runtime: CampaignRuntime
var config: ConfigStore
var nav: NavController
var sfx: SfxPlayer
var bgm: BgmPlayer
var profile_dir: String = "user://profile"
var selector_path: String = "res://data/campaigns/active_campaign.json"
var _previous_screen_name: String = "title"
var _last_won_level: String = ""
var _last_won_elapsed: int = 0
var _last_won_is_last: bool = false

@onready var screen_host: Control = get_node_or_null("ScreenHost")
@onready var save_error_dialog: AcceptDialog = get_node_or_null("SaveErrorDialog")

func _ready() -> void:
	var selection := CampaignSelector.load_config(selector_path, profile_dir)
	if not selection.ok:
		_on_boot_error(str(selection.error))
		return
	if config == null:
		config = ConfigStore.new(profile_dir)
		config.option_changed.connect(_apply_setting)

	if sfx == null:
		sfx = SfxPlayer.new()
		sfx.name = "SfxPlayer"
		add_child(sfx)
	if bgm == null:
		bgm = BgmPlayer.new()
		bgm.name = "BgmPlayer"
		add_child(bgm)
	_apply_all_settings()

	if runtime == null:
		var bank := BankReader.new()
		var pace := PaceReader.new()
		var progress := ProgressManager.new(selection.progress_dir)
		var sessions := SessionStore.new(selection.progress_dir)
		runtime = CampaignRuntime.new(bank, pace, progress, sessions)
		runtime.playlist_path = selection.playlist_path

	if not runtime.save_failed.is_connected(_on_save_failed):
		runtime.save_failed.connect(_on_save_failed)

	if runtime.playlist_order().is_empty():
		var boot_res := runtime.boot()
		if not boot_res.get("ok", false):
			_on_boot_error(str(boot_res.get("error", "Boot failed")))
			return

	if nav == null:
		nav = NavController.new()
		nav.screen_changed.connect(_swap_screen)

	var bgm_path := "res://audio/bgm/main_theme.ogg"
	if ResourceLoader.exists(bgm_path):
		bgm.play_track(bgm_path)

	if screen_host == null:
		screen_host = Control.new()
		screen_host.name = "ScreenHost"
		screen_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(screen_host)

	_swap_screen("", nav.current_name())

func _swap_screen(from_name: String, to_name: String) -> void:
	if from_name != "":
		_previous_screen_name = from_name
	if screen_host != null:
		for child in screen_host.get_children():
			child.queue_free()
			screen_host.remove_child(child)
	_instantiate_screen(to_name)

func _instantiate_screen(to_name: String) -> void:
	var scene_path: String = SCENE_MAP.get(to_name, "")
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return
	var screen := packed.instantiate() as Control
	if screen == null:
		return
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	match to_name:
		"title":
			if screen.has_signal("play_pressed"):
				screen.connect("play_pressed", _on_title_play)
			if screen.has_signal("options_pressed"):
				screen.connect("options_pressed", func(): nav.go_to(NavController.Screen.OPTIONS))
			if screen.has_method("setup"):
				screen.call("setup", runtime)
		"puzzle":
			if screen.has_signal("go_home"):
				screen.connect("go_home", func(): nav.go_to(NavController.Screen.TITLE))
			if screen.has_signal("options_pressed"):
				screen.connect("options_pressed", func(): nav.go_to(NavController.Screen.OPTIONS))
			if screen.has_signal("level_done"):
				screen.connect("level_done", _on_level_done)
			if screen.has_method("setup"):
				screen.call("setup", runtime, sfx, config)
		"win":
			if screen.has_signal("next_pressed"):
				screen.connect("next_pressed", _on_next_level)
			if screen.has_signal("home_pressed"):
				screen.connect("home_pressed", func(): nav.go_to(NavController.Screen.TITLE))
			if screen.has_signal("replay_pressed"):
				screen.connect("replay_pressed", _on_replay_campaign)
			var label: String = _last_won_level if _last_won_level != "" else runtime.current_level_label()
			var elapsed: int = _last_won_elapsed
			var is_last: bool = _last_won_is_last or runtime.is_campaign_done()
			if screen.has_method("setup"):
				screen.call("setup", true, elapsed, label, is_last)
		"fail":
			if screen.has_signal("retry_pressed"):
				screen.connect("retry_pressed", _on_retry_level)
			if screen.has_signal("home_pressed"):
				screen.connect("home_pressed", func(): nav.go_to(NavController.Screen.TITLE))
			var label: String = _last_won_level if _last_won_level != "" else runtime.current_level_label()
			if screen.has_method("setup"):
				screen.call("setup", false, 0, label, false)
		"options":
			if screen.has_signal("back_pressed"):
				screen.connect("back_pressed", _on_options_back)
			if screen.has_method("setup"):
				screen.call("setup", config)

	if screen_host != null:
		screen_host.add_child(screen)

func _on_title_play() -> void:
	if runtime != null and runtime.is_campaign_done():
		runtime.replay_campaign()
	nav.go_to(NavController.Screen.PUZZLE)

func _on_level_done(won: bool) -> void:
	var label := runtime.current_level_label()
	_last_won_level = label
	if won:
		var sess = runtime.current_session
		var elapsed: int = sess.elapsed_ms if sess != null else 0
		_last_won_elapsed = elapsed
		_last_won_is_last = (runtime.completed_count() + 1 >= runtime.playlist_order().size())
		var score_data := {
			"time_ms": elapsed,
			"mistakes": sess.mistake_count if sess != null else 0,
			"hints_used": sess.hints_used if sess != null else 0,
		}
		runtime.on_level_won(label, score_data)
		nav.go_to(NavController.Screen.WIN)
	else:
		_last_won_elapsed = 0
		_last_won_is_last = false
		runtime.on_level_lost(label)
		nav.go_to(NavController.Screen.FAIL)

func _on_next_level() -> void:
	nav.go_to(NavController.Screen.PUZZLE)

func _on_retry_level() -> void:
	if runtime != null:
		runtime.restart_level()
	nav.go_to(NavController.Screen.PUZZLE)

func _on_replay_campaign() -> void:
	runtime.replay_campaign()
	nav.go_to(NavController.Screen.PUZZLE)

func _on_options_back() -> void:
	if _previous_screen_name == "puzzle":
		nav.go_to(NavController.Screen.PUZZLE)
	else:
		nav.go_to(NavController.Screen.TITLE)

func _apply_setting(key: String, value: Variant) -> void:
	match key:
		"audio":
			if sfx != null:
				sfx.set_muted(not bool(value))
			if bgm != null:
				bgm.set_muted(not bool(value))
		"haptic":
			Vibration.set_on(bool(value))
		"reduced_motion":
			LayoutTokens.set_motion(not bool(value))
		"high_contrast":
			_refresh_puzzle_high_contrast()
		"large_text":
			LayoutTokens.set_large_text(bool(value))
			_refresh_large_text()
		"colorblind":
			_refresh_puzzle_colorblind()
		"undo_x":
			_refresh_undo_visible(bool(value))

func _refresh_undo_visible(enabled: bool) -> void:
	if screen_host == null:
		return
	for child in screen_host.get_children():
		if child.has_method("set_undo_visible"):
			child.call("set_undo_visible", enabled)

func _refresh_puzzle_high_contrast() -> void:
	if screen_host == null or config == null:
		return
	var enabled := bool(config.get_option("high_contrast"))
	for child in screen_host.get_children():
		if child.has_method("set_high_contrast_and_redraw"):
			child.call("set_high_contrast_and_redraw", enabled)

func _refresh_large_text() -> void:
	if screen_host == null or config == null:
		return
	var enabled := bool(config.get_option("large_text"))
	for child in screen_host.get_children():
		if child.has_method("set_large_text"):
			child.call("set_large_text", enabled)

func _refresh_puzzle_colorblind() -> void:
	if screen_host == null or config == null:
		return
	var enabled := bool(config.get_option("colorblind"))
	for child in screen_host.get_children():
		if child.has_method("set_colorblind_and_redraw"):
			child.call("set_colorblind_and_redraw", enabled)
		elif "board" in child and child.board != null and child.board.has_method("set_colorblind"):
			child.board.set_colorblind(enabled)
			child.board.redraw()

func _apply_all_settings() -> void:
	if config == null:
		return
	_apply_setting("audio", config.get_option("audio"))
	_apply_setting("haptic", config.get_option("haptic"))
	_apply_setting("reduced_motion", config.get_option("reduced_motion"))
	_apply_setting("high_contrast", config.get_option("high_contrast"))
	_apply_setting("large_text", config.get_option("large_text"))
	_apply_setting("colorblind", config.get_option("colorblind"))
	_apply_setting("undo_x", config.get_option("undo_x"))

func _on_boot_error(err: String) -> void:
	push_error("Boot error: " + err)
	if save_error_dialog != null:
		save_error_dialog.dialog_text = "Lỗi khởi động: " + err
		save_error_dialog.popup_centered()

func _on_save_failed(reason: String) -> void:
	push_warning("Save failed: " + reason)
	if save_error_dialog != null:
		save_error_dialog.dialog_text = "Lưu dữ liệu thất bại: " + reason
		save_error_dialog.popup_centered()

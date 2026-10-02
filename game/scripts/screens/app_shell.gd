# app_shell.gd
extends Control

const CampaignRuntime = preload("res://scripts/campaign/campaign_runtime.gd")
const BankReader = preload("res://scripts/content/bank_reader.gd")
const PaceReader = preload("res://scripts/content/pace_reader.gd")
const ProgressManager = preload("res://scripts/state/progress_manager.gd")
const SessionStore = preload("res://scripts/state/session_store.gd")
const ConfigStore = preload("res://scripts/state/config_store.gd")
const NavController = preload("res://scripts/campaign/nav_controller.gd")
const SfxPlayer = preload("res://scripts/feedback/sfx_player.gd")
const BgmPlayer = preload("res://scripts/feedback/bgm_player.gd")
const Vibration = preload("res://scripts/feedback/vibration.gd")

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
var _previous_screen_name: String = "title"

@onready var screen_host: Control = get_node_or_null("ScreenHost")
@onready var save_error_dialog: AcceptDialog = get_node_or_null("SaveErrorDialog")

func _ready() -> void:
	var profile_dir := "user://profile"
	config = ConfigStore.new(profile_dir)
	config.option_changed.connect(_apply_setting)

	sfx = SfxPlayer.new()
	sfx.name = "SfxPlayer"
	add_child(sfx)
	bgm = BgmPlayer.new()
	bgm.name = "BgmPlayer"
	add_child(bgm)
	_apply_all_settings()

	var bank := BankReader.new()
	var pace := PaceReader.new()
	var progress := ProgressManager.new(profile_dir)
	var sessions := SessionStore.new(profile_dir)
	runtime = CampaignRuntime.new(bank, pace, progress, sessions)
	runtime.save_failed.connect(_on_save_failed)

	var boot_res := runtime.boot()
	if not boot_res.get("ok", false):
		_on_boot_error(str(boot_res.get("error", "Boot failed")))
		return

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
				screen.connect("play_pressed", func(): nav.go_to(NavController.Screen.PUZZLE))
			if screen.has_signal("options_pressed"):
				screen.connect("options_pressed", func(): nav.go_to(NavController.Screen.OPTIONS))
			if screen.has_method("setup"):
				screen.call("setup", runtime)
		"puzzle":
			if screen.has_signal("go_home"):
				screen.connect("go_home", func(): nav.go_to(NavController.Screen.TITLE))
			if screen.has_signal("level_done"):
				screen.connect("level_done", _on_level_done)
			if screen.has_method("setup"):
				screen.call("setup", runtime, sfx)
		"win":
			if screen.has_signal("next_pressed"):
				screen.connect("next_pressed", _on_next_level)
			if screen.has_signal("home_pressed"):
				screen.connect("home_pressed", func(): nav.go_to(NavController.Screen.TITLE))
			if screen.has_signal("replay_pressed"):
				screen.connect("replay_pressed", _on_replay_campaign)
			var label: String = runtime.current_level_label()
			var elapsed: int = runtime.current_session.elapsed_ms if runtime.current_session != null else 0
			var is_last: bool = runtime.is_campaign_done()
			if screen.has_method("setup"):
				screen.call("setup", true, elapsed, label, is_last)
		"fail":
			if screen.has_signal("retry_pressed"):
				screen.connect("retry_pressed", func(): nav.go_to(NavController.Screen.PUZZLE))
			if screen.has_signal("home_pressed"):
				screen.connect("home_pressed", func(): nav.go_to(NavController.Screen.TITLE))
			var label: String = runtime.current_level_label()
			if screen.has_method("setup"):
				screen.call("setup", false, 0, label, false)
		"options":
			if screen.has_signal("back_pressed"):
				screen.connect("back_pressed", _on_options_back)
			if screen.has_method("setup"):
				screen.call("setup", config)

	if screen_host != null:
		screen_host.add_child(screen)

func _on_level_done(won: bool) -> void:
	var label := runtime.current_level_label()
	if won:
		var sess = runtime.current_session
		var score_data := {
			"time_ms": sess.elapsed_ms if sess != null else 0,
			"mistakes": sess.mistake_count if sess != null else 0,
		}
		runtime.on_level_won(label, score_data)
		nav.go_to(NavController.Screen.WIN)
	else:
		runtime.on_level_lost(label)
		nav.go_to(NavController.Screen.FAIL)

func _on_next_level() -> void:
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

func _apply_all_settings() -> void:
	if config == null:
		return
	_apply_setting("audio", config.get_option("audio"))
	_apply_setting("haptic", config.get_option("haptic"))

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

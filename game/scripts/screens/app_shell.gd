# app_shell.gd
extends Control

const CampaignRuntime = preload("res://scripts/campaign/campaign_runtime.gd")
const EndlessRuntimeClass = preload("res://scripts/endless/endless_runtime.gd")
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
const BGM_TRACK := "res://assets/audio/bgm/bgm-candoku-melody.wav"

const SplashScreen = preload("res://scripts/screens/splash_screen.gd")

const SCENE_MAP := {
	"title": "res://scenes/title.tscn",
	"puzzle": "res://scenes/puzzle.tscn",
	"win": "res://scenes/win.tscn",
	"fail": "res://scenes/fail.tscn",
	"options": "res://scenes/options.tscn",
}

var runtime: CampaignRuntime
var endless_runtime: RefCounted
var _mode: String = "campaign"
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
var _debug_mode: bool = false; var _debug_lvl: Dictionary = {}; var _debug_label: String = ""
var _debug_next: Dictionary = {}; var _debug_next_lbl: String = ""
var _options_overlay: Control = null

@onready var screen_host: Control = get_node_or_null("ScreenHost")
@onready var save_error_dialog: AcceptDialog = get_node_or_null("SaveErrorDialog")

func _ready() -> void:
	var sel := CampaignSelector.load_config(selector_path, profile_dir)
	if not sel.ok: _on_boot_error(str(sel.error)); return
	if config == null:
		config = ConfigStore.new(profile_dir)
		config.option_changed.connect(_apply_setting)
	if sfx == null: sfx = SfxPlayer.new(); sfx.name = "SfxPlayer"; add_child(sfx)
	if bgm == null: bgm = BgmPlayer.new(); bgm.name = "BgmPlayer"; add_child(bgm)
	_apply_all_settings()
	if runtime == null:
		var bank := BankReader.new(); var pace := PaceReader.new()
		var progress := ProgressManager.new(sel.progress_dir); var sessions := SessionStore.new(sel.progress_dir)
		runtime = CampaignRuntime.new(bank, pace, progress, sessions)
		runtime.playlist_path = sel.playlist_path
		endless_runtime = EndlessRuntimeClass.new(bank, progress, sessions)
	if not runtime.save_failed.is_connected(_on_save_failed): runtime.save_failed.connect(_on_save_failed)
	if endless_runtime != null and not endless_runtime.save_failed.is_connected(_on_save_failed):
		endless_runtime.save_failed.connect(_on_save_failed)
	if not GameFeatures.is_campaign_enabled() and GameFeatures.is_endless_enabled(): _mode = "endless"
	if GameFeatures.is_campaign_enabled() and runtime.playlist_order().is_empty():
		var b := runtime.boot()
		if not b.get("ok", false): _on_boot_error(str(b.get("error", "Boot failed"))); return
	if nav == null: nav = NavController.new(); nav.screen_changed.connect(_swap_screen)
	if screen_host == null:
		screen_host = Control.new(); screen_host.name = "ScreenHost"
		screen_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(screen_host)
	_show_splash()

func _show_splash() -> void:
	if DisplayServer.get_name() == "headless":
		_start_bgm(); _swap_screen("", nav.current_name()); return
	var splash := SplashScreen.new()
	splash.name = "SplashOverlay"
	splash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(splash)
	splash.finished.connect(func():
		splash.queue_free(); _start_bgm(); _swap_screen("", nav.current_name())
	)

func _start_bgm() -> void:
	if bgm != null and is_inside_tree() and ResourceLoader.exists(BGM_TRACK):
		bgm.play_track(BGM_TRACK)

func _swap_screen(from_name: String, to_name: String) -> void:
	if from_name != "": _previous_screen_name = from_name
	if screen_host != null:
		for child in screen_host.get_children():
			child.queue_free(); screen_host.remove_child(child)
	_instantiate_screen(to_name)

func _active_runtime() -> Variant:
	return endless_runtime if _mode == "endless" else runtime

func _instantiate_screen(to_name: String) -> void:
	var scene_path: String = SCENE_MAP.get(to_name, "")
	if scene_path == "" or not ResourceLoader.exists(scene_path): return
	var packed := load(scene_path) as PackedScene
	if packed == null: return
	var screen := packed.instantiate() as Control
	if screen == null: return
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	if screen.has_signal("debug_level_selected"): screen.connect("debug_level_selected", _on_debug_level_selected)
	if screen.has_signal("home_pressed"): screen.connect("home_pressed", _on_puzzle_home)
	var cur_rt = _active_runtime()
	match to_name:
		"title":
			if screen.has_signal("play_pressed"): screen.connect("play_pressed", _on_title_play)
			if screen.has_signal("endless_pressed"): screen.connect("endless_pressed", _on_title_endless)
			if screen.has_signal("options_pressed"): screen.connect("options_pressed", _show_options_overlay)
			if screen.has_method("setup"): screen.call("setup", runtime, endless_runtime)
		"puzzle":
			if screen.has_signal("go_home"): screen.connect("go_home", _on_puzzle_home)
			if screen.has_signal("options_pressed"): screen.connect("options_pressed", _show_options_overlay)
			if screen.has_signal("level_done"): screen.connect("level_done", _on_level_done)
			if screen.has_method("setup"): screen.call("setup", cur_rt, sfx, config, _debug_lvl if _debug_mode else {}, _previous_screen_name != "options")
		"win":
			if screen.has_signal("next_pressed"): screen.connect("next_pressed", _on_next_level)
			if screen.has_signal("replay_pressed"): screen.connect("replay_pressed", _on_replay_campaign)
			var label: String = _last_won_level if _last_won_level != "" else cur_rt.current_level_label()
			var elapsed: int = _last_won_elapsed
			var is_last: bool = _last_won_is_last or (_mode == "campaign" and runtime != null and runtime.is_campaign_done())
			if screen.has_method("setup"): screen.call("setup", true, elapsed, label, is_last)
		"fail":
			if screen.has_signal("retry_pressed"): screen.connect("retry_pressed", _on_retry_level)
			var label: String = _last_won_level if _last_won_level != "" else cur_rt.current_level_label()
			if screen.has_method("setup"): screen.call("setup", false, 0, label, false)
	if screen_host != null: screen_host.add_child(screen)

func _on_debug_level_selected(level_data: Dictionary, label: String) -> void:
	_debug_mode = true; _debug_lvl = level_data.duplicate(true); _debug_label = label
	_debug_next = {}; _debug_next_lbl = ""
	if runtime != null and runtime.playlist_order().has(label):
		var order := runtime.playlist_order(); var idx := order.find(label)
		if idx >= 0 and idx + 1 < order.size():
			var nxt: String = order[idx + 1]; var ent: Dictionary = runtime._resolve_playlist_entry(nxt)
			if not ent.is_empty():
				_debug_next_lbl = nxt; _debug_next = runtime._fetch_level(ent.size, ent.rank, ent.index, int(ent.get("transform", 0)))
				_debug_next["id"] = nxt; _debug_next["_playlist_label"] = nxt
	elif level_data.has("_bank_meta") and runtime != null and runtime.bank != null:
		var m: Dictionary = level_data._bank_meta; var s: int = int(m.get("size", 4)); var r: int = int(m.get("rank", 1))
		var nxt_i: int = int(m.get("index", 0)) + 1; var tf_id: int = int(m.get("transform", 0))
		if nxt_i < runtime.bank.level_count(s, r):
			_debug_next = runtime._fetch_level(s, r, nxt_i, tf_id); _debug_next_lbl = "Bank %dx%d R%d #%d" % [s, s, r, nxt_i]; _debug_next["id"] = _debug_next_lbl
			_debug_next["_bank_meta"] = {"size": s, "rank": r, "index": nxt_i, "transform": tf_id}
	elif level_data.has("_endless_level_num") and endless_runtime != null:
		var nxt_n: int = int(level_data._endless_level_num) + 1
		var p = load("res://scripts/endless/endless_progress.gd").new(); p.set_level_num(nxt_n)
		var sel = load("res://scripts/endless/level_selector.gd").new(endless_runtime.bank, endless_runtime.config, p)
		_debug_next = sel.select_next_level()
		if not _debug_next.is_empty():
			_debug_next_lbl = "Endless %d" % nxt_n
			_debug_next["id"] = _debug_next_lbl; _debug_next["_endless_level_num"] = nxt_n
	if nav.current() == NavController.Screen.PUZZLE: _swap_screen("puzzle", "puzzle")
	else: nav.go_to(NavController.Screen.PUZZLE)

func _on_puzzle_home() -> void:
	_debug_mode = false; _debug_lvl = {}; _debug_next = {}
	nav.go_to(NavController.Screen.TITLE)

func _on_title_play() -> void:
	_mode = "campaign"; _debug_mode = false; _debug_lvl = {}; _debug_next = {}
	if runtime != null and runtime.is_campaign_done(): runtime.replay_campaign()
	nav.go_to(NavController.Screen.PUZZLE)

func _on_title_endless() -> void:
	_mode = "endless"; _debug_mode = false; _debug_lvl = {}; _debug_next = {}
	nav.go_to(NavController.Screen.PUZZLE)

func _on_level_done(won: bool) -> void:
	var cur_rt = _active_runtime()
	var label: String = _debug_label if _debug_mode else (cur_rt.current_level_label() if cur_rt != null else "")
	_last_won_level = label
	var cur_sc := screen_host.get_child(0) if screen_host != null and screen_host.get_child_count() > 0 else null
	var sess = cur_sc.get("session") if (cur_sc != null and cur_sc.get("session") != null) else (cur_rt.current_session if cur_rt != null else null)
	var elapsed: int = sess.elapsed_ms if sess != null else 0
	_last_won_elapsed = elapsed
	if _debug_mode:
		_last_won_is_last = _debug_next.is_empty()
		nav.go_to(NavController.Screen.WIN if won else NavController.Screen.FAIL)
		return
	if won:
		_last_won_is_last = (_mode == "campaign" and runtime.completed_count() + 1 >= runtime.playlist_order().size())
		var score_data := {"time_ms": elapsed, "mistakes": sess.mistake_count if sess != null else 0, "hints_used": sess.hints_used if sess != null else 0}
		cur_rt.on_level_won(label, score_data)
		nav.go_to(NavController.Screen.WIN)
	else:
		_last_won_elapsed = 0; _last_won_is_last = false
		cur_rt.on_level_lost(label)
		nav.go_to(NavController.Screen.FAIL)

func _on_next_level() -> void:
	if _debug_mode:
		if not _debug_next.is_empty(): _on_debug_level_selected(_debug_next, _debug_next_lbl)
		else: _debug_mode = false; nav.go_to(NavController.Screen.TITLE)
		return
	if nav.current() == NavController.Screen.PUZZLE: _swap_screen("puzzle", "puzzle")
	else: nav.go_to(NavController.Screen.PUZZLE)

func _on_retry_level() -> void:
	if _debug_mode:
		if nav.current() == NavController.Screen.PUZZLE: _swap_screen("puzzle", "puzzle")
		else: nav.go_to(NavController.Screen.PUZZLE)
		return
	var cur_rt = _active_runtime()
	if cur_rt != null: cur_rt.restart_level()
	if nav.current() == NavController.Screen.PUZZLE: _swap_screen("puzzle", "puzzle")
	else: nav.go_to(NavController.Screen.PUZZLE)

func _on_replay_campaign() -> void:
	if _mode == "campaign" and runtime != null: runtime.replay_campaign()
	if nav.current() == NavController.Screen.PUZZLE: _swap_screen("puzzle", "puzzle")
	else: nav.go_to(NavController.Screen.PUZZLE)

func _show_options_overlay() -> void:
	if _options_overlay != null: return
	var p: String = SCENE_MAP.get("options", "")
	if p == "" or not ResourceLoader.exists(p): return
	var packed := load(p) as PackedScene
	if packed == null: return
	_options_overlay = packed.instantiate() as Control
	if _options_overlay == null: return
	_options_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if _options_overlay.has_signal("back_pressed"): _options_overlay.connect("back_pressed", _on_options_back)
	if _options_overlay.has_method("setup"): _options_overlay.call("setup", config)
	add_child(_options_overlay)

func _hide_options_overlay() -> void:
	if _options_overlay != null: _options_overlay.queue_free(); _options_overlay = null

func _on_options_back() -> void:
	_previous_screen_name = "options"; _hide_options_overlay()

func _apply_setting(key: String, value: Variant) -> void:
	match key:
		"audio":
			if sfx != null: sfx.set_muted(not bool(value))
			if bgm != null: bgm.set_muted(not bool(value))
		"haptic": Vibration.set_on(bool(value))
		"reduced_motion": LayoutTokens.set_motion(not bool(value))
		"high_contrast": _refresh_screen("set_high_contrast_and_redraw", bool(value))
		"large_text": LayoutTokens.set_large_text(bool(value)); _refresh_screen("set_large_text", bool(value))
		"colorblind": _refresh_puzzle_colorblind()
		"language":
			if value is String:
				TranslationServer.set_locale(str(value)); _rebuild_current_screen()

func _rebuild_current_screen() -> void:
	if nav != null: _swap_screen("", nav.current_name())

func _refresh_screen(method: String, val: Variant) -> void:
	if screen_host == null: return
	for child in screen_host.get_children():
		if child.has_method(method): child.call(method, val)

func _refresh_puzzle_colorblind() -> void:
	if screen_host == null or config == null: return
	var enabled := bool(config.get_option("colorblind"))
	for child in screen_host.get_children():
		if child.has_method("set_colorblind_and_redraw"): child.call("set_colorblind_and_redraw", enabled)
		elif "board" in child and child.board != null and child.board.has_method("set_colorblind"):
			child.board.set_colorblind(enabled); child.board.redraw()

func _apply_all_settings() -> void:
	if config == null: return
	for key in ["audio", "haptic", "reduced_motion", "high_contrast", "large_text", "colorblind", "language"]:
		_apply_setting(key, config.get_option(key))

func _on_boot_error(err: String) -> void:
	push_error("Boot error: " + err)
	if save_error_dialog != null:
		save_error_dialog.dialog_text = tr("boot.error") % err; save_error_dialog.popup_centered()

func _on_save_failed(reason: String) -> void:
	push_warning("Save failed: " + reason)
	if save_error_dialog != null:
		save_error_dialog.dialog_text = tr("boot.save_failed") % reason; save_error_dialog.popup_centered()

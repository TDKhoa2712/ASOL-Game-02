extends SceneTree

const Vibration = preload("res://scripts/feedback/vibration.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const PillToggle = preload("res://scripts/screens/pill_toggle.gd")
const Palette = preload("res://scripts/theme/palette.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await _test_toggles_through_ui()
	await _test_overlay_readability()
	await _test_reduced_motion_live()
	await _test_progress_bar_static()
	await _test_error_shake_follows_haptic()
	if _failures.is_empty():
		print("SETTINGS_APPLY_PASS"); quit(0)
	else:
		for f in _failures: printerr(f)
		quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond: _failures.append("FAIL: " + msg)

func _toggles(n: Node, out: Array) -> void:
	if n is PillToggle: out.append(n)
	for c in n.get_children(): _toggles(c, out)

func _test_toggles_through_ui() -> void:
	var pdir := OS.get_user_data_dir().path_join("test_settings_%s" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(pdir)
	var shell = load("res://scenes/main.tscn").instantiate()
	shell.profile_dir = pdir
	root.add_child(shell)
	await process_frame
	shell._show_options_overlay()
	await process_frame
	var list: Array = []
	_toggles(shell._options_overlay, list)
	_assert(list.size() == 7, "seven toggles, got %d" % list.size())
	# Order: music, audio, haptic, reduced_motion, large_text, colorblind, high_contrast
	for t in list: t.button_pressed = not t.button_pressed
	await process_frame
	_assert(shell.bgm.is_muted(), "music toggle mutes bgm")
	_assert(shell.sfx.is_muted(), "sound toggle mutes sfx")
	_assert(not Vibration.is_on(), "haptic toggle disables vibration")
	_assert(not LayoutTokens.motion_enabled, "reduced motion toggle disables motion")
	_assert(LayoutTokens.large_text_enabled, "large text toggle enables large text")
	_assert(shell.config.get_option("colorblind") == true, "colorblind saved")
	_assert(shell.config.get_option("high_contrast") == true, "high contrast saved")
	shell.config.reset_defaults()
	_assert(Vibration.is_on() and not shell.sfx.is_muted() and LayoutTokens.motion_enabled, "reset re-applies defaults")
	await process_frame
	list.clear(); _toggles(shell._options_overlay, list)
	_assert(list.size() == 7, "toggles rebuilt after reset")
	_assert(list[2].is_on() and not list[3].is_on(), "toggles redrawn with default values after reset")
	for t in list: t.button_pressed = not t.button_pressed
	await process_frame
	# Reboot: saved settings must apply on a fresh shell.
	shell.queue_free(); await process_frame
	Vibration.set_on(true); LayoutTokens.set_motion(true); LayoutTokens.set_large_text(false)
	var shell2 = load("res://scenes/main.tscn").instantiate()
	shell2.profile_dir = pdir
	root.add_child(shell2)
	await process_frame
	_assert(not Vibration.is_on(), "haptic off survives reboot")
	_assert(shell2.sfx.is_muted() and shell2.bgm.is_muted(), "mute survives reboot")
	_assert(not LayoutTokens.motion_enabled, "reduced motion survives reboot")
	shell2.queue_free(); await process_frame
	LayoutTokens.set_large_text(false); Vibration.set_on(true); LayoutTokens.set_motion(true)

static func _lum(c: Color) -> float:
	var f := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)

static func _contrast(a: Color, b: Color) -> float:
	var la := _lum(a); var lb := _lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)

func _check_button(btn: Button, label: String, min_ratio: float) -> void:
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := btn.get_theme_stylebox(st) as StyleBoxFlat
		_assert(sb != null, "%s has flat %s style" % [label, st])
		if sb == null: continue
		var key := "font_color" if st == "normal" else "font_%s_color" % st
		var fc := btn.get_theme_color(key)
		var ratio := _contrast(fc, sb.bg_color)
		_assert(ratio >= min_ratio, "%s %s text contrast %.2f < %.1f" % [label, st, ratio, min_ratio])

func _test_overlay_readability() -> void:
	var pdir := OS.get_user_data_dir().path_join("test_settings_ui_%s" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(pdir)
	var shell = load("res://scenes/main.tscn").instantiate()
	shell.profile_dir = pdir
	root.add_child(shell)
	await process_frame
	shell._show_options_overlay()
	await process_frame
	var options = shell._options_overlay
	var card: Control = options.find_child("OptionsCard", true, false)
	_assert(card.custom_minimum_size.x >= 900, "settings card fills the portrait width")
	var lang_btn: Button = options.find_child("LangBtn", true, false)
	_check_button(lang_btn, "settings language button", 4.5)
	_assert(lang_btn.get_theme_font_size("font_size") >= 28, "settings language text is large")
	_check_button(options.back_btn, "settings close button", 3.0)
	var list: Array = []
	_toggles(options, list)
	for t in list:
		_assert(_contrast(t.track_color(false), Palette.TEXT_ON_ACCENT) >= 3.0, "OFF pill label readable")
		_assert(_contrast(t.track_color(true), Palette.TEXT_ON_ACCENT) >= 3.0, "ON pill label readable")
	options._on_open_language_dialog()
	await process_frame
	var dlg: Control = options.find_child("LanguageCard", true, false)
	_assert(dlg != null and dlg.custom_minimum_size.x >= 900, "language card fills the portrait width")
	for btn in options.find_children("LangBtn_*", "Button", true, false):
		_check_button(btn, "language option " + btn.name, 4.5)
		_assert(btn.get_theme_font_size("font_size") >= 28, "language option text is large")
	shell.queue_free(); await process_frame
	var help = load("res://scripts/screens/help_screen.gd").new()
	root.add_child(help)
	await process_frame
	var help_card: Control = help.find_child("HelpCard", true, false)
	_assert(help_card.custom_minimum_size.x >= 900, "help card fills the portrait width")
	for lbl in help.find_children("*", "Label", true, false):
		_assert(lbl.get_theme_font_size("font_size") >= 28, "help text '%s' is large" % lbl.text.left(20))
		_assert(_contrast(lbl.get_theme_color("font_color"), Palette.SURFACE_TILE) >= 4.5 or lbl.text.length() <= 3, "help text '%s' has contrast" % lbl.text.left(20))
	help.queue_free(); await process_frame

func _test_reduced_motion_live() -> void:
	var pdir := OS.get_user_data_dir().path_join("test_settings_motion_%s" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(pdir)
	var shell = load("res://scenes/main.tscn").instantiate()
	shell.profile_dir = pdir
	root.add_child(shell)
	await process_frame
	var title_before: Node = shell.screen_host.get_child(0)
	shell._show_options_overlay()
	shell.config.set_option("reduced_motion", true)
	await process_frame
	_assert(not is_instance_valid(title_before) or title_before.is_queued_for_deletion() or title_before.get_parent() == null, "title rebuilt so its looping animations stop")
	_assert(shell._options_overlay != null, "settings overlay stays open after motion change")
	var mascot = load("res://scenes/components/candy_character.tscn").instantiate()
	mascot.expression = "sad"; mascot.idle_style = "hop"
	root.add_child(mascot)
	await process_frame
	for t in [mascot._flap, mascot._idle, mascot._tears, mascot._fx_tw, mascot._wave]:
		_assert(t == null or not t.is_valid(), "mascot runs no looping tween with reduced motion")
	mascot.queue_free()
	var box := Control.new(); root.add_child(box)
	load("res://scripts/feedback/tween_fx.gd").scale_pop(box, 0.25)
	await create_timer(0.05).timeout
	_assert(box.scale.is_equal_approx(Vector2.ONE), "pop finishes instantly with reduced motion")
	box.queue_free()
	shell.queue_free(); await process_frame
	LayoutTokens.set_motion(true)

func _test_progress_bar_static() -> void:
	LayoutTokens.set_motion(false)
	var holder := VBoxContainer.new()
	holder.size = Vector2(600, 200)
	root.add_child(holder)
	var bar = load("res://scripts/ui/progress_bar.gd").new(10, 30)
	holder.add_child(bar)
	bar.animate()
	for i in 3: await process_frame
	var track: Control = bar._bar_bg
	var fill: Control = bar._fill_rect
	var shown: float = fill.size.x * fill.scale.x
	_assert(absf(shown - track.size.x / 3.0) < 2.0, "reduced-motion progress shows 1/3 (shown %.0f of %.0f)" % [shown, track.size.x])
	bar.set_progress(30, 30)
	for i in 2: await process_frame
	shown = fill.size.x * fill.scale.x
	_assert(absf(shown - track.size.x) < 2.0, "progress updates to full")
	holder.queue_free(); await process_frame
	LayoutTokens.set_motion(true)

func _test_error_shake_follows_haptic() -> void:
	var board := Control.new()
	board.position = Vector2(100, 0)
	root.add_child(board)
	var Screen = load("res://scripts/screens/puzzle_screen.gd")
	Vibration.set_on(false)
	_assert(not Screen.should_shake_board(), "no board shake with haptic off")
	Vibration.set_on(true)
	_assert(Screen.should_shake_board(), "board shakes with haptic on")
	board.queue_free(); await process_frame

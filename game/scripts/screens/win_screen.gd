# win_screen.gd — Victory screen with animated mascot, hearts, ribbon, stats, and next-level preview.
extends Control

signal next_pressed()
signal retry_pressed()
signal home_pressed()
signal replay_pressed()

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const GradientBg = preload("res://scripts/ui/gradient_bg.gd")
const RibbonBanner = preload("res://scripts/ui/ribbon_banner.gd")
const HeartDisplay = preload("res://scripts/ui/heart_display.gd")
const StatCard = preload("res://scripts/ui/stat_card.gd")
const ConfettiLayer = preload("res://scripts/ui/confetti_layer.gd")
const ActionButton = preload("res://scripts/ui/action_button.gd")
const SunburstRays = preload("res://scripts/ui/sunburst_rays.gd")
const CandyCharacterScene = preload("res://scenes/components/candy_character.tscn")
const CandyCharacter = preload("res://scripts/ui/candy_character.gd")
const TweenHelpers = preload("res://scripts/ui/tween_helpers.gd")
const TwinkleStar = preload("res://scripts/ui/twinkle_star.gd")
const WinNextPreview = preload("res://scripts/screens/win_next_preview.gd")

var _is_last_level: bool = false
var _level_id: String = ""
var _elapsed_ms: int = 0
var _hearts_left: int = 3
var _mistake_count: int = 0
var _next_label: String = ""
var _next_size: int = 0
var _next_difficulty: String = ""

var _bg: ColorRect
var _rays: Control
var _confetti: ConfettiLayer
var ribbon: RibbonBanner
var message_label: Label:
	get: return ribbon.label if ribbon != null else null
var _hearts: HeartDisplay
var mascot: CandyCharacter
var _mascot_host: Control
var stat_card: StatCard
var _next_card: PanelContainer
var next_btn: Button
var home_btn: Button
var replay_btn: Button
var _level_badge: Label

func _ensure_nodes() -> void:
	if _bg != null: return
	_bg = GradientBg.new(Palette.WIN_BG_CENTER, Palette.WIN_BG_MID, Palette.WIN_BG_EDGE); add_child(_bg)
	_rays = SunburstRays.new(); add_child(_rays)
	_confetti = ConfettiLayer.new(40); _confetti.z_index = 0; add_child(_confetti)

	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	LayoutTokens.bind_responsive_margins(safe, 48, 984.0)
	safe.add_theme_constant_override("margin_top", 110); safe.add_theme_constant_override("margin_bottom", 52)
	add_child(safe)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 14)
	safe.add_child(stack)

	# 1. Top bar
	var top := HBoxContainer.new(); stack.add_child(top)

	home_btn = Button.new()
	home_btn.custom_minimum_size = Vector2(84, 84); home_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var hstyle := StyleBoxFlat.new()
	hstyle.bg_color = Color("#3B82F6"); hstyle.set_corner_radius_all(22)
	hstyle.shadow_color = Color("#1D4ED8"); hstyle.shadow_size = 6; hstyle.shadow_offset = Vector2(0, 6)
	for s in ["normal", "hover", "pressed", "focus"]: home_btn.add_theme_stylebox_override(s, hstyle)
	home_btn.pressed.connect(_on_home); top.add_child(home_btn)

	var top_center := CenterContainer.new()
	top_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); top_center.mouse_filter = Control.MOUSE_FILTER_IGNORE; home_btn.add_child(top_center)
	var top_icon := TextureRect.new()
	top_icon.texture = load("res://assets/ui/result/icon_home_white.svg") as Texture2D
	top_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; top_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top_icon.custom_minimum_size = Vector2(46, 46); top_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; top_center.add_child(top_icon)

	var spacer1 := Control.new(); spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer1)

	_level_badge = Label.new()
	_level_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_badge.add_theme_font_size_override("font_size", 28); _level_badge.add_theme_color_override("font_color", Color("#23365E"))
	var bstyle := StyleBoxFlat.new()
	bstyle.bg_color = Color.WHITE; bstyle.set_corner_radius_all(999)
	bstyle.shadow_color = Color("#E2C46A"); bstyle.shadow_size = 5; bstyle.shadow_offset = Vector2(0, 5)
	bstyle.content_margin_left = 34; bstyle.content_margin_right = 34; bstyle.content_margin_top = 10; bstyle.content_margin_bottom = 10
	_level_badge.add_theme_stylebox_override("normal", bstyle)
	var badge_font := FontTokens.heading()
	if badge_font != null: _level_badge.add_theme_font_override("font", badge_font)
	top.add_child(_level_badge)

	var spacer2 := Control.new(); spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer2)
	# Mirrors the home button width so the badge sits at the true center.
	var balance := Control.new(); balance.custom_minimum_size.x = 84; top.add_child(balance)

	# 2. Ribbon
	ribbon = RibbonBanner.new(tr("result.win.title"), "win")
	stack.add_child(ribbon)

	# 3. Hearts + sparkle stars
	var hearts_wrap := Control.new()
	hearts_wrap.custom_minimum_size = Vector2(0, 200)
	hearts_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_child(hearts_wrap)

	_hearts = HeartDisplay.new(3, _hearts_left, "win")
	_hearts.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_hearts.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hearts_wrap.add_child(_hearts)

	for s in [[Vector2(-250, 16), 22.0, Color("#FFC93C"), 0.0], [Vector2(226, -4), 30.0, Color("#FFC93C"), 0.7], [Vector2(110, -20), 20.0, Color("#7CC8FF"), 1.1]]:
		var star := TwinkleStar.new(s[1], s[2]); star.modulate.a = 0.3
		star.anchor_left = 0.5; star.anchor_right = 0.5
		star.offset_left = s[0].x; star.offset_top = s[0].y; star.offset_right = s[0].x + s[1]; star.offset_bottom = s[0].y + s[1]
		hearts_wrap.add_child(star)
		if LayoutTokens.motion_enabled: _animate_twinkle(star, s[3])

	# 4. Mascot Component
	_mascot_host = Control.new()
	_mascot_host.custom_minimum_size = Vector2(600, 380)
	_mascot_host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(_mascot_host)

	mascot = CandyCharacterScene.instantiate()
	mascot.position = Vector2(300, 184)
	mascot.scale = Vector2(1.05, 1.05)
	mascot.expression = "happy"
	mascot.idle_style = "hop" if LayoutTokens.motion_enabled else "none"
	_mascot_host.add_child(mascot)

	# 5. Stat card
	stat_card = StatCard.new(_build_stats())
	stack.add_child(stat_card)

	var bottom_space := Control.new()
	bottom_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(bottom_space)

	# 6. Next-level card
	_next_card = _create_next_card()
	stack.add_child(_next_card)

func _create_next_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "NextCard"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nc_style := StyleBoxFlat.new()
	nc_style.bg_color = Color.WHITE; nc_style.set_corner_radius_all(52)
	nc_style.shadow_color = Color("#EFD27E"); nc_style.shadow_size = 8; nc_style.shadow_offset = Vector2(0, 7)
	nc_style.set_content_margin_all(28)
	card.add_theme_stylebox_override("panel", nc_style)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 28)
	card.add_child(inner)

	var row := HBoxContainer.new()
	row.name = "PreviewRow"; row.add_theme_constant_override("separation", 28)
	inner.add_child(row)

	row.add_child(WinNextPreview.build_mini_board(_next_size))

	row.add_child(WinNextPreview.build_info(tr("result.win.next_header"), _next_label, _difficulty_display(_next_difficulty), _next_difficulty, _next_size))

	next_btn = ActionButton.create(tr("result.win.next"), Palette.WIN_BUTTON_BG, Palette.WIN_BUTTON_SHADOW, Palette.WIN_BUTTON_TEXT_SHADOW, 52, 128)
	next_btn.clip_contents = true
	ActionButton.set_trailing_icon(next_btn, "res://assets/ui/result/icon_next_white.svg", Vector2(40, 40))
	next_btn.pressed.connect(_on_next); inner.add_child(next_btn)

	var glint := ColorRect.new()
	glint.name = "Glint"
	glint.color = Color(1, 1, 1, 0.28)
	glint.custom_minimum_size = Vector2(70, 170)
	glint.size = Vector2(70, 170)
	glint.position = Vector2(-60, -10)
	glint.rotation = deg_to_rad(-20.0)
	glint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	next_btn.add_child(glint)

	replay_btn = ActionButton.create(tr("result.win.replay"), Palette.WIN_BUTTON_BG, Palette.WIN_BUTTON_SHADOW, Palette.WIN_BUTTON_TEXT_SHADOW, 52, 128)
	replay_btn.pressed.connect(_on_replay); replay_btn.visible = false; inner.add_child(replay_btn)
	return card

func _build_stats() -> Array[Dictionary]:
	return [
		{"label": tr("result.stat.time"), "value": _format_time(_elapsed_ms), "icon": "clock"},
		{"label": tr("result.stat.mistakes"), "value": str(_mistake_count), "icon": "error"},
	]

func _format_time(ms: int) -> String:
	var s: int = int(ms / 1000.0)
	return "%02d:%02d" % [int(s / 60.0), s % 60]

func _difficulty_display(d: String) -> String:
	return tr("difficulty." + d) if d in ["tutorial", "easy", "medium", "hard"] else ""


func setup(won: bool, score: int, level_id: String, is_last: bool, hearts_left: int = 3, mistake_count: int = 0, next_label: String = "", next_size: int = 0, next_difficulty: String = "") -> void:
	_is_last_level = is_last; _level_id = level_id.trim_prefix("L"); _elapsed_ms = score
	_hearts_left = clampi(hearts_left, 0, 3); _mistake_count = mistake_count
	_next_label = next_label; _next_size = next_size; _next_difficulty = next_difficulty
	_ensure_nodes(); _update_ui()

func _ready() -> void:
	_ensure_nodes(); _update_ui(); _play_entrance_animations()

func _update_ui() -> void:
	if ribbon != null: ribbon.text = tr("result.win.title_campaign") if _is_last_level else tr("result.win.title")
	if _level_badge != null:
		var loc := TranslationServer.get_locale()
		_level_badge.text = ("Màn " + _level_id) if loc.begins_with("vi") else ("Level " + _level_id)
	if next_btn != null: next_btn.visible = not _is_last_level
	if replay_btn != null: replay_btn.visible = _is_last_level
	if _next_card != null:
		_next_card.visible = _is_last_level or _next_label != ""
		var preview_row: Control = _next_card.find_child("PreviewRow", true, false)
		if preview_row != null: preview_row.visible = not _is_last_level
		var title: Label = _next_card.find_child("NextTitle", true, false)
		if title != null:
			var loc := TranslationServer.get_locale()
			var raw_num := _next_label.trim_prefix("L").trim_prefix("Màn ").trim_prefix("Level ")
			title.text = ("Màn " + raw_num) if loc.begins_with("vi") else ("Level " + raw_num)
		var diff: Label = _next_card.find_child("NextDiff", true, false)
		if diff != null:
			diff.text = _difficulty_display(_next_difficulty)
			var dp: StyleBoxFlat = diff.get_theme_stylebox("normal") as StyleBoxFlat
			if dp != null: dp.bg_color = WinNextPreview.difficulty_color(_next_difficulty)
		var sz: Label = _next_card.find_child("NextSize", true, false)
		if sz != null:
			var loc := TranslationServer.get_locale()
			var prefix := "Lưới " if loc.begins_with("vi") else "Grid "
			sz.text = ("%s%dx%d" % [prefix, _next_size, _next_size]) if _next_size > 0 else ""

func _play_entrance_animations() -> void:
	if not LayoutTokens.motion_enabled: return
	if _next_card != null: _next_card.modulate.a = 0.0
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree(): return
	if _confetti != null: _confetti.start()
	if ribbon != null: ribbon.animate()
	if _hearts != null: _hearts.animate()
	if stat_card != null: stat_card.animate(0.4)
	if _next_card != null: TweenHelpers.rise_in(_next_card, 1.3)
	if mascot != null:
		mascot.drop_in(0.8)
		get_tree().create_timer(2.2).timeout.connect(func():
			if is_instance_valid(mascot): mascot.celebrate()
		)
	if next_btn != null:
		get_tree().create_timer(2.0).timeout.connect(func():
			if is_instance_valid(next_btn): TweenHelpers.pulse(next_btn, 0.0)
		)
	_animate_glint()

func _on_next() -> void: next_pressed.emit()
func _on_replay() -> void: replay_pressed.emit()
func _on_home() -> void: home_pressed.emit()

static func _animate_twinkle(star: Control, delay: float) -> void:
	var tw := star.create_tween().set_loops()
	tw.tween_interval(delay)
	tw.tween_property(star, "scale", Vector2(1.1, 1.1), 0.8).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(star, "modulate:a", 1.0, 0.8)
	tw.parallel().tween_property(star, "rotation_degrees", 45.0, 0.8)
	tw.tween_property(star, "scale", Vector2(0.4, 0.4), 0.8).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(star, "modulate:a", 0.3, 0.8)
	tw.parallel().tween_property(star, "rotation_degrees", 0.0, 0.8)

func _animate_glint() -> void:
	if not LayoutTokens.motion_enabled: return
	var glint: ColorRect = next_btn.get_node_or_null("Glint") if next_btn != null else null
	if glint == null: return
	var tw := glint.create_tween().set_loops()
	tw.tween_interval(2.2); tw.tween_property(glint, "position:x", -160.0, 0.0)
	tw.tween_property(glint, "position:x", 420.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT); tw.tween_interval(1.8)

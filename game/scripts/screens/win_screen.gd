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
var _mascot: TextureRect
var stat_card: StatCard
var _next_card: PanelContainer
var next_btn: Button
var home_btn: Button
var replay_btn: Button
var _level_badge: Label

func _ensure_nodes() -> void:
	if _bg != null:
		return
	_bg = GradientBg.new(Palette.WIN_BG_CENTER, Palette.WIN_BG_MID, Palette.WIN_BG_EDGE)
	add_child(_bg)

	_rays = SunburstRays.new()
	add_child(_rays)

	_confetti = ConfettiLayer.new(40)
	add_child(_confetti)

	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right"]: safe.add_theme_constant_override("margin_" + s, 48)
	safe.add_theme_constant_override("margin_top", 44)
	safe.add_theme_constant_override("margin_bottom", 52)
	add_child(safe)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 14)
	safe.add_child(stack)

	# 1. Top bar
	var top := HBoxContainer.new()
	stack.add_child(top)

	var top_home := Button.new()
	top_home.custom_minimum_size = Vector2(64, 64)
	top_home.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var hstyle := StyleBoxFlat.new()
	hstyle.bg_color = Palette.HOME_TOP_BTN_BG; hstyle.set_corner_radius_all(18)
	hstyle.shadow_color = Palette.HOME_TOP_BTN_SHADOW; hstyle.shadow_size = 5; hstyle.shadow_offset = Vector2(0, 5)
	for s in ["normal", "hover", "pressed", "focus"]: top_home.add_theme_stylebox_override(s, hstyle)
	top_home.pressed.connect(func(): home_pressed.emit())
	top.add_child(top_home)

	var top_icon := TextureRect.new()
	top_icon.texture = load("res://assets/ui/board/button_back.png") as Texture2D
	top_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	top_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top_icon.custom_minimum_size = Vector2(40, 40)
	top_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	top_home.add_child(top_icon)

	var spacer1 := Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer1)

	_level_badge = Label.new()
	_level_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_badge.add_theme_font_size_override("font_size", 26)
	_level_badge.add_theme_color_override("font_color", Palette.WIN_TEXT_PRIMARY)
	var badge_font := FontTokens.heading()
	if badge_font != null: _level_badge.add_theme_font_override("font", badge_font)
	top.add_child(_level_badge)

	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer2.custom_minimum_size.x = 64
	top.add_child(spacer2)

	# 2. Ribbon
	ribbon = RibbonBanner.new(tr("result.win.title"), "win")
	stack.add_child(ribbon)

	# 3. Hearts
	_hearts = HeartDisplay.new(3, _hearts_left, "win")
	stack.add_child(_hearts)

	# 4. Mascot
	_mascot = TextureRect.new()
	_mascot.texture = load("res://assets/ui/result/mascot_happy.svg") as Texture2D
	_mascot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_mascot.custom_minimum_size = Vector2(420, 270)
	_mascot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(_mascot)

	# 5. Stat card
	stat_card = StatCard.new(_build_stats())
	stack.add_child(stat_card)

	# 6. Next-level preview card
	_next_card = _create_next_card()
	stack.add_child(_next_card)

	# Vertical flexible spacer
	var bottom_space := Control.new()
	bottom_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(bottom_space)

	# 7. Action card
	var action_card := PanelContainer.new()
	action_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ac_style := StyleBoxFlat.new()
	ac_style.bg_color = Color.WHITE; ac_style.set_corner_radius_all(30)
	ac_style.shadow_color = Palette.WIN_CARD_SHADOW; ac_style.shadow_size = 10; ac_style.shadow_offset = Vector2(0, 8)
	ac_style.set_content_margin_all(20)
	action_card.add_theme_stylebox_override("panel", ac_style)
	stack.add_child(action_card)

	var ac_stack := VBoxContainer.new()
	ac_stack.add_theme_constant_override("separation", 14)
	action_card.add_child(ac_stack)

	next_btn = ActionButton.create(tr("result.win.next"), Palette.WIN_BUTTON_BG, Palette.WIN_BUTTON_SHADOW, Palette.WIN_BUTTON_TEXT_SHADOW, 34, 92)
	next_btn.pressed.connect(_on_next)
	ac_stack.add_child(next_btn)

	replay_btn = ActionButton.create(tr("result.win.replay"), Palette.WIN_BUTTON_BG, Palette.WIN_BUTTON_SHADOW, Palette.WIN_BUTTON_TEXT_SHADOW, 34, 92)
	replay_btn.pressed.connect(_on_replay)
	replay_btn.visible = false
	ac_stack.add_child(replay_btn)

	home_btn = ActionButton.create(tr("result.win.home"), Palette.PILL_BG, Palette.WIN_CARD_SHADOW, Color.TRANSPARENT, 28, 76)
	home_btn.add_theme_color_override("font_color", Palette.INK)
	home_btn.pressed.connect(_on_home)
	ac_stack.add_child(home_btn)

func _create_next_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "NextCard"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nc_style := StyleBoxFlat.new()
	nc_style.bg_color = Palette.WIN_NEXT_BOARD_BG; nc_style.set_corner_radius_all(22)
	nc_style.shadow_color = Palette.WIN_NEXT_BOARD_SHADOW; nc_style.shadow_size = 6; nc_style.shadow_offset = Vector2(0, 6)
	nc_style.set_content_margin_all(14)
	card.add_theme_stylebox_override("panel", nc_style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)

	var mini_grid := GridContainer.new()
	mini_grid.columns = clampi(_next_size, 4, 12) if _next_size > 0 else 4
	for ci in range(mini_grid.columns * mini_grid.columns):
		var cell := ColorRect.new()
		cell.custom_minimum_size = Vector2(12, 12); cell.color = Palette.WIN_NEXT_CELL
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE; mini_grid.add_child(cell)
	row.add_child(mini_grid)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)

	var title := Label.new()
	title.name = "NextTitle"
	var t_fmt := tr("result.win.next_level")
	title.text = (t_fmt % _next_label) if t_fmt.contains("%s") else (t_fmt + ": " + _next_label)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Palette.WIN_TEXT_PRIMARY)
	var hfont := FontTokens.heading()
	if hfont != null: title.add_theme_font_override("font", hfont)
	info.add_child(title)

	var meta_row := HBoxContainer.new()
	meta_row.add_theme_constant_override("separation", 12)
	info.add_child(meta_row)

	var diff_lbl := Label.new()
	diff_lbl.name = "NextDiff"
	diff_lbl.text = _difficulty_display(_next_difficulty)
	diff_lbl.add_theme_font_size_override("font_size", 16)
	diff_lbl.add_theme_color_override("font_color", _difficulty_color(_next_difficulty))
	meta_row.add_child(diff_lbl)

	var size_lbl := Label.new()
	size_lbl.name = "NextSize"
	size_lbl.text = "%dx%d" % [_next_size, _next_size] if _next_size > 0 else ""
	size_lbl.add_theme_font_size_override("font_size", 16)
	size_lbl.add_theme_color_override("font_color", Palette.WIN_TEXT_SECONDARY)
	meta_row.add_child(size_lbl)

	return card

func _build_stats() -> Array[Dictionary]:
	return [
		{"label": tr("result.stat.time"), "value": _format_time(_elapsed_ms), "icon": "clock"},
		{"label": tr("result.stat.mistakes"), "value": str(_mistake_count), "icon": "error"},
	]

func _format_time(ms: int) -> String:
	var total_secs: int = int(ms / 1000.0)
	var mins: int = int(total_secs / 60.0)
	var secs: int = total_secs % 60
	return "%02d:%02d" % [mins, secs]

func _difficulty_display(d: String) -> String:
	match d:
		"tutorial": return tr("difficulty.tutorial")
		"easy": return tr("difficulty.easy")
		"medium": return tr("difficulty.medium")
		"hard": return tr("difficulty.hard")
		_: return ""

static func _difficulty_color(d: String) -> Color:
	match d:
		"tutorial", "easy": return Palette.WIN_DIFFICULTY_EASY
		"medium": return Palette.WIN_DIFFICULTY_MEDIUM
		"hard": return Palette.WIN_DIFFICULTY_HARD
		_: return Palette.WIN_TEXT_SECONDARY

func setup(won: bool, score: int, level_id: String, is_last: bool, hearts_left: int = 3, mistake_count: int = 0, next_label: String = "", next_size: int = 0, next_difficulty: String = "") -> void:
	_is_last_level = is_last; _level_id = level_id.trim_prefix("L"); _elapsed_ms = score
	_hearts_left = clampi(hearts_left, 0, 3); _mistake_count = mistake_count
	_next_label = next_label; _next_size = next_size; _next_difficulty = next_difficulty
	_ensure_nodes()
	_update_ui()

func _ready() -> void:
	_ensure_nodes()
	_update_ui()
	_play_entrance_animations()

func _update_ui() -> void:
	if ribbon != null:
		ribbon.text = tr("result.win.title_campaign") if _is_last_level else tr("result.win.title")
	if _level_badge != null:
		var b_fmt := tr("result.level_badge")
		_level_badge.text = (b_fmt % _level_id) if b_fmt.contains("%s") else (b_fmt + " " + _level_id)
	if next_btn != null:
		next_btn.visible = not _is_last_level
	if replay_btn != null:
		replay_btn.visible = _is_last_level
	if _next_card != null:
		_next_card.visible = not _is_last_level and _next_label != ""
		var title: Label = _next_card.find_child("NextTitle", true, false)
		if title != null:
			var t_fmt := tr("result.win.next_level")
			title.text = (t_fmt % _next_label) if t_fmt.contains("%s") else (t_fmt + ": " + _next_label)
		var diff: Label = _next_card.find_child("NextDiff", true, false)
		if diff != null:
			diff.text = _difficulty_display(_next_difficulty)
			diff.add_theme_color_override("font_color", _difficulty_color(_next_difficulty))
		var sz: Label = _next_card.find_child("NextSize", true, false)
		if sz != null:
			sz.text = "%dx%d" % [_next_size, _next_size] if _next_size > 0 else ""

func _play_entrance_animations() -> void:
	if not LayoutTokens.motion_enabled: return
	if _confetti != null: _confetti.start()
	if ribbon != null: ribbon.animate()
	if _hearts != null: _hearts.animate()
	if stat_card != null: stat_card.animate(1.1)

func _on_next() -> void: next_pressed.emit()
func _on_replay() -> void: replay_pressed.emit()
func _on_home() -> void: home_pressed.emit()

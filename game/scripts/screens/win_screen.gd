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
	if _bg != null: return
	_bg = GradientBg.new(Palette.WIN_BG_CENTER, Palette.WIN_BG_MID, Palette.WIN_BG_EDGE); add_child(_bg)
	_rays = SunburstRays.new(); add_child(_rays)
	_confetti = ConfettiLayer.new(40); add_child(_confetti)

	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right"]: safe.add_theme_constant_override("margin_" + s, 48)
	safe.add_theme_constant_override("margin_top", 44); safe.add_theme_constant_override("margin_bottom", 52)
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
	spacer2.custom_minimum_size.x = 84; top.add_child(spacer2)

	# 2. Ribbon
	ribbon = RibbonBanner.new(tr("result.win.title"), "win")
	stack.add_child(ribbon)

	# 3. Hearts
	_hearts = HeartDisplay.new(3, _hearts_left, "win")
	stack.add_child(_hearts)

	# 4. Mascot & Ground Shadow
	var mascot_box := VBoxContainer.new()
	mascot_box.alignment = BoxContainer.ALIGNMENT_CENTER
	mascot_box.add_theme_constant_override("separation", -8)
	stack.add_child(mascot_box)

	_mascot = TextureRect.new()
	_mascot.texture = load("res://assets/ui/result/mascot_happy.svg") as Texture2D
	_mascot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_mascot.custom_minimum_size = Vector2(460, 290)
	_mascot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mascot_box.add_child(_mascot)

	var shadow := _GroundShadow.new()
	shadow.custom_minimum_size = Vector2(260, 36)
	shadow.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mascot_box.add_child(shadow)

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
	nc_style.bg_color = Color.WHITE; nc_style.set_corner_radius_all(28)
	nc_style.shadow_color = Color("#EFD27E"); nc_style.shadow_size = 8; nc_style.shadow_offset = Vector2(0, 7)
	nc_style.set_content_margin_all(20)
	card.add_theme_stylebox_override("panel", nc_style)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 16)
	card.add_child(inner)

	var row := HBoxContainer.new()
	row.name = "PreviewRow"; row.add_theme_constant_override("separation", 18)
	inner.add_child(row)

	var mini_wrap := PanelContainer.new()
	mini_wrap.custom_minimum_size = Vector2(96, 96)
	var mg_style := StyleBoxFlat.new()
	mg_style.bg_color = Color("#FAF0DA"); mg_style.set_corner_radius_all(18)
	mg_style.shadow_color = Color("#E2C46A"); mg_style.shadow_size = 5; mg_style.shadow_offset = Vector2(0, 4)
	mg_style.set_content_margin_all(10)
	mini_wrap.add_theme_stylebox_override("panel", mg_style)
	row.add_child(mini_wrap)

	var mini_grid := GridContainer.new()
	mini_grid.columns = clampi(_next_size, 4, 12) if _next_size > 0 else 4
	var pcols: Array[Color] = [Color("#38BDF8"), Color("#FBBF24"), Color("#FB923C"), Color("#34D399")]
	for ci in range(mini_grid.columns * mini_grid.columns):
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(14, 14)
		var cs := StyleBoxFlat.new(); cs.bg_color = pcols[(ci * 3 + 1) % 4]; cs.set_corner_radius_all(4)
		cell.add_theme_stylebox_override("panel", cs)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE; mini_grid.add_child(cell)
	mini_wrap.add_child(mini_grid)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL; info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 4); row.add_child(info)

	var next_hdr := Label.new()
	next_hdr.name = "NextLabel"; next_hdr.text = tr("result.win.next_header")
	next_hdr.add_theme_font_size_override("font_size", 20); next_hdr.add_theme_color_override("font_color", Color("#64748B"))
	var bold := FontTokens.body_bold()
	if bold != null: next_hdr.add_theme_font_override("font", bold)
	info.add_child(next_hdr)

	var title := Label.new()
	title.name = "NextTitle"; title.text = _next_label
	title.add_theme_font_size_override("font_size", 36); title.add_theme_color_override("font_color", Color("#1E293B"))
	var hfont := FontTokens.heading()
	if hfont != null: title.add_theme_font_override("font", hfont)
	info.add_child(title)

	var meta_row := HBoxContainer.new()
	meta_row.add_theme_constant_override("separation", 12); info.add_child(meta_row)

	var diff_lbl := Label.new()
	diff_lbl.name = "NextDiff"; diff_lbl.text = _difficulty_display(_next_difficulty)
	diff_lbl.add_theme_font_size_override("font_size", 18); diff_lbl.add_theme_color_override("font_color", Color.WHITE)
	if bold != null: diff_lbl.add_theme_font_override("font", bold)
	var dp_style := StyleBoxFlat.new()
	dp_style.bg_color = _difficulty_color(_next_difficulty); dp_style.set_corner_radius_all(999)
	dp_style.content_margin_left = 16; dp_style.content_margin_right = 16; dp_style.content_margin_top = 4; dp_style.content_margin_bottom = 4
	diff_lbl.add_theme_stylebox_override("normal", dp_style); meta_row.add_child(diff_lbl)

	var size_lbl := Label.new()
	size_lbl.name = "NextSize"
	size_lbl.text = "%dx%d" % [_next_size, _next_size] if _next_size > 0 else ""
	size_lbl.add_theme_font_size_override("font_size", 22); size_lbl.add_theme_color_override("font_color", Color("#64748B"))
	if bold != null: size_lbl.add_theme_font_override("font", bold)
	meta_row.add_child(size_lbl)

	next_btn = ActionButton.create(tr("result.win.next") + " ➔", Palette.WIN_BUTTON_BG, Palette.WIN_BUTTON_SHADOW, Palette.WIN_BUTTON_TEXT_SHADOW, 34, 94)
	next_btn.pressed.connect(_on_next); inner.add_child(next_btn)

	replay_btn = ActionButton.create(tr("result.win.replay"), Palette.WIN_BUTTON_BG, Palette.WIN_BUTTON_SHADOW, Palette.WIN_BUTTON_TEXT_SHADOW, 34, 94)
	replay_btn.pressed.connect(_on_replay); replay_btn.visible = false; inner.add_child(replay_btn)

	return card

func _build_stats() -> Array[Dictionary]:
	return [
		{"label": tr("result.stat.time"), "value": _format_time(_elapsed_ms), "icon": "clock"},
		{"label": tr("result.stat.mistakes"), "value": str(_mistake_count), "icon": "error"},
	]

func _format_time(ms: int) -> String:
	var total_secs: int = int(ms / 1000.0)
	return "%02d:%02d" % [int(total_secs / 60.0), total_secs % 60]

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
		"hard": return Color("#BE185D")
		_: return Palette.WIN_TEXT_SECONDARY

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
			if dp != null: dp.bg_color = _difficulty_color(_next_difficulty)
		var sz: Label = _next_card.find_child("NextSize", true, false)
		if sz != null:
			var loc := TranslationServer.get_locale()
			var prefix := "Lưới " if loc.begins_with("vi") else "Grid "
			sz.text = ("%s%dx%d" % [prefix, _next_size, _next_size]) if _next_size > 0 else ""

func _play_entrance_animations() -> void:
	if not LayoutTokens.motion_enabled: return
	if _confetti != null: _confetti.start()
	if ribbon != null: ribbon.animate()
	if _hearts != null: _hearts.animate()
	if stat_card != null: stat_card.animate(0.4)

func _on_next() -> void: next_pressed.emit()
func _on_replay() -> void: replay_pressed.emit()
func _on_home() -> void: home_pressed.emit()

class _GroundShadow extends Control:
	func _draw() -> void:
		var pts: PackedVector2Array = []
		var rx: float = size.x * 0.5; var ry: float = size.y * 0.5; var center := Vector2(rx, ry)
		for i in range(32):
			var a: float = (float(i) / 32.0) * TAU
			pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
		draw_colored_polygon(pts, Color(0.78, 0.59, 0.16, 0.28))

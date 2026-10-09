# fail_screen.gd — Game over screen with sad mascot, broken hearts, and rain cloud.
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
const ActionButton = preload("res://scripts/ui/action_button.gd")

var _level_id: String = ""
var _elapsed_ms: int = 0

var _bg: ColorRect
var ribbon: RibbonBanner
var _hearts: HeartDisplay
var mascot: TextureRect
var _cloud: TextureRect
var stat_card: StatCard
var retry_btn: Button
var home_btn: Button
var _level_badge: Label
var _encourage_sub: Label

func _ensure_nodes() -> void:
	if _bg != null: return
	_bg = GradientBg.new(Color("#FFFFFF"), Palette.LOSE_BG_MID, Palette.LOSE_BG_EDGE, Vector2(0.5, 0.35))
	add_child(_bg)

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
	var top := HBoxContainer.new(); stack.add_child(top)

	home_btn = Button.new()
	home_btn.custom_minimum_size = Vector2(84, 84); home_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var hstyle := StyleBoxFlat.new()
	hstyle.bg_color = Color("#6D55B8"); hstyle.set_corner_radius_all(22)
	hstyle.shadow_color = Color("#4B3B9A"); hstyle.shadow_size = 6; hstyle.shadow_offset = Vector2(0, 6)
	for s in ["normal", "hover", "pressed", "focus"]: home_btn.add_theme_stylebox_override(s, hstyle)
	home_btn.pressed.connect(_on_home); top.add_child(home_btn)

	var top_center := CenterContainer.new()
	top_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); top_center.mouse_filter = Control.MOUSE_FILTER_IGNORE; home_btn.add_child(top_center)
	var top_icon := TextureRect.new()
	top_icon.texture = load("res://assets/ui/result/icon_home_white.svg") as Texture2D
	top_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; top_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top_icon.custom_minimum_size = Vector2(46, 46); top_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; top_center.add_child(top_icon)

	var spacer1 := Control.new(); spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(spacer1)

	_level_badge = Label.new()
	_level_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_badge.add_theme_font_size_override("font_size", 28); _level_badge.add_theme_color_override("font_color", Color("#23365E"))
	var bstyle := StyleBoxFlat.new()
	bstyle.bg_color = Color.WHITE; bstyle.set_corner_radius_all(999)
	bstyle.shadow_color = Palette.LOSE_CARD_SHADOW; bstyle.shadow_size = 5; bstyle.shadow_offset = Vector2(0, 5)
	bstyle.content_margin_left = 34; bstyle.content_margin_right = 34; bstyle.content_margin_top = 10; bstyle.content_margin_bottom = 10
	_level_badge.add_theme_stylebox_override("normal", bstyle)
	var badge_font := FontTokens.heading()
	if badge_font != null: _level_badge.add_theme_font_override("font", badge_font)
	top.add_child(_level_badge)

	var spacer2 := Control.new(); spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer2.custom_minimum_size.x = 84; top.add_child(spacer2)

	# 2. Ribbon
	ribbon = RibbonBanner.new(tr("result.lose.title"), "lose")
	stack.add_child(ribbon)

	# 3. Hearts (all 3 broken)
	_hearts = HeartDisplay.new(3, 0, "lose")
	stack.add_child(_hearts)

	# 4. Cloud & Mascot & Ground Shadow
	var mascot_box := VBoxContainer.new()
	mascot_box.alignment = BoxContainer.ALIGNMENT_CENTER
	mascot_box.add_theme_constant_override("separation", -12); stack.add_child(mascot_box)

	_cloud = TextureRect.new()
	_cloud.texture = load("res://assets/ui/result/cloud_rain.svg") as Texture2D
	_cloud.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; _cloud.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_cloud.custom_minimum_size = Vector2(240, 130); _cloud.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mascot_box.add_child(_cloud)

	mascot = TextureRect.new()
	mascot.texture = load("res://assets/ui/result/mascot_sad.svg") as Texture2D
	mascot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot.custom_minimum_size = Vector2(520, 330); mascot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mascot_box.add_child(mascot)

	var shadow := _GroundShadow.new()
	shadow.custom_minimum_size = Vector2(300, 42); shadow.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mascot_box.add_child(shadow)

	# 5. Stat card (time only)
	stat_card = StatCard.new([{"label": tr("result.stat.time"), "value": _format_time(_elapsed_ms), "icon": "clock"}], Palette.LOSE_CARD_SHADOW)
	stack.add_child(stat_card)

	var bottom_space := Control.new(); bottom_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(bottom_space)

	# 6. Action card
	var action_card := PanelContainer.new()
	action_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ac_style := StyleBoxFlat.new()
	ac_style.bg_color = Color.WHITE; ac_style.set_corner_radius_all(28)
	ac_style.shadow_color = Palette.LOSE_CARD_SHADOW; ac_style.shadow_size = 10; ac_style.shadow_offset = Vector2(0, 8)
	ac_style.content_margin_left = 24; ac_style.content_margin_right = 24; ac_style.content_margin_top = 26; ac_style.content_margin_bottom = 26
	action_card.add_theme_stylebox_override("panel", ac_style); stack.add_child(action_card)

	var ac_stack := VBoxContainer.new()
	ac_stack.add_theme_constant_override("separation", 14); action_card.add_child(ac_stack)

	var encourage_title := Label.new()
	encourage_title.text = tr("result.lose.encourage_title")
	encourage_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	encourage_title.add_theme_font_size_override("font_size", 32); encourage_title.add_theme_color_override("font_color", Color("#23365E"))
	var heading := FontTokens.heading()
	if heading != null: encourage_title.add_theme_font_override("font", heading)
	ac_stack.add_child(encourage_title)

	_encourage_sub = Label.new()
	_encourage_sub.name = "EncourageSub"
	_encourage_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_encourage_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_encourage_sub.add_theme_font_size_override("font_size", 19); _encourage_sub.add_theme_color_override("font_color", Color("#64748B"))
	var body := FontTokens.body()
	if body != null: _encourage_sub.add_theme_font_override("font", body)
	ac_stack.add_child(_encourage_sub)

	retry_btn = ActionButton.create(tr("result.lose.retry"), Palette.LOSE_BUTTON_BG, Palette.LOSE_BUTTON_SHADOW, Palette.LOSE_BUTTON_TEXT_SHADOW, 34, 94)
	ActionButton.set_leading_icon(retry_btn, "res://assets/ui/result/icon_replay_white.svg", Vector2(34, 34))
	retry_btn.pressed.connect(_on_retry); retry_btn.pressed.connect(_on_replay)
	ac_stack.add_child(retry_btn)

func _format_time(ms: int) -> String:
	var s: int = int(ms / 1000.0)
	return "%02d:%02d" % [int(s / 60.0), s % 60]

func setup(won: bool, score: int, level_id: String, is_last: bool) -> void:
	_level_id = level_id.trim_prefix("L")
	_elapsed_ms = score
	_ensure_nodes(); _update_ui()

func _ready() -> void:
	_ensure_nodes(); _update_ui(); _play_entrance_animations()

func _update_ui() -> void:
	var loc := TranslationServer.get_locale()
	if ribbon != null:
		ribbon.text = "HẾT TIM RỒI!" if loc.begins_with("vi") else tr("result.lose.title")
	if _level_badge != null:
		_level_badge.text = ("Màn " + _level_id) if loc.begins_with("vi") else ("Level " + _level_id)
	if _encourage_sub != null:
		var s_fmt := tr("result.lose.encourage_subtitle")
		_encourage_sub.text = (s_fmt % _level_id) if s_fmt.contains("%s") else s_fmt
	if retry_btn != null:
		var action_lbl: Label = retry_btn.find_child("ActionLabel", true, false)
		var txt := "Chơi lại màn" if loc.begins_with("vi") else tr("result.lose.retry")
		if action_lbl != null: action_lbl.text = txt
		else: retry_btn.text = txt

func _play_entrance_animations() -> void:
	if not LayoutTokens.motion_enabled: return
	if ribbon != null: ribbon.animate()
	if _hearts != null: _hearts.animate()
	if stat_card != null: stat_card.animate(0.4)
	if mascot != null:
		mascot.scale = Vector2(0.9, 0.9)
		var tw := mascot.create_tween()
		tw.tween_interval(0.3)
		tw.tween_property(mascot, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_retry() -> void: retry_pressed.emit()
func _on_replay() -> void: replay_pressed.emit()
func _on_home() -> void: home_pressed.emit()

class _GroundShadow extends Control:
	func _draw() -> void:
		var pts: PackedVector2Array = []
		var rx: float = size.x * 0.5; var ry: float = size.y * 0.5; var center := Vector2(rx, ry)
		for i in range(32):
			var a: float = (float(i) / 32.0) * TAU
			pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
		draw_colored_polygon(pts, Color(0.48, 0.40, 0.65, 0.25))

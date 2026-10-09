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

func _ensure_nodes() -> void:
	if _bg != null:
		return
	_bg = GradientBg.new(Palette.LOSE_BG_CENTER, Palette.LOSE_BG_MID, Palette.LOSE_BG_EDGE, Vector2(0.5, 0.30))
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
	var top := HBoxContainer.new()
	stack.add_child(top)

	var top_home := Button.new()
	top_home.custom_minimum_size = Vector2(64, 64)
	top_home.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var hstyle := StyleBoxFlat.new()
	hstyle.bg_color = Color("#6E5BC8"); hstyle.set_corner_radius_all(18)
	hstyle.shadow_color = Color("#4B3B9A"); hstyle.shadow_size = 5; hstyle.shadow_offset = Vector2(0, 5)
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
	_level_badge.add_theme_color_override("font_color", Palette.LOSE_TEXT_PRIMARY)
	var badge_font := FontTokens.heading()
	if badge_font != null: _level_badge.add_theme_font_override("font", badge_font)
	top.add_child(_level_badge)

	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer2.custom_minimum_size.x = 64
	top.add_child(spacer2)

	# 2. Ribbon
	ribbon = RibbonBanner.new(tr("result.lose.title"), "lose")
	stack.add_child(ribbon)

	# 3. Hearts (all 3 broken)
	_hearts = HeartDisplay.new(3, 0, "lose")
	stack.add_child(_hearts)

	# 4. Cloud
	_cloud = TextureRect.new()
	_cloud.texture = load("res://assets/ui/result/cloud_rain.svg") as Texture2D
	_cloud.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cloud.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_cloud.custom_minimum_size = Vector2(160, 90)
	_cloud.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(_cloud)

	# 5. Mascot (sad)
	mascot = TextureRect.new()
	mascot.texture = load("res://assets/ui/result/mascot_sad.svg") as Texture2D
	mascot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot.custom_minimum_size = Vector2(420, 270)
	mascot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(mascot)

	# 6. Stat card (time only)
	stat_card = StatCard.new([{"label": tr("result.stat.time"), "value": _format_time(_elapsed_ms), "icon": "clock"}])
	stack.add_child(stat_card)

	# Vertical flexible spacer
	var bottom_space := Control.new()
	bottom_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(bottom_space)

	# 7. Action card
	var action_card := PanelContainer.new()
	action_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ac_style := StyleBoxFlat.new()
	ac_style.bg_color = Color.WHITE; ac_style.set_corner_radius_all(30)
	ac_style.shadow_color = Palette.LOSE_CARD_SHADOW; ac_style.shadow_size = 10; ac_style.shadow_offset = Vector2(0, 8)
	ac_style.set_content_margin_all(20)
	action_card.add_theme_stylebox_override("panel", ac_style)
	stack.add_child(action_card)

	var ac_stack := VBoxContainer.new()
	ac_stack.add_theme_constant_override("separation", 14)
	action_card.add_child(ac_stack)

	var encourage_title := Label.new()
	encourage_title.text = tr("result.lose.encourage_title")
	encourage_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	encourage_title.add_theme_font_size_override("font_size", 28)
	encourage_title.add_theme_color_override("font_color", Palette.LOSE_TEXT_PRIMARY)
	var heading := FontTokens.heading()
	if heading != null: encourage_title.add_theme_font_override("font", heading)
	ac_stack.add_child(encourage_title)

	retry_btn = ActionButton.create(tr("result.lose.retry"), Palette.LOSE_BUTTON_BG, Palette.LOSE_BUTTON_SHADOW, Palette.LOSE_BUTTON_TEXT_SHADOW, 34, 92)
	retry_btn.pressed.connect(_on_retry)
	ac_stack.add_child(retry_btn)

	home_btn = ActionButton.create(tr("result.win.home"), Palette.PILL_BG, Palette.LOSE_CARD_SHADOW, Color.TRANSPARENT, 28, 76)
	home_btn.add_theme_color_override("font_color", Palette.INK)
	home_btn.pressed.connect(_on_home)
	ac_stack.add_child(home_btn)

func _format_time(ms: int) -> String:
	var total_secs: int = int(ms / 1000.0)
	var mins: int = int(total_secs / 60.0)
	var secs: int = total_secs % 60
	return "%02d:%02d" % [mins, secs]

func setup(won: bool, score: int, level_id: String, is_last: bool) -> void:
	_level_id = level_id.trim_prefix("L")
	_elapsed_ms = score
	_ensure_nodes()
	_update_ui()

func _ready() -> void:
	_ensure_nodes()
	_update_ui()
	_play_entrance_animations()

func _update_ui() -> void:
	if _level_badge != null:
		var b_fmt := tr("result.level_badge")
		_level_badge.text = (b_fmt % _level_id) if b_fmt.contains("%s") else (b_fmt + " " + _level_id)

func _play_entrance_animations() -> void:
	if not LayoutTokens.motion_enabled: return
	if ribbon != null: ribbon.animate()
	if _hearts != null: _hearts.animate()
	if stat_card != null: stat_card.animate(1.1)
	if mascot != null: _animate_mascot_thud()

func _animate_mascot_thud() -> void:
	mascot.position.y -= 220
	mascot.modulate.a = 0.0
	var tw := mascot.create_tween()
	tw.tween_interval(0.8)
	tw.tween_property(mascot, "position:y", mascot.position.y + 220, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(mascot, "modulate:a", 1.0, 0.2)

func _on_retry() -> void: retry_pressed.emit()
func _on_home() -> void: home_pressed.emit()

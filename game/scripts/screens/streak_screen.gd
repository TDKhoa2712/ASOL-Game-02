# Streak screen: header, glowing cartoon flame + day count, 7-day cycle card with gift box, best line.
extends Control

signal back_pressed

const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const Palette = preload("res://scripts/theme/palette.gd")
const FlameFx = preload("res://scripts/screens/flame_fx.gd")
const StripScript = preload("res://scripts/screens/streak_cycle_strip.gd")
const BackButton = preload("res://scripts/screens/back_button.gd")
const GradientBg = preload("res://scripts/ui/gradient_bg.gd")
const GlowBurst = preload("res://scripts/ui/glow_burst.gd")
const TweenHelpers = preload("res://scripts/ui/tween_helpers.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const INK := Color("#23365E")
const ON_COLOR := Color("#FF7A1A")
const ON_SHADOW := Color("#C24A10")
const BEST_BG := Color("#FFF6E2")
const BEST_INK := Color("#9B5A52")
const FLAME_SIZE := 420.0

var assists: Variant = null
var title_label: Label
var back_btn: Button
var flame: Control
var glow: GlowBurst
var count_label: Label
var days_label: Label
var strip: StreakCycleStrip
var gift_box: GiftBoxView
var best_label: Label
var _glow_tween: Tween = null

func _init() -> void:
	name = "StreakScreen"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(GradientBg.new(Palette.HOME_BG_CENTER, Palette.HOME_BG_MID, Palette.HOME_BG_EDGE, Vector2(0.5, 0.26)))
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_top = 48; col.offset_left = 48; col.offset_right = -48; col.offset_bottom = -48
	col.add_theme_constant_override("separation", 20)
	add_child(col)
	back_btn = BackButton.make()
	back_btn.pressed.connect(func(): back_pressed.emit())
	title_label = _label(72, FontTokens.heading())
	col.add_child(BackButton.make_header(back_btn, title_label))
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(FLAME_SIZE, FLAME_SIZE)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow = GlowBurst.new(FLAME_SIZE * 0.7)
	glow.position = Vector2(FLAME_SIZE * 0.5, FLAME_SIZE * 0.6)
	stage.add_child(glow)
	flame = FlameFx.new(FLAME_SIZE, 1)
	stage.add_child(flame)
	col.add_child(_centered(stage))
	count_label = _label(220, FontTokens.heading())
	count_label.add_theme_constant_override("shadow_offset_x", 0)
	count_label.add_theme_constant_override("shadow_offset_y", 12)
	col.add_child(count_label)
	days_label = _label(52, FontTokens.body_bold())
	days_label.add_theme_color_override("font_color", Palette.WIN_TEXT_SECONDARY)
	col.add_child(days_label)
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE; sb.set_corner_radius_all(64)
	sb.border_width_bottom = 14; sb.border_color = Palette.WIN_CARD_SHADOW
	sb.set_content_margin_all(32)
	card.add_theme_stylebox_override("panel", sb)
	strip = StripScript.new()
	gift_box = strip.gift_box
	card.add_child(strip)
	col.add_child(_centered(card))
	var pill := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = BEST_BG; psb.set_corner_radius_all(56)
	psb.content_margin_left = 48; psb.content_margin_right = 48
	psb.content_margin_top = 18; psb.content_margin_bottom = 18
	pill.add_theme_stylebox_override("panel", psb)
	best_label = _label(46, FontTokens.body_bold())
	best_label.add_theme_color_override("font_color", BEST_INK)
	pill.add_child(best_label)
	col.add_child(_centered(pill))

func setup(inv: Variant, today: String = "") -> void:
	assists = inv
	show_view(inv.streak_view(today) if inv != null else {})

func show_view(view: Dictionary) -> void:
	var kept: bool = view.get("kept_today", false)
	title_label.text = tr("streak.title")
	back_btn.tooltip_text = tr("settings.back")
	flame.set_lit(kept)
	count_label.text = str(int(view.get("count", 0)))
	count_label.add_theme_color_override("font_color", ON_COLOR if kept else INK)
	count_label.add_theme_color_override("font_shadow_color", ON_SHADOW if kept else Color(INK, 0.25))
	days_label.text = tr("streak.days")
	best_label.text = tr("streak.best") % int(view.get("best", 0))
	best_label.visible = true
	strip.show_view(view)
	gift_box.play_idle()
	_breathe(kept)

# Lit flame sits in a slow breathing glow; a grey flame has none.
func _breathe(on: bool) -> void:
	if _glow_tween != null and _glow_tween.is_valid():
		_glow_tween.kill()
	glow.glow = 0.8 if on else 0.0
	if not on or not LayoutTokens.motion_enabled or not is_inside_tree():
		return
	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_property(glow, "glow", 1.0, 1.3).set_trans(Tween.TRANS_SINE)
	_glow_tween.tween_property(glow, "glow", 0.75, 1.3).set_trans(Tween.TRANS_SINE)

func _centered(child: Control) -> CenterContainer:
	var c := CenterContainer.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(child)
	return c

func _label(font_size: int, font: Font) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", INK)
	if font != null: l.add_theme_font_override("font", font)
	return l

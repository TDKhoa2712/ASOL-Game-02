# Streak screen: title, back, flame + day count, 7-day cycle strip with gift box, best line.
extends Control

signal back_pressed

const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const FlameFx = preload("res://scripts/screens/flame_fx.gd")
const StripScript = preload("res://scripts/screens/streak_cycle_strip.gd")
const BG := Color("#FFF4E0")
const INK := Color("#23365E")
const ON_COLOR := Color("#FF7A1A")

var assists: Variant = null
var title_label: Label
var back_btn: Button
var flame: Control
var count_label: Label
var days_label: Label
var strip: StreakCycleStrip
var gift_box: GiftBoxView
var best_label: Label

func _init() -> void:
	name = "StreakScreen"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 20)
	add_child(col)
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 96)
	col.add_child(header)
	back_btn = Button.new()
	back_btn.name = "BackBtn"
	back_btn.custom_minimum_size = Vector2(84, 84)
	back_btn.text = "←"
	back_btn.pressed.connect(func(): back_pressed.emit())
	header.add_child(back_btn)
	title_label = _label(44, FontTokens.heading())
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	header.add_child(Control.new())  # balances the back button so the title stays centred
	header.get_child(2).custom_minimum_size = Vector2(84, 84)
	flame = FlameFx.new(200, 18)
	col.add_child(_centered(flame))
	count_label = _label(120, FontTokens.heading()); col.add_child(count_label)
	days_label = _label(32, FontTokens.body_bold()); col.add_child(days_label)
	strip = StripScript.new()
	gift_box = strip.gift_box
	col.add_child(_centered(strip))
	best_label = _label(30, FontTokens.body_bold()); col.add_child(best_label)

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
	days_label.text = tr("streak.days")
	best_label.text = tr("streak.best") % int(view.get("best", 0))
	best_label.visible = true
	strip.show_view(view)
	gift_box.play_idle()

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

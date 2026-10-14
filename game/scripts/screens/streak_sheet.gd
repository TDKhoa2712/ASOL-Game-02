# Streak sheet: big flame, day count, best, 7-day pack progress and today's status.
extends Control

const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const FlameFx = preload("res://scripts/screens/flame_fx.gd")
const FLAME := "res://assets/ui/home/icon_flame.svg"
const GIFT := "res://assets/candy/candy_icon.png"
const ON_COLOR := Color("#FF7A1A")
const OFF_COLOR := Color("#B9B4AC")
const INK := Color("#23365E")

var flame: Control
var count_label: Label
var days_label: Label
var best_label: Label
var left_label: Label
var status_label: Label
var close_btn: Button
var cells: Array = []

func _init() -> void:
	name = "StreakSheet"
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.45)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: close())
	add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(600, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE; sb.set_corner_radius_all(36)
	sb.border_width_bottom = 8; sb.border_color = Color("#E2C46A")
	for side in ["left", "right", "top", "bottom"]: sb.set("content_margin_" + side, 36)
	card.add_theme_stylebox_override("panel", sb)
	center.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	card.add_child(col)
	flame = FlameFx.new(140, 18)
	col.add_child(_centered(flame))
	count_label = _label(96, FontTokens.heading()); col.add_child(count_label)
	days_label = _label(30, FontTokens.body_bold()); col.add_child(days_label)
	best_label = _label(26, FontTokens.body()); col.add_child(best_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	for i in 7:
		var cell := _cell(i == 6)
		cells.append(cell); row.add_child(cell)
	col.add_child(row)
	left_label = _label(24, FontTokens.body()); col.add_child(left_label)
	status_label = _label(26, FontTokens.body_bold()); col.add_child(status_label)
	close_btn = Button.new()
	close_btn.name = "CloseBtn"
	close_btn.custom_minimum_size = Vector2(0, 84)
	close_btn.pressed.connect(close)
	col.add_child(close_btn)

func open(view: Dictionary) -> void:
	var kept: bool = view.get("kept_today", false)
	var count: int = int(view.get("count", 0))
	var done: int = int(view.get("cycle_done", 0))
	flame.set_lit(kept)
	count_label.text = str(count)
	count_label.add_theme_color_override("font_color", ON_COLOR if kept else INK)
	days_label.text = tr("streak.days")
	best_label.text = tr("streak.best") % int(view.get("best", 0))
	left_label.text = tr("streak.gift_got") if done >= 7 else tr("streak.left") % (7 - done)
	if kept: status_label.text = tr("streak.kept")
	elif count > 0: status_label.text = tr("streak.at_risk")
	else: status_label.text = tr("streak.start")
	for i in cells.size():
		var on := i < done
		var cell: PanelContainer = cells[i]
		cell.set_meta("done", on)
		(cell.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Color("#FFE3CC") if on else Color("#EFEDEA")
		(cell.get_child(0).get_child(0) as TextureRect).modulate = ON_COLOR if on else Color(1, 1, 1, 0.9) if i == 6 else Color(0, 0, 0, 0)
	close_btn.text = tr("assist.close")
	visible = true

func close() -> void:
	visible = false

func _cell(is_gift: bool) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.custom_minimum_size = Vector2(64, 64)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#EFEDEA"); sb.set_corner_radius_all(32)
	cell.add_theme_stylebox_override("panel", sb)
	var icon := _icon(GIFT if is_gift else FLAME, 40)
	cell.add_child(_centered(icon))
	return cell

func _icon(path: String, side: int) -> TextureRect:
	var t := TextureRect.new()
	if ResourceLoader.exists(path): t.texture = load(path) as Texture2D
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(side, side)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

func _centered(child: Control) -> CenterContainer:
	var c := CenterContainer.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(child)
	return c

func _label(font_size: int, font: Font) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", INK)
	if font != null: l.add_theme_font_override("font", font)
	return l

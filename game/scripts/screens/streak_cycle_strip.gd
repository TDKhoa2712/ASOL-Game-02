# Seven day cells of the streak cycle (done / today / todo); the last cell holds the gift box.
class_name StreakCycleStrip
extends HBoxContainer

const FlameFx = preload("res://scripts/screens/flame_fx.gd")
const GiftBoxScript = preload("res://scripts/screens/gift_box_view.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const DAYS := 7
const DONE_BG := Color("#FFE3CC")
const TODAY_BG := Color("#FFF6D6")
const TODO_BG := Color("#EFEDEA")
const TODAY_RING := Color("#FF7A1A")

var cells: Array[PanelContainer] = []
var gift_box: GiftBoxView
var _states: Array[String] = []

func _init() -> void:
	name = "StreakCycleStrip"
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 10)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in DAYS:
		var cell := PanelContainer.new()
		cell.name = "Day%d" % (i + 1)
		cell.custom_minimum_size = Vector2(72, 72)
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(36)
		cell.add_theme_stylebox_override("panel", sb)
		var center := CenterContainer.new()
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(center)
		if i == DAYS - 1:
			gift_box = GiftBoxScript.create()
			center.add_child(gift_box)
		else:
			center.add_child(FlameFx.new(40, 0))
		cells.append(cell)
		_states.append("todo")
		add_child(cell)
	show_view({})

func show_view(view: Dictionary) -> void:
	var done := clampi(int(view.get("cycle_done", 0)), 0, DAYS)
	var kept: bool = view.get("kept_today", false)
	for i in DAYS:
		var state := "todo"
		if i < done: state = "done"
		elif not kept and i == done: state = "today"
		_apply(i, state)

func cell_state(i: int) -> String:
	return _states[i] if i >= 0 and i < DAYS else ""

func today_index() -> int:
	return _states.find("today")

func fill_today_animated() -> void:
	var i := today_index()
	if i < 0:
		return
	_apply(i, "done")
	if not LayoutTokens.motion_enabled or not is_inside_tree():
		return
	var cell := cells[i]
	cell.pivot_offset = cell.custom_minimum_size * 0.5
	cell.scale = Vector2(0.6, 0.6)
	create_tween().tween_property(cell, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)

func _apply(i: int, state: String) -> void:
	_states[i] = state
	var cell := cells[i]
	cell.set_meta("state", state)
	var sb := cell.get_theme_stylebox("panel") as StyleBoxFlat
	sb.bg_color = DONE_BG if state == "done" else TODAY_BG if state == "today" else TODO_BG
	sb.border_color = TODAY_RING
	sb.set_border_width_all(4 if state == "today" else 0)
	var icon: Control = cell.get_child(0).get_child(0)
	if icon == gift_box:
		gift_box.modulate = Color.WHITE if state == "done" else Color(1, 1, 1, 0.75)
	else:
		icon.call("set_lit", state == "done")

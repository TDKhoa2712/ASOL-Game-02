# Full-screen step after the first finished round of the day: the flame lights, today's cell fills.
# Renders only what setup() receives; never reads or writes save (debug previews reuse it).
extends Control

const FlameFx = preload("res://scripts/screens/flame_fx.gd")

signal continued()

var view: Dictionary = {}
var title_label: Label
var count_label: Label
var flame: FlameFx
var strip: StreakCycleStrip
var continue_btn: Button

func setup(v: Dictionary) -> void:
	view = v.duplicate(true)
	_ensure_nodes()
	count_label.text = str(int(view.get("count", 0)))
	flame.set_lit(true)
	strip.show_view(view)
	strip.call_deferred("fill_today_animated")

func _ready() -> void:
	_ensure_nodes()

func _ensure_nodes() -> void:
	if continue_btn != null:
		return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#FFF6E8"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	add_child(box)
	title_label = Label.new(); title_label.text = tr("streak.activate_title")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 40)
	box.add_child(title_label)
	flame = FlameFx.new(160.0, 12)
	flame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(flame)
	count_label = Label.new(); count_label.text = "0"
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 64)
	box.add_child(count_label)
	strip = StreakCycleStrip.new()
	strip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(strip)
	continue_btn = Button.new(); continue_btn.text = tr("common.continue")
	continue_btn.custom_minimum_size = Vector2(280, 72)
	continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_btn.pressed.connect(func(): continued.emit())
	box.add_child(continue_btn)
